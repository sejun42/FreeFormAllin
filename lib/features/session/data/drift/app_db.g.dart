// GENERATED CODE - DO NOT MODIFY BY HAND
// This is a manually maintained file that mirrors drift codegen output.
// Run `dart run build_runner build` to regenerate.

// ignore_for_file: type=lint
// ignore_for_file: use_null_aware_elements

part of 'app_db.dart';

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _idMeta = VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );

  static const VerificationMeta _startedAtMeta = VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );

  static const VerificationMeta _endedAtMeta = VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );

  static const VerificationMeta _deviceLeftIdMeta = VerificationMeta(
    'deviceLeftId',
  );
  @override
  late final GeneratedColumn<String> deviceLeftId = GeneratedColumn<String>(
    'device_left_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );

  static const VerificationMeta _deviceRightIdMeta = VerificationMeta(
    'deviceRightId',
  );
  @override
  late final GeneratedColumn<String> deviceRightId = GeneratedColumn<String>(
    'device_right_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );

  static const VerificationMeta _packetsLeftMeta = VerificationMeta(
    'packetsLeft',
  );
  @override
  late final GeneratedColumn<int> packetsLeft = GeneratedColumn<int>(
    'packets_left',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  static const VerificationMeta _packetsRightMeta = VerificationMeta(
    'packetsRight',
  );
  @override
  late final GeneratedColumn<int> packetsRight = GeneratedColumn<int>(
    'packets_right',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  static const VerificationMeta _dropsLeftMeta = VerificationMeta('dropsLeft');
  @override
  late final GeneratedColumn<int> dropsLeft = GeneratedColumn<int>(
    'drops_left',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  static const VerificationMeta _dropsRightMeta = VerificationMeta(
    'dropsRight',
  );
  @override
  late final GeneratedColumn<int> dropsRight = GeneratedColumn<int>(
    'drops_right',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  static const VerificationMeta _estimatedHzLeftMeta = VerificationMeta(
    'estimatedHzLeft',
  );
  @override
  late final GeneratedColumn<double> estimatedHzLeft = GeneratedColumn<double>(
    'estimated_hz_left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  static const VerificationMeta _estimatedHzRightMeta = VerificationMeta(
    'estimatedHzRight',
  );
  @override
  late final GeneratedColumn<double> estimatedHzRight = GeneratedColumn<double>(
    'estimated_hz_right',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );

  static const VerificationMeta _dirPathMeta = VerificationMeta('dirPath');
  @override
  late final GeneratedColumn<String> dirPath = GeneratedColumn<String>(
    'dir_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );

  static const VerificationMeta _uploadedMeta = VerificationMeta('uploaded');
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );

  static const VerificationMeta _uploadErrorMeta = VerificationMeta(
    'uploadError',
  );
  @override
  late final GeneratedColumn<String> uploadError = GeneratedColumn<String>(
    'upload_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );

  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    deviceLeftId,
    deviceRightId,
    packetsLeft,
    packetsRight,
    dropsLeft,
    dropsRight,
    estimatedHzLeft,
    estimatedHzRight,
    dirPath,
    uploaded,
    uploadError,
  ];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';

  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('device_left_id')) {
      context.handle(
        _deviceLeftIdMeta,
        deviceLeftId.isAcceptableOrUnknown(
          data['device_left_id']!,
          _deviceLeftIdMeta,
        ),
      );
    }
    if (data.containsKey('device_right_id')) {
      context.handle(
        _deviceRightIdMeta,
        deviceRightId.isAcceptableOrUnknown(
          data['device_right_id']!,
          _deviceRightIdMeta,
        ),
      );
    }
    if (data.containsKey('packets_left')) {
      context.handle(
        _packetsLeftMeta,
        packetsLeft.isAcceptableOrUnknown(
          data['packets_left']!,
          _packetsLeftMeta,
        ),
      );
    }
    if (data.containsKey('packets_right')) {
      context.handle(
        _packetsRightMeta,
        packetsRight.isAcceptableOrUnknown(
          data['packets_right']!,
          _packetsRightMeta,
        ),
      );
    }
    if (data.containsKey('drops_left')) {
      context.handle(
        _dropsLeftMeta,
        dropsLeft.isAcceptableOrUnknown(data['drops_left']!, _dropsLeftMeta),
      );
    }
    if (data.containsKey('drops_right')) {
      context.handle(
        _dropsRightMeta,
        dropsRight.isAcceptableOrUnknown(data['drops_right']!, _dropsRightMeta),
      );
    }
    if (data.containsKey('estimated_hz_left')) {
      context.handle(
        _estimatedHzLeftMeta,
        estimatedHzLeft.isAcceptableOrUnknown(
          data['estimated_hz_left']!,
          _estimatedHzLeftMeta,
        ),
      );
    }
    if (data.containsKey('estimated_hz_right')) {
      context.handle(
        _estimatedHzRightMeta,
        estimatedHzRight.isAcceptableOrUnknown(
          data['estimated_hz_right']!,
          _estimatedHzRightMeta,
        ),
      );
    }
    if (data.containsKey('dir_path')) {
      context.handle(
        _dirPathMeta,
        dirPath.isAcceptableOrUnknown(data['dir_path']!, _dirPathMeta),
      );
    } else if (isInserting) {
      context.missing(_dirPathMeta);
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    if (data.containsKey('upload_error')) {
      context.handle(
        _uploadErrorMeta,
        uploadError.isAcceptableOrUnknown(
          data['upload_error']!,
          _uploadErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      deviceLeftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_left_id'],
      ),
      deviceRightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_right_id'],
      ),
      packetsLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}packets_left'],
      )!,
      packetsRight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}packets_right'],
      )!,
      dropsLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drops_left'],
      )!,
      dropsRight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drops_right'],
      )!,
      estimatedHzLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_hz_left'],
      )!,
      estimatedHzRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_hz_right'],
      )!,
      dirPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dir_path'],
      )!,
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
      uploadError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_error'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? deviceLeftId;
  final String? deviceRightId;
  final int packetsLeft;
  final int packetsRight;
  final int dropsLeft;
  final int dropsRight;
  final double estimatedHzLeft;
  final double estimatedHzRight;
  final String dirPath;
  final bool uploaded;
  final String? uploadError;

  const Session({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.deviceLeftId,
    this.deviceRightId,
    required this.packetsLeft,
    required this.packetsRight,
    required this.dropsLeft,
    required this.dropsRight,
    required this.estimatedHzLeft,
    required this.estimatedHzRight,
    required this.dirPath,
    required this.uploaded,
    this.uploadError,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || deviceLeftId != null) {
      map['device_left_id'] = Variable<String>(deviceLeftId);
    }
    if (!nullToAbsent || deviceRightId != null) {
      map['device_right_id'] = Variable<String>(deviceRightId);
    }
    map['packets_left'] = Variable<int>(packetsLeft);
    map['packets_right'] = Variable<int>(packetsRight);
    map['drops_left'] = Variable<int>(dropsLeft);
    map['drops_right'] = Variable<int>(dropsRight);
    map['estimated_hz_left'] = Variable<double>(estimatedHzLeft);
    map['estimated_hz_right'] = Variable<double>(estimatedHzRight);
    map['dir_path'] = Variable<String>(dirPath);
    map['uploaded'] = Variable<bool>(uploaded);
    if (!nullToAbsent || uploadError != null) {
      map['upload_error'] = Variable<String>(uploadError);
    }
    return map;
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return {
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'deviceLeftId': serializer.toJson<String?>(deviceLeftId),
      'deviceRightId': serializer.toJson<String?>(deviceRightId),
      'packetsLeft': serializer.toJson<int>(packetsLeft),
      'packetsRight': serializer.toJson<int>(packetsRight),
      'dropsLeft': serializer.toJson<int>(dropsLeft),
      'dropsRight': serializer.toJson<int>(dropsRight),
      'estimatedHzLeft': serializer.toJson<double>(estimatedHzLeft),
      'estimatedHzRight': serializer.toJson<double>(estimatedHzRight),
      'dirPath': serializer.toJson<String>(dirPath),
      'uploaded': serializer.toJson<bool>(uploaded),
      'uploadError': serializer.toJson<String?>(uploadError),
    };
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      deviceLeftId: deviceLeftId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceLeftId),
      deviceRightId: deviceRightId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceRightId),
      packetsLeft: Value(packetsLeft),
      packetsRight: Value(packetsRight),
      dropsLeft: Value(dropsLeft),
      dropsRight: Value(dropsRight),
      estimatedHzLeft: Value(estimatedHzLeft),
      estimatedHzRight: Value(estimatedHzRight),
      dirPath: Value(dirPath),
      uploaded: Value(uploaded),
      uploadError: uploadError == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadError),
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, startedAt: $startedAt, endedAt: $endedAt, '
        'deviceLeftId: $deviceLeftId, deviceRightId: $deviceRightId, '
        'packetsLeft: $packetsLeft, packetsRight: $packetsRight, '
        'dropsLeft: $dropsLeft, dropsRight: $dropsRight, '
        'estimatedHzLeft: $estimatedHzLeft, estimatedHzRight: $estimatedHzRight, '
        'dirPath: $dirPath, uploaded: $uploaded, uploadError: $uploadError)';
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    deviceLeftId,
    deviceRightId,
    packetsLeft,
    packetsRight,
    dropsLeft,
    dropsRight,
    estimatedHzLeft,
    estimatedHzRight,
    dirPath,
    uploaded,
    uploadError,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == id &&
          other.startedAt == startedAt &&
          other.endedAt == endedAt &&
          other.deviceLeftId == deviceLeftId &&
          other.deviceRightId == deviceRightId &&
          other.packetsLeft == packetsLeft &&
          other.packetsRight == packetsRight &&
          other.dropsLeft == dropsLeft &&
          other.dropsRight == dropsRight &&
          other.estimatedHzLeft == estimatedHzLeft &&
          other.estimatedHzRight == estimatedHzRight &&
          other.dirPath == dirPath &&
          other.uploaded == uploaded &&
          other.uploadError == uploadError);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> deviceLeftId;
  final Value<String?> deviceRightId;
  final Value<int> packetsLeft;
  final Value<int> packetsRight;
  final Value<int> dropsLeft;
  final Value<int> dropsRight;
  final Value<double> estimatedHzLeft;
  final Value<double> estimatedHzRight;
  final Value<String> dirPath;
  final Value<bool> uploaded;
  final Value<String?> uploadError;

  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.deviceLeftId = const Value.absent(),
    this.deviceRightId = const Value.absent(),
    this.packetsLeft = const Value.absent(),
    this.packetsRight = const Value.absent(),
    this.dropsLeft = const Value.absent(),
    this.dropsRight = const Value.absent(),
    this.estimatedHzLeft = const Value.absent(),
    this.estimatedHzRight = const Value.absent(),
    this.dirPath = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.uploadError = const Value.absent(),
  });

  SessionsCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.deviceLeftId = const Value.absent(),
    this.deviceRightId = const Value.absent(),
    this.packetsLeft = const Value.absent(),
    this.packetsRight = const Value.absent(),
    this.dropsLeft = const Value.absent(),
    this.dropsRight = const Value.absent(),
    this.estimatedHzLeft = const Value.absent(),
    this.estimatedHzRight = const Value.absent(),
    required String dirPath,
    this.uploaded = const Value.absent(),
    this.uploadError = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       dirPath = Value(dirPath);

  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? deviceLeftId,
    Expression<String>? deviceRightId,
    Expression<int>? packetsLeft,
    Expression<int>? packetsRight,
    Expression<int>? dropsLeft,
    Expression<int>? dropsRight,
    Expression<double>? estimatedHzLeft,
    Expression<double>? estimatedHzRight,
    Expression<String>? dirPath,
    Expression<bool>? uploaded,
    Expression<String>? uploadError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (deviceLeftId != null) 'device_left_id': deviceLeftId,
      if (deviceRightId != null) 'device_right_id': deviceRightId,
      if (packetsLeft != null) 'packets_left': packetsLeft,
      if (packetsRight != null) 'packets_right': packetsRight,
      if (dropsLeft != null) 'drops_left': dropsLeft,
      if (dropsRight != null) 'drops_right': dropsRight,
      if (estimatedHzLeft != null) 'estimated_hz_left': estimatedHzLeft,
      if (estimatedHzRight != null) 'estimated_hz_right': estimatedHzRight,
      if (dirPath != null) 'dir_path': dirPath,
      if (uploaded != null) 'uploaded': uploaded,
      if (uploadError != null) 'upload_error': uploadError,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? deviceLeftId,
    Value<String?>? deviceRightId,
    Value<int>? packetsLeft,
    Value<int>? packetsRight,
    Value<int>? dropsLeft,
    Value<int>? dropsRight,
    Value<double>? estimatedHzLeft,
    Value<double>? estimatedHzRight,
    Value<String>? dirPath,
    Value<bool>? uploaded,
    Value<String?>? uploadError,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      deviceLeftId: deviceLeftId ?? this.deviceLeftId,
      deviceRightId: deviceRightId ?? this.deviceRightId,
      packetsLeft: packetsLeft ?? this.packetsLeft,
      packetsRight: packetsRight ?? this.packetsRight,
      dropsLeft: dropsLeft ?? this.dropsLeft,
      dropsRight: dropsRight ?? this.dropsRight,
      estimatedHzLeft: estimatedHzLeft ?? this.estimatedHzLeft,
      estimatedHzRight: estimatedHzRight ?? this.estimatedHzRight,
      dirPath: dirPath ?? this.dirPath,
      uploaded: uploaded ?? this.uploaded,
      uploadError: uploadError ?? this.uploadError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (deviceLeftId.present) {
      map['device_left_id'] = Variable<String>(deviceLeftId.value);
    }
    if (deviceRightId.present) {
      map['device_right_id'] = Variable<String>(deviceRightId.value);
    }
    if (packetsLeft.present) {
      map['packets_left'] = Variable<int>(packetsLeft.value);
    }
    if (packetsRight.present) {
      map['packets_right'] = Variable<int>(packetsRight.value);
    }
    if (dropsLeft.present) {
      map['drops_left'] = Variable<int>(dropsLeft.value);
    }
    if (dropsRight.present) {
      map['drops_right'] = Variable<int>(dropsRight.value);
    }
    if (estimatedHzLeft.present) {
      map['estimated_hz_left'] = Variable<double>(estimatedHzLeft.value);
    }
    if (estimatedHzRight.present) {
      map['estimated_hz_right'] = Variable<double>(estimatedHzRight.value);
    }
    if (dirPath.present) {
      map['dir_path'] = Variable<String>(dirPath.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (uploadError.present) {
      map['upload_error'] = Variable<String>(uploadError.value);
    }
    return map;
  }

  @override
  String toString() {
    return 'SessionsCompanion(id: $id, startedAt: $startedAt, endedAt: $endedAt, '
        'deviceLeftId: $deviceLeftId, deviceRightId: $deviceRightId, '
        'packetsLeft: $packetsLeft, packetsRight: $packetsRight, '
        'dropsLeft: $dropsLeft, dropsRight: $dropsRight, '
        'estimatedHzLeft: $estimatedHzLeft, estimatedHzRight: $estimatedHzRight, '
        'dirPath: $dirPath, uploaded: $uploaded, uploadError: $uploadError)';
  }
}

