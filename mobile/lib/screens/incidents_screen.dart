import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

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
      setState(() => _incidents = data);
    } catch (e) {
      setState(() => _error = 'Failed to load incidents.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _advance(Incident incident, String newStatus) async {
    try {
      await IncidentService.updateStatus(incident.id, newStatus);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update the incident's status.")),
      );
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Critical':
      case 'High':
        return const Color(0xFFB3413E);
      case 'Medium':
        return const Color(0xFFB8722E);
      default:
        return const Color(0xFF2F6B4F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181F),
        title: const Text('Incidents'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.isEmpty ? 'All statuses' : s),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _statusFilter = value ?? '');
                _load();
              },
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null) Expanded(child: Center(child: Text(_error!))),
          if (!_loading && _error == null)
            Expanded(
              child: _incidents.isEmpty
                  ? const Center(child: Text('No incidents match this filter.'))
                  : ListView.builder(
                      itemCount: _incidents.length,
                      itemBuilder: (context, index) {
                        final incident = _incidents[index];
                        final nextStatus = nextIncidentStatus[incident.status];
                        final canCancel = incident.status != 'Resolved' &&
                            incident.status != 'Cancelled';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        incident.title,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _severityColor(incident.severity)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        incident.severity,
                                        style: TextStyle(
                                          color: _severityColor(incident.severity),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  incident.description,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF5B6472)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(label: Text(incident.category)),
                                    Chip(label: Text(incident.status)),
                                    if (incident.zone != null)
                                      Chip(label: Text('📍 ${incident.zone}')),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (nextStatus != null)
                                      ElevatedButton(
                                        onPressed: () => _advance(incident, nextStatus),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2F6B4F),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Mark as $nextStatus'),
                                      ),
                                    if (canCancel) ...[
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _advance(incident, 'Cancelled'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFB3413E),
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
