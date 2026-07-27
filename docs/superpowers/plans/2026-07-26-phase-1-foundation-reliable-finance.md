# Phase 1: Foundation and Reliable Finance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-quality Flutter foundation and a complete, trustworthy offline finance module that preserves the current Liquid Glass identity across Android, iOS, Windows, Linux, and macOS.

**Architecture:** Create the Flutter application in `app/` so the current WebView implementation remains available as a migration reference until final cutover. Use feature-owned domain/application/data/presentation boundaries, Riverpod for dependency wiring and isolated state, Drift for transactional SQLite persistence, and explicit adapters for notifications, files, timezones, and legacy import.

**Tech Stack:** Flutter 3.44.7, Dart 3.12.2, `flutter_riverpod` 3.3.2, `go_router` 17.3.0, `drift` 2.34.2, `drift_flutter` 0.3.1, `flutter_local_notifications` 22.1.0, `timezone` 0.11.1, `flutter_timezone` 5.1.0, `shamsi_date` 1.1.1, `fl_chart` 1.2.0, `path_provider` 2.1.6, `file_picker` 11.0.2, `cryptography` 2.9.0, `flutter_secure_storage` 10.3.1, `uuid` 4.6.0.

## Global Constraints

- Target Android API 24+, iOS 13+, macOS 10.15+, Windows 10+, and current supported Ubuntu LTS desktop builds.
- Preserve package/bundle identifier `ir.dashboard.shakhsi` for release builds; debug builds use a `.dev` suffix where the platform supports it.
- Keep the application Persian-first, RTL, and offline-first; no core screen may require network access.
- Store instants in UTC milliseconds and date-only values as ISO Gregorian local dates; display Jalali dates by default.
- Store money as signed 64-bit integer minor units plus a currency code; default user currency is `IRT` with scale `0`.
- SQLite is the source of truth; repository writes that affect multiple records must use one database transaction.
- Refunds reduce the original expense category and never inflate income.
- Transfers never count as income or expense.
- Balance adjustments affect account balance but not normal income/expense reports.
- Installments, debts, receivables, and their dashboards belong only to Finance.
- OS notifications can be globally disabled while in-app warnings remain active.
- Notification copy is short, conversational Persian; privacy settings can hide amounts and details.
- Preserve light, dark, and follow-system themes.
- Nested blur inside scrolling lists is prohibited; only major surfaces may use `BackdropFilter`.
- Every task begins with a failing test, ends with passing targeted tests, and receives a focused commit.
- Do not replace the stable legacy release until migration and rollback acceptance tests pass.

---

## Locked File Structure

```text
app/
├── pubspec.yaml
├── analysis_options.yaml
├── assets/
│   ├── fonts/vazirmatn/
│   └── icons/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── bootstrap/app_bootstrap.dart
│   │   ├── router/app_router.dart
│   │   ├── shell/adaptive_app_shell.dart
│   │   ├── shell/app_destination.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── glass_tokens.dart
│   │       └── liquid_glass_theme_extension.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── app_database.g.dart
│   │   │   ├── database_migrations.dart
│   │   │   └── database_provider.dart
│   │   ├── date_time/
│   │   │   ├── app_clock.dart
│   │   │   ├── local_date.dart
│   │   │   ├── jalali_date_formatter.dart
│   │   │   └── timezone_service.dart
│   │   ├── recurrence/
│   │   │   ├── recurrence_rule.dart
│   │   │   ├── occurrence_generator.dart
│   │   │   └── working_day_calendar.dart
│   │   ├── money/money.dart
│   │   ├── ids/id_generator.dart
│   │   ├── errors/app_failure.dart
│   │   ├── notifications/
│   │   │   ├── notification_gateway.dart
│   │   │   ├── notification_models.dart
│   │   │   └── notification_reconciler.dart
│   │   ├── files/
│   │   │   ├── file_save_gateway.dart
│   │   │   └── file_picker_save_gateway.dart
│   │   ├── backup/
│   │   │   ├── backup_codec.dart
│   │   │   ├── backup_service.dart
│   │   │   ├── automatic_backup_service.dart
│   │   │   ├── device_backup_key_store.dart
│   │   │   └── backup_manifest.dart
│   │   └── widgets/
│   │       ├── liquid_glass_surface.dart
│   │       ├── liquid_glass_card.dart
│   │       ├── liquid_glass_button.dart
│   │       ├── liquid_glass_field.dart
│   │       ├── liquid_glass_dialog.dart
│   │       ├── liquid_glass_bottom_sheet.dart
│   │       ├── liquid_glass_segmented_control.dart
│   │       ├── liquid_glass_toast.dart
│   │       └── liquid_glass_empty_state.dart
│   └── features/
│       ├── settings/
│       ├── dashboard/
│       ├── finance/
│       ├── financial_calendar/
│       ├── debts/
│       ├── installments/
│       ├── notifications/
│       ├── export/
│       ├── backup/
│       ├── migration/
│       └── onboarding/
├── test/
├── integration_test/
└── tool/
    ├── extract_legacy_vazirmatn.py
    ├── generate_finance_fixture.dart
    └── verify_no_nested_blur.dart
```

Feature folders use this internal convention only when the layers are needed:

```text
feature/
├── domain/
├── application/
├── data/
└── presentation/
```

Do not create empty layer folders. A file belongs in the smallest feature that owns its rule.

---

### Task 1: Scaffold the Flutter application and deterministic toolchain

**Files:**
- Create: `app/` Flutter project and all generated platform runners
- Create: `app/.flutter-version`
- Create: `app/analysis_options.yaml`
- Create: `app/test/app_smoke_test.dart`
- Create: `.github/workflows/flutter-ci.yml`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: approved design specification at `docs/superpowers/specs/2026-07-26-personal-dashboard-rebuild-design.md`
- Produces: buildable `dashboard_shakhsi` Flutter package and CI commands used by every later task

- [ ] **Step 1: Write the failing repository-layout test**

Create `tests/test_flutter_layout.py`:

```python
from pathlib import Path


def test_flutter_app_has_all_native_targets():
    root = Path(__file__).parents[1] / "app"
    assert (root / "pubspec.yaml").is_file()
    for platform in ("android", "ios", "linux", "macos", "windows"):
        assert (root / platform).is_dir()
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
python3 -m pytest tests/test_flutter_layout.py -q
```

Expected: FAIL because `app/pubspec.yaml` does not exist.

- [ ] **Step 3: Scaffold the application without modifying the legacy implementation**

Run:

```bash
flutter create \
  --platforms=android,ios,linux,macos,windows \
  --org ir.dashboard \
  --project-name dashboard_shakhsi \
  app
printf '3.44.7\n' > app/.flutter-version
```

Set release identifiers to `ir.dashboard.shakhsi` in:

- `app/android/app/build.gradle.kts`
- `app/ios/Runner.xcodeproj/project.pbxproj`
- `app/macos/Runner/Configs/AppInfo.xcconfig`

Add Android debug suffix:

```kotlin
buildTypes {
    getByName("debug") {
        applicationIdSuffix = ".dev"
    }
}
```

- [ ] **Step 4: Add pinned Phase 1 dependencies**

Replace the dependency sections of `app/pubspec.yaml` with:

```yaml
environment:
  sdk: ">=3.12.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^3.3.2
  go_router: ^17.3.0
  drift: ^2.34.2
  drift_flutter: ^0.3.1
  flutter_local_notifications: ^22.1.0
  timezone: ^0.11.1
  flutter_timezone: ^5.1.0
  shamsi_date: ^1.1.1
  fl_chart: ^1.2.0
  path_provider: ^2.1.6
  file_picker: ^11.0.2
  cryptography: ^2.9.0
  flutter_secure_storage: ^10.3.1
  uuid: ^4.6.0
  intl: ^0.20.2
  collection: ^1.19.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  drift_dev: ^2.34.2
  build_runner: ^2.7.1
  flutter_lints: ^6.0.0
  mocktail: ^1.0.4
```

Run:

```bash
cd app
flutter pub get
```

- [ ] **Step 5: Add strict analysis and a smoke test**

Create `app/test/app_smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test harness runs', () {
    expect(1 + 1, 2);
  });
}
```

Create `app/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_use_of_visible_for_testing_member: error
    missing_required_param: error
    dead_code: error

linter:
  rules:
    always_declare_return_types: true
    avoid_dynamic_calls: true
    avoid_print: true
    cancel_subscriptions: true
    close_sinks: true
    directives_ordering: true
    prefer_final_locals: true
    require_trailing_commas: true
    sort_constructors_first: true
    unawaited_futures: true
```

- [ ] **Step 6: Add CI**

Create `.github/workflows/flutter-ci.yml` with jobs that run from `app/`:

```yaml
name: Flutter CI
on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.7'
          channel: stable
          cache: true
      - name: Install Linux desktop build dependencies
        run: sudo apt-get update && sudo apt-get install -y ninja-build libgtk-3-dev libsecret-1-0 libsecret-1-dev
      - run: flutter pub get
        working-directory: app
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: app
      - run: flutter analyze
        working-directory: app
      - run: flutter test
        working-directory: app
      - run: flutter build apk --debug
        working-directory: app
      - run: flutter build linux --debug
        working-directory: app
```

- [ ] **Step 7: Verify scaffold and commit**

Run:

```bash
python3 -m pytest tests/test_flutter_layout.py -q
cd app
flutter analyze
flutter test
cd ..
```

Expected: all commands PASS.

Commit:

```bash
git add app .github/workflows/flutter-ci.yml .gitignore tests/test_flutter_layout.py
git commit -m "chore: scaffold Flutter cross-platform application"
```