// ── Devices Table ────────────────────────────────────────────────

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);

  static const VerificationMeta _idMeta = VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );

  static const VerificationMeta _nameMeta = VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );

  static const VerificationMeta _lastSeenMeta = VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );

  static const VerificationMeta _metaJsonMeta = VerificationMeta('metaJson');
  @override
  late final GeneratedColumn<String> metaJson = GeneratedColumn<String>(
    'meta_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );

  @override
  List<GeneratedColumn> get $columns => [id, name, lastSeen, metaJson];

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  String get actualTableName => $name;
  static const String $name = 'devices';

  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('meta_json')) {
      context.handle(
        _metaJsonMeta,
        metaJson.isAcceptableOrUnknown(data['meta_json']!, _metaJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};

  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      metaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta_json'],
      ),
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String id;
  final String name;
  final DateTime lastSeen;
  final String? metaJson;

  const Device({
    required this.id,
    required this.name,
    required this.lastSeen,
    this.metaJson,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    if (!nullToAbsent || metaJson != null) {
      map['meta_json'] = Variable<String>(metaJson);
    }
    return map;
  }

  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return {
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'metaJson': serializer.toJson<String?>(metaJson),
    };
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      lastSeen: Value(lastSeen),
      metaJson: metaJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metaJson),
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, lastSeen: $lastSeen, metaJson: $metaJson)';
  }

  @override
  int get hashCode => Object.hash(id, name, lastSeen, metaJson);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == id &&
          other.name == name &&
          other.lastSeen == lastSeen &&
          other.metaJson == metaJson);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> lastSeen;
  final Value<String?> metaJson;

  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.metaJson = const Value.absent(),
  });

  DevicesCompanion.insert({
    required String id,
    required String name,
    required DateTime lastSeen,
    this.metaJson = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       lastSeen = Value(lastSeen);

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? lastSeen,
    Value<String?>? metaJson,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lastSeen: lastSeen ?? this.lastSeen,
      metaJson: metaJson ?? this.metaJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (metaJson.present) {
      map['meta_json'] = Variable<String>(metaJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return 'DevicesCompanion(id: $id, name: $name, lastSeen: $lastSeen, metaJson: $metaJson)';
  }
}

// ── Database ─────────────────────────────────────────────────────

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(super.e);

  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessions, devices];
}
