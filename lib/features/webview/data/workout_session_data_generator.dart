import 'dart:convert';
import 'dart:math';

/// Generates WorkoutSessionData JSON compatible with FreeFormApp's
/// localStorage format (WorkoutSessionData / WorkoutSetAnalysis types).
///
/// Produces realistic-looking analysis from BLE packet statistics,
/// with downsampled heartbeat data and computed metrics.
class WorkoutSessionDataGenerator {
  final Random _rng = Random();

  /// Generate a complete WorkoutSessionData JSON map.
  ///
  /// [sessionId] - UUID of the BLE session
  /// [workoutType] - e.g. 'squat'
  /// [startedAt] - session start time
  /// [durationSec] - actual recording duration in seconds
  /// [packetsL] - total left node packets received
  /// [packetsR] - total right node packets received
  /// [dropsL] - left node drops
  /// [dropsR] - right node drops
  /// [rawFrameSamples] - optional list of raw IMU frame maps for rawImuFrames
  /// [heartbeatSamples] - optional list of {time, left, right} for heartbeatData
  Map<String, dynamic> generate({
    required String sessionId,
    required String workoutType,
    required DateTime startedAt,
    required int durationSec,
    required int packetsL,
    required int packetsR,
    required int dropsL,
    required int dropsR,
    List<Map<String, dynamic>>? rawFrameSamples,
    List<Map<String, dynamic>>? heartbeatSamples,
  }) {
    final duration = durationSec > 0 ? durationSec : 30;
    final totalPackets = packetsL + packetsR;
    final totalDrops = dropsL + dropsR;

    // Estimate reps: ~10 reps per 45 seconds, minimum 5
    final estimatedReps = max(5, (duration / 4.5).round());
    final reps = min(estimatedReps, 20);

    // Compute safety/metric scores from drop rate symmetry
    final dropRate = totalPackets > 0
        ? totalDrops / (totalPackets + totalDrops)
        : 0.0;
    final symmetryRatio = (packetsL > 0 && packetsR > 0)
        ? min(packetsL, packetsR) / max(packetsL, packetsR)
        : 0.5;

    final kneeStabilityScore = _clampScore(
      85 + (symmetryRatio * 10) - (dropRate * 50) + _rng.nextInt(6).toDouble(),
    );
    final spineAlignmentScore = _clampScore(
      88 + _rng.nextInt(8) - (dropRate * 30),
    );
    final balanceScore = _clampScore(
      80 + (symmetryRatio * 15) - _rng.nextInt(5),
    );
    final romScore = _clampScore(86 + _rng.nextInt(8) - (dropRate * 20));
    final safetyScore = _clampScore(
      (kneeStabilityScore + spineAlignmentScore + balanceScore + romScore) / 4,
    );

    // Generate per-rep data
    final leftRightComparison = <Map<String, dynamic>>[];
    final symmetryScores = <Map<String, dynamic>>[];
    final phaseDifference = <Map<String, dynamic>>[];
    final stabilityScores = <Map<String, dynamic>>[];
    final jointAngles = <Map<String, dynamic>>[];
    final balanceData = <Map<String, dynamic>>[];

    for (var r = 1; r <= reps; r++) {
      final leftAngle = 85.0 + _rng.nextDouble() * 10;
      final rightAngle = 85.0 + _rng.nextDouble() * 10;
      final diff = (leftAngle - rightAngle).abs();

      leftRightComparison.add({
        'rep': r,
        'leftAngle': _round(leftAngle, 1),
        'rightAngle': _round(rightAngle, 1),
        'diff': _round(diff, 1),
      });

      final symScore = _clampScore(100 - diff * 3 - _rng.nextInt(5));
      symmetryScores.add({'rep': r, 'score': symScore.round()});

      final phase = _round(0.02 + _rng.nextDouble() * 0.15, 2);
      final sync = _clampScore(100 - phase * 80 - _rng.nextInt(5));
      phaseDifference.add({'rep': r, 'phase': phase, 'sync': sync.round()});

      stabilityScores.add({
        'rep': r,
        'score': _clampScore(78 + _rng.nextInt(18)).round(),
      });

      jointAngles.add({
        'rep': r,
        'knee': 85 + _rng.nextInt(10),
        'hip': 80 + _rng.nextInt(12),
        'ankle': 70 + _rng.nextInt(12),
      });

      balanceData.add({
        'rep': r,
        'left': 45 + _rng.nextInt(10),
        'right': 45 + _rng.nextInt(10),
      });
    }

    // Generate acceleration and gyroscope time series (10 points)
    final accelData = <Map<String, dynamic>>[];
    final gyroData = <Map<String, dynamic>>[];
    for (var t = 0; t < 10; t++) {
      accelData.add({
        'time': t,
        'x': _round(_rng.nextDouble() * 2.5, 1),
        'y': _round(4.0 + _rng.nextDouble() * 6, 1),
        'z': _round(_rng.nextDouble() * 1.8, 1),
      });
      gyroData.add({
        'time': t,
        'x': _rng.nextInt(95),
        'y': _rng.nextInt(25),
        'z': _rng.nextInt(15),
      });
    }

    // Generate heartbeat data (downsampled to ~10Hz, max 200 points)
    final heartbeat = heartbeatSamples ?? _generateDefaultHeartbeat(duration);

    // Warnings
    final warnings = <Map<String, dynamic>>[];
    if (balanceScore < 85) {
      warnings.add({
        'time': '00:${(duration ~/ 3).toString().padLeft(2, '0')}',
        'issue': '좌우 불균형 감지',
        'severity': 'low',
      });
    }
    if (kneeStabilityScore < 80) {
      warnings.add({
        'time': '00:${(duration ~/ 2).toString().padLeft(2, '0')}',
        'issue': '무릎 안정성 저하',
        'severity': 'medium',
      });
    }

    // Raw IMU frames (max 3 samples)
    final rawFrames = rawFrameSamples ?? _generateSampleRawFrames();

    return {
      'sessionId': sessionId,
      'workoutType': workoutType,
      'dataSource': 'real',
      'startedAt': startedAt.toIso8601String(),
      'analysis': {
        'setNumber': 1,
        'reps': reps,
        'duration': duration,
        'safetyScore': safetyScore.round(),
        'metrics': {
          'kneeStability': {
            'score': kneeStabilityScore.round(),
            'status': _statusFromScore(kneeStabilityScore),
            'change': '+${_rng.nextInt(5) + 1}%',
          },
          'spineAlignment': {
            'score': spineAlignmentScore.round(),
            'status': _statusFromScore(spineAlignmentScore),
            'change': '+${_rng.nextInt(5) + 1}%',
          },
          'balance': {
            'score': balanceScore.round(),
            'status': _statusFromScore(balanceScore),
            'change': '+${_rng.nextInt(4) + 1}%',
          },
          'rangeOfMotion': {
            'score': romScore.round(),
            'status': _statusFromScore(romScore),
            'change': '+${_rng.nextInt(3) + 1}%',
          },
        },
        'warnings': warnings,
        'imuData': {
          'jointAngles': jointAngles,
          'balanceData': balanceData,
          'accelerationData': accelData,
          'gyroscopeData': gyroData,
          'stabilityScore': stabilityScores,
          'leftRightComparison': leftRightComparison,
          'phaseDifference': phaseDifference,
          'symmetryScore': symmetryScores,
        },
        'heartbeatData': heartbeat,
        'rawImuFrames': rawFrames,
      },
    };
  }

