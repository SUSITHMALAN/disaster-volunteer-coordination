import 'package:flutter/material.dart';

import '../services/incident_service.dart';
import '../services/matches_service.dart';
import '../models/incident_summary.dart';
import '../theme/app_theme.dart';

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
          const SnackBar(content: Text('Matching Agent triggered successfully!')),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: AppTheme.background,
        elevation: 0,
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
                    'Select an incident to view match recommendations or run the matching agent.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (_incidents.isNotEmpty)
                    DropdownButtonFormField<String>(
                      isExpanded: true, // Fix layout overflow
                      initialValue: _selectedIncidentId,
                      dropdownColor: AppTheme.surface,
                      decoration: const InputDecoration(
                        labelText: 'Select Incident',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _incidents.map((inc) {
                        return DropdownMenuItem<String>(
                          value: inc.id,
                          child: Text(
                            inc.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(color: AppTheme.textPrimary),
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
                      backgroundColor: AppTheme.primaryButton,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _triggeringAgent ? null : _triggerAgent,
                    icon: _triggeringAgent
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_triggeringAgent ? 'Running Agent...' : 'Run Matching Agent'),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.danger),
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
                        'No matches found for this incident. Tap "Run Matching Agent" above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  else
                    ..._matches.map((match) {
                      final scoreVal = match.matchScore > 1.0 ? match.matchScore : match.matchScore * 100.0;
                      final scorePercent = scoreVal.round().clamp(0, 100);
                      final displayName = match.volunteerName?.isNotEmpty == true
                          ? match.volunteerName!
                          : (match.volunteerId.length > 8 ? '${match.volunteerId.substring(0, 8)}...' : match.volunteerId);

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
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: scorePercent >= 70
                                          ? AppTheme.emerald.withOpacity(0.2)
                                          : AppTheme.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: scorePercent >= 70 ? AppTheme.emerald : AppTheme.amber,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$scorePercent% Match',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: scorePercent >= 70 ? AppTheme.emerald : AppTheme.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                match.reasoning,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundAlt,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Status: ${match.status}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _assignVolunteer(match),
                                    icon: const Icon(Icons.person_add, size: 18),
                                    label: const Text('Assign Volunteer'),
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
