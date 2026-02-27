import 'dart:typed_data';

/// Utility helpers for byte-level BLE data manipulation.
class Bytes {
  Bytes._();

  /// Read unsigned 16-bit little-endian from [data] at [offset].
  static int readUint16LE(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  /// Read unsigned 32-bit little-endian from [data] at [offset].
  static int readUint32LE(Uint8List data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  /// Read signed 16-bit little-endian from [data] at [offset].
  static int readInt16LE(Uint8List data, int offset) {
    final raw = readUint16LE(data, offset);
    return raw >= 0x8000 ? raw - 0x10000 : raw;
  }

  /// Write unsigned 16-bit little-endian into [data] at [offset].
  static void writeUint16LE(Uint8List data, int offset, int value) {
    data[offset] = value & 0xFF;
    data[offset + 1] = (value >> 8) & 0xFF;
  }

  /// Convert UUID string (hex without dashes) to 16 raw bytes.
  static Uint8List uuidStringToBytes(String uuid) {
    final hex = uuid.replaceAll('-', '');
    assert(hex.length == 32, 'UUID hex must be 32 chars');
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
