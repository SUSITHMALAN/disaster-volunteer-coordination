import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../services/assignment_service.dart';

class AssignmentsScreen extends StatefulWidget {
  final String volunteerId;

  const AssignmentsScreen({
    super.key,
    required this.volunteerId,
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  late Future<List<Assignment>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    _assignmentsFuture =
        AssignmentService.getMyAssignments(widget.volunteerId);
  }

  Future<void> _refresh() async {
    setState(_loadAssignments);
    await _assignmentsFuture;
  }

  List<AssignmentStatus> _availableStatuses(AssignmentStatus current) {
    switch (current) {
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

  Future<void> _updateStatus(
    Assignment assignment,
    AssignmentStatus newStatus,
  ) async {
    try {
      await AssignmentService.updateStatus(
        assignment.id,
        newStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task status updated to ${_statusLabel(newStatus)}.',
          ),
        ),
      );

      setState(_loadAssignments);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task status: $e'),
        ),
      );
    }
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

  Color _statusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return Colors.orange;
      case AssignmentStatus.dispatched:
        return Colors.blue;
      case AssignmentStatus.inProgress:
        return Colors.indigo;
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Tasks'),
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load assigned tasks.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(_loadAssignments);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'No assigned tasks yet.',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF5B6472),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final nextStatuses =
                    _availableStatuses(assignment.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.assignment_outlined,
                              color: Color(0xFFB8722E),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Task ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  assignment.status,
                                ).withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(assignment.status),
                                style: TextStyle(
                                  color: _statusColor(
                                    assignment.status,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        _InfoRow(
                          label: 'Incident',
                          value: assignment.incidentId,
                        ),

                        const SizedBox(height: 8),

                        _InfoRow(
                          label: 'Assignment',
                          value: assignment.id,
                        ),

                        const SizedBox(height: 8),

                        _InfoRow(
                          label: 'Estimated duration',
                          value:
                              '${assignment.estimatedDurationMinutes} minutes',
                        ),

                        const SizedBox(height: 16),

                        if (nextStatuses.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<
                                AssignmentStatus>(
                              initialValue: null,
                              decoration: const InputDecoration(
                                labelText: 'Update status',
                                border: OutlineInputBorder(),
                              ),
                              items: nextStatuses.map((status) {
                                return DropdownMenuItem<
                                    AssignmentStatus>(
                                  value: status,
                                  child: Text(
                                    _statusLabel(status),
                                  ),
                                );
                              }).toList(),
                              onChanged: (status) {
                                if (status != null) {
                                  _updateStatus(
                                    assignment,
                                    status,
                                  );
                                }
                              },
                            ),
                          )
                        else
                          Text(
                            assignment.status ==
                                    AssignmentStatus.completed
                                ? 'Task completed.'
                                : 'Task cancelled.',
                            style: const TextStyle(
                              color: Color(0xFF5B6472),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5B6472),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1B2430),
            ),
          ),
        ),
      ],
    );
  }
}