import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:freeform_ble_logger/core/constants/protocol.dart';
import 'package:freeform_ble_logger/features/ble/application/packet_parser.dart';

void main() {
  group('PacketParser', () {
    late PacketParser parser;

    setUp(() {
      parser = PacketParser();
    });

    Uint8List buildPacket({
      int nodeId = Protocol.nodeIdLeft,
      int seq = 0,
      int tUs = 1000,
      int ax = 100,
      int ay = -200,
      int az = 16384,
      int gx = 50,
      int gy = -50,
      int gz = 0,
    }) {
      final buf = Uint8List(Protocol.imuPacketSize);
      final bd = ByteData.sublistView(buf);
      buf[0] = nodeId;
      bd.setUint16(1, seq & 0xFFFF, Endian.little);
      bd.setUint32(3, tUs & 0xFFFFFFFF, Endian.little);
      bd.setInt16(7, ax, Endian.little);
      bd.setInt16(9, ay, Endian.little);
      bd.setInt16(11, az, Endian.little);
      bd.setInt16(13, gx, Endian.little);
      bd.setInt16(15, gy, Endian.little);
      bd.setInt16(17, gz, Endian.little);
      return buf;
    }

    test('parses a single 19-byte packet', () {
      final pkt = buildPacket(nodeId: Protocol.nodeIdLeft, seq: 42, ax: 123);
      final results = parser.parse(pkt);

      expect(results.length, 1);
      expect(results[0].nodeId, Protocol.nodeIdLeft);
      expect(results[0].seq, 42);
      expect(results[0].ax, 123);
      expect(results[0].ay, -200);
      expect(results[0].az, 16384);
      expect(results[0].isLeft, true);
      expect(results[0].isRight, false);
    });

    test('parses concatenated packets', () {
      final pkt1 = buildPacket(seq: 0, ax: 1);
      final pkt2 = buildPacket(seq: 1, ax: 2);
      final combined = Uint8List(38);
      combined.setRange(0, 19, pkt1);
      combined.setRange(19, 38, pkt2);

      final results = parser.parse(combined);
      expect(results.length, 2);
      expect(results[0].seq, 0);
      expect(results[0].ax, 1);
      expect(results[1].seq, 1);
      expect(results[1].ax, 2);
    });

    test('handles partial packet and reassembly', () {
      final pkt = buildPacket(seq: 7, ax: 999);
      final part1 = Uint8List.sublistView(pkt, 0, 10);
      final part2 = Uint8List.sublistView(pkt, 10, 19);

      final results1 = parser.parse(part1);
      expect(results1.length, 0); // not enough bytes yet

      final results2 = parser.parse(part2);
      expect(results2.length, 1);
      expect(results2[0].seq, 7);
      expect(results2[0].ax, 999);
    });

    test('parses right node packet', () {
      final pkt = buildPacket(nodeId: Protocol.nodeIdRight, seq: 100);
      final results = parser.parse(pkt);

      expect(results.length, 1);
      expect(results[0].isRight, true);
      expect(results[0].nodeId, Protocol.nodeIdRight);
    });

    test('handles negative int16 values correctly', () {
      final pkt = buildPacket(ax: -32000, gy: -100);
      final results = parser.parse(pkt);

      expect(results[0].ax, -32000);
      expect(results[0].gy, -100);
    });

    test('reset clears the buffer', () {
      final pkt = buildPacket(seq: 0);
      final partial = Uint8List.sublistView(pkt, 0, 10);
      parser.parse(partial);
      parser.reset();

      // After reset, the partial should be gone
      final remaining = Uint8List.sublistView(pkt, 10, 19);
      final results = parser.parse(remaining);
      expect(results.length, 0); // 9 bytes < 19 bytes needed
    });
  });

  group('SeqTracker', () {
    late SeqTracker tracker;

    setUp(() {
      tracker = SeqTracker();
    });

    test('tracks sequential packets with no drops', () {
      for (var i = 0; i < 100; i++) {
        tracker.track(i);
      }
      expect(tracker.totalPackets, 100);
      expect(tracker.drops, 0);
      expect(tracker.dropRate, 0);
    });

    test('detects single dropped packet', () {
      tracker.track(0);
      tracker.track(1);
      tracker.track(3); // seq 2 was dropped
      expect(tracker.drops, 1);
    });

    test('detects multiple dropped packets', () {
      tracker.track(0);
      tracker.track(5); // seq 1,2,3,4 dropped
      expect(tracker.drops, 4);
      expect(tracker.totalPackets, 2);
    });

    test('handles uint16 wrap-around', () {
      tracker.track(65534);
      tracker.track(65535);
      tracker.track(0); // wrap around
      expect(tracker.drops, 0);
      expect(tracker.totalPackets, 3);
    });

    test('drop rate calculation', () {
      tracker.track(0);
      tracker.track(2); // 1 drop
      // total packets = 2, drops = 1
      expect(tracker.dropRate, closeTo(1 / 3, 0.001));
    });

    test('reset clears all counters', () {
      tracker.track(0);
      tracker.track(5);
      tracker.reset();
      expect(tracker.totalPackets, 0);
      expect(tracker.drops, 0);
      expect(tracker.dropRate, 0);
    });
  });
}
