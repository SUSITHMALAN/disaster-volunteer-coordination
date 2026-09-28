enum AssignmentStatus {
  assigned,
  dispatched,
  inProgress,
  completed,
  cancelled,
}

class Assignment {
  final String id;
  final String incidentId;
  final String volunteerId;
  final String matchId;
  final AssignmentStatus status;
  final int estimatedDurationMinutes;
  final DateTime assignedAtUtc;
  final DateTime? dispatchedAtUtc;
  final DateTime? startedAtUtc;
  final DateTime? completedAtUtc;
  final DateTime createdAtUtc;

  Assignment({
    required this.id,
    required this.incidentId,
    required this.volunteerId,
    required this.matchId,
    required this.status,
    required this.estimatedDurationMinutes,
    required this.assignedAtUtc,
    this.dispatchedAtUtc,
    this.startedAtUtc,
    this.completedAtUtc,
    required this.createdAtUtc,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      incidentId: json['incidentId'],
      volunteerId: json['volunteerId'],
      matchId: json['matchId'],
      status: _parseStatus(json['status']),
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      assignedAtUtc: DateTime.parse(json['assignedAtUtc']),
      dispatchedAtUtc: json['dispatchedAtUtc'] != null
          ? DateTime.parse(json['dispatchedAtUtc'])
          : null,
      startedAtUtc: json['startedAtUtc'] != null
          ? DateTime.parse(json['startedAtUtc'])
          : null,
      completedAtUtc: json['completedAtUtc'] != null
          ? DateTime.parse(json['completedAtUtc'])
          : null,
      createdAtUtc: DateTime.parse(json['createdAtUtc']),
    );
  }

  static AssignmentStatus _parseStatus(dynamic value) {
    switch (value.toString().toLowerCase()) {
      case 'assigned':
        return AssignmentStatus.assigned;
      case 'dispatched':
        return AssignmentStatus.dispatched;
      case 'inprogress':
      case 'in_progress':
        return AssignmentStatus.inProgress;
      case 'completed':
        return AssignmentStatus.completed;
      case 'cancelled':
        return AssignmentStatus.cancelled;
      default:
        throw FormatException('Unknown assignment status: $value');
    }
  }

  String get statusText {
    switch (status) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.dispatched:
        return 'Dispatched';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.completed:
        return 'Completed';
      case AssignmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}