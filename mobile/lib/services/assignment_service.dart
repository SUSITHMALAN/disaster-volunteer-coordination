import '../models/assignment.dart';
import 'api_client.dart';

class AssignmentService {
  static Future<List<Assignment>> getHistory({
    String? volunteerId,
    String? incidentId,
  }) async {
    final queryParameters = <String, String>{};

    if (volunteerId != null) {
      queryParameters['volunteerId'] = volunteerId;
    }

    if (incidentId != null) {
      queryParameters['incidentId'] = incidentId;
    }

    final query = Uri(
      queryParameters: queryParameters,
    ).query;

    final path = query.isEmpty
        ? '/api/Assignments/history'
        : '/api/Assignments/history?$query';

    final response = await ApiClient.get(path);

    return (response as List)
        .map(
          (json) => Assignment.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  static Future<Assignment> updateStatus(
    String assignmentId,
    AssignmentStatus newStatus,
  ) async {
    final response = await ApiClient.patch(
      '/api/Assignments/$assignmentId/status',
      {
        'newStatus': _statusToApiValue(newStatus),
      },
    );

    return Assignment.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  static String _statusToApiValue(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.dispatched:
        return 'Dispatched';
      case AssignmentStatus.inProgress:
        return 'InProgress';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}