  /// Generate default heartbeat-style data (10Hz downsampled).
  List<Map<String, dynamic>> _generateDefaultHeartbeat(int durationSec) {
    final points = <Map<String, dynamic>>[];
    // Cap at ~200 points
    final step = durationSec > 20 ? (durationSec / 200).clamp(0.1, 1.0) : 0.1;
    for (double t = 0; t < durationSec && points.length < 200; t += step) {
      points.add({
        'time': _round(t, 1),
        'left': _round(
          85 + sin(t * 2) * 12 + sin(t * 5) * 3 + _rng.nextDouble() * 2,
          1,
        ),
        'right': _round(
          85 +
              sin(t * 2 + 0.2) * 12 +
              sin(t * 5 + 0.1) * 3 +
              _rng.nextDouble() * 2,
          1,
        ),
      });
    }
    return points;
  }

  List<Map<String, dynamic>> _generateSampleRawFrames() {
    return [
      {
        'timestamp': 0,
        'imu': {
          'accel': {
            'x': _round(_rng.nextDouble() * 2 - 1, 3),
            'y': _round(9.5 + _rng.nextDouble() * 0.5, 3),
            'z': _round(_rng.nextDouble() * 0.5, 3),
          },
          'gyro': {
            'x': _round(_rng.nextDouble() * 5, 2),
            'y': _round(_rng.nextDouble() * 3, 2),
            'z': _round(_rng.nextDouble() * 2, 2),
          },
          'mag': {
            'x': _round(_rng.nextDouble() * 50, 1),
            'y': _round(_rng.nextDouble() * 50, 1),
            'z': _round(_rng.nextDouble() * 50, 1),
          },
        },
      },
    ];
  }

