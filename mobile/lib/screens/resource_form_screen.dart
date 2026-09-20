import 'package:flutter/material.dart';

import '../models/incident_summary.dart';
import '../models/resource.dart';
import '../models/user.dart';
import '../services/incident_service.dart';
import '../services/resource_service.dart';

class ResourceFormScreen extends StatefulWidget {
  final AppUser user;
  final String? resourceId;
  final String? incidentId;
  const ResourceFormScreen({
    super.key,
    required this.user,
    this.resourceId,
    this.incidentId,
  });

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _available = TextEditingController(text: '0');
  final _needed = TextEditingController(text: '0');
  final _used = TextEditingController(text: '0');
  List<IncidentSummary> _incidents = [];
  String? _incidentId;
  ResourceCategory _category = ResourceCategory.other;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;
  bool get _editing => widget.resourceId != null;
  bool get _allowed =>
      widget.user.role == 'Coordinator' || widget.user.role == 'Admin';

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (_editing) {
        final resource = await ResourceService.getResource(widget.resourceId!);
        if (!mounted) return;
        _incidentId = resource.incidentId;
        _name.text = resource.resourceName;
        _unit.text = resource.unit;
        _category = resource.category;
        _available.text = formatQuantity(resource.availableQuantity);
        _needed.text = formatQuantity(resource.neededQuantity);
        _used.text = formatQuantity(resource.usedQuantity);
      } else {
        final incidents = await IncidentService.getIncidents();
        if (!mounted) return;
        _incidents = incidents;
        _incidentId = incidents.any((i) => i.id == widget.incidentId)
            ? widget.incidentId
            : null;
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ResourceService.save(
        id: widget.resourceId,
        incidentId: _incidentId!,
        resourceName: _name.text,
        category: _category,
        unit: _unit.text,
        available: num.parse(_available.text.trim()),
        needed: num.parse(_needed.text.trim()),
        used: num.parse(_used.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _saveError = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _unit, _available, _needed, _used]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Widget _quantity(
    TextEditingController controller,
    String label, {
    bool isUsed = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final error = validateQuantity(value);
        if (error != null) return error;
        final allocated = num.tryParse(_available.text.trim());
        if (isUsed &&
            allocated != null &&
            num.parse(value!.trim()) > allocated) {
          return 'Used quantity cannot exceed the allocated quantity.';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Update quantities' : 'Add resource'),
        backgroundColor: const Color(0xFF14181F),
        foregroundColor: Colors.white,
      ),
      body: !_allowed
          ? const Center(child: Text('Coordinator or admin access required.'))
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : !_editing && _incidents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No incidents are available. An incident must be recorded before adding supplies.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Refresh incidents'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_editing)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('Incident: $_incidentId'),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            initialValue: _incidentId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Incident',
                              border: OutlineInputBorder(),
                            ),
                            items: _incidents
                                .map(
                                  (i) => DropdownMenuItem(
                                    value: i.id,
                                    child: Text(
                                      i.label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (value) =>
                                      setState(() => _incidentId = value),
                            validator: (value) =>
                                value == null ? 'Select an incident.' : null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _name,
                          readOnly: _editing,
                          enabled: !_saving,
                          maxLength: 200,
                          validator: _requiredText,
                          decoration: const InputDecoration(
                            labelText: 'Resource name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ResourceCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: ResourceCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.label),
                                ),
                              )
                              .toList(),
                          onChanged: _editing || _saving
                              ? null
                              : (value) => setState(() => _category = value!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _unit,
                          readOnly: _editing,
                          enabled: !_saving,
                          maxLength: 50,
                          validator: _requiredText,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'e.g. litres, kits, parcels, trips',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Available is the total allocated to this incident, including supplies already used. '
                            'Needed is the total requirement. Enter all quantities in the same unit.',
                          ),
                        ),
                        _quantity(_available, 'Available / allocated'),
                        _quantity(_needed, 'Needed'),
                        _quantity(_used, 'Used', isUsed: true),
                        if (_saveError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _saveError!,
                              style: const TextStyle(color: Color(0xFFB3413E)),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB8722E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(_saving ? 'Saving…' : 'Save resource'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
