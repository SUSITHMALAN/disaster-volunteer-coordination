import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DvcApp());
}

class DvcApp extends StatelessWidget {
  const DvcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Volunteer Coordination',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // For now, always send to Login even if a token exists —
        // full session restore (fetching the stored user) can be added next.
        return const LoginScreen();
      },
    );
  }
}