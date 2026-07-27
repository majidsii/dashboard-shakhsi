# Personal Dashboard Cross-Platform Rebuild Design

**Date:** 2026-07-26
**Status:** Approved by the user; implementation planning in progress
**Target platforms:** Android, iOS, Windows, Linux, macOS
**Primary language and locale:** Persian, RTL, Jalali display calendar

## 1. Summary

The existing application is a local-first personal dashboard that combines tasks and personal finance in a single HTML file rendered through desktop and Android WebViews. The new product will be a complete Flutter rewrite with a feature-based architecture, SQLite storage, local notifications, adaptive layouts, and a custom Liquid Glass design system derived from the current product.

The rebuilt application remains single-user, offline-first, and serverless in its first generation. Its data model and boundaries must still allow encrypted synchronization and multi-device accounts to be added later without rewriting feature logic.

The product includes these major areas:

1. Dashboard
2. Finance and financial calendar
3. Debts, receivables, and installments
4. Tasks
5. Time tracking
6. Habits
7. Challenger
8. Goals
9. Reports
10. Settings, privacy, backup, and migration

All approved capabilities belong to the final product. Delivery is phased only to reduce technical and product risk; no approved capability is removed from scope.

## 2. Product principles

### 2.1 Local-first and trustworthy

- Core features work without internet access.
- SQLite is the source of truth.
- Every financial write that affects multiple records is transactional.
- Destructive actions are recoverable through Undo and a 30-day Trash.
- Backups are encrypted and portable between supported platforms.

### 2.2 Fast on modest Android devices

- Flutter renders the UI; the product must not use an HTML WebView for its main interface.
- Performance acceptance is measured on real low-end and mid-range Android hardware in profile and release modes.
- Long lists are lazy, reports are cached, and feature state updates are isolated.
- Repeated or nested blur is prohibited.

### 2.3 Friendly rather than judgmental

- Notifications and progress messages use short, conversational Persian.
- Missed habits or plans are described without blame.
- Vacation, illness, pause, justified skip, and restart are first-class states.
- Streaks can be hidden for users who find them stressful.

### 2.4 Adaptive, not merely responsive

- The visual identity is shared across devices.
- Navigation and information density change by available width.
- Mobile uses bottom navigation and bottom sheets.
- Tablet uses a navigation rail and two-pane layouts.
- Desktop uses a sidebar, multi-column dashboards, dialogs, and side panels.

## 3. Technical architecture

### 3.1 Technology stack

- Flutter and Dart
- Feature-based modular architecture
- SQLite with schema migrations
- Repository interfaces between feature logic and persistence
- Local notifications through platform-specific adapters
- Platform adapters for backup, file selection, biometric lock, widgets, and startup behavior
- Automated unit, widget, integration, migration, and performance tests

### 3.2 Proposed project structure

```text
lib/
├── app/
│   ├── bootstrap/
│   ├── router/
│   ├── theme/
│   ├── responsive/
│   └── shell/
├── core/
│   ├── database/
│   ├── migrations/
│   ├── notifications/
│   ├── recurrence/
│   ├── backup/
│   ├── date_time/
│   ├── security/
│   ├── analytics/
│   └── shared/
├── features/
│   ├── dashboard/
│   ├── finance/
│   ├── financial_calendar/
│   ├── debts/
│   ├── installments/
│   ├── tasks/
│   ├── time_tracking/
│   ├── habits/
│   ├── challenges/
│   ├── goals/
│   ├── reports/
│   └── settings/
└── main.dart
```

Each feature owns its domain models, application services, repositories, screens, widgets, and tests. Cross-feature communication happens through explicit interfaces and domain events rather than direct database access.

### 3.3 Date and time policy

- Dates are stored internally as standard UTC timestamps or local-date values where a timezone-independent calendar date is required.
- The interface displays Jalali dates by default.
- Reminder scheduling uses the device timezone.
- Timezone changes trigger future reminder reconciliation.
- The schema records enough information to avoid shifting date-only items when timezone changes.

## 4. Liquid Glass design system

The current visual identity must be preserved rather than replaced by standard Material styling.

### 4.1 Design tokens

The design system centralizes:

