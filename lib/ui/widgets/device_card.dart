import 'package:flutter/material.dart';

import '../../features/ble/domain/models.dart';

/// Card displaying a BLE device with connection state, RSSI, and action button.
class DeviceCard extends StatelessWidget {
  final BleDevice device;
  final BleConnectionState connectionState;
  final VoidCallback? onConnect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.connectionState,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connectionState == BleConnectionState.connected;
    final isConnecting = connectionState == BleConnectionState.connecting;
    final sideColor =
        device.isLeft ? const Color(0xFF00D2FF) : const Color(0xFFFF6B6B);
    final sideLabel = device.isLeft ? 'LEFT' : 'RIGHT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isConnected
              ? sideColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: isConnected ? 1.5 : 1,
        ),
        boxShadow: isConnected
            ? [
                BoxShadow(
                  color: sideColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Side indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sideColor.withValues(alpha: 0.15),
                border: Border.all(color: sideColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  device.isLeft ? 'L' : 'R',
                  style: TextStyle(
                    color: sideColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: sideColor.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          sideLabel,
                          style: TextStyle(
                            color: sideColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt,
                          size: 14, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        '${device.rssi} dBm',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBadge(connectionState),
                    ],
                  ),
                ],
              ),
            ),
            // Action button
            if (!isConnected && !isConnecting)
              IconButton(
                onPressed: onConnect,
                icon: Icon(Icons.bluetooth_connected,
                    color: sideColor, size: 28),
                tooltip: 'Connect',
              )
            else if (isConnecting)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(sideColor),
                ),
              )
            else
              Icon(Icons.check_circle, color: sideColor, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BleConnectionState state) {
    final (text, color) = switch (state) {
      BleConnectionState.connected => ('Connected', const Color(0xFF4CAF50)),
      BleConnectionState.connecting =>
        ('Connecting...', const Color(0xFFFFA726)),
      BleConnectionState.disconnecting =>
        ('Disconnecting', const Color(0xFFFFA726)),
      BleConnectionState.disconnected =>
        ('Disconnected', const Color(0xFF9E9E9E)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
