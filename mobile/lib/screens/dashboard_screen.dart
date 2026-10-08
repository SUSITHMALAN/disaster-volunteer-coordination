import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
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

class DashboardScreen extends StatefulWidget {
  final AppUser user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();

  List<Incident> _incidents = [];
  bool _loadingIncidents = false;
  String? _incidentError;

  String _selectedSeverity = 'All';

  bool get _showIncidentMap =>
      widget.user.role == 'Admin' || widget.user.role == 'Coordinator';

  List<_DashLink> get _links {
    switch (widget.user.role) {
      case 'Volunteer':
        return [
          _DashLink(
            'My Assigned Tasks',
            'assigned_tasks',
            Icons.assignment_turned_in_outlined,
          ),
          _DashLink(
            'My Profile & Availability',
            'volunteer_profile',
            Icons.person_outline,
          ),
        ];

      case 'Coordinator':
      case 'Admin':
        return [
          _DashLink('Incidents', 'incidents', Icons.warning_amber_rounded),
          _DashLink('Volunteers', 'volunteers', Icons.people_outline),
          _DashLink('Matches', 'matches', Icons.handshake_outlined),
          _DashLink('Assignments', 'assignments', Icons.assignment_outlined),
          _DashLink(
            'Resources & Supplies',
            'resources',
            Icons.inventory_2_outlined,
          ),
          _DashLink(
            'Resource Reports',
            'resource_reports',
            Icons.bar_chart_rounded,
          ),
        ];

      default:
        return [
          _DashLink(
            'Report an Incident',
            'incidents_new',
            Icons.add_alert_outlined,
          ),
        ];
    }
  }

  List<Incident> get _incidentsWithLocation {
    return _incidents.where((incident) {
      return incident.latitude != null && incident.longitude != null;
    }).toList();
  }

  List<Incident> get _filteredIncidents {
    if (_selectedSeverity == 'All') {
      return _incidentsWithLocation;
    }

    return _incidentsWithLocation.where((incident) {
      return incident.severity.toLowerCase() == _selectedSeverity.toLowerCase();
    }).toList();
  }

  int _severityCount(String severity) {
    return _incidents.where((incident) {
      return incident.severity.toLowerCase() == severity.toLowerCase();
    }).length;
  }

