import 'dart:convert';

import 'notification_owner.dart';
import 'notification_payload_codec.dart';
import 'notification_route_intent.dart';

final class NotificationRouteParser {
  const NotificationRouteParser();

  static const int _supportedPayloadVersion = 1;

  static final RegExp _identifier = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final RegExp _task = RegExp(r'^/tasks/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _habit = RegExp(r'^/habits/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _challenge = RegExp(
    r'^/challenges/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _goal = RegExp(r'^/goals/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _debt = RegExp(
    r'^/finance/debts/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _installment = RegExp(
    r'^/finance/installments/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _transaction = RegExp(
    r'^/finance/transactions/([A-Za-z0-9_-]{1,128})$',
  );

  NotificationRouteParseResult parse(String encoded) {
    final versionCheck = _validatePayloadVersion(encoded);
    if (versionCheck != null) {
      return versionCheck;
    }

    final NotificationPayload payload;
    try {
      payload = NotificationPayloadCodec.decode(encoded);
    } on FormatException {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.malformedPayload,
      );
    }

    final rawRoute = payload.values['route']?.trim();
    if (rawRoute == null || rawRoute.isEmpty) {
      return _fromOwner(payload.owner);
    }

    return _fromAllowListedRoute(rawRoute);
  }

  NotificationRouteParseIgnored? _validatePayloadVersion(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.malformedPayload,
      );
    } catch (_) {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.malformedPayload,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.malformedPayload,
      );
    }

    final version = decoded['version'];
    if (version != _supportedPayloadVersion) {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.unsupportedPayload,
      );
    }

    return null;
  }

  NotificationRouteParseResult _fromAllowListedRoute(String route) {
    final section = switch (route) {
      '/tasks' => NotificationRouteSection.tasks,
      '/finance' => NotificationRouteSection.finance,
      '/habits' => NotificationRouteSection.habits,
      '/challenges' => NotificationRouteSection.challenges,
      '/goals' => NotificationRouteSection.goals,
      '/settings' => NotificationRouteSection.settings,
      _ => null,
    };

    if (section != null) {
      return NotificationRouteParseSuccess(
        NotificationSectionRouteIntent(section),
      );
    }

    final matchers = <(RegExp, NotificationRouteIntent Function(String))>[
      (_task, NotificationTaskRouteIntent.new),
      (_habit, NotificationHabitRouteIntent.new),
      (_challenge, NotificationChallengeRouteIntent.new),
      (_goal, NotificationGoalRouteIntent.new),
      (_debt, NotificationDebtRouteIntent.new),
      (_installment, NotificationInstallmentRouteIntent.new),
      (_transaction, NotificationTransactionRouteIntent.new),
    ];

    for (final matcher in matchers) {
      final match = matcher.$1.firstMatch(route);
      if (match != null) {
        return NotificationRouteParseSuccess(matcher.$2(match.group(1)!));
      }
    }

    if (_looksLikeKnownRouteWithMissingIdentifier(route)) {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.invalidIdentifier,
      );
    }

    return const NotificationRouteParseIgnored(
      NotificationRouteIgnoreReason.unsupportedDestination,
    );
  }

  NotificationRouteParseResult _fromOwner(NotificationOwner owner) {
    if (!_identifier.hasMatch(owner.id)) {
      return const NotificationRouteParseIgnored(
        NotificationRouteIgnoreReason.invalidIdentifier,
      );
    }

    return switch (owner.type) {
      NotificationOwnerType.task => NotificationRouteParseSuccess(
        NotificationTaskRouteIntent(owner.id),
      ),
      NotificationOwnerType.habit => NotificationRouteParseSuccess(
        NotificationHabitRouteIntent(owner.id),
      ),
      NotificationOwnerType.routine => const NotificationRouteParseSuccess(
        NotificationSectionRouteIntent(NotificationRouteSection.habits),
      ),
      NotificationOwnerType.challenge => NotificationRouteParseSuccess(
        NotificationChallengeRouteIntent(owner.id),
      ),
      NotificationOwnerType.installment => NotificationRouteParseSuccess(
        NotificationInstallmentRouteIntent(owner.id),
      ),
      NotificationOwnerType.debt => NotificationRouteParseSuccess(
        NotificationDebtRouteIntent(owner.id),
      ),
      NotificationOwnerType.recurringTransaction =>
        NotificationRouteParseSuccess(
          NotificationTransactionRouteIntent(owner.id),
        ),
      NotificationOwnerType.dailySummary => const NotificationRouteParseSuccess(
        NotificationSectionRouteIntent(NotificationRouteSection.tasks),
      ),
    };
  }

  bool _looksLikeKnownRouteWithMissingIdentifier(String route) {
    return route == '/tasks/' ||
        route == '/habits/' ||
        route == '/challenges/' ||
        route == '/goals/' ||
        route == '/finance/debts/' ||
        route == '/finance/installments/' ||
        route == '/finance/transactions/';
  }
}
