import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _skillsController = TextEditingController();

  String _category = incidentCategories.first;
  String _severity = 'Medium';
  bool _submitting = false;
  String? _error;

  Future<void> _handleSubmit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final skills = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await IncidentService.createIncident(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        severity: _severity,
        zone: _zoneController.text.trim(),
        address: _addressController.text.trim(),
        requiredSkills: skills,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. A coordinator will triage it shortly.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = "Couldn't submit the report. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _zoneController.dispose();
    _addressController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181F),
        title: const Text('Report an incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E5E9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: incidentCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: incidentSeverities
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _severity = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _zoneController,
                decoration: const InputDecoration(labelText: 'Zone (e.g. Colombo)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills needed (comma-separated)',
                  hintText: 'e.g. boat, first-aid',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFB3413E), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8722E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_submitting ? 'Submitting…' : 'Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
