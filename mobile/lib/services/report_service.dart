import '../models/resource.dart';
import '../models/resource_report.dart';
import 'api_client.dart';
import 'resource_request.dart';

class ReportService {
  static Future<List<ResourceReport>> getSummary({
    String? incidentId,
    ResourceCategory? category,
    bool byIncident = false,
  }) => resourceRequest(() async {
    final response = await ApiClient.get(
      resourcePath(
        '/api/reports/resources/${byIncident ? 'by-incident' : 'summary'}',
        {'incidentId': incidentId, 'category': category?.apiValue},
      ),
    );
    return (response as List)
        .map((item) => ResourceReport.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  });

  static Future<ResourceShortagePage> getShortages({
    String? incidentId,
    ResourceCategory? category,
    int page = 1,
  }) => resourceRequest(() async {
    final response = await ApiClient.get(
      resourcePath('/api/reports/resources/shortages', {
        'incidentId': incidentId,
        'category': category?.apiValue,
        'page': '$page',
        'pageSize': '20',
      }),
    );
    return ResourceShortagePage.fromJson(Map<String, dynamic>.from(response));
  });
}