---

### Task 2: Add core value objects, IDs, clock, dates, and failures

**Files:**
- Create: `app/lib/core/money/money.dart`
- Create: `app/lib/core/ids/id_generator.dart`
- Create: `app/lib/core/date_time/app_clock.dart`
- Create: `app/lib/core/date_time/local_date.dart`
- Create: `app/lib/core/errors/app_failure.dart`
- Test: `app/test/core/money/money_test.dart`
- Test: `app/test/core/date_time/local_date_test.dart`

**Interfaces:**
- Consumes: Dart SDK and `uuid`
- Produces: `Money`, `LocalDate`, `AppClock`, `IdGenerator`, and `AppFailure` used by all domain services

- [ ] **Step 1: Write failing money tests**

```dart
import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money arithmetic requires the same currency and scale', () {
    const income = Money(minorUnits: 50_000_000, currencyCode: 'IRT', scale: 0);
    const expense = Money(minorUnits: 12_500_000, currencyCode: 'IRT', scale: 0);

    expect(income - expense, const Money(minorUnits: 37_500_000, currencyCode: 'IRT', scale: 0));
    expect(
      () => income + const Money(minorUnits: 1, currencyCode: 'USD', scale: 2),
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 2: Run and verify failure**

```bash
cd app
flutter test test/core/money/money_test.dart
```

Expected: FAIL because `Money` does not exist.

- [ ] **Step 3: Implement `Money`**

```dart
final class Money {
  const Money({
    required this.minorUnits,
    required this.currencyCode,
    required this.scale,
  });

  final int minorUnits;
  final String currencyCode;
  final int scale;

  Money operator +(Money other) {
    _requireCompatible(other);
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currencyCode: currencyCode,
      scale: scale,
    );
  }

  Money operator -(Money other) {
    _requireCompatible(other);
    return Money(
      minorUnits: minorUnits - other.minorUnits,
      currencyCode: currencyCode,
      scale: scale,
    );
  }

  void _requireCompatible(Money other) {
    if (currencyCode != other.currencyCode || scale != other.scale) {
      throw ArgumentError('Money values use different currency definitions.');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode, scale);
}
```

- [ ] **Step 4: Write and implement date-only behavior**

Test:

```dart
final date = LocalDate.parseIso('2026-07-26');
expect(date.toIso(), '2026-07-26');
expect(date.toUtcStart(), DateTime.utc(2026, 7, 26));
```

Implementation stores `year`, `month`, and `day`, validates using a UTC `DateTime`, and never constructs a local-midnight instant for persistence.

- [ ] **Step 5: Implement stable IDs and clocks**

```dart
abstract interface class AppClock {
  DateTime nowUtc();
  DateTime nowLocal();
}

final class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime nowLocal() => DateTime.now();
}

abstract interface class IdGenerator {
  String next();
}
```

`UuidV7IdGenerator.next()` returns `const Uuid().v7()`.

- [ ] **Step 6: Add typed failures**

Define:

```dart
sealed class AppFailure implements Exception {
  const AppFailure(this.userMessage, {this.cause});
  final String userMessage;
  final Object? cause;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.userMessage);
}

final class PersistenceFailure extends AppFailure {
  const PersistenceFailure(super.userMessage, {super.cause});
}
```

- [ ] **Step 7: Run tests and commit**

```bash
cd app
flutter test test/core
flutter analyze
git add lib/core test/core
git commit -m "feat: add core money date and failure primitives"
```

---

### Task 3: Bootstrap Riverpod, global error handling, localization, and routing

**Files:**
- Create: `app/lib/main.dart`
- Create: `app/lib/app/bootstrap/app_bootstrap.dart`
- Create: `app/lib/app/router/app_router.dart`
- Create: `app/lib/features/dashboard/presentation/dashboard_screen.dart`
- Test: `app/test/app/bootstrap/app_bootstrap_test.dart`

**Interfaces:**
- Consumes: core primitives from Task 2
- Produces: `bootstrapApp()`, root `ProviderScope`, `GoRouter`, Persian locale, and a stable app entry point

- [ ] **Step 1: Write a failing bootstrap widget test**

```dart
await tester.pumpWidget(const ProviderScope(child: DashboardShakhsiApp()));
await tester.pumpAndSettle();
expect(find.text('داشبورد'), findsOneWidget);
expect(Directionality.of(tester.element(find.text('داشبورد'))), TextDirection.rtl);
```

- [ ] **Step 2: Verify the test fails**

```bash
cd app
flutter test test/app/bootstrap/app_bootstrap_test.dart
```

- [ ] **Step 3: Implement application bootstrap**

```dart
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    return true;
  };

  runApp(const ProviderScope(child: DashboardShakhsiApp()));
}
```

`main()` only calls `bootstrapApp()`.

- [ ] **Step 4: Configure Persian localization and RTL**

Use `MaterialApp.router` only as the Flutter host; replace visible Material surfaces with custom Liquid Glass components in later tasks.

```dart
return MaterialApp.router(
  debugShowCheckedModeBanner: false,
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR'), Locale('en', 'US')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  routerConfig: ref.watch(appRouterProvider),
);
```

- [ ] **Step 5: Configure initial routes**

Create named paths:

```text
/
/finance
/finance/transactions
/finance/calendar
/finance/debts
/finance/installments
/settings
/backup
/migration
```

Use `StatefulShellRoute.indexedStack` so adaptive navigation keeps feature state alive.

- [ ] **Step 6: Run tests and commit**

```bash
cd app
flutter test test/app/bootstrap
flutter analyze
git add lib/main.dart lib/app lib/features/dashboard test/app
git commit -m "feat: bootstrap localized Flutter application"
```

---

### Task 4: Extract and implement the Liquid Glass token system

**Files:**
- Create: `app/lib/app/theme/glass_tokens.dart`
- Create: `app/lib/app/theme/liquid_glass_theme_extension.dart`
- Create: `app/lib/app/theme/app_theme.dart`
- Create: `app/tool/extract_legacy_vazirmatn.py`
- Create from the embedded legacy asset: `app/assets/fonts/vazirmatn/Vazirmatn-Variable.ttf`
- Copy: `src/fonts/OFL.txt` to `app/assets/fonts/vazirmatn/OFL.txt`
- Test: `app/test/app/theme/glass_tokens_test.dart`

**Interfaces:**
- Consumes: visual values from legacy `src/app.html`
- Produces: `GlassTokens.light`, `GlassTokens.dark`, `LiquidGlassThemeExtension`, and `buildAppTheme()`

- [ ] **Step 1: Write token parity tests**

```dart
test('dark theme preserves the legacy Apple accent colors', () {
  expect(GlassTokens.dark.accent, const Color(0xFF0A84FF));
  expect(GlassTokens.dark.income, const Color(0xFF30D158));
  expect(GlassTokens.dark.expense, const Color(0xFFFF453A));
  expect(GlassTokens.dark.majorBlurSigma, 28);
});
```

- [ ] **Step 2: Verify failure**

```bash
cd app
flutter test test/app/theme/glass_tokens_test.dart
```

- [ ] **Step 3: Implement immutable token sets**

Include exact legacy values:

```dart
static const dark = GlassTokens(
  backgroundStart: Color(0xFF080A13),
  backgroundMiddle: Color(0xFF05060D),
  backgroundEnd: Color(0xFF030409),
  accent: Color(0xFF0A84FF),
  accentSecondary: Color(0xFF64D2FF),
  income: Color(0xFF30D158),
  expense: Color(0xFFFF453A),
  warning: Color(0xFFFF9F0A),
  violet: Color(0xFFBF5AF2),
  majorBlurSigma: 28,
  fieldBlurSigma: 12,
  cardRadius: 28,
  surfaceRadius: 26,
  fieldRadius: 16,
);
```

Create equivalent light values from legacy CSS.

- [ ] **Step 4: Add theme/accessibility modifiers**

`GlassAccessibility` has:

```dart
const GlassAccessibility({
  required this.reduceTransparency,
  required this.reduceMotion,
  required this.increaseContrast,
});
```

`GlassTokens.resolve(accessibility)` returns:

- opacity increased when transparency is reduced
- zero/short motion duration when motion is reduced
- stronger borders and text colors when contrast is increased

- [ ] **Step 5: Extract the embedded legacy Vazirmatn asset and register it**

The current app embeds one WOFF2 variable font inside `src/app.html`; `src/fonts/` contains only its OFL license. Create `app/tool/extract_legacy_vazirmatn.py` that:

1. finds the `data:font/woff2;base64,...` payload in `src/app.html`
2. decodes it to a temporary `.woff2` file
3. uses `fontTools.ttLib.TTFont` to remove the WOFF2 flavor and save `Vazirmatn-Variable.ttf`
4. fails when exactly one embedded font is not found

Run:

```bash
python3 -m venv .tooling/fonttools
.tooling/fonttools/bin/pip install fonttools brotli
.tooling/fonttools/bin/python app/tool/extract_legacy_vazirmatn.py \
  src/app.html \
  app/assets/fonts/vazirmatn/Vazirmatn-Variable.ttf
cp src/fonts/OFL.txt app/assets/fonts/vazirmatn/OFL.txt
```

Add `.tooling/` to the repository `.gitignore`; the generated TTF and OFL license are committed, but the local extraction environment is not.

Register the variable asset:

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: Vazirmatn
      fonts:
        - asset: assets/fonts/vazirmatn/Vazirmatn-Variable.ttf
```

Add a script test that checks the output begins with a valid TrueType/OpenType signature and that the OFL file is bundled.

- [ ] **Step 6: Run tests and commit**

