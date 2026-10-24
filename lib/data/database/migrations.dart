import 'package:drift/drift.dart';

/// Numbered migrations.
///
/// To change the schema:
///  1. Bump [latestSchemaVersion] in `app_database.dart`.
///  2. Add the new number to [migrations] with the steps that take a v(N-1)
///     database to vN. Never edit an older step: phones in the field have
///     already run it.
///  3. Run `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`
///     and `dart run drift_dev schema generate drift_schemas/ test/generated/`.
///  4. Add a case to `test/data/migration_test.dart` that opens the old
///     schema with data in it and checks the data survives.
///
/// Version 1 is the schema created by [Migrator.createAll].
typedef MigrationStep = Future<void> Function(Migrator m);

final Map<int, MigrationStep> migrations = {
  // 2: (m) async { await m.addColumn(...); },
};

/// Runs every step between [from] (exclusive) and [to] (inclusive), in order.
Future<void> runMigrations(Migrator m, int from, int to) async {
  for (var version = from + 1; version <= to; version++) {
    final step = migrations[version];
    if (step == null) {
      throw StateError('No migration written for schema version $version');
    }
    await step(m);
  }
}
