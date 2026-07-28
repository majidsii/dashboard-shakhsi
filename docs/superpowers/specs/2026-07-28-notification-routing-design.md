# Phase 1 — Task 9 Design
## Notification Click Routing and Cold-Start Delivery

Date: 2026-07-28  
Project: dashboard-shakhsi v2  
Branch: `feat/v2-complete-dashboard`

## 1. Goal

Complete the notification interaction flow without coupling the notification
plugin directly to `go_router`.

When the user taps a notification, the application must:

1. decode the notification payload safely;
2. convert it into a typed navigation intent;
3. queue the intent when the router is not ready yet;
4. deliver it exactly once when navigation becomes available;
5. open the correct task, habit, challenge, goal, or application section;
6. ignore malformed, unsupported, or stale payloads without crashing.

This task covers both:

- a running application receiving a notification tap;
- a cold start caused by a notification tap.

## 2. Scope

### Included

- Typed `NotificationRouteIntent`
- Payload-to-route parser
- Route allow-list and route normalization
- Pending intent queue
- Exactly-once intent consumption
- Cold-start notification response retrieval
- Foreground/background notification response handling
- Riverpod runtime wiring
- `go_router` navigation adapter
- Unit and provider tests
- Bootstrap integration tests

### Excluded

- Linux systemd notification scheduling
- Task, habit, challenge, and goal feature screens that do not exist yet
- Creating missing domain records
- Deep-link support from external URLs
- Notification action buttons
- Permission UI
- Visual changes to the application

Unknown destination records must route to their existing parent section rather
than crash. For example, a notification referencing a deleted task opens the
tasks section after the feature repository confirms the record is unavailable.
The repository-aware fallback itself belongs to the feature phase; Task 9 only
provides typed route information.

## 3. Architecture

The notification plugin must not know about `GoRouter`.

The flow is divided into four independent units:

```text
FlutterLocalNotificationsPlugin
            │
            ▼
NotificationResponseSource
            │ raw payload
            ▼
NotificationRouteParser
            │ typed intent
            ▼
NotificationNavigationQueue
            │ exactly-once stream/state
            ▼
NotificationRouterAdapter
            │
            ▼
GoRouter
```

### 3.1 NotificationResponseSource

Responsibilities:

- expose the payload delivered by a notification tap;
- expose the initial payload used to launch the application;
- forward runtime notification responses;
- never perform navigation;
- never decode domain routing rules.

The existing `FlutterLocalNotificationsDriver` will forward payloads to this
source through its current `onPayload` callback.

Cold-start payload retrieval will use the plugin's launch-details API through a
small gateway abstraction so the code remains testable without a platform
plugin.

### 3.2 NotificationRouteIntent

A sealed, typed domain model representing supported destinations.

Initial variants:

- `NotificationTaskRouteIntent(taskId)`
- `NotificationHabitRouteIntent(habitId)`
- `NotificationChallengeRouteIntent(challengeId)`
- `NotificationGoalRouteIntent(goalId)`
- `NotificationSectionRouteIntent(section)`
- `NotificationUnknownRouteIntent`

The final unknown variant is internal to parsing and must not be sent to the
router.

Route intents contain identifiers only. They do not contain a `BuildContext`,
`GoRouter`, plugin response, or raw JSON.

### 3.3 NotificationRouteParser

Responsibilities:

- decode the existing versioned `NotificationPayloadCodec`;
- read only supported routing keys;
- validate identifiers;
- normalize route names;
- reject unsupported payload versions;
- return a typed result instead of throwing to the UI.

Parsing result:

```text
success(intent)
ignored(reason)
```

Ignore reasons include:

- malformed payload;
- unsupported payload version;
- absent route data;
- unsupported destination;
- blank identifier.

No raw route string from a payload may be passed directly to `GoRouter`.

### 3.4 NotificationNavigationQueue

A small in-memory queue that stores at most one pending intent.

Rules:

- the newest valid notification tap replaces an older unconsumed intent;
- identical consecutive intents are deduplicated;
- an intent is removed only after the router adapter confirms consumption;
- bootstrap may enqueue before the widget tree or router exists;
- runtime taps may enqueue while the application is already open;
- malformed payloads never enter the queue.

This avoids losing a cold-start notification before router initialization.

### 3.5 NotificationRouterAdapter

The only component that depends on `go_router`.

Responsibilities:

