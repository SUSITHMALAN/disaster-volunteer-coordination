import 'package:flutter/material.dart';

import '../services/assignments_service.dart';
import '../theme/app_theme.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<VolunteerAssignment> _assignments = [];
  bool _loading = true;
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
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AssignmentsService.getAssignmentHistory();
      if (mounted) {
        setState(() {
          _assignments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await AssignmentsService.updateAssignmentStatus(id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
      _loadAssignments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _assignments.where((a) {
      if (_selectedStatus == 'All') return true;
      return a.status == _selectedStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Volunteer Assignments'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadAssignments,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _statuses.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(
                    s == 'InProgress' ? 'In Progress' : s,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                ),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No assignments match this filter.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              ...filtered.map((item) {
                final displayStatus = item.status == 'InProgress' ? 'In Progress' : item.status;
                return Card(
                  color: AppTheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assignment #${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.info.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.info.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                displayStatus,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Incident GUID: ${item.incidentId}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        Text(
                          'Volunteer GUID: ${item.volunteerId}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        Text(
                          'Duration: ${item.estimatedDurationMinutes} mins',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (item.status == 'Assigned')
                              ElevatedButton(
                                onPressed: () => _updateStatus(item.id, 'Dispatched'),
                                child: const Text('Dispatch'),
                              ),
                            if (item.status == 'Dispatched')
                              ElevatedButton(
                                onPressed: () => _updateStatus(item.id, 'InProgress'),
                                child: const Text('Start Work'),
                              ),
                            if (item.status == 'InProgress')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                                onPressed: () => _updateStatus(item.id, 'Completed'),
                                child: const Text('Mark Complete'),
                              ),
                            if (['Assigned', 'Dispatched', 'InProgress'].contains(item.status)) ...[
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side: const BorderSide(color: AppTheme.danger),
                                ),
                                onPressed: () => _updateStatus(item.id, 'Cancelled'),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
