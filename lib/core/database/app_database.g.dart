// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TaskRowsTable extends TaskRows with TableInfo<$TaskRowsTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtUtcMeta = const VerificationMeta(
    'completedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> completedAtUtc =
      GeneratedColumn<DateTime>(
        'completed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    priority,
    isDone,
    sortOrder,
    createdAtUtc,
    updatedAtUtc,
    completedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('completed_at_utc')) {
      context.handle(
        _completedAtUtcMeta,
        completedAtUtc.isAcceptableOrUnknown(
          data['completed_at_utc']!,
          _completedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      completedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at_utc'],
      ),
    );
  }

  @override
  $TaskRowsTable createAlias(String alias) {
    return $TaskRowsTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final String title;
  final int priority;
  final bool isDone;
  final int sortOrder;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? completedAtUtc;
  const TaskRow({
    required this.id,
    required this.title,
    required this.priority,
    required this.isDone,
    required this.sortOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.completedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['priority'] = Variable<int>(priority);
    map['is_done'] = Variable<bool>(isDone);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || completedAtUtc != null) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc);
    }
    return map;
  }

  TaskRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskRowsCompanion(
      id: Value(id),
      title: Value(title),
      priority: Value(priority),
      isDone: Value(isDone),
      sortOrder: Value(sortOrder),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      completedAtUtc: completedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtc),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      priority: serializer.fromJson<int>(json['priority']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      completedAtUtc: serializer.fromJson<DateTime?>(json['completedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'priority': serializer.toJson<int>(priority),
      'isDone': serializer.toJson<bool>(isDone),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'completedAtUtc': serializer.toJson<DateTime?>(completedAtUtc),
    };
  }

  TaskRow copyWith({
    String? id,
    String? title,
    int? priority,
    bool? isDone,
    int? sortOrder,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> completedAtUtc = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    priority: priority ?? this.priority,
    isDone: isDone ?? this.isDone,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    completedAtUtc: completedAtUtc.present
        ? completedAtUtc.value
        : this.completedAtUtc,
  );
  TaskRow copyWithCompanion(TaskRowsCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      priority: data.priority.present ? data.priority.value : this.priority,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      completedAtUtc: data.completedAtUtc.present
          ? data.completedAtUtc.value
          : this.completedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('priority: $priority, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('completedAtUtc: $completedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    priority,
    isDone,
    sortOrder,
    createdAtUtc,
    updatedAtUtc,
    completedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.priority == this.priority &&
          other.isDone == this.isDone &&
          other.sortOrder == this.sortOrder &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.completedAtUtc == this.completedAtUtc);
}

class TaskRowsCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> priority;
  final Value<bool> isDone;
  final Value<int> sortOrder;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> completedAtUtc;
  final Value<int> rowid;
  const TaskRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.priority = const Value.absent(),
    this.isDone = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRowsCompanion.insert({
    required String id,
    required String title,
    required int priority,
    this.isDone = const Value.absent(),
    required int sortOrder,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.completedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       priority = Value(priority),
       sortOrder = Value(sortOrder),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? priority,
    Expression<bool>? isDone,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? completedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (priority != null) 'priority': priority,
      if (isDone != null) 'is_done': isDone,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (completedAtUtc != null) 'completed_at_utc': completedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? priority,
    Value<bool>? isDone,
    Value<int>? sortOrder,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? completedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (completedAtUtc.present) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('priority: $priority, ')
          ..write('isDone: $isDone, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceTransactionRowsTable extends FinanceTransactionRows
    with TableInfo<$FinanceTransactionRowsTable, FinanceTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceTransactionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IRT'),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    category,
    amountMinorUnits,
    currencyCode,
    scale,
    occurredAtUtc,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $FinanceTransactionRowsTable createAlias(String alias) {
    return $FinanceTransactionRowsTable(attachedDatabase, alias);
  }
}

class FinanceTransactionRow extends DataClass
    implements Insertable<FinanceTransactionRow> {
  final String id;
  final String type;
  final String title;
  final String category;
  final int amountMinorUnits;
  final String currencyCode;
  final int scale;
  final DateTime occurredAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const FinanceTransactionRow({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.scale,
    required this.occurredAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['scale'] = Variable<int>(scale);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  FinanceTransactionRowsCompanion toCompanion(bool nullToAbsent) {
    return FinanceTransactionRowsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      category: Value(category),
      amountMinorUnits: Value(amountMinorUnits),
      currencyCode: Value(currencyCode),
      scale: Value(scale),
      occurredAtUtc: Value(occurredAtUtc),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory FinanceTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      scale: serializer.fromJson<int>(json['scale']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'scale': serializer.toJson<int>(scale),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  FinanceTransactionRow copyWith({
    String? id,
    String? type,
    String? title,
    String? category,
    int? amountMinorUnits,
    String? currencyCode,
    int? scale,
    DateTime? occurredAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => FinanceTransactionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    category: category ?? this.category,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    scale: scale ?? this.scale,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  FinanceTransactionRow copyWithCompanion(
    FinanceTransactionRowsCompanion data,
  ) {
    return FinanceTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      scale: data.scale.present ? data.scale.value : this.scale,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    category,
    amountMinorUnits,
    currencyCode,
    scale,
    occurredAtUtc,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceTransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.category == this.category &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.scale == this.scale &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class FinanceTransactionRowsCompanion
    extends UpdateCompanion<FinanceTransactionRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> category;
  final Value<int> amountMinorUnits;
  final Value<String> currencyCode;
  final Value<int> scale;
  final Value<DateTime> occurredAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const FinanceTransactionRowsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceTransactionRowsCompanion.insert({
    required String id,
    required String type,
    required String title,
    required String category,
    required int amountMinorUnits,
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    required DateTime occurredAtUtc,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       category = Value(category),
       amountMinorUnits = Value(amountMinorUnits),
       occurredAtUtc = Value(occurredAtUtc),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<FinanceTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? category,
    Expression<int>? amountMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? scale,
    Expression<DateTime>? occurredAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (scale != null) 'scale': scale,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceTransactionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? category,
    Value<int>? amountMinorUnits,
    Value<String>? currencyCode,
    Value<int>? scale,
    Value<DateTime>? occurredAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return FinanceTransactionRowsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTransactionRowsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtRowsTable extends DebtRows with TableInfo<$DebtRowsTable, DebtRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMinorUnitsMeta = const VerificationMeta(
    'totalMinorUnits',
  );
  @override
  late final GeneratedColumn<int> totalMinorUnits = GeneratedColumn<int>(
    'total_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IRT'),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtUtcMeta = const VerificationMeta(
    'archivedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAtUtc =
      GeneratedColumn<DateTime>(
        'archived_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    totalMinorUnits,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('total_minor_units')) {
      context.handle(
        _totalMinorUnitsMeta,
        totalMinorUnits.isAcceptableOrUnknown(
          data['total_minor_units']!,
          _totalMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('archived_at_utc')) {
      context.handle(
        _archivedAtUtcMeta,
        archivedAtUtc.isAcceptableOrUnknown(
          data['archived_at_utc']!,
          _archivedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      totalMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      archivedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at_utc'],
      ),
    );
  }

  @override
  $DebtRowsTable createAlias(String alias) {
    return $DebtRowsTable(attachedDatabase, alias);
  }
}

class DebtRow extends DataClass implements Insertable<DebtRow> {
  final String id;
  final String title;
  final int totalMinorUnits;
  final String currencyCode;
  final int scale;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? archivedAtUtc;
  const DebtRow({
    required this.id,
    required this.title,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.scale,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.archivedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['total_minor_units'] = Variable<int>(totalMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['scale'] = Variable<int>(scale);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || archivedAtUtc != null) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc);
    }
    return map;
  }

  DebtRowsCompanion toCompanion(bool nullToAbsent) {
    return DebtRowsCompanion(
      id: Value(id),
      title: Value(title),
      totalMinorUnits: Value(totalMinorUnits),
      currencyCode: Value(currencyCode),
      scale: Value(scale),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      archivedAtUtc: archivedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAtUtc),
    );
  }

  factory DebtRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      totalMinorUnits: serializer.fromJson<int>(json['totalMinorUnits']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      scale: serializer.fromJson<int>(json['scale']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      archivedAtUtc: serializer.fromJson<DateTime?>(json['archivedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'totalMinorUnits': serializer.toJson<int>(totalMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'scale': serializer.toJson<int>(scale),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'archivedAtUtc': serializer.toJson<DateTime?>(archivedAtUtc),
    };
  }

  DebtRow copyWith({
    String? id,
    String? title,
    int? totalMinorUnits,
    String? currencyCode,
    int? scale,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> archivedAtUtc = const Value.absent(),
  }) => DebtRow(
    id: id ?? this.id,
    title: title ?? this.title,
    totalMinorUnits: totalMinorUnits ?? this.totalMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    scale: scale ?? this.scale,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    archivedAtUtc: archivedAtUtc.present
        ? archivedAtUtc.value
        : this.archivedAtUtc,
  );
  DebtRow copyWithCompanion(DebtRowsCompanion data) {
    return DebtRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      totalMinorUnits: data.totalMinorUnits.present
          ? data.totalMinorUnits.value
          : this.totalMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      scale: data.scale.present ? data.scale.value : this.scale,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      archivedAtUtc: data.archivedAtUtc.present
          ? data.archivedAtUtc.value
          : this.archivedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('totalMinorUnits: $totalMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    totalMinorUnits,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.totalMinorUnits == this.totalMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.scale == this.scale &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.archivedAtUtc == this.archivedAtUtc);
}

class DebtRowsCompanion extends UpdateCompanion<DebtRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> totalMinorUnits;
  final Value<String> currencyCode;
  final Value<int> scale;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> archivedAtUtc;
  final Value<int> rowid;
  const DebtRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.totalMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtRowsCompanion.insert({
    required String id,
    required String title,
    required int totalMinorUnits,
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       totalMinorUnits = Value(totalMinorUnits),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<DebtRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? totalMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? scale,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? archivedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (totalMinorUnits != null) 'total_minor_units': totalMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (scale != null) 'scale': scale,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (archivedAtUtc != null) 'archived_at_utc': archivedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? totalMinorUnits,
    Value<String>? currencyCode,
    Value<int>? scale,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? archivedAtUtc,
    Value<int>? rowid,
  }) {
    return DebtRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      totalMinorUnits: totalMinorUnits ?? this.totalMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      archivedAtUtc: archivedAtUtc ?? this.archivedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (totalMinorUnits.present) {
      map['total_minor_units'] = Variable<int>(totalMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (archivedAtUtc.present) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('totalMinorUnits: $totalMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtPaymentRowsTable extends DebtPaymentRows
    with TableInfo<$DebtPaymentRowsTable, DebtPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtPaymentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES debts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtUtcMeta = const VerificationMeta(
    'paidAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> paidAtUtc = GeneratedColumn<DateTime>(
    'paid_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    debtId,
    amountMinorUnits,
    paidAtUtc,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('paid_at_utc')) {
      context.handle(
        _paidAtUtcMeta,
        paidAtUtc.isAcceptableOrUnknown(data['paid_at_utc']!, _paidAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      paidAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $DebtPaymentRowsTable createAlias(String alias) {
    return $DebtPaymentRowsTable(attachedDatabase, alias);
  }
}

class DebtPaymentRow extends DataClass implements Insertable<DebtPaymentRow> {
  final String id;
  final String debtId;
  final int amountMinorUnits;
  final DateTime paidAtUtc;
  final DateTime createdAtUtc;
  const DebtPaymentRow({
    required this.id,
    required this.debtId,
    required this.amountMinorUnits,
    required this.paidAtUtc,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debt_id'] = Variable<String>(debtId);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['paid_at_utc'] = Variable<DateTime>(paidAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  DebtPaymentRowsCompanion toCompanion(bool nullToAbsent) {
    return DebtPaymentRowsCompanion(
      id: Value(id),
      debtId: Value(debtId),
      amountMinorUnits: Value(amountMinorUnits),
      paidAtUtc: Value(paidAtUtc),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory DebtPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      debtId: serializer.fromJson<String>(json['debtId']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      paidAtUtc: serializer.fromJson<DateTime>(json['paidAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debtId': serializer.toJson<String>(debtId),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'paidAtUtc': serializer.toJson<DateTime>(paidAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  DebtPaymentRow copyWith({
    String? id,
    String? debtId,
    int? amountMinorUnits,
    DateTime? paidAtUtc,
    DateTime? createdAtUtc,
  }) => DebtPaymentRow(
    id: id ?? this.id,
    debtId: debtId ?? this.debtId,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    paidAtUtc: paidAtUtc ?? this.paidAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  DebtPaymentRow copyWithCompanion(DebtPaymentRowsCompanion data) {
    return DebtPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      paidAtUtc: data.paidAtUtc.present ? data.paidAtUtc.value : this.paidAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentRow(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, debtId, amountMinorUnits, paidAtUtc, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtPaymentRow &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.paidAtUtc == this.paidAtUtc &&
          other.createdAtUtc == this.createdAtUtc);
}

class DebtPaymentRowsCompanion extends UpdateCompanion<DebtPaymentRow> {
  final Value<String> id;
  final Value<String> debtId;
  final Value<int> amountMinorUnits;
  final Value<DateTime> paidAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const DebtPaymentRowsCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.paidAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtPaymentRowsCompanion.insert({
    required String id,
    required String debtId,
    required int amountMinorUnits,
    required DateTime paidAtUtc,
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       debtId = Value(debtId),
       amountMinorUnits = Value(amountMinorUnits),
       paidAtUtc = Value(paidAtUtc),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<DebtPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? debtId,
    Expression<int>? amountMinorUnits,
    Expression<DateTime>? paidAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debt_id': debtId,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (paidAtUtc != null) 'paid_at_utc': paidAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtPaymentRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? debtId,
    Value<int>? amountMinorUnits,
    Value<DateTime>? paidAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return DebtPaymentRowsCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      paidAtUtc: paidAtUtc ?? this.paidAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (paidAtUtc.present) {
      map['paid_at_utc'] = Variable<DateTime>(paidAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentRowsCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallmentPlanRowsTable extends InstallmentPlanRows
    with TableInfo<$InstallmentPlanRowsTable, InstallmentPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentPlanRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perInstallmentMinorUnitsMeta =
      const VerificationMeta('perInstallmentMinorUnits');
  @override
  late final GeneratedColumn<int> perInstallmentMinorUnits =
      GeneratedColumn<int>(
        'per_installment_minor_units',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _installmentCountMeta = const VerificationMeta(
    'installmentCount',
  );
  @override
  late final GeneratedColumn<int> installmentCount = GeneratedColumn<int>(
    'installment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IRT'),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtUtcMeta = const VerificationMeta(
    'archivedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAtUtc =
      GeneratedColumn<DateTime>(
        'archived_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    perInstallmentMinorUnits,
    installmentCount,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('per_installment_minor_units')) {
      context.handle(
        _perInstallmentMinorUnitsMeta,
        perInstallmentMinorUnits.isAcceptableOrUnknown(
          data['per_installment_minor_units']!,
          _perInstallmentMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perInstallmentMinorUnitsMeta);
    }
    if (data.containsKey('installment_count')) {
      context.handle(
        _installmentCountMeta,
        installmentCount.isAcceptableOrUnknown(
          data['installment_count']!,
          _installmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentCountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('archived_at_utc')) {
      context.handle(
        _archivedAtUtcMeta,
        archivedAtUtc.isAcceptableOrUnknown(
          data['archived_at_utc']!,
          _archivedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallmentPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      perInstallmentMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}per_installment_minor_units'],
      )!,
      installmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_count'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      archivedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at_utc'],
      ),
    );
  }

  @override
  $InstallmentPlanRowsTable createAlias(String alias) {
    return $InstallmentPlanRowsTable(attachedDatabase, alias);
  }
}

class InstallmentPlanRow extends DataClass
    implements Insertable<InstallmentPlanRow> {
  final String id;
  final String title;
  final int perInstallmentMinorUnits;
  final int installmentCount;
  final String currencyCode;
  final int scale;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? archivedAtUtc;
  const InstallmentPlanRow({
    required this.id,
    required this.title,
    required this.perInstallmentMinorUnits,
    required this.installmentCount,
    required this.currencyCode,
    required this.scale,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.archivedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['per_installment_minor_units'] = Variable<int>(
      perInstallmentMinorUnits,
    );
    map['installment_count'] = Variable<int>(installmentCount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['scale'] = Variable<int>(scale);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || archivedAtUtc != null) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc);
    }
    return map;
  }

  InstallmentPlanRowsCompanion toCompanion(bool nullToAbsent) {
    return InstallmentPlanRowsCompanion(
      id: Value(id),
      title: Value(title),
      perInstallmentMinorUnits: Value(perInstallmentMinorUnits),
      installmentCount: Value(installmentCount),
      currencyCode: Value(currencyCode),
      scale: Value(scale),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      archivedAtUtc: archivedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAtUtc),
    );
  }

  factory InstallmentPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentPlanRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      perInstallmentMinorUnits: serializer.fromJson<int>(
        json['perInstallmentMinorUnits'],
      ),
      installmentCount: serializer.fromJson<int>(json['installmentCount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      scale: serializer.fromJson<int>(json['scale']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      archivedAtUtc: serializer.fromJson<DateTime?>(json['archivedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'perInstallmentMinorUnits': serializer.toJson<int>(
        perInstallmentMinorUnits,
      ),
      'installmentCount': serializer.toJson<int>(installmentCount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'scale': serializer.toJson<int>(scale),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'archivedAtUtc': serializer.toJson<DateTime?>(archivedAtUtc),
    };
  }

  InstallmentPlanRow copyWith({
    String? id,
    String? title,
    int? perInstallmentMinorUnits,
    int? installmentCount,
    String? currencyCode,
    int? scale,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> archivedAtUtc = const Value.absent(),
  }) => InstallmentPlanRow(
    id: id ?? this.id,
    title: title ?? this.title,
    perInstallmentMinorUnits:
        perInstallmentMinorUnits ?? this.perInstallmentMinorUnits,
    installmentCount: installmentCount ?? this.installmentCount,
    currencyCode: currencyCode ?? this.currencyCode,
    scale: scale ?? this.scale,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    archivedAtUtc: archivedAtUtc.present
        ? archivedAtUtc.value
        : this.archivedAtUtc,
  );
  InstallmentPlanRow copyWithCompanion(InstallmentPlanRowsCompanion data) {
    return InstallmentPlanRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      perInstallmentMinorUnits: data.perInstallmentMinorUnits.present
          ? data.perInstallmentMinorUnits.value
          : this.perInstallmentMinorUnits,
      installmentCount: data.installmentCount.present
          ? data.installmentCount.value
          : this.installmentCount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      scale: data.scale.present ? data.scale.value : this.scale,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      archivedAtUtc: data.archivedAtUtc.present
          ? data.archivedAtUtc.value
          : this.archivedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlanRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('perInstallmentMinorUnits: $perInstallmentMinorUnits, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    perInstallmentMinorUnits,
    installmentCount,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentPlanRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.perInstallmentMinorUnits == this.perInstallmentMinorUnits &&
          other.installmentCount == this.installmentCount &&
          other.currencyCode == this.currencyCode &&
          other.scale == this.scale &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.archivedAtUtc == this.archivedAtUtc);
}

class InstallmentPlanRowsCompanion extends UpdateCompanion<InstallmentPlanRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> perInstallmentMinorUnits;
  final Value<int> installmentCount;
  final Value<String> currencyCode;
  final Value<int> scale;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> archivedAtUtc;
  final Value<int> rowid;
  const InstallmentPlanRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.perInstallmentMinorUnits = const Value.absent(),
    this.installmentCount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallmentPlanRowsCompanion.insert({
    required String id,
    required String title,
    required int perInstallmentMinorUnits,
    required int installmentCount,
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       perInstallmentMinorUnits = Value(perInstallmentMinorUnits),
       installmentCount = Value(installmentCount),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<InstallmentPlanRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? perInstallmentMinorUnits,
    Expression<int>? installmentCount,
    Expression<String>? currencyCode,
    Expression<int>? scale,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? archivedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (perInstallmentMinorUnits != null)
        'per_installment_minor_units': perInstallmentMinorUnits,
      if (installmentCount != null) 'installment_count': installmentCount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (scale != null) 'scale': scale,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (archivedAtUtc != null) 'archived_at_utc': archivedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallmentPlanRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? perInstallmentMinorUnits,
    Value<int>? installmentCount,
    Value<String>? currencyCode,
    Value<int>? scale,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? archivedAtUtc,
    Value<int>? rowid,
  }) {
    return InstallmentPlanRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      perInstallmentMinorUnits:
          perInstallmentMinorUnits ?? this.perInstallmentMinorUnits,
      installmentCount: installmentCount ?? this.installmentCount,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      archivedAtUtc: archivedAtUtc ?? this.archivedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (perInstallmentMinorUnits.present) {
      map['per_installment_minor_units'] = Variable<int>(
        perInstallmentMinorUnits.value,
      );
    }
    if (installmentCount.present) {
      map['installment_count'] = Variable<int>(installmentCount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (archivedAtUtc.present) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlanRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('perInstallmentMinorUnits: $perInstallmentMinorUnits, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallmentPaymentRowsTable extends InstallmentPaymentRows
    with TableInfo<$InstallmentPaymentRowsTable, InstallmentPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentPaymentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES installment_plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _installmentNumberMeta = const VerificationMeta(
    'installmentNumber',
  );
  @override
  late final GeneratedColumn<int> installmentNumber = GeneratedColumn<int>(
    'installment_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtUtcMeta = const VerificationMeta(
    'paidAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> paidAtUtc = GeneratedColumn<DateTime>(
    'paid_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    installmentNumber,
    amountMinorUnits,
    paidAtUtc,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('installment_number')) {
      context.handle(
        _installmentNumberMeta,
        installmentNumber.isAcceptableOrUnknown(
          data['installment_number']!,
          _installmentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentNumberMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('paid_at_utc')) {
      context.handle(
        _paidAtUtcMeta,
        paidAtUtc.isAcceptableOrUnknown(data['paid_at_utc']!, _paidAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {planId, installmentNumber},
  ];
  @override
  InstallmentPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      installmentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_number'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      paidAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $InstallmentPaymentRowsTable createAlias(String alias) {
    return $InstallmentPaymentRowsTable(attachedDatabase, alias);
  }
}

class InstallmentPaymentRow extends DataClass
    implements Insertable<InstallmentPaymentRow> {
  final String id;
  final String planId;
  final int installmentNumber;
  final int amountMinorUnits;
  final DateTime paidAtUtc;
  final DateTime createdAtUtc;
  const InstallmentPaymentRow({
    required this.id,
    required this.planId,
    required this.installmentNumber,
    required this.amountMinorUnits,
    required this.paidAtUtc,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['installment_number'] = Variable<int>(installmentNumber);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['paid_at_utc'] = Variable<DateTime>(paidAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  InstallmentPaymentRowsCompanion toCompanion(bool nullToAbsent) {
    return InstallmentPaymentRowsCompanion(
      id: Value(id),
      planId: Value(planId),
      installmentNumber: Value(installmentNumber),
      amountMinorUnits: Value(amountMinorUnits),
      paidAtUtc: Value(paidAtUtc),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory InstallmentPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      installmentNumber: serializer.fromJson<int>(json['installmentNumber']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      paidAtUtc: serializer.fromJson<DateTime>(json['paidAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'installmentNumber': serializer.toJson<int>(installmentNumber),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'paidAtUtc': serializer.toJson<DateTime>(paidAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  InstallmentPaymentRow copyWith({
    String? id,
    String? planId,
    int? installmentNumber,
    int? amountMinorUnits,
    DateTime? paidAtUtc,
    DateTime? createdAtUtc,
  }) => InstallmentPaymentRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    installmentNumber: installmentNumber ?? this.installmentNumber,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    paidAtUtc: paidAtUtc ?? this.paidAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  InstallmentPaymentRow copyWithCompanion(
    InstallmentPaymentRowsCompanion data,
  ) {
    return InstallmentPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      installmentNumber: data.installmentNumber.present
          ? data.installmentNumber.value
          : this.installmentNumber,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      paidAtUtc: data.paidAtUtc.present ? data.paidAtUtc.value : this.paidAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPaymentRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('installmentNumber: $installmentNumber, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    installmentNumber,
    amountMinorUnits,
    paidAtUtc,
    createdAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentPaymentRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.installmentNumber == this.installmentNumber &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.paidAtUtc == this.paidAtUtc &&
          other.createdAtUtc == this.createdAtUtc);
}

class InstallmentPaymentRowsCompanion
    extends UpdateCompanion<InstallmentPaymentRow> {
  final Value<String> id;
  final Value<String> planId;
  final Value<int> installmentNumber;
  final Value<int> amountMinorUnits;
  final Value<DateTime> paidAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const InstallmentPaymentRowsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.installmentNumber = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.paidAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallmentPaymentRowsCompanion.insert({
    required String id,
    required String planId,
    required int installmentNumber,
    required int amountMinorUnits,
    required DateTime paidAtUtc,
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       installmentNumber = Value(installmentNumber),
       amountMinorUnits = Value(amountMinorUnits),
       paidAtUtc = Value(paidAtUtc),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<InstallmentPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? installmentNumber,
    Expression<int>? amountMinorUnits,
    Expression<DateTime>? paidAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (installmentNumber != null) 'installment_number': installmentNumber,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (paidAtUtc != null) 'paid_at_utc': paidAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallmentPaymentRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<int>? installmentNumber,
    Value<int>? amountMinorUnits,
    Value<DateTime>? paidAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return InstallmentPaymentRowsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      paidAtUtc: paidAtUtc ?? this.paidAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (installmentNumber.present) {
      map['installment_number'] = Variable<int>(installmentNumber.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (paidAtUtc.present) {
      map['paid_at_utc'] = Variable<DateTime>(paidAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPaymentRowsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('installmentNumber: $installmentNumber, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationScheduleRowsTable extends NotificationScheduleRows
    with TableInfo<$NotificationScheduleRowsTable, NotificationScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationScheduleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerTypeMeta = const VerificationMeta(
    'ownerType',
  );
  @override
  late final GeneratedColumn<String> ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtUtcMeta = const VerificationMeta(
    'scheduledAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAtUtc =
      GeneratedColumn<DateTime>(
        'scheduled_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _privacyModeMeta = const VerificationMeta(
    'privacyMode',
  );
  @override
  late final GeneratedColumn<String> privacyMode = GeneratedColumn<String>(
    'privacy_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('full'),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    ownerType,
    ownerId,
    title,
    body,
    scheduledAtUtc,
    payloadJson,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('owner_type')) {
      context.handle(
        _ownerTypeMeta,
        ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('scheduled_at_utc')) {
      context.handle(
        _scheduledAtUtcMeta,
        scheduledAtUtc.isAcceptableOrUnknown(
          data['scheduled_at_utc']!,
          _scheduledAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtUtcMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('privacy_mode')) {
      context.handle(
        _privacyModeMeta,
        privacyMode.isAcceptableOrUnknown(
          data['privacy_mode']!,
          _privacyModeMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId};
  @override
  NotificationScheduleRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationScheduleRow(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      ownerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_type'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      scheduledAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at_utc'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      privacyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy_mode'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $NotificationScheduleRowsTable createAlias(String alias) {
    return $NotificationScheduleRowsTable(attachedDatabase, alias);
  }
}

class NotificationScheduleRow extends DataClass
    implements Insertable<NotificationScheduleRow> {
  final String scheduleId;
  final String ownerType;
  final String ownerId;
  final String title;
  final String body;
  final DateTime scheduledAtUtc;
  final String payloadJson;
  final String privacyMode;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const NotificationScheduleRow({
    required this.scheduleId,
    required this.ownerType,
    required this.ownerId,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
    required this.payloadJson,
    required this.privacyMode,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['owner_type'] = Variable<String>(ownerType);
    map['owner_id'] = Variable<String>(ownerId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc);
    map['payload_json'] = Variable<String>(payloadJson);
    map['privacy_mode'] = Variable<String>(privacyMode);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  NotificationScheduleRowsCompanion toCompanion(bool nullToAbsent) {
    return NotificationScheduleRowsCompanion(
      scheduleId: Value(scheduleId),
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      title: Value(title),
      body: Value(body),
      scheduledAtUtc: Value(scheduledAtUtc),
      payloadJson: Value(payloadJson),
      privacyMode: Value(privacyMode),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory NotificationScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationScheduleRow(
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      ownerType: serializer.fromJson<String>(json['ownerType']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      scheduledAtUtc: serializer.fromJson<DateTime>(json['scheduledAtUtc']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      privacyMode: serializer.fromJson<String>(json['privacyMode']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleId': serializer.toJson<String>(scheduleId),
      'ownerType': serializer.toJson<String>(ownerType),
      'ownerId': serializer.toJson<String>(ownerId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'scheduledAtUtc': serializer.toJson<DateTime>(scheduledAtUtc),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'privacyMode': serializer.toJson<String>(privacyMode),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  NotificationScheduleRow copyWith({
    String? scheduleId,
    String? ownerType,
    String? ownerId,
    String? title,
    String? body,
    DateTime? scheduledAtUtc,
    String? payloadJson,
    String? privacyMode,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => NotificationScheduleRow(
    scheduleId: scheduleId ?? this.scheduleId,
    ownerType: ownerType ?? this.ownerType,
    ownerId: ownerId ?? this.ownerId,
    title: title ?? this.title,
    body: body ?? this.body,
    scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
    payloadJson: payloadJson ?? this.payloadJson,
    privacyMode: privacyMode ?? this.privacyMode,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  NotificationScheduleRow copyWithCompanion(
    NotificationScheduleRowsCompanion data,
  ) {
    return NotificationScheduleRow(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      scheduledAtUtc: data.scheduledAtUtc.present
          ? data.scheduledAtUtc.value
          : this.scheduledAtUtc,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      privacyMode: data.privacyMode.present
          ? data.privacyMode.value
          : this.privacyMode,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationScheduleRow(')
          ..write('scheduleId: $scheduleId, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    ownerType,
    ownerId,
    title,
    body,
    scheduledAtUtc,
    payloadJson,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationScheduleRow &&
          other.scheduleId == this.scheduleId &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.title == this.title &&
          other.body == this.body &&
          other.scheduledAtUtc == this.scheduledAtUtc &&
          other.payloadJson == this.payloadJson &&
          other.privacyMode == this.privacyMode &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class NotificationScheduleRowsCompanion
    extends UpdateCompanion<NotificationScheduleRow> {
  final Value<String> scheduleId;
  final Value<String> ownerType;
  final Value<String> ownerId;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> scheduledAtUtc;
  final Value<String> payloadJson;
  final Value<String> privacyMode;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const NotificationScheduleRowsCompanion({
    this.scheduleId = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.scheduledAtUtc = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.privacyMode = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationScheduleRowsCompanion.insert({
    required String scheduleId,
    required String ownerType,
    required String ownerId,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    this.payloadJson = const Value.absent(),
    this.privacyMode = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       ownerType = Value(ownerType),
       ownerId = Value(ownerId),
       title = Value(title),
       body = Value(body),
       scheduledAtUtc = Value(scheduledAtUtc),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<NotificationScheduleRow> custom({
    Expression<String>? scheduleId,
    Expression<String>? ownerType,
    Expression<String>? ownerId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? scheduledAtUtc,
    Expression<String>? payloadJson,
    Expression<String>? privacyMode,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (scheduledAtUtc != null) 'scheduled_at_utc': scheduledAtUtc,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (privacyMode != null) 'privacy_mode': privacyMode,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationScheduleRowsCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? ownerType,
    Value<String>? ownerId,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? scheduledAtUtc,
    Value<String>? payloadJson,
    Value<String>? privacyMode,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return NotificationScheduleRowsCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      payloadJson: payloadJson ?? this.payloadJson,
      privacyMode: privacyMode ?? this.privacyMode,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(ownerType.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (scheduledAtUtc.present) {
      map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (privacyMode.present) {
      map['privacy_mode'] = Variable<String>(privacyMode.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationScheduleRowsCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskRowsTable taskRows = $TaskRowsTable(this);
  late final $FinanceTransactionRowsTable financeTransactionRows =
      $FinanceTransactionRowsTable(this);
  late final $DebtRowsTable debtRows = $DebtRowsTable(this);
  late final $DebtPaymentRowsTable debtPaymentRows = $DebtPaymentRowsTable(
    this,
  );
  late final $InstallmentPlanRowsTable installmentPlanRows =
      $InstallmentPlanRowsTable(this);
  late final $InstallmentPaymentRowsTable installmentPaymentRows =
      $InstallmentPaymentRowsTable(this);
  late final $NotificationScheduleRowsTable notificationScheduleRows =
      $NotificationScheduleRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskRows,
    financeTransactionRows,
    debtRows,
    debtPaymentRows,
    installmentPlanRows,
    installmentPaymentRows,
    notificationScheduleRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'debts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('debt_payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'installment_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('installment_payments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TaskRowsTableCreateCompanionBuilder =
    TaskRowsCompanion Function({
      required String id,
      required String title,
      required int priority,
      Value<bool> isDone,
      required int sortOrder,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> completedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskRowsTableUpdateCompanionBuilder =
    TaskRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> priority,
      Value<bool> isDone,
      Value<int> sortOrder,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> completedAtUtc,
      Value<int> rowid,
    });

class $$TaskRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => column,
  );
}

class $$TaskRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRowsTable,
          TaskRow,
          $$TaskRowsTableFilterComposer,
          $$TaskRowsTableOrderingComposer,
          $$TaskRowsTableAnnotationComposer,
          $$TaskRowsTableCreateCompanionBuilder,
          $$TaskRowsTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$AppDatabase, $TaskRowsTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TaskRowsTableTableManager(_$AppDatabase db, $TaskRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRowsCompanion(
                id: id,
                title: title,
                priority: priority,
                isDone: isDone,
                sortOrder: sortOrder,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                completedAtUtc: completedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int priority,
                Value<bool> isDone = const Value.absent(),
                required int sortOrder,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRowsCompanion.insert(
                id: id,
                title: title,
                priority: priority,
                isDone: isDone,
                sortOrder: sortOrder,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                completedAtUtc: completedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRowsTable,
      TaskRow,
      $$TaskRowsTableFilterComposer,
      $$TaskRowsTableOrderingComposer,
      $$TaskRowsTableAnnotationComposer,
      $$TaskRowsTableCreateCompanionBuilder,
      $$TaskRowsTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$AppDatabase, $TaskRowsTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$FinanceTransactionRowsTableCreateCompanionBuilder =
    FinanceTransactionRowsCompanion Function({
      required String id,
      required String type,
      required String title,
      required String category,
      required int amountMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      required DateTime occurredAtUtc,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$FinanceTransactionRowsTableUpdateCompanionBuilder =
    FinanceTransactionRowsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String> category,
      Value<int> amountMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      Value<DateTime> occurredAtUtc,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$FinanceTransactionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceTransactionRowsTable> {
  $$FinanceTransactionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinanceTransactionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceTransactionRowsTable> {
  $$FinanceTransactionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinanceTransactionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceTransactionRowsTable> {
  $$FinanceTransactionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$FinanceTransactionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceTransactionRowsTable,
          FinanceTransactionRow,
          $$FinanceTransactionRowsTableFilterComposer,
          $$FinanceTransactionRowsTableOrderingComposer,
          $$FinanceTransactionRowsTableAnnotationComposer,
          $$FinanceTransactionRowsTableCreateCompanionBuilder,
          $$FinanceTransactionRowsTableUpdateCompanionBuilder,
          (
            FinanceTransactionRow,
            BaseReferences<
              _$AppDatabase,
              $FinanceTransactionRowsTable,
              FinanceTransactionRow
            >,
          ),
          FinanceTransactionRow,
          PrefetchHooks Function()
        > {
  $$FinanceTransactionRowsTableTableManager(
    _$AppDatabase db,
    $FinanceTransactionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceTransactionRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FinanceTransactionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinanceTransactionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceTransactionRowsCompanion(
                id: id,
                type: type,
                title: title,
                category: category,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                occurredAtUtc: occurredAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String title,
                required String category,
                required int amountMinorUnits,
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                required DateTime occurredAtUtc,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => FinanceTransactionRowsCompanion.insert(
                id: id,
                type: type,
                title: title,
                category: category,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                occurredAtUtc: occurredAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinanceTransactionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceTransactionRowsTable,
      FinanceTransactionRow,
      $$FinanceTransactionRowsTableFilterComposer,
      $$FinanceTransactionRowsTableOrderingComposer,
      $$FinanceTransactionRowsTableAnnotationComposer,
      $$FinanceTransactionRowsTableCreateCompanionBuilder,
      $$FinanceTransactionRowsTableUpdateCompanionBuilder,
      (
        FinanceTransactionRow,
        BaseReferences<
          _$AppDatabase,
          $FinanceTransactionRowsTable,
          FinanceTransactionRow
        >,
      ),
      FinanceTransactionRow,
      PrefetchHooks Function()
    >;
typedef $$DebtRowsTableCreateCompanionBuilder =
    DebtRowsCompanion Function({
      required String id,
      required String title,
      required int totalMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });
typedef $$DebtRowsTableUpdateCompanionBuilder =
    DebtRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> totalMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });

final class $$DebtRowsTableReferences
    extends BaseReferences<_$AppDatabase, $DebtRowsTable, DebtRow> {
  $$DebtRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DebtPaymentRowsTable, List<DebtPaymentRow>>
  _debtPaymentRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.debtPaymentRows,
    aliasName: 'debts__id__debt_payments__debt_id',
  );

  $$DebtPaymentRowsTableProcessedTableManager get debtPaymentRowsRefs {
    final manager = $$DebtPaymentRowsTableTableManager(
      $_db,
      $_db.debtPaymentRows,
    ).filter((f) => f.debtId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _debtPaymentRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DebtRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DebtRowsTable> {
  $$DebtRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> debtPaymentRowsRefs(
    Expression<bool> Function($$DebtPaymentRowsTableFilterComposer f) f,
  ) {
    final $$DebtPaymentRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtPaymentRows,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtPaymentRowsTableFilterComposer(
            $db: $db,
            $table: $db.debtPaymentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtRowsTable> {
  $$DebtRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtRowsTable> {
  $$DebtRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => column,
  );

  Expression<T> debtPaymentRowsRefs<T extends Object>(
    Expression<T> Function($$DebtPaymentRowsTableAnnotationComposer a) f,
  ) {
    final $$DebtPaymentRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtPaymentRows,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtPaymentRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.debtPaymentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtRowsTable,
          DebtRow,
          $$DebtRowsTableFilterComposer,
          $$DebtRowsTableOrderingComposer,
          $$DebtRowsTableAnnotationComposer,
          $$DebtRowsTableCreateCompanionBuilder,
          $$DebtRowsTableUpdateCompanionBuilder,
          (DebtRow, $$DebtRowsTableReferences),
          DebtRow,
          PrefetchHooks Function({bool debtPaymentRowsRefs})
        > {
  $$DebtRowsTableTableManager(_$AppDatabase db, $DebtRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> totalMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtRowsCompanion(
                id: id,
                title: title,
                totalMinorUnits: totalMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int totalMinorUnits,
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtRowsCompanion.insert(
                id: id,
                title: title,
                totalMinorUnits: totalMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DebtRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtPaymentRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (debtPaymentRowsRefs) db.debtPaymentRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (debtPaymentRowsRefs)
                    await $_getPrefetchedData<
                      DebtRow,
                      $DebtRowsTable,
                      DebtPaymentRow
                    >(
                      currentTable: table,
                      referencedTable: $$DebtRowsTableReferences
                          ._debtPaymentRowsRefsTable(db),
                      managerFromTypedResult: (p0) => $$DebtRowsTableReferences(
                        db,
                        table,
                        p0,
                      ).debtPaymentRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.debtId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DebtRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtRowsTable,
      DebtRow,
      $$DebtRowsTableFilterComposer,
      $$DebtRowsTableOrderingComposer,
      $$DebtRowsTableAnnotationComposer,
      $$DebtRowsTableCreateCompanionBuilder,
      $$DebtRowsTableUpdateCompanionBuilder,
      (DebtRow, $$DebtRowsTableReferences),
      DebtRow,
      PrefetchHooks Function({bool debtPaymentRowsRefs})
    >;
typedef $$DebtPaymentRowsTableCreateCompanionBuilder =
    DebtPaymentRowsCompanion Function({
      required String id,
      required String debtId,
      required int amountMinorUnits,
      required DateTime paidAtUtc,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$DebtPaymentRowsTableUpdateCompanionBuilder =
    DebtPaymentRowsCompanion Function({
      Value<String> id,
      Value<String> debtId,
      Value<int> amountMinorUnits,
      Value<DateTime> paidAtUtc,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

final class $$DebtPaymentRowsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DebtPaymentRowsTable, DebtPaymentRow> {
  $$DebtPaymentRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DebtRowsTable _debtIdTable(_$AppDatabase db) =>
      db.debtRows.createAlias('debt_payments__debt_id__debts__id');

  $$DebtRowsTableProcessedTableManager get debtId {
    final $_column = $_itemColumn<String>('debt_id')!;

    final manager = $$DebtRowsTableTableManager(
      $_db,
      $_db.debtRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DebtPaymentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DebtPaymentRowsTable> {
  $$DebtPaymentRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$DebtRowsTableFilterComposer get debtId {
    final $$DebtRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debtRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtRowsTableFilterComposer(
            $db: $db,
            $table: $db.debtRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtPaymentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtPaymentRowsTable> {
  $$DebtPaymentRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$DebtRowsTableOrderingComposer get debtId {
    final $$DebtRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debtRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtRowsTableOrderingComposer(
            $db: $db,
            $table: $db.debtRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtPaymentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtPaymentRowsTable> {
  $$DebtPaymentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAtUtc =>
      $composableBuilder(column: $table.paidAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$DebtRowsTableAnnotationComposer get debtId {
    final $$DebtRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debtRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.debtRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtPaymentRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtPaymentRowsTable,
          DebtPaymentRow,
          $$DebtPaymentRowsTableFilterComposer,
          $$DebtPaymentRowsTableOrderingComposer,
          $$DebtPaymentRowsTableAnnotationComposer,
          $$DebtPaymentRowsTableCreateCompanionBuilder,
          $$DebtPaymentRowsTableUpdateCompanionBuilder,
          (DebtPaymentRow, $$DebtPaymentRowsTableReferences),
          DebtPaymentRow,
          PrefetchHooks Function({bool debtId})
        > {
  $$DebtPaymentRowsTableTableManager(
    _$AppDatabase db,
    $DebtPaymentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtPaymentRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtPaymentRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtPaymentRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> debtId = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<DateTime> paidAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtPaymentRowsCompanion(
                id: id,
                debtId: debtId,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String debtId,
                required int amountMinorUnits,
                required DateTime paidAtUtc,
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => DebtPaymentRowsCompanion.insert(
                id: id,
                debtId: debtId,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DebtPaymentRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (debtId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.debtId,
                                referencedTable:
                                    $$DebtPaymentRowsTableReferences
                                        ._debtIdTable(db),
                                referencedColumn:
                                    $$DebtPaymentRowsTableReferences
                                        ._debtIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DebtPaymentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtPaymentRowsTable,
      DebtPaymentRow,
      $$DebtPaymentRowsTableFilterComposer,
      $$DebtPaymentRowsTableOrderingComposer,
      $$DebtPaymentRowsTableAnnotationComposer,
      $$DebtPaymentRowsTableCreateCompanionBuilder,
      $$DebtPaymentRowsTableUpdateCompanionBuilder,
      (DebtPaymentRow, $$DebtPaymentRowsTableReferences),
      DebtPaymentRow,
      PrefetchHooks Function({bool debtId})
    >;
typedef $$InstallmentPlanRowsTableCreateCompanionBuilder =
    InstallmentPlanRowsCompanion Function({
      required String id,
      required String title,
      required int perInstallmentMinorUnits,
      required int installmentCount,
      Value<String> currencyCode,
      Value<int> scale,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });
typedef $$InstallmentPlanRowsTableUpdateCompanionBuilder =
    InstallmentPlanRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> perInstallmentMinorUnits,
      Value<int> installmentCount,
      Value<String> currencyCode,
      Value<int> scale,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });

final class $$InstallmentPlanRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstallmentPlanRowsTable,
          InstallmentPlanRow
        > {
  $$InstallmentPlanRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $InstallmentPaymentRowsTable,
    List<InstallmentPaymentRow>
  >
  _installmentPaymentRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.installmentPaymentRows,
        aliasName: 'installment_plans__id__installment_payments__plan_id',
      );

  $$InstallmentPaymentRowsTableProcessedTableManager
  get installmentPaymentRowsRefs {
    final manager = $$InstallmentPaymentRowsTableTableManager(
      $_db,
      $_db.installmentPaymentRows,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _installmentPaymentRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstallmentPlanRowsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentPlanRowsTable> {
  $$InstallmentPlanRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perInstallmentMinorUnits => $composableBuilder(
    column: $table.perInstallmentMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> installmentPaymentRowsRefs(
    Expression<bool> Function($$InstallmentPaymentRowsTableFilterComposer f) f,
  ) {
    final $$InstallmentPaymentRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.installmentPaymentRows,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPaymentRowsTableFilterComposer(
                $db: $db,
                $table: $db.installmentPaymentRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InstallmentPlanRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentPlanRowsTable> {
  $$InstallmentPlanRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perInstallmentMinorUnits => $composableBuilder(
    column: $table.perInstallmentMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstallmentPlanRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentPlanRowsTable> {
  $$InstallmentPlanRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get perInstallmentMinorUnits => $composableBuilder(
    column: $table.perInstallmentMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => column,
  );

  Expression<T> installmentPaymentRowsRefs<T extends Object>(
    Expression<T> Function($$InstallmentPaymentRowsTableAnnotationComposer a) f,
  ) {
    final $$InstallmentPaymentRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.installmentPaymentRows,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPaymentRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.installmentPaymentRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InstallmentPlanRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentPlanRowsTable,
          InstallmentPlanRow,
          $$InstallmentPlanRowsTableFilterComposer,
          $$InstallmentPlanRowsTableOrderingComposer,
          $$InstallmentPlanRowsTableAnnotationComposer,
          $$InstallmentPlanRowsTableCreateCompanionBuilder,
          $$InstallmentPlanRowsTableUpdateCompanionBuilder,
          (InstallmentPlanRow, $$InstallmentPlanRowsTableReferences),
          InstallmentPlanRow,
          PrefetchHooks Function({bool installmentPaymentRowsRefs})
        > {
  $$InstallmentPlanRowsTableTableManager(
    _$AppDatabase db,
    $InstallmentPlanRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentPlanRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentPlanRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstallmentPlanRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> perInstallmentMinorUnits = const Value.absent(),
                Value<int> installmentCount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPlanRowsCompanion(
                id: id,
                title: title,
                perInstallmentMinorUnits: perInstallmentMinorUnits,
                installmentCount: installmentCount,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int perInstallmentMinorUnits,
                required int installmentCount,
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPlanRowsCompanion.insert(
                id: id,
                title: title,
                perInstallmentMinorUnits: perInstallmentMinorUnits,
                installmentCount: installmentCount,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstallmentPlanRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({installmentPaymentRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (installmentPaymentRowsRefs) db.installmentPaymentRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (installmentPaymentRowsRefs)
                    await $_getPrefetchedData<
                      InstallmentPlanRow,
                      $InstallmentPlanRowsTable,
                      InstallmentPaymentRow
                    >(
                      currentTable: table,
                      referencedTable: $$InstallmentPlanRowsTableReferences
                          ._installmentPaymentRowsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InstallmentPlanRowsTableReferences(
                            db,
                            table,
                            p0,
                          ).installmentPaymentRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.planId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InstallmentPlanRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentPlanRowsTable,
      InstallmentPlanRow,
      $$InstallmentPlanRowsTableFilterComposer,
      $$InstallmentPlanRowsTableOrderingComposer,
      $$InstallmentPlanRowsTableAnnotationComposer,
      $$InstallmentPlanRowsTableCreateCompanionBuilder,
      $$InstallmentPlanRowsTableUpdateCompanionBuilder,
      (InstallmentPlanRow, $$InstallmentPlanRowsTableReferences),
      InstallmentPlanRow,
      PrefetchHooks Function({bool installmentPaymentRowsRefs})
    >;
typedef $$InstallmentPaymentRowsTableCreateCompanionBuilder =
    InstallmentPaymentRowsCompanion Function({
      required String id,
      required String planId,
      required int installmentNumber,
      required int amountMinorUnits,
      required DateTime paidAtUtc,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$InstallmentPaymentRowsTableUpdateCompanionBuilder =
    InstallmentPaymentRowsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<int> installmentNumber,
      Value<int> amountMinorUnits,
      Value<DateTime> paidAtUtc,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

final class $$InstallmentPaymentRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstallmentPaymentRowsTable,
          InstallmentPaymentRow
        > {
  $$InstallmentPaymentRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InstallmentPlanRowsTable _planIdTable(_$AppDatabase db) => db
      .installmentPlanRows
      .createAlias('installment_payments__plan_id__installment_plans__id');

  $$InstallmentPlanRowsTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$InstallmentPlanRowsTableTableManager(
      $_db,
      $_db.installmentPlanRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstallmentPaymentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentPaymentRowsTable> {
  $$InstallmentPaymentRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$InstallmentPlanRowsTableFilterComposer get planId {
    final $$InstallmentPlanRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.installmentPlanRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlanRowsTableFilterComposer(
            $db: $db,
            $table: $db.installmentPlanRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentPaymentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentPaymentRowsTable> {
  $$InstallmentPaymentRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstallmentPlanRowsTableOrderingComposer get planId {
    final $$InstallmentPlanRowsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.planId,
          referencedTable: $db.installmentPlanRows,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPlanRowsTableOrderingComposer(
                $db: $db,
                $table: $db.installmentPlanRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$InstallmentPaymentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentPaymentRowsTable> {
  $$InstallmentPaymentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAtUtc =>
      $composableBuilder(column: $table.paidAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$InstallmentPlanRowsTableAnnotationComposer get planId {
    final $$InstallmentPlanRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.planId,
          referencedTable: $db.installmentPlanRows,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPlanRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.installmentPlanRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$InstallmentPaymentRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentPaymentRowsTable,
          InstallmentPaymentRow,
          $$InstallmentPaymentRowsTableFilterComposer,
          $$InstallmentPaymentRowsTableOrderingComposer,
          $$InstallmentPaymentRowsTableAnnotationComposer,
          $$InstallmentPaymentRowsTableCreateCompanionBuilder,
          $$InstallmentPaymentRowsTableUpdateCompanionBuilder,
          (InstallmentPaymentRow, $$InstallmentPaymentRowsTableReferences),
          InstallmentPaymentRow,
          PrefetchHooks Function({bool planId})
        > {
  $$InstallmentPaymentRowsTableTableManager(
    _$AppDatabase db,
    $InstallmentPaymentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentPaymentRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InstallmentPaymentRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstallmentPaymentRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> installmentNumber = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<DateTime> paidAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPaymentRowsCompanion(
                id: id,
                planId: planId,
                installmentNumber: installmentNumber,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required int installmentNumber,
                required int amountMinorUnits,
                required DateTime paidAtUtc,
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPaymentRowsCompanion.insert(
                id: id,
                planId: planId,
                installmentNumber: installmentNumber,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstallmentPaymentRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planId,
                                referencedTable:
                                    $$InstallmentPaymentRowsTableReferences
                                        ._planIdTable(db),
                                referencedColumn:
                                    $$InstallmentPaymentRowsTableReferences
                                        ._planIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InstallmentPaymentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentPaymentRowsTable,
      InstallmentPaymentRow,
      $$InstallmentPaymentRowsTableFilterComposer,
      $$InstallmentPaymentRowsTableOrderingComposer,
      $$InstallmentPaymentRowsTableAnnotationComposer,
      $$InstallmentPaymentRowsTableCreateCompanionBuilder,
      $$InstallmentPaymentRowsTableUpdateCompanionBuilder,
      (InstallmentPaymentRow, $$InstallmentPaymentRowsTableReferences),
      InstallmentPaymentRow,
      PrefetchHooks Function({bool planId})
    >;
typedef $$NotificationScheduleRowsTableCreateCompanionBuilder =
    NotificationScheduleRowsCompanion Function({
      required String scheduleId,
      required String ownerType,
      required String ownerId,
      required String title,
      required String body,
      required DateTime scheduledAtUtc,
      Value<String> payloadJson,
      Value<String> privacyMode,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$NotificationScheduleRowsTableUpdateCompanionBuilder =
    NotificationScheduleRowsCompanion Function({
      Value<String> scheduleId,
      Value<String> ownerType,
      Value<String> ownerId,
      Value<String> title,
      Value<String> body,
      Value<DateTime> scheduledAtUtc,
      Value<String> payloadJson,
      Value<String> privacyMode,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$NotificationScheduleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationScheduleRowsTable> {
  $$NotificationScheduleRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationScheduleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationScheduleRowsTable> {
  $$NotificationScheduleRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationScheduleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationScheduleRowsTable> {
  $$NotificationScheduleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$NotificationScheduleRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationScheduleRowsTable,
          NotificationScheduleRow,
          $$NotificationScheduleRowsTableFilterComposer,
          $$NotificationScheduleRowsTableOrderingComposer,
          $$NotificationScheduleRowsTableAnnotationComposer,
          $$NotificationScheduleRowsTableCreateCompanionBuilder,
          $$NotificationScheduleRowsTableUpdateCompanionBuilder,
          (
            NotificationScheduleRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationScheduleRowsTable,
              NotificationScheduleRow
            >,
          ),
          NotificationScheduleRow,
          PrefetchHooks Function()
        > {
  $$NotificationScheduleRowsTableTableManager(
    _$AppDatabase db,
    $NotificationScheduleRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationScheduleRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NotificationScheduleRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationScheduleRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scheduleId = const Value.absent(),
                Value<String> ownerType = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> scheduledAtUtc = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationScheduleRowsCompanion(
                scheduleId: scheduleId,
                ownerType: ownerType,
                ownerId: ownerId,
                title: title,
                body: body,
                scheduledAtUtc: scheduledAtUtc,
                payloadJson: payloadJson,
                privacyMode: privacyMode,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scheduleId,
                required String ownerType,
                required String ownerId,
                required String title,
                required String body,
                required DateTime scheduledAtUtc,
                Value<String> payloadJson = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => NotificationScheduleRowsCompanion.insert(
                scheduleId: scheduleId,
                ownerType: ownerType,
                ownerId: ownerId,
                title: title,
                body: body,
                scheduledAtUtc: scheduledAtUtc,
                payloadJson: payloadJson,
                privacyMode: privacyMode,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationScheduleRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationScheduleRowsTable,
      NotificationScheduleRow,
      $$NotificationScheduleRowsTableFilterComposer,
      $$NotificationScheduleRowsTableOrderingComposer,
      $$NotificationScheduleRowsTableAnnotationComposer,
      $$NotificationScheduleRowsTableCreateCompanionBuilder,
      $$NotificationScheduleRowsTableUpdateCompanionBuilder,
      (
        NotificationScheduleRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationScheduleRowsTable,
          NotificationScheduleRow
        >,
      ),
      NotificationScheduleRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskRowsTableTableManager get taskRows =>
      $$TaskRowsTableTableManager(_db, _db.taskRows);
  $$FinanceTransactionRowsTableTableManager get financeTransactionRows =>
      $$FinanceTransactionRowsTableTableManager(
        _db,
        _db.financeTransactionRows,
      );
  $$DebtRowsTableTableManager get debtRows =>
      $$DebtRowsTableTableManager(_db, _db.debtRows);
  $$DebtPaymentRowsTableTableManager get debtPaymentRows =>
      $$DebtPaymentRowsTableTableManager(_db, _db.debtPaymentRows);
  $$InstallmentPlanRowsTableTableManager get installmentPlanRows =>
      $$InstallmentPlanRowsTableTableManager(_db, _db.installmentPlanRows);
  $$InstallmentPaymentRowsTableTableManager get installmentPaymentRows =>
      $$InstallmentPaymentRowsTableTableManager(
        _db,
        _db.installmentPaymentRows,
      );
  $$NotificationScheduleRowsTableTableManager get notificationScheduleRows =>
      $$NotificationScheduleRowsTableTableManager(
        _db,
        _db.notificationScheduleRows,
      );
}