```bash
cd app
flutter test test/app/theme
flutter analyze
git add lib/app/theme assets/fonts tool/extract_legacy_vazirmatn.py pubspec.yaml test/app/theme
git commit -m "feat: add Liquid Glass theme tokens"
```

---

### Task 5: Build performant Liquid Glass primitives

**Files:**
- Create: `app/lib/core/widgets/liquid_glass_surface.dart`
- Create: `app/lib/core/widgets/liquid_glass_card.dart`
- Create: `app/lib/core/widgets/liquid_glass_button.dart`
- Create: `app/lib/core/widgets/liquid_glass_field.dart`
- Create: `app/lib/core/widgets/liquid_glass_dialog.dart`
- Create: `app/lib/core/widgets/liquid_glass_bottom_sheet.dart`
- Create: `app/lib/core/widgets/liquid_glass_segmented_control.dart`
- Create: `app/lib/core/widgets/liquid_glass_toast.dart`
- Create: `app/lib/core/widgets/liquid_glass_empty_state.dart`
- Create: `app/tool/verify_no_nested_blur.dart`
- Test: `app/test/core/widgets/liquid_glass_surface_test.dart`

**Interfaces:**
- Consumes: `LiquidGlassThemeExtension`
- Produces: reusable visual primitives used by all screens

- [ ] **Step 1: Write widget tests for accessibility and blur policy**

```dart
await tester.pumpWidget(
  testApp(
    const LiquidGlassSurface(
      semanticLabel: 'کارت آزمایشی',
      child: Text('محتوا'),
    ),
  ),
);
expect(find.byType(BackdropFilter), findsOneWidget);
expect(find.bySemanticsLabel('کارت آزمایشی'), findsOneWidget);
```

Add a second test where reduced transparency is enabled and expect zero `BackdropFilter` widgets.

- [ ] **Step 2: Implement one-blur surface composition**

The widget tree is:

```text
RepaintBoundary
└── ClipRRect
    └── BackdropFilter (major surfaces only)
        └── DecoratedBox (fill, rim border, sheen, shadow)
            └── child
```

Do not wrap a `LiquidGlassCard` in another `LiquidGlassSurface` with blur enabled. `LiquidGlassCard` defaults to `blur: false` when used in a scrolling collection.

- [ ] **Step 3: Implement interaction primitives**

All mobile controls enforce a minimum `48x48` logical-pixel hit target. Buttons expose loading, disabled, destructive, and icon-only states. Fields preserve entered text after validation failure.

- [ ] **Step 4: Add a source scanner for nested blur**

`tool/verify_no_nested_blur.dart` scans feature presentation files and fails when a `ListView.builder`, `SliverList`, or `ReorderableListView` item builder directly contains `BackdropFilter`.

Run:

```bash
cd app
dart run tool/verify_no_nested_blur.dart
```

- [ ] **Step 5: Add golden tests for light/dark/reduced transparency**

Create goldens at widths 390 and 1280 for `LiquidGlassCard`, `LiquidGlassField`, and `LiquidGlassSegmentedControl`.

- [ ] **Step 6: Verify and commit**

```bash
cd app
flutter test test/core/widgets
dart run tool/verify_no_nested_blur.dart
flutter analyze
git add lib/core/widgets test/core/widgets tool
git commit -m "feat: add performant Liquid Glass components"
```

---

### Task 6: Implement adaptive application shell and destination model

**Files:**
- Create: `app/lib/app/shell/app_destination.dart`
- Create: `app/lib/app/shell/adaptive_app_shell.dart`
- Modify: `app/lib/app/router/app_router.dart`
- Test: `app/test/app/shell/adaptive_app_shell_test.dart`

**Interfaces:**
- Consumes: router and Liquid Glass navigation components
- Produces: width-driven mobile/tablet/desktop navigation and persistent shell state

- [ ] **Step 1: Write failing breakpoint tests**

Use these locked widths:

```dart
const mobileMax = 699.0;
const tabletMax = 1099.0;
```

Tests:

```dart
await pumpAtWidth(tester, 390);
expect(find.byKey(const Key('mobile-bottom-navigation')), findsOneWidget);

await pumpAtWidth(tester, 820);
expect(find.byKey(const Key('tablet-navigation-rail')), findsOneWidget);

await pumpAtWidth(tester, 1280);
expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
```

- [ ] **Step 2: Implement destination ownership**

`AppDestination` contains route, Persian label, icon, and placement groups. Mobile destinations are:

```text
خانه | مالی | افزودن | برنامه | بیشتر
```

Phase 1 routes hidden behind `برنامه` display a calm unavailable-state explaining that tasks/time modules arrive in the next milestone; do not create fake data or inactive buttons without explanation.

- [ ] **Step 3: Implement width-driven shell**

Use `LayoutBuilder`; never branch only on `TargetPlatform`. Preserve the same route state while changing widths.

- [ ] **Step 4: Verify focus and keyboard navigation**

Desktop sidebar destinations must be focusable and activatable with Enter/Space. Tab order follows visual order in RTL.

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/app/shell
flutter analyze
git add lib/app/shell lib/app/router/app_router.dart test/app/shell
git commit -m "feat: add adaptive navigation shell"
```

---

### Task 7: Create Drift database schema v1 and migration harness

**Files:**
- Create: `app/lib/core/database/app_database.dart`
- Generate: `app/lib/core/database/app_database.g.dart`
- Create: `app/lib/core/database/database_migrations.dart`
- Create: `app/lib/core/database/database_provider.dart`
- Test: `app/test/core/database/schema_v1_test.dart`
- Test: `app/test/core/database/migration_test.dart`

**Interfaces:**
- Consumes: `drift`, `drift_flutter`, `LocalDate`
- Produces: `AppDatabase`, schema version 1, transaction API, and in-memory test constructor

- [ ] **Step 1: Write a failing schema test**

```dart
final db = AppDatabase.inMemory();
addTearDown(db.close);
expect(db.schemaVersion, 1);
expect(
  await db.customSelect("SELECT name FROM sqlite_master WHERE type='table'").get(),
  isNotEmpty,
);
```

Assert these tables exist:

```text
app_settings
accounts
finance_categories
transactions
transaction_splits
monthly_plans
category_budgets
planned_finance_items
debts
installment_plans
installment_occurrences
finance_payments
notification_rules
scheduled_notifications
recurrence_rules
calendar_exceptions
audit_events
legacy_import_runs
legacy_import_blobs
```

- [ ] **Step 2: Define shared columns and enums**

Use string enum converters with explicit stable values. Every mutable business table includes:

```text
id TEXT PRIMARY KEY
created_at_utc INTEGER NOT NULL
updated_at_utc INTEGER NOT NULL
deleted_at_utc INTEGER NULL
```

Money columns use `INTEGER`; dates use ISO `YYYY-MM-DD` text; instants use UTC epoch milliseconds.

- [ ] **Step 3: Define foreign keys and indexes**

Required indexes:

```text
transactions(account_id, occurred_at_utc)
transactions(category_id, occurred_at_utc)
transaction_splits(transaction_id)
category_budgets(monthly_plan_id, category_id)
monthly_plans(calendar_code, period_year, period_month) UNIQUE
planned_finance_items(due_date, status)
debts(direction, status, due_date)
installment_occurrences(plan_id, due_date, status)
finance_payments(debt_id, paid_at_utc)
finance_payments(installment_occurrence_id, paid_at_utc)
scheduled_notifications(source_type, source_id, fire_at_utc)
recurrence_rules(owner_type, owner_id) UNIQUE
calendar_exceptions(date, kind) UNIQUE
```

Enable foreign keys on open:

```dart
await customStatement('PRAGMA foreign_keys = ON');
```

- [ ] **Step 4: Implement migration strategy**

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => m.createAll(),
  onUpgrade: runDatabaseUpgrade,
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

`runDatabaseUpgrade` throws a `StateError` for an unknown downgrade or skipped migration path; no silent reset is allowed.

- [ ] **Step 5: Generate code and run tests**

```bash
cd app
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/database
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/database test/core/database
git commit -m "feat: add transactional finance database schema"
```

---

### Task 8: Implement settings, appearance, currency, and Jalali/timezone services

**Files:**
- Create: `app/lib/features/settings/domain/app_settings.dart`
- Create: `app/lib/features/settings/data/settings_repository.dart`
- Create: `app/lib/features/settings/application/settings_controller.dart`
- Create: `app/lib/core/date_time/jalali_date_formatter.dart`
- Create: `app/lib/core/date_time/timezone_service.dart`
- Create: `app/lib/features/settings/presentation/settings_screen.dart`
- Test: `app/test/features/settings/settings_repository_test.dart`
- Test: `app/test/core/date_time/jalali_date_formatter_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, Riverpod, `shamsi_date`, `flutter_timezone`
- Produces: persisted `AppSettings`, `settingsControllerProvider`, Jalali formatting, and timezone-change signal

- [ ] **Step 1: Write settings default tests**

Expected defaults:

```dart
const AppSettings(
  themeMode: AppThemeMode.system,
  currencyCode: 'IRT',
  currencyScale: 0,
  notificationsEnabled: true,
  financeNotificationsEnabled: true,
  taskNotificationsEnabled: true,
  habitChallengeNotificationsEnabled: true,
  goalNotificationsEnabled: true,
  morningSummaryEnabled: false,
  eveningSummaryEnabled: false,
  privateLockScreen: false,
  showFinancialAmounts: true,
  emojiEnabled: true,
  reduceTransparency: false,
  reduceMotion: false,
  increaseContrast: false,
  automaticBackupsEnabled: true,
  retainedAutomaticBackupCount: 5,
);
```

