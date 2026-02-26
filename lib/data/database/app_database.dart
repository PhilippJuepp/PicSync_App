import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'upload_states_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [UploadStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<UploadState?> getByLocalId(String localId) {
    return (select(uploadStates)
          ..where((tbl) => tbl.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<void> insertOrIgnore({
    required String localId,
    required String hash,
    required int size,
  }) async {
    await into(uploadStates).insertOnConflictUpdate(
      UploadStatesCompanion(
        localId: Value(localId),
        hash: Value(hash),
        size: Value(size),
        status: const Value('NEW'),
      ),
    );
  }

  Future<void> updateStatus(String localId, String status) async {
    await (update(uploadStates)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      UploadStatesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markDone(String localId, String serverId) async {
    await (update(uploadStates)
          ..where((tbl) => tbl.localId.equals(localId)))
        .write(
      UploadStatesCompanion(
        status: const Value('DONE'),
        serverAssetId: Value(serverId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

// DB CONNECTION

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'picsync.db'));
    return NativeDatabase(file);
  });
}