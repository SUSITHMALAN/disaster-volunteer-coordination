import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../models/resource_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/resource_card.dart';
import '../widgets/resource_filters.dart';

class ResourceReportsScreen extends StatefulWidget {
  final AppUser user;
  final String? incidentId;

  const ResourceReportsScreen({super.key, required this.user, this.incidentId});

  @override
  State<ResourceReportsScreen> createState() => _ResourceReportsScreenState();
}

class _ResourceReportsScreenState extends State<ResourceReportsScreen> {
  String? _incidentId;
  ResourceCategory? _category;

  String _view = 'summary';

  List<ResourceReport> _reports = [];

  Map<String, String> _incidentTitles = {};

  ResourceShortagePage? _shortages;

  int _page = 1;
  int _request = 0;

  bool _loading = true;

  String? _error;

  bool get _allowed =>
      widget.user.role == 'Coordinator' || widget.user.role == 'Admin';

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
      if (_view == 'shortages') {
        final data = await ReportService.getShortages(
          incidentId: _incidentId,
          category: _category,
          page: _page,
        );

        if (!mounted || request != _request) {
          return;
        }

        setState(() {
          _shortages = data;
        });
      } else {
        final data = await ReportService.getSummary(
          incidentId: _incidentId,
          category: _category,
          byIncident: _view == 'incident',
        );

        if (!mounted || request != _request) {
          return;
        }

        setState(() {
          _reports = data;
        });
      }
    } catch (_) {
      if (!mounted || request != _request) {
        return;
      }

      setState(() {
        _error = 'Failed to load resource report.';
      });
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _reportTitle() {
    switch (_view) {
      case 'incident':
        return 'Distribution by Incident';

      case 'shortages':
        return 'Shortage Resources';

      default:
        return 'Resource Summary';
    }
  }

  String _reportDescription() {
    switch (_view) {
      case 'incident':
        return 'Review how resources are distributed across individual incidents.';

      case 'shortages':
        return 'Review resource records that currently have active shortages.';

      default:
        return 'Review grouped totals for available, needed and used supplies.';
    }
  }

  Widget _reportCard(ResourceReport report) {
    final shortage = report.totalShortage > 0;

    final statusColor = shortage ? AppTheme.danger : AppTheme.emerald;

    final progress = report.totalNeeded <= 0
        ? report.totalAvailable > 0
              ? 1.0
              : 0.0
        : (report.totalAvailable / report.totalNeeded).clamp(0, 1).toDouble();

    final progressPercent = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: shortage
              ? AppTheme.danger.withValues(alpha: 0.30)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESOURCE REPORT',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            report.resourceName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${report.category.label} · ${report.unit}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),

          if (report.incidentTitle != null) ...[
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INCIDENT',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        report.incidentTitle!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.backgroundAlt,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatQuantity(report.totalAvailable)} / '
                  '${formatQuantity(report.totalNeeded)} '
                  '${report.unit} ($progressPercent%)',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                shortage
                    ? 'Shortage ${formatQuantity(report.totalShortage)} ${report.unit}'
                    : 'No shortage',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(height: 1, color: AppTheme.border),

          const SizedBox(height: 14),

          ResourceQuantities(
            available: report.totalAvailable,
            needed: report.totalNeeded,
            used: report.totalUsed,
            unit: report.unit,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                shortage
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: statusColor,
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  shortage
                      ? '${report.shortageResourceCount} of ${report.resourceCount} resource records have shortages.'
                      : 'All ${report.resourceCount} resource records meet their required quantities.',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
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
          'Resource Reports',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: _allowed
            ? [
                IconButton(
                  tooltip: 'Refresh reports',
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

      body: !_allowed
          ? _buildAccessDenied()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 22),

                  _buildReportSelector(),

                  const SizedBox(height: 14),

                  ResourceFilters(
                    incidentId: _incidentId,
                    category: _category,
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
                    onChanged: (incident, category, _) {
                      setState(() {
                        _incidentId = incident;
                        _category = category;
                        _page = 1;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RESOURCE ANALYTICS',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          _reportTitle(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          _reportDescription(),
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildReportSelector() {
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
            'REPORT TYPE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _view,
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            iconEnabledColor: AppTheme.textMuted,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
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
            items: const [
              DropdownMenuItem(
                value: 'summary',
                child: Text(
                  'Resource summary',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'incident',
                child: Text(
                  'Distribution by incident',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'shortages',
                child: Text(
                  'Shortage resources',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _view = value;
                _page = 1;
              });

              _load();
            },
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
              'Available includes used supplies. Shortages are calculated per resource record, so surplus elsewhere does not cancel them.',
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

    if (_view == 'shortages' && _shortages != null) {
      return _buildShortages();
    }

    if (_reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.analytics_outlined, color: AppTheme.textMuted, size: 38),

            SizedBox(height: 12),

            Text(
              'No resource data matches these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(children: _reports.map(_reportCard).toList());
  }

  Widget _buildShortages() {
    final shortages = _shortages!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.danger,
              size: 20,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                '${shortages.totalCount} resources with shortages',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (shortages.items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'No shortages on this page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          )
        else
          ...shortages.items.map(
            (resource) => ResourceCard(
              resource: resource,
              incidentTitle: _incidentTitles[resource.incidentId],
            ),
          ),

        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _page > 1
                  ? () {
                      setState(() {
                        _page--;
                      });

                      _load();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
            ),

            Text(
              'Page $_page',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            TextButton.icon(
              onPressed: shortages.hasNext
                  ? () {
                      setState(() {
                        _page++;
                      });

                      _load();
                    }
                  : null,
              label: const Text('Next'),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
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