- [ ] **Step 2: Implement one-row settings repository**

`SettingsRepository.watch()` emits the current row. `save(AppSettings)` uses an upsert in a database transaction. Unknown enum strings are rejected during migration tests instead of silently selecting a different value.

- [ ] **Step 3: Implement Jalali formatting**

Required API:

```dart
abstract interface class AppDateFormatter {
  String full(LocalDate date);
  String compact(LocalDate date);
  String monthTitle(LocalDate date);
}
```

Golden outputs include Persian digits and non-breaking separators where needed.

- [ ] **Step 4: Implement timezone service**

```dart
abstract interface class TimezoneService {
  Future<String> currentIanaName();
  Stream<String> changes();
}
```

At startup initialize `timezone` data, set local location from `FlutterTimezone.getLocalTimezone()`, and emit when the name differs from the last persisted value.

- [ ] **Step 5: Build settings UI**

Include controls for:

- Light / Dark / System
- Reduce transparency
- Reduce motion
- Increase contrast
- Global notifications
- Finance notifications
- Task notifications
- Habit/challenge notifications
- Goal notifications
- Optional morning/evening summaries
- Private lock-screen content
- Show/hide amounts
- Emoji on/off

Changes save immediately but show a reversible toast when disabling all notifications.

- [ ] **Step 6: Verify and commit**

```bash
cd app
flutter test test/features/settings test/core/date_time
flutter analyze
git add lib/features/settings lib/core/date_time test/features/settings test/core/date_time
git commit -m "feat: add persisted settings and Jalali date services"
```

---

### Task 9: Implement account and finance-category repositories

**Files:**
- Create: `app/lib/features/finance/domain/account.dart`
- Create: `app/lib/features/finance/domain/finance_category.dart`
- Create: `app/lib/features/finance/domain/finance_repository.dart`
- Create: `app/lib/features/finance/data/drift_finance_repository.dart`
- Create: `app/lib/features/finance/application/account_service.dart`
- Test: `app/test/features/finance/account_service_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `Money`, `IdGenerator`, `AppClock`
- Produces: `FinanceRepository`, account/category CRUD, default-account bootstrap

- [ ] **Step 1: Write a failing default-account test**

```dart
final account = await service.ensureDefaultAccount();
expect(account.name, 'حساب اصلی');
expect(account.type, AccountType.bank);
expect(account.currencyCode, 'IRT');
expect(await service.ensureDefaultAccount(), account);
```

- [ ] **Step 2: Define domain models and repository contract**

```dart
abstract interface class FinanceRepository {
  Stream<List<Account>> watchAccounts();
  Future<Account?> getAccount(String id);
  Future<void> saveAccount(Account account);
  Future<void> softDeleteAccount(String id);
  Stream<List<FinanceCategory>> watchCategories(CategoryKind kind);
  Future<void> saveCategory(FinanceCategory category);
}
```

Account types: bank, cash, wallet, savings, other. Category kinds: income, expense.

- [ ] **Step 3: Seed stable default categories**

Expense defaults:

```text
خوراک، رفت‌وآمد، مسکن، قبوض، سلامت، آموزش، تفریح، خرید، بدهی، قسط، سایر
```

Income defaults:

```text
حقوق، پروژه، فروش، هدیه، سرمایه‌گذاری، دریافت طلب، سایر
```

Each seed has a stable ID such as `category-expense-food`; rerunning seed is idempotent.

- [ ] **Step 4: Enforce deletion rules**

An account with transactions cannot be hard-deleted. `softDeleteAccount` marks it deleted only after the user selected a replacement account or archived it with zero usable balance. The repository returns a Persian validation failure for an invalid operation.

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/features/finance/account_service_test.dart
flutter analyze
git add lib/features/finance test/features/finance
git commit -m "feat: add finance accounts and categories"
```

---

### Task 10: Implement atomic transactions, splits, transfers, refunds, and reconciliation adjustments

**Files:**
- Create: `app/lib/features/finance/domain/finance_transaction.dart`
- Create: `app/lib/features/finance/domain/transaction_split.dart`
- Create: `app/lib/features/finance/domain/transaction_commands.dart`
- Create: `app/lib/features/finance/application/transaction_service.dart`
- Modify: `app/lib/features/finance/domain/finance_repository.dart`
- Modify: `app/lib/features/finance/data/drift_finance_repository.dart`
- Test: `app/test/features/finance/transaction_service_test.dart`
- Test: `app/test/features/finance/transaction_atomicity_test.dart`

**Interfaces:**
- Consumes: accounts/categories and database transaction API
- Produces: `TransactionService.create`, `edit`, `softDelete`, `restore`, `reconcileAccount`

- [ ] **Step 1: Write failing transaction-classification tests**

Test these report effects:

```text
Income: +income, +account balance
Expense: +expense, -account balance
Transfer: 0 income, 0 expense, source -, destination +
Refund: -expense in original category, +account balance
Reimbursement: -recoverable expense, +account balance, 0 ordinary income
Balance adjustment: 0 income, 0 expense, account balance delta
```

- [ ] **Step 2: Define command validation**

```dart
final class CreateExpenseCommand {
  const CreateExpenseCommand({
    required this.accountId,
    required this.amount,
    required this.occurredAtUtc,
    required this.title,
    required this.splits,
  });

  final String accountId;
  final Money amount;
  final DateTime occurredAtUtc;
  final String title;
  final List<TransactionSplitDraft> splits;
}
```

Rules:

- amount must be positive
- title must be non-empty after trim
- split sum must equal transaction amount exactly
- expense splits use expense categories
- income splits use income categories
- transfer source and destination differ and use compatible currency definitions
- refund references an existing expense and cannot exceed its remaining refundable amount
- a shared/recoverable expense may define counterparty shares whose sum is less than or equal to the expense amount
- reimbursement references one recoverable share and cannot exceed its remaining recoverable amount

Add tests for a 1,000,000 IRT shared expense where 400,000 IRT is recoverable from a named counterparty; collecting 250,000 IRT must reduce recoverable expense by 250,000 IRT without increasing ordinary income.

- [ ] **Step 3: Implement atomic persistence**

```dart
await database.transaction(() async {
  await repository.insertTransaction(transaction);
  await repository.insertSplits(splits);
  await repository.insertAuditEvent(auditEvent);
});
```

Inject a repository failure after the first insert in a test and assert that neither transaction nor split remains.

- [ ] **Step 4: Implement soft delete and immediate Undo**

`softDelete(transactionId)` sets `deleted_at_utc`. `restore(transactionId)` clears it. Queries exclude deleted records by default. This is the Phase 1 finance foundation for the generic Trash UI delivered in Phase 2.

- [ ] **Step 5: Implement account reconciliation**

`reconcileAccount(accountId, observedBalance)` calculates the ledger difference and creates one balance-adjustment transaction only after explicit confirmation. The adjustment is excluded from income and expense totals.

- [ ] **Step 6: Run tests and commit**

```bash
cd app
flutter test test/features/finance/transaction_service_test.dart test/features/finance/transaction_atomicity_test.dart
flutter analyze
git add lib/features/finance test/features/finance
git commit -m "feat: add atomic finance transactions"
```

---

### Task 11: Implement monthly plans, recurring finance items, budgets, and rollover

**Files:**
- Create: `app/lib/features/finance/domain/monthly_plan.dart`
- Create: `app/lib/features/finance/domain/category_budget.dart`
- Create: `app/lib/features/finance/domain/planned_finance_item.dart`
- Create: `app/lib/features/finance/application/monthly_plan_service.dart`
- Create: `app/lib/core/recurrence/recurrence_rule.dart`
- Create: `app/lib/core/recurrence/occurrence_generator.dart`
- Create: `app/lib/core/recurrence/working_day_calendar.dart`
- Modify: finance repository files
- Test: `app/test/features/finance/monthly_plan_service_test.dart`
- Test: `app/test/features/finance/budget_rollover_test.dart`
- Test: `app/test/core/recurrence/finance_occurrence_generator_test.dart`

**Interfaces:**
- Consumes: transactions, categories, `LocalDate`
- Produces: per-month targets, category budgets, known recurring items, rollover snapshots, and a reusable recurrence core that Phase 2 extends for tasks

- [ ] **Step 1: Write no-double-counting tests**

```dart
expect(
  result.incomeTarget.minorUnits,
  50_000_000,
);
expect(
  result.knownRecurringIncome.minorUnits,
  45_000_000,
);
expect(
  result.unexplainedTarget.minorUnits,
  5_000_000,
);
```

Known recurring income explains the target; it is not added on top of the target.

- [ ] **Step 2: Implement unambiguous planning-period identity**

A monthly plan persists:

```text
calendar_code = jalali
period_year = user-selected Jalali year
period_month = user-selected Jalali month
start_date = Gregorian ISO date for Jalali day 1
end_exclusive_date = Gregorian ISO date for the next Jalali month day 1
```

The unique key is `(calendar_code, period_year, period_month)`. Queries use the stored Gregorian boundaries, so timestamps remain standard while the plan remains unmistakably tied to the user's Jalali month. Do not group a user-selected Jalali month by Gregorian calendar month.

- [ ] **Step 3: Add the finance recurrence core**

Implement immutable recurrence rules for Phase 1 finance items:

```text
daily
selected weekdays
every N days
N times per week or month
specific days of month
last day of month
first working day of month
end date
pause until date
explicit exceptions
holiday policy: keep date | previous working day | next working day
missed occurrence policy: create | skip | warn
```

