// /lib/core/database/database_factory_web.dart
// Web implementation

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor createWebDatabase() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'permuta_policial_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

QueryExecutor createNativeDatabase() {
  throw UnsupportedError('Native database not available on web');
}

