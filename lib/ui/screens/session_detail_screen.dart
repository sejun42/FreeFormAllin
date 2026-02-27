import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/time.dart';
import '../../features/session/application/session_controller.dart';
import '../../features/session/domain/session.dart';
import '../../features/upload/application/upload_controller.dart';
import '../widgets/metric_tile.dart';
import '../widgets/primary_button.dart';

/// Session detail screen with stats, export, and upload.
class SessionDetailScreen extends ConsumerWidget {
  final Session session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadControllerProvider);
    final isUploading = uploadState.uploading[session.id] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Session Detail',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Session ID
            _infoRow('Session ID', '${session.id.substring(0, 8)}...'),
            _infoRow('Started', TimeUtils.formatDateTime(session.startedAt)),
            if (session.endedAt != null)
              _infoRow('Ended', TimeUtils.formatDateTime(session.endedAt!)),
            if (session.duration != null)
              _infoRow(
                  'Duration', TimeUtils.formatDuration(session.duration!)),

            const SizedBox(height: 20),

            // Left stats
            _buildNodeSection('LEFT (FF_L)', const Color(0xFF00D2FF),
                session.packetsLeft, session.dropsLeft,
                session.estimatedHzLeft),
            const SizedBox(height: 12),

            // Right stats
            _buildNodeSection('RIGHT (FF_R)', const Color(0xFFFF6B6B),
                session.packetsRight, session.dropsRight,
                session.estimatedHzRight),

            const SizedBox(height: 20),

            // File path
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.04),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FILE PATH',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.dirPath,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upload status
            if (session.uploaded)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_done,
                        color: Color(0xFF4CAF50), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Successfully uploaded',
                      style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            if (session.uploadError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                ),
                child: Text(
                  'Upload error: ${session.uploadError}',
                  style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action buttons
            PrimaryButton(
              label: 'Upload to Server',
              icon: Icons.cloud_upload,
              isLoading: isUploading,
              onPressed: session.uploaded
                  ? null
                  : () {
                      ref
                          .read(uploadControllerProvider.notifier)
                          .uploadSession(
                            sessionId: session.id,
                            dirPath: session.dirPath,
                          );
                    },
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Export / Share',
              icon: Icons.share,
              color: const Color(0xFF00D2FF),
              onPressed: () {
                // Share the session directory path
                Share.share('FreeForm Session: ${session.dirPath}');
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeSection(
      String label, Color color, int packets, int drops, double hz) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'PACKETS',
                  value: packets.toString(),
                  icon: Icons.analytics,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricTile(
                  label: 'DROPS',
                  value: drops.toString(),
                  icon: Icons.warning_amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricTile(
                  label: 'Hz EST',
                  value: hz.toStringAsFixed(0),
                  icon: Icons.speed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Session',
            style: TextStyle(color: Colors.white)),
        content: const Text('This will delete all session data permanently.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(sessionRepositoryProvider)
                  .deleteSession(session.id);
              ref.invalidate(sessionsListProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
