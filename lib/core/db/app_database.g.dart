// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BookmarkRowsTable extends BookmarkRows
    with TableInfo<$BookmarkRowsTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saintIdMeta =
      const VerificationMeta('saintId');
  @override
  late final GeneratedColumn<String> saintId = GeneratedColumn<String>(
      'saint_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
      'section_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paragraphIdMeta =
      const VerificationMeta('paragraphId');
  @override
  late final GeneratedColumn<String> paragraphId = GeneratedColumn<String>(
      'paragraph_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _charOffsetMeta =
      const VerificationMeta('charOffset');
  @override
  late final GeneratedColumn<int> charOffset = GeneratedColumn<int>(
      'char_offset', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<int> contentVersion = GeneratedColumn<int>(
      'content_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMsMeta =
      const VerificationMeta('createdAtMs');
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
      'created_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        saintId,
        sectionId,
        paragraphId,
        charOffset,
        contentVersion,
        createdAtMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<BookmarkRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('saint_id')) {
      context.handle(_saintIdMeta,
          saintId.isAcceptableOrUnknown(data['saint_id']!, _saintIdMeta));
    } else if (isInserting) {
      context.missing(_saintIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('paragraph_id')) {
      context.handle(
          _paragraphIdMeta,
          paragraphId.isAcceptableOrUnknown(
              data['paragraph_id']!, _paragraphIdMeta));
    } else if (isInserting) {
      context.missing(_paragraphIdMeta);
    }
    if (data.containsKey('char_offset')) {
      context.handle(
          _charOffsetMeta,
          charOffset.isAcceptableOrUnknown(
              data['char_offset']!, _charOffsetMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
          _createdAtMsMeta,
          createdAtMs.isAcceptableOrUnknown(
              data['created_at_ms']!, _createdAtMsMeta));
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {paragraphId, charOffset},
      ];
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      saintId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}saint_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_id'])!,
      paragraphId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paragraph_id'])!,
      charOffset: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}char_offset'])!,
      contentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_version'])!,
      createdAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_ms'])!,
    );
  }

  @override
  $BookmarkRowsTable createAlias(String alias) {
    return $BookmarkRowsTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final String id;
  final String saintId;
  final String sectionId;
  final String paragraphId;
  final int charOffset;

  /// The content version the bookmark was created under.
  final int contentVersion;

  /// Milliseconds since the Unix epoch (UTC).
  final int createdAtMs;
  const BookmarkRow(
      {required this.id,
      required this.saintId,
      required this.sectionId,
      required this.paragraphId,
      required this.charOffset,
      required this.contentVersion,
      required this.createdAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['saint_id'] = Variable<String>(saintId);
    map['section_id'] = Variable<String>(sectionId);
    map['paragraph_id'] = Variable<String>(paragraphId);
    map['char_offset'] = Variable<int>(charOffset);
    map['content_version'] = Variable<int>(contentVersion);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  BookmarkRowsCompanion toCompanion(bool nullToAbsent) {
    return BookmarkRowsCompanion(
      id: Value(id),
      saintId: Value(saintId),
      sectionId: Value(sectionId),
      paragraphId: Value(paragraphId),
      charOffset: Value(charOffset),
      contentVersion: Value(contentVersion),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory BookmarkRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      id: serializer.fromJson<String>(json['id']),
      saintId: serializer.fromJson<String>(json['saintId']),
      sectionId: serializer.fromJson<String>(json['sectionId']),
      paragraphId: serializer.fromJson<String>(json['paragraphId']),
      charOffset: serializer.fromJson<int>(json['charOffset']),
      contentVersion: serializer.fromJson<int>(json['contentVersion']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saintId': serializer.toJson<String>(saintId),
      'sectionId': serializer.toJson<String>(sectionId),
      'paragraphId': serializer.toJson<String>(paragraphId),
      'charOffset': serializer.toJson<int>(charOffset),
      'contentVersion': serializer.toJson<int>(contentVersion),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  BookmarkRow copyWith(
          {String? id,
          String? saintId,
          String? sectionId,
          String? paragraphId,
          int? charOffset,
          int? contentVersion,
          int? createdAtMs}) =>
      BookmarkRow(
        id: id ?? this.id,
        saintId: saintId ?? this.saintId,
        sectionId: sectionId ?? this.sectionId,
        paragraphId: paragraphId ?? this.paragraphId,
        charOffset: charOffset ?? this.charOffset,
        contentVersion: contentVersion ?? this.contentVersion,
        createdAtMs: createdAtMs ?? this.createdAtMs,
      );
  BookmarkRow copyWithCompanion(BookmarkRowsCompanion data) {
    return BookmarkRow(
      id: data.id.present ? data.id.value : this.id,
      saintId: data.saintId.present ? data.saintId.value : this.saintId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      paragraphId:
          data.paragraphId.present ? data.paragraphId.value : this.paragraphId,
      charOffset:
          data.charOffset.present ? data.charOffset.value : this.charOffset,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      createdAtMs:
          data.createdAtMs.present ? data.createdAtMs.value : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('id: $id, ')
          ..write('saintId: $saintId, ')
          ..write('sectionId: $sectionId, ')
          ..write('paragraphId: $paragraphId, ')
          ..write('charOffset: $charOffset, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, saintId, sectionId, paragraphId,
      charOffset, contentVersion, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.id == this.id &&
          other.saintId == this.saintId &&
          other.sectionId == this.sectionId &&
          other.paragraphId == this.paragraphId &&
          other.charOffset == this.charOffset &&
          other.contentVersion == this.contentVersion &&
          other.createdAtMs == this.createdAtMs);
}

class BookmarkRowsCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<String> id;
  final Value<String> saintId;
  final Value<String> sectionId;
  final Value<String> paragraphId;
  final Value<int> charOffset;
  final Value<int> contentVersion;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const BookmarkRowsCompanion({
    this.id = const Value.absent(),
    this.saintId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.paragraphId = const Value.absent(),
    this.charOffset = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarkRowsCompanion.insert({
    required String id,
    required String saintId,
    required String sectionId,
    required String paragraphId,
    this.charOffset = const Value.absent(),
    required int contentVersion,
    required int createdAtMs,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        saintId = Value(saintId),
        sectionId = Value(sectionId),
        paragraphId = Value(paragraphId),
        contentVersion = Value(contentVersion),
        createdAtMs = Value(createdAtMs);
  static Insertable<BookmarkRow> custom({
    Expression<String>? id,
    Expression<String>? saintId,
    Expression<String>? sectionId,
    Expression<String>? paragraphId,
    Expression<int>? charOffset,
    Expression<int>? contentVersion,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saintId != null) 'saint_id': saintId,
      if (sectionId != null) 'section_id': sectionId,
      if (paragraphId != null) 'paragraph_id': paragraphId,
      if (charOffset != null) 'char_offset': charOffset,
      if (contentVersion != null) 'content_version': contentVersion,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarkRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? saintId,
      Value<String>? sectionId,
      Value<String>? paragraphId,
      Value<int>? charOffset,
      Value<int>? contentVersion,
      Value<int>? createdAtMs,
      Value<int>? rowid}) {
    return BookmarkRowsCompanion(
      id: id ?? this.id,
      saintId: saintId ?? this.saintId,
      sectionId: sectionId ?? this.sectionId,
      paragraphId: paragraphId ?? this.paragraphId,
      charOffset: charOffset ?? this.charOffset,
      contentVersion: contentVersion ?? this.contentVersion,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saintId.present) {
      map['saint_id'] = Variable<String>(saintId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (paragraphId.present) {
      map['paragraph_id'] = Variable<String>(paragraphId.value);
    }
    if (charOffset.present) {
      map['char_offset'] = Variable<int>(charOffset.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<int>(contentVersion.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRowsCompanion(')
          ..write('id: $id, ')
          ..write('saintId: $saintId, ')
          ..write('sectionId: $sectionId, ')
          ..write('paragraphId: $paragraphId, ')
          ..write('charOffset: $charOffset, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressRowsTable extends ProgressRows
    with TableInfo<$ProgressRowsTable, ProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
      'section_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _saintIdMeta =
      const VerificationMeta('saintId');
  @override
  late final GeneratedColumn<String> saintId = GeneratedColumn<String>(
      'saint_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _paragraphIdMeta =
      const VerificationMeta('paragraphId');
  @override
  late final GeneratedColumn<String> paragraphId = GeneratedColumn<String>(
      'paragraph_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _charOffsetMeta =
      const VerificationMeta('charOffset');
  @override
  late final GeneratedColumn<int> charOffset = GeneratedColumn<int>(
      'char_offset', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<int> contentVersion = GeneratedColumn<int>(
      'content_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMsMeta =
      const VerificationMeta('updatedAtMs');
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
      'updated_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        sectionId,
        saintId,
        paragraphId,
        charOffset,
        contentVersion,
        updatedAtMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(Insertable<ProgressRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('saint_id')) {
      context.handle(_saintIdMeta,
          saintId.isAcceptableOrUnknown(data['saint_id']!, _saintIdMeta));
    } else if (isInserting) {
      context.missing(_saintIdMeta);
    }
    if (data.containsKey('paragraph_id')) {
      context.handle(
          _paragraphIdMeta,
          paragraphId.isAcceptableOrUnknown(
              data['paragraph_id']!, _paragraphIdMeta));
    } else if (isInserting) {
      context.missing(_paragraphIdMeta);
    }
    if (data.containsKey('char_offset')) {
      context.handle(
          _charOffsetMeta,
          charOffset.isAcceptableOrUnknown(
              data['char_offset']!, _charOffsetMeta));
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
          _updatedAtMsMeta,
          updatedAtMs.isAcceptableOrUnknown(
              data['updated_at_ms']!, _updatedAtMsMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sectionId};
  @override
  ProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressRow(
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_id'])!,
      saintId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}saint_id'])!,
      paragraphId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paragraph_id'])!,
      charOffset: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}char_offset'])!,
      contentVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}content_version'])!,
      updatedAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at_ms'])!,
    );
  }

  @override
  $ProgressRowsTable createAlias(String alias) {
    return $ProgressRowsTable(attachedDatabase, alias);
  }
}

class ProgressRow extends DataClass implements Insertable<ProgressRow> {
  final String sectionId;
  final String saintId;
  final String paragraphId;
  final int charOffset;
  final int contentVersion;
  final int updatedAtMs;
  const ProgressRow(
      {required this.sectionId,
      required this.saintId,
      required this.paragraphId,
      required this.charOffset,
      required this.contentVersion,
      required this.updatedAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section_id'] = Variable<String>(sectionId);
    map['saint_id'] = Variable<String>(saintId);
    map['paragraph_id'] = Variable<String>(paragraphId);
    map['char_offset'] = Variable<int>(charOffset);
    map['content_version'] = Variable<int>(contentVersion);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  ProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return ProgressRowsCompanion(
      sectionId: Value(sectionId),
      saintId: Value(saintId),
      paragraphId: Value(paragraphId),
      charOffset: Value(charOffset),
      contentVersion: Value(contentVersion),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory ProgressRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressRow(
      sectionId: serializer.fromJson<String>(json['sectionId']),
      saintId: serializer.fromJson<String>(json['saintId']),
      paragraphId: serializer.fromJson<String>(json['paragraphId']),
      charOffset: serializer.fromJson<int>(json['charOffset']),
      contentVersion: serializer.fromJson<int>(json['contentVersion']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sectionId': serializer.toJson<String>(sectionId),
      'saintId': serializer.toJson<String>(saintId),
      'paragraphId': serializer.toJson<String>(paragraphId),
      'charOffset': serializer.toJson<int>(charOffset),
      'contentVersion': serializer.toJson<int>(contentVersion),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  ProgressRow copyWith(
          {String? sectionId,
          String? saintId,
          String? paragraphId,
          int? charOffset,
          int? contentVersion,
          int? updatedAtMs}) =>
      ProgressRow(
        sectionId: sectionId ?? this.sectionId,
        saintId: saintId ?? this.saintId,
        paragraphId: paragraphId ?? this.paragraphId,
        charOffset: charOffset ?? this.charOffset,
        contentVersion: contentVersion ?? this.contentVersion,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      );
  ProgressRow copyWithCompanion(ProgressRowsCompanion data) {
    return ProgressRow(
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      saintId: data.saintId.present ? data.saintId.value : this.saintId,
      paragraphId:
          data.paragraphId.present ? data.paragraphId.value : this.paragraphId,
      charOffset:
          data.charOffset.present ? data.charOffset.value : this.charOffset,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      updatedAtMs:
          data.updatedAtMs.present ? data.updatedAtMs.value : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRow(')
          ..write('sectionId: $sectionId, ')
          ..write('saintId: $saintId, ')
          ..write('paragraphId: $paragraphId, ')
          ..write('charOffset: $charOffset, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sectionId, saintId, paragraphId, charOffset, contentVersion, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressRow &&
          other.sectionId == this.sectionId &&
          other.saintId == this.saintId &&
          other.paragraphId == this.paragraphId &&
          other.charOffset == this.charOffset &&
          other.contentVersion == this.contentVersion &&
          other.updatedAtMs == this.updatedAtMs);
}

class ProgressRowsCompanion extends UpdateCompanion<ProgressRow> {
  final Value<String> sectionId;
  final Value<String> saintId;
  final Value<String> paragraphId;
  final Value<int> charOffset;
  final Value<int> contentVersion;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const ProgressRowsCompanion({
    this.sectionId = const Value.absent(),
    this.saintId = const Value.absent(),
    this.paragraphId = const Value.absent(),
    this.charOffset = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressRowsCompanion.insert({
    required String sectionId,
    required String saintId,
    required String paragraphId,
    this.charOffset = const Value.absent(),
    required int contentVersion,
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  })  : sectionId = Value(sectionId),
        saintId = Value(saintId),
        paragraphId = Value(paragraphId),
        contentVersion = Value(contentVersion),
        updatedAtMs = Value(updatedAtMs);
  static Insertable<ProgressRow> custom({
    Expression<String>? sectionId,
    Expression<String>? saintId,
    Expression<String>? paragraphId,
    Expression<int>? charOffset,
    Expression<int>? contentVersion,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sectionId != null) 'section_id': sectionId,
      if (saintId != null) 'saint_id': saintId,
      if (paragraphId != null) 'paragraph_id': paragraphId,
      if (charOffset != null) 'char_offset': charOffset,
      if (contentVersion != null) 'content_version': contentVersion,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressRowsCompanion copyWith(
      {Value<String>? sectionId,
      Value<String>? saintId,
      Value<String>? paragraphId,
      Value<int>? charOffset,
      Value<int>? contentVersion,
      Value<int>? updatedAtMs,
      Value<int>? rowid}) {
    return ProgressRowsCompanion(
      sectionId: sectionId ?? this.sectionId,
      saintId: saintId ?? this.saintId,
      paragraphId: paragraphId ?? this.paragraphId,
      charOffset: charOffset ?? this.charOffset,
      contentVersion: contentVersion ?? this.contentVersion,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (saintId.present) {
      map['saint_id'] = Variable<String>(saintId.value);
    }
    if (paragraphId.present) {
      map['paragraph_id'] = Variable<String>(paragraphId.value);
    }
    if (charOffset.present) {
      map['char_offset'] = Variable<int>(charOffset.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<int>(contentVersion.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRowsCompanion(')
          ..write('sectionId: $sectionId, ')
          ..write('saintId: $saintId, ')
          ..write('paragraphId: $paragraphId, ')
          ..write('charOffset: $charOffset, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BookmarkRowsTable bookmarkRows = $BookmarkRowsTable(this);
  late final $ProgressRowsTable progressRows = $ProgressRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [bookmarkRows, progressRows, settingRows];
}

typedef $$BookmarkRowsTableCreateCompanionBuilder = BookmarkRowsCompanion
    Function({
  required String id,
  required String saintId,
  required String sectionId,
  required String paragraphId,
  Value<int> charOffset,
  required int contentVersion,
  required int createdAtMs,
  Value<int> rowid,
});
typedef $$BookmarkRowsTableUpdateCompanionBuilder = BookmarkRowsCompanion
    Function({
  Value<String> id,
  Value<String> saintId,
  Value<String> sectionId,
  Value<String> paragraphId,
  Value<int> charOffset,
  Value<int> contentVersion,
  Value<int> createdAtMs,
  Value<int> rowid,
});

class $$BookmarkRowsTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarkRowsTable> {
  $$BookmarkRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saintId => $composableBuilder(
      column: $table.saintId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paragraphId => $composableBuilder(
      column: $table.paragraphId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get charOffset => $composableBuilder(
      column: $table.charOffset, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnFilters(column));
}

class $$BookmarkRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarkRowsTable> {
  $$BookmarkRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saintId => $composableBuilder(
      column: $table.saintId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paragraphId => $composableBuilder(
      column: $table.paragraphId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get charOffset => $composableBuilder(
      column: $table.charOffset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnOrderings(column));
}

class $$BookmarkRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarkRowsTable> {
  $$BookmarkRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saintId =>
      $composableBuilder(column: $table.saintId, builder: (column) => column);

  GeneratedColumn<String> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get paragraphId => $composableBuilder(
      column: $table.paragraphId, builder: (column) => column);

  GeneratedColumn<int> get charOffset => $composableBuilder(
      column: $table.charOffset, builder: (column) => column);

  GeneratedColumn<int> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => column);
}

class $$BookmarkRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarkRowsTable,
    BookmarkRow,
    $$BookmarkRowsTableFilterComposer,
    $$BookmarkRowsTableOrderingComposer,
    $$BookmarkRowsTableAnnotationComposer,
    $$BookmarkRowsTableCreateCompanionBuilder,
    $$BookmarkRowsTableUpdateCompanionBuilder,
    (
      BookmarkRow,
      BaseReferences<_$AppDatabase, $BookmarkRowsTable, BookmarkRow>
    ),
    BookmarkRow,
    PrefetchHooks Function()> {
  $$BookmarkRowsTableTableManager(_$AppDatabase db, $BookmarkRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarkRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarkRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> saintId = const Value.absent(),
            Value<String> sectionId = const Value.absent(),
            Value<String> paragraphId = const Value.absent(),
            Value<int> charOffset = const Value.absent(),
            Value<int> contentVersion = const Value.absent(),
            Value<int> createdAtMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarkRowsCompanion(
            id: id,
            saintId: saintId,
            sectionId: sectionId,
            paragraphId: paragraphId,
            charOffset: charOffset,
            contentVersion: contentVersion,
            createdAtMs: createdAtMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String saintId,
            required String sectionId,
            required String paragraphId,
            Value<int> charOffset = const Value.absent(),
            required int contentVersion,
            required int createdAtMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarkRowsCompanion.insert(
            id: id,
            saintId: saintId,
            sectionId: sectionId,
            paragraphId: paragraphId,
            charOffset: charOffset,
            contentVersion: contentVersion,
            createdAtMs: createdAtMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookmarkRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarkRowsTable,
    BookmarkRow,
    $$BookmarkRowsTableFilterComposer,
    $$BookmarkRowsTableOrderingComposer,
    $$BookmarkRowsTableAnnotationComposer,
    $$BookmarkRowsTableCreateCompanionBuilder,
    $$BookmarkRowsTableUpdateCompanionBuilder,
    (
      BookmarkRow,
      BaseReferences<_$AppDatabase, $BookmarkRowsTable, BookmarkRow>
    ),
    BookmarkRow,
    PrefetchHooks Function()>;
typedef $$ProgressRowsTableCreateCompanionBuilder = ProgressRowsCompanion
    Function({
  required String sectionId,
  required String saintId,
  required String paragraphId,
  Value<int> charOffset,
  required int contentVersion,
  required int updatedAtMs,
  Value<int> rowid,
});
typedef $$ProgressRowsTableUpdateCompanionBuilder = ProgressRowsCompanion
    Function({
  Value<String> sectionId,
  Value<String> saintId,
  Value<String> paragraphId,
  Value<int> charOffset,
  Value<int> contentVersion,
  Value<int> updatedAtMs,
  Value<int> rowid,
});

class $$ProgressRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressRowsTable> {
  $$ProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saintId => $composableBuilder(
      column: $table.saintId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paragraphId => $composableBuilder(
      column: $table.paragraphId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get charOffset => $composableBuilder(
      column: $table.charOffset, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
      column: $table.updatedAtMs, builder: (column) => ColumnFilters(column));
}

class $$ProgressRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressRowsTable> {
  $$ProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saintId => $composableBuilder(
      column: $table.saintId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paragraphId => $composableBuilder(
      column: $table.paragraphId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get charOffset => $composableBuilder(
      column: $table.charOffset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
      column: $table.updatedAtMs, builder: (column) => ColumnOrderings(column));
}

class $$ProgressRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressRowsTable> {
  $$ProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get saintId =>
      $composableBuilder(column: $table.saintId, builder: (column) => column);

  GeneratedColumn<String> get paragraphId => $composableBuilder(
      column: $table.paragraphId, builder: (column) => column);

  GeneratedColumn<int> get charOffset => $composableBuilder(
      column: $table.charOffset, builder: (column) => column);

  GeneratedColumn<int> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
      column: $table.updatedAtMs, builder: (column) => column);
}

class $$ProgressRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgressRowsTable,
    ProgressRow,
    $$ProgressRowsTableFilterComposer,
    $$ProgressRowsTableOrderingComposer,
    $$ProgressRowsTableAnnotationComposer,
    $$ProgressRowsTableCreateCompanionBuilder,
    $$ProgressRowsTableUpdateCompanionBuilder,
    (
      ProgressRow,
      BaseReferences<_$AppDatabase, $ProgressRowsTable, ProgressRow>
    ),
    ProgressRow,
    PrefetchHooks Function()> {
  $$ProgressRowsTableTableManager(_$AppDatabase db, $ProgressRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sectionId = const Value.absent(),
            Value<String> saintId = const Value.absent(),
            Value<String> paragraphId = const Value.absent(),
            Value<int> charOffset = const Value.absent(),
            Value<int> contentVersion = const Value.absent(),
            Value<int> updatedAtMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressRowsCompanion(
            sectionId: sectionId,
            saintId: saintId,
            paragraphId: paragraphId,
            charOffset: charOffset,
            contentVersion: contentVersion,
            updatedAtMs: updatedAtMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sectionId,
            required String saintId,
            required String paragraphId,
            Value<int> charOffset = const Value.absent(),
            required int contentVersion,
            required int updatedAtMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressRowsCompanion.insert(
            sectionId: sectionId,
            saintId: saintId,
            paragraphId: paragraphId,
            charOffset: charOffset,
            contentVersion: contentVersion,
            updatedAtMs: updatedAtMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProgressRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProgressRowsTable,
    ProgressRow,
    $$ProgressRowsTableFilterComposer,
    $$ProgressRowsTableOrderingComposer,
    $$ProgressRowsTableAnnotationComposer,
    $$ProgressRowsTableCreateCompanionBuilder,
    $$ProgressRowsTableUpdateCompanionBuilder,
    (
      ProgressRow,
      BaseReferences<_$AppDatabase, $ProgressRowsTable, ProgressRow>
    ),
    ProgressRow,
    PrefetchHooks Function()>;
typedef $$SettingRowsTableCreateCompanionBuilder = SettingRowsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingRowsTableUpdateCompanionBuilder = SettingRowsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingRowsTable,
    SettingRow,
    $$SettingRowsTableFilterComposer,
    $$SettingRowsTableOrderingComposer,
    $$SettingRowsTableAnnotationComposer,
    $$SettingRowsTableCreateCompanionBuilder,
    $$SettingRowsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingRowsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingRowsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingRowsTable,
    SettingRow,
    $$SettingRowsTableFilterComposer,
    $$SettingRowsTableOrderingComposer,
    $$SettingRowsTableAnnotationComposer,
    $$SettingRowsTableCreateCompanionBuilder,
    $$SettingRowsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BookmarkRowsTableTableManager get bookmarkRows =>
      $$BookmarkRowsTableTableManager(_db, _db.bookmarkRows);
  $$ProgressRowsTableTableManager get progressRows =>
      $$ProgressRowsTableTableManager(_db, _db.progressRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
}
