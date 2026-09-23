import '../models/resource.dart';
import 'api_client.dart';
import 'resource_request.dart';

class ResourceService {
  static Future<List<Resource>> getResources({
    String? incidentId,
    ResourceCategory? category,
    bool? isShortage,
  }) => resourceRequest(() async {
    final path = incidentId == null
        ? '/api/resources'
        : '/api/resources/incident/$incidentId';
    final response = await ApiClient.get(
      resourcePath(path, {
        'category': category?.apiValue,
        'isShortage': isShortage?.toString(),
      }),
    );
    return (response as List)
        .map((item) => Resource.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  });

  static Future<Resource> getResource(String id) => resourceRequest(() async {
    final response = await ApiClient.get('/api/resources/$id');
    return Resource.fromJson(Map<String, dynamic>.from(response));
  });

  static Future<Resource> save({
    String? id,
    required String incidentId,
    required String resourceName,
    required ResourceCategory category,
    required String unit,
    required num available,
    required num needed,
    required num used,
  }) => resourceRequest(() async {
    final body = <String, dynamic>{
      if (id == null) 'incidentId': incidentId,
      'resourceName': resourceName.trim(),
      'category': category.apiValue,
      'unit': unit.trim(),
      'availableQuantity': available,
      'neededQuantity': needed,
      'usedQuantity': used,
    };
    final response = id == null
        ? await ApiClient.post('/api/resources', body)
        : await ApiClient.put('/api/resources/$id', body);
    return Resource.fromJson(Map<String, dynamic>.from(response));
  });
}
