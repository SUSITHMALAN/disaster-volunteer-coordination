import '../models/incident_summary.dart';
import 'api_client.dart';
import 'resource_request.dart';

class IncidentService {
  static Future<List<IncidentSummary>> getIncidents() =>
      resourceRequest(() async {
        final response = await ApiClient.get('/api/incidents');
        return (response as List)
            .map(
              (item) =>
                  IncidentSummary.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      });
}
