import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/dashboard/presentation/widgets/finance_preview_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Money amount(String value) => Money.parseMajorUnits(
    value,
    currencyCode: Money.tomanCurrencyCode,
    scale: Money.financeScale,
  );

  test('finance totals retain all eight decimal digits exactly', () {
    final now = DateTime(2026, 7, 26);
    final totals = FinancePreviewMath.totals(
      now: now,
      transactions: <FinancePreviewTransaction>[
        FinancePreviewTransaction(
          id: 1,
          type: FinanceEntryType.income,
          title: 'درآمد',
          category: 'حقوق',
          amount: amount('1000.12345678'),
          createdAt: now,
        ),
        FinancePreviewTransaction(
          id: 2,
          type: FinanceEntryType.expense,
          title: 'هزینه',
          category: 'خوراک',
          amount: amount('0.00000001'),
          createdAt: now,
        ),
      ],
      debts: <FinancePreviewDebt>[
        FinancePreviewDebt(
          id: 3,
          title: 'بدهی',
          total: amount('20.50000001'),
          paid: amount('0.50000001'),
        ),
      ],
      installments: <FinancePreviewInstallment>[],
    );

    expect(totals.balance.formatMajorUnits(), '۱٬۰۰۰٫۱۲۳۴۵۶۷۷');
    expect(totals.monthIncome.formatMajorUnits(), '۱٬۰۰۰٫۱۲۳۴۵۶۷۸');
    expect(totals.monthExpense.formatMajorUnits(), '۰٫۰۰۰۰۰۰۰۱');
    expect(totals.debtRemaining.formatMajorUnits(), '۲۰');
  });
}
