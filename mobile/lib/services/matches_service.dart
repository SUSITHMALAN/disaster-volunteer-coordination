import 'api_client.dart';

class MatchResult {
  final String id;
  final String incidentId;
  final String volunteerId;
  final double matchScore;
  final String reasoning;
  final String recommendedRole;
  final String? createdUtc;

  MatchResult({
    required this.id,
    required this.incidentId,
    required this.volunteerId,
    required this.matchScore,
    required this.reasoning,
    required this.recommendedRole,
    this.createdUtc,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      id: json['id']?.toString() ?? '',
      incidentId: json['incidentId']?.toString() ?? '',
      volunteerId: json['volunteerId']?.toString() ?? '',
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning']?.toString() ?? '',
      recommendedRole: json['recommendedRole']?.toString() ?? '',
      createdUtc: json['createdUtc']?.toString(),
    );
  }
}

class MatchesService {
  static Future<List<MatchResult>> getMatches(String incidentId) async {
    final response = await ApiClient.get('/api/Matches?incidentId=$incidentId');
    if (response == null) return [];
    return (response as List).map((i) => MatchResult.fromJson(i)).toList();
  }

  static Future<void> triggerMatchingAgent(String incidentId) async {
    await ApiClient.post('/api/AgentWorkflows/matching', {
      'incidentId': incidentId,
    });
  }

  static Future<dynamic> createAssignment({
    required String incidentId,
    required String volunteerId,
    int estimatedDurationMinutes = 120,
  }) async {
    return await ApiClient.post('/api/Assignments', {
      'incidentId': incidentId,
      'volunteerId': volunteerId,
      'estimatedDurationMinutes': estimatedDurationMinutes,
    });
  }
}
