# Notification Click Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route notification taps safely and exactly once to the appropriate
application section during both normal runtime and cold start.

**Architecture:** The Flutter notification plugin emits only raw payloads. A
pure parser converts each payload to a typed route intent, an in-memory queue
holds at most one unconsumed intent, and an adapter is the only component that
depends on `GoRouter`. Cold-start retrieval and runtime tap handling share the
same parser and queue.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Riverpod 2.6.1, go_router 17.3.0,
flutter_local_notifications 22.1.0, flutter_test.

## Global Constraints

- Continue on branch `feat/v2-complete-dashboard`.
- Do not begin Phase 2 until every Phase 1 task is complete.
- Preserve the original Liquid Glass UI; this task must not introduce visual
  redesigns.
- Keep notification plugin types out of domain route models.
- Never pass a raw payload route directly to `GoRouter`.
- Accept only explicit allow-listed destinations and identifier formats.
- A malformed or unsupported payload must not prevent application startup.
- Cold-start navigation must wait until the router is attached.
- A valid tap may navigate at most once.
- An invalid tap must not mutate the pending navigation queue.
- Linux scheduling remains outside this task.
- Use RED → observed failure → GREEN → focused test → analyzer → full test →
  Linux debug build for every implementation unit.
- Each RED and GREEN delivery must be packaged together in one ZIP.
- Do not use `set -e` or terminal-ending commands in user-pasted command blocks.

---

## File Structure

### New domain and application files

- `lib/core/notifications/notification_route_intent.dart`  
  Typed destinations and parse-result types.

- `lib/core/notifications/notification_route_parser.dart`  
  Converts the existing versioned `NotificationPayload` into a typed intent.

- `lib/core/notifications/notification_navigation_queue.dart`  
  Stores one pending intent, deduplicates identical input, and acknowledges by
  generation token.

- `lib/core/notifications/notification_response_source.dart`  
  Broadcasts runtime payload callbacks and replays no stale values.

- `lib/core/notifications/notification_launch_details_gateway.dart`  
  Platform-independent contract for retrieving one cold-start payload.

- `lib/core/notifications/notification_routing_startup.dart`  
  Attaches runtime payload handling and processes cold-start payload exactly
  once.

### New router files

- `lib/app/router/notification_route_location_mapper.dart`  
  Maps typed intents to centralized application locations.

- `lib/app/router/notification_router_adapter.dart`  
  Subscribes to the queue, performs post-frame navigation, retries once, and
  acknowledges success.

### Existing files to modify

- `lib/core/notifications/flutter_local_notifications_driver.dart`  
  Implement `NotificationLaunchDetailsGateway`; keep `onPayload` callback as
  the runtime response boundary.

- `lib/core/providers/persistence_providers.dart`  
  Register response source, parser, queue, launch gateway, and routing startup
  providers. Pass `responseSource.accept` into the Flutter driver.

- `lib/app/router/app_router.dart`  
  Add centralized notification adapter provider and parse the dashboard
  `panel` query without changing layout.

- `lib/app/bootstrap/app_bootstrap.dart`  
  Initialize notification routing after plugin/schedule initialization and
  attach the adapter through the application widget.

- `lib/features/dashboard/presentation/dashboard_screen.dart`  
  Accept an initial panel index so `/?panel=finance` and `/?panel=tasks`
  select the existing panel without visual changes.

### New tests

- `test/core/notifications/notification_route_parser_test.dart`
- `test/core/notifications/notification_navigation_queue_test.dart`
- `test/core/notifications/notification_response_source_test.dart`
- `test/core/notifications/notification_routing_startup_test.dart`
- `test/core/providers/notification_routing_providers_test.dart`
- `test/app/router/notification_route_location_mapper_test.dart`
- `test/app/router/notification_router_adapter_test.dart`
- `test/app/bootstrap/notification_routing_bootstrap_test.dart`
- `test/features/dashboard/dashboard_notification_route_test.dart`
- `test/support/fake_notification_launch_details_gateway.dart`
- `test/support/fake_notification_navigator.dart`

---

### Task 1: Typed Route Intents and Safe Parser

**Files:**
- Create:
  `lib/core/notifications/notification_route_intent.dart`
- Create:
  `lib/core/notifications/notification_route_parser.dart`
- Test:
  `test/core/notifications/notification_route_parser_test.dart`

**Interfaces:**

- Consumes:
  `NotificationPayload NotificationPayloadCodec.decode(String encoded)`
- Produces:
  `NotificationRouteParseResult NotificationRouteParser.parse(String encoded)`
