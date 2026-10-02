import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../theme/app_theme.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  List<Incident> _incidents = [];
  bool _loading = true;
  String? _error;

  String _statusFilter = '';
  String _severityFilter = 'All';

  static const _statusOptions = [
    '',
    'Reported',
    'Triaged',
    'Matching',
    'Assigned',
    'InProgress',
    'Resolved',
    'Cancelled',
  ];

  static const _severityOptions = ['All', 'Critical', 'High', 'Medium', 'Low'];

  List<Incident> get _filteredIncidents {
    if (_severityFilter == 'All') {
      return _incidents;
    }

    return _incidents.where((incident) {
      return incident.severity.toLowerCase() == _severityFilter.toLowerCase();
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await IncidentService.getIncidents(
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );

      if (!mounted) return;

      setState(() {
        _incidents = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load incidents.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _advance(Incident incident, String newStatus) async {
    try {
      await IncidentService.updateStatus(incident.id, newStatus);

      await _load();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update the incident's status.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Incidents',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatusFilter(),
            const SizedBox(height: 18),
            _buildSeverityFilters(),
            const SizedBox(height: 22),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INCIDENT MANAGEMENT',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Monitor and manage incidents',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Track reported incidents and update their response status.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _statusFilter,
      dropdownColor: AppTheme.surface,
      iconEnabledColor: AppTheme.textMuted,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Filter by status',
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
      items: _statusOptions
          .map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(status.isEmpty ? 'All statuses' : status),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _statusFilter = value ?? '';
        });

        _load();
      },
    );
  }

  Widget _buildSeverityFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _severityOptions.map((severity) {
          final selected = _severityFilter == severity;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(severity),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              side: BorderSide(
                color: selected ? AppTheme.primary : AppTheme.border,
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  _severityFilter = severity;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 70),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final incidents = _filteredIncidents;

    if (incidents.isEmpty) {
      return _buildEmptyState();
    }

    return Column(children: incidents.map(_buildIncidentCard).toList());
  }

  Widget _buildIncidentCard(Incident incident) {
    final nextStatus = nextIncidentStatus[incident.status];

    final canCancel =
        incident.status != 'Resolved' && incident.status != 'Cancelled';

    final location = _incidentLocation(incident);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  incident.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildBadge(incident.severity, _severityColor(incident.severity)),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            incident.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(incident.category, Icons.category_outlined),
              _buildInfoChip(incident.status, Icons.timeline_rounded),
              if (location.isNotEmpty)
                _buildInfoChip(location, Icons.location_on_outlined),
            ],
          ),

          if (nextStatus != null || canCancel) ...[
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (nextStatus != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      _advance(incident, nextStatus);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                    label: Text('Mark as ${_statusLabel(nextStatus)}'),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmCancel(incident);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 14),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: AppTheme.textMuted, size: 38),
          SizedBox(height: 12),
          Text(
            'No incidents match these filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(Incident incident) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Text(
            'Cancel incident?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel "${incident.title}"?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Keep incident',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              child: const Text('Cancel incident'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await _advance(incident, 'Cancelled');
    }
  }

  String _incidentLocation(Incident incident) {
    if (incident.zone != null && incident.zone!.trim().isNotEmpty) {
      return incident.zone!;
    }

    if (incident.address != null && incident.address!.trim().isNotEmpty) {
      return incident.address!;
    }

    return '';
  }

  String _statusLabel(String status) {
    if (status == 'InProgress') {
      return 'In Progress';
    }

    return status;
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
