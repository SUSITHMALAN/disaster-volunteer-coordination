import 'package:flutter/material.dart';

import '../services/incident_service.dart';
import '../services/matches_service.dart';
import '../models/incident_summary.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<IncidentSummary> _incidents = [];
  String? _selectedIncidentId;
  List<MatchResult> _matches = [];
  bool _loadingIncidents = true;
  bool _loadingMatches = false;
  bool _triggeringAgent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents = await IncidentService.getIncidentSummaries();
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _loadingIncidents = false;
          if (incidents.isNotEmpty) {
            _selectedIncidentId = incidents.first.id;
            _loadMatches(_selectedIncidentId!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loadingIncidents = false;
        });
      }
    }
  }

  Future<void> _loadMatches(String incidentId) async {
    setState(() {
      _loadingMatches = true;
      _error = null;
    });
    try {
      final matches = await MatchesService.getMatches(incidentId);
      if (mounted) {
        setState(() {
          _matches = matches;
          _loadingMatches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load matches: $e';
          _loadingMatches = false;
        });
      }
    }
  }

  Future<void> _triggerAgent() async {
    if (_selectedIncidentId == null) return;
    setState(() => _triggeringAgent = true);
    try {
      await MatchesService.triggerMatchingAgent(_selectedIncidentId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Matching Agent triggered successfully!')),
        );
      }
      await _loadMatches(_selectedIncidentId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Matching failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _triggeringAgent = false);
    }
  }

  Future<void> _assignVolunteer(MatchResult match) async {
    try {
      await MatchesService.createAssignment(
        incidentId: match.incidentId,
        volunteerId: match.volunteerId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteer assigned to incident!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assignment failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Volunteer Matches'),
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedIncidentId != null && !_loadingMatches
                ? () => _loadMatches(_selectedIncidentId!)
                : null,
          ),
        ],
      ),
      body: _loadingIncidents
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (_selectedIncidentId != null) {
                  await _loadMatches(_selectedIncidentId!);
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Select an incident to view AI match recommendations or run the matching agent.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5B6472)),
                  ),
                  const SizedBox(height: 16),
                  if (_incidents.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIncidentId,
                      decoration: const InputDecoration(
                        labelText: 'Select Incident',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _incidents.map((inc) {
                        return DropdownMenuItem<String>(
                          value: inc.id,
                          child: Text(
                            inc.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedIncidentId = val);
                          _loadMatches(val);
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8722E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _triggeringAgent ? null : _triggerAgent,
                    icon: _triggeringAgent
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_triggeringAgent ? 'Running AI Agent...' : 'Run AI Matching Agent'),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_loadingMatches)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No matches found for this incident. Tap "Run AI Matching Agent" above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._matches.map((match) {
                      final scorePercent = (match.matchScore * 100).round();
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
                                  Expanded(
                                    child: Text(
                                      'Volunteer: ${match.volunteerId.length > 8 ? match.volunteerId.substring(0, 8) : match.volunteerId}...',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: scorePercent >= 70 ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$scorePercent% Match',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: scorePercent >= 70 ? Colors.green.shade800 : Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Role: ${match.recommendedRole}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(match.reasoning, style: const TextStyle(color: Color(0xFF4A5568))),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _assignVolunteer(match),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Assign Volunteer'),
                                ),
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
