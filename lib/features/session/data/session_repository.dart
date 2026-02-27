import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/logging/log.dart';
import '../domain/session.dart' as domain;
import 'drift/app_db.dart';

/// Repository bridging domain Session model ↔ Drift DB.
class SessionRepository {
  final AppDb _db;

  SessionRepository(this._db);

  /// Create a new session record in DB and its directory.
  Future<domain.Session> createSession({
    required String id,
    required DateTime startedAt,
    String? deviceLeftId,
    String? deviceRightId,
  }) async {
    final docDir = await getApplicationDocumentsDirectory();
    final dirPath = p.join(docDir.path, 'freeform', 'sessions', id);

    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await _db.insertSession(SessionsCompanion.insert(
      id: id,
      startedAt: startedAt,
      deviceLeftId: Value(deviceLeftId),
      deviceRightId: Value(deviceRightId),
      dirPath: dirPath,
    ));

    // Write session.json
    final meta = {
      'session_id': id,
      'started_at': startedAt.toIso8601String(),
      'protocol_version': '1.0',
      'app_version': '1.0.0',
    };
    final metaFile = File(p.join(dirPath, 'session.json'));
    await metaFile.writeAsString(jsonEncode(meta));

    log.i('Session created: $id at $dirPath');

    return domain.Session(
      id: id,
      startedAt: startedAt,
      deviceLeftId: deviceLeftId,
      deviceRightId: deviceRightId,
      dirPath: dirPath,
    );
  }

  /// Close session: update DB with summary stats.
  Future<void> closeSession({
    required String id,
    required DateTime endedAt,
    required int packetsLeft,
    required int packetsRight,
    required int dropsLeft,
    required int dropsRight,
    required double estimatedHzLeft,
    required double estimatedHzRight,
  }) async {
    await _db.updateSession(
      id,
      SessionsCompanion(
        endedAt: Value(endedAt),
        packetsLeft: Value(packetsLeft),
        packetsRight: Value(packetsRight),
        dropsLeft: Value(dropsLeft),
        dropsRight: Value(dropsRight),
        estimatedHzLeft: Value(estimatedHzLeft),
        estimatedHzRight: Value(estimatedHzRight),
      ),
    );
    log.i('Session closed: $id');
  }

  /// Mark session as uploaded.
  Future<void> markUploaded(String id, {String? error}) async {
    await _db.updateSession(
      id,
      SessionsCompanion(
        uploaded: Value(error == null),
        uploadError: Value(error),
      ),
    );
  }

  /// Get all sessions, newest first.
  Future<List<domain.Session>> getAllSessions() async {
    final rows = await _db.getAllSessions();
    return rows.map(_toDomain).toList();
  }

  /// Get a single session.
  Future<domain.Session?> getSession(String id) async {
    final row = await _db.getSession(id);
    return row != null ? _toDomain(row) : null;
  }

  /// Delete session (DB + files).
  Future<void> deleteSession(String id) async {
    final session = await _db.getSession(id);
    if (session != null) {
      final dir = Directory(session.dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    await _db.deleteSession(id);
    log.i('Session deleted: $id');
  }

  domain.Session _toDomain(Session row) {
    return domain.Session(
      id: row.id,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      deviceLeftId: row.deviceLeftId,
      deviceRightId: row.deviceRightId,
      packetsLeft: row.packetsLeft,
      packetsRight: row.packetsRight,
      dropsLeft: row.dropsLeft,
      dropsRight: row.dropsRight,
      estimatedHzLeft: row.estimatedHzLeft,
      estimatedHzRight: row.estimatedHzRight,
      dirPath: row.dirPath,
      uploaded: row.uploaded,
      uploadError: row.uploadError,
    );
  }
}
