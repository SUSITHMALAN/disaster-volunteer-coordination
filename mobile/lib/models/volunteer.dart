class Volunteer {
  final String id;
  final String fullName;
  final String email;
  final List<String> skills;
  final bool isAvailable;

  Volunteer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.skills,
    required this.isAvailable,
  });

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      skills: List<String>.from(json['skills'] ?? []),
      isAvailable: json['isAvailable'] ?? false,
    );
  }
}