`OccurrenceGenerator.between(rule, start, endExclusive, workingDayCalendar)` is pure, deterministic, and timezone-independent because it accepts and returns `LocalDate`. `WorkingDayCalendar` exposes `isWorkingDay(LocalDate)` and is configured from the user's weekend-day set plus explicit local holiday dates; no network holiday service is required. For `N times per week or month`, generation creates deterministic occurrence slots using the rule's selected weekdays or preferred month days and never invents duplicate dates. Phase 2 reuses this same interface for tasks instead of creating another engine. Test leap years, Jalali/Gregorian boundaries, month lengths, paused intervals, holiday shifts, impossible month days, quota-style rules, and duplicate-generation prevention.

- [ ] **Step 4: Implement rollover rules**

```dart
enum BudgetRolloverRule {
  reset,
  carrySurplus,
  carrySurplusAndDeficit,
}
```

At month creation, persist the calculated opening rollover so historical months do not change when later transactions are edited. A recalculation command can deliberately rebuild it with an audit event.

- [ ] **Step 5: Implement planned-item statuses**

Statuses:

```text
planned | confirmed | completed | overdue | skipped | canceled
```

A future planned record does not affect actual cash flow. Completing it can create a linked actual transaction once; repeated taps are idempotent.

- [ ] **Step 6: Run tests and commit**

```bash
cd app
flutter test test/features/finance/monthly_plan_service_test.dart test/features/finance/budget_rollover_test.dart test/core/recurrence/finance_occurrence_generator_test.dart
flutter analyze
git add lib/features/finance lib/core/recurrence test/features/finance test/core/recurrence
git commit -m "feat: add monthly finance planning and rollover"
```

---

### Task 12: Implement the finance metrics and report-query engine

**Files:**
- Create: `app/lib/features/finance/domain/finance_metrics.dart`
- Create: `app/lib/features/finance/application/finance_metrics_service.dart`
- Create: `app/lib/features/finance/data/finance_report_queries.dart`
- Test: `app/test/features/finance/finance_metrics_service_test.dart`
- Test: `app/test/features/finance/refund_reporting_test.dart`

**Interfaces:**
- Consumes: actual transactions, monthly plan, unpaid commitments, account balances
- Produces: one immutable `FinanceMonthSummary` used by dashboard, reports, calendar, and charts

- [ ] **Step 1: Write formula tests before query code**

Lock definitions:

```dart
actualNet = receivedIncome - ordinaryPaidExpenses - paidCommitments + linkedRefunds;
forecastSavings = forecastIncome - plannedExpenses - commitmentsDue;
safeToSpend = currentAvailableBalance - unpaidCommitments - remainingSavingsTarget;
shortfall = max(0, -safeToSpend);
```

Here `ordinaryPaidExpenses` excludes transfers and balance adjustments, `paidCommitments` includes actual debt and installment payments, and `linkedRefunds` reduces outflow instead of becoming income. Test positive and negative safe-to-spend values, partial commitment payments, transfers, adjustments, and refunds; assert negative values are never labeled as savings.

- [ ] **Step 2: Define immutable summary fields**

`FinanceMonthSummary` includes every metric from specification section 7.5:

```text
incomeTarget
receivedIncome
confirmedRemainingIncome
distanceToIncomeTarget
overdueExpectedIncome
expenseBudget
actualExpense
plannedRemainingExpense
availableBudget
overBudget
totalDueThisMonth
paidCommitments
remainingCommitments
overdueCommitments
nearestDueDate
totalFutureCommitments
actualNet
forecastSavings
safeToSpend
shortfall
```

- [ ] **Step 3: Implement SQL aggregation queries**

Use database-side `SUM`, grouped by classification and split category. Do not load all transaction rows to Dart for monthly totals. Exclude soft-deleted rows and use refund linkage to reduce the original expense category.

- [ ] **Step 4: Cache by report input revision**

Cache key:

```text
selected date range + latest finance updated_at + plan updated_at + settings currency
```

A targeted write invalidates only affected date ranges. Unit tests use a fake cache and assert unrelated months remain cached.

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/features/finance/finance_metrics_service_test.dart test/features/finance/refund_reporting_test.dart
flutter analyze
git add lib/features/finance test/features/finance
git commit -m "feat: add explainable finance metrics"
```

---

### Task 13: Build accounts, transaction list, and quick-entry flows

**Files:**
- Create: `app/lib/features/finance/presentation/finance_screen.dart`
- Create: `app/lib/features/finance/presentation/accounts/accounts_screen.dart`
- Create: `app/lib/features/finance/presentation/transactions/transaction_list_screen.dart`
- Create: `app/lib/features/finance/presentation/transactions/transaction_form.dart`
- Create: `app/lib/features/finance/presentation/transactions/split_editor.dart`
- Create: `app/lib/features/finance/application/finance_controllers.dart`
- Test: `app/test/features/finance/transaction_form_test.dart`
- Test: `app/test/features/finance/transaction_list_test.dart`

**Interfaces:**
- Consumes: transaction/account services and metrics
- Produces: daily entry, edit, filter, split, refund, transfer, and reconciliation user flows

- [ ] **Step 1: Write a failing quick-expense widget test**

Test this sequence at mobile width:

```text
Open central add action
Choose هزینه
Enter 125000
Choose خوراک
Choose yesterday in Jalali picker
Save
See ۱۲۵٬۰۰۰ تومان in transaction list
```

- [ ] **Step 2: Build one reusable transaction form**

The form adapts by host:

- mobile: bottom sheet
- tablet: dialog
- desktop: side panel

The amount field uses a numeric keyboard, Persian/Arabic digit normalization, thousands separators, and an inline calculator for `+ - × ÷` expressions. Saving is blocked when the expression is incomplete.

- [ ] **Step 3: Add recent values and templates foundation**

Remember only local user choices:

- last account by transaction type
- recent categories
- last five titles
- duplicate transaction action

Do not infer sensitive merchant data outside the device.

- [ ] **Step 4: Implement list virtualization and filters**

Use `ListView.builder` with paged Drift queries. Filters:

```text
income | expense | transfer | refund | adjustment | category | account | custom date range
```

Deleting shows a toast with an Undo action that calls `restore`.

- [ ] **Step 5: Verify and commit**

```bash
cd app
flutter test test/features/finance/transaction_form_test.dart test/features/finance/transaction_list_test.dart
dart run tool/verify_no_nested_blur.dart
flutter analyze
git add lib/features/finance test/features/finance
git commit -m "feat: add finance transaction experience"
```

---

### Task 14: Build monthly finance overview and budget management UI

**Files:**
- Create: `app/lib/features/finance/presentation/overview/finance_overview_screen.dart`
- Create: `app/lib/features/finance/presentation/overview/finance_metric_card.dart`
- Create: `app/lib/features/finance/presentation/planning/monthly_plan_screen.dart`
- Create: `app/lib/features/finance/presentation/planning/category_budget_editor.dart`
- Test: `app/test/features/finance/finance_overview_screen_test.dart`

**Interfaces:**
- Consumes: `FinanceMonthSummary`, monthly plan service
- Produces: explainable monthly finance dashboard and planning screens

- [ ] **Step 1: Write negative-safe-to-spend copy test**

```dart
expect(find.textContaining('کسری داری'), findsOneWidget);
expect(find.textContaining('پس‌انداز'), findsNothing);
```

- [ ] **Step 2: Build overview sections**

Desktop/tablet sections:

```text
Income metrics | Expense metrics | Safe to spend
Monthly trend  | Spending categories | Commitments
```

Mobile uses one vertical list with the safe-to-spend/shortfall card first.

- [ ] **Step 3: Add metric explanations**

Every calculated metric has an info action showing its inputs. Example:

```text
مبلغ امن برای خرج‌کردن
= موجودی قابل استفاده
− تعهدات پرداخت‌نشده
− باقی‌مانده هدف پس‌انداز
```

The displayed inputs must equal the stored summary values.

- [ ] **Step 4: Build plan/budget editing**

Support income target, expense ceiling, savings target, recurring items, category budgets, and per-category rollover rules. Warn rather than block when category budgets exceed the total expense ceiling.

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/features/finance/finance_overview_screen_test.dart
flutter analyze
git add lib/features/finance/presentation test/features/finance
git commit -m "feat: add monthly finance overview and budgets"
```

---

### Task 15: Implement financial calendar and date-range agenda

**Files:**
- Create: `app/lib/features/financial_calendar/domain/financial_calendar_day.dart`
- Create: `app/lib/features/financial_calendar/application/financial_calendar_service.dart`
- Create: `app/lib/features/financial_calendar/presentation/financial_calendar_screen.dart`
- Create: `app/lib/features/financial_calendar/presentation/jalali_month_grid.dart`
- Create: `app/lib/features/financial_calendar/presentation/financial_day_details.dart`
- Test: `app/test/features/financial_calendar/financial_calendar_service_test.dart`
- Test: `app/test/features/financial_calendar/jalali_month_grid_test.dart`

**Interfaces:**
- Consumes: transactions, planned items, debt/installment due items
- Produces: month, week, and agenda day summaries

- [ ] **Step 1: Write a failing day-summary test**

For one local date containing two expenses, one income, one expected income, and one installment due, assert all values appear separately; planned values do not alter actual totals.

- [ ] **Step 2: Implement day query model**

```dart
final class FinancialCalendarDay {
  const FinancialCalendarDay({
    required this.date,
    required this.income,
    required this.expense,
    required this.expectedIncome,
    required this.plannedExpense,
    required this.commitments,
    required this.hasOverdueWarning,
  });
}
```

- [ ] **Step 3: Build Jalali month grid**

