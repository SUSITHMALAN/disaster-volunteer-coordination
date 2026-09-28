import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../services/assignment_service.dart';

class AssignmentStatusScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentStatusScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<AssignmentStatusScreen> createState() =>
      _AssignmentStatusScreenState();
}

class _AssignmentStatusScreenState extends State<AssignmentStatusScreen> {
  late Assignment _assignment;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
  }

  List<AssignmentStatus> get _availableStatuses {
    switch (_assignment.status) {
      case AssignmentStatus.assigned:
        return [
          AssignmentStatus.dispatched,
          AssignmentStatus.cancelled,
        ];

      case AssignmentStatus.dispatched:
        return [
          AssignmentStatus.inProgress,
          AssignmentStatus.cancelled,
        ];

      case AssignmentStatus.inProgress:
        return [
          AssignmentStatus.completed,
          AssignmentStatus.cancelled,
        ];

      case AssignmentStatus.completed:
      case AssignmentStatus.cancelled:
        return [];
    }
  }

  Future<void> _updateStatus(AssignmentStatus newStatus) async {
    final confirmed = await _showConfirmationDialog(newStatus);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedAssignment =
          await AssignmentService.updateStatus(
        _assignment.id,
        newStatus,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _assignment = updatedAssignment;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${updatedAssignment.statusText}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update status: $error'),
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog(
    AssignmentStatus newStatus,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update assignment status'),
          content: Text(
            'Change status from ${_assignment.statusText} '
            'to ${_statusLabel(newStatus)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _statusLabel(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.dispatched:
        return 'Dispatched';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableStatuses = _availableStatuses;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
        title: const Text('Assignment Status'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AssignmentDetailsCard(
            assignment: _assignment,
          ),
          const SizedBox(height: 20),
          const Text(
            'Update status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2430),
            ),
          ),
          const SizedBox(height: 10),
          if (availableStatuses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFE2E5E9),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _assignment.status == AssignmentStatus.completed
                    ? 'This assignment has been completed.'
                    : 'This assignment has been cancelled.',
                style: const TextStyle(
                  color: Color(0xFF5B6472),
                ),
              ),
            )
          else
            ...availableStatuses.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _updateStatus(status),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    child: Text(_statusLabel(status)),
                  ),
                ),
              ),
            ),
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentDetailsCard extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentDetailsCard({
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Color(0xFFE2E5E9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assignment details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B2430),
                    ),
                  ),
                ),
                _StatusChip(
                  status: assignment.status,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Assignment ID',
              value: assignment.id,
            ),
            _InfoRow(
              label: 'Incident ID',
              value: assignment.incidentId,
            ),
            _InfoRow(
              label: 'Match ID',
              value: assignment.matchId,
            ),
            _InfoRow(
              label: 'Duration',
              value:
                  '${assignment.estimatedDurationMinutes} minutes',
            ),
            _InfoRow(
              label: 'Assigned',
              value: _formatDateTime(
                assignment.assignedAtUtc,
              ),
            ),
            if (assignment.dispatchedAtUtc != null)
              _InfoRow(
                label: 'Dispatched',
                value: _formatDateTime(
                  assignment.dispatchedAtUtc!,
                ),
              ),
            if (assignment.startedAtUtc != null)
              _InfoRow(
                label: 'Started',
                value: _formatDateTime(
                  assignment.startedAtUtc!,
                ),
              ),
            if (assignment.completedAtUtc != null)
              _InfoRow(
                label: 'Completed',
                value: _formatDateTime(
                  assignment.completedAtUtc!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${twoDigits(local.month)}-'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1B2430),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AssignmentStatus status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.dispatched:
        return 'Dispatched';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case AssignmentStatus.assigned:
        return const Color(0xFFEAF2FF);
      case AssignmentStatus.dispatched:
        return const Color(0xFFFFF4E5);
      case AssignmentStatus.inProgress:
        return const Color(0xFFE8F5E9);
      case AssignmentStatus.completed:
        return const Color(0xFFE6F4EA);
      case AssignmentStatus.cancelled:
        return const Color(0xFFFDECEC);
    }
  }

  Color get _textColor {
    switch (status) {
      case AssignmentStatus.assigned:
        return const Color(0xFF2457A6);
      case AssignmentStatus.dispatched:
        return const Color(0xFF9A6700);
      case AssignmentStatus.inProgress:
        return const Color(0xFF267A3D);
      case AssignmentStatus.completed:
        return const Color(0xFF1E6B35);
      case AssignmentStatus.cancelled:
        return const Color(0xFFB42318);
    }
  }
}