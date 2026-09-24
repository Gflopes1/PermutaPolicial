// /lib/core/database/database_factory_io.dart
// Mobile/Desktop implementation

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor createNativeDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'permuta_policial.db'));
    return NativeDatabase(file);
  });
}

QueryExecutor createWebDatabase() {
  throw UnsupportedError('Web database not available on native platforms');
}

