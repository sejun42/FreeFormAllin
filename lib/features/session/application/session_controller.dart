import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/protocol.dart';
import '../../../core/logging/log.dart';
import '../../../core/utils/bytes.dart';
import '../../ble/application/ble_controller.dart';
import '../../ble/application/packet_parser.dart';
import '../../ble/domain/ble_client.dart';
import '../data/drift/app_db.dart' hide Session;
import '../data/session_file_writer.dart';
import '../data/session_repository.dart';
import '../domain/session.dart';

// ── DB Provider ──────────────────────────────────────────────────

final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(() => db.close());
  return db;
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(appDbProvider));
});

// ── Session List ─────────────────────────────────────────────────

final sessionsListProvider =
    FutureProvider.autoDispose<List<Session>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getAllSessions();
});

// ── Session Controller ───────────────────────────────────────────

enum SessionPhase { idle, starting, recording, stopping }

class SessionState {
  final SessionPhase phase;
  final String? sessionId;
  final DateTime? startedAt;

  const SessionState({
    this.phase = SessionPhase.idle,
    this.sessionId,
    this.startedAt,
  });

  SessionState copyWith({
    SessionPhase? phase,
    String? sessionId,
    DateTime? startedAt,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  final BleClient _bleClient;
  final SessionRepository _repo;
  final StateController<LiveStats> _liveStatsController;
  final DeviceConnectionInfo _connInfo;

  SessionFileWriter? _fileWriter;
  final PacketParser _parserL = PacketParser();
  final PacketParser _parserR = PacketParser();
  final SeqTracker _seqL = SeqTracker();
  final SeqTracker _seqR = SeqTracker();

  StreamSubscription<Uint8List>? _leftDataSub;
  StreamSubscription<Uint8List>? _rightDataSub;
  Timer? _statsTimer;
  DateTime? _lastStatsTime;
  int _prevPacketsL = 0;
  int _prevPacketsR = 0;

  SessionController({
    required BleClient bleClient,
    required SessionRepository repo,
    required StateController<LiveStats> liveStatsController,
    required DeviceConnectionInfo connInfo,
  })  : _bleClient = bleClient,
        _repo = repo,
        _liveStatsController = liveStatsController,
        _connInfo = connInfo,
        super(const SessionState());

  /// Start a new recording session.
  Future<void> startSession() async {
    if (state.phase != SessionPhase.idle) return;
    state = state.copyWith(phase: SessionPhase.starting);

    try {
      final uuid = const Uuid().v4();
      final now = DateTime.now();

      // 1. Create session in DB and filesystem
      final session = await _repo.createSession(
        id: uuid,
        startedAt: now,
        deviceLeftId: _connInfo.leftDevice?.id,
        deviceRightId: _connInfo.rightDevice?.id,
      );

      // 2. Open file writer
      _fileWriter = SessionFileWriter(dirPath: session.dirPath);
      await _fileWriter!.open();

      // 3. Subscribe to data notifications
      _parserL.reset();
      _parserR.reset();
      _seqL.reset();
      _seqR.reset();

      if (_connInfo.leftDevice != null) {
        _leftDataSub =
            _bleClient.subscribeToData(_connInfo.leftDevice!.id).listen(
          (data) => _handleData(data, isLeft: true),
          onError: (e) => log.e('L data error', error: e),
        );
      }

      if (_connInfo.rightDevice != null) {
        _rightDataSub =
            _bleClient.subscribeToData(_connInfo.rightDevice!.id).listen(
          (data) => _handleData(data, isLeft: false),
          onError: (e) => log.e('R data error', error: e),
        );
      }

      // 4. Send START command to both nodes
      final cmdPayload = Uint8List(17);
      cmdPayload[0] = Protocol.cmdStart;
      final uuidBytes = Bytes.uuidStringToBytes(uuid);
      cmdPayload.setRange(1, 17, uuidBytes);

      if (_connInfo.leftDevice != null) {
        await _bleClient.writeCommand(_connInfo.leftDevice!.id, cmdPayload);
      }
      if (_connInfo.rightDevice != null) {
        await _bleClient.writeCommand(_connInfo.rightDevice!.id, cmdPayload);
      }

      // 5. Start PPS timer
      _prevPacketsL = 0;
      _prevPacketsR = 0;
      _lastStatsTime = DateTime.now();
      _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updatePps();
      });

      state = state.copyWith(
        phase: SessionPhase.recording,
        sessionId: uuid,
        startedAt: now,
      );
      log.i('Session started: $uuid');
    } catch (e) {
      log.e('Failed to start session', error: e);
      state = state.copyWith(phase: SessionPhase.idle);
    }
  }

