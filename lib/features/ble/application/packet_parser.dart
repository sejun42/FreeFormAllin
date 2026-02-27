import 'dart:typed_data';

import '../../../core/constants/protocol.dart';
import '../../../core/utils/bytes.dart';

/// Parsed IMU sample from a 19-byte BLE packet.
class ImuPacket {
  final int nodeId; // 0x4C='L', 0x52='R'
  final int seq; // uint16 sequence number
  final int timestampUs; // uint32 microsecond counter
  final int ax, ay, az; // raw accel int16
  final int gx, gy, gz; // raw gyro  int16

  const ImuPacket({
    required this.nodeId,
    required this.seq,
    required this.timestampUs,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  bool get isLeft => nodeId == Protocol.nodeIdLeft;
  bool get isRight => nodeId == Protocol.nodeIdRight;

  @override
  String toString() =>
      'IMU(${isLeft ? "L" : "R"} seq=$seq t=$timestampUs ax=$ax ay=$ay az=$az gx=$gx gy=$gy gz=$gz)';
}

/// Packet parser with internal reassembly buffer.
/// Handles: exact 19B packets, concatenated packets, partial packets.
class PacketParser {
  final _buffer = BytesBuilder(copy: false);

  /// Parse incoming BLE data. May yield 0, 1, or more [ImuPacket]s.
  List<ImuPacket> parse(Uint8List data) {
    _buffer.add(data);
    final accumulated = _buffer.toBytes();
    final results = <ImuPacket>[];
    int offset = 0;

    while (offset + Protocol.imuPacketSize <= accumulated.length) {
      final slice = Uint8List.sublistView(
          accumulated, offset, offset + Protocol.imuPacketSize);
      results.add(_parsePacket(slice));
      offset += Protocol.imuPacketSize;
    }

    // Keep remainder in buffer
    _buffer.clear();
    if (offset < accumulated.length) {
      _buffer.add(Uint8List.sublistView(accumulated, offset));
    }

    return results;
  }

  ImuPacket _parsePacket(Uint8List p) {
    return ImuPacket(
      nodeId: p[0],
      seq: Bytes.readUint16LE(p, 1),
      timestampUs: Bytes.readUint32LE(p, 3),
      ax: Bytes.readInt16LE(p, 7),
      ay: Bytes.readInt16LE(p, 9),
      az: Bytes.readInt16LE(p, 11),
      gx: Bytes.readInt16LE(p, 13),
      gy: Bytes.readInt16LE(p, 15),
      gz: Bytes.readInt16LE(p, 17),
    );
  }

  /// Reset the internal buffer (e.g., on session stop).
  void reset() {
    _buffer.clear();
  }
}

/// Tracks sequence number gaps for a single node.
class SeqTracker {
  int _lastSeq = -1;
  int _totalPackets = 0;
  int _drops = 0;

  int get totalPackets => _totalPackets;
  int get drops => _drops;
  double get dropRate => _totalPackets == 0 ? 0 : _drops / (_totalPackets + _drops);

  void track(int seq) {
    _totalPackets++;
    if (_lastSeq >= 0) {
      final expected = (_lastSeq + 1) & 0xFFFF;
      if (seq != expected) {
        // Calculate gap, handling wrap-around
        final gap = (seq - expected) & 0xFFFF;
        if (gap < 1000) {
          // Reasonable gap — count as drops
          _drops += gap;
        }
        // Very large gap could be a reset; don't count
      }
    }
    _lastSeq = seq;
  }

  void reset() {
    _lastSeq = -1;
    _totalPackets = 0;
    _drops = 0;
  }
}
