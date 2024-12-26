// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PuzzleCategoriesTable extends PuzzleCategories
    with TableInfo<$PuzzleCategoriesTable, PuzzleCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, iconName, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_categories';
  @override
  VerificationContext validateIntegrity(Insertable<PuzzleCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PuzzleCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $PuzzleCategoriesTable createAlias(String alias) {
    return $PuzzleCategoriesTable(attachedDatabase, alias);
  }
}

class PuzzleCategory extends DataClass implements Insertable<PuzzleCategory> {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final int sortOrder;
  const PuzzleCategory(
      {required this.id,
      required this.name,
      required this.description,
      required this.iconName,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['icon_name'] = Variable<String>(iconName);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PuzzleCategoriesCompanion toCompanion(bool nullToAbsent) {
    return PuzzleCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      iconName: Value(iconName),
      sortOrder: Value(sortOrder),
    );
  }

  factory PuzzleCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      iconName: serializer.fromJson<String>(json['iconName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'iconName': serializer.toJson<String>(iconName),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PuzzleCategory copyWith(
          {int? id,
          String? name,
          String? description,
          String? iconName,
          int? sortOrder}) =>
      PuzzleCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        iconName: iconName ?? this.iconName,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  PuzzleCategory copyWithCompanion(PuzzleCategoriesCompanion data) {
    return PuzzleCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, iconName, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.iconName == this.iconName &&
          other.sortOrder == this.sortOrder);
}

class PuzzleCategoriesCompanion extends UpdateCompanion<PuzzleCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> iconName;
  final Value<int> sortOrder;
  const PuzzleCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  PuzzleCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String description,
    required String iconName,
    required int sortOrder,
  })  : name = Value(name),
        description = Value(description),
        iconName = Value(iconName),
        sortOrder = Value(sortOrder);
  static Insertable<PuzzleCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? iconName,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (iconName != null) 'icon_name': iconName,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  PuzzleCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? description,
      Value<String>? iconName,
      Value<int>? sortOrder}) {
    return PuzzleCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $PuzzlesTable extends Puzzles with TableInfo<$PuzzlesTable, Puzzle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES puzzle_categories (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderInCategoryMeta =
      const VerificationMeta('orderInCategory');
  @override
  late final GeneratedColumn<int> orderInCategory = GeneratedColumn<int>(
      'order_in_category', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _gameDataMeta =
      const VerificationMeta('gameData');
  @override
  late final GeneratedColumn<String> gameData = GeneratedColumn<String>(
      'game_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isLockedMeta =
      const VerificationMeta('isLocked');
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
      'is_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_locked" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _requiredScoreMeta =
      const VerificationMeta('requiredScore');
  @override
  late final GeneratedColumn<int> requiredScore = GeneratedColumn<int>(
      'required_score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        categoryId,
        name,
        description,
        difficulty,
        orderInCategory,
        gameData,
        isLocked,
        requiredScore
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzles';
  @override
  VerificationContext validateIntegrity(Insertable<Puzzle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('order_in_category')) {
      context.handle(
          _orderInCategoryMeta,
          orderInCategory.isAcceptableOrUnknown(
              data['order_in_category']!, _orderInCategoryMeta));
    } else if (isInserting) {
      context.missing(_orderInCategoryMeta);
    }
    if (data.containsKey('game_data')) {
      context.handle(_gameDataMeta,
          gameData.isAcceptableOrUnknown(data['game_data']!, _gameDataMeta));
    } else if (isInserting) {
      context.missing(_gameDataMeta);
    }
    if (data.containsKey('is_locked')) {
      context.handle(_isLockedMeta,
          isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta));
    }
    if (data.containsKey('required_score')) {
      context.handle(
          _requiredScoreMeta,
          requiredScore.isAcceptableOrUnknown(
              data['required_score']!, _requiredScoreMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Puzzle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Puzzle(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      orderInCategory: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_in_category'])!,
      gameData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_data'])!,
      isLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_locked'])!,
      requiredScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}required_score'])!,
    );
  }

  @override
  $PuzzlesTable createAlias(String alias) {
    return $PuzzlesTable(attachedDatabase, alias);
  }
}

class Puzzle extends DataClass implements Insertable<Puzzle> {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String difficulty;
  final int orderInCategory;
  final String gameData;
  final bool isLocked;
  final int requiredScore;
  const Puzzle(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.description,
      required this.difficulty,
      required this.orderInCategory,
      required this.gameData,
      required this.isLocked,
      required this.requiredScore});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['difficulty'] = Variable<String>(difficulty);
    map['order_in_category'] = Variable<int>(orderInCategory);
    map['game_data'] = Variable<String>(gameData);
    map['is_locked'] = Variable<bool>(isLocked);
    map['required_score'] = Variable<int>(requiredScore);
    return map;
  }

  PuzzlesCompanion toCompanion(bool nullToAbsent) {
    return PuzzlesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      description: Value(description),
      difficulty: Value(difficulty),
      orderInCategory: Value(orderInCategory),
      gameData: Value(gameData),
      isLocked: Value(isLocked),
      requiredScore: Value(requiredScore),
    );
  }

  factory Puzzle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Puzzle(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      orderInCategory: serializer.fromJson<int>(json['orderInCategory']),
      gameData: serializer.fromJson<String>(json['gameData']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      requiredScore: serializer.fromJson<int>(json['requiredScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'difficulty': serializer.toJson<String>(difficulty),
      'orderInCategory': serializer.toJson<int>(orderInCategory),
      'gameData': serializer.toJson<String>(gameData),
      'isLocked': serializer.toJson<bool>(isLocked),
      'requiredScore': serializer.toJson<int>(requiredScore),
    };
  }

  Puzzle copyWith(
          {int? id,
          int? categoryId,
          String? name,
          String? description,
          String? difficulty,
          int? orderInCategory,
          String? gameData,
          bool? isLocked,
          int? requiredScore}) =>
      Puzzle(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        description: description ?? this.description,
        difficulty: difficulty ?? this.difficulty,
        orderInCategory: orderInCategory ?? this.orderInCategory,
        gameData: gameData ?? this.gameData,
        isLocked: isLocked ?? this.isLocked,
        requiredScore: requiredScore ?? this.requiredScore,
      );
  Puzzle copyWithCompanion(PuzzlesCompanion data) {
    return Puzzle(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      orderInCategory: data.orderInCategory.present
          ? data.orderInCategory.value
          : this.orderInCategory,
      gameData: data.gameData.present ? data.gameData.value : this.gameData,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      requiredScore: data.requiredScore.present
          ? data.requiredScore.value
          : this.requiredScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Puzzle(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('difficulty: $difficulty, ')
          ..write('orderInCategory: $orderInCategory, ')
          ..write('gameData: $gameData, ')
          ..write('isLocked: $isLocked, ')
          ..write('requiredScore: $requiredScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, name, description, difficulty,
      orderInCategory, gameData, isLocked, requiredScore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Puzzle &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.description == this.description &&
          other.difficulty == this.difficulty &&
          other.orderInCategory == this.orderInCategory &&
          other.gameData == this.gameData &&
          other.isLocked == this.isLocked &&
          other.requiredScore == this.requiredScore);
}

class PuzzlesCompanion extends UpdateCompanion<Puzzle> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> difficulty;
  final Value<int> orderInCategory;
  final Value<String> gameData;
  final Value<bool> isLocked;
  final Value<int> requiredScore;
  const PuzzlesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.orderInCategory = const Value.absent(),
    this.gameData = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.requiredScore = const Value.absent(),
  });
  PuzzlesCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String name,
    required String description,
    required String difficulty,
    required int orderInCategory,
    required String gameData,
    this.isLocked = const Value.absent(),
    this.requiredScore = const Value.absent(),
  })  : categoryId = Value(categoryId),
        name = Value(name),
        description = Value(description),
        difficulty = Value(difficulty),
        orderInCategory = Value(orderInCategory),
        gameData = Value(gameData);
  static Insertable<Puzzle> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? difficulty,
    Expression<int>? orderInCategory,
    Expression<String>? gameData,
    Expression<bool>? isLocked,
    Expression<int>? requiredScore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (difficulty != null) 'difficulty': difficulty,
      if (orderInCategory != null) 'order_in_category': orderInCategory,
      if (gameData != null) 'game_data': gameData,
      if (isLocked != null) 'is_locked': isLocked,
      if (requiredScore != null) 'required_score': requiredScore,
    });
  }

  PuzzlesCompanion copyWith(
      {Value<int>? id,
      Value<int>? categoryId,
      Value<String>? name,
      Value<String>? description,
      Value<String>? difficulty,
      Value<int>? orderInCategory,
      Value<String>? gameData,
      Value<bool>? isLocked,
      Value<int>? requiredScore}) {
    return PuzzlesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      orderInCategory: orderInCategory ?? this.orderInCategory,
      gameData: gameData ?? this.gameData,
      isLocked: isLocked ?? this.isLocked,
      requiredScore: requiredScore ?? this.requiredScore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (orderInCategory.present) {
      map['order_in_category'] = Variable<int>(orderInCategory.value);
    }
    if (gameData.present) {
      map['game_data'] = Variable<String>(gameData.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (requiredScore.present) {
      map['required_score'] = Variable<int>(requiredScore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzlesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('difficulty: $difficulty, ')
          ..write('orderInCategory: $orderInCategory, ')
          ..write('gameData: $gameData, ')
          ..write('isLocked: $isLocked, ')
          ..write('requiredScore: $requiredScore')
          ..write(')'))
        .toString();
  }
}

class $UserProgressTable extends UserProgress
    with TableInfo<$UserProgressTable, UserProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _puzzleIdMeta =
      const VerificationMeta('puzzleId');
  @override
  late final GeneratedColumn<int> puzzleId = GeneratedColumn<int>(
      'puzzle_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES puzzles (id)'));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
      'stars', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hintsUsedMeta =
      const VerificationMeta('hintsUsed');
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
      'hints_used', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _timeSpentSecondsMeta =
      const VerificationMeta('timeSpentSeconds');
  @override
  late final GeneratedColumn<int> timeSpentSeconds = GeneratedColumn<int>(
      'time_spent_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        puzzleId,
        level,
        stars,
        score,
        hintsUsed,
        timeSpentSeconds,
        lastPlayedAt,
        isCompleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress';
  @override
  VerificationContext validateIntegrity(Insertable<UserProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(_puzzleIdMeta,
          puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta));
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('stars')) {
      context.handle(
          _starsMeta, stars.isAcceptableOrUnknown(data['stars']!, _starsMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('hints_used')) {
      context.handle(_hintsUsedMeta,
          hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta));
    }
    if (data.containsKey('time_spent_seconds')) {
      context.handle(
          _timeSpentSecondsMeta,
          timeSpentSeconds.isAcceptableOrUnknown(
              data['time_spent_seconds']!, _timeSpentSecondsMeta));
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      puzzleId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}puzzle_id'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      stars: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stars'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      hintsUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hints_used'])!,
      timeSpentSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}time_spent_seconds'])!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_played_at']),
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
    );
  }

  @override
  $UserProgressTable createAlias(String alias) {
    return $UserProgressTable(attachedDatabase, alias);
  }
}

