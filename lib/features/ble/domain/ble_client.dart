import 'dart:typed_data';

import 'models.dart';

/// Abstract BLE client interface — allows swapping reactive_ble ↔ blue_plus
/// or a mock implementation.
abstract class BleClient {
  /// Stream of adapter state changes.
  Stream<BleAdapterState> get adapterState;

  /// Start scanning for FreeForm devices.
  /// Yields devices as they are discovered.
  Stream<BleDevice> scanForDevices();

  /// Stop scanning.
  void stopScan();

  /// Connect to a device by [deviceId].
  /// Returns a stream of connection-state changes.
  Stream<BleConnectionState> connectToDevice(String deviceId);

  /// Disconnect from a device.
  Future<void> disconnect(String deviceId);

  /// Subscribe to DATA characteristic notifications.
  /// Returns a stream of raw byte packets.
  Stream<Uint8List> subscribeToData(String deviceId);

  /// Write a command to the CMD characteristic.
  Future<void> writeCommand(String deviceId, Uint8List payload);

  /// Read META characteristic (JSON).
  Future<Uint8List> readMeta(String deviceId);

  /// Dispose / clean-up resources.
  void dispose();
}
