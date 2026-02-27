import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';

/// Settings screen for server URL, mock mode, scan timeout, sample rate,
/// webAppUrl, and auto-inject options.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // Development
          _buildSection(
            'Development',
            children: [
              _buildSwitch(
                icon: Icons.science,
                label: 'Mock Mode',
                subtitle: 'Simulate BLE devices without hardware',
                value: settings.mockMode,
                onChanged: (v) => ctrl.setMockMode(v),
                activeColor: const Color(0xFFFFA726),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Web App
          _buildSection(
            'Web App',
            children: [
              _buildTextField(
                icon: Icons.web,
                label: 'Web App URL',
                value: settings.webAppUrl,
                onSubmitted: (v) => ctrl.setWebAppUrl(v),
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildSwitch(
                icon: Icons.sync,
                label: 'Auto Inject to Web',
                subtitle: 'Send session data to WebView after recording',
                value: settings.enableAutoInjectToWeb,
                onChanged: (v) => ctrl.setEnableAutoInjectToWeb(v),
                activeColor: const Color(0xFF4CAF50),
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildTextField(
                icon: Icons.route,
                label: 'Post-Session Nav Path',
                value: settings.postSessionNavigatePath,
                onSubmitted: (v) => ctrl.setPostSessionNavigatePath(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Server
          _buildSection(
            'Server',
            children: [
              _buildTextField(
                icon: Icons.dns,
                label: 'Upload Base URL',
                value: settings.serverBaseUrl,
                onSubmitted: (v) => ctrl.setServerBaseUrl(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // BLE Settings
          _buildSection(
            'BLE Configuration',
            children: [
              _buildSlider(
                icon: Icons.timer,
                label: 'Scan Timeout',
                value: settings.scanTimeoutSec.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                suffix: 's',
                onChanged: (v) => ctrl.setScanTimeout(v.toInt()),
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildSlider(
                icon: Icons.speed,
                label: 'Sample Rate Request',
                value: settings.sampleRateHz.toDouble(),
                min: 50,
                max: 400,
                divisions: 7,
                suffix: 'Hz',
                onChanged: (v) => ctrl.setSampleRate(v.toInt()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App info
          Center(
            child: Text(
              'FreeForm Unified App v1.0.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildSection(String title, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = const Color(0xFF6C63FF),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return activeColor;
              return Colors.white38;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String label,
    required String value,
    required ValueChanged<String> onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onFieldSubmitted: onSubmitted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${value.toInt()}$suffix',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF6C63FF),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: const Color(0xFF6C63FF),
                    overlayColor: const Color(
                      0xFF6C63FF,
                    ).withValues(alpha: 0.2),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              Navigator.of(context).pushReplacementNamed('/sessions');
              break;
            case 2:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Devices',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Sessions'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
