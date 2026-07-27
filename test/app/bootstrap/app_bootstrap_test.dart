import 'package:dashboard_shakhsi/app/bootstrap/app_bootstrap.dart';
import 'package:dashboard_shakhsi/core/providers/persistence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  testWidgets('app starts in Persian with RTL directionality', (tester) async {
    final database = openTestDatabase();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const DashboardShakhsiApp(),
      ),
    );
    await tester.pump();

    final dashboard = find.text('داشبورد شخصی');

    expect(dashboard, findsOneWidget);
    expect(Directionality.of(tester.element(dashboard)), TextDirection.rtl);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
