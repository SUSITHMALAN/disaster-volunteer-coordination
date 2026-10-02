import 'api_client.dart';

class MatchResult {
  final String id;
  final String incidentId;
  final String volunteerId;
  final String? volunteerName;
  final double matchScore;
  final String reasoning;
  final String status;
  final String recommendedRole;
  final String? createdUtc;

  MatchResult({
    required this.id,
    required this.incidentId,
    required this.volunteerId,
    this.volunteerName,
    required this.matchScore,
    required this.reasoning,
    required this.status,
    required this.recommendedRole,
    this.createdUtc,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'] ?? json['matchScore'];

    final parsedScore = (rawScore as num?)?.toDouble() ?? 0.0;

    return MatchResult(
      id: json['id']?.toString() ?? '',
      incidentId: json['incidentId']?.toString() ?? '',
      volunteerId: json['volunteerId']?.toString() ?? '',
      volunteerName:
          json['volunteerName']?.toString() ??
          json['volunteer']?['fullName']?.toString(),
      matchScore: parsedScore,
      reasoning:
          json['rationale']?.toString() ??
          json['reasoning']?.toString() ??
          'Matched based on skills and proximity.',
      status: json['status']?.toString() ?? 'Proposed',
      recommendedRole: json['recommendedRole']?.toString() ?? 'Volunteer',
      createdUtc: json['createdUtc']?.toString(),
    );
  }
}

class MatchesService {
  static Future<List<MatchResult>> getMatches(String incidentId) async {
    final response = await ApiClient.get('/api/Matches?incidentId=$incidentId');

    if (response == null) {
      return [];
    }

    return (response as List)
        .map((item) => MatchResult.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> triggerMatchingAgent(
    String incidentId, {
    String? reportText,
  }) async {
    await ApiClient.post('/api/AgentWorkflows', {
      'incidentId': incidentId,
      'rawReportText':
          reportText ?? 'Automated matching requested for incident.',
      'requiredSkills': [],
    });
  }

  static Future<MatchResult> updateMatchStatus(
    String matchId,
    String newStatus,
  ) async {
    final response = await ApiClient.patch('/api/Matches/$matchId/status', {
      'newStatus': newStatus,
    });

    return MatchResult.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<dynamic> createAssignment({
    required String matchId,
    required int estimatedDurationMinutes,
  }) async {
    return ApiClient.post('/api/Assignments', {
      'matchId': matchId,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    });
  }
}
