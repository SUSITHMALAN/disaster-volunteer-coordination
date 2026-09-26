import '../models/incident.dart';
import '../models/incident_summary.dart';
import 'api_client.dart';
import 'resource_request.dart';

class IncidentService {
  static Future<List<IncidentSummary>> getIncidentSummaries() =>
      resourceRequest(() async {
        final response = await ApiClient.get('/api/incidents');
        return (response as List)
            .map(
              (item) =>
                  IncidentSummary.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      });

  static Future<List<Incident>> getIncidents({String? status}) async {
    final params = <String>[];
    if (status != null && status.isNotEmpty) params.add('status=$status');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    final response = await ApiClient.get('/api/Incidents$query');
    return (response as List).map((i) => Incident.fromJson(i)).toList();
  }

  static Future<Incident> createIncident({
    required String title,
    required String description,
    required String category,
    required String severity,
    String? zone,
    String? address,
    List<String> requiredSkills = const [],
  }) async {
    final response = await ApiClient.post('/api/Incidents', {
      'title': title,
      'description': description,
      'category': category,
      'severity': severity,
      if (zone != null && zone.isNotEmpty) 'zone': zone,
      if (address != null && address.isNotEmpty) 'address': address,
      'requiredSkills': requiredSkills,
      'rawReportText': description,
    });
    return Incident.fromJson(response);
  }

  static Future<void> updateStatus(String id, String newStatus) async {
    await ApiClient.patch('/api/Incidents/$id/status', {
      'newStatus': newStatus,
    });
  }
}
