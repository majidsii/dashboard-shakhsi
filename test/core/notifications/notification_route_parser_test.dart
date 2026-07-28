import 'dart:convert';

import 'package:dashboard_shakhsi/core/notifications/notification_owner.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_payload_codec.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_request.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_route_intent.dart';
import 'package:dashboard_shakhsi/core/notifications/notification_route_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = NotificationRouteParser();

  test('allow-listed task route becomes a typed task intent', () {
    final result = parser.parse(_encodedRequest(route: '/tasks/task-1'));

    expect(
      result,
      const NotificationRouteParseSuccess(
        NotificationTaskRouteIntent('task-1'),
      ),
    );
  });

  test('exact section routes become typed section intents', () {
    final cases = <String, NotificationRouteSection>{
      '/tasks': NotificationRouteSection.tasks,
      '/finance': NotificationRouteSection.finance,
      '/habits': NotificationRouteSection.habits,
      '/challenges': NotificationRouteSection.challenges,
      '/goals': NotificationRouteSection.goals,
      '/settings': NotificationRouteSection.settings,
    };

    for (final entry in cases.entries) {
      expect(
        parser.parse(_encodedRequest(route: entry.key)),
        NotificationRouteParseSuccess(
          NotificationSectionRouteIntent(entry.value),
        ),
        reason: entry.key,
      );
    }
  });

  test('allow-listed entity routes become typed intents', () {
    final cases = <String, NotificationRouteIntent>{
      '/habits/habit_1': const NotificationHabitRouteIntent('habit_1'),
      '/challenges/challenge-1': const NotificationChallengeRouteIntent(
        'challenge-1',
      ),
      '/goals/goal-1': const NotificationGoalRouteIntent('goal-1'),
      '/finance/debts/debt-1': const NotificationDebtRouteIntent('debt-1'),
      '/finance/installments/plan-1': const NotificationInstallmentRouteIntent(
        'plan-1',
      ),
      '/finance/transactions/transaction-1':
          const NotificationTransactionRouteIntent('transaction-1'),
    };

    for (final entry in cases.entries) {
      expect(
        parser.parse(_encodedRequest(route: entry.key)),
        NotificationRouteParseSuccess(entry.value),
        reason: entry.key,
      );
    }
  });

  test('missing route falls back to the notification owner', () {
    expect(
      parser.parse(
        _encodedRequest(
          ownerType: NotificationOwnerType.habit,
          ownerId: 'habit-1',
        ),
      ),
      const NotificationRouteParseSuccess(
        NotificationHabitRouteIntent('habit-1'),
      ),
    );

    expect(
      parser.parse(
        _encodedRequest(
          ownerType: NotificationOwnerType.dailySummary,
          ownerId: 'summary-1',
        ),
      ),
      const NotificationRouteParseSuccess(
        NotificationSectionRouteIntent(NotificationRouteSection.tasks),
      ),
    );

    expect(
      parser.parse(
        _encodedRequest(
          ownerType: NotificationOwnerType.routine,
          ownerId: 'routine-1',
        ),
      ),
      const NotificationRouteParseSuccess(
        NotificationSectionRouteIntent(NotificationRouteSection.habits),
      ),
    );
  });

  test('unknown raw route is ignored instead of forwarded', () {
    final result = parser.parse(
      _encodedRequest(route: 'https://example.com/unsafe'),
    );

    expect(
      result,
      const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.unsupportedDestination,
      ),
    );
  });

  test('query fragments and extra path segments are rejected', () {
    for (final route in <String>[
      '/tasks/task-1?admin=true',
      '/tasks/task-1/details',
      '/tasks/../settings',
      '/finance/debts/debt-1#fragment',
    ]) {
      expect(
        parser.parse(_encodedRequest(route: route)),
        const NotificationRouteParseIgnored(
          NotificationRouteIgnoreReason.unsupportedDestination,
        ),
        reason: route,
      );
    }
  });

  test('blank or invalid identifiers are ignored', () {
    expect(
      parser.parse(_encodedRequest(route: '/tasks/')),
      const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.invalidIdentifier,
      ),
    );

    expect(
      parser.parse(
        _encodedRequest(
          ownerType: NotificationOwnerType.task,
          ownerId: 'task/invalid',
        ),
      ),
      const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.invalidIdentifier,
      ),
    );
  });

  test('malformed JSON is ignored without throwing', () {
    expect(
      parser.parse('{broken'),
      const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.malformedPayload,
      ),
    );
  });

  test('unsupported payload version is distinguished safely', () {
    final encoded = jsonEncode(<String, Object>{
      'version': 2,
      'scheduleId': 'task-reminder-1',
      'ownerType': 'task',
      'ownerId': 'task-1',
      'values': <String, String>{'route': '/tasks/task-1'},
    });

    expect(
      parser.parse(encoded),
      const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.unsupportedPayload,
      ),
    );
  });

  test('incomplete supported payload is treated as malformed', () {
    final encoded = jsonEncode(<String, Object>{
      'version': 1,
      'scheduleId': 'task-reminder-1',
    });

    expect(
      parser.parse(encoded),
      const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.malformedPayload,
      ),
    );
  });
}

String _encodedRequest({
  String? route,
  NotificationOwnerType ownerType = NotificationOwnerType.task,
  String ownerId = 'task-1',
}) {
  return NotificationPayloadCodec.encode(
    NotificationRequest(
      scheduleId: 'route-test-${ownerType.name}-$ownerId',
      owner: NotificationOwner(type: ownerType, id: ownerId),
      title: 'یادآوری',
      body: 'زمان انجام رسیده است.',
      scheduledAtUtc: DateTime.utc(2026, 7, 28, 10),
      payload: route == null
          ? const <String, String>{}
          : <String, String>{'route': route},
    ),
  );
}
