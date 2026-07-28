# Notification Click Routing — Phase 1 Checkpoint

Date: 2026-07-28  
Phase: 1  
Task: 9  
Status: Pending final repository verification

## Scope completed

Notification click routing is split into independently tested boundaries:

1. Safe payload parser and typed route intents
2. Exactly-once navigation queue
3. Runtime response source and cold-start gateway
4. Startup orchestration service
5. Riverpod lifecycle and bootstrap providers
6. Allow-listed GoRouter adapter and router lifecycle binding
7. End-to-end verification checkpoint

## Routing flow

```text
Native notification response
        │
        ▼
NotificationResponseSource / ColdStartGateway
        │
        ▼
NotificationRouteParser
        │ typed allow-listed intent
        ▼
NotificationNavigationQueue
        │ waits for router readiness
        ▼
GoRouterNotificationAdapter
        │ safe mapped location
        ▼
GoRouter
```

Raw notification routes are never passed directly to GoRouter.

## Supported locations

```text
/tasks/:id
/habits/:id
/challenges/:id
/goals/:id
/finance/debts/:id
/finance/installments/:id
/finance/transactions/:id
/tasks
/finance
/settings
```

Entity IDs are restricted to `A-Z`, `a-z`, `0-9`, underscore, and hyphen,
with a maximum length of 128 characters.

## Failure behavior

- Malformed JSON is ignored.
- Unsupported payload versions are ignored.
- Unknown routes are ignored.
- Empty or unsafe entity IDs are ignored.
- Startup notification failures do not block application rendering.
- Runtime responses received during cold-start loading are buffered.
- Cold-start navigation is processed before buffered runtime responses.
- Consumed cold-start details are not replayed.
- Router unmount or replacement pauses queue delivery.

## Linux limitation

`flutter_local_notifications` supports immediate delivery on Linux but does
not provide native scheduled notifications or pending scheduled request
inspection. Future Linux scheduling remains persisted in Drift and requires
the separate systemd user-timer task.

This limitation does not prevent handling a click on an immediate Linux
notification while the desktop integration supports the response callback.

## Automated verification gate

Before this checkpoint can be marked complete, run:

```bash
flutter test test/app/router/notification_click_routing_end_to_end_test.dart
flutter analyze
flutter test
flutter build linux --debug
git diff --check
```

Record the actual test count and build output in the commit or handoff. Do not
claim Android, Windows, or macOS runtime delivery from a Linux-only build.

## Manual native smoke checklist

Run on each supported target when that target becomes available:

1. Launch normally and confirm no navigation occurs.
2. Tap a valid immediate notification while the app is open.
3. Tap a valid notification that launches a closed app.
4. Tap a notification with malformed or unknown payload.
5. Confirm each valid click navigates once.
6. Confirm an invalid click leaves the current screen unchanged.

## Deferred work outside Task 9

- Linux systemd user-timer scheduling
- Entity detail screens that belong to later product phases
- Release-target signing and installer verification
