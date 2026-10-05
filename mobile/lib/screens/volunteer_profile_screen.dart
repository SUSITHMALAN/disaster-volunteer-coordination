import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/volunteer.dart';
import '../services/volunteer_service.dart';
import '../theme/app_theme.dart';

class VolunteerProfileScreen extends StatefulWidget {
  final AppUser user;

  const VolunteerProfileScreen({super.key, required this.user});

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  bool _loading = true;
  bool _updating = false;
  String? _error;
  String? _success;
  Volunteer? _volunteerProfile;

  late bool _isAvailable;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _isAvailable = true;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await VolunteerService.getVolunteerById(widget.user.userId);
      if (profile != null) {
        setState(() {
          _volunteerProfile = profile;
          _isAvailable = profile.isAvailable;
          _skills = List.from(profile.skills);
        });
      } else {
        // Fallback default if API returns null
        setState(() {
          _volunteerProfile = Volunteer(
            id: widget.user.userId,
            fullName: widget.user.fullName,
            email: widget.user.email,
            skills: ['first-aid', 'driving', 'logistics'],
            isAvailable: true,
          );
          _isAvailable = true;
          _skills = ['first-aid', 'driving', 'logistics'];
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not load profile details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() {
      _isAvailable = value;
      _updating = true;
      _success = null;
      _error = null;
    });

    try {
      await VolunteerService.updateAvailability(widget.user.userId, value);
      setState(() {
        _success = value
            ? 'Your status is now marked as AVAILABLE for dispatches.'
            : 'Your status is now marked as UNAVAILABLE.';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to update availability status.';
        _isAvailable = !value; // Revert on failure
      });
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  Future<void> _removeSkill(String skill) async {
    setState(() {
      _skills.remove(skill);
    });
    await _saveSkills();
  }

  Future<void> _saveSkills() async {
    try {
      await VolunteerService.updateProfile(widget.user.userId, _skills, _isAvailable);
      setState(() => _success = 'Profile skills updated successfully.');
    } catch (_) {
      setState(() => _error = 'Failed to update skills.');
    }
  }

  Future<void> _showAddSkillDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Skill', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. medical, search-rescue, boat-driver',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSkill = controller.text.trim();
              if (newSkill.isNotEmpty && !_skills.contains(newSkill)) {
                setState(() => _skills.add(newSkill));
                _saveSkills();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _volunteerProfile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'My Profile & Availability',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. User Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          widget.user.fullName.isNotEmpty
                              ? widget.user.fullName[0].toUpperCase()
                              : 'V',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'REGISTERED VOLUNTEER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Success / Error Alerts
                if (_success != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _success!,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Availability Switch Card
                Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_isAvailable ? AppTheme.emerald : AppTheme.textMuted)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isAvailable
                                ? Icons.check_circle_rounded
                                : Icons.do_not_disturb_on_rounded,
                            color: _isAvailable ? AppTheme.emerald : AppTheme.textMuted,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dispatch Availability',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isAvailable
                                    ? 'Available for emergency dispatch'
                                    : 'Currently unavailable for new tasks',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isAvailable ? AppTheme.emerald : AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAvailable,
                          activeThumbColor: AppTheme.emerald,
                          onChanged: _updating ? null : _toggleAvailability,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Workload Capacity Card
                Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.assignment_ind_outlined,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Workload Capacity & Active Assignments',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatBox(
                              label: 'Active Tasks',
                              value: '${v?.activeAssignments ?? 0}',
                              color: AppTheme.info,
                            ),
                            _buildStatBox(
                              label: 'Max Assignments',
                              value: '${v?.maximumActiveAssignments ?? 3}',
                              color: AppTheme.primary,
                            ),
                            _buildStatBox(
                              label: 'Comfort Tier',
                              value: v?.comfortTier ?? 'Moderate',
                              color: AppTheme.emerald,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Registered Skills & Certifications Manager
                Card(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.workspace_premium_outlined,
                                    color: AppTheme.primary, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Skills & Certifications Manager',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                              tooltip: 'Add Skill',
                              onPressed: _showAddSkillDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_skills.isEmpty)
                          const Text(
                            'No skills listed in profile. Click + to add skills.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.map((skill) {
                              return InputChip(
                                label: Text(skill),
                                labelStyle: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                deleteIcon: const Icon(Icons.close, size: 16, color: AppTheme.primary),
                                onDeleted: () => _removeSkill(skill),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
