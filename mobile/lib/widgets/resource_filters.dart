import 'package:flutter/material.dart';

import '../models/incident_summary.dart';
import '../models/resource.dart';
import '../services/incident_service.dart';
import '../theme/app_theme.dart';

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
      final data = await IncidentService.getIncidentSummaries();

      if (!mounted) return;

      setState(() {
        _incidents = data;
      });

      widget.onIncidentsLoaded?.call(data);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load incident choices.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      filled: true,
      fillColor: AppTheme.backgroundAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'FILTER RESOURCES',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            key: ValueKey('incident-${widget.incidentId}'),
            initialValue: widget.incidentId ?? '',
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            iconEnabledColor: AppTheme.textMuted,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: _decoration(
              _loading ? 'Loading incidents...' : 'Incident',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text(
                  'All incidents',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),

              if (widget.incidentId != null &&
                  !_incidents.any(
                    (incident) => incident.id == widget.incidentId,
                  ))
                DropdownMenuItem(
                  value: widget.incidentId,
                  child: Text(
                    widget.incidentId!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),

              ..._incidents.map(
                (incident) => DropdownMenuItem(
                  value: incident.id,
                  child: Text(
                    incident.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    widget.onChanged(
                      value == '' ? null : value,
                      widget.category,
                      widget.isShortage,
                    );
                  },
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ),

                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ],

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: widget.category?.apiValue ?? '',
            key: ValueKey('category-${widget.category}'),
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            iconEnabledColor: AppTheme.textMuted,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: _decoration('Category'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text(
                  'All categories',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),

              ...ResourceCategory.values.map(
                (category) => DropdownMenuItem(
                  value: category.apiValue,
                  child: Text(
                    category.label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              widget.onChanged(
                widget.incidentId,
                value == null || value.isEmpty
                    ? null
                    : ResourceCategory.fromJson(value),
                widget.isShortage,
              );
            },
          ),

          if (widget.showShortage) ...[
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: widget.isShortage?.toString() ?? '',
              key: ValueKey('shortage-${widget.isShortage}'),
              isExpanded: true,
              dropdownColor: AppTheme.surface,
              iconEnabledColor: AppTheme.textMuted,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: _decoration('Supply status'),
              items: const [
                DropdownMenuItem(
                  value: '',
                  child: Text(
                    'All resources',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'true',
                  child: Text(
                    'Shortages only',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ),
                DropdownMenuItem(
                  value: 'false',
                  child: Text(
                    'No shortage',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ),
              ],
              onChanged: (value) {
                widget.onChanged(
                  widget.incidentId,
                  widget.category,
                  value == '' || value == null ? null : value == 'true',
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