Use Jalali month length and weekday offset from `shamsi_date`. Store selection as `LocalDate` after conversion to Gregorian. A device timezone change must not move a selected date.

- [ ] **Step 4: Add adaptive details**

- mobile: day details in `LiquidGlassBottomSheet`
- tablet/desktop: persistent side panel
- quick actions: income, expense, planned item, payment

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/features/financial_calendar
flutter analyze
git add lib/features/financial_calendar test/features/financial_calendar
git commit -m "feat: add Jalali financial calendar"
```

---

### Task 16: Implement corrected charts and category drill-down

**Files:**
- Create: `app/lib/features/finance/application/spending_chart_service.dart`
- Create: `app/lib/features/finance/presentation/charts/monthly_trend_chart.dart`
- Create: `app/lib/features/finance/presentation/charts/spending_category_chart.dart`
- Create: `app/lib/features/finance/presentation/charts/daily_spending_chart.dart`
- Test: `app/test/features/finance/spending_chart_service_test.dart`

**Interfaces:**
- Consumes: report queries and category repository
- Produces: stable chart series and category drill-down filters

- [ ] **Step 1: Write the real-Other-category regression test**

Create categories `سایر` and `خودکار: سایر دسته‌ها`. Assert the stored real category remains a separate slice and the grouped remainder uses an internal sentinel ID `__grouped_remainder__`.

- [ ] **Step 2: Implement chart range queries**

Ranges:

```text
day | week | Jalali month | Jalali year | custom
```

Debt/installment payments are selectable as included or separated; the default overview separates them from ordinary living expenses.

- [ ] **Step 3: Implement deterministic grouping**

Group small categories only when more than eight visible slices exist. Sort by amount descending, preserve the top seven, and aggregate the remainder. Never mutate category data to perform grouping.

- [ ] **Step 4: Implement chart widgets without list blur**

Wrap each chart once in `LiquidGlassChartContainer`. Touching a slice sets the transaction-list category filter and navigates to the list.

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/features/finance/spending_chart_service_test.dart
dart run tool/verify_no_nested_blur.dart
flutter analyze
git add lib/features/finance test/features/finance
git commit -m "fix: add correct finance category charts"
```

---

### Task 17: Implement debts, receivables, installments, and atomic payments

**Files:**
- Create: `app/lib/features/debts/domain/debt.dart`
- Create: `app/lib/features/debts/application/debt_service.dart`
- Create: `app/lib/features/debts/presentation/debts_screen.dart`
- Create: `app/lib/features/installments/domain/installment_plan.dart`
- Create: `app/lib/features/installments/domain/installment_occurrence.dart`
- Create: `app/lib/features/installments/application/installment_service.dart`
- Create: `app/lib/features/installments/presentation/installments_screen.dart`
- Create: `app/lib/features/installments/presentation/installment_payment_sheet.dart`
- Test: `app/test/features/debts/debt_service_test.dart`
- Test: `app/test/features/installments/installment_atomic_payment_test.dart`

**Interfaces:**
- Consumes: finance transaction service and database transaction API
- Produces: finance-owned debt/receivable/installment management and payment history

- [ ] **Step 1: Write direction and partial-payment tests**

Directions:

```dart
enum DebtDirection { userOwes, owedToUser }
```

Assert:

- paying `userOwes` creates an expense-classified debt payment
- collecting `owedToUser` creates income-classified receivable collection
- partial payment reduces only the remaining amount
- overpayment is rejected

- [ ] **Step 2: Implement immutable payment records**

A payment can be corrected only by a reversal record plus a replacement payment. Do not edit the amount of an existing posted payment in place.

- [ ] **Step 3: Implement installment occurrences**

Plan fields support fixed or variable amounts. Each due date is a separate occurrence with:

```text
upcoming | partiallyPaid | paid | overdue | canceled | rescheduled
```

Rescheduling creates a new occurrence and records the previous due date in audit metadata.

- [ ] **Step 4: Implement atomic payment transaction**

```dart
await database.transaction(() async {
  final financeTransaction = await transactionService.createInstallmentPayment(...);
  await installmentRepository.insertPayment(
    payment.copyWith(transactionId: financeTransaction.id),
  );
  await installmentRepository.recalculateOccurrenceStatus(occurrenceId);
});
```

Inject failure after transaction creation and assert no transaction or payment remains.

- [ ] **Step 5: Build Finance-only screens**

Routes remain under `/finance/debts` and `/finance/installments`. No task screen imports debt/installment presentation code.

- [ ] **Step 6: Run tests and commit**

```bash
cd app
flutter test test/features/debts test/features/installments
flutter analyze
git add lib/features/debts lib/features/installments test/features/debts test/features/installments
git commit -m "feat: add finance debts and installments"
```

---

### Task 18: Implement notification settings, friendly copy, scheduling, and reconciliation

**Files:**
- Create: `app/lib/core/notifications/notification_gateway.dart`
- Create: `app/lib/core/notifications/notification_models.dart`
- Create: `app/lib/core/notifications/notification_reconciler.dart`
- Create: `app/lib/features/notifications/data/local_notification_gateway.dart`
- Create: `app/lib/features/notifications/application/finance_notification_service.dart`
- Create: `app/lib/features/notifications/application/finance_notification_copy.dart`
- Modify: settings screen and repositories
- Test: `app/test/features/notifications/finance_notification_copy_test.dart`
- Test: `app/test/features/notifications/notification_reconciler_test.dart`

**Interfaces:**
- Consumes: settings, timezone service, debts/installments
- Produces: schedule/cancel/reconcile APIs and user-approved Persian notification tone

- [ ] **Step 1: Write exact copy tests**

```dart
expect(
  copy.installmentDueInDays(bankName: 'بانک ملت', days: 3, amountText: null),
  'حواست باشه، ۳ روز دیگه قسط بانک ملتته.',
);
expect(
  copy.installmentDueTomorrow(bankName: 'بانک ملت', emojiEnabled: true),
  'یادت نره، فردا موعد قسط بانک ملتته 👀',
);
```

When privacy is enabled:

```text
حواست باشه، یه پرداخت نزدیک داری.
```

- [ ] **Step 2: Define platform-neutral notification contract**

```dart
abstract interface class NotificationGateway {
  Future<NotificationPermissionState> requestPermission();
  Future<void> schedule(LocalNotificationRequest request);
  Future<void> cancel(String notificationId);
  Future<void> cancelAll();
  Future<Set<String>> pendingIds();
}
```

The adapter derives the plugin's integer notification ID from the stored string ID with a stable positive 31-bit hash and persists the mapping in `scheduled_notifications`; hash collisions are resolved by incrementing until an unused integer is found.

- [ ] **Step 3: Implement global off behavior**

When `notificationsEnabled` changes from true to false:

1. cancel all OS notifications
2. keep notification rules and due dates in SQLite
3. keep in-app warnings
4. show: `اعلان‌ها خاموش شدن؛ یادآوری‌ها هنوز داخل برنامه هستن، ولی دیگه نوتیفیکیشن نمی‌گیری.`

Re-enabling schedules only future relevant reminders.

- [ ] **Step 4: Implement reminder defaults and quiet controls**

Default installment offsets:

```text
3 days before, 1 day before, due day at 09:00 local time
```

Support quiet hours, quiet days, maximum daily count, snooze one hour, snooze tomorrow, and custom snooze. When enabled, morning and evening summaries combine low-priority finance reminders into one message; due-today and overdue installments remain individual high-priority reminders. Finance reminders outrank summary notifications when the daily cap is reached.

- [ ] **Step 5: Implement safe notification actions**

`LocalNotificationRequest` supports stable action IDs:

```text
open_details | confirm_payment | snooze_1h | snooze_tomorrow
```

`confirm_payment` opens the installment payment confirmation sheet with the source preselected; it does not mutate finance data from the background because the user must choose the paying account and confirm the amount. Snooze actions replace only the selected notification instance. Action routing is idempotent and validates that the source still exists and remains unpaid.

- [ ] **Step 6: Reconcile after edits/startup/timezone changes**

Compute desired future schedules from the database, diff against `pendingIds`, cancel stale IDs, and schedule missing IDs. Running reconciliation twice produces no additional schedules.

- [ ] **Step 7: Configure platforms**

Apply required Android manifest receivers/permissions from the plugin documentation, iOS/macOS notification capabilities, and Linux/Windows initialization. iOS logic uses pre-scheduled local notifications and never assumes a permanent background process.

- [ ] **Step 8: Run tests and commit**

```bash
cd app
flutter test test/features/notifications
flutter analyze
git add lib/core/notifications lib/features/notifications lib/features/settings test/features/notifications android ios linux macos windows
git commit -m "feat: add configurable finance notifications"
```

---

### Task 19: Implement versioned JSON, CSV, and Markdown finance exports

**Files:**
- Create: `app/lib/core/files/file_save_gateway.dart`
- Create: `app/lib/core/files/file_picker_save_gateway.dart`
- Create: `app/lib/features/export/domain/export_format.dart`
- Create: `app/lib/features/export/domain/finance_export_request.dart`
- Create: `app/lib/features/export/application/finance_export_service.dart`
- Create: `app/lib/features/export/data/json_finance_exporter.dart`
- Create: `app/lib/features/export/data/csv_finance_exporter.dart`
- Create: `app/lib/features/export/data/markdown_finance_exporter.dart`
- Create: `app/lib/features/export/presentation/finance_export_sheet.dart`
- Test: `app/test/features/export/json_finance_exporter_test.dart`
- Test: `app/test/features/export/csv_finance_exporter_test.dart`
- Test: `app/test/features/export/markdown_finance_exporter_test.dart`

