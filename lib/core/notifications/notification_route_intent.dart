/// A validated, typed navigation request produced from a notification payload.
///
/// Raw notification routes must never reach the application router directly.
sealed class NotificationRouteIntent {
  const NotificationRouteIntent();
}

/// Shared value semantics for notification routes that target one entity.
sealed class NotificationEntityRouteIntent extends NotificationRouteIntent {
  const NotificationEntityRouteIntent(this.entityId);

  final String entityId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other is NotificationEntityRouteIntent &&
            other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(runtimeType, entityId);
}

final class NotificationTaskRouteIntent extends NotificationEntityRouteIntent {
  const NotificationTaskRouteIntent(super.entityId);

  String get taskId => entityId;
}

final class NotificationHabitRouteIntent extends NotificationEntityRouteIntent {
  const NotificationHabitRouteIntent(super.entityId);

  String get habitId => entityId;
}

final class NotificationChallengeRouteIntent
    extends NotificationEntityRouteIntent {
  const NotificationChallengeRouteIntent(super.entityId);

  String get challengeId => entityId;
}

final class NotificationGoalRouteIntent extends NotificationEntityRouteIntent {
  const NotificationGoalRouteIntent(super.entityId);

  String get goalId => entityId;
}

final class NotificationDebtRouteIntent extends NotificationEntityRouteIntent {
  const NotificationDebtRouteIntent(super.entityId);

  String get debtId => entityId;
}

final class NotificationInstallmentRouteIntent
    extends NotificationEntityRouteIntent {
  const NotificationInstallmentRouteIntent(super.entityId);

  String get installmentId => entityId;
}

final class NotificationTransactionRouteIntent
    extends NotificationEntityRouteIntent {
  const NotificationTransactionRouteIntent(super.entityId);

  String get transactionId => entityId;
}

enum NotificationSection { tasks, finance, settings }

final class NotificationSectionRouteIntent extends NotificationRouteIntent {
  const NotificationSectionRouteIntent(this.section);

  final NotificationSection section;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSectionRouteIntent && other.section == section;
  }

  @override
  int get hashCode => section.hashCode;
}
