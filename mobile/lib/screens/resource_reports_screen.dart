import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../models/resource_report.dart';
import '../models/user.dart';
import '../services/report_service.dart';
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
    if (_allowed) _load();
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
        if (mounted && request == _request) setState(() => _shortages = data);
      } else {
        final data = await ReportService.getSummary(
          incidentId: _incidentId,
          category: _category,
          byIncident: _view == 'incident',
        );
        if (mounted && request == _request) setState(() => _reports = data);
      }
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = '$error');
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Widget _reportCard(ResourceReport report) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.resourceName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('${report.category.label} · ${report.unit}'),
          if (report.incidentTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              report.incidentTitle!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          ResourceQuantities(
            available: report.totalAvailable,
            needed: report.totalNeeded,
            used: report.totalUsed,
            unit: report.unit,
          ),
          const SizedBox(height: 12),
          Text(
            'Total shortage: ${formatQuantity(report.totalShortage)} ${report.unit}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: report.totalShortage > 0
                  ? const Color(0xFFB3413E)
                  : const Color(0xFF2F6B4F),
            ),
          ),
          Text(
            '${report.shortageResourceCount} of ${report.resourceCount} resource records have shortages.',
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Resource reports'),
      backgroundColor: const Color(0xFF14181F),
      foregroundColor: Colors.white,
      actions: _allowed
          ? [
              IconButton(
                tooltip: 'Refresh reports',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ]
          : null,
    ),
    body: !_allowed
        ? const Center(child: Text('Coordinator or admin access required.'))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _view,
                  decoration: const InputDecoration(
                    labelText: 'Report',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'summary',
                      child: Text('Resource summary'),
                    ),
                    DropdownMenuItem(
                      value: 'incident',
                      child: Text('Distribution by incident'),
                    ),
                    DropdownMenuItem(
                      value: 'shortages',
                      child: Text('Shortage resources'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _view = value!;
                      _page = 1;
                    });
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                ResourceFilters(
                  incidentId: _incidentId,
                  category: _category,
                  onIncidentsLoaded: (incidents) => setState(() {
                    _incidentTitles = {
                      for (final incident in incidents)
                        incident.id: incident.title,
                    };
                  }),
                  onChanged: (incident, category, _) {
                    setState(() {
                      _incidentId = incident;
                      _category = category;
                      _page = 1;
                    });
                    _load();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Totals are grouped by resource, category and unit. Available includes used supplies. '
                    'Shortages are added per resource record; surplus elsewhere does not cancel them.',
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry report'),
                      ),
                    ],
                  )
                else if (_view == 'shortages' && _shortages != null) ...[
                  Text(
                    '${_shortages!.totalCount} resources with shortages',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_shortages!.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No shortages on this page.'),
                    ),
                  ..._shortages!.items.map(
                    (resource) => ResourceCard(
                      resource: resource,
                      incidentTitle: _incidentTitles[resource.incidentId],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _page > 1
                            ? () {
                                setState(() => _page--);
                                _load();
                              }
                            : null,
                        child: const Text('Previous'),
                      ),
                      Text('Page $_page'),
                      TextButton(
                        onPressed: _shortages!.hasNext
                            ? () {
                                setState(() => _page++);
                                _load();
                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ] else if (_reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No resource data matches these filters.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._reports.map(_reportCard),
              ],
            ),
          ),
  );
}
