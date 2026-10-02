import 'package:flutter/material.dart';

import '../models/volunteer.dart';
import '../services/volunteer_service.dart';
import '../theme/app_theme.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  List<Volunteer> _volunteers = [];

  bool _loading = true;
  String? _error;
  String? _updatingId;

  final _skillController = TextEditingController();

  final Set<String> _expandedVolunteerIds = {};

  String _availabilityFilter = 'all';
  String _certificationFilter = 'all';
  String _comfortFilter = 'all';

  String _volunteerKey(Volunteer volunteer) {
    if (volunteer.id.trim().isNotEmpty) {
      return volunteer.id;
    }

    return volunteer.email;
  }

  List<String> get _certificationOptions {
    final values = _volunteers
        .expand((volunteer) => volunteer.certifications)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  List<String> get _comfortOptions {
    final values = _volunteers
        .map((volunteer) => volunteer.comfortTier.trim())
        .where((tier) => tier.isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return values;
  }

  List<Volunteer> get _filteredVolunteers {
    final skillText = _skillController.text.trim().toLowerCase();

    return _volunteers.where((volunteer) {
      final matchesSkill =
          skillText.isEmpty ||
          volunteer.skills.any(
            (skill) => skill.toLowerCase().contains(skillText),
          );

      final matchesAvailability =
          _availabilityFilter == 'all' ||
          (_availabilityFilter == 'available' && volunteer.isAvailable) ||
          (_availabilityFilter == 'unavailable' && !volunteer.isAvailable);

      final matchesCertification =
          _certificationFilter == 'all' ||
          volunteer.certifications.contains(_certificationFilter);

      final matchesComfort =
          _comfortFilter == 'all' || volunteer.comfortTier == _comfortFilter;

      return matchesSkill &&
          matchesAvailability &&
          matchesCertification &&
          matchesComfort;
    }).toList();
  }

  bool get _hasFilters {
    return _skillController.text.trim().isNotEmpty ||
        _availabilityFilter != 'all' ||
        _certificationFilter != 'all' ||
        _comfortFilter != 'all';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await VolunteerService.getVolunteers();

      if (!mounted) return;

      setState(() {
        _volunteers = data;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load volunteers.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(Volunteer volunteer) async {
    if (_updatingId != null) {
      return;
    }

    final key = _volunteerKey(volunteer);

    setState(() {
      _updatingId = key;
      _error = null;
    });

    try {
      await VolunteerService.updateAvailability(
        volunteer.id,
        !volunteer.isAvailable,
      );

      if (!mounted) return;

      setState(() {
        _volunteers = _volunteers.map((item) {
          if (_volunteerKey(item) != key) {
            return item;
          }

          return Volunteer(
            id: item.id,
            fullName: item.fullName,
            email: item.email,
            skills: item.skills,
            isAvailable: !item.isAvailable,
            maximumActiveAssignments: item.maximumActiveAssignments,
            activeAssignments: item.activeAssignments,
            certifications: item.certifications,
            comfortTier: item.comfortTier,
            availabilityStartUtc: item.availabilityStartUtc,
            availabilityEndUtc: item.availabilityEndUtc,
          );
        }).toList();
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update volunteer availability."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingId = null;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _skillController.clear();
      _availabilityFilter = 'all';
      _certificationFilter = 'all';
      _comfortFilter = 'all';
    });
  }

  void _toggleExpanded(Volunteer volunteer) {
    final key = _volunteerKey(volunteer);

    setState(() {
      if (_expandedVolunteerIds.contains(key)) {
        _expandedVolunteerIds.remove(key);
      } else {
        _expandedVolunteerIds.add(key);
      }
    });
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
          'Volunteers',
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
        onRefresh: _load,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 18),
            _buildResultInfo(),
            const SizedBox(height: 16),
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
          'Volunteers',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Review availability, skills, certifications and current workload.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _skillController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            onChanged: (_) {
              setState(() {});
            },
            decoration: _inputDecoration(
              label: 'Skill',
              hint: 'Search skill, e.g. first aid',
              icon: Icons.search_rounded,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Availability',
                  value: _availabilityFilter,
                  items: const {
                    'all': 'All volunteers',
                    'available': 'Available',
                    'unavailable': 'Unavailable',
                  },
                  onChanged: (value) {
                    setState(() {
                      _availabilityFilter = value ?? 'all';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: 'Comfort Tier',
                  value: _comfortFilter,
                  items: {
                    'all': 'All tiers',
                    for (final tier in _comfortOptions) tier: tier,
                  },
                  onChanged: (value) {
                    setState(() {
                      _comfortFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Certification',
            value: _certificationFilter,
            items: {
              'all': 'All certifications',
              for (final certification in _certificationOptions)
                certification: certification,
            },
            onChanged: (value) {
              setState(() {
                _certificationFilter = value ?? 'all';
              });
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppTheme.textMuted, size: 20),
      filled: true,
      fillColor: AppTheme.backgroundAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppTheme.surface,
      isExpanded: true,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      iconEnabledColor: AppTheme.textMuted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
        filled: true,
        fillColor: AppTheme.backgroundAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
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
      items: items.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildResultInfo() {
    final shown = _filteredVolunteers.length;
    final total = _volunteers.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: '$shown',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: ' of $total shown'),
              ],
            ),
          ),
        ),
        const Spacer(),
        if (_hasFilters)
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear filters'),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final volunteers = _filteredVolunteers;

    if (volunteers.isEmpty) {
      return _buildEmptyState();
    }

    return Column(children: volunteers.map(_buildVolunteerCard).toList());
  }

  Widget _buildVolunteerCard(Volunteer volunteer) {
    final key = _volunteerKey(volunteer);

    final isExpanded = _expandedVolunteerIds.contains(key);

    final atCapacity =
        volunteer.maximumActiveAssignments > 0 &&
        volunteer.activeAssignments >= volunteer.maximumActiveAssignments;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteer.fullName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      volunteer.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              _buildAvailabilityButton(volunteer),
            ],
          ),

          if (volunteer.skills.isNotEmpty) ...[
            const SizedBox(height: 12),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: volunteer.skills
                  .take(4)
                  .map((skill) => _buildSkillChip(skill))
                  .toList(),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildCompactMetric(
                  'Capacity',
                  '${volunteer.activeAssignments} / '
                      '${volunteer.maximumActiveAssignments}',
                  valueColor: atCapacity
                      ? AppTheme.danger
                      : AppTheme.textPrimary,
                ),
              ),

              Expanded(
                child: _buildCompactMetric(
                  'Comfort Tier',
                  volunteer.comfortTier,
                ),
              ),

              IconButton(
                onPressed: () {
                  _toggleExpanded(volunteer);
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          if (isExpanded) ...[
            const SizedBox(height: 10),

            const Divider(color: AppTheme.border, height: 1),

            const SizedBox(height: 14),

            _buildTagSection(
              title: 'CERTIFICATIONS',
              values: volunteer.certifications,
              color: const Color(0xFFA855F7),
              emptyText: 'No certifications',
            ),

            const SizedBox(height: 16),

            _buildMetric(
              'Availability Window',
              _formatAvailabilityWindow(
                volunteer.availabilityStartUtc,
                volunteer.availabilityEndUtc,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    const color = Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAvailabilityButton(Volunteer volunteer) {
    final key = _volunteerKey(volunteer);

    final updating = _updatingId == key;

    final color = volunteer.isAvailable ? AppTheme.emerald : AppTheme.textMuted;

    return OutlinedButton(
      onPressed: updating
          ? null
          : () {
              _toggleAvailability(volunteer);
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        backgroundColor: color.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: updating
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Text(
              volunteer.isAvailable ? 'Available' : 'Unavailable',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
    );
  }

  Widget _buildTagSection({
    required String title,
    required List<String> values,
    required Color color,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            emptyText,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map((value) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCompactMetric(
    String label,
    String value, {
    Color valueColor = AppTheme.textPrimary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    String label,
    String value, {
    Color valueColor = AppTheme.textPrimary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  String _formatAvailabilityWindow(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Not specified';
    }

    final localStart = start.toLocal();
    final localEnd = end.toLocal();

    return '${_formatDate(localStart)} — '
        '${_formatDate(localEnd)}';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$year-$month-$day '
        '$hour:$minute';
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: AppTheme.textMuted,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No volunteers match the selected filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