- Blur strength
- Surface opacity
- Saturation
- Corner radii
- Highlight borders and rim lighting
- Inner and outer shadows
- Apple-style accent colors already used by the current UI
- Typography and spacing
- Spring motion curves and durations
- Light and dark theme values

### 4.2 Shared components

```text
LiquidGlassScaffold
LiquidGlassSurface
LiquidGlassCard
LiquidGlassNavigation
LiquidGlassButton
LiquidGlassField
LiquidGlassDialog
LiquidGlassBottomSheet
LiquidGlassSegmentedControl
LiquidGlassChartContainer
LiquidGlassToast
LiquidGlassEmptyState
```

Blur is applied only to major surfaces. Nested list items use lightweight translucent fills, gradients, borders, and highlights to retain the appearance without excessive GPU cost.

### 4.3 Appearance and accessibility

Themes:

- Light
- Dark
- Follow system

Accessibility options:

- Reduce transparency
- Reduce motion
- Increase contrast
- Dynamic text scaling
- Screen-reader labels
- Minimum mobile touch targets
- Status indicators that do not rely on color alone

## 5. Adaptive navigation

### 5.1 Mobile

Primary bottom navigation:

```text
خانه | مالی | افزودن | برنامه | بیشتر
```

`برنامه` contains tasks, habits, time tracking, Challenger, and goals. `بیشتر` contains reports, backup, settings, and about.

The central add action opens a quick-entry bottom sheet for:

- Expense
- Income
- Task
- Start timer
- Manual time entry
- Habit progress

### 5.2 Tablet

Navigation rail:

```text
خانه
مالی
تسک‌ها
زمان
چالش‌ها
اهداف
گزارش‌ها
```

Two-pane layouts are used for calendar/details and list/details workflows.

### 5.3 Desktop

Sidebar:

```text
داشبورد
مالی
تقویم مالی
تسک‌ها
مدیریت زمان
عادت‌ها
Challenger
اهداف
گزارش‌ها
تنظیمات
```

The dashboard can use multiple columns. Forms open as dialogs or side panels.

## 6. Dashboard

The main dashboard summarizes the day and does not become a management screen for every module.

It shows:

- Greeting and Jalali date
- Today's tasks and current active task
- Remaining habits
- Active timer
- Useful time and wasted time today
- Compact monthly finance summary
- Active goal and challenge progress
- Customizable quick actions

The compact finance summary may show that an installment is near, but all installment management and detailed dashboards remain inside Finance.

Dashboard cards are user-configurable and draggable. Users may hide modules they do not use.

### 6.1 Global search

A global search surface can find transactions, debts, installments, tasks, habits, challenges, time entries, and goals. Desktop exposes a keyboard shortcut; mobile exposes search from the dashboard. Results are grouped by module, respect soft deletion and privacy settings, and open the owning detail screen rather than duplicating management UI inside search.

## 7. Finance

### 7.1 Accounts

Supported account types:

- Bank account
- Cash
- Wallet
- Savings account
- Other

A default account is created for users who do not want multi-account management. Transfers between accounts are not income or expense.

### 7.2 Transactions

Transaction types:

- Income
- Expense
- Transfer
- Debt payment
- Receivable collection
- Installment payment
- Refund
- Reimbursement
- Balance adjustment

Fields include:

- Amount
- Date and time
- Account
- Category
- Title
- Description
- Related planned item
- Related debt, receivable, or installment
- Attachments and reference number
- Split lines when applicable

Users can register transactions for today, past dates, or future planned dates.

### 7.3 Split transactions and refunds

- A single payment can be split across categories.
- A shared expense can be split between people.
- Refunds reference the original expense and reduce expense totals rather than inflating income.
- Reimbursements can be tracked as recoverable amounts.

### 7.4 Monthly planning

Each month may define:

- Income target
- Expense ceiling
- Savings target
- Category budgets
- Recurring income and expenses
- Installments and debts due in the month

Recurring items can contribute to a monthly target without being double-counted. The report shows how much of the target is explained by known recurring income and how much remains unplanned.

### 7.5 Required monthly metrics

Income:

- Target income
- Received income
- Confirmed remaining income
- Distance to target
- Overdue expected income

Expense:

- Monthly budget
- Actual expense
- Planned remaining expense
- Available budget
- Amount over budget
- Spending by category

