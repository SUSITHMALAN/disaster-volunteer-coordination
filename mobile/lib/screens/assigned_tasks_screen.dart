import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/user.dart';
import 'assignment_status_screen.dart';
import '../services/assignment_service.dart';

class AssignedTasksScreen extends StatefulWidget {
  final AppUser user;

  const AssignedTasksScreen({
    super.key,
    required this.user,
  });

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  late Future<List<Assignment>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    _assignmentsFuture = AssignmentService.getHistory(
      volunteerId: widget.user.userId,
    );
  }

  Future<void> _refreshAssignments() async {
    setState(_loadAssignments);
    await _assignmentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
        title: const Text('My Assigned Tasks'),
      ),
      body: FutureBuilder<List<Assignment>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(_loadAssignments);
              },
            );
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshAssignments,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Color(0xFF8A929D),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No assigned tasks yet.',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2430),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Pull down to refresh.',
                      style: TextStyle(
                        color: Color(0xFF5B6472),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAssignments,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _AssignmentCard(
                  assignment: assignments[index],
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AssignmentStatusScreen(
                          assignment: assignments[index],
                        ),
                      ),
                    );

                    if (mounted) {
                      setState(_loadAssignments);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
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
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF344054),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Assignment',
                      style: TextStyle(
                        fontSize: 17,
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
                label: 'Estimated duration',
                value:
                    '${assignment.estimatedDurationMinutes} minutes',
              ),
              _InfoRow(
                label: 'Assigned',
                value: _formatDateTime(
                  assignment.assignedAtUtc,
                ),
              ),
            ],
          ),
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
            width: 130,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Color(0xFF8A929D),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load assigned tasks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2430),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}