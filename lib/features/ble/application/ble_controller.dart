import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/log.dart';
import '../data/mock_ble_client.dart';
import '../data/reactive_ble_client.dart';
import '../domain/ble_client.dart';
import '../domain/models.dart';
import 'packet_parser.dart';

// ── BLE Client Provider ──────────────────────────────────────────

final isMockModeProvider = StateProvider<bool>((ref) => true);

final bleClientProvider = Provider<BleClient>((ref) {
  final isMock = ref.watch(isMockModeProvider);
  final client = isMock ? MockBleClient() : ReactiveBleClient();
  ref.onDispose(() => client.dispose());
  return client;
});

// ── Adapter State ────────────────────────────────────────────────

final bleAdapterStateProvider = StreamProvider<BleAdapterState>((ref) {
  final client = ref.watch(bleClientProvider);
  return client.adapterState;
});

// ── Scan State ───────────────────────────────────────────────────

class ScanState {
  final bool isScanning;
  final List<BleDevice> discoveredDevices;

  const ScanState({
    this.isScanning = false,
    this.discoveredDevices = const [],
  });

  ScanState copyWith({bool? isScanning, List<BleDevice>? discoveredDevices}) {
    return ScanState(
      isScanning: isScanning ?? this.isScanning,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  final BleClient _client;
  StreamSubscription<BleDevice>? _scanSub;

  ScanController(this._client) : super(const ScanState());

  void startScan() {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, discoveredDevices: []);
    _scanSub = _client.scanForDevices().listen(
      (device) {
        // Update or add device
        final devices = List<BleDevice>.from(state.discoveredDevices);
        final idx = devices.indexWhere((d) => d.id == device.id);
        if (idx >= 0) {
          devices[idx] = device;
        } else {
          devices.add(device);
        }
        state = state.copyWith(discoveredDevices: devices);
      },
      onError: (e) {
        log.e('Scan error', error: e);
        state = state.copyWith(isScanning: false);
      },
    );
  }

  void stopScan() {
    _scanSub?.cancel();
    _client.stopScan();
    state = state.copyWith(isScanning: false);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }
}

final scanControllerProvider =
    StateNotifierProvider<ScanController, ScanState>((ref) {
  final client = ref.watch(bleClientProvider);
  return ScanController(client);
});

// ── Connection State ─────────────────────────────────────────────

class DeviceConnectionInfo {
  final BleDevice? leftDevice;
  final BleDevice? rightDevice;
  final BleConnectionState leftState;
  final BleConnectionState rightState;

  const DeviceConnectionInfo({
    this.leftDevice,
    this.rightDevice,
    this.leftState = BleConnectionState.disconnected,
    this.rightState = BleConnectionState.disconnected,
  });

  DeviceConnectionInfo copyWith({
    BleDevice? leftDevice,
    BleDevice? rightDevice,
    BleConnectionState? leftState,
    BleConnectionState? rightState,
  }) {
    return DeviceConnectionInfo(
      leftDevice: leftDevice ?? this.leftDevice,
      rightDevice: rightDevice ?? this.rightDevice,
      leftState: leftState ?? this.leftState,
      rightState: rightState ?? this.rightState,
    );
  }

  bool get bothConnected =>
      leftState == BleConnectionState.connected &&
      rightState == BleConnectionState.connected;
}

class ConnectionController extends StateNotifier<DeviceConnectionInfo> {
  final BleClient _client;
  StreamSubscription<BleConnectionState>? _leftConnSub;
  StreamSubscription<BleConnectionState>? _rightConnSub;

  ConnectionController(this._client) : super(const DeviceConnectionInfo());

  void connectDevice(BleDevice device) {
    if (device.isLeft) {
      state = state.copyWith(
        leftDevice: device,
        leftState: BleConnectionState.connecting,
      );
      _leftConnSub?.cancel();
      _leftConnSub = _client.connectToDevice(device.id).listen(
        (connState) {
          state = state.copyWith(leftState: connState);
        },
        onError: (e) {
          log.e('Left connection error', error: e);
          state = state.copyWith(leftState: BleConnectionState.disconnected);
        },
      );
    } else {
      state = state.copyWith(
        rightDevice: device,
        rightState: BleConnectionState.connecting,
      );
      _rightConnSub?.cancel();
      _rightConnSub = _client.connectToDevice(device.id).listen(
        (connState) {
          state = state.copyWith(rightState: connState);
        },
        onError: (e) {
          log.e('Right connection error', error: e);
          state = state.copyWith(rightState: BleConnectionState.disconnected);
        },
      );
    }
  }

  Future<void> disconnectAll() async {
    _leftConnSub?.cancel();
    _rightConnSub?.cancel();
    if (state.leftDevice != null) {
      await _client.disconnect(state.leftDevice!.id);
    }
    if (state.rightDevice != null) {
      await _client.disconnect(state.rightDevice!.id);
    }
    state = const DeviceConnectionInfo();
  }

  @override
  void dispose() {
    _leftConnSub?.cancel();
    _rightConnSub?.cancel();
    super.dispose();
  }
}

final connectionControllerProvider =
    StateNotifierProvider<ConnectionController, DeviceConnectionInfo>((ref) {
  final client = ref.watch(bleClientProvider);
  return ConnectionController(client);
});

// ── Live Session Data ────────────────────────────────────────────

class LiveStats {
  final int packetsL;
  final int packetsR;
  final int dropsL;
  final int dropsR;
  final double dropRateL;
  final double dropRateR;
  final ImuPacket? lastPacketL;
  final ImuPacket? lastPacketR;
  final double ppsL; // packets per second
  final double ppsR;

  const LiveStats({
    this.packetsL = 0,
    this.packetsR = 0,
    this.dropsL = 0,
    this.dropsR = 0,
    this.dropRateL = 0,
    this.dropRateR = 0,
    this.lastPacketL,
    this.lastPacketR,
    this.ppsL = 0,
    this.ppsR = 0,
  });

  LiveStats copyWith({
    int? packetsL,
    int? packetsR,
    int? dropsL,
    int? dropsR,
    double? dropRateL,
    double? dropRateR,
    ImuPacket? lastPacketL,
    ImuPacket? lastPacketR,
    double? ppsL,
    double? ppsR,
  }) {
    return LiveStats(
      packetsL: packetsL ?? this.packetsL,
      packetsR: packetsR ?? this.packetsR,
      dropsL: dropsL ?? this.dropsL,
      dropsR: dropsR ?? this.dropsR,
      dropRateL: dropRateL ?? this.dropRateL,
      dropRateR: dropRateR ?? this.dropRateR,
      lastPacketL: lastPacketL ?? this.lastPacketL,
      lastPacketR: lastPacketR ?? this.lastPacketR,
      ppsL: ppsL ?? this.ppsL,
      ppsR: ppsR ?? this.ppsR,
    );
  }
}

final liveStatsProvider = StateProvider<LiveStats>((ref) => const LiveStats());
