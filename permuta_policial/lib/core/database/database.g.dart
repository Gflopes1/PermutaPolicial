// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalPoliciaisTable extends LocalPoliciais
    with TableInfo<$LocalPoliciaisTable, LocalPoliciai> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPoliciaisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _forcaIdMeta =
      const VerificationMeta('forcaId');
  @override
  late final GeneratedColumn<int> forcaId = GeneratedColumn<int>(
      'forca_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idFuncionalMeta =
      const VerificationMeta('idFuncional');
  @override
  late final GeneratedColumn<String> idFuncional = GeneratedColumn<String>(
      'id_funcional', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _qsoMeta = const VerificationMeta('qso');
  @override
  late final GeneratedColumn<String> qso = GeneratedColumn<String>(
      'qso', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unidadeAtualNomeMeta =
      const VerificationMeta('unidadeAtualNome');
  @override
  late final GeneratedColumn<String> unidadeAtualNome = GeneratedColumn<String>(
      'unidade_atual_nome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _municipioAtualNomeMeta =
      const VerificationMeta('municipioAtualNome');
  @override
  late final GeneratedColumn<String> municipioAtualNome =
      GeneratedColumn<String>('municipio_atual_nome', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _estadoAtualSiglaMeta =
      const VerificationMeta('estadoAtualSigla');
  @override
  late final GeneratedColumn<String> estadoAtualSigla = GeneratedColumn<String>(
      'estado_atual_sigla', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lotacaoInterestadualMeta =
      const VerificationMeta('lotacaoInterestadual');
  @override
  late final GeneratedColumn<bool> lotacaoInterestadual = GeneratedColumn<bool>(
      'lotacao_interestadual', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("lotacao_interestadual" IN (0, 1))'));
  static const VerificationMeta _ocultarNoMapaMeta =
      const VerificationMeta('ocultarNoMapa');
  @override
  late final GeneratedColumn<bool> ocultarNoMapa = GeneratedColumn<bool>(
      'ocultar_no_mapa', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("ocultar_no_mapa" IN (0, 1))'));
  static const VerificationMeta _isEmbaixadorMeta =
      const VerificationMeta('isEmbaixador');
  @override
  late final GeneratedColumn<bool> isEmbaixador = GeneratedColumn<bool>(
      'is_embaixador', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_embaixador" IN (0, 1))'));
  static const VerificationMeta _isPremiumMeta =
      const VerificationMeta('isPremium');
  @override
  late final GeneratedColumn<bool> isPremium = GeneratedColumn<bool>(
      'is_premium', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_premium" IN (0, 1))'));
  static const VerificationMeta _postoGraduacaoNomeMeta =
      const VerificationMeta('postoGraduacaoNome');
  @override
  late final GeneratedColumn<String> postoGraduacaoNome =
      GeneratedColumn<String>('posto_graduacao_nome', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _forcaSiglaMeta =
      const VerificationMeta('forcaSigla');
  @override
  late final GeneratedColumn<String> forcaSigla = GeneratedColumn<String>(
      'forca_sigla', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        forcaId,
        nome,
        email,
        idFuncional,
        qso,
        unidadeAtualNome,
        municipioAtualNome,
        estadoAtualSigla,
        lotacaoInterestadual,
        ocultarNoMapa,
        isEmbaixador,
        isPremium,
        postoGraduacaoNome,
        forcaSigla,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_policiais';
  @override
  VerificationContext validateIntegrity(Insertable<LocalPoliciai> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('forca_id')) {
      context.handle(_forcaIdMeta,
          forcaId.isAcceptableOrUnknown(data['forca_id']!, _forcaIdMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('id_funcional')) {
      context.handle(
          _idFuncionalMeta,
          idFuncional.isAcceptableOrUnknown(
              data['id_funcional']!, _idFuncionalMeta));
    }
    if (data.containsKey('qso')) {
      context.handle(
          _qsoMeta, qso.isAcceptableOrUnknown(data['qso']!, _qsoMeta));
    }
    if (data.containsKey('unidade_atual_nome')) {
      context.handle(
          _unidadeAtualNomeMeta,
          unidadeAtualNome.isAcceptableOrUnknown(
              data['unidade_atual_nome']!, _unidadeAtualNomeMeta));
    }
    if (data.containsKey('municipio_atual_nome')) {
      context.handle(
          _municipioAtualNomeMeta,
          municipioAtualNome.isAcceptableOrUnknown(
              data['municipio_atual_nome']!, _municipioAtualNomeMeta));
    }
    if (data.containsKey('estado_atual_sigla')) {
      context.handle(
          _estadoAtualSiglaMeta,
          estadoAtualSigla.isAcceptableOrUnknown(
              data['estado_atual_sigla']!, _estadoAtualSiglaMeta));
    }
    if (data.containsKey('lotacao_interestadual')) {
      context.handle(
          _lotacaoInterestadualMeta,
          lotacaoInterestadual.isAcceptableOrUnknown(
              data['lotacao_interestadual']!, _lotacaoInterestadualMeta));
    } else if (isInserting) {
      context.missing(_lotacaoInterestadualMeta);
    }
    if (data.containsKey('ocultar_no_mapa')) {
      context.handle(
          _ocultarNoMapaMeta,
          ocultarNoMapa.isAcceptableOrUnknown(
              data['ocultar_no_mapa']!, _ocultarNoMapaMeta));
    }
    if (data.containsKey('is_embaixador')) {
      context.handle(
          _isEmbaixadorMeta,
          isEmbaixador.isAcceptableOrUnknown(
              data['is_embaixador']!, _isEmbaixadorMeta));
    } else if (isInserting) {
      context.missing(_isEmbaixadorMeta);
    }
    if (data.containsKey('is_premium')) {
      context.handle(_isPremiumMeta,
          isPremium.isAcceptableOrUnknown(data['is_premium']!, _isPremiumMeta));
    } else if (isInserting) {
      context.missing(_isPremiumMeta);
    }
    if (data.containsKey('posto_graduacao_nome')) {
      context.handle(
          _postoGraduacaoNomeMeta,
          postoGraduacaoNome.isAcceptableOrUnknown(
              data['posto_graduacao_nome']!, _postoGraduacaoNomeMeta));
    }
    if (data.containsKey('forca_sigla')) {
      context.handle(
          _forcaSiglaMeta,
          forcaSigla.isAcceptableOrUnknown(
              data['forca_sigla']!, _forcaSiglaMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPoliciai map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPoliciai(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      forcaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}forca_id']),
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      idFuncional: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id_funcional']),
      qso: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}qso']),
      unidadeAtualNome: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unidade_atual_nome']),
      municipioAtualNome: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}municipio_atual_nome']),
      estadoAtualSigla: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}estado_atual_sigla']),
      lotacaoInterestadual: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}lotacao_interestadual'])!,
      ocultarNoMapa: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ocultar_no_mapa']),
      isEmbaixador: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_embaixador'])!,
      isPremium: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_premium'])!,
      postoGraduacaoNome: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}posto_graduacao_nome']),
      forcaSigla: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}forca_sigla']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $LocalPoliciaisTable createAlias(String alias) {
    return $LocalPoliciaisTable(attachedDatabase, alias);
  }
}

class LocalPoliciai extends DataClass implements Insertable<LocalPoliciai> {
  final int id;
  final int? forcaId;
  final String nome;
  final String? email;
  final String? idFuncional;
  final String? qso;
  final String? unidadeAtualNome;
  final String? municipioAtualNome;
  final String? estadoAtualSigla;
  final bool lotacaoInterestadual;
  final bool? ocultarNoMapa;
  final bool isEmbaixador;
  final bool isPremium;
  final String? postoGraduacaoNome;
  final String? forcaSigla;
  final DateTime cachedAt;
  const LocalPoliciai(
      {required this.id,
      this.forcaId,
      required this.nome,
      this.email,
      this.idFuncional,
      this.qso,
      this.unidadeAtualNome,
      this.municipioAtualNome,
      this.estadoAtualSigla,
      required this.lotacaoInterestadual,
      this.ocultarNoMapa,
      required this.isEmbaixador,
      required this.isPremium,
      this.postoGraduacaoNome,
      this.forcaSigla,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || forcaId != null) {
      map['forca_id'] = Variable<int>(forcaId);
    }
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || idFuncional != null) {
      map['id_funcional'] = Variable<String>(idFuncional);
    }
    if (!nullToAbsent || qso != null) {
      map['qso'] = Variable<String>(qso);
    }
    if (!nullToAbsent || unidadeAtualNome != null) {
      map['unidade_atual_nome'] = Variable<String>(unidadeAtualNome);
    }
    if (!nullToAbsent || municipioAtualNome != null) {
      map['municipio_atual_nome'] = Variable<String>(municipioAtualNome);
    }
    if (!nullToAbsent || estadoAtualSigla != null) {
      map['estado_atual_sigla'] = Variable<String>(estadoAtualSigla);
    }
    map['lotacao_interestadual'] = Variable<bool>(lotacaoInterestadual);
    if (!nullToAbsent || ocultarNoMapa != null) {
      map['ocultar_no_mapa'] = Variable<bool>(ocultarNoMapa);
    }
    map['is_embaixador'] = Variable<bool>(isEmbaixador);
    map['is_premium'] = Variable<bool>(isPremium);
    if (!nullToAbsent || postoGraduacaoNome != null) {
      map['posto_graduacao_nome'] = Variable<String>(postoGraduacaoNome);
    }
    if (!nullToAbsent || forcaSigla != null) {
      map['forca_sigla'] = Variable<String>(forcaSigla);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalPoliciaisCompanion toCompanion(bool nullToAbsent) {
    return LocalPoliciaisCompanion(
      id: Value(id),
      forcaId: forcaId == null && nullToAbsent
          ? const Value.absent()
          : Value(forcaId),
      nome: Value(nome),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      idFuncional: idFuncional == null && nullToAbsent
          ? const Value.absent()
          : Value(idFuncional),
      qso: qso == null && nullToAbsent ? const Value.absent() : Value(qso),
      unidadeAtualNome: unidadeAtualNome == null && nullToAbsent
          ? const Value.absent()
          : Value(unidadeAtualNome),
      municipioAtualNome: municipioAtualNome == null && nullToAbsent
          ? const Value.absent()
          : Value(municipioAtualNome),
      estadoAtualSigla: estadoAtualSigla == null && nullToAbsent
          ? const Value.absent()
          : Value(estadoAtualSigla),
      lotacaoInterestadual: Value(lotacaoInterestadual),
      ocultarNoMapa: ocultarNoMapa == null && nullToAbsent
          ? const Value.absent()
          : Value(ocultarNoMapa),
      isEmbaixador: Value(isEmbaixador),
      isPremium: Value(isPremium),
      postoGraduacaoNome: postoGraduacaoNome == null && nullToAbsent
          ? const Value.absent()
          : Value(postoGraduacaoNome),
      forcaSigla: forcaSigla == null && nullToAbsent
          ? const Value.absent()
          : Value(forcaSigla),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalPoliciai.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPoliciai(
      id: serializer.fromJson<int>(json['id']),
      forcaId: serializer.fromJson<int?>(json['forcaId']),
      nome: serializer.fromJson<String>(json['nome']),
      email: serializer.fromJson<String?>(json['email']),
      idFuncional: serializer.fromJson<String?>(json['idFuncional']),
      qso: serializer.fromJson<String?>(json['qso']),
      unidadeAtualNome: serializer.fromJson<String?>(json['unidadeAtualNome']),
      municipioAtualNome:
          serializer.fromJson<String?>(json['municipioAtualNome']),
      estadoAtualSigla: serializer.fromJson<String?>(json['estadoAtualSigla']),
      lotacaoInterestadual:
          serializer.fromJson<bool>(json['lotacaoInterestadual']),
      ocultarNoMapa: serializer.fromJson<bool?>(json['ocultarNoMapa']),
      isEmbaixador: serializer.fromJson<bool>(json['isEmbaixador']),
      isPremium: serializer.fromJson<bool>(json['isPremium']),
      postoGraduacaoNome:
          serializer.fromJson<String?>(json['postoGraduacaoNome']),
      forcaSigla: serializer.fromJson<String?>(json['forcaSigla']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'forcaId': serializer.toJson<int?>(forcaId),
      'nome': serializer.toJson<String>(nome),
      'email': serializer.toJson<String?>(email),
      'idFuncional': serializer.toJson<String?>(idFuncional),
      'qso': serializer.toJson<String?>(qso),
      'unidadeAtualNome': serializer.toJson<String?>(unidadeAtualNome),
      'municipioAtualNome': serializer.toJson<String?>(municipioAtualNome),
      'estadoAtualSigla': serializer.toJson<String?>(estadoAtualSigla),
      'lotacaoInterestadual': serializer.toJson<bool>(lotacaoInterestadual),
      'ocultarNoMapa': serializer.toJson<bool?>(ocultarNoMapa),
      'isEmbaixador': serializer.toJson<bool>(isEmbaixador),
      'isPremium': serializer.toJson<bool>(isPremium),
      'postoGraduacaoNome': serializer.toJson<String?>(postoGraduacaoNome),
      'forcaSigla': serializer.toJson<String?>(forcaSigla),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalPoliciai copyWith(
          {int? id,
          Value<int?> forcaId = const Value.absent(),
          String? nome,
          Value<String?> email = const Value.absent(),
          Value<String?> idFuncional = const Value.absent(),
          Value<String?> qso = const Value.absent(),
          Value<String?> unidadeAtualNome = const Value.absent(),
          Value<String?> municipioAtualNome = const Value.absent(),
          Value<String?> estadoAtualSigla = const Value.absent(),
          bool? lotacaoInterestadual,
          Value<bool?> ocultarNoMapa = const Value.absent(),
          bool? isEmbaixador,
          bool? isPremium,
          Value<String?> postoGraduacaoNome = const Value.absent(),
          Value<String?> forcaSigla = const Value.absent(),
          DateTime? cachedAt}) =>
      LocalPoliciai(
        id: id ?? this.id,
        forcaId: forcaId.present ? forcaId.value : this.forcaId,
        nome: nome ?? this.nome,
        email: email.present ? email.value : this.email,
        idFuncional: idFuncional.present ? idFuncional.value : this.idFuncional,
        qso: qso.present ? qso.value : this.qso,
        unidadeAtualNome: unidadeAtualNome.present
            ? unidadeAtualNome.value
            : this.unidadeAtualNome,
        municipioAtualNome: municipioAtualNome.present
            ? municipioAtualNome.value
            : this.municipioAtualNome,
        estadoAtualSigla: estadoAtualSigla.present
            ? estadoAtualSigla.value
            : this.estadoAtualSigla,
        lotacaoInterestadual: lotacaoInterestadual ?? this.lotacaoInterestadual,
        ocultarNoMapa:
            ocultarNoMapa.present ? ocultarNoMapa.value : this.ocultarNoMapa,
        isEmbaixador: isEmbaixador ?? this.isEmbaixador,
        isPremium: isPremium ?? this.isPremium,
        postoGraduacaoNome: postoGraduacaoNome.present
            ? postoGraduacaoNome.value
            : this.postoGraduacaoNome,
        forcaSigla: forcaSigla.present ? forcaSigla.value : this.forcaSigla,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  LocalPoliciai copyWithCompanion(LocalPoliciaisCompanion data) {
    return LocalPoliciai(
      id: data.id.present ? data.id.value : this.id,
      forcaId: data.forcaId.present ? data.forcaId.value : this.forcaId,
      nome: data.nome.present ? data.nome.value : this.nome,
      email: data.email.present ? data.email.value : this.email,
      idFuncional:
          data.idFuncional.present ? data.idFuncional.value : this.idFuncional,
      qso: data.qso.present ? data.qso.value : this.qso,
      unidadeAtualNome: data.unidadeAtualNome.present
          ? data.unidadeAtualNome.value
          : this.unidadeAtualNome,
      municipioAtualNome: data.municipioAtualNome.present
          ? data.municipioAtualNome.value
          : this.municipioAtualNome,
      estadoAtualSigla: data.estadoAtualSigla.present
          ? data.estadoAtualSigla.value
          : this.estadoAtualSigla,
      lotacaoInterestadual: data.lotacaoInterestadual.present
          ? data.lotacaoInterestadual.value
          : this.lotacaoInterestadual,
      ocultarNoMapa: data.ocultarNoMapa.present
          ? data.ocultarNoMapa.value
          : this.ocultarNoMapa,
      isEmbaixador: data.isEmbaixador.present
          ? data.isEmbaixador.value
          : this.isEmbaixador,
      isPremium: data.isPremium.present ? data.isPremium.value : this.isPremium,
      postoGraduacaoNome: data.postoGraduacaoNome.present
          ? data.postoGraduacaoNome.value
          : this.postoGraduacaoNome,
      forcaSigla:
          data.forcaSigla.present ? data.forcaSigla.value : this.forcaSigla,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPoliciai(')
          ..write('id: $id, ')
          ..write('forcaId: $forcaId, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('idFuncional: $idFuncional, ')
          ..write('qso: $qso, ')
          ..write('unidadeAtualNome: $unidadeAtualNome, ')
          ..write('municipioAtualNome: $municipioAtualNome, ')
          ..write('estadoAtualSigla: $estadoAtualSigla, ')
          ..write('lotacaoInterestadual: $lotacaoInterestadual, ')
          ..write('ocultarNoMapa: $ocultarNoMapa, ')
          ..write('isEmbaixador: $isEmbaixador, ')
          ..write('isPremium: $isPremium, ')
          ..write('postoGraduacaoNome: $postoGraduacaoNome, ')
          ..write('forcaSigla: $forcaSigla, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      forcaId,
      nome,
      email,
      idFuncional,
      qso,
      unidadeAtualNome,
      municipioAtualNome,
      estadoAtualSigla,
      lotacaoInterestadual,
      ocultarNoMapa,
      isEmbaixador,
      isPremium,
      postoGraduacaoNome,
      forcaSigla,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPoliciai &&
          other.id == this.id &&
          other.forcaId == this.forcaId &&
          other.nome == this.nome &&
          other.email == this.email &&
          other.idFuncional == this.idFuncional &&
          other.qso == this.qso &&
          other.unidadeAtualNome == this.unidadeAtualNome &&
          other.municipioAtualNome == this.municipioAtualNome &&
          other.estadoAtualSigla == this.estadoAtualSigla &&
          other.lotacaoInterestadual == this.lotacaoInterestadual &&
          other.ocultarNoMapa == this.ocultarNoMapa &&
          other.isEmbaixador == this.isEmbaixador &&
          other.isPremium == this.isPremium &&
          other.postoGraduacaoNome == this.postoGraduacaoNome &&
          other.forcaSigla == this.forcaSigla &&
          other.cachedAt == this.cachedAt);
}

class LocalPoliciaisCompanion extends UpdateCompanion<LocalPoliciai> {
  final Value<int> id;
  final Value<int?> forcaId;
  final Value<String> nome;
  final Value<String?> email;
  final Value<String?> idFuncional;
  final Value<String?> qso;
  final Value<String?> unidadeAtualNome;
  final Value<String?> municipioAtualNome;
  final Value<String?> estadoAtualSigla;
  final Value<bool> lotacaoInterestadual;
  final Value<bool?> ocultarNoMapa;
  final Value<bool> isEmbaixador;
  final Value<bool> isPremium;
  final Value<String?> postoGraduacaoNome;
  final Value<String?> forcaSigla;
  final Value<DateTime> cachedAt;
  const LocalPoliciaisCompanion({
    this.id = const Value.absent(),
    this.forcaId = const Value.absent(),
    this.nome = const Value.absent(),
    this.email = const Value.absent(),
    this.idFuncional = const Value.absent(),
    this.qso = const Value.absent(),
    this.unidadeAtualNome = const Value.absent(),
    this.municipioAtualNome = const Value.absent(),
    this.estadoAtualSigla = const Value.absent(),
    this.lotacaoInterestadual = const Value.absent(),
    this.ocultarNoMapa = const Value.absent(),
    this.isEmbaixador = const Value.absent(),
    this.isPremium = const Value.absent(),
    this.postoGraduacaoNome = const Value.absent(),
    this.forcaSigla = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  LocalPoliciaisCompanion.insert({
    this.id = const Value.absent(),
    this.forcaId = const Value.absent(),
    required String nome,
    this.email = const Value.absent(),
    this.idFuncional = const Value.absent(),
    this.qso = const Value.absent(),
    this.unidadeAtualNome = const Value.absent(),
    this.municipioAtualNome = const Value.absent(),
    this.estadoAtualSigla = const Value.absent(),
    required bool lotacaoInterestadual,
    this.ocultarNoMapa = const Value.absent(),
    required bool isEmbaixador,
    required bool isPremium,
    this.postoGraduacaoNome = const Value.absent(),
    this.forcaSigla = const Value.absent(),
    required DateTime cachedAt,
  })  : nome = Value(nome),
        lotacaoInterestadual = Value(lotacaoInterestadual),
        isEmbaixador = Value(isEmbaixador),
        isPremium = Value(isPremium),
        cachedAt = Value(cachedAt);
  static Insertable<LocalPoliciai> custom({
    Expression<int>? id,
    Expression<int>? forcaId,
    Expression<String>? nome,
    Expression<String>? email,
    Expression<String>? idFuncional,
    Expression<String>? qso,
    Expression<String>? unidadeAtualNome,
    Expression<String>? municipioAtualNome,
    Expression<String>? estadoAtualSigla,
    Expression<bool>? lotacaoInterestadual,
    Expression<bool>? ocultarNoMapa,
    Expression<bool>? isEmbaixador,
    Expression<bool>? isPremium,
    Expression<String>? postoGraduacaoNome,
    Expression<String>? forcaSigla,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (forcaId != null) 'forca_id': forcaId,
      if (nome != null) 'nome': nome,
      if (email != null) 'email': email,
      if (idFuncional != null) 'id_funcional': idFuncional,
      if (qso != null) 'qso': qso,
      if (unidadeAtualNome != null) 'unidade_atual_nome': unidadeAtualNome,
      if (municipioAtualNome != null)
        'municipio_atual_nome': municipioAtualNome,
      if (estadoAtualSigla != null) 'estado_atual_sigla': estadoAtualSigla,
      if (lotacaoInterestadual != null)
        'lotacao_interestadual': lotacaoInterestadual,
      if (ocultarNoMapa != null) 'ocultar_no_mapa': ocultarNoMapa,
      if (isEmbaixador != null) 'is_embaixador': isEmbaixador,
      if (isPremium != null) 'is_premium': isPremium,
      if (postoGraduacaoNome != null)
        'posto_graduacao_nome': postoGraduacaoNome,
      if (forcaSigla != null) 'forca_sigla': forcaSigla,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  LocalPoliciaisCompanion copyWith(
      {Value<int>? id,
      Value<int?>? forcaId,
      Value<String>? nome,
      Value<String?>? email,
      Value<String?>? idFuncional,
      Value<String?>? qso,
      Value<String?>? unidadeAtualNome,
      Value<String?>? municipioAtualNome,
      Value<String?>? estadoAtualSigla,
      Value<bool>? lotacaoInterestadual,
      Value<bool?>? ocultarNoMapa,
      Value<bool>? isEmbaixador,
      Value<bool>? isPremium,
      Value<String?>? postoGraduacaoNome,
      Value<String?>? forcaSigla,
      Value<DateTime>? cachedAt}) {
    return LocalPoliciaisCompanion(
      id: id ?? this.id,
      forcaId: forcaId ?? this.forcaId,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      idFuncional: idFuncional ?? this.idFuncional,
      qso: qso ?? this.qso,
      unidadeAtualNome: unidadeAtualNome ?? this.unidadeAtualNome,
      municipioAtualNome: municipioAtualNome ?? this.municipioAtualNome,
      estadoAtualSigla: estadoAtualSigla ?? this.estadoAtualSigla,
      lotacaoInterestadual: lotacaoInterestadual ?? this.lotacaoInterestadual,
      ocultarNoMapa: ocultarNoMapa ?? this.ocultarNoMapa,
      isEmbaixador: isEmbaixador ?? this.isEmbaixador,
      isPremium: isPremium ?? this.isPremium,
      postoGraduacaoNome: postoGraduacaoNome ?? this.postoGraduacaoNome,
      forcaSigla: forcaSigla ?? this.forcaSigla,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (forcaId.present) {
      map['forca_id'] = Variable<int>(forcaId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (idFuncional.present) {
      map['id_funcional'] = Variable<String>(idFuncional.value);
    }
    if (qso.present) {
      map['qso'] = Variable<String>(qso.value);
    }
    if (unidadeAtualNome.present) {
      map['unidade_atual_nome'] = Variable<String>(unidadeAtualNome.value);
    }
    if (municipioAtualNome.present) {
      map['municipio_atual_nome'] = Variable<String>(municipioAtualNome.value);
    }
    if (estadoAtualSigla.present) {
      map['estado_atual_sigla'] = Variable<String>(estadoAtualSigla.value);
    }
    if (lotacaoInterestadual.present) {
      map['lotacao_interestadual'] = Variable<bool>(lotacaoInterestadual.value);
    }
    if (ocultarNoMapa.present) {
      map['ocultar_no_mapa'] = Variable<bool>(ocultarNoMapa.value);
    }
    if (isEmbaixador.present) {
      map['is_embaixador'] = Variable<bool>(isEmbaixador.value);
    }
    if (isPremium.present) {
      map['is_premium'] = Variable<bool>(isPremium.value);
    }
    if (postoGraduacaoNome.present) {
      map['posto_graduacao_nome'] = Variable<String>(postoGraduacaoNome.value);
    }
    if (forcaSigla.present) {
      map['forca_sigla'] = Variable<String>(forcaSigla.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPoliciaisCompanion(')
          ..write('id: $id, ')
          ..write('forcaId: $forcaId, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('idFuncional: $idFuncional, ')
          ..write('qso: $qso, ')
          ..write('unidadeAtualNome: $unidadeAtualNome, ')
          ..write('municipioAtualNome: $municipioAtualNome, ')
          ..write('estadoAtualSigla: $estadoAtualSigla, ')
          ..write('lotacaoInterestadual: $lotacaoInterestadual, ')
          ..write('ocultarNoMapa: $ocultarNoMapa, ')
          ..write('isEmbaixador: $isEmbaixador, ')
          ..write('isPremium: $isPremium, ')
          ..write('postoGraduacaoNome: $postoGraduacaoNome, ')
          ..write('forcaSigla: $forcaSigla, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalMarketplaceTable extends LocalMarketplace
    with TableInfo<$LocalMarketplaceTable, LocalMarketplaceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMarketplaceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
      'titulo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
      'valor', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fotosMeta = const VerificationMeta('fotos');
  @override
  late final GeneratedColumn<String> fotos = GeneratedColumn<String>(
      'fotos', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _policialIdMeta =
      const VerificationMeta('policialId');
  @override
  late final GeneratedColumn<int> policialId = GeneratedColumn<int>(
      'policial_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _policialNomeMeta =
      const VerificationMeta('policialNome');
  @override
  late final GeneratedColumn<String> policialNome = GeneratedColumn<String>(
      'policial_nome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _policialEmailMeta =
      const VerificationMeta('policialEmail');
  @override
  late final GeneratedColumn<String> policialEmail = GeneratedColumn<String>(
      'policial_email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _policialTelefoneMeta =
      const VerificationMeta('policialTelefone');
  @override
  late final GeneratedColumn<String> policialTelefone = GeneratedColumn<String>(
      'policial_telefone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _criadoEmMeta =
      const VerificationMeta('criadoEm');
  @override
  late final GeneratedColumn<DateTime> criadoEm = GeneratedColumn<DateTime>(
      'criado_em', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _atualizadoEmMeta =
      const VerificationMeta('atualizadoEm');
  @override
  late final GeneratedColumn<DateTime> atualizadoEm = GeneratedColumn<DateTime>(
      'atualizado_em', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        titulo,
        descricao,
        valor,
        tipo,
        fotos,
        policialId,
        policialNome,
        policialEmail,
        policialTelefone,
        status,
        criadoEm,
        atualizadoEm,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_marketplace';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalMarketplaceData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('titulo')) {
      context.handle(_tituloMeta,
          titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta));
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
          _valorMeta, valor.isAcceptableOrUnknown(data['valor']!, _valorMeta));
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('fotos')) {
      context.handle(
          _fotosMeta, fotos.isAcceptableOrUnknown(data['fotos']!, _fotosMeta));
    } else if (isInserting) {
      context.missing(_fotosMeta);
    }
    if (data.containsKey('policial_id')) {
      context.handle(
          _policialIdMeta,
          policialId.isAcceptableOrUnknown(
              data['policial_id']!, _policialIdMeta));
    } else if (isInserting) {
      context.missing(_policialIdMeta);
    }
    if (data.containsKey('policial_nome')) {
      context.handle(
          _policialNomeMeta,
          policialNome.isAcceptableOrUnknown(
              data['policial_nome']!, _policialNomeMeta));
    }
    if (data.containsKey('policial_email')) {
      context.handle(
          _policialEmailMeta,
          policialEmail.isAcceptableOrUnknown(
              data['policial_email']!, _policialEmailMeta));
    }
    if (data.containsKey('policial_telefone')) {
      context.handle(
          _policialTelefoneMeta,
          policialTelefone.isAcceptableOrUnknown(
              data['policial_telefone']!, _policialTelefoneMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('criado_em')) {
      context.handle(_criadoEmMeta,
          criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta));
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    if (data.containsKey('atualizado_em')) {
      context.handle(
          _atualizadoEmMeta,
          atualizadoEm.isAcceptableOrUnknown(
              data['atualizado_em']!, _atualizadoEmMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMarketplaceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMarketplaceData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      titulo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titulo'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao'])!,
      valor: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      fotos: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fotos'])!,
      policialId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}policial_id'])!,
      policialNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}policial_nome']),
      policialEmail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}policial_email']),
      policialTelefone: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}policial_telefone']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      criadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}criado_em'])!,
      atualizadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}atualizado_em']),
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $LocalMarketplaceTable createAlias(String alias) {
    return $LocalMarketplaceTable(attachedDatabase, alias);
  }
}

class LocalMarketplaceData extends DataClass
    implements Insertable<LocalMarketplaceData> {
  final int id;
  final String titulo;
  final String descricao;
  final double valor;
  final String tipo;
  final String fotos;
  final int policialId;
  final String? policialNome;
  final String? policialEmail;
  final String? policialTelefone;
  final String status;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final DateTime cachedAt;
  const LocalMarketplaceData(
      {required this.id,
      required this.titulo,
      required this.descricao,
      required this.valor,
      required this.tipo,
      required this.fotos,
      required this.policialId,
      this.policialNome,
      this.policialEmail,
      this.policialTelefone,
      required this.status,
      required this.criadoEm,
      this.atualizadoEm,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['titulo'] = Variable<String>(titulo);
    map['descricao'] = Variable<String>(descricao);
    map['valor'] = Variable<double>(valor);
    map['tipo'] = Variable<String>(tipo);
    map['fotos'] = Variable<String>(fotos);
    map['policial_id'] = Variable<int>(policialId);
    if (!nullToAbsent || policialNome != null) {
      map['policial_nome'] = Variable<String>(policialNome);
    }
    if (!nullToAbsent || policialEmail != null) {
      map['policial_email'] = Variable<String>(policialEmail);
    }
    if (!nullToAbsent || policialTelefone != null) {
      map['policial_telefone'] = Variable<String>(policialTelefone);
    }
    map['status'] = Variable<String>(status);
    map['criado_em'] = Variable<DateTime>(criadoEm);
    if (!nullToAbsent || atualizadoEm != null) {
      map['atualizado_em'] = Variable<DateTime>(atualizadoEm);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalMarketplaceCompanion toCompanion(bool nullToAbsent) {
    return LocalMarketplaceCompanion(
      id: Value(id),
      titulo: Value(titulo),
      descricao: Value(descricao),
      valor: Value(valor),
      tipo: Value(tipo),
      fotos: Value(fotos),
      policialId: Value(policialId),
      policialNome: policialNome == null && nullToAbsent
          ? const Value.absent()
          : Value(policialNome),
      policialEmail: policialEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(policialEmail),
      policialTelefone: policialTelefone == null && nullToAbsent
          ? const Value.absent()
          : Value(policialTelefone),
      status: Value(status),
      criadoEm: Value(criadoEm),
      atualizadoEm: atualizadoEm == null && nullToAbsent
          ? const Value.absent()
          : Value(atualizadoEm),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalMarketplaceData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMarketplaceData(
      id: serializer.fromJson<int>(json['id']),
      titulo: serializer.fromJson<String>(json['titulo']),
      descricao: serializer.fromJson<String>(json['descricao']),
      valor: serializer.fromJson<double>(json['valor']),
      tipo: serializer.fromJson<String>(json['tipo']),
      fotos: serializer.fromJson<String>(json['fotos']),
      policialId: serializer.fromJson<int>(json['policialId']),
      policialNome: serializer.fromJson<String?>(json['policialNome']),
      policialEmail: serializer.fromJson<String?>(json['policialEmail']),
      policialTelefone: serializer.fromJson<String?>(json['policialTelefone']),
      status: serializer.fromJson<String>(json['status']),
      criadoEm: serializer.fromJson<DateTime>(json['criadoEm']),
      atualizadoEm: serializer.fromJson<DateTime?>(json['atualizadoEm']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'titulo': serializer.toJson<String>(titulo),
      'descricao': serializer.toJson<String>(descricao),
      'valor': serializer.toJson<double>(valor),
      'tipo': serializer.toJson<String>(tipo),
      'fotos': serializer.toJson<String>(fotos),
      'policialId': serializer.toJson<int>(policialId),
      'policialNome': serializer.toJson<String?>(policialNome),
      'policialEmail': serializer.toJson<String?>(policialEmail),
      'policialTelefone': serializer.toJson<String?>(policialTelefone),
      'status': serializer.toJson<String>(status),
      'criadoEm': serializer.toJson<DateTime>(criadoEm),
      'atualizadoEm': serializer.toJson<DateTime?>(atualizadoEm),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalMarketplaceData copyWith(
          {int? id,
          String? titulo,
          String? descricao,
          double? valor,
          String? tipo,
          String? fotos,
          int? policialId,
          Value<String?> policialNome = const Value.absent(),
          Value<String?> policialEmail = const Value.absent(),
          Value<String?> policialTelefone = const Value.absent(),
          String? status,
          DateTime? criadoEm,
          Value<DateTime?> atualizadoEm = const Value.absent(),
          DateTime? cachedAt}) =>
      LocalMarketplaceData(
        id: id ?? this.id,
        titulo: titulo ?? this.titulo,
        descricao: descricao ?? this.descricao,
        valor: valor ?? this.valor,
        tipo: tipo ?? this.tipo,
        fotos: fotos ?? this.fotos,
        policialId: policialId ?? this.policialId,
        policialNome:
            policialNome.present ? policialNome.value : this.policialNome,
        policialEmail:
            policialEmail.present ? policialEmail.value : this.policialEmail,
        policialTelefone: policialTelefone.present
            ? policialTelefone.value
            : this.policialTelefone,
        status: status ?? this.status,
        criadoEm: criadoEm ?? this.criadoEm,
        atualizadoEm:
            atualizadoEm.present ? atualizadoEm.value : this.atualizadoEm,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  LocalMarketplaceData copyWithCompanion(LocalMarketplaceCompanion data) {
    return LocalMarketplaceData(
      id: data.id.present ? data.id.value : this.id,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      valor: data.valor.present ? data.valor.value : this.valor,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      fotos: data.fotos.present ? data.fotos.value : this.fotos,
      policialId:
          data.policialId.present ? data.policialId.value : this.policialId,
      policialNome: data.policialNome.present
          ? data.policialNome.value
          : this.policialNome,
      policialEmail: data.policialEmail.present
          ? data.policialEmail.value
          : this.policialEmail,
      policialTelefone: data.policialTelefone.present
          ? data.policialTelefone.value
          : this.policialTelefone,
      status: data.status.present ? data.status.value : this.status,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      atualizadoEm: data.atualizadoEm.present
          ? data.atualizadoEm.value
          : this.atualizadoEm,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMarketplaceData(')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('valor: $valor, ')
          ..write('tipo: $tipo, ')
          ..write('fotos: $fotos, ')
          ..write('policialId: $policialId, ')
          ..write('policialNome: $policialNome, ')
          ..write('policialEmail: $policialEmail, ')
          ..write('policialTelefone: $policialTelefone, ')
          ..write('status: $status, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('atualizadoEm: $atualizadoEm, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      titulo,
      descricao,
      valor,
      tipo,
      fotos,
      policialId,
      policialNome,
      policialEmail,
      policialTelefone,
      status,
      criadoEm,
      atualizadoEm,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMarketplaceData &&
          other.id == this.id &&
          other.titulo == this.titulo &&
          other.descricao == this.descricao &&
          other.valor == this.valor &&
          other.tipo == this.tipo &&
          other.fotos == this.fotos &&
          other.policialId == this.policialId &&
          other.policialNome == this.policialNome &&
          other.policialEmail == this.policialEmail &&
          other.policialTelefone == this.policialTelefone &&
          other.status == this.status &&
          other.criadoEm == this.criadoEm &&
          other.atualizadoEm == this.atualizadoEm &&
          other.cachedAt == this.cachedAt);
}

class LocalMarketplaceCompanion extends UpdateCompanion<LocalMarketplaceData> {
  final Value<int> id;
  final Value<String> titulo;
  final Value<String> descricao;
  final Value<double> valor;
  final Value<String> tipo;
  final Value<String> fotos;
  final Value<int> policialId;
  final Value<String?> policialNome;
  final Value<String?> policialEmail;
  final Value<String?> policialTelefone;
  final Value<String> status;
  final Value<DateTime> criadoEm;
  final Value<DateTime?> atualizadoEm;
  final Value<DateTime> cachedAt;
  const LocalMarketplaceCompanion({
    this.id = const Value.absent(),
    this.titulo = const Value.absent(),
    this.descricao = const Value.absent(),
    this.valor = const Value.absent(),
    this.tipo = const Value.absent(),
    this.fotos = const Value.absent(),
    this.policialId = const Value.absent(),
    this.policialNome = const Value.absent(),
    this.policialEmail = const Value.absent(),
    this.policialTelefone = const Value.absent(),
    this.status = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.atualizadoEm = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  LocalMarketplaceCompanion.insert({
    this.id = const Value.absent(),
    required String titulo,
    required String descricao,
    required double valor,
    required String tipo,
    required String fotos,
    required int policialId,
    this.policialNome = const Value.absent(),
    this.policialEmail = const Value.absent(),
    this.policialTelefone = const Value.absent(),
    required String status,
    required DateTime criadoEm,
    this.atualizadoEm = const Value.absent(),
    required DateTime cachedAt,
  })  : titulo = Value(titulo),
        descricao = Value(descricao),
        valor = Value(valor),
        tipo = Value(tipo),
        fotos = Value(fotos),
        policialId = Value(policialId),
        status = Value(status),
        criadoEm = Value(criadoEm),
        cachedAt = Value(cachedAt);
  static Insertable<LocalMarketplaceData> custom({
    Expression<int>? id,
    Expression<String>? titulo,
    Expression<String>? descricao,
    Expression<double>? valor,
    Expression<String>? tipo,
    Expression<String>? fotos,
    Expression<int>? policialId,
    Expression<String>? policialNome,
    Expression<String>? policialEmail,
    Expression<String>? policialTelefone,
    Expression<String>? status,
    Expression<DateTime>? criadoEm,
    Expression<DateTime>? atualizadoEm,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titulo != null) 'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (valor != null) 'valor': valor,
      if (tipo != null) 'tipo': tipo,
      if (fotos != null) 'fotos': fotos,
      if (policialId != null) 'policial_id': policialId,
      if (policialNome != null) 'policial_nome': policialNome,
      if (policialEmail != null) 'policial_email': policialEmail,
      if (policialTelefone != null) 'policial_telefone': policialTelefone,
      if (status != null) 'status': status,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (atualizadoEm != null) 'atualizado_em': atualizadoEm,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  LocalMarketplaceCompanion copyWith(
      {Value<int>? id,
      Value<String>? titulo,
      Value<String>? descricao,
      Value<double>? valor,
      Value<String>? tipo,
      Value<String>? fotos,
      Value<int>? policialId,
      Value<String?>? policialNome,
      Value<String?>? policialEmail,
      Value<String?>? policialTelefone,
      Value<String>? status,
      Value<DateTime>? criadoEm,
      Value<DateTime?>? atualizadoEm,
      Value<DateTime>? cachedAt}) {
    return LocalMarketplaceCompanion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      fotos: fotos ?? this.fotos,
      policialId: policialId ?? this.policialId,
      policialNome: policialNome ?? this.policialNome,
      policialEmail: policialEmail ?? this.policialEmail,
      policialTelefone: policialTelefone ?? this.policialTelefone,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (fotos.present) {
      map['fotos'] = Variable<String>(fotos.value);
    }
    if (policialId.present) {
      map['policial_id'] = Variable<int>(policialId.value);
    }
    if (policialNome.present) {
      map['policial_nome'] = Variable<String>(policialNome.value);
    }
    if (policialEmail.present) {
      map['policial_email'] = Variable<String>(policialEmail.value);
    }
    if (policialTelefone.present) {
      map['policial_telefone'] = Variable<String>(policialTelefone.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<DateTime>(criadoEm.value);
    }
    if (atualizadoEm.present) {
      map['atualizado_em'] = Variable<DateTime>(atualizadoEm.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMarketplaceCompanion(')
          ..write('id: $id, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('valor: $valor, ')
          ..write('tipo: $tipo, ')
          ..write('fotos: $fotos, ')
          ..write('policialId: $policialId, ')
          ..write('policialNome: $policialNome, ')
          ..write('policialEmail: $policialEmail, ')
          ..write('policialTelefone: $policialTelefone, ')
          ..write('status: $status, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('atualizadoEm: $atualizadoEm, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('PENDING'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        action,
        endpoint,
        data,
        retryCount,
        createdAt,
        syncedAt,
        error,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String action;
  final String endpoint;
  final String data;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final String? error;
  final String status;
  const SyncQueueData(
      {required this.id,
      required this.action,
      required this.endpoint,
      required this.data,
      required this.retryCount,
      required this.createdAt,
      this.syncedAt,
      this.error,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['endpoint'] = Variable<String>(endpoint);
    map['data'] = Variable<String>(data);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      action: Value(action),
      endpoint: Value(endpoint),
      data: Value(data),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      status: Value(status),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      data: serializer.fromJson<String>(json['data']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      error: serializer.fromJson<String?>(json['error']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'endpoint': serializer.toJson<String>(endpoint),
      'data': serializer.toJson<String>(data),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'error': serializer.toJson<String?>(error),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? action,
          String? endpoint,
          String? data,
          int? retryCount,
          DateTime? createdAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          Value<String?> error = const Value.absent(),
          String? status}) =>
      SyncQueueData(
        id: id ?? this.id,
        action: action ?? this.action,
        endpoint: endpoint ?? this.endpoint,
        data: data ?? this.data,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        error: error.present ? error.value : this.error,
        status: status ?? this.status,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      data: data.data.present ? data.data.value : this.data,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      error: data.error.present ? data.error.value : this.error,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('endpoint: $endpoint, ')
          ..write('data: $data, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('error: $error, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, action, endpoint, data, retryCount,
      createdAt, syncedAt, error, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.action == this.action &&
          other.endpoint == this.endpoint &&
          other.data == this.data &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.error == this.error &&
          other.status == this.status);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> endpoint;
  final Value<String> data;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<String?> error;
  final Value<String> status;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.data = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.error = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String endpoint,
    required String data,
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.error = const Value.absent(),
    this.status = const Value.absent(),
  })  : action = Value(action),
        endpoint = Value(endpoint),
        data = Value(data),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? endpoint,
    Expression<String>? data,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<String>? error,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (endpoint != null) 'endpoint': endpoint,
      if (data != null) 'data': data,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (error != null) 'error': error,
      if (status != null) 'status': status,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? action,
      Value<String>? endpoint,
      Value<String>? data,
      Value<int>? retryCount,
      Value<DateTime>? createdAt,
      Value<DateTime?>? syncedAt,
      Value<String?>? error,
      Value<String>? status}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      endpoint: endpoint ?? this.endpoint,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('endpoint: $endpoint, ')
          ..write('data: $data, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('error: $error, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalPoliciaisTable localPoliciais = $LocalPoliciaisTable(this);
  late final $LocalMarketplaceTable localMarketplace =
      $LocalMarketplaceTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localPoliciais, localMarketplace, syncQueue];
}

typedef $$LocalPoliciaisTableCreateCompanionBuilder = LocalPoliciaisCompanion
    Function({
  Value<int> id,
  Value<int?> forcaId,
  required String nome,
  Value<String?> email,
  Value<String?> idFuncional,
  Value<String?> qso,
  Value<String?> unidadeAtualNome,
  Value<String?> municipioAtualNome,
  Value<String?> estadoAtualSigla,
  required bool lotacaoInterestadual,
  Value<bool?> ocultarNoMapa,
  required bool isEmbaixador,
  required bool isPremium,
  Value<String?> postoGraduacaoNome,
  Value<String?> forcaSigla,
  required DateTime cachedAt,
});
typedef $$LocalPoliciaisTableUpdateCompanionBuilder = LocalPoliciaisCompanion
    Function({
  Value<int> id,
  Value<int?> forcaId,
  Value<String> nome,
  Value<String?> email,
  Value<String?> idFuncional,
  Value<String?> qso,
  Value<String?> unidadeAtualNome,
  Value<String?> municipioAtualNome,
  Value<String?> estadoAtualSigla,
  Value<bool> lotacaoInterestadual,
  Value<bool?> ocultarNoMapa,
  Value<bool> isEmbaixador,
  Value<bool> isPremium,
  Value<String?> postoGraduacaoNome,
  Value<String?> forcaSigla,
  Value<DateTime> cachedAt,
});

class $$LocalPoliciaisTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPoliciaisTable> {
  $$LocalPoliciaisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get forcaId => $composableBuilder(
      column: $table.forcaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idFuncional => $composableBuilder(
      column: $table.idFuncional, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qso => $composableBuilder(
      column: $table.qso, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unidadeAtualNome => $composableBuilder(
      column: $table.unidadeAtualNome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get municipioAtualNome => $composableBuilder(
      column: $table.municipioAtualNome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get estadoAtualSigla => $composableBuilder(
      column: $table.estadoAtualSigla,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get lotacaoInterestadual => $composableBuilder(
      column: $table.lotacaoInterestadual,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ocultarNoMapa => $composableBuilder(
      column: $table.ocultarNoMapa, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEmbaixador => $composableBuilder(
      column: $table.isEmbaixador, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPremium => $composableBuilder(
      column: $table.isPremium, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get postoGraduacaoNome => $composableBuilder(
      column: $table.postoGraduacaoNome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get forcaSigla => $composableBuilder(
      column: $table.forcaSigla, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPoliciaisTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPoliciaisTable> {
  $$LocalPoliciaisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get forcaId => $composableBuilder(
      column: $table.forcaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idFuncional => $composableBuilder(
      column: $table.idFuncional, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qso => $composableBuilder(
      column: $table.qso, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unidadeAtualNome => $composableBuilder(
      column: $table.unidadeAtualNome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get municipioAtualNome => $composableBuilder(
      column: $table.municipioAtualNome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get estadoAtualSigla => $composableBuilder(
      column: $table.estadoAtualSigla,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get lotacaoInterestadual => $composableBuilder(
      column: $table.lotacaoInterestadual,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ocultarNoMapa => $composableBuilder(
      column: $table.ocultarNoMapa,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEmbaixador => $composableBuilder(
      column: $table.isEmbaixador,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPremium => $composableBuilder(
      column: $table.isPremium, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get postoGraduacaoNome => $composableBuilder(
      column: $table.postoGraduacaoNome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get forcaSigla => $composableBuilder(
      column: $table.forcaSigla, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPoliciaisTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPoliciaisTable> {
  $$LocalPoliciaisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get forcaId =>
      $composableBuilder(column: $table.forcaId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get idFuncional => $composableBuilder(
      column: $table.idFuncional, builder: (column) => column);

  GeneratedColumn<String> get qso =>
      $composableBuilder(column: $table.qso, builder: (column) => column);

  GeneratedColumn<String> get unidadeAtualNome => $composableBuilder(
      column: $table.unidadeAtualNome, builder: (column) => column);

  GeneratedColumn<String> get municipioAtualNome => $composableBuilder(
      column: $table.municipioAtualNome, builder: (column) => column);

  GeneratedColumn<String> get estadoAtualSigla => $composableBuilder(
      column: $table.estadoAtualSigla, builder: (column) => column);

  GeneratedColumn<bool> get lotacaoInterestadual => $composableBuilder(
      column: $table.lotacaoInterestadual, builder: (column) => column);

  GeneratedColumn<bool> get ocultarNoMapa => $composableBuilder(
      column: $table.ocultarNoMapa, builder: (column) => column);

  GeneratedColumn<bool> get isEmbaixador => $composableBuilder(
      column: $table.isEmbaixador, builder: (column) => column);

  GeneratedColumn<bool> get isPremium =>
      $composableBuilder(column: $table.isPremium, builder: (column) => column);

  GeneratedColumn<String> get postoGraduacaoNome => $composableBuilder(
      column: $table.postoGraduacaoNome, builder: (column) => column);

  GeneratedColumn<String> get forcaSigla => $composableBuilder(
      column: $table.forcaSigla, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalPoliciaisTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalPoliciaisTable,
    LocalPoliciai,
    $$LocalPoliciaisTableFilterComposer,
    $$LocalPoliciaisTableOrderingComposer,
    $$LocalPoliciaisTableAnnotationComposer,
    $$LocalPoliciaisTableCreateCompanionBuilder,
    $$LocalPoliciaisTableUpdateCompanionBuilder,
    (
      LocalPoliciai,
      BaseReferences<_$AppDatabase, $LocalPoliciaisTable, LocalPoliciai>
    ),
    LocalPoliciai,
    PrefetchHooks Function()> {
  $$LocalPoliciaisTableTableManager(
      _$AppDatabase db, $LocalPoliciaisTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPoliciaisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPoliciaisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPoliciaisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> forcaId = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> idFuncional = const Value.absent(),
            Value<String?> qso = const Value.absent(),
            Value<String?> unidadeAtualNome = const Value.absent(),
            Value<String?> municipioAtualNome = const Value.absent(),
            Value<String?> estadoAtualSigla = const Value.absent(),
            Value<bool> lotacaoInterestadual = const Value.absent(),
            Value<bool?> ocultarNoMapa = const Value.absent(),
            Value<bool> isEmbaixador = const Value.absent(),
            Value<bool> isPremium = const Value.absent(),
            Value<String?> postoGraduacaoNome = const Value.absent(),
            Value<String?> forcaSigla = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              LocalPoliciaisCompanion(
            id: id,
            forcaId: forcaId,
            nome: nome,
            email: email,
            idFuncional: idFuncional,
            qso: qso,
            unidadeAtualNome: unidadeAtualNome,
            municipioAtualNome: municipioAtualNome,
            estadoAtualSigla: estadoAtualSigla,
            lotacaoInterestadual: lotacaoInterestadual,
            ocultarNoMapa: ocultarNoMapa,
            isEmbaixador: isEmbaixador,
            isPremium: isPremium,
            postoGraduacaoNome: postoGraduacaoNome,
            forcaSigla: forcaSigla,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> forcaId = const Value.absent(),
            required String nome,
            Value<String?> email = const Value.absent(),
            Value<String?> idFuncional = const Value.absent(),
            Value<String?> qso = const Value.absent(),
            Value<String?> unidadeAtualNome = const Value.absent(),
            Value<String?> municipioAtualNome = const Value.absent(),
            Value<String?> estadoAtualSigla = const Value.absent(),
            required bool lotacaoInterestadual,
            Value<bool?> ocultarNoMapa = const Value.absent(),
            required bool isEmbaixador,
            required bool isPremium,
            Value<String?> postoGraduacaoNome = const Value.absent(),
            Value<String?> forcaSigla = const Value.absent(),
            required DateTime cachedAt,
          }) =>
              LocalPoliciaisCompanion.insert(
            id: id,
            forcaId: forcaId,
            nome: nome,
            email: email,
            idFuncional: idFuncional,
            qso: qso,
            unidadeAtualNome: unidadeAtualNome,
            municipioAtualNome: municipioAtualNome,
            estadoAtualSigla: estadoAtualSigla,
            lotacaoInterestadual: lotacaoInterestadual,
            ocultarNoMapa: ocultarNoMapa,
            isEmbaixador: isEmbaixador,
            isPremium: isPremium,
            postoGraduacaoNome: postoGraduacaoNome,
            forcaSigla: forcaSigla,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPoliciaisTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalPoliciaisTable,
    LocalPoliciai,
    $$LocalPoliciaisTableFilterComposer,
    $$LocalPoliciaisTableOrderingComposer,
    $$LocalPoliciaisTableAnnotationComposer,
    $$LocalPoliciaisTableCreateCompanionBuilder,
    $$LocalPoliciaisTableUpdateCompanionBuilder,
    (
      LocalPoliciai,
      BaseReferences<_$AppDatabase, $LocalPoliciaisTable, LocalPoliciai>
    ),
    LocalPoliciai,
    PrefetchHooks Function()>;
typedef $$LocalMarketplaceTableCreateCompanionBuilder
    = LocalMarketplaceCompanion Function({
  Value<int> id,
  required String titulo,
  required String descricao,
  required double valor,
  required String tipo,
  required String fotos,
  required int policialId,
  Value<String?> policialNome,
  Value<String?> policialEmail,
  Value<String?> policialTelefone,
  required String status,
  required DateTime criadoEm,
  Value<DateTime?> atualizadoEm,
  required DateTime cachedAt,
});
typedef $$LocalMarketplaceTableUpdateCompanionBuilder
    = LocalMarketplaceCompanion Function({
  Value<int> id,
  Value<String> titulo,
  Value<String> descricao,
  Value<double> valor,
  Value<String> tipo,
  Value<String> fotos,
  Value<int> policialId,
  Value<String?> policialNome,
  Value<String?> policialEmail,
  Value<String?> policialTelefone,
  Value<String> status,
  Value<DateTime> criadoEm,
  Value<DateTime?> atualizadoEm,
  Value<DateTime> cachedAt,
});

class $$LocalMarketplaceTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMarketplaceTable> {
  $$LocalMarketplaceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valor => $composableBuilder(
      column: $table.valor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotos => $composableBuilder(
      column: $table.fotos, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get policialId => $composableBuilder(
      column: $table.policialId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get policialNome => $composableBuilder(
      column: $table.policialNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get policialEmail => $composableBuilder(
      column: $table.policialEmail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get policialTelefone => $composableBuilder(
      column: $table.policialTelefone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get atualizadoEm => $composableBuilder(
      column: $table.atualizadoEm, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalMarketplaceTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMarketplaceTable> {
  $$LocalMarketplaceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valor => $composableBuilder(
      column: $table.valor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotos => $composableBuilder(
      column: $table.fotos, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get policialId => $composableBuilder(
      column: $table.policialId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get policialNome => $composableBuilder(
      column: $table.policialNome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get policialEmail => $composableBuilder(
      column: $table.policialEmail,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get policialTelefone => $composableBuilder(
      column: $table.policialTelefone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get atualizadoEm => $composableBuilder(
      column: $table.atualizadoEm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalMarketplaceTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMarketplaceTable> {
  $$LocalMarketplaceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get fotos =>
      $composableBuilder(column: $table.fotos, builder: (column) => column);

  GeneratedColumn<int> get policialId => $composableBuilder(
      column: $table.policialId, builder: (column) => column);

  GeneratedColumn<String> get policialNome => $composableBuilder(
      column: $table.policialNome, builder: (column) => column);

  GeneratedColumn<String> get policialEmail => $composableBuilder(
      column: $table.policialEmail, builder: (column) => column);

  GeneratedColumn<String> get policialTelefone => $composableBuilder(
      column: $table.policialTelefone, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<DateTime> get atualizadoEm => $composableBuilder(
      column: $table.atualizadoEm, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalMarketplaceTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalMarketplaceTable,
    LocalMarketplaceData,
    $$LocalMarketplaceTableFilterComposer,
    $$LocalMarketplaceTableOrderingComposer,
    $$LocalMarketplaceTableAnnotationComposer,
    $$LocalMarketplaceTableCreateCompanionBuilder,
    $$LocalMarketplaceTableUpdateCompanionBuilder,
    (
      LocalMarketplaceData,
      BaseReferences<_$AppDatabase, $LocalMarketplaceTable,
          LocalMarketplaceData>
    ),
    LocalMarketplaceData,
    PrefetchHooks Function()> {
  $$LocalMarketplaceTableTableManager(
      _$AppDatabase db, $LocalMarketplaceTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMarketplaceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMarketplaceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMarketplaceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> titulo = const Value.absent(),
            Value<String> descricao = const Value.absent(),
            Value<double> valor = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> fotos = const Value.absent(),
            Value<int> policialId = const Value.absent(),
            Value<String?> policialNome = const Value.absent(),
            Value<String?> policialEmail = const Value.absent(),
            Value<String?> policialTelefone = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> criadoEm = const Value.absent(),
            Value<DateTime?> atualizadoEm = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
          }) =>
              LocalMarketplaceCompanion(
            id: id,
            titulo: titulo,
            descricao: descricao,
            valor: valor,
            tipo: tipo,
            fotos: fotos,
            policialId: policialId,
            policialNome: policialNome,
            policialEmail: policialEmail,
            policialTelefone: policialTelefone,
            status: status,
            criadoEm: criadoEm,
            atualizadoEm: atualizadoEm,
            cachedAt: cachedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String titulo,
            required String descricao,
            required double valor,
            required String tipo,
            required String fotos,
            required int policialId,
            Value<String?> policialNome = const Value.absent(),
            Value<String?> policialEmail = const Value.absent(),
            Value<String?> policialTelefone = const Value.absent(),
            required String status,
            required DateTime criadoEm,
            Value<DateTime?> atualizadoEm = const Value.absent(),
            required DateTime cachedAt,
          }) =>
              LocalMarketplaceCompanion.insert(
            id: id,
            titulo: titulo,
            descricao: descricao,
            valor: valor,
            tipo: tipo,
            fotos: fotos,
            policialId: policialId,
            policialNome: policialNome,
            policialEmail: policialEmail,
            policialTelefone: policialTelefone,
            status: status,
            criadoEm: criadoEm,
            atualizadoEm: atualizadoEm,
            cachedAt: cachedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalMarketplaceTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalMarketplaceTable,
    LocalMarketplaceData,
    $$LocalMarketplaceTableFilterComposer,
    $$LocalMarketplaceTableOrderingComposer,
    $$LocalMarketplaceTableAnnotationComposer,
    $$LocalMarketplaceTableCreateCompanionBuilder,
    $$LocalMarketplaceTableUpdateCompanionBuilder,
    (
      LocalMarketplaceData,
      BaseReferences<_$AppDatabase, $LocalMarketplaceTable,
          LocalMarketplaceData>
    ),
    LocalMarketplaceData,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String action,
  required String endpoint,
  required String data,
  Value<int> retryCount,
  required DateTime createdAt,
  Value<DateTime?> syncedAt,
  Value<String?> error,
  Value<String> status,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> action,
  Value<String> endpoint,
  Value<String> data,
  Value<int> retryCount,
  Value<DateTime> createdAt,
  Value<DateTime?> syncedAt,
  Value<String?> error,
  Value<String> status,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> endpoint = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            action: action,
            endpoint: endpoint,
            data: data,
            retryCount: retryCount,
            createdAt: createdAt,
            syncedAt: syncedAt,
            error: error,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String action,
            required String endpoint,
            required String data,
            Value<int> retryCount = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            action: action,
            endpoint: endpoint,
            data: data,
            retryCount: retryCount,
            createdAt: createdAt,
            syncedAt: syncedAt,
            error: error,
            status: status,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalPoliciaisTableTableManager get localPoliciais =>
      $$LocalPoliciaisTableTableManager(_db, _db.localPoliciais);
  $$LocalMarketplaceTableTableManager get localMarketplace =>
      $$LocalMarketplaceTableTableManager(_db, _db.localMarketplace);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
