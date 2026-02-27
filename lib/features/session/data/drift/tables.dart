import 'package:drift/drift.dart';

/// Drift table: sessions
class Sessions extends Table {
  TextColumn get id => text()(); // UUID primary key
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get deviceLeftId => text().nullable()();
  TextColumn get deviceRightId => text().nullable()();
  IntColumn get packetsLeft => integer().withDefault(const Constant(0))();
  IntColumn get packetsRight => integer().withDefault(const Constant(0))();
  IntColumn get dropsLeft => integer().withDefault(const Constant(0))();
  IntColumn get dropsRight => integer().withDefault(const Constant(0))();
  RealColumn get estimatedHzLeft => real().withDefault(const Constant(0))();
  RealColumn get estimatedHzRight => real().withDefault(const Constant(0))();
  TextColumn get dirPath => text()();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  TextColumn get uploadError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table: devices
class Devices extends Table {
  TextColumn get id => text()(); // BLE device ID
  TextColumn get name => text()();
  DateTimeColumn get lastSeen => dateTime()();
  TextColumn get metaJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