  @override
  void initState() {
    super.initState();

    if (_showIncidentMap) {
      _loadIncidents();
    }
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _loadingIncidents = true;
      _incidentError = null;
    });

    try {
      final incidents = await IncidentService.getIncidents();

      if (!mounted) return;

      setState(() {
        _incidents = incidents;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _incidentError = 'Unable to load incident map data.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingIncidents = false;
        });
      }
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.danger),
              SizedBox(width: 10),
              Text(
                'Sign out?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  void _navigate(String key) {
    switch (key) {
      case 'matches':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MatchesScreen()));
        break;

      case 'assignments':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
        break;

      case 'assigned_tasks':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssignedTasksScreen(user: widget.user),
          ),
        );
        break;

      case 'volunteer_profile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VolunteerProfileScreen(user: widget.user),
          ),
        );
        break;

      case 'resources':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResourcesScreen(user: widget.user)),
        );
        break;

      case 'resource_reports':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResourceReportsScreen(user: widget.user),
          ),
        );
        break;

      case 'volunteers':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const VolunteersScreen()));
        break;

      case 'incidents':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const IncidentsScreen()));
        break;

      case 'incidents_new':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReportIncidentScreen()));
        break;
    }
  }

  void _focusFilteredIncidents(String filter) {
    final incidents = filter == 'All'
        ? _incidentsWithLocation
        : _incidentsWithLocation.where((incident) {
            return incident.severity.toLowerCase() == filter.toLowerCase();
          }).toList();

    if (incidents.isEmpty) {
      return;
    }

    if (incidents.length == 1) {
      final incident = incidents.first;

      _mapController.move(LatLng(incident.latitude!, incident.longitude!), 12);

      return;
    }

    final points = incidents.map((incident) {
      return LatLng(incident.latitude!, incident.longitude!);
    }).toList();

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(45),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _showIncidentMap ? _loadIncidents : () async {},
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              _buildWelcomeSection(),

              const SizedBox(height: 28),

              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),

              const SizedBox(height: 14),

              _buildQuickActions(),

              if (_showIncidentMap) ...[
                const SizedBox(height: 30),
                _buildIncidentMapSection(),
              ],

              const SizedBox(height: 28),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background,
      elevation: 0,
      titleSpacing: 20,
      title: const Row(
        children: [
          Text(
            'DVC',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Disaster Volunteer Coordination',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppTheme.border),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WELCOME BACK',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.user.fullName,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            widget.user.role,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.builder(
      itemCount: _links.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final link = _links[index];

        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _navigate(link.key),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(link.icon, size: 21, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      link.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncidentMapSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🗺️ Live Incident Risk Map',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Real-time geospatial monitoring',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 16),

          _buildSummaryChips(),

          const SizedBox(height: 16),

          _buildSeverityFilters(),

          const SizedBox(height: 16),

          if (_loadingIncidents)
            _buildLoadingMap()
          else if (_incidentError != null)
            _buildMapError()
          else
            _buildMap(),

          if (!_loadingIncidents && _incidentError == null) ...[
            const SizedBox(height: 18),
            _buildIncidentPreviewList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSummaryChip(
          '${_severityCount('Critical')} Critical',
          AppTheme.danger,
        ),
        _buildSummaryChip('${_severityCount('High')} High', AppTheme.primary),
        _buildSummaryChip('${_incidents.length} Total', AppTheme.textSecondary),
      ],
    );
  }

  Widget _buildSummaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSeverityFilters() {
    const filters = ['All', 'Critical', 'High', 'Medium', 'Low'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedSeverity == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedSeverity = filter;
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _focusFilteredIncidents(filter);
                });
              },
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.backgroundAlt,
              side: BorderSide(
                color: selected ? AppTheme.primary : AppTheme.border,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMap() {
    final incidents = _filteredIncidents;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(7.8731, 80.7718),
            initialZoom: 6.7,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png?key=cb1_3wna_1_dd1faf8169540033ea0e561d',
              userAgentPackageName:
                  'com.example.disaster_volunteer_coordination',
            ),

            MarkerLayer(
              markers: incidents.map((incident) {
                return Marker(
                  point: LatLng(incident.latitude!, incident.longitude!),
                  width: 38,
                  height: 38,
                  child: GestureDetector(
                    onTap: () {
                      _showIncidentDetails(incident);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _severityColor(incident.severity),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _severityColor(incident.severity)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildMapError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            _incidentError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _loadIncidents, child: const Text('Try again')),
        ],
      ),
    );
  }

  Widget _buildIncidentPreviewList() {
    final incidents = _filteredIncidents.take(4).toList();

    if (incidents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            'No incidents with map coordinates found.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INCIDENTS ON MAP',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 10),

        ...incidents.map((incident) => _buildIncidentPreview(incident)),

        const SizedBox(height: 4),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              _navigate('incidents');
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('View all incidents'),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentPreview(Incident incident) {
    final location = _incidentLocation(incident);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _mapController.move(
          LatLng(incident.latitude!, incident.longitude!),
          13,
        );

        _showIncidentDetails(incident);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _severityColor(incident.severity),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _severityColor(incident.severity)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                incident.severity,
                style: TextStyle(
                  color: _severityColor(incident.severity),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetails(Incident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                incident.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSummaryChip(
                    incident.severity,
                    _severityColor(incident.severity),
                  ),
                  _buildSummaryChip(incident.category, AppTheme.info),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _incidentLocation(incident),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  String _incidentLocation(Incident incident) {
    if (incident.address != null && incident.address!.trim().isNotEmpty) {
      return incident.address!;
    }

    if (incident.zone != null && incident.zone!.trim().isNotEmpty) {
      return incident.zone!;
    }

    return 'Location available on map';
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppTheme.danger;

      case 'high':
        return AppTheme.primary;

      case 'medium':
        return AppTheme.amber;

      case 'low':
        return const Color(0xFF3B82F6);

      default:
        return AppTheme.textMuted;
    }
  }
}

class _DashLink {
  final String label;
  final String key;
  final IconData icon;

  _DashLink(this.label, this.key, this.icon);
}
