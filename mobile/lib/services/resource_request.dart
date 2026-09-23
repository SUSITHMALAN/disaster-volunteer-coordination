import 'dart:async';
import 'dart:convert';

// Error presentation for this feature; HTTP and authentication remain in ApiClient.
class ResourceApiException implements Exception {
  final String message;
  const ResourceApiException(this.message);
  @override
  String toString() => message;
}

Future<T> resourceRequest<T>(Future<T> Function() operation) async {
  try {
    return await operation().timeout(const Duration(seconds: 30));
  } on TimeoutException {
    throw const ResourceApiException(
      'The request timed out. Refresh to check the latest data before trying again.',
    );
  } on FormatException {
    throw const ResourceApiException(
      'The server returned an unexpected response.',
    );
  } on TypeError {
    throw const ResourceApiException(
      'Resource data could not be read. Please try again later.',
    );
  } catch (error) {
    final match = RegExp(r'Request failed \((\d+)\): ([\s\S]*)')
        .firstMatch('$error');
    if (match == null) {
      throw const ResourceApiException(
        'Cannot reach the server. Check your connection and try again.',
      );
    }
    final code = int.parse(match.group(1)!);
    if (code == 401) {
      throw const ResourceApiException(
        'Your session has expired. Return to the dashboard, sign out, and sign in again.',
      );
    }
    if (code == 403) {
      throw const ResourceApiException(
        'Only coordinators and admins can access resources.',
      );
    }
    if (code == 404) {
      throw const ResourceApiException(
        'The requested resource could not be found. Refresh and try again.',
      );
    }
    if (code >= 500) {
      throw const ResourceApiException(
        'The server could not complete the request. Please try again later.',
      );
    }
    final body = match.group(2)!.trim();
    try {
      final data = jsonDecode(body);
      if (data is Map && data['errors'] is Map) {
        final messages = (data['errors'] as Map).values.expand(
          (value) => value is List ? value.map((item) => '$item') : ['$value'],
        );
        throw ResourceApiException(messages.join('\n'));
      }
      if (data is Map && data['title'] is String) {
        throw ResourceApiException(data['title'] as String);
      }
      if (data is String) throw ResourceApiException(data);
    } on FormatException {
      // Existing controllers also return plain-text validation messages.
    }
    throw ResourceApiException(body.isEmpty ? 'Request failed ($code).' : body);
  }
}

String resourcePath(String path, Map<String, String?> filters) => Uri(
  path: path,
  queryParameters: Map.fromEntries(
    filters.entries.where((entry) => entry.value != null),
  ),
).toString();
