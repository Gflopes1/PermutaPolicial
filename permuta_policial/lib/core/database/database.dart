// /lib/core/database/database.dart

import 'package:drift/drift.dart';
import 'tables.dart';
import 'database_factory.dart';

part 'database.g.dart';

@DriftDatabase(tables: [LocalPoliciais, LocalMarketplace, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Implementar migrações futuras aqui
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() => createDatabaseConnection());
}

