/// BLE domain models — framework-agnostic.
enum BleConnectionState { disconnected, connecting, connected, disconnecting }

enum NodeSide { left, right }

class BleDevice {
  final String id;
  final String name;
  final NodeSide side;
  final int rssi;
  final BleConnectionState connectionState;

  const BleDevice({
    required this.id,
    required this.name,
    required this.side,
    this.rssi = 0,
    this.connectionState = BleConnectionState.disconnected,
  });

  BleDevice copyWith({
    String? id,
    String? name,
    NodeSide? side,
    int? rssi,
    BleConnectionState? connectionState,
  }) {
    return BleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      side: side ?? this.side,
      rssi: rssi ?? this.rssi,
      connectionState: connectionState ?? this.connectionState,
    );
  }

  bool get isLeft => side == NodeSide.left;
  bool get isRight => side == NodeSide.right;
}

/// Device metadata read from META characteristic.
class DeviceMeta {
  final String side;
  final String firmware;
  final String imu;
  final int sampleRateHz;
  final int batteryMv;

  const DeviceMeta({
    required this.side,
    required this.firmware,
    required this.imu,
    required this.sampleRateHz,
    required this.batteryMv,
  });

  factory DeviceMeta.fromJson(Map<String, dynamic> json) {
    return DeviceMeta(
      side: json['side'] as String? ?? 'U',
      firmware: json['fw'] as String? ?? '0.0.0',
      imu: json['imu'] as String? ?? 'unknown',
      sampleRateHz: json['sr_hz'] as int? ?? 200,
      batteryMv: json['battery_mv'] as int? ?? 0,
    );
  }
}

/// Global BLE adapter state.
enum BleAdapterState { unknown, resetting, unsupported, unauthorized, poweredOff, poweredOn }
