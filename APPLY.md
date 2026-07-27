# Phase 1 — Task 1 GREEN

The RED tests have already been observed failing. Apply this overlay at the
repository root, then run the focused tests, analyzer, and full suite.

```bash
unzip -o dashboard-shakhsi-v2-phase1-task1-green.zip -d .
python3 tool/verify_phase1_task1_green.py

flutter test \
  test/core/date_time/local_day_boundary_test.dart \
  test/core/notifications/notification_request_test.dart \
  test/core/notifications/fake_notification_scheduler_test.dart

flutter analyze
flutter test
```

Do not claim success until all commands pass on the user's Flutter environment.
