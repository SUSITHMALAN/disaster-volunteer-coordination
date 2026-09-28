import 'api_client.dart';

class VolunteerAssignment {
  final String id;
  final String incidentId;
  final String volunteerId;
  final String status;
  final String assignedAtUtc;
  final int estimatedDurationMinutes;

  VolunteerAssignment({
    required this.id,
    required this.incidentId,
    required this.volunteerId,
    required this.status,
    required this.assignedAtUtc,
    required this.estimatedDurationMinutes,
  });

  factory VolunteerAssignment.fromJson(Map<String, dynamic> json) {
    return VolunteerAssignment(
      id: json['id']?.toString() ?? '',
      incidentId: json['incidentId']?.toString() ?? '',
      volunteerId: json['volunteerId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Assigned',
      assignedAtUtc: json['assignedAtUtc']?.toString() ?? '',
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 120,
    );
  }
}

class AssignmentsService {
  static Future<List<VolunteerAssignment>> getAssignmentHistory() async {
    final response = await ApiClient.get('/api/Assignments/history');
    if (response == null) return [];
    return (response as List).map((i) => VolunteerAssignment.fromJson(i)).toList();
  }

  static Future<void> updateAssignmentStatus(String id, String newStatus) async {
    await ApiClient.patch('/api/Assignments/$id/status', {
      'newStatus': newStatus,
    });
  }
}