Debt and installments:

- Total due this month
- Paid amount
- Remaining amount
- Overdue items
- Nearest due date
- Total future commitments

Savings and cash flow:

- Actual monthly net cash flow
- Forecast end-of-month savings
- Safe-to-spend amount
- Shortfall required to meet the plan

Definitions:

```text
Actual monthly net = received income - paid expenses
Forecast savings = forecast income - planned expenses - debts/installments due
Safe to spend = current available balance - unpaid commitments - remaining savings target
```

A negative safe-to-spend amount is presented as a clear shortfall, not as savings.

### 7.6 Budgets and rollover

Each category supports one rollover rule:

- Reset to zero next month
- Carry remaining budget forward
- Carry both surplus and deficit forward

### 7.7 Account reconciliation

Users can enter the real current account balance. The application shows the difference and allows them to:

- Locate missing or incorrect transactions
- Record a balance adjustment

Balance adjustments do not count as normal income or expense.

### 7.8 Financial calendar

Views:

- Month
- Week
- Agenda

Each day can show:

- Income total
- Expense total
- Installment due
- Debt due
- Expected income
- Planned expense
- Overdue warning

Selecting a day opens its details and quick-entry actions.

### 7.9 Spending chart correctness

- Categories come from the database.
- A real category named `Other` is not mixed with an automatically grouped remainder.
- Installment and debt payments can be included or separated.
- Daily, weekly, monthly, yearly, and custom ranges are supported.
- Amount and percentage are shown.
- Month-over-month comparison is supported.
- Selecting a category filters the transaction list.

## 8. Debts, receivables, and installments

This area belongs exclusively to Finance.

### 8.1 Direction

A record can represent:

- Money the user owes
- Money owed to the user

### 8.2 Payment history

Each payment is an independent immutable record with:

- Amount
- Date
- Account
- Notes
- Related transaction

Partial payments are supported. Payment creation and financial transaction creation occur in one database transaction.

### 8.3 Installment plans

Installment plans support:

- Fixed or variable amounts
- Due dates
- Partial payments
- Paid, upcoming, overdue, and canceled states
- Custom reminder rules
- Rescheduling with audit history

## 9. Notifications

### 9.1 Global control

A global notification switch can disable all operating-system notifications.

When disabled:

- Scheduled OS notifications are canceled.
- No new OS notifications are scheduled.
- Reminder data remains intact.
- In-app warnings remain visible.
- Re-enabling schedules only relevant future notifications.

### 9.2 Per-category controls

Users can separately control:

- Finance reminders
- Tasks
- Habits and challenges
- Goals
- Morning summary
- Evening summary

Additional controls:

- Quiet hours
- Quiet days
- Maximum daily notifications
- Private lock-screen content
- Show or hide financial amounts
- Emoji on or off
- Default notification time
- Snooze options

### 9.3 Friendly Persian tone

Examples:

```text
حواست باشه، ۳ روز دیگه قسط بانک ملتته.
یادت نره، فردا موعد قسط بانک ملتته 👀
امروز موعد قسط بانک ملتته؛ پرداختش کردی از همین‌جا ثبتش کن.
قسط بانک ملتت هنوز پرداخت نشده؛ ۲ روزه از موعدش گذشته.
```

Notifications can include platform-supported actions such as:

- Paid
- Remind in one hour
- Remind tomorrow
- Open details

### 9.4 Platform behavior

- Android and iOS use pre-scheduled local notifications.
- Desktop platforms use native system notifications.
- Editing a due date replaces old schedules.
- Completing a payment cancels irrelevant future reminders.
- Application startup reconciles reminder schedules.
- iOS must not depend on an always-running background process.

## 10. Tasks

Statuses:

- Planned
- In progress
- Completed
- Canceled

Each task supports:

- Title
- Description
- Status
- Priority
- Start and due date/time
- Estimated and actual time
- Recurrence
- Tags
- Related goal and challenge
- Subtasks
- Reminder
- Position and display number

Views:

- List
- Kanban
- Calendar

Drag and drop changes position within a status and across statuses. Display numbers update automatically and can be hidden.

Starting a task timer changes the task to `In progress`, creates a linked time entry, and updates linked goals and challenges. Only one primary timer may run at once.

