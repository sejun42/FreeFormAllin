import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/log.dart';
import '../../core/utils/time.dart';
import '../../features/ble/application/ble_controller.dart';
import '../../features/session/application/session_controller.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../features/webview/data/workout_session_data_generator.dart';
import '../widgets/metric_tile.dart';
import '../widgets/primary_button.dart';
import 'web_shell_screen.dart';

/// Live recording session screen with real-time metrics.
/// After session stop, auto-injects WorkoutSessionData into WebView localStorage
/// and navigates the WebView to /workout-summary?sessionId=...
class LiveSessionScreen extends ConsumerStatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  String _workoutType = 'squat';

  @override
  void initState() {
    super.initState();
    // Auto-start session when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get workout type from route arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _workoutType = args['workoutType'] as String? ?? 'squat';
      }

      final sessionCtrl = ref.read(sessionControllerProvider.notifier);
      final phase = ref.read(sessionControllerProvider).phase;
      if (phase == SessionPhase.idle) {
        sessionCtrl.startSession();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final started = ref.read(sessionControllerProvider).startedAt;
      if (started != null) {
        setState(() {
          _elapsed = DateTime.now().difference(started);
        });
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final stats = ref.watch(liveStatsProvider);

    // Start duration timer when recording
    if (sessionState.phase == SessionPhase.recording &&
        _durationTimer == null) {
      _startDurationTimer();
    }

    final isRecording = sessionState.phase == SessionPhase.recording;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isRecording ? null : () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (isRecording) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF5350),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              isRecording ? 'Recording' : 'Session',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (_workoutType.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                ),
                child: Text(
                  _workoutType.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isRecording)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    TimeUtils.formatDuration(_elapsed),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Left node metrics
            _buildNodeMetrics(
              'LEFT (FF_L)',
              const Color(0xFF00D2FF),
              stats,
              isLeft: true,
            ),
            const SizedBox(height: 16),

            // Right node metrics
            _buildNodeMetrics(
              'RIGHT (FF_R)',
              const Color(0xFFFF6B6B),
              stats,
              isLeft: false,
            ),
            const SizedBox(height: 24),

            // Raw values
            if (isRecording) ...[_buildRawValues(stats)],

            const Spacer(),

            // Session phase indicator / Stop button
            if (sessionState.phase == SessionPhase.starting)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Starting session...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              )
            else if (sessionState.phase == SessionPhase.stopping)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Stopping & saving...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              )
            else if (isRecording)
              PrimaryButton(
                label: 'Stop Recording',
                icon: Icons.stop,
                color: const Color(0xFFEF5350),
                onPressed: () async {
                  _durationTimer?.cancel();
                  // Capture stats BEFORE stopping (they get reset)
                  final preStopStats = ref.read(liveStatsProvider);
                  final preStopState = ref.read(sessionControllerProvider);

                  // Stop the session
                  await ref
                      .read(sessionControllerProvider.notifier)
                      .stopSession();

                  // Inject into WebView using pre-stop data
                  await _onSessionStoppedWithData(preStopState, preStopStats);
                },
              )
            else
              PrimaryButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Uses pre-stop data to generate and inject session into WebView.
  Future<void> _onSessionStoppedWithData(
    SessionState preStopState,
    LiveStats preStopStats,
  ) async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableAutoInjectToWeb) {
      log.i('Auto inject disabled, skipping WebView injection');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final sessionId = preStopState.sessionId;
    final startedAt = preStopState.startedAt;

    if (sessionId == null || startedAt == null) {
      log.w('No session data available for injection');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final durationSec = DateTime.now().difference(startedAt).inSeconds;

    // 1. Generate WorkoutSessionData
    final generator = WorkoutSessionDataGenerator();
    final sessionData = generator.generate(
      sessionId: sessionId,
      workoutType: _workoutType,
      startedAt: startedAt,
      durationSec: durationSec,
      packetsL: preStopStats.packetsL,
      packetsR: preStopStats.packetsR,
      dropsL: preStopStats.dropsL,
      dropsR: preStopStats.dropsR,
    );

    log.i('Generated WorkoutSessionData for $sessionId');

    // 2. Inject into WebView localStorage
    final webController = ref.read(webViewControllerProvider);
    if (webController != null) {
      try {
        final js = generator.generateInjectionJs(sessionData);
        await webController.runJavaScript(js);
        log.i('Session data injected into WebView localStorage');

        // 3. Navigate WebView to workout-summary
        final summaryPath = settings.postSessionNavigatePath;
        final webAppUrl = settings.webAppUrl;
        final summaryUrl = '$webAppUrl$summaryPath?sessionId=$sessionId';
        await webController.loadRequest(Uri.parse(summaryUrl));
        log.i('WebView navigated to: $summaryUrl');
      } catch (e) {
        log.e('Failed to inject session data into WebView', error: e);
      }
    } else {
      log.w('WebViewController not available, skipping injection');
    }

    // 4. Pop back (will return to WebShellScreen showing workout-summary)
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildNodeMetrics(
    String label,
    Color color,
    LiveStats stats, {
    required bool isLeft,
  }) {
    final packets = isLeft ? stats.packetsL : stats.packetsR;
    final dropRate = isLeft ? stats.dropRateL : stats.dropRateR;
    final pps = isLeft ? stats.ppsL : stats.ppsR;
    final lastPkt = isLeft ? stats.lastPacketL : stats.lastPacketR;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: packets > 0 ? color : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (lastPkt != null)
                Text(
                  'seq: ${lastPkt.seq}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'PPS',
                  value: pps.toStringAsFixed(0),
                  icon: Icons.speed,
                  valueColor: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricTile(
                  label: 'PACKETS',
                  value: _formatCount(packets),
                  icon: Icons.analytics,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricTile(
                  label: 'DROP %',
                  value: '${(dropRate * 100).toStringAsFixed(1)}%',
                  icon: Icons.warning_amber,
                  valueColor: dropRate > 0.05
                      ? const Color(0xFFEF5350)
                      : dropRate > 0.01
                      ? const Color(0xFFFFA726)
                      : const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRawValues(LiveStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RAW IMU VALUES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          if (stats.lastPacketL != null)
            _rawRow('L', stats.lastPacketL!, const Color(0xFF00D2FF)),
          if (stats.lastPacketR != null) ...[
            const SizedBox(height: 6),
            _rawRow('R', stats.lastPacketR!, const Color(0xFFFF6B6B)),
          ],
          if (stats.lastPacketL == null && stats.lastPacketR == null)
            Text(
              'Waiting for data...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _rawRow(String side, dynamic pkt, Color color) {
    return Text(
      '$side: ax=${pkt.ax} ay=${pkt.ay} az=${pkt.az} gx=${pkt.gx} gy=${pkt.gy} gz=${pkt.gz}',
      style: TextStyle(
        color: color.withValues(alpha: 0.7),
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
