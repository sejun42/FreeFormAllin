/// BLE UUID constants — shared contract between app and firmware.
/// DO NOT change these without updating the firmware.
class BleUuids {
  BleUuids._();

  /// Custom FreeForm service UUID (128-bit)
  static const String freeformService =
      'a1b2c3d4-e5f6-47a8-9abc-1234567890ab';

  /// CMD Characteristic — Write Without Response / Write
  static const String cmdChar =
      'a1b2c3d4-e5f6-47a8-9abc-1234567890ac';

  /// DATA Characteristic — Notify (IMU packets)
  static const String dataChar =
      'a1b2c3d4-e5f6-47a8-9abc-1234567890ad';

  /// META Characteristic — Read (device info JSON)
  static const String metaChar =
      'a1b2c3d4-e5f6-47a8-9abc-1234567890ae';

  /// Expected device names during BLE scan
  static const String deviceNameLeft = 'FF_L';
  static const String deviceNameRight = 'FF_R';
}
