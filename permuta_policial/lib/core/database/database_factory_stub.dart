// /lib/core/database/database_factory_stub.dart
// Stub implementation (fallback)

import 'package:drift/drift.dart';

QueryExecutor createWebDatabase() {
  throw UnsupportedError('Web database not available');
}

QueryExecutor createNativeDatabase() {
  throw UnsupportedError('Native database not available');
}

