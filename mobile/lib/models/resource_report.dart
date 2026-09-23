import 'resource.dart';

class ResourceReport {
  final String resourceName;
  final ResourceCategory category;
  final String unit;
  final num totalAvailable;
  final num totalNeeded;
  final num totalUsed;
  final num totalShortage;
  final int resourceCount;
  final int shortageResourceCount;
  final String? incidentId;
  final String? incidentTitle;

  ResourceReport.fromJson(Map<String, dynamic> json)
    : resourceName = json['resourceName'] as String,
      category = ResourceCategory.fromJson(json['category'] as String),
      unit = json['unit'] as String,
      totalAvailable = json['totalAvailable'] as num,
      totalNeeded = json['totalNeeded'] as num,
      totalUsed = json['totalUsed'] as num,
      totalShortage = json['totalShortage'] as num,
      resourceCount = json['resourceCount'] as int,
      shortageResourceCount = json['shortageResourceCount'] as int,
      incidentId = json['incidentId'] as String?,
      incidentTitle = json['incidentTitle'] as String?;
}

class ResourceShortagePage {
  final int totalCount;
  final int page;
  final int pageSize;
  final List<Resource> items;

  ResourceShortagePage.fromJson(Map<String, dynamic> json)
    : totalCount = json['totalCount'] as int,
      page = json['page'] as int,
      pageSize = json['pageSize'] as int,
      items = (json['items'] as List)
          .map((item) => Resource.fromJson(Map<String, dynamic>.from(item)))
          .toList();

  bool get hasNext => page * pageSize < totalCount;
}
