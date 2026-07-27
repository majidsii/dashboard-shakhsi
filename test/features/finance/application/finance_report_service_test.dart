import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/application/finance_report_service.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  const service = FinanceReportService();

  test('summary preserves exact eight-decimal values', () {
    final now = DateTime.utc(2026, 7, 26, 12);

    final summary = service.summary(
      transactions: <FinanceTransaction>[
        _transaction(
          id: 'income-a',
          type: FinanceTransactionType.income,
          amount: '0.10000001',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'income-b',
          type: FinanceTransactionType.income,
          amount: '0.20000002',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'expense-a',
          type: FinanceTransactionType.expense,
          amount: '0.00000003',
          occurredAtUtc: now,
        ),
      ],
      debts: <Debt>[
        Debt(
          id: 'debt-1',
          title: 'بدهی',
          total: _money('20.50000001'),
          paid: _money('0.50000001'),
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
      installments: <InstallmentPlan>[
        InstallmentPlan(
          id: 'plan-1',
          title: 'اقساط',
          perInstallment: _money('2.5'),
          installmentCount: 4,
          paidCount: 1,
          createdAtUtc: now,
          updatedAtUtc: now,
        ),
      ],
      now: now,
    );

    expect(summary.balance, _money('0.3'));
    expect(summary.monthIncome, _money('0.30000003'));
    expect(summary.monthExpense, _money('0.00000003'));
    expect(summary.debtRemaining, _money('27.5'));
  });

  test('summary separates the current Jalali month', () {
    final now = DateTime.utc(2026, 7, 26, 12);

    final summary = service.summary(
      transactions: <FinanceTransaction>[
        _transaction(
          id: 'current-income',
          type: FinanceTransactionType.income,
          amount: '10',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'old-income',
          type: FinanceTransactionType.income,
          amount: '40',
          occurredAtUtc: now.subtract(const Duration(days: 45)),
        ),
        _transaction(
          id: 'current-expense',
          type: FinanceTransactionType.expense,
          amount: '3',
          occurredAtUtc: now,
        ),
      ],
      debts: const <Debt>[],
      installments: const <InstallmentPlan>[],
      now: now,
    );

    expect(summary.balance, _money('47'));
    expect(summary.monthIncome, _money('10'));
    expect(summary.monthExpense, _money('3'));
  });

  test('trend returns six chronological Jalali month points', () {
    final now = DateTime.utc(2026, 7, 26, 12);
    final localNow = now.toLocal();
    final jalaliNow = Jalali.fromDateTime(localNow);

    final points = service.trend(
      transactions: <FinanceTransaction>[
        _transaction(
          id: 'income',
          type: FinanceTransactionType.income,
          amount: '11.00000001',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'expense',
          type: FinanceTransactionType.expense,
          amount: '4.00000001',
          occurredAtUtc: now,
        ),
      ],
      now: now,
    );

    expect(points, hasLength(6));
    expect(points.last.year, jalaliNow.year);
    expect(points.last.month, jalaliNow.month);
    expect(points.last.income, _money('11.00000001'));
    expect(points.last.expense, _money('4.00000001'));

    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1].year * 12 + points[index - 1].month;
      final current = points[index].year * 12 + points[index].month;
      expect(current, previous + 1);
    }
  });

  test('categories aggregate expenses and sort descending', () {
    final now = DateTime.utc(2026, 7, 26, 12);

    final current = service.categories(
      transactions: <FinanceTransaction>[
        _transaction(
          id: 'food-a',
          type: FinanceTransactionType.expense,
          category: 'خوراک',
          amount: '1.25',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'food-b',
          type: FinanceTransactionType.expense,
          category: 'خوراک',
          amount: '2.75',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'rent',
          type: FinanceTransactionType.expense,
          category: 'اجاره',
          amount: '7',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'income',
          type: FinanceTransactionType.income,
          category: 'حقوق',
          amount: '100',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'old',
          type: FinanceTransactionType.expense,
          category: 'قدیمی',
          amount: '50',
          occurredAtUtc: now.subtract(const Duration(days: 45)),
        ),
      ],
      currentMonthOnly: true,
      now: now,
    );

    expect(current.map((point) => point.label).toList(), <String>[
      'اجاره',
      'خوراک',
    ]);
    expect(current.first.value, _money('7'));
    expect(current.last.value, _money('4'));

    final all = service.categories(
      transactions: <FinanceTransaction>[
        _transaction(
          id: 'current',
          type: FinanceTransactionType.expense,
          category: 'فعلی',
          amount: '2',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'old',
          type: FinanceTransactionType.expense,
          category: 'قدیمی',
          amount: '50',
          occurredAtUtc: now.subtract(const Duration(days: 45)),
        ),
      ],
      currentMonthOnly: false,
      now: now,
    );

    expect(all.first.label, 'قدیمی');
    expect(all.first.value, _money('50'));
  });

  test('week returns seven local days and ignores income', () {
    final now = DateTime.utc(2026, 7, 26, 12);

    final points = service.week(
      transactions: <FinanceTransaction>[
        _transaction(
          id: 'today-expense',
          type: FinanceTransactionType.expense,
          amount: '1.00000001',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'two-days-ago-expense',
          type: FinanceTransactionType.expense,
          amount: '2.00000002',
          occurredAtUtc: now.subtract(const Duration(days: 2)),
        ),
        _transaction(
          id: 'today-income',
          type: FinanceTransactionType.income,
          amount: '100',
          occurredAtUtc: now,
        ),
        _transaction(
          id: 'old-expense',
          type: FinanceTransactionType.expense,
          amount: '50',
          occurredAtUtc: now.subtract(const Duration(days: 8)),
        ),
      ],
      now: now,
    );

    expect(points, hasLength(7));
    expect(points.last.isToday, isTrue);
    expect(points.last.value, _money('1.00000001'));
    expect(points[4].value, _money('2.00000002'));
    expect(points.first.value, Money.zeroIRT);

    for (var index = 1; index < points.length; index++) {
      expect(
        points[index].date.difference(points[index - 1].date),
        const Duration(days: 1),
      );
    }
  });
}

FinanceTransaction _transaction({
  required String id,
  required FinanceTransactionType type,
  required String amount,
  required DateTime occurredAtUtc,
  String category = 'آزمایش',
}) {
  return FinanceTransaction.create(
    id: id,
    type: type,
    title: id,
    category: category,
    amount: _money(amount),
    occurredAtUtc: occurredAtUtc,
    createdAtUtc: occurredAtUtc,
  );
}

Money _money(String value) {
  return Money.parseMajorUnits(
    value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );
}
