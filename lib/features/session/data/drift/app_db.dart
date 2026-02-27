import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Sessions, Devices])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Session CRUD ────────────────────────────────────────────────

  Future<List<Session>> getAllSessions() {
    return (select(sessions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
          ]))
        .get();
  }

  Future<Session?> getSession(String id) {
    return (select(sessions)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertSession(SessionsCompanion entry) {
    return into(sessions).insert(entry);
  }

  Future<void> updateSession(String id, SessionsCompanion entry) {
    return (update(sessions)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteSession(String id) {
    return (delete(sessions)..where((t) => t.id.equals(id))).go();
  }

  // ── Device CRUD ─────────────────────────────────────────────────

  Future<void> upsertDevice(DevicesCompanion entry) {
    return into(devices).insertOnConflictUpdate(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'freeform', 'freeform.db'));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return NativeDatabase.createInBackground(file);
  });
}
