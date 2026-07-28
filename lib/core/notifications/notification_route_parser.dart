import 'dart:convert';

import 'notification_route_intent.dart';

/// Converts a versioned notification payload into an allow-listed typed intent.
///
/// Invalid JSON, unsupported versions, unknown routes, and unsafe identifiers
/// are intentionally ignored by returning `null`.
final class NotificationRouteParser {
  const NotificationRouteParser();

  static const int supportedPayloadVersion = 1;

  static final RegExp _taskRoutePattern = RegExp(
    r'^/tasks/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _habitRoutePattern = RegExp(
    r'^/habits/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _challengeRoutePattern = RegExp(
    r'^/challenges/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _goalRoutePattern = RegExp(
    r'^/goals/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _debtRoutePattern = RegExp(
    r'^/finance/debts/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _installmentRoutePattern = RegExp(
    r'^/finance/installments/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _transactionRoutePattern = RegExp(
    r'^/finance/transactions/([A-Za-z0-9_-]{1,128})$',
  );
  static final RegExp _safeEntityIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  NotificationRouteIntent? parse(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map) {
        return null;
      }

      final payload = Map<String, Object?>.from(decoded);
      if (_readVersion(payload) != supportedPayloadVersion) {
        return null;
      }

      final routeRead = _readRoute(payload);
      if (!routeRead.isValid) {
        return null;
      }

      if (routeRead.isPresent) {
        final route = routeRead.value;
        if (route == null) {
          return _intentFromOwner(payload);
        }

        // An explicit but invalid route must not silently fall back to owner.
        return _intentFromRoute(route);
      }

      return _intentFromOwner(payload);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  int? _readVersion(Map<String, Object?> payload) {
    final hasLong = payload.containsKey('version');
    final hasShort = payload.containsKey('v');

    if (!hasLong && !hasShort) {
      return null;
    }

    final longValue = payload['version'];
    final shortValue = payload['v'];

    if (hasLong && hasShort && longValue != shortValue) {
      return null;
    }

    final value = hasLong ? longValue : shortValue;
    return value is int ? value : null;
  }

  _AliasedStringRead _readRoute(Map<String, Object?> payload) {
    final hasLong = payload.containsKey('route');
    final hasShort = payload.containsKey('r');

    if (!hasLong && !hasShort) {
      return const _AliasedStringRead.absent();
    }

    final longValue = payload['route'];
    final shortValue = payload['r'];

    if (hasLong && hasShort && longValue != shortValue) {
      return const _AliasedStringRead.invalid();
    }

    final value = hasLong ? longValue : shortValue;
    if (value == null) {
      return const _AliasedStringRead.present(null);
    }
    if (value is! String || value.isEmpty) {
      return const _AliasedStringRead.invalid();
    }

    return _AliasedStringRead.present(value);
  }

  NotificationRouteIntent? _intentFromRoute(String route) {
    switch (route) {
      case '/tasks':
        return const NotificationSectionRouteIntent(NotificationSection.tasks);
      case '/finance':
        return const NotificationSectionRouteIntent(
          NotificationSection.finance,
        );
      case '/settings':
        return const NotificationSectionRouteIntent(
          NotificationSection.settings,
        );
    }

    final taskId = _capture(_taskRoutePattern, route);
    if (taskId != null) {
      return NotificationTaskRouteIntent(taskId);
    }

    final habitId = _capture(_habitRoutePattern, route);
    if (habitId != null) {
      return NotificationHabitRouteIntent(habitId);
    }

    final challengeId = _capture(_challengeRoutePattern, route);
    if (challengeId != null) {
      return NotificationChallengeRouteIntent(challengeId);
    }

    final goalId = _capture(_goalRoutePattern, route);
    if (goalId != null) {
      return NotificationGoalRouteIntent(goalId);
    }

    final debtId = _capture(_debtRoutePattern, route);
    if (debtId != null) {
      return NotificationDebtRouteIntent(debtId);
    }

    final installmentId = _capture(_installmentRoutePattern, route);
    if (installmentId != null) {
      return NotificationInstallmentRouteIntent(installmentId);
    }

    final transactionId = _capture(_transactionRoutePattern, route);
    if (transactionId != null) {
      return NotificationTransactionRouteIntent(transactionId);
    }

    return null;
  }

  NotificationRouteIntent? _intentFromOwner(Map<String, Object?> payload) {
    final owner = _readOwner(payload);
    if (owner == null || !_safeEntityIdPattern.hasMatch(owner.id)) {
      return null;
    }

    return switch (owner.type) {
      'task' => NotificationTaskRouteIntent(owner.id),
      'habit' => NotificationHabitRouteIntent(owner.id),
      'challenge' => NotificationChallengeRouteIntent(owner.id),
      'goal' => NotificationGoalRouteIntent(owner.id),
      'debt' => NotificationDebtRouteIntent(owner.id),
      'installment' => NotificationInstallmentRouteIntent(owner.id),
      'transaction' => NotificationTransactionRouteIntent(owner.id),
      _ => null,
    };
  }

  _NotificationOwnerData? _readOwner(Map<String, Object?> payload) {
    final flatType = payload['ownerType'];
    final flatId = payload['ownerId'];
    final hasFlatOwner =
        payload.containsKey('ownerType') || payload.containsKey('ownerId');

    String? nestedType;
    String? nestedId;
    final rawNestedOwner = payload['owner'];
    final hasNestedOwner = payload.containsKey('owner');

    if (hasNestedOwner) {
      if (rawNestedOwner is! Map) {
        return null;
      }

      final nestedOwner = Map<String, Object?>.from(rawNestedOwner);
      final rawType = nestedOwner['type'];
      final rawId = nestedOwner['id'];
      if (rawType is! String || rawId is! String) {
        return null;
      }
      nestedType = rawType;
      nestedId = rawId;
    }

    if (hasFlatOwner && (flatType is! String || flatId is! String)) {
      return null;
    }

    if (hasFlatOwner && hasNestedOwner) {
      if (flatType != nestedType || flatId != nestedId) {
        return null;
      }
    }

    final type = hasFlatOwner ? flatType as String : nestedType;
    final id = hasFlatOwner ? flatId as String : nestedId;
    if (type == null || id == null) {
      return null;
    }

    return _NotificationOwnerData(type: type, id: id);
  }

  String? _capture(RegExp pattern, String route) {
    return pattern.firstMatch(route)?.group(1);
  }
}

final class _NotificationOwnerData {
  const _NotificationOwnerData({required this.type, required this.id});

  final String type;
  final String id;
}

final class _AliasedStringRead {
  const _AliasedStringRead.absent()
    : isPresent = false,
      isValid = true,
      value = null;

  const _AliasedStringRead.present(this.value)
    : isPresent = true,
      isValid = true;

  const _AliasedStringRead.invalid()
    : isPresent = false,
      isValid = false,
      value = null;

  final bool isPresent;
  final bool isValid;
  final String? value;
}
