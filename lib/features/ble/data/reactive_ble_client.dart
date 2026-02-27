import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;

import '../../../core/constants/uuids.dart';
import '../../../core/logging/log.dart';
import '../domain/ble_client.dart';
import '../domain/models.dart';

/// Production BLE client backed by flutter_reactive_ble.
class ReactiveBleClient implements BleClient {
  final ble.FlutterReactiveBle _ble;
  StreamSubscription<ble.DiscoveredDevice>? _scanSub;

  ReactiveBleClient() : _ble = ble.FlutterReactiveBle();

  // ── Adapter state ────────────────────────────────────────────────

  @override
  Stream<BleAdapterState> get adapterState {
    return _ble.statusStream.map(_mapStatus);
  }

  BleAdapterState _mapStatus(ble.BleStatus s) {
    switch (s) {
      case ble.BleStatus.unknown:
        return BleAdapterState.unknown;
      case ble.BleStatus.unsupported:
        return BleAdapterState.unsupported;
      case ble.BleStatus.unauthorized:
        return BleAdapterState.unauthorized;
      case ble.BleStatus.poweredOff:
        return BleAdapterState.poweredOff;
      case ble.BleStatus.ready:
        return BleAdapterState.poweredOn;
      case ble.BleStatus.locationServicesDisabled:
        return BleAdapterState.poweredOff;
    }
  }

  // ── Scanning ─────────────────────────────────────────────────────

  @override
  Stream<BleDevice> scanForDevices() {
    final controller = StreamController<BleDevice>();
    _scanSub?.cancel();
    _scanSub = _ble.scanForDevices(
      withServices: [ble.Uuid.parse(BleUuids.freeformService)],
    ).listen(
      (d) {
        final side = d.name == BleUuids.deviceNameLeft
            ? NodeSide.left
            : d.name == BleUuids.deviceNameRight
                ? NodeSide.right
                : null;
        if (side != null) {
          controller.add(BleDevice(
            id: d.id,
            name: d.name,
            side: side,
            rssi: d.rssi,
          ));
        }
      },
      onError: (e) {
        log.e('BLE scan error', error: e);
        controller.addError(e);
      },
      onDone: () => controller.close(),
    );

    controller.onCancel = () => _scanSub?.cancel();
    return controller.stream;
  }

  @override
  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }

  // ── Connection ───────────────────────────────────────────────────

  @override
  Stream<BleConnectionState> connectToDevice(String deviceId) {
    return _ble
        .connectToDevice(id: deviceId)
        .map((update) => _mapConnectionState(update.connectionState));
  }

  BleConnectionState _mapConnectionState(ble.DeviceConnectionState s) {
    switch (s) {
      case ble.DeviceConnectionState.connecting:
        return BleConnectionState.connecting;
      case ble.DeviceConnectionState.connected:
        return BleConnectionState.connected;
      case ble.DeviceConnectionState.disconnecting:
        return BleConnectionState.disconnecting;
      case ble.DeviceConnectionState.disconnected:
        return BleConnectionState.disconnected;
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    // reactive_ble auto-disconnects when the stream subscription is cancelled.
    // The controller manages subscriptions.
  }

  // ── Data ─────────────────────────────────────────────────────────

  @override
  Stream<Uint8List> subscribeToData(String deviceId) {
    final char = ble.QualifiedCharacteristic(
      serviceId: ble.Uuid.parse(BleUuids.freeformService),
      characteristicId: ble.Uuid.parse(BleUuids.dataChar),
      deviceId: deviceId,
    );
    return _ble.subscribeToCharacteristic(char).map(Uint8List.fromList);
  }

  @override
  Future<void> writeCommand(String deviceId, Uint8List payload) async {
    final char = ble.QualifiedCharacteristic(
      serviceId: ble.Uuid.parse(BleUuids.freeformService),
      characteristicId: ble.Uuid.parse(BleUuids.cmdChar),
      deviceId: deviceId,
    );
    await _ble.writeCharacteristicWithoutResponse(char, value: payload);
  }

  @override
  Future<Uint8List> readMeta(String deviceId) async {
    final char = ble.QualifiedCharacteristic(
      serviceId: ble.Uuid.parse(BleUuids.freeformService),
      characteristicId: ble.Uuid.parse(BleUuids.metaChar),
      deviceId: deviceId,
    );
    final data = await _ble.readCharacteristic(char);
    return Uint8List.fromList(data);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
  }
}