## 11. Recurrence engine

One shared recurrence engine is used by tasks, habits, finance items, installments, and reminders.

It supports:

- Daily
- Selected weekdays
- Every N days
- N times per week or month
- Specific days of month
- Last day of month
- First working day of month
- End date
- Pause until date
- Exceptions
- Holiday handling rule
- Missed occurrence handling

Missed occurrences can be created, skipped, or surfaced only as warnings according to the item's policy.

## 12. Time tracking

### 12.1 Entry methods

- Live start, pause, resume, stop timer
- Manual start/end entry
- Editing past entries

Time entries may link to a task, goal, challenge, or habit.

Overlapping entries are blocked by default. The user may adjust the new entry, shorten the old one, or replace the overlapping range.

### 12.2 Time classification

Base types:

- Work
- Useful personal time
- Necessary rest
- Wasted time

Users create custom categories beneath them. Reports recalculate when category classification changes.

### 12.3 Untracked time

Untracked time is calculated inside the user's configured waking window and is not automatically treated as wasted time.

## 13. Habits

Habit types:

- Check-off
- Numeric
- Duration

Scheduling supports daily or weekly targets, selected days, rest days, reminders, start/end dates, and recurrence rules.

Metrics:

- Current streak
- Best streak
- Weekly adherence
- Monthly adherence
- Successful days
- Missed days

Planned rest, vacation, illness, justified skip, and pause do not break the streak.

Users may hide streaks and emphasize weekly or monthly consistency instead.

## 14. Challenger

### 14.1 Simple challenge

One behavior over a fixed period, such as 30 days of study.

### 14.2 Multi-part challenge

A challenge may combine:

- Habits
- Tasks
- Time targets
- Numeric targets
- Maximum limits, such as wasted time under 30 minutes

Challenges support pause, resume, justified skip, progress history, and restart without erasing previous attempts.

## 15. Goals

Goal statuses:

- Planned
- In progress
- Paused
- Completed
- Canceled

Progress modes:

- Manual
- Automatic
- Hybrid

Goals may link to tasks, habits, challenges, time entries, numeric targets, and milestones. Automatic progress is weight-based and must show the user how the percentage was calculated.

Milestones support deadlines, weights, and linked tasks.

## 16. Reports

### 16.1 Daily

- Timeline
- Time by category
- Habits completed
- Tasks completed
- Useful and wasted time
- Untracked gaps
- Financial activity for the day

### 16.2 Weekly

- Average useful time
- Most and least productive day
- Time distribution
- Habit trend
- Task completion trend
- Comparison with previous week

### 16.3 Monthly

- Income, expenses, commitments, and savings
- Category budget performance
- Work, useful personal time, rest, and wasted time
- Habit adherence
- Challenge and goal progress
- Best day and monthly trend
- Comparison with previous month

Reports use supportive language and explain the inputs behind totals.

## 17. Quick entry and templates

Quick entry includes:

- Numeric keyboard for amounts
- Calculator in amount fields
- Recent categories and accounts
- Remembered merchant/category suggestions
- Duplicate previous record
- Reusable templates
- Fast date selection

Templates can cover regular purchases, income, tasks, and time entries.

## 18. Attachments

Transactions, debts, receivables, and installments can store:

- Receipt images
- PDF documents
- Reference numbers
- Links

Attachments are local and included in encrypted backups.

## 19. Undo, trash, and auditability

- Undo appears after destructive or high-impact actions.
- Soft-deleted records remain in Trash for 30 days.
- Users can restore or permanently delete records.
- Important financial edits record creation and last-edit metadata.
- Complex financial operations are atomic.

## 20. Onboarding and customization

Initial onboarding asks only for:

1. Name and currency
2. Optional initial balance
3. Monthly income target
4. Important fixed expenses
5. Modules the user wants to see

Users can later show, hide, and reorder dashboard modules.

The app supports a simple mode where only selected modules are visible.

## 21. Widgets

The architecture must support native home-screen widgets, even if rollout is staged.

Planned widgets:

- Quick expense/income entry
- Safe-to-spend amount
- Today's tasks
- Today's habit progress
- Start/stop timer
- Nearest installment
- Useful time today

