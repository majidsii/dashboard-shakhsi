import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the persistent, cross-platform dashboard database.
///
/// On native Flutter platforms, drift_flutter stores this connection in a
/// file named `dashboard_shakhsi.sqlite` in the application documents folder.
DatabaseConnection openDashboardDatabase() {
  return driftDatabase(name: 'dashboard_shakhsi');
}
