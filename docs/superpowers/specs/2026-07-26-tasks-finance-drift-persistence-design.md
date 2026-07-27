# طراحی ذخیره‌سازی دائمی تسک‌ها و امور مالی با Drift

## هدف

جایگزین‌کردن State موقت صفحه «کارها» و «مالی» با یک دیتابیس محلی و آفلاین، به‌گونه‌ای که پس از بستن یا ری‌استارت برنامه، تمام تسک‌ها، تراکنش‌ها، بدهی‌ها، پرداخت بدهی‌ها، اقساط و پرداخت اقساط بدون تغییر باقی بمانند.

ظاهر Liquid Glass، متن‌های فارسی، تاریخ جلالی و رفتار فعلی رابط کاربری نباید تغییر کند.

## محدوده این مرحله

این مرحله شامل موارد زیر است:

- ذخیره دائمی تسک‌ها
- ذخیره دائمی تراکنش‌های درآمد و هزینه
- ذخیره دائمی بدهی‌ها و پرداخت‌های بدهی
- ذخیره دائمی برنامه‌های اقساط و پرداخت اقساط
- Stream زنده برای به‌روزرسانی خودکار رابط کاربری
- محاسبه دقیق مبالغ با دقت ۸ رقم اعشار
- Migration نسخه اول دیتابیس
- تست CRUD و بازیابی داده پس از بازکردن دوباره دیتابیس

موارد زیر خارج از این مرحله‌اند:

- همگام‌سازی ابری
- حساب کاربری و ورود
- رمزنگاری SQLite با SQLCipher
- اعلان‌های محلی
- بودجه‌بندی ماهانه پیشرفته
- Import/Export فایل

## اصول داده

### مبالغ

مبالغ در UI تا ۸ رقم اعشار دارند. مقدار پول در دیتابیس به‌صورت `minor_units` عدد صحیح ۶۴ بیتی ذخیره می‌شود و `scale` همیشه برابر ۸ است.

نمونه:

```text
۱۲۳٫۴۵۶۷۸۹۰۱ تومان
minor_units = 12345678901
scale = 8
currency_code = IRT
```

هیچ محاسبه مالی با `double` انجام نمی‌شود. `double` فقط برای مختصات نمودار و Progress Visual مجاز است.

### زمان

- تاریخ‌ها داخل دیتابیس به UTC ذخیره می‌شوند.
- رابط کاربری تاریخ را به شمسی تبدیل می‌کند.
- روز و ماه گزارش‌ها بر اساس زمان محلی کاربر محاسبه می‌شوند.

### شناسه‌ها

تمام رکوردهای جدید از UUID متنی استفاده می‌کنند. شناسه UI دیگر به ترتیب لیست وابسته نیست.

## ساختار دیتابیس

نام فایل دیتابیس:

```text
dashboard_shakhsi.sqlite
```

نسخه اولیه Schema:

```text
schemaVersion = 1
```

### جدول `tasks`

| ستون | نوع | توضیح |
|---|---|---|
| `id` | TEXT PK | UUID |
| `title` | TEXT | عنوان Trim‌شده |
| `priority` | INTEGER | از ۰ تا ۳ |
| `is_done` | INTEGER/BOOL | وضعیت انجام |
| `sort_order` | INTEGER | ترتیب پایدار برای نمایش |
| `created_at_utc` | DATETIME | زمان ایجاد |
| `updated_at_utc` | DATETIME | آخرین تغییر |
| `completed_at_utc` | DATETIME NULL | زمان انجام |

فیلتر و Sort فعلی UI روی Stream داده‌های این جدول اعمال می‌شود. `sort_order` برای Drag & Drop آینده از همین حالا وجود دارد، ولی Drag & Drop در این مرحله پیاده نمی‌شود.

### جدول `finance_transactions`

فقط درآمد و هزینه در این جدول ذخیره می‌شوند.

| ستون | نوع | توضیح |
|---|---|---|
| `id` | TEXT PK | UUID |
| `type` | TEXT | `income` یا `expense` |
| `title` | TEXT | عنوان تراکنش |
| `category` | TEXT | دسته‌بندی |
| `amount_minor_units` | INTEGER | مبلغ دقیق |
| `currency_code` | TEXT | فعلاً `IRT` |
| `scale` | INTEGER | همیشه ۸ |
| `occurred_at_utc` | DATETIME | تاریخ مالی تراکنش |
| `created_at_utc` | DATETIME | زمان ایجاد رکورد |
| `updated_at_utc` | DATETIME | زمان ویرایش |

### جدول `debts`

