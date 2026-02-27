import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../../features/session/application/session_controller.dart';
import '../../features/session/domain/session.dart';

/// Sessions list screen showing recorded sessions.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sessions',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () => ref.invalidate(sessionsListProvider),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect devices and start recording',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return _SessionCard(
                session: sessions[index],
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/session_detail',
                    arguments: sessions[index],
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13132B),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/devices');
              break;
            case 1:
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth), label: 'Devices'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder), label: 'Sessions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = session.duration;
    final durationStr = duration != null
        ? TimeUtils.formatDuration(duration)
        : 'In progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        TimeUtils.formatDateTime(session.startedAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _uploadBadge(session.uploaded),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniStat(Icons.timer, durationStr),
                    const SizedBox(width: 16),
                    _miniStat(Icons.analytics,
                        '${session.totalPackets} pkts'),
                    const SizedBox(width: 16),
                    _miniStat(
                      Icons.warning_amber,
                      '${(session.overallDropRate * 100).toStringAsFixed(1)}%',
                      color: session.overallDropRate > 0.05
                          ? const Color(0xFFEF5350)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.white30),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color ?? Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _uploadBadge(bool uploaded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: uploaded
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
      ),
      child: Text(
        uploaded ? 'Uploaded' : 'Local',
        style: TextStyle(
          color: uploaded ? const Color(0xFF4CAF50) : Colors.white30,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
