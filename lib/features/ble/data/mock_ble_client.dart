import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../core/constants/protocol.dart';
import '../../../core/logging/log.dart';
import '../domain/ble_client.dart';
import '../domain/models.dart';

/// Mock BLE client that simulates two FreeForm nodes (FF_L, FF_R).
/// Generates realistic IMU data at ~100-200 Hz with intentional 1-2% drops.
class MockBleClient implements BleClient {
  final _adapterController = StreamController<BleAdapterState>.broadcast();
  final _rng = Random();

  // Simulated connection state per device
  final Map<String, BleConnectionState> _connectionStates = {};
  final Map<String, StreamController<BleConnectionState>> _connControllers = {};
  final Map<String, Timer> _dataTimers = {};
  final Map<String, StreamController<Uint8List>> _dataControllers = {};
  final Map<String, int> _seqCounters = {};
  final Map<String, int> _startTimestamp = {};

  bool _scanning = false;
  Timer? _scanTimer;
  StreamController<BleDevice>? _scanController;

  static const _leftId = 'mock-ff-l-001';
  static const _rightId = 'mock-ff-r-002';

  MockBleClient() {
    // Emit poweredOn immediately.
    Future.microtask(() => _adapterController.add(BleAdapterState.poweredOn));
  }

  @override
  Stream<BleAdapterState> get adapterState => _adapterController.stream;

  // ── Scanning ─────────────────────────────────────────────────────

  @override
  Stream<BleDevice> scanForDevices() {
    _scanning = true;
    _scanController = StreamController<BleDevice>();
    var tick = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!_scanning) return;
      tick++;
      // Emit left on first tick, right on second, then repeat with varying RSSI.
      if (tick % 2 == 1) {
        _scanController?.add(BleDevice(
          id: _leftId,
          name: 'FF_L',
          side: NodeSide.left,
          rssi: -45 - _rng.nextInt(20),
        ));
      } else {
        _scanController?.add(BleDevice(
          id: _rightId,
          name: 'FF_R',
          side: NodeSide.right,
          rssi: -50 - _rng.nextInt(20),
        ));
      }
    });

    _scanController!.onCancel = () {
      _scanTimer?.cancel();
      _scanning = false;
    };
    return _scanController!.stream;
  }

  @override
  void stopScan() {
    _scanning = false;
    _scanTimer?.cancel();
    _scanController?.close();
    _scanController = null;
  }

  // ── Connection ───────────────────────────────────────────────────

  @override
  Stream<BleConnectionState> connectToDevice(String deviceId) {
    final controller = StreamController<BleConnectionState>();
    _connControllers[deviceId] = controller;

    // Simulate connection delay
    controller.add(BleConnectionState.connecting);
    _connectionStates[deviceId] = BleConnectionState.connecting;

    Future.delayed(const Duration(milliseconds: 500), () {
      _connectionStates[deviceId] = BleConnectionState.connected;
      controller.add(BleConnectionState.connected);
      log.i('Mock BLE: connected to $deviceId');
    });

    return controller.stream;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _connectionStates[deviceId] = BleConnectionState.disconnected;
    _connControllers[deviceId]?.add(BleConnectionState.disconnected);
    _connControllers[deviceId]?.close();
    _connControllers.remove(deviceId);
    _dataTimers[deviceId]?.cancel();
    _dataTimers.remove(deviceId);
    _dataControllers[deviceId]?.close();
    _dataControllers.remove(deviceId);
  }

  // ── Data ─────────────────────────────────────────────────────────

  @override
  Stream<Uint8List> subscribeToData(String deviceId) {
    final controller = StreamController<Uint8List>();
    _dataControllers[deviceId] = controller;
    _seqCounters[deviceId] = 0;
    _startTimestamp[deviceId] = DateTime.now().microsecondsSinceEpoch;

    // 200Hz → 5ms interval
    _dataTimers[deviceId] = Timer.periodic(
      const Duration(milliseconds: 5),
      (_) {
        final seq = _seqCounters[deviceId]!;
        _seqCounters[deviceId] = (seq + 1) & 0xFFFF;

        // 1.5% drop rate
        if (_rng.nextInt(1000) < 15) return;

        final packet = _generateImuPacket(deviceId, seq);
        controller.add(packet);
      },
    );

    controller.onCancel = () {
      _dataTimers[deviceId]?.cancel();
      _dataTimers.remove(deviceId);
    };
    return controller.stream;
  }

  Uint8List _generateImuPacket(String deviceId, int seq) {
    final buf = Uint8List(Protocol.imuPacketSize);
    final bd = ByteData.sublistView(buf);

    // node_id
    buf[0] = deviceId == _leftId ? Protocol.nodeIdLeft : Protocol.nodeIdRight;
    // seq (uint16 LE)
    bd.setUint16(1, seq & 0xFFFF, Endian.little);
    // t_us (uint32 LE) — microseconds since START
    final elapsedUs =
        DateTime.now().microsecondsSinceEpoch - (_startTimestamp[deviceId] ?? 0);
    bd.setUint32(3, elapsedUs & 0xFFFFFFFF, Endian.little);
    // ax, ay, az, gx, gy, gz — simulate with noise around baseline
    for (var i = 0; i < 6; i++) {
      final baseline = i == 2 ? 16384 : 0; // az ≈ 1g for upright
      final noise = (_rng.nextInt(200) - 100);
      bd.setInt16(7 + i * 2, (baseline + noise).clamp(-32768, 32767), Endian.little);
    }

    return buf;
  }

  @override
  Future<void> writeCommand(String deviceId, Uint8List payload) async {
    log.i('Mock BLE: CMD write to $deviceId → ${payload.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    // no-op in mock
  }

  @override
  Future<Uint8List> readMeta(String deviceId) async {
    final side = deviceId == _leftId ? 'L' : 'R';
    final json = {
      'side': side,
      'fw': '0.1.0-mock',
      'imu': 'mpu6050',
      'sr_hz': 200,
      'battery_mv': 3800 + _rng.nextInt(500),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scanController?.close();
    _adapterController.close();
    for (final c in _connControllers.values) {
      c.close();
    }
    for (final t in _dataTimers.values) {
      t.cancel();
    }
    for (final c in _dataControllers.values) {
      c.close();
    }
  }
}
