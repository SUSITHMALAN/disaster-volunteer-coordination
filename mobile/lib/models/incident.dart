class Incident {
  final String id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? zone;
  final String? address;
  final List<String> requiredSkills;
  final String createdAtUtc;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    this.latitude,
    this.longitude,
    this.zone,
    this.address,
    required this.requiredSkills,
    required this.createdAtUtc,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      severity: json['severity'],
      status: json['status'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      zone: json['zone'],
      address: json['address'],
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      createdAtUtc: json['createdAtUtc'] ?? '',
    );
  }
}

// Mirrors IncidentService.IsLegalTransition on the backend, so the app only
// ever offers a status change the API will actually accept.
const Map<String, String> nextIncidentStatus = {
  'Reported': 'Triaged',
  'Triaged': 'Matching',
  'Matching': 'Assigned',
  'Assigned': 'InProgress',
  'InProgress': 'Resolved',
};

const List<String> incidentCategories = [
  'Flood',
  'Landslide',
  'PowerOutage',
  'MedicalEmergency',
  'StructuralDamage',
  'Other',
];

const List<String> incidentSeverities = ['Low', 'Medium', 'High', 'Critical'];
