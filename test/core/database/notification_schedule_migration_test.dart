import 'dart:io';

import 'package:dashboard_shakhsi/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version one migrates to two without losing task data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dashboard-shakhsi-notification-migration-',
    );
    final file = File('${directory.path}/migration.sqlite');

    try {
      final beforeMigration = AppDatabase(NativeDatabase(file));
      final now = DateTime.utc(2026, 7, 27, 8);

      await beforeMigration
          .into(beforeMigration.taskRows)
          .insert(
            TaskRowsCompanion.insert(
              id: 'task-before-migration',
              title: 'تسک قبل از مهاجرت',
              priority: 2,
              sortOrder: 0,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      await beforeMigration.customStatement(
        'DROP TABLE IF EXISTS notification_schedules',
      );
      await beforeMigration.customStatement('PRAGMA user_version = 1');
      await beforeMigration.close();

      final migrated = AppDatabase(NativeDatabase(file));
      try {
        expect(migrated.schemaVersion, 2);

        final versionRows = await migrated
            .customSelect('PRAGMA user_version')
            .get();
        expect(versionRows.single.read<int>('user_version'), 2);

        final tasks = await migrated.select(migrated.taskRows).get();
        expect(tasks, hasLength(1));
        expect(tasks.single.id, 'task-before-migration');

        final tableRows = await migrated
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'table' AND name = 'notification_schedules'",
            )
            .get();
        expect(tableRows, hasLength(1));
      } finally {
        await migrated.close();
      }
    } finally {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  });
}