- Produces typed intents:
  `NotificationTaskRouteIntent`,
  `NotificationHabitRouteIntent`,
  `NotificationChallengeRouteIntent`,
  `NotificationGoalRouteIntent`,
  `NotificationDebtRouteIntent`,
  `NotificationInstallmentRouteIntent`,
  `NotificationTransactionRouteIntent`,
  and `NotificationSectionRouteIntent`.

- [ ] **Step 1: Write the failing parser tests**

Cover these exact cases:

```dart
test('allow-listed task route becomes a typed task intent', () {
  final request = NotificationRequest(
    scheduleId: 'task-reminder-1',
    owner: NotificationOwner(
      type: NotificationOwnerType.task,
      id: 'task-1',
    ),
    title: 'کار',
    body: 'یادآوری',
    scheduledAtUtc: DateTime.utc(2026, 7, 28, 10),
    payload: const <String, String>{
      'route': '/tasks/task-1',
    },
  );

  final result = const NotificationRouteParser().parse(
    NotificationPayloadCodec.encode(request),
  );

  expect(
    result,
    const NotificationRouteParseSuccess(
      NotificationTaskRouteIntent('task-1'),
    ),
  );
});

test('unknown raw route is ignored instead of forwarded', () {
  final result = const NotificationRouteParser().parse(
    encodedRequest(route: 'https://example.com/unsafe'),
  );

  expect(
    result,
    const NotificationRouteParseIgnored(
      NotificationRouteIgnoreReason.unsupportedDestination,
    ),
  );
});

test('malformed JSON is ignored without throwing', () {
  expect(
    const NotificationRouteParser().parse('{broken'),
    const NotificationRouteParseIgnored(
      NotificationRouteIgnoreReason.malformedPayload,
    ),
  );
});
```

Also test:

- exact section routes `/tasks`, `/finance`, and `/settings`;
- `/habits/:id`, `/challenges/:id`, `/goals/:id`;
- `/finance/debts/:id`;
- `/finance/installments/:id`;
- `/finance/transactions/:id`;
- blank identifiers;
- extra path segments;
- owner fallback when `values['route']` is absent;
- unsupported payload version;
- value strings containing query fragments or traversal sequences.

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/notification_route_parser_test.dart
```

Expected: compilation failure because the route intent and parser types do not
exist.

- [ ] **Step 3: Implement immutable typed intents**

Use sealed classes with value equality:

```dart
sealed class NotificationRouteIntent {
  const NotificationRouteIntent();

  String get deduplicationKey;
}

final class NotificationTaskRouteIntent
    extends NotificationRouteIntent {
  const NotificationTaskRouteIntent(this.taskId);

  final String taskId;

  @override
  String get deduplicationKey => 'task:$taskId';

  @override
  bool operator ==(Object other) {
    return other is NotificationTaskRouteIntent &&
        other.taskId == taskId;
  }

  @override
  int get hashCode => Object.hash(runtimeType, taskId);
}
```

Repeat the same explicit pattern for each entity type. Define:

```dart
enum NotificationRouteSection {
  tasks,
  finance,
  habits,
  challenges,
  goals,
  settings,
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

final class NotificationRouteParseSuccess
    extends NotificationRouteParseResult {
  const NotificationRouteParseSuccess(this.intent);

  final NotificationRouteIntent intent;
}

final class NotificationRouteParseIgnored
    extends NotificationRouteParseResult {
  const NotificationRouteParseIgnored(this.reason);

  final NotificationRouteIgnoreReason reason;
}
```

- [ ] **Step 4: Implement the allow-listed parser**

Use anchored regular expressions only:

```dart
final class NotificationRouteParser {
  const NotificationRouteParser();

