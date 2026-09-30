import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'assigned_tasks_screen.dart';
import 'assignments_screen.dart';
import 'incidents_screen.dart';
import 'login_screen.dart';
import 'matches_screen.dart';
import 'report_incident_screen.dart';
import 'resource_reports_screen.dart';
import 'resources_screen.dart';
import 'volunteer_profile_screen.dart';
import 'volunteers_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppUser user;

  const DashboardScreen({super.key, required this.user});

  List<_DashLink> get _links {
    switch (user.role) {
      case 'Volunteer':
        return [
          _DashLink('My Assigned Tasks', 'assigned_tasks', Icons.assignment_turned_in_outlined),
          _DashLink('My Profile & Availability', 'volunteer_profile', Icons.person_outline),
        ];
      case 'Coordinator':
      case 'Admin':
        return [
          _DashLink('Volunteers', 'volunteers', Icons.people_outline),
          _DashLink('Incidents', 'incidents', Icons.warning_amber_rounded),
          _DashLink('Matches', 'matches', Icons.handshake_outlined),
          _DashLink('Assignments', 'assignments', Icons.assignment_outlined),
          _DashLink('Resources & Supplies', 'resources', Icons.inventory_2_outlined),
          _DashLink('Resource Reports', 'resource_reports', Icons.bar_chart_rounded),
        ];
      default: // Requester
        return [
          _DashLink('Report an Incident', 'incidents_new', Icons.add_alert_outlined),
        ];
    }
  }

  void _navigate(BuildContext context, String key) {
    switch (key) {
      case 'matches':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MatchesScreen()),
        );
        break;
      case 'assignments':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
        break;
      case 'assigned_tasks':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AssignedTasksScreen(user: user)),
        );
        break;
      case 'volunteer_profile':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VolunteerProfileScreen(user: user)),
        );
        break;
      case 'resources':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResourcesScreen(user: user)),
        );
        break;
      case 'resource_reports':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResourceReportsScreen(user: user)),
        );
        break;
      case 'volunteers':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VolunteersScreen()),
        );
        break;
      case 'incidents':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const IncidentsScreen()),
        );
        break;
      case 'incidents_new':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReportIncidentScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon.')),
        );
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DVC',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Disaster Aid System',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome User Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF151E32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user.fullName}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'COORDINATION MODULES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ..._links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: AppTheme.surface,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _navigate(context, link.key),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(link.icon, color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            link.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: AppTheme.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _DashLink {
  final String label;
  final String key;
  final IconData icon;

  _DashLink(this.label, this.key, this.icon);
}