| ستون | نوع | توضیح |
|---|---|---|
| `id` | TEXT PK | UUID |
| `title` | TEXT | نام بدهی |
| `total_minor_units` | INTEGER | مبلغ کل |
| `currency_code` | TEXT | `IRT` |
| `scale` | INTEGER | ۸ |
| `created_at_utc` | DATETIME | ایجاد |
| `updated_at_utc` | DATETIME | تغییر |
| `archived_at_utc` | DATETIME NULL | آرشیو پس از تسویه یا حذف نرم |

### جدول `debt_payments`

پرداخت بدهی به‌صورت رکورد مستقل ذخیره می‌شود تا تاریخچه و گزارش روزانه دقیق بماند.

| ستون | نوع | توضیح |
|---|---|---|
| `id` | TEXT PK | UUID |
| `debt_id` | TEXT FK | بدهی والد |
| `amount_minor_units` | INTEGER | مبلغ پرداخت |
| `paid_at_utc` | DATETIME | زمان پرداخت |
| `created_at_utc` | DATETIME | زمان ثبت |

مبلغ پرداخت‌شده بدهی از مجموع `debt_payments` محاسبه می‌شود. پرداختی که مجموع را از مبلغ کل بیشتر کند پذیرفته نمی‌شود.

### جدول `installment_plans`

| ستون | نوع | توضیح |
|---|---|---|
| `id` | TEXT PK | UUID |
| `title` | TEXT | عنوان قسط |
| `per_installment_minor_units` | INTEGER | مبلغ هر قسط |
| `installment_count` | INTEGER | تعداد کل، حداقل ۱ |
| `currency_code` | TEXT | `IRT` |
| `scale` | INTEGER | ۸ |
| `created_at_utc` | DATETIME | ایجاد |
| `updated_at_utc` | DATETIME | تغییر |
| `archived_at_utc` | DATETIME NULL | آرشیو |

### جدول `installment_payments`

| ستون | نوع | توضیح |
|---|---|---|
| `id` | TEXT PK | UUID |
| `plan_id` | TEXT FK | برنامه قسط والد |
| `installment_number` | INTEGER | شماره قسط پرداخت‌شده |
| `amount_minor_units` | INTEGER | مبلغ واقعی پرداخت |
| `paid_at_utc` | DATETIME | زمان پرداخت |
| `created_at_utc` | DATETIME | زمان ثبت |

روی `(plan_id, installment_number)` محدودیت Unique وجود دارد. تعداد پرداخت‌شده از تعداد رکوردهای پرداخت محاسبه می‌شود و نمی‌تواند از تعداد کل بیشتر شود.

## معماری فایل‌ها

```text
lib/
  core/
    database/
      app_database.dart
      app_database.g.dart
      database_connection.dart
  features/
    tasks/
      domain/
        task_item.dart
        task_repository.dart
      data/
        drift_task_repository.dart
    finance/
      domain/
        finance_transaction.dart
        debt.dart
        installment_plan.dart
        finance_repository.dart
      data/
        drift_finance_repository.dart
      application/
        finance_summary.dart
        finance_report_service.dart
```

### `AppDatabase`

مسئولیت‌ها:

- تعریف Tableها
- تعریف Foreign Key و Indexها
- بازکردن دیتابیس با `drift_flutter`
- مدیریت `schemaVersion`
- Migrationها
- اجرای Transactionهای اتمیک

### Repository تسک

رابط پیشنهادی:

```dart
abstract interface class TaskRepository {
  Stream<List<TaskItem>> watchAll();
  Future<void> create(TaskItem task);
  Future<void> update(TaskItem task);
  Future<void> setDone(String id, bool isDone, DateTime changedAt);
  Future<void> delete(String id);
  Future<void> deleteCompleted();
  Future<void> reorder(List<String> orderedIds);
}
```

### Repository مالی

رابط پیشنهادی:

```dart
abstract interface class FinanceRepository {
  Stream<List<FinanceTransaction>> watchTransactions();
  Stream<List<Debt>> watchDebts();
  Stream<List<InstallmentPlan>> watchInstallmentPlans();

  Future<void> addTransaction(FinanceTransaction transaction);
  Future<void> deleteTransaction(String id);

  Future<void> addDebt(Debt debt);
  Future<void> recordDebtPayment({
    required String debtId,
    required Money amount,
    required DateTime paidAt,
  });
  Future<void> deleteDebt(String id);

  Future<void> addInstallmentPlan(InstallmentPlan plan);
  Future<void> payNextInstallment({
    required String planId,
    required DateTime paidAt,
  });
  Future<void> deleteInstallmentPlan(String id);
}
```

پرداخت بدهی و قسط داخل Drift Transaction انجام می‌شود تا بررسی مانده و درج پرداخت اتمیک باشد.

## Riverpod و جریان داده

Providerهای اصلی:

```text
appDatabaseProvider
 taskRepositoryProvider
financeRepositoryProvider
watchTasksProvider
watchTransactionsProvider
watchDebtsProvider
watchInstallmentsProvider
```

