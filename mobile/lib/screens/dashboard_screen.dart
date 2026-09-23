import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'volunteers_screen.dart';
import 'resources_screen.dart';
import 'resource_reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppUser user;

  const DashboardScreen({super.key, required this.user});

  List<_DashLink> get _links {
    switch (user.role) {
      case 'Volunteer':
        return [_DashLink('My profile & availability', 'volunteers')];
      case 'Coordinator':
      case 'Admin':
        return [
          _DashLink('Volunteers', 'volunteers'),
          _DashLink('Resources & supplies', 'resources'),
          _DashLink('Resource reports', 'resource_reports'),
        ];
      default: // Requester
        return [_DashLink('Report an incident', 'incidents_new')];
    }
  }

  void _navigate(BuildContext context, String key) {
    switch (key) {
      case 'resources':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ResourcesScreen(user: user)));
        break;
      case 'resource_reports':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResourceReportsScreen(user: user)),
        );
        break;
      case 'volunteers':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const VolunteersScreen()));
        break;
      default:
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Not built yet')));
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181F),
        title: const Text('DVC'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Welcome, ${user.fullName}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Signed in as ${user.role}',
            style: const TextStyle(color: Color(0xFF5B6472), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ..._links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _navigate(context, link.key),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E5E9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    link.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B2430),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _logout(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _DashLink {
  final String label;
  final String key;
  _DashLink(this.label, this.key);
}