  void _handleData(Uint8List data, {required bool isLeft}) {
    // Write raw data to file
    if (isLeft) {
      _fileWriter?.appendLeft(data);
    } else {
      _fileWriter?.appendRight(data);
    }

    // Parse packets
    final parser = isLeft ? _parserL : _parserR;
    final tracker = isLeft ? _seqL : _seqR;
    final packets = parser.parse(data);

    for (final pkt in packets) {
      tracker.track(pkt.seq);
    }

    // Update live stats
    final stats = _liveStatsController.state;
    if (isLeft) {
      _liveStatsController.state = stats.copyWith(
        packetsL: _seqL.totalPackets,
        dropsL: _seqL.drops,
        dropRateL: _seqL.dropRate,
        lastPacketL: packets.isNotEmpty ? packets.last : stats.lastPacketL,
      );
    } else {
      _liveStatsController.state = stats.copyWith(
        packetsR: _seqR.totalPackets,
        dropsR: _seqR.drops,
        dropRateR: _seqR.dropRate,
        lastPacketR: packets.isNotEmpty ? packets.last : stats.lastPacketR,
      );
    }
  }

  void _updatePps() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastStatsTime!).inMilliseconds / 1000.0;
    if (elapsed <= 0) return;

    final stats = _liveStatsController.state;
    final ppsL = (stats.packetsL - _prevPacketsL) / elapsed;
    final ppsR = (stats.packetsR - _prevPacketsR) / elapsed;

    _liveStatsController.state = stats.copyWith(ppsL: ppsL, ppsR: ppsR);
    _prevPacketsL = stats.packetsL;
    _prevPacketsR = stats.packetsR;
    _lastStatsTime = now;
  }

  /// Stop the current recording session.
  Future<void> stopSession() async {
    if (state.phase != SessionPhase.recording) return;
    state = state.copyWith(phase: SessionPhase.stopping);

    _statsTimer?.cancel();

    // 1. Send STOP to both nodes (best effort)
    final stopCmd = Uint8List.fromList([Protocol.cmdStop]);
    try {
      if (_connInfo.leftDevice != null) {
        await _bleClient.writeCommand(_connInfo.leftDevice!.id, stopCmd);
      }
    } catch (e) {
      log.w('Failed to send STOP to L', error: e);
    }
    try {
      if (_connInfo.rightDevice != null) {
        await _bleClient.writeCommand(_connInfo.rightDevice!.id, stopCmd);
      }
    } catch (e) {
      log.w('Failed to send STOP to R', error: e);
    }

    // 2. Cancel data subscriptions
    await _leftDataSub?.cancel();
    await _rightDataSub?.cancel();

    // 3. Close files
    await _fileWriter?.close();

    // 4. Compute summary and save to DB
    final endedAt = DateTime.now();
    final durationSec = endedAt.difference(state.startedAt!).inSeconds;
    final hzL = durationSec > 0 ? _seqL.totalPackets / durationSec : 0.0;
    final hzR = durationSec > 0 ? _seqR.totalPackets / durationSec : 0.0;

    await _repo.closeSession(
      id: state.sessionId!,
      endedAt: endedAt,
      packetsLeft: _seqL.totalPackets,
      packetsRight: _seqR.totalPackets,
      dropsLeft: _seqL.drops,
      dropsRight: _seqR.drops,
      estimatedHzLeft: hzL,
      estimatedHzRight: hzR,
    );

    // Reset live stats
    _liveStatsController.state = const LiveStats();

    state = const SessionState();
    log.i('Session stopped: ${state.sessionId}');
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _leftDataSub?.cancel();
    _rightDataSub?.cancel();
    super.dispose();
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(
    bleClient: ref.watch(bleClientProvider),
    repo: ref.watch(sessionRepositoryProvider),
    liveStatsController: ref.read(liveStatsProvider.notifier),
    connInfo: ref.watch(connectionControllerProvider),
  );
});