صفحه‌ها دیگر `List` محلی نگه نمی‌دارند. هر صفحه داده را از Stream Provider دریافت می‌کند و عملیات را از Repository صدا می‌زند.

حالت‌های UI:

- `loading`: Skeleton یا همان فضای خالی فعلی بدون Flash اضافی
- `data`: UI فعلی بدون تغییر ظاهری
- `error`: پیام فارسی داخل همان پنل، همراه دکمه «تلاش دوباره»

## اتصال به UI فعلی

### صفحه کارها

حذف می‌شود:

```text
final List<_TaskPreview> _tasks
int _nextTaskId
```

جایگزین می‌شود با:

```text
watchTasksProvider
TaskRepository
```

Stateهای جست‌وجو، فیلتر، Sort و متن ورودی همچنان محلی و موقت باقی می‌مانند.

### صفحه مالی

حذف می‌شود:

```text
List<FinancePreviewTransaction>
List<FinancePreviewDebt>
List<FinancePreviewInstallment>
```

جایگزین می‌شود با Streamهای Repository. محاسبات کارت‌ها و نمودارها از Domain Modelها انجام می‌شوند.

ظاهر کارت‌ها، فرم‌ها، نمودارها و فیلترها تغییر نمی‌کند.

## Validation و خطاها

- عنوان خالی ثبت نمی‌شود.
- مبلغ باید بزرگ‌تر از صفر باشد.
- Scale مبلغ باید ۸ و Currency باید `IRT` باشد.
- مبلغ پرداخت بدهی نمی‌تواند بیشتر از مانده باشد.
- قسط پرداخت‌شده تکراری ثبت نمی‌شود.
- تعداد اقساط حداقل ۱ است.
- خطای دیتابیس با `AppFailure` به پیام فارسی تبدیل می‌شود.
- در صورت شکست عملیات، UI مقدار خوش‌بینانه نمایش نمی‌دهد؛ ابتدا دیتابیس Commit می‌شود، سپس Stream UI را به‌روزرسانی می‌کند.

## Migration

نسخه ۱ دیتابیس Tableها را ایجاد می‌کند. چون نسخه فعلی داده را فقط در حافظه نگه می‌دارد، داده‌ای برای انتقال خودکار از نسخه قبلی وجود ندارد.

Migrationهای بعدی فقط از طریق `MigrationStrategy` و تست اختصاصی اضافه می‌شوند. حذف و ساخت دوباره دیتابیس در نسخه Release مجاز نیست.

## تست‌ها

### تست دیتابیس

- ساخت Schema نسخه ۱
- Foreign Keyهای پرداخت‌ها
- Unique بودن شماره قسط
- حذف Cascade پرداخت‌ها همراه والد

### تست Repository تسک

- ساخت تسک و دریافت از Stream
- تغییر عنوان و اولویت
- انجام/بازکردن دوباره تسک
- حذف انجام‌شده‌ها
- حفظ ترتیب بعد از بازکردن دوباره دیتابیس

### تست Repository مالی

- ذخیره و بازیابی درآمد/هزینه با ۸ رقم اعشار
- جمع دقیق بدون `double`
- ثبت پرداخت بدهی
- جلوگیری از Overpayment
- پرداخت قسط بعدی
- جلوگیری از پرداخت بیشتر از تعداد کل

### تست Restart

یک دیتابیس File-backed موقت ساخته می‌شود:

1. داده ثبت می‌شود.
2. اتصال بسته می‌شود.
3. دیتابیس از همان فایل دوباره باز می‌شود.
4. داده‌ها و مبالغ دقیق مقایسه می‌شوند.

### تست Widget

تست‌های فعلی با Repository حافظه‌ای یا دیتابیس موقت اجرا می‌شوند و ظاهر/رفتار فعلی را حفظ می‌کنند.

## معیار پذیرش

این مرحله زمانی کامل است که:

- `flutter analyze` بدون Issue باشد.
- تمام تست‌ها پاس شوند.
- پس از ثبت تسک و داده مالی، بستن کامل برنامه و اجرای دوباره داده‌ها را حفظ کند.
- مبالغ ۸ رقمی دقیقاً Round-trip شوند.
- کارت‌ها و نمودارها پس از Restart همان نتایج را نشان دهند.
- ظاهر صفحات کارها و مالی نسبت به Commit فعلی تغییر محسوسی نکند.

## نکته امنیتی

دیتابیس در این مرحله محلی و آفلاین است، اما به‌صورت پیش‌فرض رمزنگاری‌شده نیست. رمزنگاری دیتابیس و مدیریت کلید باید در یک مرحله مستقل انجام شود تا Migration و بازیابی داده با ریسک کمتر طراحی شود.