**Interfaces:**
- Consumes: finance report queries, account/category repositories, Jalali formatter, selected date range, and `FileSaveGateway`
- Produces: `FinanceExportArtifact` with `suggestedFileName`, `mimeType`, and immutable `Uint8List bytes`

- [ ] **Step 1: Write failing export-contract tests**

Lock these behaviors before implementation:

```dart
test('JSON export is versioned and keeps exact minor units', () async {
  final artifact = await exporter.export(fixtureRequest);
  final decoded = jsonDecode(utf8.decode(artifact.bytes));
  expect(decoded['format'], 'dashboard-shakhsi-finance');
  expect(decoded['formatVersion'], 1);
  expect(decoded['transactions'][0]['amountMinor'], 1250000);
  expect(decoded['transactions'][0]['occurredAtUtc'], isNotNull);
});

test('CSV export is UTF-8 BOM and RFC4180-safe', () async {
  final artifact = await exporter.export(fixtureRequestWithCommaAndNewline);
  expect(artifact.bytes.take(3), [0xEF, 0xBB, 0xBF]);
  expect(utf8.decode(artifact.bytes.skip(3).toList()), contains('"عنوان، با ویرگول"'));
});
```

Also assert that soft-deleted records are omitted, transfers keep both account references, refunds keep the original transaction ID, and Jalali display dates never replace machine-readable ISO/UTC fields.

- [ ] **Step 2: Define one explicit export request and artifact contract**

```dart
enum FinanceExportFormat { json, csv, markdown }

class FinanceExportRequest {
  const FinanceExportRequest({
    required this.format,
    required this.startDate,
    required this.endExclusive,
    required this.includeAccounts,
    required this.includeBudgets,
    required this.includeDebtsAndInstallments,
  });
}

class FinanceExportArtifact {
  const FinanceExportArtifact({
    required this.suggestedFileName,
    required this.mimeType,
    required this.bytes,
  });
}
```

`FinanceExportService.createArtifact(request)` loads one transactionally consistent read snapshot and delegates formatting without re-querying per exporter. Define `FileSaveGateway.save({required String suggestedName, required Uint8List bytes})` in this task; `FilePickerSaveGateway` is the only platform-aware implementation and returns `null` when the user cancels.

- [ ] **Step 3: Implement the versioned JSON exporter**

The root object includes:

```json
{
  "format": "dashboard-shakhsi-finance",
  "formatVersion": 1,
  "exportedAtUtc": "2026-07-26T00:00:00.000Z",
  "range": {"startDate": "2026-07-01", "endExclusive": "2026-08-01"},
  "currency": {"code": "IRT", "scale": 0},
  "accounts": [],
  "categories": [],
  "transactions": [],
  "monthlyPlans": [],
  "debts": [],
  "installments": []
}
```

Money remains integer minor units. IDs and linkage fields are preserved. Human-readable Jalali labels may be added, but never replace canonical ISO dates or UTC instants.

- [ ] **Step 4: Implement the Persian CSV exporter**

Produce one transaction-oriented UTF-8 CSV with BOM for spreadsheet compatibility. Required columns are:

```text
شناسه,نوع,مبلغ,کد ارز,تاریخ شمسی,تاریخ استاندارد,ساعت,حساب,حساب مقصد,دسته,عنوان,توضیحات,شناسه مرجع
```

Use RFC 4180 quoting for commas, quotes, and newlines. Split transactions emit one row per split with the parent transaction ID and split category. Do not localize digits inside the numeric amount column.

- [ ] **Step 5: Implement the human-readable Markdown report**

The Markdown output contains:

- selected range and generated-at time
- finance summary metrics
- category totals
- commitment summary
- transaction table

Escape pipe characters and line breaks so user-entered text cannot corrupt tables. Markdown is legacy-parity output and is not accepted as an import format.

- [ ] **Step 6: Build the export sheet and safe file write**

The Liquid Glass sheet lets the user select format, date range, and optional sections. Generate filenames such as:

```text
dashboard-shakhsi-finance-1405-05.json
```

Use the file-save gateway to write to a user-selected path through a temporary file followed by rename. On cancel, write nothing. Show a Persian success message with the saved filename; never claim success before the write completes.

- [ ] **Step 7: Run tests and commit**

```bash
cd app
flutter test test/features/export
flutter analyze
git add lib/core/files lib/features/export test/features/export
git commit -m "feat: add versioned finance exports"
```

---

### Task 20: Implement encrypted backup and safe restore foundation

**Files:**
- Create: `app/lib/core/backup/backup_manifest.dart`
- Create: `app/lib/core/backup/backup_codec.dart`
- Create: `app/lib/core/backup/backup_service.dart`
- Create: `app/lib/core/backup/automatic_backup_service.dart`
- Create: `app/lib/core/backup/device_backup_key_store.dart`
- Create: `app/lib/features/backup/presentation/backup_screen.dart`
- Modify: `app/lib/features/settings/domain/app_settings.dart`
- Modify: `app/lib/features/settings/presentation/settings_screen.dart`
- Modify: Android and Apple platform security configuration
- Test: `app/test/core/backup/backup_codec_test.dart`
- Test: `app/test/core/backup/backup_restore_test.dart`
- Test: `app/test/core/backup/automatic_backup_service_test.dart`

**Interfaces:**
- Consumes: database file/export, `cryptography`, `flutter_secure_storage`, `FileSaveGateway`, path provider, and backup settings
- Produces: portable password-encrypted `.dshbackup` files, device-encrypted rotating automatic backups, and transactional restore

- [ ] **Step 1: Write encryption round-trip and tamper tests**

```dart
final encoded = await codec.encrypt(
  plaintext: utf8.encode('{"schemaVersion":1}'),
  password: 'correct horse battery staple',
);
expect(await codec.decrypt(encoded: encoded, password: 'correct horse battery staple'), isNotEmpty);
expect(
  () => codec.decrypt(encoded: mutateOneByte(encoded), password: 'correct horse battery staple'),
  throwsA(isA<BackupIntegrityFailure>()),
);
```

- [ ] **Step 2: Lock backup envelope format**

JSON envelope fields:

```json
{
  "magic": "DSHB",
  "formatVersion": 1,
  "kdf": "PBKDF2-HMAC-SHA256",
  "iterations": 210000,
  "salt": "base64",
  "cipher": "AES-256-GCM",
  "nonce": "base64",
  "ciphertext": "base64",
  "mac": "base64"
}
```

Use a fresh 16-byte salt and 12-byte nonce for every backup.

- [ ] **Step 3: Export a consistent database snapshot**

Before reading the SQLite file, run a WAL checkpoint or use SQLite backup/export APIs so the snapshot includes committed data. Manifest contains schema version, app version, created-at UTC, currency, and record counts.

- [ ] **Step 4: Implement safe restore**

Restore flow:

1. decode and authenticate into a temporary directory
2. validate manifest and SQLite integrity
3. open the restored database with current migration code
4. create a safety backup of current data
5. close current database
6. atomically swap files
7. reopen and verify record counts
8. roll back automatically if reopen fails

Corrupt/wrong-password backups never touch current data.

- [ ] **Step 5: Add encrypted rotating automatic local backups**

`DeviceBackupKeyStore` creates one random 256-bit key and stores it through `flutter_secure_storage`; it never exports that key. `AutomaticBackupService.createIfDue()` encrypts a consistent snapshot with that device key, writes it atomically under the application-support backup directory, and retains the newest configured count.

Defaults:

```text
automaticBackupsEnabled = true
retainedAutomaticBackupCount = 5
create at most one automatic backup per local day after the first successful data-changing session
```

Rotation never deletes the last known-good backup before the replacement has been authenticated and renamed successfully. Tests cover disabled mode, same-day idempotency, retention of exactly N newest files, corrupted newest backup, and secure-key read failure.

- [ ] **Step 6: Build backup UI and settings**

Actions:

- Create portable password-encrypted backup
- Restore portable or local automatic backup
- Turn automatic local backups on/off
- Choose retained count from 1, 3, 5, 10, or 20
- Explain that a portable backup password cannot be recovered
- Explain that device-encrypted automatic backups are intended for recovery on the same installation
- Show last successful manual and automatic backup metadata

Do not log passwords, keys, plaintext database bytes, or decrypted temporary paths.

- [ ] **Step 7: Configure secure storage per platform**

- Android: disable OS auto-backup for secure-storage preferences, initialize default RSA-OAEP/AES-GCM storage, and test key recreation behavior after app-data reset.
- iOS/macOS: add required Keychain Sharing entitlement entries to debug and release configurations.
- Linux: document runtime dependency `libsecret-1-0`; CI installs both `libsecret-1-0` and `libsecret-1-dev`.
- Windows: include secure-storage runner requirements in release documentation.

A secure-storage initialization failure disables automatic backups with an in-app warning; it never silently writes an unencrypted snapshot.

- [ ] **Step 8: Run tests and commit**

```bash
cd app
flutter test test/core/backup
flutter analyze
git add lib/core/backup lib/features/backup lib/features/settings test/core/backup android ios macos linux windows
git commit -m "feat: add encrypted manual and rotating backups"
```

---

### Task 21: Implement deterministic legacy finance import and migration report

**Files:**
- Create: `app/lib/features/migration/domain/legacy_models.dart`
- Create: `app/lib/features/migration/application/legacy_data_locator.dart`
- Create: `app/lib/features/migration/application/legacy_parser.dart`
- Create: `app/lib/features/migration/application/legacy_import_service.dart`
- Create: `app/lib/features/migration/presentation/legacy_migration_screen.dart`
- Create: `app/test/fixtures/legacy/valid_data.json`
- Create: `app/test/fixtures/legacy/corrupt_data.json`
- Test: `app/test/features/migration/legacy_parser_test.dart`
- Test: `app/test/features/migration/legacy_import_service_test.dart`

