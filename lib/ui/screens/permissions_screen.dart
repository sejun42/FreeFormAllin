import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/ble/application/ble_controller.dart';
import '../../features/ble/domain/models.dart';
import '../widgets/primary_button.dart';

/// Permissions & BLE adapter status screen.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Map<Permission, PermissionStatus> _permStatuses = {};
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _checking = true);
    final perms = _requiredPermissions;
    final statuses = <Permission, PermissionStatus>{};
    for (final p in perms) {
      statuses[p] = await p.status;
    }
    setState(() {
      _permStatuses = statuses;
      _checking = false;
    });
  }

  List<Permission> get _requiredPermissions {
    if (Platform.isAndroid) {
      return [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ];
    } else if (Platform.isIOS) {
      return [Permission.bluetooth];
    }
    return [];
  }

  Future<void> _requestPermissions() async {
    final statuses = await _requiredPermissions.request();
    setState(() => _permStatuses = statuses);
  }

  bool get _allGranted =>
      _permStatuses.isNotEmpty &&
      _permStatuses.values.every((s) => s.isGranted);

  @override
  Widget build(BuildContext context) {
    final adapterState = ref.watch(bleAdapterStateProvider);
    final isMock = ref.watch(isMockModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
                ).createShader(bounds),
                child: const Text(
                  'FreeForm',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IMU BLE Logger',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              // BLE Adapter State
              _buildSection(
                'Bluetooth Status',
                Icons.bluetooth,
                child: adapterState.when(
                  data: (state) => _buildStatusRow(
                    state == BleAdapterState.poweredOn
                        ? 'Bluetooth is ON'
                        : 'Bluetooth is ${state.name}',
                    state == BleAdapterState.poweredOn,
                  ),
                  loading: () => const Row(
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Checking...',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                  error: (e, _) => _buildStatusRow('Error: $e', false),
                ),
              ),

              const SizedBox(height: 16),

              // Mock Mode indicator
              if (isMock)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFFA726).withValues(alpha: 0.12),
                    border: Border.all(
                        color:
                            const Color(0xFFFFA726).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science,
                          color: Color(0xFFFFA726), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mock Mode is ON — using simulated BLE devices',
                          style: TextStyle(
                            color: Color(0xFFFFA726),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Permissions
              _buildSection(
                'Permissions',
                Icons.security,
                child: _checking
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          ..._permStatuses.entries.map((e) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: _buildStatusRow(
                                  _permissionLabel(e.key),
                                  e.value.isGranted,
                                ),
                              )),
                          if (isMock && _permStatuses.isEmpty)
                            _buildStatusRow(
                                'Not required in Mock Mode', true),
                        ],
                      ),
              ),

              const Spacer(),

              // Actions
              if (!_allGranted && !isMock)
                PrimaryButton(
                  label: 'Grant Permissions',
                  icon: Icons.check_circle_outline,
                  onPressed: _requestPermissions,
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Continue to FreeForm',
                icon: Icons.arrow_forward,
                onPressed:
                    (_allGranted || isMock) ? () => _navigateToWebShell() : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToWebShell() {
    Navigator.of(context).pushReplacementNamed('/web_shell');
  }

  Widget _buildSection(String title, IconData icon, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          color: ok ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _permissionLabel(Permission p) {
    if (p == Permission.bluetoothScan) return 'Bluetooth Scan';
    if (p == Permission.bluetoothConnect) return 'Bluetooth Connect';
    if (p == Permission.location) return 'Location (for BLE)';
    if (p == Permission.bluetooth) return 'Bluetooth';
    return p.toString();
  }
}
