// /lib/core/database/database_factory.dart

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

// Importações condicionais para path e file
import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart'
    if (dart.library.html) 'database_factory_web.dart';

/// Factory para criar conexão de banco de dados condicionalmente (Web/Mobile)
QueryExecutor createDatabaseConnection() {
  if (kIsWeb) {
    return createWebDatabase();
  } else {
    return createNativeDatabase();
  }
}
