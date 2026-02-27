import 'dart:io';
import 'dart:typed_data';

import '../../../core/logging/log.dart';

/// Writes raw BLE notify payloads to binary files (L.bin, R.bin).
/// Each payload is appended as-is (19 bytes per IMU packet).
class SessionFileWriter {
  final String dirPath;
  IOSink? _leftSink;
  IOSink? _rightSink;
  bool _isOpen = false;

  SessionFileWriter({required this.dirPath});

  bool get isOpen => _isOpen;

  /// Open the session directory and create/open L.bin and R.bin.
  Future<void> open() async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final leftFile = File('$dirPath/L.bin');
    final rightFile = File('$dirPath/R.bin');

    _leftSink = leftFile.openWrite(mode: FileMode.append);
    _rightSink = rightFile.openWrite(mode: FileMode.append);
    _isOpen = true;
    log.i('SessionFileWriter: opened at $dirPath');
  }

  /// Append raw packet data for the left node.
  void appendLeft(Uint8List data) {
    _leftSink?.add(data);
  }

  /// Append raw packet data for the right node.
  void appendRight(Uint8List data) {
    _rightSink?.add(data);
  }

  /// Flush and close both files.
  Future<void> close() async {
    try {
      await _leftSink?.flush();
      await _leftSink?.close();
    } catch (e) {
      log.e('Error closing L.bin', error: e);
    }
    try {
      await _rightSink?.flush();
      await _rightSink?.close();
    } catch (e) {
      log.e('Error closing R.bin', error: e);
    }
    _leftSink = null;
    _rightSink = null;
    _isOpen = false;
    log.i('SessionFileWriter: closed');
  }
}
