import '../../core/notifications/notification_route_intent.dart';

/// Converts validated notification intents into application-owned locations.
///
/// This mapper is the only place where a notification intent becomes a router
/// location. It never accepts a raw payload or raw route.
final class NotificationRouteLocationMapper {
  const NotificationRouteLocationMapper();

  static final RegExp _safeEntityId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// Returns an allow-listed location, or `null` for a defensively invalid
  /// entity intent constructed outside [NotificationRouteParser].
  String? locationFor(NotificationRouteIntent intent) {
    return switch (intent) {
      NotificationTaskRouteIntent() => _entityLocation('/tasks', intent.taskId),
      NotificationHabitRouteIntent() => _entityLocation(
        '/habits',
        intent.habitId,
      ),
      NotificationChallengeRouteIntent() => _entityLocation(
        '/challenges',
        intent.challengeId,
      ),
      NotificationGoalRouteIntent() => _entityLocation('/goals', intent.goalId),
      NotificationDebtRouteIntent() => _entityLocation(
        '/finance/debts',
        intent.debtId,
      ),
      NotificationInstallmentRouteIntent() => _entityLocation(
        '/finance/installments',
        intent.installmentId,
      ),
      NotificationTransactionRouteIntent() => _entityLocation(
        '/finance/transactions',
        intent.transactionId,
      ),
      NotificationSectionRouteIntent() => switch (intent.section) {
        NotificationSection.tasks => '/tasks',
        NotificationSection.finance => '/finance',
        NotificationSection.settings => '/settings',
      },
    };
  }

  String? _entityLocation(String prefix, String entityId) {
    if (!_safeEntityId.hasMatch(entityId)) {
      return null;
    }

    return '$prefix/$entityId';
  }
}
