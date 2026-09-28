import 'package:flutter/material.dart';

import '../services/assignments_service.dart';

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
      appBar: AppBar(
        title: const Text('Volunteer Assignments'),
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
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
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _statuses.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s),
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
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No assignments match this filter.'),
                ),
              )
            else
              ...filtered.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Incident ID: ${item.incidentId}'),
                        Text('Volunteer ID: ${item.volunteerId}'),
                        Text('Duration: ${item.estimatedDurationMinutes} mins'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (item.status == 'Assigned')
                              TextButton(
                                onPressed: () => _updateStatus(item.id, 'Dispatched'),
                                child: const Text('Dispatch'),
                              ),
                            if (item.status == 'Dispatched')
                              TextButton(
                                onPressed: () => _updateStatus(item.id, 'InProgress'),
                                child: const Text('Start Work'),
                              ),
                            if (item.status == 'InProgress')
                              TextButton(
                                onPressed: () => _updateStatus(item.id, 'Completed'),
                                child: const Text('Mark Complete'),
                              ),
                            if (['Assigned', 'Dispatched', 'InProgress'].contains(item.status))
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () => _updateStatus(item.id, 'Cancelled'),
                                child: const Text('Cancel'),
                              ),
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