class UserProgressData extends DataClass
    implements Insertable<UserProgressData> {
  final int id;
  final int puzzleId;
  final int level;
  final int stars;
  final int score;
  final int hintsUsed;
  final int timeSpentSeconds;
  final DateTime? lastPlayedAt;
  final bool isCompleted;
  const UserProgressData(
      {required this.id,
      required this.puzzleId,
      required this.level,
      required this.stars,
      required this.score,
      required this.hintsUsed,
      required this.timeSpentSeconds,
      this.lastPlayedAt,
      required this.isCompleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<int>(puzzleId);
    map['level'] = Variable<int>(level);
    map['stars'] = Variable<int>(stars);
    map['score'] = Variable<int>(score);
    map['hints_used'] = Variable<int>(hintsUsed);
    map['time_spent_seconds'] = Variable<int>(timeSpentSeconds);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  UserProgressCompanion toCompanion(bool nullToAbsent) {
    return UserProgressCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      level: Value(level),
      stars: Value(stars),
      score: Value(score),
      hintsUsed: Value(hintsUsed),
      timeSpentSeconds: Value(timeSpentSeconds),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      isCompleted: Value(isCompleted),
    );
  }

  factory UserProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgressData(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<int>(json['puzzleId']),
      level: serializer.fromJson<int>(json['level']),
      stars: serializer.fromJson<int>(json['stars']),
      score: serializer.fromJson<int>(json['score']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      timeSpentSeconds: serializer.fromJson<int>(json['timeSpentSeconds']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<int>(puzzleId),
      'level': serializer.toJson<int>(level),
      'stars': serializer.toJson<int>(stars),
      'score': serializer.toJson<int>(score),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'timeSpentSeconds': serializer.toJson<int>(timeSpentSeconds),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  UserProgressData copyWith(
          {int? id,
          int? puzzleId,
          int? level,
          int? stars,
          int? score,
          int? hintsUsed,
          int? timeSpentSeconds,
          Value<DateTime?> lastPlayedAt = const Value.absent(),
          bool? isCompleted}) =>
      UserProgressData(
        id: id ?? this.id,
        puzzleId: puzzleId ?? this.puzzleId,
        level: level ?? this.level,
        stars: stars ?? this.stars,
        score: score ?? this.score,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
        isCompleted: isCompleted ?? this.isCompleted,
      );
  UserProgressData copyWithCompanion(UserProgressCompanion data) {
    return UserProgressData(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      level: data.level.present ? data.level.value : this.level,
      stars: data.stars.present ? data.stars.value : this.stars,
      score: data.score.present ? data.score.value : this.score,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      timeSpentSeconds: data.timeSpentSeconds.present
          ? data.timeSpentSeconds.value
          : this.timeSpentSeconds,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressData(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('level: $level, ')
          ..write('stars: $stars, ')
          ..write('score: $score, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, puzzleId, level, stars, score, hintsUsed,
      timeSpentSeconds, lastPlayedAt, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgressData &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.level == this.level &&
          other.stars == this.stars &&
          other.score == this.score &&
          other.hintsUsed == this.hintsUsed &&
          other.timeSpentSeconds == this.timeSpentSeconds &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.isCompleted == this.isCompleted);
}

class UserProgressCompanion extends UpdateCompanion<UserProgressData> {
  final Value<int> id;
  final Value<int> puzzleId;
  final Value<int> level;
  final Value<int> stars;
  final Value<int> score;
  final Value<int> hintsUsed;
  final Value<int> timeSpentSeconds;
  final Value<DateTime?> lastPlayedAt;
  final Value<bool> isCompleted;
  const UserProgressCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.level = const Value.absent(),
    this.stars = const Value.absent(),
    this.score = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
  });
  UserProgressCompanion.insert({
    this.id = const Value.absent(),
    required int puzzleId,
    this.level = const Value.absent(),
    this.stars = const Value.absent(),
    this.score = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.timeSpentSeconds = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
  }) : puzzleId = Value(puzzleId);
  static Insertable<UserProgressData> custom({
    Expression<int>? id,
    Expression<int>? puzzleId,
    Expression<int>? level,
    Expression<int>? stars,
    Expression<int>? score,
    Expression<int>? hintsUsed,
    Expression<int>? timeSpentSeconds,
    Expression<DateTime>? lastPlayedAt,
    Expression<bool>? isCompleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (level != null) 'level': level,
      if (stars != null) 'stars': stars,
      if (score != null) 'score': score,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (isCompleted != null) 'is_completed': isCompleted,
    });
  }

  UserProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? puzzleId,
      Value<int>? level,
      Value<int>? stars,
      Value<int>? score,
      Value<int>? hintsUsed,
      Value<int>? timeSpentSeconds,
      Value<DateTime?>? lastPlayedAt,
      Value<bool>? isCompleted}) {
    return UserProgressCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      level: level ?? this.level,
      stars: stars ?? this.stars,
      score: score ?? this.score,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<int>(puzzleId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (timeSpentSeconds.present) {
      map['time_spent_seconds'] = Variable<int>(timeSpentSeconds.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('level: $level, ')
          ..write('stars: $stars, ')
          ..write('score: $score, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('timeSpentSeconds: $timeSpentSeconds, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requirementMeta =
      const VerificationMeta('requirement');
  @override
  late final GeneratedColumn<int> requirement = GeneratedColumn<int>(
      'requirement', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rewardMeta = const VerificationMeta('reward');
  @override
  late final GeneratedColumn<String> reward = GeneratedColumn<String>(
      'reward', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, iconName, type, requirement, reward];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(Insertable<Achievement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('requirement')) {
      context.handle(
          _requirementMeta,
          requirement.isAcceptableOrUnknown(
              data['requirement']!, _requirementMeta));
    } else if (isInserting) {
      context.missing(_requirementMeta);
    }
    if (data.containsKey('reward')) {
      context.handle(_rewardMeta,
          reward.isAcceptableOrUnknown(data['reward']!, _rewardMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      requirement: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}requirement'])!,
      reward: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reward']),
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final String type;
  final int requirement;
  final String? reward;
  const Achievement(
      {required this.id,
      required this.name,
      required this.description,
      required this.iconName,
      required this.type,
      required this.requirement,
      this.reward});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['icon_name'] = Variable<String>(iconName);
    map['type'] = Variable<String>(type);
    map['requirement'] = Variable<int>(requirement);
    if (!nullToAbsent || reward != null) {
      map['reward'] = Variable<String>(reward);
    }
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      iconName: Value(iconName),
      type: Value(type),
      requirement: Value(requirement),
      reward:
          reward == null && nullToAbsent ? const Value.absent() : Value(reward),
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      iconName: serializer.fromJson<String>(json['iconName']),
      type: serializer.fromJson<String>(json['type']),
      requirement: serializer.fromJson<int>(json['requirement']),
      reward: serializer.fromJson<String?>(json['reward']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'iconName': serializer.toJson<String>(iconName),
      'type': serializer.toJson<String>(type),
      'requirement': serializer.toJson<int>(requirement),
      'reward': serializer.toJson<String?>(reward),
    };
  }

  Achievement copyWith(
          {int? id,
          String? name,
          String? description,
          String? iconName,
          String? type,
          int? requirement,
          Value<String?> reward = const Value.absent()}) =>
      Achievement(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        iconName: iconName ?? this.iconName,
        type: type ?? this.type,
        requirement: requirement ?? this.requirement,
        reward: reward.present ? reward.value : this.reward,
      );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      type: data.type.present ? data.type.value : this.type,
      requirement:
          data.requirement.present ? data.requirement.value : this.requirement,
      reward: data.reward.present ? data.reward.value : this.reward,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('iconName: $iconName, ')
          ..write('type: $type, ')
          ..write('requirement: $requirement, ')
          ..write('reward: $reward')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, iconName, type, requirement, reward);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.iconName == this.iconName &&
          other.type == this.type &&
          other.requirement == this.requirement &&
          other.reward == this.reward);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> iconName;
  final Value<String> type;
  final Value<int> requirement;
  final Value<String?> reward;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.iconName = const Value.absent(),
    this.type = const Value.absent(),
    this.requirement = const Value.absent(),
    this.reward = const Value.absent(),
  });
  AchievementsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String description,
    required String iconName,
    required String type,
    required int requirement,
    this.reward = const Value.absent(),
  })  : name = Value(name),
        description = Value(description),
        iconName = Value(iconName),
        type = Value(type),
        requirement = Value(requirement);
  static Insertable<Achievement> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? iconName,
    Expression<String>? type,
    Expression<int>? requirement,
    Expression<String>? reward,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (iconName != null) 'icon_name': iconName,
      if (type != null) 'type': type,
      if (requirement != null) 'requirement': requirement,
      if (reward != null) 'reward': reward,
    });
  }

  AchievementsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? description,
      Value<String>? iconName,
      Value<String>? type,
      Value<int>? requirement,
      Value<String?>? reward}) {
    return AchievementsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      requirement: requirement ?? this.requirement,
      reward: reward ?? this.reward,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (requirement.present) {
      map['requirement'] = Variable<int>(requirement.value);
    }
    if (reward.present) {
      map['reward'] = Variable<String>(reward.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('iconName: $iconName, ')
          ..write('type: $type, ')
          ..write('requirement: $requirement, ')
          ..write('reward: $reward')
          ..write(')'))
        .toString();
  }
}

