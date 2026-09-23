import 'package:flutter/material.dart';

import '../models/incident_summary.dart';
import '../models/resource.dart';
import '../services/incident_service.dart';

class ResourceFilters extends StatefulWidget {
  final String? incidentId;
  final ResourceCategory? category;
  final bool? isShortage;
  final bool showShortage;
  final void Function(String?, ResourceCategory?, bool?) onChanged;
  final ValueChanged<List<IncidentSummary>>? onIncidentsLoaded;

  const ResourceFilters({
    super.key,
    this.incidentId,
    this.category,
    this.isShortage,
    this.showShortage = false,
    required this.onChanged,
    this.onIncidentsLoaded,
  });

  @override
  State<ResourceFilters> createState() => _ResourceFiltersState();
}

class _ResourceFiltersState extends State<ResourceFilters> {
  List<IncidentSummary> _incidents = [];
  bool _loading = true;
  String? _error;

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
      final data = await IncidentService.getIncidents();
      if (mounted) {
        setState(() => _incidents = data);
        widget.onIncidentsLoaded?.call(data);
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        key: ValueKey('incident-${widget.incidentId}'),
        initialValue: widget.incidentId ?? '',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: _loading ? 'Loading incidents…' : 'Incident',
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('All incidents')),
          if (widget.incidentId != null &&
              !_incidents.any((i) => i.id == widget.incidentId))
            DropdownMenuItem(
              value: widget.incidentId,
              child: Text(widget.incidentId!, overflow: TextOverflow.ellipsis),
            ),
          ..._incidents.map(
            (i) => DropdownMenuItem(
              value: i.id,
              child: Text(i.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: _loading
            ? null
            : (value) => widget.onChanged(
                value == '' ? null : value,
                widget.category,
                widget.isShortage,
              ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Incident choices: $_error'),
              TextButton(
                onPressed: _load,
                child: const Text('Retry incidents'),
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: widget.category?.apiValue ?? '',
        key: ValueKey('category-${widget.category}'),
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('All categories')),
          ...ResourceCategory.values.map(
            (c) => DropdownMenuItem(value: c.apiValue, child: Text(c.label)),
          ),
        ],
        onChanged: (value) => widget.onChanged(
          widget.incidentId,
          value == null || value.isEmpty
              ? null
              : ResourceCategory.fromJson(value),
          widget.isShortage,
        ),
      ),
      if (widget.showShortage) ...[
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: widget.isShortage?.toString() ?? '',
          key: ValueKey('shortage-${widget.isShortage}'),
          decoration: const InputDecoration(
            labelText: 'Supply status',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: '', child: Text('All resources')),
            DropdownMenuItem(value: 'true', child: Text('Shortages only')),
            DropdownMenuItem(value: 'false', child: Text('No shortage')),
          ],
          onChanged: (value) => widget.onChanged(
            widget.incidentId,
            widget.category,
            value == '' || value == null ? null : value == 'true',
          ),
        ),
      ],
    ],
  );
}
