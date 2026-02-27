import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:freeform_ble_logger/features/session/data/session_file_writer.dart';

void main() {
  group('SessionFileWriter', () {
    late Directory tempDir;
    late String dirPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('session_writer_test_');
      dirPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates directory and files on open', () async {
      final writer = SessionFileWriter(dirPath: '$dirPath/session_01');
      await writer.open();
      expect(writer.isOpen, true);

      expect(await File('$dirPath/session_01/L.bin').exists(), true);
      expect(await File('$dirPath/session_01/R.bin').exists(), true);

      await writer.close();
    });

    test('appends data to L.bin', () async {
      final writer = SessionFileWriter(dirPath: dirPath);
      await writer.open();

      final packet = Uint8List(19);
      packet[0] = 0x4C; // 'L'
      writer.appendLeft(packet);
      writer.appendLeft(packet);
      writer.appendLeft(packet);

      await writer.close();

      final file = File('$dirPath/L.bin');
      expect(await file.length(), 19 * 3); // 57 bytes
    });

    test('appends data to R.bin', () async {
      final writer = SessionFileWriter(dirPath: dirPath);
      await writer.open();

      final packet = Uint8List(19);
      packet[0] = 0x52; // 'R'

      for (int i = 0; i < 10; i++) {
        writer.appendRight(packet);
      }

      await writer.close();

      final file = File('$dirPath/R.bin');
      expect(await file.length(), 19 * 10); // 190 bytes
    });

    test('closes without error when no data written', () async {
      final writer = SessionFileWriter(dirPath: dirPath);
      await writer.open();
      expect(writer.isOpen, true);

      await writer.close();
      expect(writer.isOpen, false);

      // Files should exist but be empty
      expect(await File('$dirPath/L.bin').length(), 0);
      expect(await File('$dirPath/R.bin').length(), 0);
    });

    test('isOpen reflects state correctly', () async {
      final writer = SessionFileWriter(dirPath: dirPath);
      expect(writer.isOpen, false);

      await writer.open();
      expect(writer.isOpen, true);

      await writer.close();
      expect(writer.isOpen, false);
    });

    test('handles large data volume', () async {
      final writer = SessionFileWriter(dirPath: dirPath);
      await writer.open();

      final packet = Uint8List(19);
      // Simulate 1000 packets (≈ 5 seconds at 200Hz)
      for (int i = 0; i < 1000; i++) {
        writer.appendLeft(packet);
        writer.appendRight(packet);
      }

      await writer.close();

      expect(await File('$dirPath/L.bin').length(), 19 * 1000);
      expect(await File('$dirPath/R.bin').length(), 19 * 1000);
    });
  });
}
