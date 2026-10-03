import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../models/user.dart';
import '../services/resource_service.dart';
import '../theme/app_theme.dart';
import '../widgets/resource_card.dart';
import '../widgets/resource_filters.dart';
import 'resource_form_screen.dart';
import 'resource_reports_screen.dart';

class ResourcesScreen extends StatefulWidget {
  final AppUser user;
  final String? incidentId;

  const ResourcesScreen({super.key, required this.user, this.incidentId});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<Resource> _resources = [];

  Map<String, String> _incidentTitles = {};

  String? _incidentId;
  ResourceCategory? _category;
  bool? _isShortage;

  bool _loading = true;
  String? _error;

  int _request = 0;

  bool get _allowed =>
      widget.user.role == 'Coordinator' || widget.user.role == 'Admin';

  int get _shortageCount {
    return _resources.where((resource) => resource.isShortage).length;
  }

  @override
  void initState() {
    super.initState();

    _incidentId = widget.incidentId;

    if (_allowed) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resources = await ResourceService.getResources(
        incidentId: _incidentId,
        category: _category,
        isShortage: _isShortage,
      );

      if (!mounted || request != _request) {
        return;
      }

      setState(() {
        _resources = resources;
      });
    } catch (_) {
      if (!mounted || request != _request) {
        return;
      }

      setState(() {
        _error = 'Failed to load resources.';
      });
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openForm([Resource? resource]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ResourceFormScreen(
          user: widget.user,
          resourceId: resource?.id,
          incidentId: _incidentId,
        ),
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Resource saved.')));

    await _load();
  }

  void _openReports() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ResourceReportsScreen(user: widget.user, incidentId: _incidentId),
      ),
    );
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
          'Resources & Supplies',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: _allowed
            ? [
                IconButton(
                  tooltip: 'Resource reports',
                  onPressed: _openReports,
                  icon: const Icon(Icons.bar_chart_rounded),
                ),

                IconButton(
                  tooltip: 'Refresh resources',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ]
            : null,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),

      floatingActionButton: _allowed
          ? FloatingActionButton.extended(
              onPressed: () {
                _openForm();
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Resource',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,

      body: !_allowed
          ? _buildAccessDenied()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 22),

                  if (!_loading && _error == null) _buildSummary(),

                  if (!_loading && _error == null) const SizedBox(height: 20),

                  ResourceFilters(
                    incidentId: _incidentId,
                    category: _category,
                    isShortage: _isShortage,
                    showShortage: true,
                    onIncidentsLoaded: (incidents) {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _incidentTitles = {
                          for (final incident in incidents)
                            incident.id: incident.title,
                        };
                      });
                    },
                    onChanged: (incident, category, shortage) {
                      setState(() {
                        _incidentId = incident;
                        _category = category;
                        _isShortage = shortage;
                      });

                      _load();
                    },
                  ),

                  const SizedBox(height: 14),

                  _buildInfoNote(),

                  const SizedBox(height: 18),

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
          'SUPPLY & INVENTORY',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Disaster Resources & Supplies',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Manage required equipment, medical supplies, food and water allocations across incidents.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            label: 'Resource Items',
            value: _resources.length,
            color: AppTheme.primary,
            icon: Icons.inventory_2_outlined,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            label: 'Shortages',
            value: _shortageCount,
            color: AppTheme.danger,
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.20)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 19),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'Available means the total quantity allocated, including supplies that have already been used.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.danger, fontSize: 13),
            ),

            const SizedBox(height: 6),

            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_resources.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.textMuted,
              size: 38,
            ),

            SizedBox(height: 12),

            Text(
              'No resources match these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _resources
          .map(
            (resource) => ResourceCard(
              resource: resource,
              incidentTitle: _incidentTitles[resource.incidentId],
              onEdit: () {
                _openForm(resource);
              },
              onIncident: _incidentId == resource.incidentId
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResourcesScreen(
                            user: widget.user,
                            incidentId: resource.incidentId,
                          ),
                        ),
                      );

                      if (mounted) {
                        _load();
                      }
                    },
            ),
          )
          .toList(),
    );
  }

  Widget _buildAccessDenied() {
    return Container(
      color: AppTheme.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 42),

          SizedBox(height: 12),

          Text(
            'Coordinator or admin access required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
