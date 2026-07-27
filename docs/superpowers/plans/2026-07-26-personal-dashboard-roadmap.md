# Personal Dashboard Rebuild Delivery Roadmap

> **For agentic workers:** Each linked phase requires its own implementation plan and must be executed with `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans`.

**Goal:** Deliver the complete approved personal-dashboard rebuild without dropping any requested capability, while keeping every milestone independently testable and reversible.

**Architecture:** The existing WebView application remains available as the legacy reference while a new Flutter application is built in `app/`. Shared domain rules live behind repositories and platform adapters so the same feature code runs on Android, iOS, Windows, Linux, and macOS.

**Tech Stack:** Flutter 3.44.7, Dart 3.12.2, Riverpod, go_router, Drift/SQLite, local notifications, platform adapters, Flutter test/integration_test.

## Global Constraints

- Preserve the existing Liquid Glass identity in light and dark themes.
- Use adaptive layouts: bottom navigation on mobile, navigation rail on tablet, sidebar on desktop.
- Keep the first generation single-user, offline-first, and serverless.
- Store timestamps in UTC and date-only values without timezone drift; display Jalali dates by default.
- Use SQLite as the source of truth and transactions for multi-record financial writes.
- Keep all approved features in scope; phasing changes delivery order only.
- Do not ship a stable replacement until legacy data migration and rollback tests pass.
- Measure mobile performance on real low-end and mid-range Android devices in profile and release modes.

---

## Plan Sequence

### Phase 1 — Foundation and Reliable Finance

Detailed plan: `docs/superpowers/plans/2026-07-26-phase-1-foundation-reliable-finance.md`

Delivers:

- Flutter multi-platform shell
- Liquid Glass design system
- Adaptive navigation
- Drift/SQLite schema and migration harness
- Settings, date/time, and currency foundations
- Accounts, categories, transactions, splits, refunds, transfers, and balance adjustments
- Monthly plans, budgets, rollover, finance metrics, financial calendar, and corrected charts
- Debts, receivables, installment plans, partial payments, and finance-only dashboards
- Friendly configurable local notifications with a global off switch
- Versioned JSON, CSV, and Markdown finance exports
- Encrypted backup/restore foundation
- Legacy finance migration and migration reporting
- Basic onboarding, quick entry, and performance gates

Exit gate: financial totals are reproducible from records, all atomic-write tests pass, legacy imports produce deterministic reports, and the adaptive Liquid Glass shell is smooth on agreed Android test devices.

### Phase 2 — Planning and Execution

A separate detailed plan will be written after Phase 1 review, using the approved design and the stable Phase 1 interfaces.

Delivers:

- Tasks with Planned/In progress/Completed/Canceled statuses
- Stable display numbering and per-column positions
- List, Kanban, and calendar views with drag and drop
- Extend the shared recurrence engine from finance to tasks and add task-specific exception handling
- Timer lifecycle and manual time entries
- Quick-entry templates
- Generic Undo, 30-day Trash, and audit-history UI
- Task/time notifications and notification actions
- User-configurable dashboard cards, module visibility, and drag-and-drop ordering

Exit gate: task ordering survives restart, timer state is recoverable, recurrence fixtures pass timezone and Jalali-boundary tests, and destructive operations are reversible.

### Phase 3 — Personal Growth

A separate detailed plan will be written after Phase 2 review.

Delivers:

- Checkbox, numeric, and timed habits
- Pause, vacation, illness, justified skip, restart, and no-guilt modes
- Simple and multipart challenges
- Goals, milestones, manual/automatic/hybrid progress
- Cross-feature links between tasks, time, habits, challenges, and goals
- Daily, weekly, and monthly personal-growth reports

Exit gate: progress is calculated without duplicated data, paused/justified days do not break streaks, and all cross-feature updates are idempotent.

### Phase 4 — Experience Completion and Store Readiness

A separate detailed plan will be written after Phase 3 review.

Delivers:

- Native home-screen widgets
- Global search across finance, tasks, habits, challenges, time entries, and goals
- Attachments and receipt storage
- Advanced CSV/Excel imports with mapping
- Reconciliation refinements and richer audit tools
- Optional application lock with PIN and device biometrics
- Privacy controls for deleting history in a selected date range
- Accessibility hardening: reduced transparency, reduced motion, high contrast, dynamic type, screen readers
- Performance hardening and long-history stress tests
- Android, iOS, Windows, Linux, and macOS packaging and store/release workflows
- Final stable cutover from the legacy application

Exit gate: platform release builds pass smoke tests, encrypted backup/restore passes cross-platform fixtures, accessibility audits pass, and the stable package can migrate existing users with rollback instructions.

## Release Policy

- Each phase is developed on an isolated worktree/branch.
- Every task starts with a failing test and ends with a focused commit.
- Generated files are committed only when required by Flutter/Drift conventions.
- Database migrations are append-only after a build has been distributed to testers.
- Stable releases require a migration dry run against sanitized copies of legacy datasets.
- The existing WebView release remains downloadable until the Flutter replacement has passed the final cutover gate.
