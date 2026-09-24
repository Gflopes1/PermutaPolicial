// /lib/core/database/tables.dart

import 'package:drift/drift.dart';

/// Tabela para cache local de policiais
class LocalPoliciais extends Table {
  IntColumn get id => integer()();
  IntColumn? get forcaId => integer().nullable()();
  TextColumn get nome => text()();
  TextColumn? get email => text().nullable()();
  TextColumn? get idFuncional => text().nullable()();
  TextColumn? get qso => text().nullable()();
  TextColumn? get unidadeAtualNome => text().nullable()();
  TextColumn? get municipioAtualNome => text().nullable()();
  TextColumn? get estadoAtualSigla => text().nullable()();
  BoolColumn get lotacaoInterestadual => boolean()();
  BoolColumn? get ocultarNoMapa => boolean().nullable()();
  BoolColumn get isEmbaixador => boolean()();
  BoolColumn get isPremium => boolean()();
  TextColumn? get postoGraduacaoNome => text().nullable()();
  TextColumn? get forcaSigla => text().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela para cache local de marketplace
class LocalMarketplace extends Table {
  IntColumn get id => integer()();
  TextColumn get titulo => text()();
  TextColumn get descricao => text()();
  RealColumn get valor => real()();
  TextColumn get tipo => text()(); // 'armas', 'veiculos', 'equipamentos'
  TextColumn get fotos => text()(); // JSON string
  IntColumn get policialId => integer()();
  TextColumn? get policialNome => text().nullable()();
  TextColumn? get policialEmail => text().nullable()();
  TextColumn? get policialTelefone => text().nullable()();
  TextColumn get status => text()(); // 'PENDENTE', 'APROVADO', 'REJEITADO'
  DateTimeColumn get criadoEm => dateTime()();
  DateTimeColumn? get atualizadoEm => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela para fila de sincronização (ações offline)
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // 'POST', 'PUT', 'DELETE'
  TextColumn get endpoint => text()();
  TextColumn get data => text()(); // JSON string
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get syncedAt => dateTime().nullable()();
  TextColumn? get error => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // 'PENDING', 'SYNCING', 'COMPLETED', 'FAILED'
  
  // Não precisa sobrescrever primaryKey quando usa autoIncrement()
  // O Drift automaticamente configura 'id' como primary key
}

