import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_temp/models/resource.dart';
import 'package:mobile_temp/models/resource_report.dart';
import 'package:mobile_temp/models/user.dart';
import 'package:mobile_temp/screens/dashboard_screen.dart';
import 'package:mobile_temp/screens/resources_screen.dart';
import 'package:mobile_temp/services/resource_request.dart';
import 'package:mobile_temp/widgets/resource_card.dart';

Map<String, dynamic> resourceJson() => {
  'id': 'resource-1',
  'incidentId': 'incident-1',
  'resourceName': 'Water',
  'category': 'Water',
  'unit': 'litres',
  'availableQuantity': 10,
  'neededQuantity': 12.5,
  'usedQuantity': 4,
  'isShortage': true,
  'shortageQuantity': 2.5,
};

AppUser user(String role) => AppUser(
  userId: 'user-1',
  fullName: 'Coordinator',
  email: 'user@example.test',
  role: role,
);

void main() {
  test(
    'resource parses integer and fractional quantities and API shortage',
    () {
      final resource = Resource.fromJson(resourceJson());
      expect(resource.availableQuantity, 10);
      expect(resource.neededQuantity, 12.5);
      expect(resource.isShortage, isTrue);
      expect(resource.shortageQuantity, 2.5);
      expect(ResourceCategory.firstAid.apiValue, 'FirstAid');
    },
  );

  test('quantity validation rejects missing, negative, nonfinite and overprecision values', () {
    for (final value in [
      '',
      '-1',
      'NaN',
      'Infinity',
      '1.001',
      '1e3',
      '10000000000000000',
    ]) {
      expect(validateQuantity(value), isNotNull, reason: value);
    }
    for (final value in ['0', '0.00', '10', '12.50']) {
      expect(validateQuantity(value), isNull, reason: value);
    }
    expect(formatQuantity(0), '0');
    expect(formatQuantity(100), '100');
    expect(formatQuantity(12.5), '12.5');
  });

  test('report pagination follows server totals', () {
    final page = ResourceShortagePage.fromJson({
      'totalCount': 21,
      'page': 1,
      'pageSize': 20,
      'items': [resourceJson()],
    });
    expect(page.hasNext, isTrue);
    expect(page.items.single.id, 'resource-1');
    final empty = ResourceShortagePage.fromJson({
      'totalCount': 0,
      'page': 1,
      'pageSize': 20,
      'items': [],
    });
    expect(empty.hasNext, isFalse);
  });

  test('filters use URI encoding and omit absent values', () {
    final uri = Uri.parse(
      resourcePath('/api/resources', {
        'category': 'FirstAid',
        'unused': null,
        'example': 'A & B',
      }),
    );
    expect(uri.queryParameters, {'category': 'FirstAid', 'example': 'A & B'});
  });

  test(
    'resource errors preserve server validation and distinguish permissions',
    () async {
      await expectLater(
        resourceRequest<void>(() async {
          throw Exception(
            'Request failed (400): {"errors":{"UsedQuantity":["Used exceeds available."]}}',
          );
        }),
        throwsA(
          isA<ResourceApiException>().having(
            (e) => e.message,
            'message',
            'Used exceeds available.',
          ),
        ),
      );
      await expectLater(
        resourceRequest<void>(() async {
          throw Exception('Request failed (403): ');
        }),
        throwsA(
          isA<ResourceApiException>().having(
            (e) => e.message,
            'message',
            contains('coordinators'),
          ),
        ),
      );
      await expectLater(
        resourceRequest<void>(() async {
          throw TimeoutException('test');
        }),
        throwsA(
          isA<ResourceApiException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    },
  );

  testWidgets('shortage card includes quantities and a textual warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceCard(resource: Resource.fromJson(resourceJson())),
        ),
      ),
    );
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Needed'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(find.text('Shortage: 2.5 litres'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('dashboard resource links are limited to management roles', (
    tester,
  ) async {
    for (final role in ['Coordinator', 'Admin', 'Volunteer', 'Requester']) {
      await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(user: user(role))),
      );
      final allowed = role == 'Coordinator' || role == 'Admin';
      expect(
        find.text('Resources & supplies'),
        allowed ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Resource reports'),
        allowed ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets('unauthorized resource screen does not load protected data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ResourcesScreen(user: user('Volunteer'))),
    );
    expect(find.text('Coordinator or admin access required.'), findsOneWidget);
    expect(find.text('Add resource'), findsNothing);
  });
}