- watch the navigation queue;
- map typed intents to application routes;
- navigate after the root router is ready;
- acknowledge successful consumption;
- preserve the current page when an intent is ignored;
- never decode raw payloads.

Route mapping must use named application route helpers or centralized path
builders. Literal paths must not be scattered across notification code.

## 4. Data Flow

### 4.1 Running application

```text
User taps notification
→ plugin callback receives payload
→ response source forwards payload
→ parser returns typed intent
→ queue stores intent
→ router adapter observes intent
→ GoRouter navigates
→ queue acknowledges and clears intent
```

### 4.2 Cold start

```text
Application bootstrap starts
→ notification plugin initializes
→ launch-details gateway reads initial response
→ parser returns typed intent
→ queue stores intent
→ ProviderContainer and router start
→ router adapter becomes ready
→ GoRouter navigates
→ queue acknowledges and clears intent
```

### 4.3 Invalid payload

```text
Plugin returns malformed payload
→ parser returns ignored(reason)
→ optional diagnostic is reported
→ no queue mutation
→ no navigation
→ application continues normally
```

## 5. Error Handling

- Plugin launch-details failures are reported through `FlutterError` and do not
  prevent application startup.
- Payload decode errors are converted to typed ignored results.
- Navigation failures retain the pending intent for one controlled retry.
- Repeated navigation failure must not create an infinite loop.
- Unsupported routes are ignored safely.
- Notification taps received before initialization are buffered by the response
  source.
- Duplicate callbacks for the same payload do not navigate twice.

No exception from notification routing may terminate application startup.

## 6. Riverpod Wiring

New providers:

- `notificationLaunchDetailsGatewayProvider`
- `notificationResponseSourceProvider`
- `notificationRouteParserProvider`
- `notificationNavigationQueueProvider`
- `notificationRoutingStartupProvider`
- `notificationRouterAdapterProvider`

The existing notification startup service remains responsible for plugin and
schedule reconciliation.

A separate routing startup service handles:

1. initial notification response retrieval;
2. payload parsing;
3. queue insertion.

This separation ensures a routing failure does not affect persisted schedule
reconciliation.

## 7. Bootstrap and UI Integration

Bootstrap order:

1. create `ProviderContainer`;
2. initialize timezone and notification plugin;
3. reconcile persisted schedules;
4. read cold-start notification response;
5. start the application;
6. attach the router adapter after `GoRouter` exists;
7. consume a queued intent exactly once.

No visual layout changes are included.

## 8. Testing Strategy

### Unit tests

- supported payloads map to the correct typed intent;
- malformed JSON is ignored;
- unsupported payload version is ignored;
- blank identifiers are ignored;
- route strings are not accepted outside the allow-list;
- duplicate intents are deduplicated;
- newest unconsumed intent replaces an older intent;
- acknowledgement clears only the consumed intent;
- failed navigation retains the intent for retry.

### Driver/gateway tests

- runtime payload callback reaches the response source;
- cold-start launch details are read once;
- absent launch payload produces no navigation;
- plugin failure does not crash startup.

### Provider tests

- provider graph resolves without the platform plugin when overridden;
- routing startup enqueues a valid initial intent;
- invalid initial payload leaves the queue empty;
- unsupported platforms remain safe.

### Bootstrap tests

- cold-start payload is captured before router attachment;
- router attachment consumes it once;
- normal startup performs no navigation.

### Regression tests

- existing notification schedule tests remain unchanged;
- existing startup tests remain green;
- Linux build remains successful;
- no UI golden changes are expected.

## 9. Acceptance Criteria

Task 9 is complete when:

- notification payloads are never routed directly as raw strings;
- runtime taps navigate through typed intents;
- cold-start taps are retained until the router is ready;
- each valid tap navigates at most once;
- malformed payloads cannot crash startup;
- unsupported destinations do not navigate;
- notification plugin and `go_router` remain separated by interfaces;
- focused tests, full tests, analyzer, and Linux debug build pass;
- the architecture is documented and committed.

## 10. Planned Implementation Tasks

1. Add typed route intents and parser with RED/GREEN tests.
2. Add navigation queue and exactly-once semantics.
3. Add launch-details gateway and response source.
4. Wire routing startup into Riverpod and bootstrap.
5. Add the `go_router` adapter and route mapping.
6. Run full regression verification and commit Task 9.

These implementation steps remain inside Phase 1. Phase 2 must not begin until
Task 9, Linux scheduling, and final Phase 1 hardening are complete.