class $UserAchievementsTable extends UserAchievements
    with TableInfo<$UserAchievementsTable, UserAchievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _achievementIdMeta =
      const VerificationMeta('achievementId');
  @override
  late final GeneratedColumn<int> achievementId = GeneratedColumn<int>(
      'achievement_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES achievements (id)'));
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
      'unlocked_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isCollectedMeta =
      const VerificationMeta('isCollected');
  @override
  late final GeneratedColumn<bool> isCollected = GeneratedColumn<bool>(
      'is_collected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_collected" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, achievementId, unlockedAt, isCollected];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_achievements';
  @override
  VerificationContext validateIntegrity(Insertable<UserAchievement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('achievement_id')) {
      context.handle(
          _achievementIdMeta,
          achievementId.isAcceptableOrUnknown(
              data['achievement_id']!, _achievementIdMeta));
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('is_collected')) {
      context.handle(
          _isCollectedMeta,
          isCollected.isAcceptableOrUnknown(
              data['is_collected']!, _isCollectedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserAchievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAchievement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      achievementId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}achievement_id'])!,
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}unlocked_at'])!,
      isCollected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_collected'])!,
    );
  }

  @override
  $UserAchievementsTable createAlias(String alias) {
    return $UserAchievementsTable(attachedDatabase, alias);
  }
}