  static final RegExp _task =
      RegExp(r'^/tasks/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _habit =
      RegExp(r'^/habits/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _challenge =
      RegExp(r'^/challenges/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _goal =
      RegExp(r'^/goals/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _debt =
      RegExp(r'^/finance/debts/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _installment =
      RegExp(r'^/finance/installments/([A-Za-z0-9_-]{1,128})$');
  static final RegExp _transaction =
      RegExp(r'^/finance/transactions/([A-Za-z0-9_-]{1,128})$');

  NotificationRouteParseResult parse(String encoded) {
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
}
```

Do not use `Uri.parse(rawRoute)` as authorization. Parsing may be used only
after the allow-list has matched.

Owner fallback mapping:

```text
task                 → task entity
habit                → habit entity
routine              → habits section
challenge            → challenge entity
installment          → installment entity
debt                 → debt entity
recurringTransaction → transaction entity
dailySummary         → tasks section
```

- [ ] **Step 5: Run GREEN and commit**

```bash
dart format lib test

flutter test \
  test/core/notifications/notification_route_parser_test.dart

git add \
  lib/core/notifications/notification_route_intent.dart \
  lib/core/notifications/notification_route_parser.dart \
  test/core/notifications/notification_route_parser_test.dart

git commit -m "feat: parse notification routes into typed intents"
```

---

### Task 2: Exactly-Once Pending Navigation Queue

**Files:**
- Create:
  `lib/core/notifications/notification_navigation_queue.dart`
- Test:
  `test/core/notifications/notification_navigation_queue_test.dart`

**Interfaces:**

- Consumes:
  `NotificationRouteIntent`
- Produces:
  `NotificationNavigationEntry enqueue(NotificationRouteIntent intent)`
- Produces:
  `Stream<NotificationNavigationEntry> watch()`
- Produces:
  `bool acknowledge(int token)`
- Produces:
  `NotificationNavigationEntry? get pending`

- [ ] **Step 1: Write failing queue tests**

```dart
test('newest unconsumed intent replaces the older intent', () {
  final queue = NotificationNavigationQueue();
  addTearDown(queue.dispose);

  final first = queue.enqueue(
    const NotificationTaskRouteIntent('task-1'),
  );
  final second = queue.enqueue(
    const NotificationTaskRouteIntent('task-2'),
  );

  expect(second.token, greaterThan(first.token));
  expect(
    queue.pending?.intent,
    const NotificationTaskRouteIntent('task-2'),
  );
});

test('identical pending intent is deduplicated', () {
  final queue = NotificationNavigationQueue();
  addTearDown(queue.dispose);

  final first = queue.enqueue(
    const NotificationTaskRouteIntent('task-1'),
  );
  final duplicate = queue.enqueue(
    const NotificationTaskRouteIntent('task-1'),
  );

  expect(duplicate.token, first.token);
});

test('stale acknowledgement cannot clear a newer intent', () {
  final queue = NotificationNavigationQueue();
  addTearDown(queue.dispose);

  final first = queue.enqueue(
    const NotificationTaskRouteIntent('task-1'),
  );
  final second = queue.enqueue(
    const NotificationTaskRouteIntent('task-2'),
  );

  expect(queue.acknowledge(first.token), isFalse);
  expect(queue.pending, second);
});
```

Also verify that `watch()` immediately yields the current pending entry to a
late subscriber, which is required for cold start.

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/notification_navigation_queue_test.dart
```

- [ ] **Step 3: Implement queue and generation tokens**

```dart
final class NotificationNavigationEntry {
  const NotificationNavigationEntry({
    required this.token,
    required this.intent,
  });

  final int token;
  final NotificationRouteIntent intent;
}

final class NotificationNavigationQueue {
  final StreamController<NotificationNavigationEntry> _controller =
      StreamController<NotificationNavigationEntry>.broadcast(
        sync: true,
      );

  NotificationNavigationEntry? _pending;
  int _nextToken = 1;

  NotificationNavigationEntry? get pending => _pending;

  NotificationNavigationEntry enqueue(
    NotificationRouteIntent intent,
  ) {
    final existing = _pending;
    if (existing?.intent.deduplicationKey ==
        intent.deduplicationKey) {
      return existing!;
    }

    final entry = NotificationNavigationEntry(
      token: _nextToken++,
      intent: intent,
    );
    _pending = entry;
    _controller.add(entry);
    return entry;
  }

  Stream<NotificationNavigationEntry> watch() async* {
    final current = _pending;
    if (current != null) {
      yield current;
    }
    yield* _controller.stream;
  }

  bool acknowledge(int token) {
    if (_pending?.token != token) {
      return false;
    }
    _pending = null;
    return true;
  }

  Future<void> dispose() => _controller.close();
}
```

- [ ] **Step 4: Run GREEN and commit**

```bash
dart format lib test

flutter test \
  test/core/notifications/notification_navigation_queue_test.dart

git add \
  lib/core/notifications/notification_navigation_queue.dart \
  test/core/notifications/notification_navigation_queue_test.dart

git commit -m "feat: queue notification navigation exactly once"
```

---

### Task 3: Runtime Response Source and Cold-Start Gateway

**Files:**
- Create:
  `lib/core/notifications/notification_response_source.dart`
- Create:
  `lib/core/notifications/notification_launch_details_gateway.dart`
- Modify:
  `lib/core/notifications/flutter_local_notifications_driver.dart`
- Test:
  `test/core/notifications/notification_response_source_test.dart`
- Test support:
  `test/support/fake_notification_launch_details_gateway.dart`

**Interfaces:**

- Produces:
  `void NotificationResponseSource.accept(String payload)`
- Produces:
  `Stream<String> get payloads`
- Produces:
  `Future<String?> NotificationLaunchDetailsGateway.initialPayload()`
- `FlutterLocalNotificationsDriver` implements
  `NotificationLaunchDetailsGateway`.

- [ ] **Step 1: Write failing source and gateway contract tests**

```dart
test('response source emits nonblank runtime payloads', () async {
  final source = NotificationResponseSource();
  addTearDown(source.dispose);

  final values = <String>[];
  final subscription = source.payloads.listen(values.add);
  addTearDown(subscription.cancel);

  source.accept('payload-1');
  source.accept('   ');
  await Future<void>.delayed(Duration.zero);

  expect(values, const <String>['payload-1']);
});
```

Add a fake:

```dart
final class FakeNotificationLaunchDetailsGateway
    implements NotificationLaunchDetailsGateway {
  FakeNotificationLaunchDetailsGateway({
    this.payload,
    this.error,
  });

  final String? payload;
  final Object? error;
  int callCount = 0;

  @override
  Future<String?> initialPayload() async {
    callCount += 1;
    if (error != null) {
      throw error!;
    }
    return payload;
  }
}
```

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/notification_response_source_test.dart
```

- [ ] **Step 3: Implement the source and gateway**

```dart
abstract interface class NotificationLaunchDetailsGateway {
  Future<String?> initialPayload();
}

final class NotificationResponseSource {
  final StreamController<String> _controller =
      StreamController<String>.broadcast(sync: true);

  Stream<String> get payloads => _controller.stream;

  void accept(String payload) {
    final normalized = payload.trim();
    if (normalized.isNotEmpty) {
      _controller.add(normalized);
    }
  }

  Future<void> dispose() => _controller.close();
}
```

- [ ] **Step 4: Extend the Flutter driver**

Add `NotificationLaunchDetailsGateway` to the implements list and implement:

```dart
@override
Future<String?> initialPayload() async {
  final details = await _plugin.getNotificationAppLaunchDetails();
  if (details?.didNotificationLaunchApp != true) {
    return null;
  }

  final payload = details?.notificationResponse?.payload?.trim();
  return payload == null || payload.isEmpty ? null : payload;
}
```

Keep the existing initialization callback:

```dart
onDidReceiveNotificationResponse: (response) {
  final payload = response.payload;
  if (payload != null && payload.isNotEmpty) {
    _onPayload?.call(payload);
  }
},
```

Do not navigate from the driver.

- [ ] **Step 5: Run focused and regression tests, then commit**

```bash
dart format lib test

flutter test \
  test/core/notifications/notification_response_source_test.dart \
  test/core/notifications/local_notifications_initializer_test.dart \
  test/core/notifications/notification_permission_service_test.dart

git add \
  lib/core/notifications/notification_response_source.dart \
  lib/core/notifications/notification_launch_details_gateway.dart \
  lib/core/notifications/flutter_local_notifications_driver.dart \
  test/core/notifications/notification_response_source_test.dart \
  test/support/fake_notification_launch_details_gateway.dart

git commit -m "feat: capture notification launch and runtime responses"
```

---

### Task 4: Routing Startup Service

**Files:**
- Create:
  `lib/core/notifications/notification_routing_startup.dart`
- Test:
  `test/core/notifications/notification_routing_startup_test.dart`

**Interfaces:**

- Consumes:
  `NotificationLaunchDetailsGateway`
- Consumes:
  `NotificationResponseSource`
- Consumes:
  `NotificationRouteParser`
- Consumes:
  `NotificationNavigationQueue`
- Produces:
  `Future<void> initialize()`
- Produces:
  `Future<void> dispose()`

- [ ] **Step 1: Write failing startup tests**

Required behaviors:

```dart
test('cold-start payload is parsed and queued once', () async {
  final queue = NotificationNavigationQueue();
  final source = NotificationResponseSource();
  final gateway = FakeNotificationLaunchDetailsGateway(
    payload: encodedTaskPayload('task-1'),
  );
  final startup = NotificationRoutingStartup(
    launchDetailsGateway: gateway,
    responseSource: source,
    parser: const NotificationRouteParser(),
    queue: queue,
  );
  addTearDown(startup.dispose);
  addTearDown(source.dispose);
  addTearDown(queue.dispose);

  await Future.wait(<Future<void>>[
    startup.initialize(),
    startup.initialize(),
    startup.initialize(),
  ]);

  expect(gateway.callCount, 1);
  expect(
    queue.pending?.intent,
    const NotificationTaskRouteIntent('task-1'),
  );
});

test('runtime tap is routed after initialization', () async {
  // initialize with no cold-start payload
  // call source.accept(encodedTaskPayload('task-2'))
  // assert queue.pending is task-2
});

test('invalid payload leaves the queue unchanged', () async {
  // source.accept('{broken')
  // assert queue.pending is null
});

test('failed cold-start lookup can be retried', () async {
  // first initialPayload throws, second returns a valid payload
  // runtime subscription must not be duplicated
});
```

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/notifications/notification_routing_startup_test.dart
```

- [ ] **Step 3: Implement idempotent initialization**

The service must subscribe to runtime payloads once and allow cold-start lookup
retry after failure:

```dart
abstract interface class NotificationRoutingStartupContract {
  Future<void> initialize();

  Future<void> dispose();
}

final class NotificationRoutingStartup
    implements NotificationRoutingStartupContract {
  factory NotificationRoutingStartup({
    required NotificationLaunchDetailsGateway
        launchDetailsGateway,
    required NotificationResponseSource responseSource,
    required NotificationRouteParser parser,
    required NotificationNavigationQueue queue,
  }) {
    return NotificationRoutingStartup._(
      launchDetailsGateway,
      responseSource,
      parser,
      queue,
    );
  }

  NotificationRoutingStartup._(
    this._launchDetailsGateway,
    this._responseSource,
    this._parser,
    this._queue,
  );

  final NotificationLaunchDetailsGateway
      _launchDetailsGateway;
  final NotificationResponseSource _responseSource;
  final NotificationRouteParser _parser;
  final NotificationNavigationQueue _queue;

  StreamSubscription<String>? _subscription;
  Future<void>? _initialization;

  Future<void> initialize() {
    _subscription ??=
        _responseSource.payloads.listen(_acceptPayload);

    return _initialization ??=
        _initializeColdStart().catchError(
          (Object error, StackTrace stackTrace) {
            _initialization = null;
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
  }

  Future<void> _initializeColdStart() async {
    final payload =
        await _launchDetailsGateway.initialPayload();
    if (payload != null) {
      _acceptPayload(payload);
    }
  }

  void _acceptPayload(String payload) {
    final result = _parser.parse(payload);
    if (result case NotificationRouteParseSuccess(:final intent)) {
      _queue.enqueue(intent);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
```

- [ ] **Step 4: Run GREEN and commit**

```bash
dart format lib test

flutter test \
  test/core/notifications/notification_routing_startup_test.dart

git add \
  lib/core/notifications/notification_routing_startup.dart \
  test/core/notifications/notification_routing_startup_test.dart

git commit -m "feat: initialize notification routing safely"
```

---

### Task 5: Riverpod and Bootstrap Wiring

**Files:**
- Modify:
  `lib/core/providers/persistence_providers.dart`
- Modify:
  `lib/app/bootstrap/app_bootstrap.dart`
- Test:
  `test/core/providers/notification_routing_providers_test.dart`
- Test:
  `test/app/bootstrap/notification_routing_bootstrap_test.dart`

**Interfaces:**

- Produces providers:
  `notificationResponseSourceProvider`
  `notificationRouteParserProvider`
  `notificationNavigationQueueProvider`
  `notificationLaunchDetailsGatewayProvider`
  `notificationRoutingStartupProvider`
- Produces bootstrap helper:
  `Future<void> initializeNotificationRoutingForApp(ProviderContainer container)`

- [ ] **Step 1: Write failing provider and bootstrap tests**

Provider test:

```dart
test('routing providers share driver, source, parser, and queue', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  expect(
    container.read(notificationRouteParserProvider),
    isA<NotificationRouteParser>(),
  );
  expect(
    container.read(notificationNavigationQueueProvider),
    isA<NotificationNavigationQueue>(),
  );
  expect(
    container.read(notificationRoutingStartupProvider),
    isA<NotificationRoutingStartup>(),
  );
});
```

Bootstrap helper test:

```dart
test('bootstrap initializes notification routing once', () async {
  final startup = _FakeRoutingStartup();
  final container = ProviderContainer(
    overrides: <Override>[
      notificationRoutingStartupProvider.overrideWithValue(
        startup,
      ),
    ],
  );
  addTearDown(container.dispose);

  await initializeNotificationRoutingForApp(container);

  expect(startup.callCount, 1);
});
```

- [ ] **Step 2: Run RED**

```bash
flutter test \
  test/core/providers/notification_routing_providers_test.dart \
  test/app/bootstrap/notification_routing_bootstrap_test.dart
```

- [ ] **Step 3: Add providers**

The response source must be created before the Flutter driver and supplied to
its callback:

```dart
final notificationResponseSourceProvider =
    Provider<NotificationResponseSource>((ref) {
      final source = NotificationResponseSource();
      ref.onDispose(source.dispose);
      return source;
    });

final notificationRouteParserProvider =
    Provider<NotificationRouteParser>((ref) {
      return const NotificationRouteParser();
    });

final notificationNavigationQueueProvider =
    Provider<NotificationNavigationQueue>((ref) {
      final queue = NotificationNavigationQueue();
      ref.onDispose(queue.dispose);
      return queue;
    });
```

Update the driver provider:

```dart
return FlutterLocalNotificationsDriver(
  config: ref.watch(localNotificationPluginConfigProvider),
  hostPlatform: ref.watch(notificationHostPlatformProvider),
  onPayload: ref.watch(notificationResponseSourceProvider).accept,
);
```

Expose the same driver as launch-details gateway:

```dart
final notificationLaunchDetailsGatewayProvider =
    Provider<NotificationLaunchDetailsGateway>((ref) {
      return ref.watch(
        flutterLocalNotificationsDriverProvider,
      );
    });
```

Create startup provider and register `dispose`.

- [ ] **Step 4: Extend bootstrap**

After the existing notification startup helper completes:

```dart
await initializeNotificationsForApp(container);

try {
  await initializeNotificationRoutingForApp(container);
} catch (error, stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'dashboard_shakhsi',
      context: ErrorDescription(
        'while initializing notification routing',
      ),
    ),
  );
}
```

A routing failure must not block `runApp`.

- [ ] **Step 5: Run GREEN and commit**

```bash
dart format lib test

flutter test \
  test/core/providers/notification_routing_providers_test.dart \
  test/app/bootstrap/notification_routing_bootstrap_test.dart \
  test/app/bootstrap/notification_bootstrap_test.dart

git add \
  lib/core/providers/persistence_providers.dart \
  lib/app/bootstrap/app_bootstrap.dart \
  test/core/providers/notification_routing_providers_test.dart \
  test/app/bootstrap/notification_routing_bootstrap_test.dart

git commit -m "feat: wire notification routing into bootstrap"
```

---

### Task 6: GoRouter Adapter and Safe Location Mapping

**Files:**
- Create:
  `lib/app/router/notification_route_location_mapper.dart`
- Create:
  `lib/app/router/notification_router_adapter.dart`
- Modify:
  `lib/app/router/app_router.dart`
- Modify:
  `lib/app/bootstrap/app_bootstrap.dart`
- Modify:
  `lib/features/dashboard/presentation/dashboard_screen.dart`
- Test:
  `test/app/router/notification_route_location_mapper_test.dart`
- Test:
  `test/app/router/notification_router_adapter_test.dart`
- Test:
  `test/features/dashboard/dashboard_notification_route_test.dart`
- Test support:
  `test/support/fake_notification_navigator.dart`

**Interfaces:**

- Produces:
  `String NotificationRouteLocationMapper.locationFor(NotificationRouteIntent intent)`
- Produces:
  `void NotificationNavigator.go(String location)`
- Produces:
  `NotificationRouterAdapter.attach()`
- Produces:
  `Future<void> NotificationRouterAdapter.dispose()`

- [ ] **Step 1: Write failing mapping tests**

```dart
test('task location preserves only encoded task id', () {
  expect(
    const NotificationRouteLocationMapper().locationFor(
      const NotificationTaskRouteIntent('task_1'),
    ),
    '/?panel=tasks&taskId=task_1',
  );
});

test('finance entity intents map to existing finance routes', () {
  const mapper = NotificationRouteLocationMapper();

  expect(
    mapper.locationFor(
      const NotificationDebtRouteIntent('debt-1'),
    ),
    '/finance/debts?debtId=debt-1',
  );
  expect(
    mapper.locationFor(
      const NotificationInstallmentRouteIntent('plan-1'),
    ),
    '/finance/installments?installmentId=plan-1',
  );
});
```

Map future sections safely:

```text
habit entity      → /?panel=habits&habitId=<encoded>
challenge entity  → /?panel=challenges&challengeId=<encoded>
goal entity       → /?panel=goals&goalId=<encoded>
```

The current dashboard falls back visually to the tasks panel for panel values
that do not have screens yet. Query information remains available for the
future feature phase.

- [ ] **Step 2: Write failing adapter tests**

Use this contract:

```dart
abstract interface class NotificationNavigator {
  void go(String location);
}
```

Required tests:

```dart
test('adapter acknowledges only after successful navigation', () async {
  final queue = NotificationNavigationQueue();
  final navigator = FakeNotificationNavigator();
  final adapter = NotificationRouterAdapter(
    queue: queue,
    mapper: const NotificationRouteLocationMapper(),
    navigator: navigator,
    scheduleDelivery: (callback) => callback(),
  );
  addTearDown(adapter.dispose);
  addTearDown(queue.dispose);

  adapter.attach();
  queue.enqueue(
    const NotificationTaskRouteIntent('task-1'),
  );
  await Future<void>.delayed(Duration.zero);

  expect(
    navigator.locations,
    const <String>['/?panel=tasks&taskId=task-1'],
  );
  expect(queue.pending, isNull);
});

test('adapter retries one navigation failure and then acknowledges', () async {
  // fake navigator throws on first call and succeeds on second
  // expect two attempts and a cleared queue
});

test('adapter does not loop after two navigation failures', () async {
  // fake navigator always throws
  // expect exactly two calls and pending entry retained
});
```

The injectable `scheduleDelivery` keeps unit tests deterministic. Production
uses a post-frame callback.

- [ ] **Step 3: Implement mapper and adapter**

Production scheduler:

```dart
typedef NotificationNavigationDeliveryScheduler =
    void Function(VoidCallback callback);

void scheduleNotificationNavigationAfterFrame(
  VoidCallback callback,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    callback();
  });
}
```

Adapter state:

```dart
StreamSubscription<NotificationNavigationEntry>? _subscription;
final Set<int> _processing = <int>{};
final Map<int, int> _attempts = <int, int>{};
```

Rules:

1. Ignore an entry already being processed.
2. Attempt navigation.
3. On success, acknowledge the same token and clear attempt state.
4. On first failure, schedule one retry.
5. On second failure, retain the pending entry and stop.
6. A newer entry may still be processed normally.

- [ ] **Step 4: Wire the adapter provider**

In `app_router.dart` add:

```dart
final notificationRouterAdapterProvider =
    Provider<NotificationRouterAdapter>((ref) {
      final adapter = NotificationRouterAdapter(
        queue: ref.watch(notificationNavigationQueueProvider),
        mapper: const NotificationRouteLocationMapper(),
        navigator: GoRouterNotificationNavigator(
          ref.watch(appRouterProvider),
        ),
        scheduleDelivery:
            scheduleNotificationNavigationAfterFrame,
      );

      adapter.attach();
      ref.onDispose(adapter.dispose);
      return adapter;
    });
```

Ensure imports do not create a cycle. `persistence_providers.dart` must not
import `app_router.dart`.

In `DashboardShakhsiApp.build` instantiate the adapter before returning
`MaterialApp.router`:

```dart
ref.watch(notificationRouterAdapterProvider);
```

- [ ] **Step 5: Make dashboard panel selection query-driven**

Change constructor:

```dart
final class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    this.initialPanel = 0,
  });

  final int initialPanel;
}
```

Initialize and update state:

```dart
late int _selectedPanel;

@override
void initState() {
  super.initState();
  _selectedPanel = widget.initialPanel;
}

@override
void didUpdateWidget(covariant DashboardScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.initialPanel != widget.initialPanel) {
    _selectedPanel = widget.initialPanel;
  }
}
```

Update the dashboard route builder:

```dart
GoRoute(
  path: AppRoutes.dashboard,
  builder: (context, state) {
    final panel = state.uri.queryParameters['panel'];
    final initialPanel = panel == 'finance' ? 1 : 0;

    return DashboardScreen(
      key: ValueKey<String>(state.uri.toString()),
      initialPanel: initialPanel,
    );
  },
),
```

Unknown future panel values intentionally display the current tasks panel
until those feature screens are implemented.

- [ ] **Step 6: Run focused tests and commit**

```bash
dart format lib test

flutter test \
  test/app/router/notification_route_location_mapper_test.dart \
  test/app/router/notification_router_adapter_test.dart \
  test/features/dashboard/dashboard_notification_route_test.dart \
  test/app/bootstrap/notification_routing_bootstrap_test.dart

git add \
  lib/app/router/notification_route_location_mapper.dart \
  lib/app/router/notification_router_adapter.dart \
  lib/app/router/app_router.dart \
  lib/app/bootstrap/app_bootstrap.dart \
  lib/features/dashboard/presentation/dashboard_screen.dart \
  test/app/router/notification_route_location_mapper_test.dart \
  test/app/router/notification_router_adapter_test.dart \
  test/features/dashboard/dashboard_notification_route_test.dart \
  test/support/fake_notification_navigator.dart

git commit -m "feat: navigate notification taps through go router"
```

---

### Task 7: Task 9 Verification and Documentation Checkpoint

**Files:**
- Modify:
  `docs/superpowers/specs/2026-07-28-notification-routing-design.md`
- Create:
  `docs/architecture/notification-routing.md`
- Test:
  all Task 9 tests and full regression suite

**Interfaces:**

- No new production API.
- Produces a stable Task 9 checkpoint commit.

- [ ] **Step 1: Add architecture documentation**

Document:

- runtime tap sequence;
- cold-start sequence;
- allow-listed routes;
- queue replacement and acknowledgement semantics;
- one-retry navigation behavior;
- current fallback for future habit/challenge/goal sections;
- malformed payload handling;
- separation between routing and Linux scheduling.

Include this route table:

```text
/tasks/:id                    → /?panel=tasks&taskId=:id
/habits/:id                   → /?panel=habits&habitId=:id
/challenges/:id               → /?panel=challenges&challengeId=:id
/goals/:id                    → /?panel=goals&goalId=:id
/finance/debts/:id            → /finance/debts?debtId=:id
/finance/installments/:id     → /finance/installments?installmentId=:id
/finance/transactions/:id     → /finance/transactions?transactionId=:id
/settings                     → /settings
```

- [ ] **Step 2: Run all focused Task 9 tests**

```bash
flutter test \
  test/core/notifications/notification_route_parser_test.dart \
  test/core/notifications/notification_navigation_queue_test.dart \
  test/core/notifications/notification_response_source_test.dart \
  test/core/notifications/notification_routing_startup_test.dart \
  test/core/providers/notification_routing_providers_test.dart \
  test/app/router/notification_route_location_mapper_test.dart \
  test/app/router/notification_router_adapter_test.dart \
  test/app/bootstrap/notification_routing_bootstrap_test.dart \
  test/features/dashboard/dashboard_notification_route_test.dart
```

Expected: all focused tests pass with zero failures.

- [ ] **Step 3: Run complete verification**

```bash
flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

Expected:

```text
No issues found!
All tests passed!
✓ Built build/linux/x64/debug/bundle/dashboard_shakhsi
```

Do not claim completion unless the fresh command output confirms all four
checks.

- [ ] **Step 4: Commit the Task 9 checkpoint**

```bash
git add -A

git commit -m "docs: complete notification routing checkpoint"

git push

git status
git log -5 --oneline --decorate
```

Expected final Git status:

```text
nothing to commit, working tree clean
```

---

## Plan Self-Review

### Spec coverage

- Typed intents: Task 1
- Safe allow-list parser: Task 1
- Exactly-once queue: Task 2
- Runtime payload source: Task 3
- Cold-start launch details: Task 3
- Routing startup and retry: Task 4
- Riverpod wiring: Task 5
- Bootstrap error isolation: Task 5
- GoRouter-only adapter boundary: Task 6
- Post-frame routing: Task 6
- One controlled retry: Task 6
- Dashboard section selection without redesign: Task 6
- Full regression and architecture docs: Task 7

No approved design requirement is intentionally omitted.

### Type consistency

- Parser returns `NotificationRouteParseResult`.
- Success contains `NotificationRouteIntent`.
- Queue accepts `NotificationRouteIntent` and emits
  `NotificationNavigationEntry`.
- Startup consumes parser success and enqueues its intent.
- Adapter consumes queue entries and acknowledges by `token`.
- Mapper accepts the same `NotificationRouteIntent` type.
- Driver implements the exact
  `NotificationLaunchDetailsGateway.initialPayload()` signature.

### Scope check

The plan remains limited to click routing and cold-start delivery. Linux
systemd scheduling, permission UI, task detail screens, external deep links,
and notification action buttons remain outside Task 9.
