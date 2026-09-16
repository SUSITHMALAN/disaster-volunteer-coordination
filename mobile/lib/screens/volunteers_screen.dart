import 'package:flutter/material.dart';
import '../models/volunteer.dart';
import '../services/volunteer_service.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  List<Volunteer> _volunteers = [];
  bool _loading = true;
  String? _error;
  final _skillController = TextEditingController();

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
      final data = await VolunteerService.getVolunteers(
        skill: _skillController.text.trim().isEmpty ? null : _skillController.text.trim(),
      );
      setState(() => _volunteers = data);
    } catch (e) {
      setState(() => _error = 'Failed to load volunteers.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Volunteer v) async {
    await VolunteerService.updateAvailability(v.id, !v.isAvailable);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181F),
        title: const Text('Volunteers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _skillController,
              decoration: const InputDecoration(
                labelText: 'Filter by skill',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null) Expanded(child: Center(child: Text(_error!))),
          if (!_loading && _error == null)
            Expanded(
              child: _volunteers.isEmpty
                  ? const Center(child: Text('No volunteers match this filter.'))
                  : ListView.builder(
                      itemCount: _volunteers.length,
                      itemBuilder: (context, index) {
                        final v = _volunteers[index];
                        return ListTile(
                          title: Text(v.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(v.skills.isEmpty ? 'No skills listed' : v.skills.join(' · ')),
                          trailing: ElevatedButton(
                            onPressed: () => _toggle(v),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: v.isAvailable
                                  ? const Color(0xFF2F6B4F)
                                  : const Color(0xFF8A8F98),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(v.isAvailable ? 'Available' : 'Unavailable'),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}