**Interfaces:**
- Consumes: old key/value JSON format and new finance services
- Produces: idempotent import run, raw legacy backup, and human-readable migration report

- [ ] **Step 1: Create a faithful legacy fixture**

Fixture shape:

```json
{
  "tasklist:v1": "[{\"id\":\"t1\",\"text\":\"نمونه\",\"done\":false,\"priority\":3,\"created\":1700000000000}]",
  "tasklist:prefs:v1": "{\"sort\":\"new\"}",
  "finance:v1": "{\"tx\":[{\"id\":\"x1\",\"type\":\"ex\",\"title\":\"خرید\",\"cat\":\"خوراک\",\"amount\":125000,\"ts\":1700000000000}],\"debts\":[{\"id\":\"d1\",\"name\":\"بانک\",\"total\":1000000,\"paid\":250000,\"created\":1700000000000}],\"insts\":[{\"id\":\"i1\",\"name\":\"وام\",\"per\":200000,\"count\":10,\"paidCount\":2,\"created\":1700000000000}]}",
  "app:prefs:v1": "{\"theme\":\"dark\",\"tab\":\"fin\"}"
}
```

- [ ] **Step 2: Implement platform candidate locations**

Desktop candidates:

```text
Linux: ~/.local/share/dashboard-shakhsi/data.json
Windows: %APPDATA%/dashboard-shakhsi/data.json
macOS: ~/Library/Application Support/dashboard-shakhsi/data.json
```

Android release update checks the existing application files directory for `data.json`. Debug builds also expose file-picker import for fixtures and manual testing.

- [ ] **Step 3: Parse without guessing missing facts**

Rules:

- legacy income/expense maps to actual transactions
- category names map to seeded categories; unknown names create user categories
- all imported transaction timestamps retain their instant
- existing paid debt amount becomes an imported opening payment excluded from period cash-flow because the original payment date is unknown
- `paidCount` creates imported paid installment occurrences excluded from period cash-flow
- unpaid legacy installments have `scheduleNeedsReview = true`; no notification is scheduled until due dates are supplied
- task JSON is preserved verbatim in `legacy_import_blobs` for Phase 2 migration

- [ ] **Step 4: Make import idempotent and atomic**

Derive deterministic IDs from `legacy:<entity-type>:<legacy-id>`. If an import run with the same source SHA-256 already completed, show its report and do not duplicate records.

Import occurs in one database transaction. A malformed nested JSON string aborts the import and retains the current database unchanged.

- [ ] **Step 5: Create pre-import copy and report**

Before import, copy the source as:

```text
legacy-data-YYYYMMDD-HHMMSS.json
```

Report includes:

```text
transactions imported
categories created
debts imported
installment plans imported
items requiring due-date review
task records retained for Phase 2
warnings and skipped records
source hash
```

- [ ] **Step 6: Run tests and commit**

```bash
cd app
flutter test test/features/migration
flutter analyze
git add lib/features/migration test/features/migration
git commit -m "feat: add safe legacy finance migration"
```

---

### Task 22: Add onboarding, dashboard finance summary, and in-app warnings

**Files:**
- Create: `app/lib/features/onboarding/presentation/onboarding_flow.dart`
- Create: `app/lib/features/onboarding/application/onboarding_controller.dart`
- Modify: `app/lib/features/dashboard/presentation/dashboard_screen.dart`
- Create: `app/lib/features/dashboard/presentation/widgets/finance_summary_card.dart`
- Create: `app/lib/features/dashboard/presentation/widgets/in_app_warning_card.dart`
- Test: `app/test/features/onboarding/onboarding_flow_test.dart`
- Test: `app/test/features/dashboard/finance_summary_card_test.dart`

**Interfaces:**
- Consumes: settings, account/category bootstrap, finance metrics, commitments
- Produces: first-run setup, compact dashboard finance summary, and warnings independent from OS notifications

- [ ] **Step 1: Write the minimal onboarding-flow test**

Flow asks only:

```text
name (optional)
currency
default account/opening balance (optional)
monthly income target (optional)
fixed expenses (optional)
module visibility preset: finance only | planning only | all modules
notification permission choice
```

Skipping optional steps must still create a usable default account and categories.

- [ ] **Step 2: Implement resumable onboarding**

Persist the last completed step. Killing and reopening the app resumes from that step without duplicating accounts or plans.

- [ ] **Step 3: Build compact dashboard finance summary**

Show:

- received income this Jalali month
- actual expense this Jalali month
- safe-to-spend or shortfall
- budget state

A compact `قسط نزدیک داری` warning may link to Finance, but no installment controls appear on the main dashboard.

- [ ] **Step 4: Keep in-app warnings when OS notifications are off**

The dashboard warning query ignores `notificationsEnabled`. It uses due/overdue finance data directly.

- [ ] **Step 5: Run tests and commit**

```bash
cd app
flutter test test/features/onboarding test/features/dashboard
flutter analyze
git add lib/features/onboarding lib/features/dashboard test/features/onboarding test/features/dashboard
git commit -m "feat: add onboarding and finance dashboard summary"
```

---

### Task 23: Add realistic fixtures, performance gates, end-to-end flows, and release documentation

**Files:**
- Create: `app/tool/generate_finance_fixture.dart`
- Create: `app/integration_test/finance_happy_path_test.dart`
- Create: `app/integration_test/legacy_migration_test.dart`
- Create: `app/test/performance/finance_query_benchmark_test.dart`
- Create: `docs/testing/android-performance-matrix.md`
- Create: `docs/migration/legacy-to-flutter.md`
- Modify: `README.md`
- Modify: `.github/workflows/flutter-ci.yml`

**Interfaces:**
- Consumes: all Phase 1 features
- Produces: reproducible acceptance dataset, end-to-end coverage, performance evidence, and contributor instructions

- [ ] **Step 1: Generate a deterministic multi-year fixture**

Generate:

```text
5 accounts
40 categories
10,000 transactions over 36 months
600 split lines
24 refunds
36 monthly plans
120 planned items
12 debts/receivables
6 installment plans with 120 occurrences
300 scheduled-notification rows
```

Use a fixed random seed and fixed clock so benchmark results are comparable.

- [ ] **Step 2: Add report-query performance tests**

On the CI host, enforce algorithmic bounds rather than device frame timing:

```text
one Jalali month summary <= 250 ms after warm database open
one category chart query <= 250 ms
one 36-month trend query <= 500 ms
```

If CI variance proves higher in three consecutive runs, update the bound only with a benchmark note and query plan evidence.

- [ ] **Step 3: Add end-to-end finance flow**

Integration test:

```text
complete onboarding
create income target
record income and split expense
create installment
schedule reminders with fake gateway
pay part of installment
verify finance summary and calendar
create encrypted backup
restore into clean database
verify record counts and metrics
```

- [ ] **Step 4: Add legacy migration integration test**

Import the fixture, verify source backup/report, verify no duplicate on second run, and verify rollback on corrupt fixture.

- [ ] **Step 5: Add Android device performance matrix**

Document required manual runs in profile and release mode:

```text
low-end Android 7/8-class device or closest available 2-3 GB RAM device
mid-range current Android device
60 Hz scrolling through 10,000 transactions
finance dashboard first open
calendar month switch
chart interaction
quick expense save
```

Record startup time, jank frames, memory, and observed thermal throttling. Debug-mode results are explicitly rejected.

- [ ] **Step 6: Update CI and documentation**

CI additionally runs:

```bash
flutter test test/performance
flutter test integration_test -d linux
flutter build apk --release
flutter build linux --release
```

README explains:

- legacy app remains under the existing source during migration
- Flutter app lives in `app/`
- Flutter 3.44.7 setup
- code generation command
- test commands
- current Phase 1 scope
- data migration safety

- [ ] **Step 7: Run full verification**

```bash
python3 -m pytest tests -q
cd app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
dart run tool/verify_no_nested_blur.dart
flutter test integration_test -d linux
flutter build apk --release
flutter build linux --release
```

Expected: all commands PASS. iOS/macOS and Windows release builds run in their platform CI jobs or on their native build machines before a tagged release.

- [ ] **Step 8: Commit Phase 1 acceptance suite**

```bash
cd ..
git add app/tool app/integration_test app/test/performance docs/testing docs/migration README.md .github/workflows/flutter-ci.yml
git commit -m "test: add Phase 1 finance acceptance suite"
```

---

## Phase 1 Final Review Gate

Before calling Phase 1 complete:

- [ ] Run every command in Task 23 Step 7.
- [ ] Inspect `git diff --check` and confirm no generated or secret files are untracked.
- [ ] Run migration against at least three sanitized legacy datasets: empty, ordinary, and malformed-edge-case.
- [ ] Confirm negative safe-to-spend appears as a shortfall, never savings.
- [ ] Confirm refunds reduce expenses and transfers do not affect income/expense.
- [ ] Confirm a failed installment payment leaves neither payment nor transaction behind.
- [ ] Confirm global notification off cancels OS notifications while in-app warnings remain visible.
- [ ] Confirm light, dark, system, reduced-transparency, reduced-motion, and increased-contrast states.
- [ ] Confirm no task screen owns or renders installment management.
- [ ] Capture Android profile/release performance evidence in `docs/testing/android-performance-matrix.md`.
- [ ] Review dependency licenses and include notices required by bundled assets/packages.
- [ ] Tag the internal milestone only after migration rollback and encrypted restore tests pass.
