import 'package:dashboard_shakhsi/core/money/money.dart';
import 'package:dashboard_shakhsi/features/finance/domain/debt.dart';
import 'package:dashboard_shakhsi/features/finance/domain/finance_transaction.dart';
import 'package:dashboard_shakhsi/features/finance/domain/installment_plan.dart';

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
