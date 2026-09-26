import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../models/user.dart';
import '../services/resource_service.dart';
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
      final resources = await ResourceService.getResources(
        incidentId: _incidentId,
        category: _category,
        isShortage: _isShortage,
      );
      if (mounted && request == _request) {
        setState(() => _resources = resources);
      }
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = '$error');
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
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
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Resource saved.')));
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Resources & supplies'),
      backgroundColor: const Color(0xFF14181F),
      foregroundColor: Colors.white,
      actions: _allowed
          ? [
              IconButton(
                tooltip: 'Resource reports',
                icon: const Icon(Icons.bar_chart),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ResourceReportsScreen(
                      user: widget.user,
                      incidentId: _incidentId,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh resources',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ]
          : null,
    ),
    floatingActionButton: _allowed
        ? FloatingActionButton.extended(
            onPressed: () => _openForm(),
            backgroundColor: const Color(0xFFB8722E),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add resource'),
          )
        : null,
    body: !_allowed
        ? const Center(child: Text('Coordinator or admin access required.'))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                const Text(
                  'Track supplies allocated to each incident.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ResourceFilters(
                  incidentId: _incidentId,
                  category: _category,
                  isShortage: _isShortage,
                  showShortage: true,
                  onIncidentsLoaded: (incidents) => setState(() {
                    _incidentTitles = {
                      for (final incident in incidents)
                        incident.id: incident.title,
                    };
                  }),
                  onChanged: (incident, category, shortage) {
                    setState(() {
                      _incidentId = incident;
                      _category = category;
                      _isShortage = shortage;
                    });
                    _load();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Available = total allocated, including supplies already used.',
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
                        child: const Text('Retry resources'),
                      ),
                    ],
                  )
                else if (_resources.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No resources match these filters. Choose another filter or add a resource.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._resources.map(
                    (resource) => ResourceCard(
                      resource: resource,
                      incidentTitle: _incidentTitles[resource.incidentId],
                      onEdit: () => _openForm(resource),
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
                              if (mounted) _load();
                            },
                    ),
                  ),
              ],
            ),
          ),
  );
}
