enum ResourceCategory {
  water('Water', 'Water'),
  firstAid('FirstAid', 'First aid'),
  food('Food', 'Food'),
  transport('Transport', 'Transport'),
  other('Other', 'Other');

  const ResourceCategory(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ResourceCategory fromJson(String value) => values.firstWhere(
    (category) => category.apiValue == value,
    orElse: () => throw FormatException('Unknown resource category: $value'),
  );
}

class Resource {
  final String id;
  final String incidentId;
  final String resourceName;
  final ResourceCategory category;
  final String unit;
  final num availableQuantity;
  final num neededQuantity;
  final num usedQuantity;
  final bool isShortage;
  final num shortageQuantity;

  const Resource({
    required this.id,
    required this.incidentId,
    required this.resourceName,
    required this.category,
    required this.unit,
    required this.availableQuantity,
    required this.neededQuantity,
    required this.usedQuantity,
    required this.isShortage,
    required this.shortageQuantity,
  });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
    id: json['id'] as String,
    incidentId: json['incidentId'] as String,
    resourceName: json['resourceName'] as String,
    category: ResourceCategory.fromJson(json['category'] as String),
    unit: json['unit'] as String,
    availableQuantity: json['availableQuantity'] as num,
    neededQuantity: json['neededQuantity'] as num,
    usedQuantity: json['usedQuantity'] as num,
    isShortage: json['isShortage'] as bool,
    shortageQuantity: json['shortageQuantity'] as num,
  );
}

String formatQuantity(num value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

String? validateQuantity(String? input) {
  final text = input?.trim() ?? '';
  if (text.isEmpty) return 'Enter a quantity (use 0 if none).';
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
    return 'Use a nonnegative number with up to 2 decimal places.';
  }
  final value = num.tryParse(text);
  if (value == null || !value.isFinite || value >= 10000000000000000) {
    return 'Quantity is too large.';
  }
  return null;
}
