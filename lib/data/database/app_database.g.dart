// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UploadStatesTable extends UploadStates
    with TableInfo<$UploadStatesTable, UploadState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverAssetIdMeta = const VerificationMeta(
    'serverAssetId',
  );
  @override
  late final GeneratedColumn<String> serverAssetId = GeneratedColumn<String>(
    'server_asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    hash,
    size,
    status,
    serverAssetId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('server_asset_id')) {
      context.handle(
        _serverAssetIdMeta,
        serverAssetId.isAcceptableOrUnknown(
          data['server_asset_id']!,
          _serverAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      serverAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_asset_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UploadStatesTable createAlias(String alias) {
    return $UploadStatesTable(attachedDatabase, alias);
  }
}

class UploadState extends DataClass implements Insertable<UploadState> {
  final int id;
  final String localId;
  final String hash;
  final int size;
  final String status;
  final String? serverAssetId;
  final DateTime updatedAt;
  const UploadState({
    required this.id,
    required this.localId,
    required this.hash,
    required this.size,
    required this.status,
    this.serverAssetId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    map['hash'] = Variable<String>(hash);
    map['size'] = Variable<int>(size);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || serverAssetId != null) {
      map['server_asset_id'] = Variable<String>(serverAssetId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UploadStatesCompanion toCompanion(bool nullToAbsent) {
    return UploadStatesCompanion(
      id: Value(id),
      localId: Value(localId),
      hash: Value(hash),
      size: Value(size),
      status: Value(status),
      serverAssetId: serverAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverAssetId),
      updatedAt: Value(updatedAt),
    );
  }

  factory UploadState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadState(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      hash: serializer.fromJson<String>(json['hash']),
      size: serializer.fromJson<int>(json['size']),
      status: serializer.fromJson<String>(json['status']),
      serverAssetId: serializer.fromJson<String?>(json['serverAssetId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'hash': serializer.toJson<String>(hash),
      'size': serializer.toJson<int>(size),
      'status': serializer.toJson<String>(status),
      'serverAssetId': serializer.toJson<String?>(serverAssetId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UploadState copyWith({
    int? id,
    String? localId,
    String? hash,
    int? size,
    String? status,
    Value<String?> serverAssetId = const Value.absent(),
    DateTime? updatedAt,
  }) => UploadState(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    hash: hash ?? this.hash,
    size: size ?? this.size,
    status: status ?? this.status,
    serverAssetId: serverAssetId.present
        ? serverAssetId.value
        : this.serverAssetId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UploadState copyWithCompanion(UploadStatesCompanion data) {
    return UploadState(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      hash: data.hash.present ? data.hash.value : this.hash,
      size: data.size.present ? data.size.value : this.size,
      status: data.status.present ? data.status.value : this.status,
      serverAssetId: data.serverAssetId.present
          ? data.serverAssetId.value
          : this.serverAssetId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadState(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('hash: $hash, ')
          ..write('size: $size, ')
          ..write('status: $status, ')
          ..write('serverAssetId: $serverAssetId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, localId, hash, size, status, serverAssetId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadState &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.hash == this.hash &&
          other.size == this.size &&
          other.status == this.status &&
          other.serverAssetId == this.serverAssetId &&
          other.updatedAt == this.updatedAt);
}

class UploadStatesCompanion extends UpdateCompanion<UploadState> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String> hash;
  final Value<int> size;
  final Value<String> status;
  final Value<String?> serverAssetId;
  final Value<DateTime> updatedAt;
  const UploadStatesCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.hash = const Value.absent(),
    this.size = const Value.absent(),
    this.status = const Value.absent(),
    this.serverAssetId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UploadStatesCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required String hash,
    required int size,
    required String status,
    this.serverAssetId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : localId = Value(localId),
       hash = Value(hash),
       size = Value(size),
       status = Value(status);
  static Insertable<UploadState> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? hash,
    Expression<int>? size,
    Expression<String>? status,
    Expression<String>? serverAssetId,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (hash != null) 'hash': hash,
      if (size != null) 'size': size,
      if (status != null) 'status': status,
      if (serverAssetId != null) 'server_asset_id': serverAssetId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UploadStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String>? hash,
    Value<int>? size,
    Value<String>? status,
    Value<String?>? serverAssetId,
    Value<DateTime>? updatedAt,
  }) {
    return UploadStatesCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      hash: hash ?? this.hash,
      size: size ?? this.size,
      status: status ?? this.status,
      serverAssetId: serverAssetId ?? this.serverAssetId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (serverAssetId.present) {
      map['server_asset_id'] = Variable<String>(serverAssetId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadStatesCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('hash: $hash, ')
          ..write('size: $size, ')
          ..write('status: $status, ')
          ..write('serverAssetId: $serverAssetId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UploadStatesTable uploadStates = $UploadStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [uploadStates];
}

typedef $$UploadStatesTableCreateCompanionBuilder =
    UploadStatesCompanion Function({
      Value<int> id,
      required String localId,
      required String hash,
      required int size,
      required String status,
      Value<String?> serverAssetId,
      Value<DateTime> updatedAt,
    });
typedef $$UploadStatesTableUpdateCompanionBuilder =
    UploadStatesCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String> hash,
      Value<int> size,
      Value<String> status,
      Value<String?> serverAssetId,
      Value<DateTime> updatedAt,
    });

class $$UploadStatesTableFilterComposer
    extends Composer<_$AppDatabase, $UploadStatesTable> {
  $$UploadStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverAssetId => $composableBuilder(
    column: $table.serverAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UploadStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadStatesTable> {
  $$UploadStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverAssetId => $composableBuilder(
    column: $table.serverAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadStatesTable> {
  $$UploadStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get serverAssetId => $composableBuilder(
    column: $table.serverAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UploadStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UploadStatesTable,
          UploadState,
          $$UploadStatesTableFilterComposer,
          $$UploadStatesTableOrderingComposer,
          $$UploadStatesTableAnnotationComposer,
          $$UploadStatesTableCreateCompanionBuilder,
          $$UploadStatesTableUpdateCompanionBuilder,
          (
            UploadState,
            BaseReferences<_$AppDatabase, $UploadStatesTable, UploadState>,
          ),
          UploadState,
          PrefetchHooks Function()
        > {
  $$UploadStatesTableTableManager(_$AppDatabase db, $UploadStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> serverAssetId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UploadStatesCompanion(
                id: id,
                localId: localId,
                hash: hash,
                size: size,
                status: status,
                serverAssetId: serverAssetId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                required String hash,
                required int size,
                required String status,
                Value<String?> serverAssetId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UploadStatesCompanion.insert(
                id: id,
                localId: localId,
                hash: hash,
                size: size,
                status: status,
                serverAssetId: serverAssetId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UploadStatesTable,
      UploadState,
      $$UploadStatesTableFilterComposer,
      $$UploadStatesTableOrderingComposer,
      $$UploadStatesTableAnnotationComposer,
      $$UploadStatesTableCreateCompanionBuilder,
      $$UploadStatesTableUpdateCompanionBuilder,
      (
        UploadState,
        BaseReferences<_$AppDatabase, $UploadStatesTable, UploadState>,
      ),
      UploadState,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UploadStatesTableTableManager get uploadStates =>
      $$UploadStatesTableTableManager(_db, _db.uploadStates);
}