class UserAchievement extends DataClass implements Insertable<UserAchievement> {
  final int id;
  final int achievementId;
  final DateTime unlockedAt;
  final bool isCollected;
  const UserAchievement(
      {required this.id,
      required this.achievementId,
      required this.unlockedAt,
      required this.isCollected});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['achievement_id'] = Variable<int>(achievementId);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    map['is_collected'] = Variable<bool>(isCollected);
    return map;
  }

  UserAchievementsCompanion toCompanion(bool nullToAbsent) {
    return UserAchievementsCompanion(
      id: Value(id),
      achievementId: Value(achievementId),
      unlockedAt: Value(unlockedAt),
      isCollected: Value(isCollected),
    );
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAchievement(
      id: serializer.fromJson<int>(json['id']),
      achievementId: serializer.fromJson<int>(json['achievementId']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
      isCollected: serializer.fromJson<bool>(json['isCollected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'achievementId': serializer.toJson<int>(achievementId),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
      'isCollected': serializer.toJson<bool>(isCollected),
    };
  }

  UserAchievement copyWith(
          {int? id,
          int? achievementId,
          DateTime? unlockedAt,
          bool? isCollected}) =>
      UserAchievement(
        id: id ?? this.id,
        achievementId: achievementId ?? this.achievementId,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        isCollected: isCollected ?? this.isCollected,
      );
  UserAchievement copyWithCompanion(UserAchievementsCompanion data) {
    return UserAchievement(
      id: data.id.present ? data.id.value : this.id,
      achievementId: data.achievementId.present
          ? data.achievementId.value
          : this.achievementId,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
      isCollected:
          data.isCollected.present ? data.isCollected.value : this.isCollected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAchievement(')
          ..write('id: $id, ')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('isCollected: $isCollected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, achievementId, unlockedAt, isCollected);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAchievement &&
          other.id == this.id &&
          other.achievementId == this.achievementId &&
          other.unlockedAt == this.unlockedAt &&
          other.isCollected == this.isCollected);
}

class UserAchievementsCompanion extends UpdateCompanion<UserAchievement> {
  final Value<int> id;
  final Value<int> achievementId;
  final Value<DateTime> unlockedAt;
  final Value<bool> isCollected;
  const UserAchievementsCompanion({
    this.id = const Value.absent(),
    this.achievementId = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.isCollected = const Value.absent(),
  });
  UserAchievementsCompanion.insert({
    this.id = const Value.absent(),
    required int achievementId,
    required DateTime unlockedAt,
    this.isCollected = const Value.absent(),
  })  : achievementId = Value(achievementId),
        unlockedAt = Value(unlockedAt);
  static Insertable<UserAchievement> custom({
    Expression<int>? id,
    Expression<int>? achievementId,
    Expression<DateTime>? unlockedAt,
    Expression<bool>? isCollected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (achievementId != null) 'achievement_id': achievementId,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (isCollected != null) 'is_collected': isCollected,
    });
  }

  UserAchievementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? achievementId,
      Value<DateTime>? unlockedAt,
      Value<bool>? isCollected}) {
    return UserAchievementsCompanion(
      id: id ?? this.id,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isCollected: isCollected ?? this.isCollected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (achievementId.present) {
      map['achievement_id'] = Variable<int>(achievementId.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (isCollected.present) {
      map['is_collected'] = Variable<bool>(isCollected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAchievementsCompanion(')
          ..write('id: $id, ')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('isCollected: $isCollected')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
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
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
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

  Setting copyWith({String? key, String? value}) => Setting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
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
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Setting> custom({
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

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
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
  late final $PuzzleCategoriesTable puzzleCategories =
      $PuzzleCategoriesTable(this);
  late final $PuzzlesTable puzzles = $PuzzlesTable(this);
  late final $UserProgressTable userProgress = $UserProgressTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $UserAchievementsTable userAchievements =
      $UserAchievementsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        puzzleCategories,
        puzzles,
        userProgress,
        achievements,
        userAchievements,
        settings
      ];
}

typedef $$PuzzleCategoriesTableCreateCompanionBuilder
    = PuzzleCategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String description,
  required String iconName,
  required int sortOrder,
});
typedef $$PuzzleCategoriesTableUpdateCompanionBuilder
    = PuzzleCategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> description,
  Value<String> iconName,
  Value<int> sortOrder,
});

final class $$PuzzleCategoriesTableReferences extends BaseReferences<
    _$AppDatabase, $PuzzleCategoriesTable, PuzzleCategory> {
  $$PuzzleCategoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PuzzlesTable, List<Puzzle>> _puzzlesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.puzzles,
          aliasName: $_aliasNameGenerator(
              db.puzzleCategories.id, db.puzzles.categoryId));

  $$PuzzlesTableProcessedTableManager get puzzlesRefs {
    final manager = $$PuzzlesTableTableManager($_db, $_db.puzzles)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_puzzlesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PuzzleCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleCategoriesTable> {
  $$PuzzleCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> puzzlesRefs(
      Expression<bool> Function($$PuzzlesTableFilterComposer f) f) {
    final $$PuzzlesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.puzzles,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableFilterComposer(
              $db: $db,
              $table: $db.puzzles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PuzzleCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleCategoriesTable> {
  $$PuzzleCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$PuzzleCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleCategoriesTable> {
  $$PuzzleCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> puzzlesRefs<T extends Object>(
      Expression<T> Function($$PuzzlesTableAnnotationComposer a) f) {
    final $$PuzzlesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.puzzles,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PuzzleCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PuzzleCategoriesTable,
    PuzzleCategory,
    $$PuzzleCategoriesTableFilterComposer,
    $$PuzzleCategoriesTableOrderingComposer,
    $$PuzzleCategoriesTableAnnotationComposer,
    $$PuzzleCategoriesTableCreateCompanionBuilder,
    $$PuzzleCategoriesTableUpdateCompanionBuilder,
    (PuzzleCategory, $$PuzzleCategoriesTableReferences),
    PuzzleCategory,
    PrefetchHooks Function({bool puzzlesRefs})> {
  $$PuzzleCategoriesTableTableManager(
      _$AppDatabase db, $PuzzleCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              PuzzleCategoriesCompanion(
            id: id,
            name: name,
            description: description,
            iconName: iconName,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String description,
            required String iconName,
            required int sortOrder,
          }) =>
              PuzzleCategoriesCompanion.insert(
            id: id,
            name: name,
            description: description,
            iconName: iconName,
            sortOrder: sortOrder,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PuzzleCategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({puzzlesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (puzzlesRefs) db.puzzles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (puzzlesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$PuzzleCategoriesTableReferences
                            ._puzzlesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PuzzleCategoriesTableReferences(db, table, p0)
                                .puzzlesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PuzzleCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PuzzleCategoriesTable,
    PuzzleCategory,
    $$PuzzleCategoriesTableFilterComposer,
    $$PuzzleCategoriesTableOrderingComposer,
    $$PuzzleCategoriesTableAnnotationComposer,
    $$PuzzleCategoriesTableCreateCompanionBuilder,
    $$PuzzleCategoriesTableUpdateCompanionBuilder,
    (PuzzleCategory, $$PuzzleCategoriesTableReferences),
    PuzzleCategory,
    PrefetchHooks Function({bool puzzlesRefs})>;
typedef $$PuzzlesTableCreateCompanionBuilder = PuzzlesCompanion Function({
  Value<int> id,
  required int categoryId,
  required String name,
  required String description,
  required String difficulty,
  required int orderInCategory,
  required String gameData,
  Value<bool> isLocked,
  Value<int> requiredScore,
});
typedef $$PuzzlesTableUpdateCompanionBuilder = PuzzlesCompanion Function({
  Value<int> id,
  Value<int> categoryId,
  Value<String> name,
  Value<String> description,
  Value<String> difficulty,
  Value<int> orderInCategory,
  Value<String> gameData,
  Value<bool> isLocked,
  Value<int> requiredScore,
});

final class $$PuzzlesTableReferences
    extends BaseReferences<_$AppDatabase, $PuzzlesTable, Puzzle> {
  $$PuzzlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PuzzleCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.puzzleCategories.createAlias(
          $_aliasNameGenerator(db.puzzles.categoryId, db.puzzleCategories.id));

  $$PuzzleCategoriesTableProcessedTableManager get categoryId {
    final manager =
        $$PuzzleCategoriesTableTableManager($_db, $_db.puzzleCategories)
            .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$UserProgressTable, List<UserProgressData>>
      _userProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.userProgress,
          aliasName:
              $_aliasNameGenerator(db.puzzles.id, db.userProgress.puzzleId));

  $$UserProgressTableProcessedTableManager get userProgressRefs {
    final manager = $$UserProgressTableTableManager($_db, $_db.userProgress)
        .filter((f) => f.puzzleId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_userProgressRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PuzzlesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderInCategory => $composableBuilder(
      column: $table.orderInCategory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameData => $composableBuilder(
      column: $table.gameData, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requiredScore => $composableBuilder(
      column: $table.requiredScore, builder: (column) => ColumnFilters(column));

  $$PuzzleCategoriesTableFilterComposer get categoryId {
    final $$PuzzleCategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.puzzleCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzleCategoriesTableFilterComposer(
              $db: $db,
              $table: $db.puzzleCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> userProgressRefs(
      Expression<bool> Function($$UserProgressTableFilterComposer f) f) {
    final $$UserProgressTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userProgress,
        getReferencedColumn: (t) => t.puzzleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserProgressTableFilterComposer(
              $db: $db,
              $table: $db.userProgress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PuzzlesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderInCategory => $composableBuilder(
      column: $table.orderInCategory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameData => $composableBuilder(
      column: $table.gameData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLocked => $composableBuilder(
      column: $table.isLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requiredScore => $composableBuilder(
      column: $table.requiredScore,
      builder: (column) => ColumnOrderings(column));

  $$PuzzleCategoriesTableOrderingComposer get categoryId {
    final $$PuzzleCategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.puzzleCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzleCategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.puzzleCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PuzzlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzlesTable> {
  $$PuzzlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get orderInCategory => $composableBuilder(
      column: $table.orderInCategory, builder: (column) => column);

  GeneratedColumn<String> get gameData =>
      $composableBuilder(column: $table.gameData, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<int> get requiredScore => $composableBuilder(
      column: $table.requiredScore, builder: (column) => column);

  $$PuzzleCategoriesTableAnnotationComposer get categoryId {
    final $$PuzzleCategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.puzzleCategories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzleCategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzleCategories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> userProgressRefs<T extends Object>(
      Expression<T> Function($$UserProgressTableAnnotationComposer a) f) {
    final $$UserProgressTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userProgress,
        getReferencedColumn: (t) => t.puzzleId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserProgressTableAnnotationComposer(
              $db: $db,
              $table: $db.userProgress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PuzzlesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PuzzlesTable,
    Puzzle,
    $$PuzzlesTableFilterComposer,
    $$PuzzlesTableOrderingComposer,
    $$PuzzlesTableAnnotationComposer,
    $$PuzzlesTableCreateCompanionBuilder,
    $$PuzzlesTableUpdateCompanionBuilder,
    (Puzzle, $$PuzzlesTableReferences),
    Puzzle,
    PrefetchHooks Function({bool categoryId, bool userProgressRefs})> {
  $$PuzzlesTableTableManager(_$AppDatabase db, $PuzzlesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<int> orderInCategory = const Value.absent(),
            Value<String> gameData = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<int> requiredScore = const Value.absent(),
          }) =>
              PuzzlesCompanion(
            id: id,
            categoryId: categoryId,
            name: name,
            description: description,
            difficulty: difficulty,
            orderInCategory: orderInCategory,
            gameData: gameData,
            isLocked: isLocked,
            requiredScore: requiredScore,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int categoryId,
            required String name,
            required String description,
            required String difficulty,
            required int orderInCategory,
            required String gameData,
            Value<bool> isLocked = const Value.absent(),
            Value<int> requiredScore = const Value.absent(),
          }) =>
              PuzzlesCompanion.insert(
            id: id,
            categoryId: categoryId,
            name: name,
            description: description,
            difficulty: difficulty,
            orderInCategory: orderInCategory,
            gameData: gameData,
            isLocked: isLocked,
            requiredScore: requiredScore,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PuzzlesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false, userProgressRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (userProgressRefs) db.userProgress],
              addJoins: <
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
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$PuzzlesTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$PuzzlesTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userProgressRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$PuzzlesTableReferences._userProgressRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PuzzlesTableReferences(db, table, p0)
                                .userProgressRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.puzzleId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PuzzlesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PuzzlesTable,
    Puzzle,
    $$PuzzlesTableFilterComposer,
    $$PuzzlesTableOrderingComposer,
    $$PuzzlesTableAnnotationComposer,
    $$PuzzlesTableCreateCompanionBuilder,
    $$PuzzlesTableUpdateCompanionBuilder,
    (Puzzle, $$PuzzlesTableReferences),
    Puzzle,
    PrefetchHooks Function({bool categoryId, bool userProgressRefs})>;
typedef $$UserProgressTableCreateCompanionBuilder = UserProgressCompanion
    Function({
  Value<int> id,
  required int puzzleId,
  Value<int> level,
  Value<int> stars,
  Value<int> score,
  Value<int> hintsUsed,
  Value<int> timeSpentSeconds,
  Value<DateTime?> lastPlayedAt,
  Value<bool> isCompleted,
});
typedef $$UserProgressTableUpdateCompanionBuilder = UserProgressCompanion
    Function({
  Value<int> id,
  Value<int> puzzleId,
  Value<int> level,
  Value<int> stars,
  Value<int> score,
  Value<int> hintsUsed,
  Value<int> timeSpentSeconds,
  Value<DateTime?> lastPlayedAt,
  Value<bool> isCompleted,
});

final class $$UserProgressTableReferences extends BaseReferences<_$AppDatabase,
    $UserProgressTable, UserProgressData> {
  $$UserProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PuzzlesTable _puzzleIdTable(_$AppDatabase db) =>
      db.puzzles.createAlias(
          $_aliasNameGenerator(db.userProgress.puzzleId, db.puzzles.id));

  $$PuzzlesTableProcessedTableManager get puzzleId {
    final manager = $$PuzzlesTableTableManager($_db, $_db.puzzles)
        .filter((f) => f.id($_item.puzzleId!));
    final item = $_typedResult.readTableOrNull(_puzzleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stars => $composableBuilder(
      column: $table.stars, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hintsUsed => $composableBuilder(
      column: $table.hintsUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  $$PuzzlesTableFilterComposer get puzzleId {
    final $$PuzzlesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableFilterComposer(
              $db: $db,
              $table: $db.puzzles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stars => $composableBuilder(
      column: $table.stars, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
      column: $table.hintsUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  $$PuzzlesTableOrderingComposer get puzzleId {
    final $$PuzzlesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableOrderingComposer(
              $db: $db,
              $table: $db.puzzles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get timeSpentSeconds => $composableBuilder(
      column: $table.timeSpentSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  $$PuzzlesTableAnnotationComposer get puzzleId {
    final $$PuzzlesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.puzzleId,
        referencedTable: $db.puzzles,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PuzzlesTableAnnotationComposer(
              $db: $db,
              $table: $db.puzzles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProgressTable,
    UserProgressData,
    $$UserProgressTableFilterComposer,
    $$UserProgressTableOrderingComposer,
    $$UserProgressTableAnnotationComposer,
    $$UserProgressTableCreateCompanionBuilder,
    $$UserProgressTableUpdateCompanionBuilder,
    (UserProgressData, $$UserProgressTableReferences),
    UserProgressData,
    PrefetchHooks Function({bool puzzleId})> {
  $$UserProgressTableTableManager(_$AppDatabase db, $UserProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> puzzleId = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> stars = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<int> hintsUsed = const Value.absent(),
            Value<int> timeSpentSeconds = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
          }) =>
              UserProgressCompanion(
            id: id,
            puzzleId: puzzleId,
            level: level,
            stars: stars,
            score: score,
            hintsUsed: hintsUsed,
            timeSpentSeconds: timeSpentSeconds,
            lastPlayedAt: lastPlayedAt,
            isCompleted: isCompleted,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int puzzleId,
            Value<int> level = const Value.absent(),
            Value<int> stars = const Value.absent(),
            Value<int> score = const Value.absent(),
            Value<int> hintsUsed = const Value.absent(),
            Value<int> timeSpentSeconds = const Value.absent(),
            Value<DateTime?> lastPlayedAt = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
          }) =>
              UserProgressCompanion.insert(
            id: id,
            puzzleId: puzzleId,
            level: level,
            stars: stars,
            score: score,
            hintsUsed: hintsUsed,
            timeSpentSeconds: timeSpentSeconds,
            lastPlayedAt: lastPlayedAt,
            isCompleted: isCompleted,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserProgressTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({puzzleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (puzzleId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.puzzleId,
                    referencedTable:
                        $$UserProgressTableReferences._puzzleIdTable(db),
                    referencedColumn:
                        $$UserProgressTableReferences._puzzleIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProgressTable,
    UserProgressData,
    $$UserProgressTableFilterComposer,
    $$UserProgressTableOrderingComposer,
    $$UserProgressTableAnnotationComposer,
    $$UserProgressTableCreateCompanionBuilder,
    $$UserProgressTableUpdateCompanionBuilder,
    (UserProgressData, $$UserProgressTableReferences),
    UserProgressData,
    PrefetchHooks Function({bool puzzleId})>;
typedef $$AchievementsTableCreateCompanionBuilder = AchievementsCompanion
    Function({
  Value<int> id,
  required String name,
  required String description,
  required String iconName,
  required String type,
  required int requirement,
  Value<String?> reward,
});
typedef $$AchievementsTableUpdateCompanionBuilder = AchievementsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> description,
  Value<String> iconName,
  Value<String> type,
  Value<int> requirement,
  Value<String?> reward,
});

final class $$AchievementsTableReferences
    extends BaseReferences<_$AppDatabase, $AchievementsTable, Achievement> {
  $$AchievementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserAchievementsTable, List<UserAchievement>>
      _userAchievementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.userAchievements,
              aliasName: $_aliasNameGenerator(
                  db.achievements.id, db.userAchievements.achievementId));

  $$UserAchievementsTableProcessedTableManager get userAchievementsRefs {
    final manager =
        $$UserAchievementsTableTableManager($_db, $_db.userAchievements)
            .filter((f) => f.achievementId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_userAchievementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requirement => $composableBuilder(
      column: $table.requirement, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reward => $composableBuilder(
      column: $table.reward, builder: (column) => ColumnFilters(column));

  Expression<bool> userAchievementsRefs(
      Expression<bool> Function($$UserAchievementsTableFilterComposer f) f) {
    final $$UserAchievementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userAchievements,
        getReferencedColumn: (t) => t.achievementId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserAchievementsTableFilterComposer(
              $db: $db,
              $table: $db.userAchievements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requirement => $composableBuilder(
      column: $table.requirement, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reward => $composableBuilder(
      column: $table.reward, builder: (column) => ColumnOrderings(column));
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get requirement => $composableBuilder(
      column: $table.requirement, builder: (column) => column);

  GeneratedColumn<String> get reward =>
      $composableBuilder(column: $table.reward, builder: (column) => column);

  Expression<T> userAchievementsRefs<T extends Object>(
      Expression<T> Function($$UserAchievementsTableAnnotationComposer a) f) {
    final $$UserAchievementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userAchievements,
        getReferencedColumn: (t) => t.achievementId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserAchievementsTableAnnotationComposer(
              $db: $db,
              $table: $db.userAchievements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AchievementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AchievementsTable,
    Achievement,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (Achievement, $$AchievementsTableReferences),
    Achievement,
    PrefetchHooks Function({bool userAchievementsRefs})> {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> requirement = const Value.absent(),
            Value<String?> reward = const Value.absent(),
          }) =>
              AchievementsCompanion(
            id: id,
            name: name,
            description: description,
            iconName: iconName,
            type: type,
            requirement: requirement,
            reward: reward,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String description,
            required String iconName,
            required String type,
            required int requirement,
            Value<String?> reward = const Value.absent(),
          }) =>
              AchievementsCompanion.insert(
            id: id,
            name: name,
            description: description,
            iconName: iconName,
            type: type,
            requirement: requirement,
            reward: reward,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AchievementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userAchievementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userAchievementsRefs) db.userAchievements
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userAchievementsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$AchievementsTableReferences
                            ._userAchievementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AchievementsTableReferences(db, table, p0)
                                .userAchievementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.achievementId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AchievementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AchievementsTable,
    Achievement,
    $$AchievementsTableFilterComposer,
    $$AchievementsTableOrderingComposer,
    $$AchievementsTableAnnotationComposer,
    $$AchievementsTableCreateCompanionBuilder,
    $$AchievementsTableUpdateCompanionBuilder,
    (Achievement, $$AchievementsTableReferences),
    Achievement,
    PrefetchHooks Function({bool userAchievementsRefs})>;
typedef $$UserAchievementsTableCreateCompanionBuilder
    = UserAchievementsCompanion Function({
  Value<int> id,
  required int achievementId,
  required DateTime unlockedAt,
  Value<bool> isCollected,
});
typedef $$UserAchievementsTableUpdateCompanionBuilder
    = UserAchievementsCompanion Function({
  Value<int> id,
  Value<int> achievementId,
  Value<DateTime> unlockedAt,
  Value<bool> isCollected,
});

final class $$UserAchievementsTableReferences extends BaseReferences<
    _$AppDatabase, $UserAchievementsTable, UserAchievement> {
  $$UserAchievementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AchievementsTable _achievementIdTable(_$AppDatabase db) =>
      db.achievements.createAlias($_aliasNameGenerator(
          db.userAchievements.achievementId, db.achievements.id));

  $$AchievementsTableProcessedTableManager get achievementId {
    final manager = $$AchievementsTableTableManager($_db, $_db.achievements)
        .filter((f) => f.id($_item.achievementId!));
    final item = $_typedResult.readTableOrNull(_achievementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserAchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $UserAchievementsTable> {
  $$UserAchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCollected => $composableBuilder(
      column: $table.isCollected, builder: (column) => ColumnFilters(column));

  $$AchievementsTableFilterComposer get achievementId {
    final $$AchievementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.achievementId,
        referencedTable: $db.achievements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AchievementsTableFilterComposer(
              $db: $db,
              $table: $db.achievements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserAchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserAchievementsTable> {
  $$UserAchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCollected => $composableBuilder(
      column: $table.isCollected, builder: (column) => ColumnOrderings(column));

  $$AchievementsTableOrderingComposer get achievementId {
    final $$AchievementsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.achievementId,
        referencedTable: $db.achievements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AchievementsTableOrderingComposer(
              $db: $db,
              $table: $db.achievements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserAchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserAchievementsTable> {
  $$UserAchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCollected => $composableBuilder(
      column: $table.isCollected, builder: (column) => column);

  $$AchievementsTableAnnotationComposer get achievementId {
    final $$AchievementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.achievementId,
        referencedTable: $db.achievements,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AchievementsTableAnnotationComposer(
              $db: $db,
              $table: $db.achievements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserAchievementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserAchievementsTable,
    UserAchievement,
    $$UserAchievementsTableFilterComposer,
    $$UserAchievementsTableOrderingComposer,
    $$UserAchievementsTableAnnotationComposer,
    $$UserAchievementsTableCreateCompanionBuilder,
    $$UserAchievementsTableUpdateCompanionBuilder,
    (UserAchievement, $$UserAchievementsTableReferences),
    UserAchievement,
    PrefetchHooks Function({bool achievementId})> {
  $$UserAchievementsTableTableManager(
      _$AppDatabase db, $UserAchievementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserAchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserAchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserAchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> achievementId = const Value.absent(),
            Value<DateTime> unlockedAt = const Value.absent(),
            Value<bool> isCollected = const Value.absent(),
          }) =>
              UserAchievementsCompanion(
            id: id,
            achievementId: achievementId,
            unlockedAt: unlockedAt,
            isCollected: isCollected,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int achievementId,
            required DateTime unlockedAt,
            Value<bool> isCollected = const Value.absent(),
          }) =>
              UserAchievementsCompanion.insert(
            id: id,
            achievementId: achievementId,
            unlockedAt: unlockedAt,
            isCollected: isCollected,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserAchievementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({achievementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (achievementId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.achievementId,
                    referencedTable: $$UserAchievementsTableReferences
                        ._achievementIdTable(db),
                    referencedColumn: $$UserAchievementsTableReferences
                        ._achievementIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserAchievementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserAchievementsTable,
    UserAchievement,
    $$UserAchievementsTableFilterComposer,
    $$UserAchievementsTableOrderingComposer,
    $$UserAchievementsTableAnnotationComposer,
    $$UserAchievementsTableCreateCompanionBuilder,
    $$UserAchievementsTableUpdateCompanionBuilder,
    (UserAchievement, $$UserAchievementsTableReferences),
    UserAchievement,
    PrefetchHooks Function({bool achievementId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
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

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PuzzleCategoriesTableTableManager get puzzleCategories =>
      $$PuzzleCategoriesTableTableManager(_db, _db.puzzleCategories);
  $$PuzzlesTableTableManager get puzzles =>
      $$PuzzlesTableTableManager(_db, _db.puzzles);
  $$UserProgressTableTableManager get userProgress =>
      $$UserProgressTableTableManager(_db, _db.userProgress);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$UserAchievementsTableTableManager get userAchievements =>
      $$UserAchievementsTableTableManager(_db, _db.userAchievements);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
