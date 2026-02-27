/// BLE command protocol constants.
class Protocol {
  Protocol._();

  // ── Command opcodes ──────────────────────────────────────────────
  /// START — payload: [0x01, session_id(16 bytes UUID v4 raw)]
  static const int cmdStart = 0x01;

  /// STOP — payload: [0x02]
  static const int cmdStop = 0x02;

  /// PING — payload: [0x03]
  static const int cmdPing = 0x03;

  /// SET_RATE — payload: [0x04, rate_hz(uint16 LE)]
  static const int cmdSetRate = 0x04;

  // ── IMU data packet ──────────────────────────────────────────────
  /// Fixed packet size in bytes
  static const int imuPacketSize = 19;

  /// Node-ID byte values
  static const int nodeIdLeft = 0x4C; // 'L'
  static const int nodeIdRight = 0x52; // 'R'
}
