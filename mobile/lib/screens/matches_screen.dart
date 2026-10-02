import 'package:flutter/material.dart';

import '../models/incident_summary.dart';
import '../services/incident_service.dart';
import '../services/matches_service.dart';
import '../theme/app_theme.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<IncidentSummary> _incidents = [];
  List<MatchResult> _matches = [];

  String? _selectedIncidentId;
  String? _viewedIncidentId;

  bool _loadingIncidents = true;
  bool _loadingMatches = false;
  bool _triggeringAgent = false;

  String? _updatingMatchId;
  String? _assignmentMatchId;

  int _durationMinutes = 60;
  String _durationMode = '60';

  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _loadingIncidents = true;
      _error = null;
    });

    try {
      final incidents = await IncidentService.getIncidentSummaries();

      if (!mounted) return;

      setState(() {
        _incidents = incidents;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load incidents.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingIncidents = false;
        });
      }
    }
  }

  Future<void> _viewMatches() async {
    if (_selectedIncidentId == null) {
      return;
    }

    setState(() {
      _viewedIncidentId = _selectedIncidentId;
    });

    await _loadMatches(_selectedIncidentId!);
  }

  Future<void> _loadMatches(String incidentId) async {
    setState(() {
      _loadingMatches = true;
      _error = null;
      _success = null;
    });

    try {
      final matches = await MatchesService.getMatches(incidentId);

      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      if (!mounted) return;

      setState(() {
        _matches = matches;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load matches.';
        _matches = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMatches = false;
        });
      }
    }
  }

  Future<void> _triggerAgent() async {
    if (_selectedIncidentId == null) {
      return;
    }

    setState(() {
      _triggeringAgent = true;
      _error = null;
      _success = null;
    });

    try {
      await MatchesService.triggerMatchingAgent(_selectedIncidentId!);

      if (!mounted) return;

      setState(() {
        _success = 'Matching Agent completed successfully.';
        _viewedIncidentId = _selectedIncidentId;
      });

      await _loadMatches(_selectedIncidentId!);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'Matching Agent is currently unavailable. '
            'You can still view previously saved matches.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _triggeringAgent = false;
        });
      }
    }
  }

  Future<void> _updateMatchStatus(MatchResult match, String newStatus) async {
    if (_updatingMatchId != null) {
      return;
    }

    setState(() {
      _updatingMatchId = match.id;
      _error = null;
      _success = null;
    });

    try {
      final updated = await MatchesService.updateMatchStatus(
        match.id,
        newStatus,
      );

      if (!mounted) return;

      setState(() {
        _matches = _matches.map((item) {
          if (item.id == match.id) {
            return updated;
          }

          return item;
        }).toList();

        _success = 'Match ${newStatus.toLowerCase()} successfully.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to update match status.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _updatingMatchId = null;
        });
      }
    }
  }

  void _openAssignment(MatchResult match) {
    setState(() {
      _assignmentMatchId = match.id;
      _durationMinutes = 60;
      _durationMode = '60';
      _error = null;
      _success = null;
    });
  }

  Future<void> _createAssignment(MatchResult match) async {
    if (_durationMinutes <= 0) {
      setState(() {
        _error = 'Estimated duration must be greater than 0 minutes.';
      });

      return;
    }

    setState(() {
      _updatingMatchId = match.id;
      _error = null;
      _success = null;
    });

    try {
      await MatchesService.createAssignment(
        matchId: match.id,
        estimatedDurationMinutes: _durationMinutes,
      );

      if (!mounted) return;

      setState(() {
        _assignmentMatchId = null;
        _success = 'Assignment created successfully.';
      });

      if (_viewedIncidentId != null) {
        await _loadMatches(_viewedIncidentId!);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to create assignment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _updatingMatchId = null;
        });
      }
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
          'Matches',
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
        onRefresh: () async {
          if (_viewedIncidentId != null) {
            await _loadMatches(_viewedIncidentId!);
          } else {
            await _loadIncidents();
          }
        },
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            _buildIncidentSelector(),

            const SizedBox(height: 14),

            _buildMainActions(),

            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildMessage(_error!, AppTheme.danger),
            ],

            if (_success != null) ...[
              const SizedBox(height: 16),
              _buildMessage(_success!, AppTheme.emerald),
            ],

            if (_viewedIncidentId != null) ...[
              const SizedBox(height: 24),

              _buildValidationNote(),

              const SizedBox(height: 16),

              _buildMatchesContent(),
            ],
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
          'VOLUNTEER COORDINATION',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Volunteer Matches',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Select an incident to review ranked volunteer matches and create assignments.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentSelector() {
    if (_loadingIncidents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

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
            'INCIDENT',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _selectedIncidentId,
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            iconEnabledColor: AppTheme.textMuted,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Select an incident',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
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
            items: _incidents
                .map(
                  (incident) => DropdownMenuItem(
                    value: incident.id,
                    child: Text(
                      incident.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedIncidentId = value;

                _viewedIncidentId = null;

                _matches = [];
                _error = null;
                _success = null;
              });
            },
          ),

          if (_selectedIncidentId != null) ...[
            const SizedBox(height: 12),

            Text(
              'Incident ID: '
              '$_selectedIncidentId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _selectedIncidentId == null || _loadingMatches
                ? null
                : _viewMatches,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryButton,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 19),
            label: const Text('View Matches'),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _selectedIncidentId == null || _triggeringAgent
                ? null
                : _triggerAgent,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: _triggeringAgent
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(Icons.auto_awesome, size: 19),
            label: Text(
              _triggeringAgent
                  ? 'Running Matching Agent...'
                  : 'Run Matching Agent',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppTheme.emerald, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Safety validation re-checks volunteer capacity, required skills, severity comfort tier and availability before assignment.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesContent() {
    if (_loadingMatches) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              color: AppTheme.textMuted,
              size: 38,
            ),
            SizedBox(height: 12),
            Text(
              'No saved matches found for this incident.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(
        _matches.length,
        (index) => _buildMatchCard(_matches[index], index + 1),
      ),
    );
  }

  Widget _buildMatchCard(MatchResult match, int rank) {
    final rawScore = match.matchScore > 1
        ? match.matchScore
        : match.matchScore * 100;

    final score = rawScore.round().clamp(0, 100);

    final displayName = match.volunteerName?.trim().isNotEmpty == true
        ? match.volunteerName!
        : match.volunteerId;

    final isUpdating = _updatingMatchId == match.id;

    final assignmentOpen = _assignmentMatchId == match.id;

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
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.reasoning,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _buildScoreBadge(score),

              const SizedBox(width: 8),

              _buildStatusBadge(match.status),
            ],
          ),

          if (match.status.toLowerCase() == 'proposed') ...[
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () {
                            _updateMatchStatus(match, 'Approved');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isUpdating ? 'Updating...' : 'Approve'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating
                        ? null
                        : () {
                            _updateMatchStatus(match, 'Rejected');
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],

          if (match.status.toLowerCase() == 'approved') ...[
            const SizedBox(height: 14),

            if (!assignmentOpen)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openAssignment(match);
                  },
                  icon: const Icon(Icons.assignment_add, size: 18),
                  label: const Text('Create Assignment'),
                ),
              )
            else
              _buildAssignmentForm(match),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentForm(MatchResult match) {
    final isUpdating = _updatingMatchId == match.id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTIMATED DURATION',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDurationOption('30 min', '30'),
              _buildDurationOption('1 hour', '60'),
              _buildDurationOption('2 hours', '120'),
              _buildDurationOption('Custom', 'custom'),
            ],
          ),

          if (_durationMode == 'custom') ...[
            const SizedBox(height: 12),

            TextFormField(
              initialValue: _durationMinutes.toString(),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Custom minutes'),
              onChanged: (value) {
                _durationMinutes = int.tryParse(value) ?? 0;
              },
            ),
          ],

          const SizedBox(height: 12),

          Text(
            'Selected: $_durationMinutes minutes',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () {
                          _createAssignment(match);
                        },
                  child: Text(isUpdating ? 'Creating...' : 'Confirm'),
                ),
              ),

              const SizedBox(width: 10),

              OutlinedButton(
                onPressed: isUpdating
                    ? null
                    : () {
                        setState(() {
                          _assignmentMatchId = null;
                        });
                      },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String label, String value) {
    final selected = _durationMode == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() {
          _durationMode = value;

          if (value != 'custom') {
            _durationMinutes = int.parse(value);
          }
        });
      },
    );
  }

Widget _buildScoreBadge(int score) {
    final color = score >= 70 ? AppTheme.emerald : AppTheme.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$score% Match',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'approved':
        color = AppTheme.emerald;
        break;

      case 'rejected':
        color = AppTheme.danger;
        break;

      case 'dispatched':
        color = const Color(0xFF3B82F6);
        break;

      default:
        color = AppTheme.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
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

  Widget _buildMessage(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(message, style: TextStyle(color: color, fontSize: 13)),
    );
  }
}
