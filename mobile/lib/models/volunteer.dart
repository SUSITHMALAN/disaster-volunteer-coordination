class Volunteer {
  final String id;
  final String fullName;
  final String email;
  final List<String> skills;
  final bool isAvailable;
  final int maximumActiveAssignments;
  final int activeAssignments;
  final List<String> certifications;
  final String comfortTier;
  final DateTime? availabilityStartUtc;
  final DateTime? availabilityEndUtc;

  Volunteer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.skills,
    required this.isAvailable,
    this.maximumActiveAssignments = 3,
    this.activeAssignments = 0,
    this.certifications = const [],
    this.comfortTier = 'Moderate',
    this.availabilityStartUtc,
    this.availabilityEndUtc,
  });

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      skills: List<String>.from(json['skills'] ?? []),
      isAvailable: json['isAvailable'] ?? false,
      maximumActiveAssignments: json['maximumActiveAssignments'] ?? 3,
      activeAssignments: json['activeAssignments'] ?? 0,
      certifications: List<String>.from(json['certifications'] ?? []),
      comfortTier: (json['comfortTier'] ?? 'Moderate').toString(),
      availabilityStartUtc: DateTime.tryParse(
        (json['availabilityStartUtc'] ?? '').toString(),
      ),
      availabilityEndUtc: DateTime.tryParse(
        (json['availabilityEndUtc'] ?? '').toString(),
      ),
    );
  }
}
