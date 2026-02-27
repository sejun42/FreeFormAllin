/// Domain model for a recorded session.
class Session {
  final String id; // UUID
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? deviceLeftId;
  final String? deviceRightId;
  final int packetsLeft;
  final int packetsRight;
  final int dropsLeft;
  final int dropsRight;
  final double estimatedHzLeft;
  final double estimatedHzRight;
  final String dirPath;
  final bool uploaded;
  final String? uploadError;

  const Session({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.deviceLeftId,
    this.deviceRightId,
    this.packetsLeft = 0,
    this.packetsRight = 0,
    this.dropsLeft = 0,
    this.dropsRight = 0,
    this.estimatedHzLeft = 0,
    this.estimatedHzRight = 0,
    required this.dirPath,
    this.uploaded = false,
    this.uploadError,
  });

  Duration? get duration => endedAt?.difference(startedAt);

  int get totalPackets => packetsLeft + packetsRight;
  int get totalDrops => dropsLeft + dropsRight;

  double get overallDropRate {
    final total = totalPackets + totalDrops;
    return total == 0 ? 0 : totalDrops / total;
  }

  Session copyWith({
    DateTime? endedAt,
    int? packetsLeft,
    int? packetsRight,
    int? dropsLeft,
    int? dropsRight,
    double? estimatedHzLeft,
    double? estimatedHzRight,
    bool? uploaded,
    String? uploadError,
  }) {
    return Session(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      deviceLeftId: deviceLeftId,
      deviceRightId: deviceRightId,
      packetsLeft: packetsLeft ?? this.packetsLeft,
      packetsRight: packetsRight ?? this.packetsRight,
      dropsLeft: dropsLeft ?? this.dropsLeft,
      dropsRight: dropsRight ?? this.dropsRight,
      estimatedHzLeft: estimatedHzLeft ?? this.estimatedHzLeft,
      estimatedHzRight: estimatedHzRight ?? this.estimatedHzRight,
      dirPath: dirPath,
      uploaded: uploaded ?? this.uploaded,
      uploadError: uploadError ?? this.uploadError,
    );
  }
}
