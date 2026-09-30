import 'api_client.dart';
import '../models/volunteer.dart';

class VolunteerService {
  static Future<List<Volunteer>> getVolunteers({String? skill, bool? available}) async {
    final params = <String>[];
    if (skill != null && skill.isNotEmpty) params.add('skill=$skill');
    if (available != null) params.add('available=$available');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    final response = await ApiClient.get('/api/Volunteers$query');
    return (response as List).map((v) => Volunteer.fromJson(v)).toList();
  }

  static Future<Volunteer?> getVolunteerById(String id) async {
    try {
      final response = await ApiClient.get('/api/Volunteers/$id');
      if (response == null) return null;
      return Volunteer.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateAvailability(String id, bool isAvailable) async {
    await ApiClient.patch('/api/Volunteers/$id/availability', {
      'isAvailable': isAvailable,
    });
  }

  static Future<void> updateProfile(String id, List<String> skills, bool isAvailable) async {
    await ApiClient.patch('/api/Volunteers/$id/profile', {
      'skills': skills,
      'isAvailable': isAvailable,
    });
  }
}