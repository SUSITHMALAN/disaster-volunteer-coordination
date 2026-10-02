import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../services/assignment_service.dart';
import '../services/incident_service.dart';
import '../services/volunteer_service.dart';
import '../theme/app_theme.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Assignment> _assignments = [];

  final Map<String, String> _incidentNames = {};
  final Map<String, String> _volunteerNames = {};

  bool _loading = true;
  bool _updating = false;

  String? _error;

  String _selectedStatus = 'All';

  final List<String> _statuses = [
    'All',
    'Assigned',
    'Dispatched',
    'InProgress',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assignments = await AssignmentService.getHistory();

      // Load readable incident names.
      try {
        final incidents = await IncidentService.getIncidentSummaries();

        _incidentNames.clear();

        for (final incident in incidents) {
          _incidentNames[incident.id] = incident.title;
        }
      } catch (_) {
        // Assignments can still be shown using IDs.
      }

      // Load readable volunteer names.
      try {
        final volunteers = await VolunteerService.getVolunteers();

        _volunteerNames.clear();

        for (final volunteer in volunteers) {
          _volunteerNames[volunteer.id] = volunteer.fullName;
        }
      } catch (_) {
        // Assignments can still be shown using IDs.
      }

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load assignments.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Assignment> get _filteredAssignments {
    if (_selectedStatus == 'All') {
      return _assignments;
    }

    return _assignments.where((assignment) {
      switch (_selectedStatus) {
        case 'Assigned':
          return assignment.status == AssignmentStatus.assigned;

        case 'Dispatched':
          return assignment.status == AssignmentStatus.dispatched;

        case 'InProgress':
          return assignment.status == AssignmentStatus.inProgress;

        case 'Completed':
          return assignment.status == AssignmentStatus.completed;

        case 'Cancelled':
          return assignment.status == AssignmentStatus.cancelled;

        default:
          return true;
      }
    }).toList();
  }

  int get _activeCount {
    return _assignments.where((assignment) {
      return assignment.status == AssignmentStatus.assigned ||
          assignment.status == AssignmentStatus.dispatched ||
          assignment.status == AssignmentStatus.inProgress;
    }).length;
  }

  int get _completedCount {
    return _assignments
        .where((assignment) => assignment.status == AssignmentStatus.completed)
        .length;
  }

  int get _cancelledCount {
    return _assignments
        .where((assignment) => assignment.status == AssignmentStatus.cancelled)
        .length;
  }

  Future<void> _updateStatus(
    Assignment assignment,
    AssignmentStatus status,
  ) async {
    if (_updating) return;

    setState(() {
      _updating = true;
    });

    try {
      await AssignmentService.updateStatus(assignment.id, status);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment updated successfully.')),
      );

      await _loadData();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update assignment status.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  Future<void> _confirmCancel(Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Cancel assignment?',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to cancel this assignment?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Keep Assignment'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Cancel Assignment'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _updateStatus(assignment, AssignmentStatus.cancelled);
    }
  }

  String _incidentName(Assignment assignment) {
    return _incidentNames[assignment.incidentId] ??
        'Incident ${_shortId(assignment.incidentId)}';
  }

  String _volunteerName(Assignment assignment) {
    return _volunteerNames[assignment.volunteerId] ??
        'Volunteer ${_shortId(assignment.volunteerId)}';
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.year}-$month-$day  $hour:$minute';
  }

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return AppTheme.primary;

      case AssignmentStatus.dispatched:
        return AppTheme.info;

      case AssignmentStatus.inProgress:
        return AppTheme.amber;

      case AssignmentStatus.completed:
        return AppTheme.emerald;

      case AssignmentStatus.cancelled:
        return AppTheme.danger;
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
          'Assignments',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _buildHeader(),

            const SizedBox(height: 22),

            if (!_loading && _error == null) _buildSummary(),

            if (!_loading && _error == null) const SizedBox(height: 20),

            _buildFilter(),

            const SizedBox(height: 18),

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
          'ASSIGNMENT MANAGEMENT',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Volunteer Assignments',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Track volunteer assignments and manage dispatch progress.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total',
            _assignments.length,
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard('Active', _activeCount, AppTheme.info),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            _completedCount,
            AppTheme.emerald,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Cancelled',
            _cancelledCount,
            AppTheme.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILTER STATUS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            iconEnabledColor: AppTheme.textMuted,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.backgroundAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
            items: _statuses.map((status) {
              final label = status == 'InProgress' ? 'In Progress' : status;

              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedStatus = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: AppTheme.danger, fontSize: 13),
        ),
      );
    }

    final filtered = _filteredAssignments;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 38,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'No assignments match this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(children: filtered.map(_buildAssignmentCard).toList());
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final color = _statusColor(assignment.status);

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
                  'Assignment #${_shortId(assignment.id)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              _buildStatusBadge(assignment.statusText, color),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoSection(
            label: 'INCIDENT',
            icon: Icons.warning_amber_rounded,
            value: _incidentName(assignment),
            id: assignment.incidentId,
          ),

          const SizedBox(height: 14),

          _buildInfoSection(
            label: 'VOLUNTEER',
            icon: Icons.person_outline_rounded,
            value: _volunteerName(assignment),
            id: assignment.volunteerId,
          ),

          const SizedBox(height: 16),

          const Divider(height: 1, color: AppTheme.border),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Duration',
                  '${assignment.estimatedDurationMinutes} min',
                ),
              ),
              Expanded(
                child: _buildMetric(
                  'Assigned',
                  _formatDate(assignment.assignedAtUtc),
                ),
              ),
            ],
          ),

          if (_hasActions(assignment.status)) ...[
            const SizedBox(height: 16),

            _buildActions(assignment),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String label,
    required IconData icon,
    required String value,
    required String id,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'ID: ${_shortId(id)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _hasActions(AssignmentStatus status) {
    return status == AssignmentStatus.assigned ||
        status == AssignmentStatus.dispatched ||
        status == AssignmentStatus.inProgress;
  }

  Widget _buildActions(Assignment assignment) {
    String actionText;
    AssignmentStatus nextStatus;
    Color actionColor;

    switch (assignment.status) {
      case AssignmentStatus.assigned:
        actionText = 'Dispatch';
        nextStatus = AssignmentStatus.dispatched;
        actionColor = AppTheme.primary;
        break;

      case AssignmentStatus.dispatched:
        actionText = 'Start Work';
        nextStatus = AssignmentStatus.inProgress;
        actionColor = AppTheme.info;
        break;

      case AssignmentStatus.inProgress:
        actionText = 'Mark Complete';
        nextStatus = AssignmentStatus.completed;
        actionColor = AppTheme.emerald;
        break;

      default:
        return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _updating
                ? null
                : () {
                    _updateStatus(assignment, nextStatus);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(_updating ? 'Updating...' : actionText),
          ),
        ),

        const SizedBox(width: 10),

        OutlinedButton(
          onPressed: _updating
              ? null
              : () {
                  _confirmCancel(assignment);
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.danger,
            side: const BorderSide(color: AppTheme.danger),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
