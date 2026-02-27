import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ble/application/ble_controller.dart';
import '../../features/ble/domain/models.dart';
import '../widgets/device_card.dart';
import '../widgets/primary_button.dart';

/// Device scanning & connection screen.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanControllerProvider);
    final connInfo = ref.watch(connectionControllerProvider);
    final scanCtrl = ref.read(scanControllerProvider.notifier);
    final connCtrl = ref.read(connectionControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Connect Devices',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Scan button
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: scanState.isScanning ? 'Stop Scan' : 'Scan for Devices',
                    icon: scanState.isScanning
                        ? Icons.stop
                        : Icons.bluetooth_searching,
                    onPressed: () {
                      if (scanState.isScanning) {
                        scanCtrl.stopScan();
                      } else {
                        scanCtrl.startScan();
                      }
                    },
                    color: scanState.isScanning
                        ? const Color(0xFFEF5350)
                        : const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Scanning indicator
            if (scanState.isScanning)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Scanning... (${scanState.discoveredDevices.length} found)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Device heading
            Text(
              'Discovered Devices',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            // Device list
            Expanded(
              child: scanState.discoveredDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bluetooth_disabled,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.15)),
                          const SizedBox(height: 16),
                          Text(
                            scanState.isScanning
                                ? 'Searching for FF_L & FF_R...'
                                : 'Tap "Scan" to find devices',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: scanState.discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = scanState.discoveredDevices[index];
                        final connState = device.isLeft
                            ? connInfo.leftState
                            : connInfo.rightState;
                        return DeviceCard(
                          device: device,
                          connectionState: connState,
                          onConnect: () => connCtrl.connectDevice(device),
                        );
                      },
                    ),
            ),

            // Connection summary + continue
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // Status summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statusDot(connInfo.leftState, 'L',
                          const Color(0xFF00D2FF)),
                      const SizedBox(width: 24),
                      _statusDot(connInfo.rightState, 'R',
                          const Color(0xFFFF6B6B)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Start Session',
                    icon: Icons.play_arrow,
                    onPressed: connInfo.bothConnected
                        ? () =>
                            Navigator.of(context).pushNamed('/live_session')
                        : null,
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),

      // Bottom nav
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  Widget _statusDot(BleConnectionState state, String label, Color color) {
    final connected = state == BleConnectionState.connected;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? color : Colors.grey.shade700,
            boxShadow: connected
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${connected ? "OK" : "—"}',
          style: TextStyle(
            color: connected ? color : Colors.white38,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
              break; // Already here
            case 1:
              Navigator.of(context).pushReplacementNamed('/sessions');
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
