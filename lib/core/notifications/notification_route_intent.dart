enum NotificationRouteSection {
  tasks,
  finance,
  habits,
  challenges,
  goals,
  settings,
}

sealed class NotificationRouteIntent {
  const NotificationRouteIntent();

  String get deduplicationKey;
}

abstract base class NotificationEntityRouteIntent
    extends NotificationRouteIntent {
  const NotificationEntityRouteIntent(this.entityId, this.entityKind);

  final String entityId;
  final String entityKind;

  @override
  String get deduplicationKey => '$entityKind:$entityId';

  @override
  bool operator ==(Object other) {
    return other is NotificationEntityRouteIntent &&
        other.runtimeType == runtimeType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(runtimeType, entityId);
}

final class NotificationTaskRouteIntent extends NotificationEntityRouteIntent {
  const NotificationTaskRouteIntent(String taskId) : super(taskId, 'task');

  String get taskId => entityId;
}

final class NotificationHabitRouteIntent extends NotificationEntityRouteIntent {
  const NotificationHabitRouteIntent(String habitId) : super(habitId, 'habit');

  String get habitId => entityId;
}

final class NotificationChallengeRouteIntent
    extends NotificationEntityRouteIntent {
  const NotificationChallengeRouteIntent(String challengeId)
    : super(challengeId, 'challenge');

  String get challengeId => entityId;
}

final class NotificationGoalRouteIntent extends NotificationEntityRouteIntent {
  const NotificationGoalRouteIntent(String goalId) : super(goalId, 'goal');

  String get goalId => entityId;
}

final class NotificationDebtRouteIntent extends NotificationEntityRouteIntent {
  const NotificationDebtRouteIntent(String debtId) : super(debtId, 'debt');

  String get debtId => entityId;
}

final class NotificationInstallmentRouteIntent
    extends NotificationEntityRouteIntent {
  const NotificationInstallmentRouteIntent(String installmentId)
    : super(installmentId, 'installment');

  String get installmentId => entityId;
}

final class NotificationTransactionRouteIntent
    extends NotificationEntityRouteIntent {
  const NotificationTransactionRouteIntent(String transactionId)
    : super(transactionId, 'transaction');

  String get transactionId => entityId;
}

final class NotificationSectionRouteIntent extends NotificationRouteIntent {
  const NotificationSectionRouteIntent(this.section);

  final NotificationRouteSection section;

  @override
  String get deduplicationKey => 'section:${section.name}';

  @override
  bool operator ==(Object other) {
    return other is NotificationSectionRouteIntent && other.section == section;
  }

  @override
  int get hashCode => Object.hash(runtimeType, section);
}

enum NotificationRouteIgnoreReason {
  malformedPayload,
  unsupportedPayload,
  missingDestination,
  unsupportedDestination,
  invalidIdentifier,
}

sealed class NotificationRouteParseResult {
  const NotificationRouteParseResult();
}

final class NotificationRouteParseSuccess extends NotificationRouteParseResult {
  const NotificationRouteParseSuccess(this.intent);

  final NotificationRouteIntent intent;

  @override
  bool operator ==(Object other) {
    return other is NotificationRouteParseSuccess && other.intent == intent;
  }

  @override
  int get hashCode => Object.hash(runtimeType, intent);
}

final class NotificationRouteParseIgnored extends NotificationRouteParseResult {
  const NotificationRouteParseIgnored(this.reason);

  final NotificationRouteIgnoreReason reason;

  @override
  bool operator ==(Object other) {
    return other is NotificationRouteParseIgnored && other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);
}
