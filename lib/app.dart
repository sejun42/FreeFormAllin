import 'package:flutter/material.dart';

import 'features/session/domain/session.dart';
import 'ui/screens/devices_screen.dart';
import 'ui/screens/live_session_screen.dart';
import 'ui/screens/permissions_screen.dart';
import 'ui/screens/session_detail_screen.dart';
import 'ui/screens/sessions_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/web_shell_screen.dart';

class FreeFormApp extends StatelessWidget {
  const FreeFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreeForm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00D2FF),
          surface: Color(0xFF13132B),
          error: Color(0xFFEF5350),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _buildRoute(const PermissionsScreen(), settings);
          case '/web_shell':
            return _buildRoute(const WebShellScreen(), settings);
          case '/devices':
            return _buildRoute(const DevicesScreen(), settings);
          case '/live_session':
            return _buildRoute(const LiveSessionScreen(), settings);
          case '/sessions':
            return _buildRoute(const SessionsScreen(), settings);
          case '/session_detail':
            final session = settings.arguments as Session;
            return _buildRoute(
                SessionDetailScreen(session: session), settings);
          case '/settings':
            return _buildRoute(const SettingsScreen(), settings);
          default:
            return _buildRoute(const PermissionsScreen(), settings);
        }
      },
    );
  }

  PageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