Widgets must display actual progress for numeric and duration habits, not just a check mark.

## 22. Backup, restore, migration, and privacy

- Manual encrypted backup
- Automatic rotating local backups
- Configurable retained backup count
- JSON, CSV, and human-readable Markdown exports
- Full database restore
- Import from the legacy application JSON format
- Transfer backup files between mobile and desktop
- Optional PIN and device biometrics
- Ability to remove history for a selected date range

Migration from legacy keys and JSON data preserves tasks, transactions, debts, installments, theme preferences, and available metadata. The migration creates a backup before changing data and produces a human-readable migration report.

## 23. Future-ready capabilities

These are part of the intended product direction and the schema must not block them:

- Encrypted multi-device synchronization
- Shared household budgets
- Calendar integration
- Android bank-SMS import
- Receipt OCR
- Voice entry
- CSV/Excel mapping import
- Backup to the user's own cloud provider
- Multiple currencies and exchange rates
- Credit-card statement cycles
- Duplicate-payment detection

They are not prerequisites for the first stable offline release unless explicitly promoted during implementation planning.

## 24. Error handling

- User input is validated before persistence.
- Database failures produce actionable Persian messages without losing entered form data.
- Notification permission denial keeps in-app reminders active.
- Attachment failure does not create an incomplete financial operation.
- Import runs in a transaction and can be rolled back.
- Corrupt backups are rejected without touching current data.
- Report errors show a recoverable state and never silently display zero as valid data.

## 25. Testing strategy

### Unit tests

- Finance calculations
- Safe-to-spend and forecast formulas
- Split transactions and refunds
- Recurrence rules
- Jalali display conversion and timezone boundaries
- Habit adherence and streak exceptions
- Goal weighted progress

### Database and migration tests

- Schema migrations
- Atomic installment payments
- Trash restore
- Legacy data import
- Backup and restore integrity

### Widget and integration tests

- Adaptive navigation at target widths
- Quick-entry flows
- Drag and drop
- Timer lifecycle
- Notification settings and rescheduling
- Accessibility modes

### Performance tests

Use realistic multi-year sample data and real Android devices. Acceptance includes:

- Smooth primary scrolling and navigation on agreed low-end and mid-range devices
- No full-page rebuild after isolated edits
- Bounded report generation time
- Bounded startup time
- No repeated blur layers in scrolling lists

## 26. Delivery phases

All approved features remain in the product scope. Implementation is divided into coherent release milestones.

### Phase 1: Foundation and reliable finance

- Flutter shell and Liquid Glass system
- Adaptive navigation
- SQLite and migrations
- Accounts, transactions, monthly planning, categories
- Debts, receivables, installments
- Financial calendar and corrected reports
- Notifications and global controls
- Legacy migration
- Backup and restore foundation

### Phase 2: Planning and execution

- Tasks, statuses, numbering, drag and drop
- Shared recurrence engine
- Time tracking
- Quick entry and templates
- Undo, Trash, and audit metadata

### Phase 3: Personal growth

- Habits
- Vacation and no-guilt modes
- Challenger
- Goals and milestones
- Cross-feature progress and reports

### Phase 4: Experience completion

- Native widgets
- Global cross-module search
- Optional PIN and device-biometric application lock
- Attachments
- Advanced imports
- Reconciliation refinements
- Accessibility hardening
- Performance hardening across all platforms
- Store-ready packaging for Android, iOS, Windows, Linux, and macOS

A phase is not considered complete until its migrations, automated tests, and rollback behavior pass.

## 27. Success criteria

The redesign succeeds when:

- Monthly finance totals are explainable and reproducible from records.
- Safe-to-spend and savings no longer confuse cash flow with future commitments.
- Users can enter financial and time data for any day and see it in calendars and reports.
- Tasks support a stable order, numbering, In Progress status, and drag and drop.
- Installment notifications are friendly, configurable, private when requested, and globally disableable.
- The Liquid Glass identity is retained in light and dark themes without causing Android lag.
- Users can understand daily, weekly, and monthly use of their time.
- Habits, challenges, goals, tasks, and time entries connect without duplicating data.
- Existing user data can be migrated with a backup and a clear report.
- The same codebase produces usable adaptive applications for all five target platforms.
