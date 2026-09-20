class IncidentSummary {
  final String id;
  final String title;
  final String? zone;

  const IncidentSummary({required this.id, required this.title, this.zone});

  factory IncidentSummary.fromJson(Map<String, dynamic> json) =>
      IncidentSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        zone: json['zone'] as String?,
      );

  String get label =>
      zone == null || zone!.trim().isEmpty ? title : '$title · $zone';
}