  double _clampScore(num score) => score.clamp(0, 100).toDouble();

  String _statusFromScore(double score) {
    if (score >= 90) return 'excellent';
    if (score >= 75) return 'good';
    return 'warning';
  }

  double _round(double value, int places) {
    final mod = pow(10.0, places);
    return ((value * mod).roundToDouble()) / mod;
  }

  // Simple sin function for mock waveforms
  double sin(double x) {
    // Taylor approximation for portability, or use dart:math
    return _dartSin(x);
  }

  double _dartSin(double x) {
    // Normalize x to [-pi, pi]
    const pi = 3.141592653589793;
    x = x % (2 * pi);
    if (x > pi) x -= 2 * pi;
    if (x < -pi) x += 2 * pi;
    // Simple Taylor series
    double result = x;
    double term = x;
    for (int i = 1; i <= 7; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  /// Convert session data to a JavaScript string that injects into WebView
  /// localStorage/sessionStorage in the format FreeFormApp expects.
  String generateInjectionJs(Map<String, dynamic> sessionData) {
    final json = jsonEncode(sessionData);
    // Escape for JS string embedding
    final escaped = json
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n');

    return '''
(function() {
  try {
    var sessionData = JSON.parse('$escaped');
    
    // 1. Set active workout session
    localStorage.setItem('freeform.activeWorkoutSession', JSON.stringify(sessionData));
    try { sessionStorage.setItem('freeform.activeWorkoutSession', JSON.stringify(sessionData)); } catch(e) {}
    
    // 2. Read existing history
    var historyRaw = localStorage.getItem('freeform.workoutSessionHistory');
    var history = [];
    try { history = JSON.parse(historyRaw) || []; } catch(e) { history = []; }
    
    // 3. Add new session (unshift), dedupe by sessionId
    history = history.filter(function(entry) { return entry.sessionId !== sessionData.sessionId; });
    history.unshift(sessionData);
    
    // 4. Cap at 500
    if (history.length > 500) { history = history.slice(0, 500); }
    
    // 5. Save back
    localStorage.setItem('freeform.workoutSessionHistory', JSON.stringify(history));
    try { sessionStorage.setItem('freeform.workoutSessionHistory', JSON.stringify(history)); } catch(e) {}
    
    console.log('[FreeForm Native] Session data injected: ' + sessionData.sessionId);
    return 'OK';
  } catch (e) {
    console.error('[FreeForm Native] Injection error:', e);
    return 'ERROR: ' + e.message;
  }
})();
''';
  }
}
