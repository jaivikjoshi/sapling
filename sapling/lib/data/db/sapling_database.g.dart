// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sapling_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('singleton'),
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cad'),
  );
  static const VerificationMeta _rolloverResetTypeMeta = const VerificationMeta(
    'rolloverResetType',
  );
  @override
  late final GeneratedColumn<String> rolloverResetType =
      GeneratedColumn<String>(
        'rollover_reset_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('monthly'),
      );
  static const VerificationMeta _spendingBaselineDaysMeta =
      const VerificationMeta('spendingBaselineDays');
  @override
  late final GeneratedColumn<int> spendingBaselineDays = GeneratedColumn<int>(
    'spending_baseline_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _allowanceDefaultModeMeta =
      const VerificationMeta('allowanceDefaultMode');
  @override
  late final GeneratedColumn<String> allowanceDefaultMode =
      GeneratedColumn<String>(
        'allowance_default_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('paycheck'),
      );
  static const VerificationMeta _primaryGoalIdMeta = const VerificationMeta(
    'primaryGoalId',
  );
  @override
  late final GeneratedColumn<String> primaryGoalId = GeneratedColumn<String>(
    'primary_goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paydayAnchorRecurringIncomeIdMeta =
      const VerificationMeta('paydayAnchorRecurringIncomeId');
  @override
  late final GeneratedColumn<String> paydayAnchorRecurringIncomeId =
      GeneratedColumn<String>(
        'payday_anchor_recurring_income_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _defaultPaydayBehaviorMeta =
      const VerificationMeta('defaultPaydayBehavior');
  @override
  late final GeneratedColumn<String> defaultPaydayBehavior =
      GeneratedColumn<String>(
        'default_payday_behavior',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('confirm_actual_on_payday'),
      );
  static const VerificationMeta _paydayEnabledMeta = const VerificationMeta(
    'paydayEnabled',
  );
  @override
  late final GeneratedColumn<bool> paydayEnabled = GeneratedColumn<bool>(
    'payday_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("payday_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _billsEnabledMeta = const VerificationMeta(
    'billsEnabled',
  );
  @override
  late final GeneratedColumn<bool> billsEnabled = GeneratedColumn<bool>(
    'bills_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bills_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _overspendEnabledMeta = const VerificationMeta(
    'overspendEnabled',
  );
  @override
  late final GeneratedColumn<bool> overspendEnabled = GeneratedColumn<bool>(
    'overspend_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("overspend_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cycleResetEnabledMeta = const VerificationMeta(
    'cycleResetEnabled',
  );
  @override
  late final GeneratedColumn<bool> cycleResetEnabled = GeneratedColumn<bool>(
    'cycle_reset_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cycle_reset_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nightlyCloseoutEnabledMeta =
      const VerificationMeta('nightlyCloseoutEnabled');
  @override
  late final GeneratedColumn<bool> nightlyCloseoutEnabled =
      GeneratedColumn<bool>(
        'nightly_closeout_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("nightly_closeout_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _nightlyCloseoutTimeMeta =
      const VerificationMeta('nightlyCloseoutTime');
  @override
  late final GeneratedColumn<String> nightlyCloseoutTime =
      GeneratedColumn<String>(
        'nightly_closeout_time',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('21:00'),
      );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseCurrency,
    rolloverResetType,
    spendingBaselineDays,
    allowanceDefaultMode,
    primaryGoalId,
    paydayAnchorRecurringIncomeId,
    defaultPaydayBehavior,
    paydayEnabled,
    billsEnabled,
    overspendEnabled,
    cycleResetEnabled,
    nightlyCloseoutEnabled,
    nightlyCloseoutTime,
    onboardingCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('rollover_reset_type')) {
      context.handle(
        _rolloverResetTypeMeta,
        rolloverResetType.isAcceptableOrUnknown(
          data['rollover_reset_type']!,
          _rolloverResetTypeMeta,
        ),
      );
    }
    if (data.containsKey('spending_baseline_days')) {
      context.handle(
        _spendingBaselineDaysMeta,
        spendingBaselineDays.isAcceptableOrUnknown(
          data['spending_baseline_days']!,
          _spendingBaselineDaysMeta,
        ),
      );
    }
    if (data.containsKey('allowance_default_mode')) {
      context.handle(
        _allowanceDefaultModeMeta,
        allowanceDefaultMode.isAcceptableOrUnknown(
          data['allowance_default_mode']!,
          _allowanceDefaultModeMeta,
        ),
      );
    }
    if (data.containsKey('primary_goal_id')) {
      context.handle(
        _primaryGoalIdMeta,
        primaryGoalId.isAcceptableOrUnknown(
          data['primary_goal_id']!,
          _primaryGoalIdMeta,
        ),
      );
    }
    if (data.containsKey('payday_anchor_recurring_income_id')) {
      context.handle(
        _paydayAnchorRecurringIncomeIdMeta,
        paydayAnchorRecurringIncomeId.isAcceptableOrUnknown(
          data['payday_anchor_recurring_income_id']!,
          _paydayAnchorRecurringIncomeIdMeta,
        ),
      );
    }
    if (data.containsKey('default_payday_behavior')) {
      context.handle(
        _defaultPaydayBehaviorMeta,
        defaultPaydayBehavior.isAcceptableOrUnknown(
          data['default_payday_behavior']!,
          _defaultPaydayBehaviorMeta,
        ),
      );
    }
    if (data.containsKey('payday_enabled')) {
      context.handle(
        _paydayEnabledMeta,
        paydayEnabled.isAcceptableOrUnknown(
          data['payday_enabled']!,
          _paydayEnabledMeta,
        ),
      );
    }
    if (data.containsKey('bills_enabled')) {
      context.handle(
        _billsEnabledMeta,
        billsEnabled.isAcceptableOrUnknown(
          data['bills_enabled']!,
          _billsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('overspend_enabled')) {
      context.handle(
        _overspendEnabledMeta,
        overspendEnabled.isAcceptableOrUnknown(
          data['overspend_enabled']!,
          _overspendEnabledMeta,
        ),
      );
    }
    if (data.containsKey('cycle_reset_enabled')) {
      context.handle(
        _cycleResetEnabledMeta,
        cycleResetEnabled.isAcceptableOrUnknown(
          data['cycle_reset_enabled']!,
          _cycleResetEnabledMeta,
        ),
      );
    }
    if (data.containsKey('nightly_closeout_enabled')) {
      context.handle(
        _nightlyCloseoutEnabledMeta,
        nightlyCloseoutEnabled.isAcceptableOrUnknown(
          data['nightly_closeout_enabled']!,
          _nightlyCloseoutEnabledMeta,
        ),
      );
    }
    if (data.containsKey('nightly_closeout_time')) {
      context.handle(
        _nightlyCloseoutTimeMeta,
        nightlyCloseoutTime.isAcceptableOrUnknown(
          data['nightly_closeout_time']!,
          _nightlyCloseoutTimeMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      baseCurrency:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}base_currency'],
          )!,
      rolloverResetType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}rollover_reset_type'],
          )!,
      spendingBaselineDays:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}spending_baseline_days'],
          )!,
      allowanceDefaultMode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}allowance_default_mode'],
          )!,
      primaryGoalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_goal_id'],
      ),
      paydayAnchorRecurringIncomeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payday_anchor_recurring_income_id'],
      ),
      defaultPaydayBehavior:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}default_payday_behavior'],
          )!,
      paydayEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}payday_enabled'],
          )!,
      billsEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}bills_enabled'],
          )!,
      overspendEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}overspend_enabled'],
          )!,
      cycleResetEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}cycle_reset_enabled'],
          )!,
      nightlyCloseoutEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}nightly_closeout_enabled'],
          )!,
      nightlyCloseoutTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nightly_closeout_time'],
          )!,
      onboardingCompleted:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}onboarding_completed'],
          )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String id;
  final String baseCurrency;
  final String rolloverResetType;
  final int spendingBaselineDays;
  final String allowanceDefaultMode;
  final String? primaryGoalId;
  final String? paydayAnchorRecurringIncomeId;
  final String defaultPaydayBehavior;
  final bool paydayEnabled;
  final bool billsEnabled;
  final bool overspendEnabled;
  final bool cycleResetEnabled;
  final bool nightlyCloseoutEnabled;
  final String nightlyCloseoutTime;
  final bool onboardingCompleted;
  const AppSetting({
    required this.id,
    required this.baseCurrency,
    required this.rolloverResetType,
    required this.spendingBaselineDays,
    required this.allowanceDefaultMode,
    this.primaryGoalId,
    this.paydayAnchorRecurringIncomeId,
    required this.defaultPaydayBehavior,
    required this.paydayEnabled,
    required this.billsEnabled,
    required this.overspendEnabled,
    required this.cycleResetEnabled,
    required this.nightlyCloseoutEnabled,
    required this.nightlyCloseoutTime,
    required this.onboardingCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['rollover_reset_type'] = Variable<String>(rolloverResetType);
    map['spending_baseline_days'] = Variable<int>(spendingBaselineDays);
    map['allowance_default_mode'] = Variable<String>(allowanceDefaultMode);
    if (!nullToAbsent || primaryGoalId != null) {
      map['primary_goal_id'] = Variable<String>(primaryGoalId);
    }
    if (!nullToAbsent || paydayAnchorRecurringIncomeId != null) {
      map['payday_anchor_recurring_income_id'] = Variable<String>(
        paydayAnchorRecurringIncomeId,
      );
    }
    map['default_payday_behavior'] = Variable<String>(defaultPaydayBehavior);
    map['payday_enabled'] = Variable<bool>(paydayEnabled);
    map['bills_enabled'] = Variable<bool>(billsEnabled);
    map['overspend_enabled'] = Variable<bool>(overspendEnabled);
    map['cycle_reset_enabled'] = Variable<bool>(cycleResetEnabled);
    map['nightly_closeout_enabled'] = Variable<bool>(nightlyCloseoutEnabled);
    map['nightly_closeout_time'] = Variable<String>(nightlyCloseoutTime);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      baseCurrency: Value(baseCurrency),
      rolloverResetType: Value(rolloverResetType),
      spendingBaselineDays: Value(spendingBaselineDays),
      allowanceDefaultMode: Value(allowanceDefaultMode),
      primaryGoalId:
          primaryGoalId == null && nullToAbsent
              ? const Value.absent()
              : Value(primaryGoalId),
      paydayAnchorRecurringIncomeId:
          paydayAnchorRecurringIncomeId == null && nullToAbsent
              ? const Value.absent()
              : Value(paydayAnchorRecurringIncomeId),
      defaultPaydayBehavior: Value(defaultPaydayBehavior),
      paydayEnabled: Value(paydayEnabled),
      billsEnabled: Value(billsEnabled),
      overspendEnabled: Value(overspendEnabled),
      cycleResetEnabled: Value(cycleResetEnabled),
      nightlyCloseoutEnabled: Value(nightlyCloseoutEnabled),
      nightlyCloseoutTime: Value(nightlyCloseoutTime),
      onboardingCompleted: Value(onboardingCompleted),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<String>(json['id']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      rolloverResetType: serializer.fromJson<String>(json['rolloverResetType']),
      spendingBaselineDays: serializer.fromJson<int>(
        json['spendingBaselineDays'],
      ),
      allowanceDefaultMode: serializer.fromJson<String>(
        json['allowanceDefaultMode'],
      ),
      primaryGoalId: serializer.fromJson<String?>(json['primaryGoalId']),
      paydayAnchorRecurringIncomeId: serializer.fromJson<String?>(
        json['paydayAnchorRecurringIncomeId'],
      ),
      defaultPaydayBehavior: serializer.fromJson<String>(
        json['defaultPaydayBehavior'],
      ),
      paydayEnabled: serializer.fromJson<bool>(json['paydayEnabled']),
      billsEnabled: serializer.fromJson<bool>(json['billsEnabled']),
      overspendEnabled: serializer.fromJson<bool>(json['overspendEnabled']),
      cycleResetEnabled: serializer.fromJson<bool>(json['cycleResetEnabled']),
      nightlyCloseoutEnabled: serializer.fromJson<bool>(
        json['nightlyCloseoutEnabled'],
      ),
      nightlyCloseoutTime: serializer.fromJson<String>(
        json['nightlyCloseoutTime'],
      ),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'rolloverResetType': serializer.toJson<String>(rolloverResetType),
      'spendingBaselineDays': serializer.toJson<int>(spendingBaselineDays),
      'allowanceDefaultMode': serializer.toJson<String>(allowanceDefaultMode),
      'primaryGoalId': serializer.toJson<String?>(primaryGoalId),
      'paydayAnchorRecurringIncomeId': serializer.toJson<String?>(
        paydayAnchorRecurringIncomeId,
      ),
      'defaultPaydayBehavior': serializer.toJson<String>(defaultPaydayBehavior),
      'paydayEnabled': serializer.toJson<bool>(paydayEnabled),
      'billsEnabled': serializer.toJson<bool>(billsEnabled),
      'overspendEnabled': serializer.toJson<bool>(overspendEnabled),
      'cycleResetEnabled': serializer.toJson<bool>(cycleResetEnabled),
      'nightlyCloseoutEnabled': serializer.toJson<bool>(nightlyCloseoutEnabled),
      'nightlyCloseoutTime': serializer.toJson<String>(nightlyCloseoutTime),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
    };
  }

  AppSetting copyWith({
    String? id,
    String? baseCurrency,
    String? rolloverResetType,
    int? spendingBaselineDays,
    String? allowanceDefaultMode,
    Value<String?> primaryGoalId = const Value.absent(),
    Value<String?> paydayAnchorRecurringIncomeId = const Value.absent(),
    String? defaultPaydayBehavior,
    bool? paydayEnabled,
    bool? billsEnabled,
    bool? overspendEnabled,
    bool? cycleResetEnabled,
    bool? nightlyCloseoutEnabled,
    String? nightlyCloseoutTime,
    bool? onboardingCompleted,
  }) => AppSetting(
    id: id ?? this.id,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    rolloverResetType: rolloverResetType ?? this.rolloverResetType,
    spendingBaselineDays: spendingBaselineDays ?? this.spendingBaselineDays,
    allowanceDefaultMode: allowanceDefaultMode ?? this.allowanceDefaultMode,
    primaryGoalId:
        primaryGoalId.present ? primaryGoalId.value : this.primaryGoalId,
    paydayAnchorRecurringIncomeId:
        paydayAnchorRecurringIncomeId.present
            ? paydayAnchorRecurringIncomeId.value
            : this.paydayAnchorRecurringIncomeId,
    defaultPaydayBehavior: defaultPaydayBehavior ?? this.defaultPaydayBehavior,
    paydayEnabled: paydayEnabled ?? this.paydayEnabled,
    billsEnabled: billsEnabled ?? this.billsEnabled,
    overspendEnabled: overspendEnabled ?? this.overspendEnabled,
    cycleResetEnabled: cycleResetEnabled ?? this.cycleResetEnabled,
    nightlyCloseoutEnabled:
        nightlyCloseoutEnabled ?? this.nightlyCloseoutEnabled,
    nightlyCloseoutTime: nightlyCloseoutTime ?? this.nightlyCloseoutTime,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      baseCurrency:
          data.baseCurrency.present
              ? data.baseCurrency.value
              : this.baseCurrency,
      rolloverResetType:
          data.rolloverResetType.present
              ? data.rolloverResetType.value
              : this.rolloverResetType,
      spendingBaselineDays:
          data.spendingBaselineDays.present
              ? data.spendingBaselineDays.value
              : this.spendingBaselineDays,
      allowanceDefaultMode:
          data.allowanceDefaultMode.present
              ? data.allowanceDefaultMode.value
              : this.allowanceDefaultMode,
      primaryGoalId:
          data.primaryGoalId.present
              ? data.primaryGoalId.value
              : this.primaryGoalId,
      paydayAnchorRecurringIncomeId:
          data.paydayAnchorRecurringIncomeId.present
              ? data.paydayAnchorRecurringIncomeId.value
              : this.paydayAnchorRecurringIncomeId,
      defaultPaydayBehavior:
          data.defaultPaydayBehavior.present
              ? data.defaultPaydayBehavior.value
              : this.defaultPaydayBehavior,
      paydayEnabled:
          data.paydayEnabled.present
              ? data.paydayEnabled.value
              : this.paydayEnabled,
      billsEnabled:
          data.billsEnabled.present
              ? data.billsEnabled.value
              : this.billsEnabled,
      overspendEnabled:
          data.overspendEnabled.present
              ? data.overspendEnabled.value
              : this.overspendEnabled,
      cycleResetEnabled:
          data.cycleResetEnabled.present
              ? data.cycleResetEnabled.value
              : this.cycleResetEnabled,
      nightlyCloseoutEnabled:
          data.nightlyCloseoutEnabled.present
              ? data.nightlyCloseoutEnabled.value
              : this.nightlyCloseoutEnabled,
      nightlyCloseoutTime:
          data.nightlyCloseoutTime.present
              ? data.nightlyCloseoutTime.value
              : this.nightlyCloseoutTime,
      onboardingCompleted:
          data.onboardingCompleted.present
              ? data.onboardingCompleted.value
              : this.onboardingCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('rolloverResetType: $rolloverResetType, ')
          ..write('spendingBaselineDays: $spendingBaselineDays, ')
          ..write('allowanceDefaultMode: $allowanceDefaultMode, ')
          ..write('primaryGoalId: $primaryGoalId, ')
          ..write(
            'paydayAnchorRecurringIncomeId: $paydayAnchorRecurringIncomeId, ',
          )
          ..write('defaultPaydayBehavior: $defaultPaydayBehavior, ')
          ..write('paydayEnabled: $paydayEnabled, ')
          ..write('billsEnabled: $billsEnabled, ')
          ..write('overspendEnabled: $overspendEnabled, ')
          ..write('cycleResetEnabled: $cycleResetEnabled, ')
          ..write('nightlyCloseoutEnabled: $nightlyCloseoutEnabled, ')
          ..write('nightlyCloseoutTime: $nightlyCloseoutTime, ')
          ..write('onboardingCompleted: $onboardingCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseCurrency,
    rolloverResetType,
    spendingBaselineDays,
    allowanceDefaultMode,
    primaryGoalId,
    paydayAnchorRecurringIncomeId,
    defaultPaydayBehavior,
    paydayEnabled,
    billsEnabled,
    overspendEnabled,
    cycleResetEnabled,
    nightlyCloseoutEnabled,
    nightlyCloseoutTime,
    onboardingCompleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.baseCurrency == this.baseCurrency &&
          other.rolloverResetType == this.rolloverResetType &&
          other.spendingBaselineDays == this.spendingBaselineDays &&
          other.allowanceDefaultMode == this.allowanceDefaultMode &&
          other.primaryGoalId == this.primaryGoalId &&
          other.paydayAnchorRecurringIncomeId ==
              this.paydayAnchorRecurringIncomeId &&
          other.defaultPaydayBehavior == this.defaultPaydayBehavior &&
          other.paydayEnabled == this.paydayEnabled &&
          other.billsEnabled == this.billsEnabled &&
          other.overspendEnabled == this.overspendEnabled &&
          other.cycleResetEnabled == this.cycleResetEnabled &&
          other.nightlyCloseoutEnabled == this.nightlyCloseoutEnabled &&
          other.nightlyCloseoutTime == this.nightlyCloseoutTime &&
          other.onboardingCompleted == this.onboardingCompleted);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> id;
  final Value<String> baseCurrency;
  final Value<String> rolloverResetType;
  final Value<int> spendingBaselineDays;
  final Value<String> allowanceDefaultMode;
  final Value<String?> primaryGoalId;
  final Value<String?> paydayAnchorRecurringIncomeId;
  final Value<String> defaultPaydayBehavior;
  final Value<bool> paydayEnabled;
  final Value<bool> billsEnabled;
  final Value<bool> overspendEnabled;
  final Value<bool> cycleResetEnabled;
  final Value<bool> nightlyCloseoutEnabled;
  final Value<String> nightlyCloseoutTime;
  final Value<bool> onboardingCompleted;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.rolloverResetType = const Value.absent(),
    this.spendingBaselineDays = const Value.absent(),
    this.allowanceDefaultMode = const Value.absent(),
    this.primaryGoalId = const Value.absent(),
    this.paydayAnchorRecurringIncomeId = const Value.absent(),
    this.defaultPaydayBehavior = const Value.absent(),
    this.paydayEnabled = const Value.absent(),
    this.billsEnabled = const Value.absent(),
    this.overspendEnabled = const Value.absent(),
    this.cycleResetEnabled = const Value.absent(),
    this.nightlyCloseoutEnabled = const Value.absent(),
    this.nightlyCloseoutTime = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.rolloverResetType = const Value.absent(),
    this.spendingBaselineDays = const Value.absent(),
    this.allowanceDefaultMode = const Value.absent(),
    this.primaryGoalId = const Value.absent(),
    this.paydayAnchorRecurringIncomeId = const Value.absent(),
    this.defaultPaydayBehavior = const Value.absent(),
    this.paydayEnabled = const Value.absent(),
    this.billsEnabled = const Value.absent(),
    this.overspendEnabled = const Value.absent(),
    this.cycleResetEnabled = const Value.absent(),
    this.nightlyCloseoutEnabled = const Value.absent(),
    this.nightlyCloseoutTime = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<String>? id,
    Expression<String>? baseCurrency,
    Expression<String>? rolloverResetType,
    Expression<int>? spendingBaselineDays,
    Expression<String>? allowanceDefaultMode,
    Expression<String>? primaryGoalId,
    Expression<String>? paydayAnchorRecurringIncomeId,
    Expression<String>? defaultPaydayBehavior,
    Expression<bool>? paydayEnabled,
    Expression<bool>? billsEnabled,
    Expression<bool>? overspendEnabled,
    Expression<bool>? cycleResetEnabled,
    Expression<bool>? nightlyCloseoutEnabled,
    Expression<String>? nightlyCloseoutTime,
    Expression<bool>? onboardingCompleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (rolloverResetType != null) 'rollover_reset_type': rolloverResetType,
      if (spendingBaselineDays != null)
        'spending_baseline_days': spendingBaselineDays,
      if (allowanceDefaultMode != null)
        'allowance_default_mode': allowanceDefaultMode,
      if (primaryGoalId != null) 'primary_goal_id': primaryGoalId,
      if (paydayAnchorRecurringIncomeId != null)
        'payday_anchor_recurring_income_id': paydayAnchorRecurringIncomeId,
      if (defaultPaydayBehavior != null)
        'default_payday_behavior': defaultPaydayBehavior,
      if (paydayEnabled != null) 'payday_enabled': paydayEnabled,
      if (billsEnabled != null) 'bills_enabled': billsEnabled,
      if (overspendEnabled != null) 'overspend_enabled': overspendEnabled,
      if (cycleResetEnabled != null) 'cycle_reset_enabled': cycleResetEnabled,
      if (nightlyCloseoutEnabled != null)
        'nightly_closeout_enabled': nightlyCloseoutEnabled,
      if (nightlyCloseoutTime != null)
        'nightly_closeout_time': nightlyCloseoutTime,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? baseCurrency,
    Value<String>? rolloverResetType,
    Value<int>? spendingBaselineDays,
    Value<String>? allowanceDefaultMode,
    Value<String?>? primaryGoalId,
    Value<String?>? paydayAnchorRecurringIncomeId,
    Value<String>? defaultPaydayBehavior,
    Value<bool>? paydayEnabled,
    Value<bool>? billsEnabled,
    Value<bool>? overspendEnabled,
    Value<bool>? cycleResetEnabled,
    Value<bool>? nightlyCloseoutEnabled,
    Value<String>? nightlyCloseoutTime,
    Value<bool>? onboardingCompleted,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      rolloverResetType: rolloverResetType ?? this.rolloverResetType,
      spendingBaselineDays: spendingBaselineDays ?? this.spendingBaselineDays,
      allowanceDefaultMode: allowanceDefaultMode ?? this.allowanceDefaultMode,
      primaryGoalId: primaryGoalId ?? this.primaryGoalId,
      paydayAnchorRecurringIncomeId:
          paydayAnchorRecurringIncomeId ?? this.paydayAnchorRecurringIncomeId,
      defaultPaydayBehavior:
          defaultPaydayBehavior ?? this.defaultPaydayBehavior,
      paydayEnabled: paydayEnabled ?? this.paydayEnabled,
      billsEnabled: billsEnabled ?? this.billsEnabled,
      overspendEnabled: overspendEnabled ?? this.overspendEnabled,
      cycleResetEnabled: cycleResetEnabled ?? this.cycleResetEnabled,
      nightlyCloseoutEnabled:
          nightlyCloseoutEnabled ?? this.nightlyCloseoutEnabled,
      nightlyCloseoutTime: nightlyCloseoutTime ?? this.nightlyCloseoutTime,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (rolloverResetType.present) {
      map['rollover_reset_type'] = Variable<String>(rolloverResetType.value);
    }
    if (spendingBaselineDays.present) {
      map['spending_baseline_days'] = Variable<int>(spendingBaselineDays.value);
    }
    if (allowanceDefaultMode.present) {
      map['allowance_default_mode'] = Variable<String>(
        allowanceDefaultMode.value,
      );
    }
    if (primaryGoalId.present) {
      map['primary_goal_id'] = Variable<String>(primaryGoalId.value);
    }
    if (paydayAnchorRecurringIncomeId.present) {
      map['payday_anchor_recurring_income_id'] = Variable<String>(
        paydayAnchorRecurringIncomeId.value,
      );
    }
    if (defaultPaydayBehavior.present) {
      map['default_payday_behavior'] = Variable<String>(
        defaultPaydayBehavior.value,
      );
    }
    if (paydayEnabled.present) {
      map['payday_enabled'] = Variable<bool>(paydayEnabled.value);
    }
    if (billsEnabled.present) {
      map['bills_enabled'] = Variable<bool>(billsEnabled.value);
    }
    if (overspendEnabled.present) {
      map['overspend_enabled'] = Variable<bool>(overspendEnabled.value);
    }
    if (cycleResetEnabled.present) {
      map['cycle_reset_enabled'] = Variable<bool>(cycleResetEnabled.value);
    }
    if (nightlyCloseoutEnabled.present) {
      map['nightly_closeout_enabled'] = Variable<bool>(
        nightlyCloseoutEnabled.value,
      );
    }
    if (nightlyCloseoutTime.present) {
      map['nightly_closeout_time'] = Variable<String>(
        nightlyCloseoutTime.value,
      );
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('rolloverResetType: $rolloverResetType, ')
          ..write('spendingBaselineDays: $spendingBaselineDays, ')
          ..write('allowanceDefaultMode: $allowanceDefaultMode, ')
          ..write('primaryGoalId: $primaryGoalId, ')
          ..write(
            'paydayAnchorRecurringIncomeId: $paydayAnchorRecurringIncomeId, ',
          )
          ..write('defaultPaydayBehavior: $defaultPaydayBehavior, ')
          ..write('paydayEnabled: $paydayEnabled, ')
          ..write('billsEnabled: $billsEnabled, ')
          ..write('overspendEnabled: $overspendEnabled, ')
          ..write('cycleResetEnabled: $cycleResetEnabled, ')
          ..write('nightlyCloseoutEnabled: $nightlyCloseoutEnabled, ')
          ..write('nightlyCloseoutTime: $nightlyCloseoutTime, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedBillIdMeta = const VerificationMeta(
    'linkedBillId',
  );
  @override
  late final GeneratedColumn<String> linkedBillId = GeneratedColumn<String>(
    'linked_bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedRecurringIncomeIdMeta =
      const VerificationMeta('linkedRecurringIncomeId');
  @override
  late final GeneratedColumn<String> linkedRecurringIncomeId =
      GeneratedColumn<String>(
        'linked_recurring_income_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _linkedSplitEntryIdMeta =
      const VerificationMeta('linkedSplitEntryId');
  @override
  late final GeneratedColumn<String> linkedSplitEntryId =
      GeneratedColumn<String>(
        'linked_split_entry_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _incomePostingTypeMeta = const VerificationMeta(
    'incomePostingType',
  );
  @override
  late final GeneratedColumn<String> incomePostingType =
      GeneratedColumn<String>(
        'income_posting_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    date,
    categoryId,
    label,
    note,
    linkedBillId,
    linkedRecurringIncomeId,
    linkedSplitEntryId,
    incomePostingType,
    source,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
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
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('linked_bill_id')) {
      context.handle(
        _linkedBillIdMeta,
        linkedBillId.isAcceptableOrUnknown(
          data['linked_bill_id']!,
          _linkedBillIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_recurring_income_id')) {
      context.handle(
        _linkedRecurringIncomeIdMeta,
        linkedRecurringIncomeId.isAcceptableOrUnknown(
          data['linked_recurring_income_id']!,
          _linkedRecurringIncomeIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_split_entry_id')) {
      context.handle(
        _linkedSplitEntryIdMeta,
        linkedSplitEntryId.isAcceptableOrUnknown(
          data['linked_split_entry_id']!,
          _linkedSplitEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('income_posting_type')) {
      context.handle(
        _incomePostingTypeMeta,
        incomePostingType.isAcceptableOrUnknown(
          data['income_posting_type']!,
          _incomePostingTypeMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      type:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}type'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}amount'],
          )!,
      date:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}date'],
          )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      linkedBillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_bill_id'],
      ),
      linkedRecurringIncomeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_recurring_income_id'],
      ),
      linkedSplitEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_split_entry_id'],
      ),
      incomePostingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_posting_type'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String? categoryId;
  final String? label;
  final String? note;
  final String? linkedBillId;
  final String? linkedRecurringIncomeId;
  final String? linkedSplitEntryId;
  final String? incomePostingType;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    this.label,
    this.note,
    this.linkedBillId,
    this.linkedRecurringIncomeId,
    this.linkedSplitEntryId,
    this.incomePostingType,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || linkedBillId != null) {
      map['linked_bill_id'] = Variable<String>(linkedBillId);
    }
    if (!nullToAbsent || linkedRecurringIncomeId != null) {
      map['linked_recurring_income_id'] = Variable<String>(
        linkedRecurringIncomeId,
      );
    }
    if (!nullToAbsent || linkedSplitEntryId != null) {
      map['linked_split_entry_id'] = Variable<String>(linkedSplitEntryId);
    }
    if (!nullToAbsent || incomePostingType != null) {
      map['income_posting_type'] = Variable<String>(incomePostingType);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      date: Value(date),
      categoryId:
          categoryId == null && nullToAbsent
              ? const Value.absent()
              : Value(categoryId),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      linkedBillId:
          linkedBillId == null && nullToAbsent
              ? const Value.absent()
              : Value(linkedBillId),
      linkedRecurringIncomeId:
          linkedRecurringIncomeId == null && nullToAbsent
              ? const Value.absent()
              : Value(linkedRecurringIncomeId),
      linkedSplitEntryId:
          linkedSplitEntryId == null && nullToAbsent
              ? const Value.absent()
              : Value(linkedSplitEntryId),
      incomePostingType:
          incomePostingType == null && nullToAbsent
              ? const Value.absent()
              : Value(incomePostingType),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      label: serializer.fromJson<String?>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
      linkedBillId: serializer.fromJson<String?>(json['linkedBillId']),
      linkedRecurringIncomeId: serializer.fromJson<String?>(
        json['linkedRecurringIncomeId'],
      ),
      linkedSplitEntryId: serializer.fromJson<String?>(
        json['linkedSplitEntryId'],
      ),
      incomePostingType: serializer.fromJson<String?>(
        json['incomePostingType'],
      ),
      source: serializer.fromJson<String?>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'categoryId': serializer.toJson<String?>(categoryId),
      'label': serializer.toJson<String?>(label),
      'note': serializer.toJson<String?>(note),
      'linkedBillId': serializer.toJson<String?>(linkedBillId),
      'linkedRecurringIncomeId': serializer.toJson<String?>(
        linkedRecurringIncomeId,
      ),
      'linkedSplitEntryId': serializer.toJson<String?>(linkedSplitEntryId),
      'incomePostingType': serializer.toJson<String?>(incomePostingType),
      'source': serializer.toJson<String?>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    DateTime? date,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> linkedBillId = const Value.absent(),
    Value<String?> linkedRecurringIncomeId = const Value.absent(),
    Value<String?> linkedSplitEntryId = const Value.absent(),
    Value<String?> incomePostingType = const Value.absent(),
    Value<String?> source = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    label: label.present ? label.value : this.label,
    note: note.present ? note.value : this.note,
    linkedBillId: linkedBillId.present ? linkedBillId.value : this.linkedBillId,
    linkedRecurringIncomeId:
        linkedRecurringIncomeId.present
            ? linkedRecurringIncomeId.value
            : this.linkedRecurringIncomeId,
    linkedSplitEntryId:
        linkedSplitEntryId.present
            ? linkedSplitEntryId.value
            : this.linkedSplitEntryId,
    incomePostingType:
        incomePostingType.present
            ? incomePostingType.value
            : this.incomePostingType,
    source: source.present ? source.value : this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
      linkedBillId:
          data.linkedBillId.present
              ? data.linkedBillId.value
              : this.linkedBillId,
      linkedRecurringIncomeId:
          data.linkedRecurringIncomeId.present
              ? data.linkedRecurringIncomeId.value
              : this.linkedRecurringIncomeId,
      linkedSplitEntryId:
          data.linkedSplitEntryId.present
              ? data.linkedSplitEntryId.value
              : this.linkedSplitEntryId,
      incomePostingType:
          data.incomePostingType.present
              ? data.incomePostingType.value
              : this.incomePostingType,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('categoryId: $categoryId, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('linkedBillId: $linkedBillId, ')
          ..write('linkedRecurringIncomeId: $linkedRecurringIncomeId, ')
          ..write('linkedSplitEntryId: $linkedSplitEntryId, ')
          ..write('incomePostingType: $incomePostingType, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    date,
    categoryId,
    label,
    note,
    linkedBillId,
    linkedRecurringIncomeId,
    linkedSplitEntryId,
    incomePostingType,
    source,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.categoryId == this.categoryId &&
          other.label == this.label &&
          other.note == this.note &&
          other.linkedBillId == this.linkedBillId &&
          other.linkedRecurringIncomeId == this.linkedRecurringIncomeId &&
          other.linkedSplitEntryId == this.linkedSplitEntryId &&
          other.incomePostingType == this.incomePostingType &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String?> categoryId;
  final Value<String?> label;
  final Value<String?> note;
  final Value<String?> linkedBillId;
  final Value<String?> linkedRecurringIncomeId;
  final Value<String?> linkedSplitEntryId;
  final Value<String?> incomePostingType;
  final Value<String?> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.linkedBillId = const Value.absent(),
    this.linkedRecurringIncomeId = const Value.absent(),
    this.linkedSplitEntryId = const Value.absent(),
    this.incomePostingType = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String type,
    required double amount,
    required DateTime date,
    this.categoryId = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.linkedBillId = const Value.absent(),
    this.linkedRecurringIncomeId = const Value.absent(),
    this.linkedSplitEntryId = const Value.absent(),
    this.incomePostingType = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? categoryId,
    Expression<String>? label,
    Expression<String>? note,
    Expression<String>? linkedBillId,
    Expression<String>? linkedRecurringIncomeId,
    Expression<String>? linkedSplitEntryId,
    Expression<String>? incomePostingType,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (categoryId != null) 'category_id': categoryId,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (linkedBillId != null) 'linked_bill_id': linkedBillId,
      if (linkedRecurringIncomeId != null)
        'linked_recurring_income_id': linkedRecurringIncomeId,
      if (linkedSplitEntryId != null)
        'linked_split_entry_id': linkedSplitEntryId,
      if (incomePostingType != null) 'income_posting_type': incomePostingType,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String?>? categoryId,
    Value<String?>? label,
    Value<String?>? note,
    Value<String?>? linkedBillId,
    Value<String?>? linkedRecurringIncomeId,
    Value<String?>? linkedSplitEntryId,
    Value<String?>? incomePostingType,
    Value<String?>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      label: label ?? this.label,
      note: note ?? this.note,
      linkedBillId: linkedBillId ?? this.linkedBillId,
      linkedRecurringIncomeId:
          linkedRecurringIncomeId ?? this.linkedRecurringIncomeId,
      linkedSplitEntryId: linkedSplitEntryId ?? this.linkedSplitEntryId,
      incomePostingType: incomePostingType ?? this.incomePostingType,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (linkedBillId.present) {
      map['linked_bill_id'] = Variable<String>(linkedBillId.value);
    }
    if (linkedRecurringIncomeId.present) {
      map['linked_recurring_income_id'] = Variable<String>(
        linkedRecurringIncomeId.value,
      );
    }
    if (linkedSplitEntryId.present) {
      map['linked_split_entry_id'] = Variable<String>(linkedSplitEntryId.value);
    }
    if (incomePostingType.present) {
      map['income_posting_type'] = Variable<String>(incomePostingType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('categoryId: $categoryId, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('linkedBillId: $linkedBillId, ')
          ..write('linkedRecurringIncomeId: $linkedRecurringIncomeId, ')
          ..write('linkedSplitEntryId: $linkedSplitEntryId, ')
          ..write('incomePostingType: $incomePostingType, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _defaultLabelMeta = const VerificationMeta(
    'defaultLabel',
  );
  @override
  late final GeneratedColumn<String> defaultLabel = GeneratedColumn<String>(
    'default_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('green'),
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    defaultLabel,
    isSystem,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
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
    if (data.containsKey('default_label')) {
      context.handle(
        _defaultLabelMeta,
        defaultLabel.isAcceptableOrUnknown(
          data['default_label']!,
          _defaultLabelMeta,
        ),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      defaultLabel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}default_label'],
          )!,
      isSystem:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_system'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String defaultLabel;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Category({
    required this.id,
    required this.name,
    required this.defaultLabel,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['default_label'] = Variable<String>(defaultLabel);
    map['is_system'] = Variable<bool>(isSystem);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      defaultLabel: Value(defaultLabel),
      isSystem: Value(isSystem),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      defaultLabel: serializer.fromJson<String>(json['defaultLabel']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'defaultLabel': serializer.toJson<String>(defaultLabel),
      'isSystem': serializer.toJson<bool>(isSystem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? defaultLabel,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    defaultLabel: defaultLabel ?? this.defaultLabel,
    isSystem: isSystem ?? this.isSystem,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      defaultLabel:
          data.defaultLabel.present
              ? data.defaultLabel.value
              : this.defaultLabel,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('defaultLabel: $defaultLabel, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, defaultLabel, isSystem, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.defaultLabel == this.defaultLabel &&
          other.isSystem == this.isSystem &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> defaultLabel;
  final Value<bool> isSystem;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.defaultLabel = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.defaultLabel = const Value.absent(),
    this.isSystem = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? defaultLabel,
    Expression<bool>? isSystem,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (defaultLabel != null) 'default_label': defaultLabel,
      if (isSystem != null) 'is_system': isSystem,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? defaultLabel,
    Value<bool>? isSystem,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultLabel: defaultLabel ?? this.defaultLabel,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
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
    if (defaultLabel.present) {
      map['default_label'] = Variable<String>(defaultLabel.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('defaultLabel: $defaultLabel, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savingStyleMeta = const VerificationMeta(
    'savingStyle',
  );
  @override
  late final GeneratedColumn<String> savingStyle = GeneratedColumn<String>(
    'saving_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('natural'),
  );
  static const VerificationMeta _priorityOrderMeta = const VerificationMeta(
    'priorityOrder',
  );
  @override
  late final GeneratedColumn<int> priorityOrder = GeneratedColumn<int>(
    'priority_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetAmount,
    targetDate,
    savingStyle,
    priorityOrder,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
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
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('saving_style')) {
      context.handle(
        _savingStyleMeta,
        savingStyle.isAcceptableOrUnknown(
          data['saving_style']!,
          _savingStyleMeta,
        ),
      );
    }
    if (data.containsKey('priority_order')) {
      context.handle(
        _priorityOrderMeta,
        priorityOrder.isAcceptableOrUnknown(
          data['priority_order']!,
          _priorityOrderMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      targetAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}target_amount'],
          )!,
      targetDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}target_date'],
          )!,
      savingStyle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}saving_style'],
          )!,
      priorityOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}priority_order'],
          )!,
      isArchived:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_archived'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String name;
  final double targetAmount;
  final DateTime targetDate;
  final String savingStyle;
  final int priorityOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.targetDate,
    required this.savingStyle,
    required this.priorityOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_amount'] = Variable<double>(targetAmount);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['saving_style'] = Variable<String>(savingStyle);
    map['priority_order'] = Variable<int>(priorityOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetAmount: Value(targetAmount),
      targetDate: Value(targetDate),
      savingStyle: Value(savingStyle),
      priorityOrder: Value(priorityOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      savingStyle: serializer.fromJson<String>(json['savingStyle']),
      priorityOrder: serializer.fromJson<int>(json['priorityOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'savingStyle': serializer.toJson<String>(savingStyle),
      'priorityOrder': serializer.toJson<int>(priorityOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    String? savingStyle,
    int? priorityOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    targetDate: targetDate ?? this.targetDate,
    savingStyle: savingStyle ?? this.savingStyle,
    priorityOrder: priorityOrder ?? this.priorityOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmount:
          data.targetAmount.present
              ? data.targetAmount.value
              : this.targetAmount,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      savingStyle:
          data.savingStyle.present ? data.savingStyle.value : this.savingStyle,
      priorityOrder:
          data.priorityOrder.present
              ? data.priorityOrder.value
              : this.priorityOrder,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('savingStyle: $savingStyle, ')
          ..write('priorityOrder: $priorityOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetAmount,
    targetDate,
    savingStyle,
    priorityOrder,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmount == this.targetAmount &&
          other.targetDate == this.targetDate &&
          other.savingStyle == this.savingStyle &&
          other.priorityOrder == this.priorityOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> targetAmount;
  final Value<DateTime> targetDate;
  final Value<String> savingStyle;
  final Value<int> priorityOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.savingStyle = const Value.absent(),
    this.priorityOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    this.savingStyle = const Value.absent(),
    this.priorityOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetAmount = Value(targetAmount),
       targetDate = Value(targetDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? targetAmount,
    Expression<DateTime>? targetDate,
    Expression<String>? savingStyle,
    Expression<int>? priorityOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (targetDate != null) 'target_date': targetDate,
      if (savingStyle != null) 'saving_style': savingStyle,
      if (priorityOrder != null) 'priority_order': priorityOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? targetAmount,
    Value<DateTime>? targetDate,
    Value<String>? savingStyle,
    Value<int>? priorityOrder,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      savingStyle: savingStyle ?? this.savingStyle,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
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
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (savingStyle.present) {
      map['saving_style'] = Variable<String>(savingStyle.value);
    }
    if (priorityOrder.present) {
      map['priority_order'] = Variable<int>(priorityOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('savingStyle: $savingStyle, ')
          ..write('priorityOrder: $priorityOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringIncomesTable extends RecurringIncomes
    with TableInfo<$RecurringIncomesTable, RecurringIncome> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringIncomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _nextPaydayDateMeta = const VerificationMeta(
    'nextPaydayDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextPaydayDate =
      GeneratedColumn<DateTime>(
        'next_payday_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _expectedAmountMeta = const VerificationMeta(
    'expectedAmount',
  );
  @override
  late final GeneratedColumn<double> expectedAmount = GeneratedColumn<double>(
    'expected_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paydayBehaviorMeta = const VerificationMeta(
    'paydayBehavior',
  );
  @override
  late final GeneratedColumn<String> paydayBehavior = GeneratedColumn<String>(
    'payday_behavior',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('confirm_actual_on_payday'),
  );
  static const VerificationMeta _isPaydayAnchorEligibleMeta =
      const VerificationMeta('isPaydayAnchorEligible');
  @override
  late final GeneratedColumn<bool> isPaydayAnchorEligible =
      GeneratedColumn<bool>(
        'is_payday_anchor_eligible',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_payday_anchor_eligible" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _isPaydayAnchorMeta = const VerificationMeta(
    'isPaydayAnchor',
  );
  @override
  late final GeneratedColumn<bool> isPaydayAnchor = GeneratedColumn<bool>(
    'is_payday_anchor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_payday_anchor" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    frequency,
    nextPaydayDate,
    expectedAmount,
    paydayBehavior,
    isPaydayAnchorEligible,
    isPaydayAnchor,
    reminderEnabled,
    reminderTime,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_incomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringIncome> instance, {
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
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('next_payday_date')) {
      context.handle(
        _nextPaydayDateMeta,
        nextPaydayDate.isAcceptableOrUnknown(
          data['next_payday_date']!,
          _nextPaydayDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextPaydayDateMeta);
    }
    if (data.containsKey('expected_amount')) {
      context.handle(
        _expectedAmountMeta,
        expectedAmount.isAcceptableOrUnknown(
          data['expected_amount']!,
          _expectedAmountMeta,
        ),
      );
    }
    if (data.containsKey('payday_behavior')) {
      context.handle(
        _paydayBehaviorMeta,
        paydayBehavior.isAcceptableOrUnknown(
          data['payday_behavior']!,
          _paydayBehaviorMeta,
        ),
      );
    }
    if (data.containsKey('is_payday_anchor_eligible')) {
      context.handle(
        _isPaydayAnchorEligibleMeta,
        isPaydayAnchorEligible.isAcceptableOrUnknown(
          data['is_payday_anchor_eligible']!,
          _isPaydayAnchorEligibleMeta,
        ),
      );
    }
    if (data.containsKey('is_payday_anchor')) {
      context.handle(
        _isPaydayAnchorMeta,
        isPaydayAnchor.isAcceptableOrUnknown(
          data['is_payday_anchor']!,
          _isPaydayAnchorMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringIncome map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringIncome(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      frequency:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}frequency'],
          )!,
      nextPaydayDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}next_payday_date'],
          )!,
      expectedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}expected_amount'],
      ),
      paydayBehavior:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payday_behavior'],
          )!,
      isPaydayAnchorEligible:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_payday_anchor_eligible'],
          )!,
      isPaydayAnchor:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_payday_anchor'],
          )!,
      reminderEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}reminder_enabled'],
          )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $RecurringIncomesTable createAlias(String alias) {
    return $RecurringIncomesTable(attachedDatabase, alias);
  }
}

class RecurringIncome extends DataClass implements Insertable<RecurringIncome> {
  final String id;
  final String name;
  final String frequency;
  final DateTime nextPaydayDate;
  final double? expectedAmount;
  final String paydayBehavior;
  final bool isPaydayAnchorEligible;
  final bool isPaydayAnchor;
  final bool reminderEnabled;
  final String? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecurringIncome({
    required this.id,
    required this.name,
    required this.frequency,
    required this.nextPaydayDate,
    this.expectedAmount,
    required this.paydayBehavior,
    required this.isPaydayAnchorEligible,
    required this.isPaydayAnchor,
    required this.reminderEnabled,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['frequency'] = Variable<String>(frequency);
    map['next_payday_date'] = Variable<DateTime>(nextPaydayDate);
    if (!nullToAbsent || expectedAmount != null) {
      map['expected_amount'] = Variable<double>(expectedAmount);
    }
    map['payday_behavior'] = Variable<String>(paydayBehavior);
    map['is_payday_anchor_eligible'] = Variable<bool>(isPaydayAnchorEligible);
    map['is_payday_anchor'] = Variable<bool>(isPaydayAnchor);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecurringIncomesCompanion toCompanion(bool nullToAbsent) {
    return RecurringIncomesCompanion(
      id: Value(id),
      name: Value(name),
      frequency: Value(frequency),
      nextPaydayDate: Value(nextPaydayDate),
      expectedAmount:
          expectedAmount == null && nullToAbsent
              ? const Value.absent()
              : Value(expectedAmount),
      paydayBehavior: Value(paydayBehavior),
      isPaydayAnchorEligible: Value(isPaydayAnchorEligible),
      isPaydayAnchor: Value(isPaydayAnchor),
      reminderEnabled: Value(reminderEnabled),
      reminderTime:
          reminderTime == null && nullToAbsent
              ? const Value.absent()
              : Value(reminderTime),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecurringIncome.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringIncome(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      frequency: serializer.fromJson<String>(json['frequency']),
      nextPaydayDate: serializer.fromJson<DateTime>(json['nextPaydayDate']),
      expectedAmount: serializer.fromJson<double?>(json['expectedAmount']),
      paydayBehavior: serializer.fromJson<String>(json['paydayBehavior']),
      isPaydayAnchorEligible: serializer.fromJson<bool>(
        json['isPaydayAnchorEligible'],
      ),
      isPaydayAnchor: serializer.fromJson<bool>(json['isPaydayAnchor']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'frequency': serializer.toJson<String>(frequency),
      'nextPaydayDate': serializer.toJson<DateTime>(nextPaydayDate),
      'expectedAmount': serializer.toJson<double?>(expectedAmount),
      'paydayBehavior': serializer.toJson<String>(paydayBehavior),
      'isPaydayAnchorEligible': serializer.toJson<bool>(isPaydayAnchorEligible),
      'isPaydayAnchor': serializer.toJson<bool>(isPaydayAnchor),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecurringIncome copyWith({
    String? id,
    String? name,
    String? frequency,
    DateTime? nextPaydayDate,
    Value<double?> expectedAmount = const Value.absent(),
    String? paydayBehavior,
    bool? isPaydayAnchorEligible,
    bool? isPaydayAnchor,
    bool? reminderEnabled,
    Value<String?> reminderTime = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RecurringIncome(
    id: id ?? this.id,
    name: name ?? this.name,
    frequency: frequency ?? this.frequency,
    nextPaydayDate: nextPaydayDate ?? this.nextPaydayDate,
    expectedAmount:
        expectedAmount.present ? expectedAmount.value : this.expectedAmount,
    paydayBehavior: paydayBehavior ?? this.paydayBehavior,
    isPaydayAnchorEligible:
        isPaydayAnchorEligible ?? this.isPaydayAnchorEligible,
    isPaydayAnchor: isPaydayAnchor ?? this.isPaydayAnchor,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecurringIncome copyWithCompanion(RecurringIncomesCompanion data) {
    return RecurringIncome(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      nextPaydayDate:
          data.nextPaydayDate.present
              ? data.nextPaydayDate.value
              : this.nextPaydayDate,
      expectedAmount:
          data.expectedAmount.present
              ? data.expectedAmount.value
              : this.expectedAmount,
      paydayBehavior:
          data.paydayBehavior.present
              ? data.paydayBehavior.value
              : this.paydayBehavior,
      isPaydayAnchorEligible:
          data.isPaydayAnchorEligible.present
              ? data.isPaydayAnchorEligible.value
              : this.isPaydayAnchorEligible,
      isPaydayAnchor:
          data.isPaydayAnchor.present
              ? data.isPaydayAnchor.value
              : this.isPaydayAnchor,
      reminderEnabled:
          data.reminderEnabled.present
              ? data.reminderEnabled.value
              : this.reminderEnabled,
      reminderTime:
          data.reminderTime.present
              ? data.reminderTime.value
              : this.reminderTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringIncome(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('frequency: $frequency, ')
          ..write('nextPaydayDate: $nextPaydayDate, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('paydayBehavior: $paydayBehavior, ')
          ..write('isPaydayAnchorEligible: $isPaydayAnchorEligible, ')
          ..write('isPaydayAnchor: $isPaydayAnchor, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    frequency,
    nextPaydayDate,
    expectedAmount,
    paydayBehavior,
    isPaydayAnchorEligible,
    isPaydayAnchor,
    reminderEnabled,
    reminderTime,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringIncome &&
          other.id == this.id &&
          other.name == this.name &&
          other.frequency == this.frequency &&
          other.nextPaydayDate == this.nextPaydayDate &&
          other.expectedAmount == this.expectedAmount &&
          other.paydayBehavior == this.paydayBehavior &&
          other.isPaydayAnchorEligible == this.isPaydayAnchorEligible &&
          other.isPaydayAnchor == this.isPaydayAnchor &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderTime == this.reminderTime &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecurringIncomesCompanion extends UpdateCompanion<RecurringIncome> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> frequency;
  final Value<DateTime> nextPaydayDate;
  final Value<double?> expectedAmount;
  final Value<String> paydayBehavior;
  final Value<bool> isPaydayAnchorEligible;
  final Value<bool> isPaydayAnchor;
  final Value<bool> reminderEnabled;
  final Value<String?> reminderTime;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RecurringIncomesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.frequency = const Value.absent(),
    this.nextPaydayDate = const Value.absent(),
    this.expectedAmount = const Value.absent(),
    this.paydayBehavior = const Value.absent(),
    this.isPaydayAnchorEligible = const Value.absent(),
    this.isPaydayAnchor = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringIncomesCompanion.insert({
    required String id,
    required String name,
    this.frequency = const Value.absent(),
    required DateTime nextPaydayDate,
    this.expectedAmount = const Value.absent(),
    this.paydayBehavior = const Value.absent(),
    this.isPaydayAnchorEligible = const Value.absent(),
    this.isPaydayAnchor = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderTime = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       nextPaydayDate = Value(nextPaydayDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecurringIncome> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? frequency,
    Expression<DateTime>? nextPaydayDate,
    Expression<double>? expectedAmount,
    Expression<String>? paydayBehavior,
    Expression<bool>? isPaydayAnchorEligible,
    Expression<bool>? isPaydayAnchor,
    Expression<bool>? reminderEnabled,
    Expression<String>? reminderTime,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (frequency != null) 'frequency': frequency,
      if (nextPaydayDate != null) 'next_payday_date': nextPaydayDate,
      if (expectedAmount != null) 'expected_amount': expectedAmount,
      if (paydayBehavior != null) 'payday_behavior': paydayBehavior,
      if (isPaydayAnchorEligible != null)
        'is_payday_anchor_eligible': isPaydayAnchorEligible,
      if (isPaydayAnchor != null) 'is_payday_anchor': isPaydayAnchor,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringIncomesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? frequency,
    Value<DateTime>? nextPaydayDate,
    Value<double?>? expectedAmount,
    Value<String>? paydayBehavior,
    Value<bool>? isPaydayAnchorEligible,
    Value<bool>? isPaydayAnchor,
    Value<bool>? reminderEnabled,
    Value<String?>? reminderTime,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecurringIncomesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      nextPaydayDate: nextPaydayDate ?? this.nextPaydayDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      paydayBehavior: paydayBehavior ?? this.paydayBehavior,
      isPaydayAnchorEligible:
          isPaydayAnchorEligible ?? this.isPaydayAnchorEligible,
      isPaydayAnchor: isPaydayAnchor ?? this.isPaydayAnchor,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
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
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (nextPaydayDate.present) {
      map['next_payday_date'] = Variable<DateTime>(nextPaydayDate.value);
    }
    if (expectedAmount.present) {
      map['expected_amount'] = Variable<double>(expectedAmount.value);
    }
    if (paydayBehavior.present) {
      map['payday_behavior'] = Variable<String>(paydayBehavior.value);
    }
    if (isPaydayAnchorEligible.present) {
      map['is_payday_anchor_eligible'] = Variable<bool>(
        isPaydayAnchorEligible.value,
      );
    }
    if (isPaydayAnchor.present) {
      map['is_payday_anchor'] = Variable<bool>(isPaydayAnchor.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringIncomesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('frequency: $frequency, ')
          ..write('nextPaydayDate: $nextPaydayDate, ')
          ..write('expectedAmount: $expectedAmount, ')
          ..write('paydayBehavior: $paydayBehavior, ')
          ..write('isPaydayAnchorEligible: $isPaydayAnchorEligible, ')
          ..write('isPaydayAnchor: $isPaydayAnchor, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _nextDueDateMeta = const VerificationMeta(
    'nextDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
    'next_due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultLabelMeta = const VerificationMeta(
    'defaultLabel',
  );
  @override
  late final GeneratedColumn<String> defaultLabel = GeneratedColumn<String>(
    'default_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('green'),
  );
  static const VerificationMeta _autopayMeta = const VerificationMeta(
    'autopay',
  );
  @override
  late final GeneratedColumn<bool> autopay = GeneratedColumn<bool>(
    'autopay',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("autopay" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderLeadTimeDaysMeta =
      const VerificationMeta('reminderLeadTimeDays');
  @override
  late final GeneratedColumn<int> reminderLeadTimeDays = GeneratedColumn<int>(
    'reminder_lead_time_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    frequency,
    nextDueDate,
    categoryId,
    defaultLabel,
    autopay,
    reminderEnabled,
    reminderLeadTimeDays,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bill> instance, {
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
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
        _nextDueDateMeta,
        nextDueDate.isAcceptableOrUnknown(
          data['next_due_date']!,
          _nextDueDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextDueDateMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('default_label')) {
      context.handle(
        _defaultLabelMeta,
        defaultLabel.isAcceptableOrUnknown(
          data['default_label']!,
          _defaultLabelMeta,
        ),
      );
    }
    if (data.containsKey('autopay')) {
      context.handle(
        _autopayMeta,
        autopay.isAcceptableOrUnknown(data['autopay']!, _autopayMeta),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_lead_time_days')) {
      context.handle(
        _reminderLeadTimeDaysMeta,
        reminderLeadTimeDays.isAcceptableOrUnknown(
          data['reminder_lead_time_days']!,
          _reminderLeadTimeDaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      amount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}amount'],
          )!,
      frequency:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}frequency'],
          )!,
      nextDueDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}next_due_date'],
          )!,
      categoryId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}category_id'],
          )!,
      defaultLabel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}default_label'],
          )!,
      autopay:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}autopay'],
          )!,
      reminderEnabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}reminder_enabled'],
          )!,
      reminderLeadTimeDays:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}reminder_lead_time_days'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class Bill extends DataClass implements Insertable<Bill> {
  final String id;
  final String name;
  final double amount;
  final String frequency;
  final DateTime nextDueDate;
  final String categoryId;
  final String defaultLabel;
  final bool autopay;
  final bool reminderEnabled;
  final int reminderLeadTimeDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
    required this.categoryId,
    required this.defaultLabel,
    required this.autopay,
    required this.reminderEnabled,
    required this.reminderLeadTimeDays,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['frequency'] = Variable<String>(frequency);
    map['next_due_date'] = Variable<DateTime>(nextDueDate);
    map['category_id'] = Variable<String>(categoryId);
    map['default_label'] = Variable<String>(defaultLabel);
    map['autopay'] = Variable<bool>(autopay);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['reminder_lead_time_days'] = Variable<int>(reminderLeadTimeDays);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      frequency: Value(frequency),
      nextDueDate: Value(nextDueDate),
      categoryId: Value(categoryId),
      defaultLabel: Value(defaultLabel),
      autopay: Value(autopay),
      reminderEnabled: Value(reminderEnabled),
      reminderLeadTimeDays: Value(reminderLeadTimeDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      frequency: serializer.fromJson<String>(json['frequency']),
      nextDueDate: serializer.fromJson<DateTime>(json['nextDueDate']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      defaultLabel: serializer.fromJson<String>(json['defaultLabel']),
      autopay: serializer.fromJson<bool>(json['autopay']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderLeadTimeDays: serializer.fromJson<int>(
        json['reminderLeadTimeDays'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'frequency': serializer.toJson<String>(frequency),
      'nextDueDate': serializer.toJson<DateTime>(nextDueDate),
      'categoryId': serializer.toJson<String>(categoryId),
      'defaultLabel': serializer.toJson<String>(defaultLabel),
      'autopay': serializer.toJson<bool>(autopay),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderLeadTimeDays': serializer.toJson<int>(reminderLeadTimeDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    String? frequency,
    DateTime? nextDueDate,
    String? categoryId,
    String? defaultLabel,
    bool? autopay,
    bool? reminderEnabled,
    int? reminderLeadTimeDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Bill(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    frequency: frequency ?? this.frequency,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    categoryId: categoryId ?? this.categoryId,
    defaultLabel: defaultLabel ?? this.defaultLabel,
    autopay: autopay ?? this.autopay,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderLeadTimeDays: reminderLeadTimeDays ?? this.reminderLeadTimeDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      nextDueDate:
          data.nextDueDate.present ? data.nextDueDate.value : this.nextDueDate,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      defaultLabel:
          data.defaultLabel.present
              ? data.defaultLabel.value
              : this.defaultLabel,
      autopay: data.autopay.present ? data.autopay.value : this.autopay,
      reminderEnabled:
          data.reminderEnabled.present
              ? data.reminderEnabled.value
              : this.reminderEnabled,
      reminderLeadTimeDays:
          data.reminderLeadTimeDays.present
              ? data.reminderLeadTimeDays.value
              : this.reminderLeadTimeDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('frequency: $frequency, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('defaultLabel: $defaultLabel, ')
          ..write('autopay: $autopay, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderLeadTimeDays: $reminderLeadTimeDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    frequency,
    nextDueDate,
    categoryId,
    defaultLabel,
    autopay,
    reminderEnabled,
    reminderLeadTimeDays,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.frequency == this.frequency &&
          other.nextDueDate == this.nextDueDate &&
          other.categoryId == this.categoryId &&
          other.defaultLabel == this.defaultLabel &&
          other.autopay == this.autopay &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderLeadTimeDays == this.reminderLeadTimeDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> frequency;
  final Value<DateTime> nextDueDate;
  final Value<String> categoryId;
  final Value<String> defaultLabel;
  final Value<bool> autopay;
  final Value<bool> reminderEnabled;
  final Value<int> reminderLeadTimeDays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.frequency = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.defaultLabel = const Value.absent(),
    this.autopay = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderLeadTimeDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    required String name,
    required double amount,
    this.frequency = const Value.absent(),
    required DateTime nextDueDate,
    required String categoryId,
    this.defaultLabel = const Value.absent(),
    this.autopay = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderLeadTimeDays = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       amount = Value(amount),
       nextDueDate = Value(nextDueDate),
       categoryId = Value(categoryId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Bill> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? frequency,
    Expression<DateTime>? nextDueDate,
    Expression<String>? categoryId,
    Expression<String>? defaultLabel,
    Expression<bool>? autopay,
    Expression<bool>? reminderEnabled,
    Expression<int>? reminderLeadTimeDays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (frequency != null) 'frequency': frequency,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (categoryId != null) 'category_id': categoryId,
      if (defaultLabel != null) 'default_label': defaultLabel,
      if (autopay != null) 'autopay': autopay,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderLeadTimeDays != null)
        'reminder_lead_time_days': reminderLeadTimeDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<String>? frequency,
    Value<DateTime>? nextDueDate,
    Value<String>? categoryId,
    Value<String>? defaultLabel,
    Value<bool>? autopay,
    Value<bool>? reminderEnabled,
    Value<int>? reminderLeadTimeDays,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BillsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      categoryId: categoryId ?? this.categoryId,
      defaultLabel: defaultLabel ?? this.defaultLabel,
      autopay: autopay ?? this.autopay,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderLeadTimeDays: reminderLeadTimeDays ?? this.reminderLeadTimeDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (defaultLabel.present) {
      map['default_label'] = Variable<String>(defaultLabel.value);
    }
    if (autopay.present) {
      map['autopay'] = Variable<bool>(autopay.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderLeadTimeDays.present) {
      map['reminder_lead_time_days'] = Variable<int>(
        reminderLeadTimeDays.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('frequency: $frequency, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('defaultLabel: $defaultLabel, ')
          ..write('autopay: $autopay, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderLeadTimeDays: $reminderLeadTimeDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    handle,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
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
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      ),
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final String id;
  final String name;
  final String? handle;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Person({
    required this.id,
    required this.name,
    this.handle,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || handle != null) {
      map['handle'] = Variable<String>(handle);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      name: Value(name),
      handle:
          handle == null && nullToAbsent ? const Value.absent() : Value(handle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      handle: serializer.fromJson<String?>(json['handle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'handle': serializer.toJson<String?>(handle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Person copyWith({
    String? id,
    String? name,
    Value<String?> handle = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    handle: handle.present ? handle.value : this.handle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      handle: data.handle.present ? data.handle.value : this.handle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('handle: $handle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, handle, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.handle == this.handle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> handle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.handle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    required String id,
    required String name,
    this.handle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Person> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? handle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (handle != null) 'handle': handle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? handle,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PersonsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
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
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('handle: $handle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitEntriesTable extends SplitEntries
    with TableInfo<$SplitEntriesTable, SplitEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidByMeta = const VerificationMeta('paidBy');
  @override
  late final GeneratedColumn<String> paidBy = GeneratedColumn<String>(
    'paid_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkToExpenseTransactionIdMeta =
      const VerificationMeta('linkToExpenseTransactionId');
  @override
  late final GeneratedColumn<String> linkToExpenseTransactionId =
      GeneratedColumn<String>(
        'link_to_expense_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    description,
    totalAmount,
    paidBy,
    linkToExpenseTransactionId,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('paid_by')) {
      context.handle(
        _paidByMeta,
        paidBy.isAcceptableOrUnknown(data['paid_by']!, _paidByMeta),
      );
    } else if (isInserting) {
      context.missing(_paidByMeta);
    }
    if (data.containsKey('link_to_expense_transaction_id')) {
      context.handle(
        _linkToExpenseTransactionIdMeta,
        linkToExpenseTransactionId.isAcceptableOrUnknown(
          data['link_to_expense_transaction_id']!,
          _linkToExpenseTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      date:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}date'],
          )!,
      description:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}description'],
          )!,
      totalAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}total_amount'],
          )!,
      paidBy:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}paid_by'],
          )!,
      linkToExpenseTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_to_expense_transaction_id'],
      ),
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $SplitEntriesTable createAlias(String alias) {
    return $SplitEntriesTable(attachedDatabase, alias);
  }
}

class SplitEntry extends DataClass implements Insertable<SplitEntry> {
  final String id;
  final DateTime date;
  final String description;
  final double totalAmount;
  final String paidBy;
  final String? linkToExpenseTransactionId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SplitEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.totalAmount,
    required this.paidBy,
    this.linkToExpenseTransactionId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['description'] = Variable<String>(description);
    map['total_amount'] = Variable<double>(totalAmount);
    map['paid_by'] = Variable<String>(paidBy);
    if (!nullToAbsent || linkToExpenseTransactionId != null) {
      map['link_to_expense_transaction_id'] = Variable<String>(
        linkToExpenseTransactionId,
      );
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SplitEntriesCompanion toCompanion(bool nullToAbsent) {
    return SplitEntriesCompanion(
      id: Value(id),
      date: Value(date),
      description: Value(description),
      totalAmount: Value(totalAmount),
      paidBy: Value(paidBy),
      linkToExpenseTransactionId:
          linkToExpenseTransactionId == null && nullToAbsent
              ? const Value.absent()
              : Value(linkToExpenseTransactionId),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SplitEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      description: serializer.fromJson<String>(json['description']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paidBy: serializer.fromJson<String>(json['paidBy']),
      linkToExpenseTransactionId: serializer.fromJson<String?>(
        json['linkToExpenseTransactionId'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'description': serializer.toJson<String>(description),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paidBy': serializer.toJson<String>(paidBy),
      'linkToExpenseTransactionId': serializer.toJson<String?>(
        linkToExpenseTransactionId,
      ),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SplitEntry copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? totalAmount,
    String? paidBy,
    Value<String?> linkToExpenseTransactionId = const Value.absent(),
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SplitEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    description: description ?? this.description,
    totalAmount: totalAmount ?? this.totalAmount,
    paidBy: paidBy ?? this.paidBy,
    linkToExpenseTransactionId:
        linkToExpenseTransactionId.present
            ? linkToExpenseTransactionId.value
            : this.linkToExpenseTransactionId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SplitEntry copyWithCompanion(SplitEntriesCompanion data) {
    return SplitEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      description:
          data.description.present ? data.description.value : this.description,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paidBy: data.paidBy.present ? data.paidBy.value : this.paidBy,
      linkToExpenseTransactionId:
          data.linkToExpenseTransactionId.present
              ? data.linkToExpenseTransactionId.value
              : this.linkToExpenseTransactionId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('description: $description, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidBy: $paidBy, ')
          ..write('linkToExpenseTransactionId: $linkToExpenseTransactionId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    description,
    totalAmount,
    paidBy,
    linkToExpenseTransactionId,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.description == this.description &&
          other.totalAmount == this.totalAmount &&
          other.paidBy == this.paidBy &&
          other.linkToExpenseTransactionId == this.linkToExpenseTransactionId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SplitEntriesCompanion extends UpdateCompanion<SplitEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> description;
  final Value<double> totalAmount;
  final Value<String> paidBy;
  final Value<String?> linkToExpenseTransactionId;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SplitEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.description = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paidBy = const Value.absent(),
    this.linkToExpenseTransactionId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitEntriesCompanion.insert({
    required String id,
    required DateTime date,
    required String description,
    required double totalAmount,
    required String paidBy,
    this.linkToExpenseTransactionId = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       description = Value(description),
       totalAmount = Value(totalAmount),
       paidBy = Value(paidBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SplitEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? description,
    Expression<double>? totalAmount,
    Expression<String>? paidBy,
    Expression<String>? linkToExpenseTransactionId,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (description != null) 'description': description,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paidBy != null) 'paid_by': paidBy,
      if (linkToExpenseTransactionId != null)
        'link_to_expense_transaction_id': linkToExpenseTransactionId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? description,
    Value<double>? totalAmount,
    Value<String>? paidBy,
    Value<String?>? linkToExpenseTransactionId,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SplitEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      paidBy: paidBy ?? this.paidBy,
      linkToExpenseTransactionId:
          linkToExpenseTransactionId ?? this.linkToExpenseTransactionId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paidBy.present) {
      map['paid_by'] = Variable<String>(paidBy.value);
    }
    if (linkToExpenseTransactionId.present) {
      map['link_to_expense_transaction_id'] = Variable<String>(
        linkToExpenseTransactionId.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('description: $description, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidBy: $paidBy, ')
          ..write('linkToExpenseTransactionId: $linkToExpenseTransactionId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitSharesTable extends SplitShares
    with TableInfo<$SplitSharesTable, SplitShare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitEntryIdMeta = const VerificationMeta(
    'splitEntryId',
  );
  @override
  late final GeneratedColumn<String> splitEntryId = GeneratedColumn<String>(
    'split_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareAmountMeta = const VerificationMeta(
    'shareAmount',
  );
  @override
  late final GeneratedColumn<double> shareAmount = GeneratedColumn<double>(
    'share_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    splitEntryId,
    personId,
    shareAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_shares';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitShare> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('split_entry_id')) {
      context.handle(
        _splitEntryIdMeta,
        splitEntryId.isAcceptableOrUnknown(
          data['split_entry_id']!,
          _splitEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitEntryIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('share_amount')) {
      context.handle(
        _shareAmountMeta,
        shareAmount.isAcceptableOrUnknown(
          data['share_amount']!,
          _shareAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shareAmountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitShare map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitShare(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      splitEntryId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}split_entry_id'],
          )!,
      personId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}person_id'],
          )!,
      shareAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}share_amount'],
          )!,
    );
  }

  @override
  $SplitSharesTable createAlias(String alias) {
    return $SplitSharesTable(attachedDatabase, alias);
  }
}

class SplitShare extends DataClass implements Insertable<SplitShare> {
  final String id;
  final String splitEntryId;
  final String personId;
  final double shareAmount;
  const SplitShare({
    required this.id,
    required this.splitEntryId,
    required this.personId,
    required this.shareAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['split_entry_id'] = Variable<String>(splitEntryId);
    map['person_id'] = Variable<String>(personId);
    map['share_amount'] = Variable<double>(shareAmount);
    return map;
  }

  SplitSharesCompanion toCompanion(bool nullToAbsent) {
    return SplitSharesCompanion(
      id: Value(id),
      splitEntryId: Value(splitEntryId),
      personId: Value(personId),
      shareAmount: Value(shareAmount),
    );
  }

  factory SplitShare.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitShare(
      id: serializer.fromJson<String>(json['id']),
      splitEntryId: serializer.fromJson<String>(json['splitEntryId']),
      personId: serializer.fromJson<String>(json['personId']),
      shareAmount: serializer.fromJson<double>(json['shareAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'splitEntryId': serializer.toJson<String>(splitEntryId),
      'personId': serializer.toJson<String>(personId),
      'shareAmount': serializer.toJson<double>(shareAmount),
    };
  }

  SplitShare copyWith({
    String? id,
    String? splitEntryId,
    String? personId,
    double? shareAmount,
  }) => SplitShare(
    id: id ?? this.id,
    splitEntryId: splitEntryId ?? this.splitEntryId,
    personId: personId ?? this.personId,
    shareAmount: shareAmount ?? this.shareAmount,
  );
  SplitShare copyWithCompanion(SplitSharesCompanion data) {
    return SplitShare(
      id: data.id.present ? data.id.value : this.id,
      splitEntryId:
          data.splitEntryId.present
              ? data.splitEntryId.value
              : this.splitEntryId,
      personId: data.personId.present ? data.personId.value : this.personId,
      shareAmount:
          data.shareAmount.present ? data.shareAmount.value : this.shareAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitShare(')
          ..write('id: $id, ')
          ..write('splitEntryId: $splitEntryId, ')
          ..write('personId: $personId, ')
          ..write('shareAmount: $shareAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, splitEntryId, personId, shareAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitShare &&
          other.id == this.id &&
          other.splitEntryId == this.splitEntryId &&
          other.personId == this.personId &&
          other.shareAmount == this.shareAmount);
}

class SplitSharesCompanion extends UpdateCompanion<SplitShare> {
  final Value<String> id;
  final Value<String> splitEntryId;
  final Value<String> personId;
  final Value<double> shareAmount;
  final Value<int> rowid;
  const SplitSharesCompanion({
    this.id = const Value.absent(),
    this.splitEntryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.shareAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitSharesCompanion.insert({
    required String id,
    required String splitEntryId,
    required String personId,
    required double shareAmount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       splitEntryId = Value(splitEntryId),
       personId = Value(personId),
       shareAmount = Value(shareAmount);
  static Insertable<SplitShare> custom({
    Expression<String>? id,
    Expression<String>? splitEntryId,
    Expression<String>? personId,
    Expression<double>? shareAmount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitEntryId != null) 'split_entry_id': splitEntryId,
      if (personId != null) 'person_id': personId,
      if (shareAmount != null) 'share_amount': shareAmount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitSharesCompanion copyWith({
    Value<String>? id,
    Value<String>? splitEntryId,
    Value<String>? personId,
    Value<double>? shareAmount,
    Value<int>? rowid,
  }) {
    return SplitSharesCompanion(
      id: id ?? this.id,
      splitEntryId: splitEntryId ?? this.splitEntryId,
      personId: personId ?? this.personId,
      shareAmount: shareAmount ?? this.shareAmount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (splitEntryId.present) {
      map['split_entry_id'] = Variable<String>(splitEntryId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (shareAmount.present) {
      map['share_amount'] = Variable<double>(shareAmount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitSharesCompanion(')
          ..write('id: $id, ')
          ..write('splitEntryId: $splitEntryId, ')
          ..write('personId: $personId, ')
          ..write('shareAmount: $shareAmount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyCloseoutsTable extends DailyCloseouts
    with TableInfo<$DailyCloseoutsTable, DailyCloseout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCloseoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, result, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_closeouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyCloseout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyCloseout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCloseout(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      date:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}date'],
          )!,
      result:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}result'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $DailyCloseoutsTable createAlias(String alias) {
    return $DailyCloseoutsTable(attachedDatabase, alias);
  }
}

class DailyCloseout extends DataClass implements Insertable<DailyCloseout> {
  final String id;
  final DateTime date;
  final String result;
  final DateTime createdAt;
  const DailyCloseout({
    required this.id,
    required this.date,
    required this.result,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['result'] = Variable<String>(result);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyCloseoutsCompanion toCompanion(bool nullToAbsent) {
    return DailyCloseoutsCompanion(
      id: Value(id),
      date: Value(date),
      result: Value(result),
      createdAt: Value(createdAt),
    );
  }

  factory DailyCloseout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCloseout(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      result: serializer.fromJson<String>(json['result']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'result': serializer.toJson<String>(result),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyCloseout copyWith({
    String? id,
    DateTime? date,
    String? result,
    DateTime? createdAt,
  }) => DailyCloseout(
    id: id ?? this.id,
    date: date ?? this.date,
    result: result ?? this.result,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyCloseout copyWithCompanion(DailyCloseoutsCompanion data) {
    return DailyCloseout(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      result: data.result.present ? data.result.value : this.result,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCloseout(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('result: $result, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, result, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCloseout &&
          other.id == this.id &&
          other.date == this.date &&
          other.result == this.result &&
          other.createdAt == this.createdAt);
}

class DailyCloseoutsCompanion extends UpdateCompanion<DailyCloseout> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> result;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DailyCloseoutsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.result = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyCloseoutsCompanion.insert({
    required String id,
    required DateTime date,
    required String result,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       result = Value(result),
       createdAt = Value(createdAt);
  static Insertable<DailyCloseout> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? result,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (result != null) 'result': result,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyCloseoutsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? result,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DailyCloseoutsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCloseoutsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('result: $result, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecoveryPlansTable extends RecoveryPlans
    with TableInfo<$RecoveryPlansTable, RecoveryPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecoveryPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerTransactionIdMeta =
      const VerificationMeta('triggerTransactionId');
  @override
  late final GeneratedColumn<String> triggerTransactionId =
      GeneratedColumn<String>(
        'trigger_transaction_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _overspendAmountMeta = const VerificationMeta(
    'overspendAmount',
  );
  @override
  late final GeneratedColumn<double> overspendAmount = GeneratedColumn<double>(
    'overspend_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planTypeMeta = const VerificationMeta(
    'planType',
  );
  @override
  late final GeneratedColumn<String> planType = GeneratedColumn<String>(
    'plan_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parametersMeta = const VerificationMeta(
    'parameters',
  );
  @override
  late final GeneratedColumn<String> parameters = GeneratedColumn<String>(
    'parameters',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    triggerTransactionId,
    overspendAmount,
    planType,
    parameters,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recovery_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecoveryPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('trigger_transaction_id')) {
      context.handle(
        _triggerTransactionIdMeta,
        triggerTransactionId.isAcceptableOrUnknown(
          data['trigger_transaction_id']!,
          _triggerTransactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerTransactionIdMeta);
    }
    if (data.containsKey('overspend_amount')) {
      context.handle(
        _overspendAmountMeta,
        overspendAmount.isAcceptableOrUnknown(
          data['overspend_amount']!,
          _overspendAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overspendAmountMeta);
    }
    if (data.containsKey('plan_type')) {
      context.handle(
        _planTypeMeta,
        planType.isAcceptableOrUnknown(data['plan_type']!, _planTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_planTypeMeta);
    }
    if (data.containsKey('parameters')) {
      context.handle(
        _parametersMeta,
        parameters.isAcceptableOrUnknown(data['parameters']!, _parametersMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecoveryPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecoveryPlan(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      triggerTransactionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}trigger_transaction_id'],
          )!,
      overspendAmount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}overspend_amount'],
          )!,
      planType:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}plan_type'],
          )!,
      parameters:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}parameters'],
          )!,
      status:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}status'],
          )!,
    );
  }

  @override
  $RecoveryPlansTable createAlias(String alias) {
    return $RecoveryPlansTable(attachedDatabase, alias);
  }
}

class RecoveryPlan extends DataClass implements Insertable<RecoveryPlan> {
  final String id;
  final DateTime createdAt;
  final String triggerTransactionId;
  final double overspendAmount;
  final String planType;
  final String parameters;
  final String status;
  const RecoveryPlan({
    required this.id,
    required this.createdAt,
    required this.triggerTransactionId,
    required this.overspendAmount,
    required this.planType,
    required this.parameters,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['trigger_transaction_id'] = Variable<String>(triggerTransactionId);
    map['overspend_amount'] = Variable<double>(overspendAmount);
    map['plan_type'] = Variable<String>(planType);
    map['parameters'] = Variable<String>(parameters);
    map['status'] = Variable<String>(status);
    return map;
  }

  RecoveryPlansCompanion toCompanion(bool nullToAbsent) {
    return RecoveryPlansCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      triggerTransactionId: Value(triggerTransactionId),
      overspendAmount: Value(overspendAmount),
      planType: Value(planType),
      parameters: Value(parameters),
      status: Value(status),
    );
  }

  factory RecoveryPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecoveryPlan(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      triggerTransactionId: serializer.fromJson<String>(
        json['triggerTransactionId'],
      ),
      overspendAmount: serializer.fromJson<double>(json['overspendAmount']),
      planType: serializer.fromJson<String>(json['planType']),
      parameters: serializer.fromJson<String>(json['parameters']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'triggerTransactionId': serializer.toJson<String>(triggerTransactionId),
      'overspendAmount': serializer.toJson<double>(overspendAmount),
      'planType': serializer.toJson<String>(planType),
      'parameters': serializer.toJson<String>(parameters),
      'status': serializer.toJson<String>(status),
    };
  }

  RecoveryPlan copyWith({
    String? id,
    DateTime? createdAt,
    String? triggerTransactionId,
    double? overspendAmount,
    String? planType,
    String? parameters,
    String? status,
  }) => RecoveryPlan(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    triggerTransactionId: triggerTransactionId ?? this.triggerTransactionId,
    overspendAmount: overspendAmount ?? this.overspendAmount,
    planType: planType ?? this.planType,
    parameters: parameters ?? this.parameters,
    status: status ?? this.status,
  );
  RecoveryPlan copyWithCompanion(RecoveryPlansCompanion data) {
    return RecoveryPlan(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      triggerTransactionId:
          data.triggerTransactionId.present
              ? data.triggerTransactionId.value
              : this.triggerTransactionId,
      overspendAmount:
          data.overspendAmount.present
              ? data.overspendAmount.value
              : this.overspendAmount,
      planType: data.planType.present ? data.planType.value : this.planType,
      parameters:
          data.parameters.present ? data.parameters.value : this.parameters,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryPlan(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('triggerTransactionId: $triggerTransactionId, ')
          ..write('overspendAmount: $overspendAmount, ')
          ..write('planType: $planType, ')
          ..write('parameters: $parameters, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    triggerTransactionId,
    overspendAmount,
    planType,
    parameters,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecoveryPlan &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.triggerTransactionId == this.triggerTransactionId &&
          other.overspendAmount == this.overspendAmount &&
          other.planType == this.planType &&
          other.parameters == this.parameters &&
          other.status == this.status);
}

class RecoveryPlansCompanion extends UpdateCompanion<RecoveryPlan> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> triggerTransactionId;
  final Value<double> overspendAmount;
  final Value<String> planType;
  final Value<String> parameters;
  final Value<String> status;
  final Value<int> rowid;
  const RecoveryPlansCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.triggerTransactionId = const Value.absent(),
    this.overspendAmount = const Value.absent(),
    this.planType = const Value.absent(),
    this.parameters = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecoveryPlansCompanion.insert({
    required String id,
    required DateTime createdAt,
    required String triggerTransactionId,
    required double overspendAmount,
    required String planType,
    this.parameters = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       triggerTransactionId = Value(triggerTransactionId),
       overspendAmount = Value(overspendAmount),
       planType = Value(planType);
  static Insertable<RecoveryPlan> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? triggerTransactionId,
    Expression<double>? overspendAmount,
    Expression<String>? planType,
    Expression<String>? parameters,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (triggerTransactionId != null)
        'trigger_transaction_id': triggerTransactionId,
      if (overspendAmount != null) 'overspend_amount': overspendAmount,
      if (planType != null) 'plan_type': planType,
      if (parameters != null) 'parameters': parameters,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecoveryPlansCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? triggerTransactionId,
    Value<double>? overspendAmount,
    Value<String>? planType,
    Value<String>? parameters,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return RecoveryPlansCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      triggerTransactionId: triggerTransactionId ?? this.triggerTransactionId,
      overspendAmount: overspendAmount ?? this.overspendAmount,
      planType: planType ?? this.planType,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (triggerTransactionId.present) {
      map['trigger_transaction_id'] = Variable<String>(
        triggerTransactionId.value,
      );
    }
    if (overspendAmount.present) {
      map['overspend_amount'] = Variable<double>(overspendAmount.value);
    }
    if (planType.present) {
      map['plan_type'] = Variable<String>(planType.value);
    }
    if (parameters.present) {
      map['parameters'] = Variable<String>(parameters.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecoveryPlansCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('triggerTransactionId: $triggerTransactionId, ')
          ..write('overspendAmount: $overspendAmount, ')
          ..write('planType: $planType, ')
          ..write('parameters: $parameters, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulerMetadataTable extends SchedulerMetadata
    with TableInfo<$SchedulerMetadataTable, SchedulerMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulerMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduler_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchedulerMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SchedulerMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchedulerMetadataData(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $SchedulerMetadataTable createAlias(String alias) {
    return $SchedulerMetadataTable(attachedDatabase, alias);
  }
}

class SchedulerMetadataData extends DataClass
    implements Insertable<SchedulerMetadataData> {
  final String key;
  final String value;
  const SchedulerMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SchedulerMetadataCompanion toCompanion(bool nullToAbsent) {
    return SchedulerMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SchedulerMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchedulerMetadataData(
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

  SchedulerMetadataData copyWith({String? key, String? value}) =>
      SchedulerMetadataData(key: key ?? this.key, value: value ?? this.value);
  SchedulerMetadataData copyWithCompanion(SchedulerMetadataCompanion data) {
    return SchedulerMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchedulerMetadataData(')
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
      (other is SchedulerMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class SchedulerMetadataCompanion
    extends UpdateCompanion<SchedulerMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SchedulerMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulerMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SchedulerMetadataData> custom({
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

  SchedulerMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SchedulerMetadataCompanion(
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
    return (StringBuffer('SchedulerMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SaplingDatabase extends GeneratedDatabase {
  _$SaplingDatabase(QueryExecutor e) : super(e);
  $SaplingDatabaseManager get managers => $SaplingDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $RecurringIncomesTable recurringIncomes = $RecurringIncomesTable(
    this,
  );
  late final $BillsTable bills = $BillsTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $SplitEntriesTable splitEntries = $SplitEntriesTable(this);
  late final $SplitSharesTable splitShares = $SplitSharesTable(this);
  late final $DailyCloseoutsTable dailyCloseouts = $DailyCloseoutsTable(this);
  late final $RecoveryPlansTable recoveryPlans = $RecoveryPlansTable(this);
  late final $SchedulerMetadataTable schedulerMetadata =
      $SchedulerMetadataTable(this);
  late final Index idxTransactionsDate = Index(
    'idx_transactions_date',
    'CREATE INDEX idx_transactions_date ON transactions (date)',
  );
  late final Index idxTransactionsTypeDate = Index(
    'idx_transactions_type_date',
    'CREATE INDEX idx_transactions_type_date ON transactions (type, date)',
  );
  late final Index idxTransactionsLinkedBill = Index(
    'idx_transactions_linked_bill',
    'CREATE INDEX idx_transactions_linked_bill ON transactions (linked_bill_id)',
  );
  late final Index idxRecurringIncomesNextPayday = Index(
    'idx_recurring_incomes_next_payday',
    'CREATE INDEX idx_recurring_incomes_next_payday ON recurring_incomes (next_payday_date)',
  );
  late final Index idxBillsNextDue = Index(
    'idx_bills_next_due',
    'CREATE INDEX idx_bills_next_due ON bills (next_due_date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    transactions,
    categories,
    goals,
    recurringIncomes,
    bills,
    persons,
    splitEntries,
    splitShares,
    dailyCloseouts,
    recoveryPlans,
    schedulerMetadata,
    idxTransactionsDate,
    idxTransactionsTypeDate,
    idxTransactionsLinkedBill,
    idxRecurringIncomesNextPayday,
    idxBillsNextDue,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<String> baseCurrency,
      Value<String> rolloverResetType,
      Value<int> spendingBaselineDays,
      Value<String> allowanceDefaultMode,
      Value<String?> primaryGoalId,
      Value<String?> paydayAnchorRecurringIncomeId,
      Value<String> defaultPaydayBehavior,
      Value<bool> paydayEnabled,
      Value<bool> billsEnabled,
      Value<bool> overspendEnabled,
      Value<bool> cycleResetEnabled,
      Value<bool> nightlyCloseoutEnabled,
      Value<String> nightlyCloseoutTime,
      Value<bool> onboardingCompleted,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<String> baseCurrency,
      Value<String> rolloverResetType,
      Value<int> spendingBaselineDays,
      Value<String> allowanceDefaultMode,
      Value<String?> primaryGoalId,
      Value<String?> paydayAnchorRecurringIncomeId,
      Value<String> defaultPaydayBehavior,
      Value<bool> paydayEnabled,
      Value<bool> billsEnabled,
      Value<bool> overspendEnabled,
      Value<bool> cycleResetEnabled,
      Value<bool> nightlyCloseoutEnabled,
      Value<String> nightlyCloseoutTime,
      Value<bool> onboardingCompleted,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$SaplingDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rolloverResetType => $composableBuilder(
    column: $table.rolloverResetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spendingBaselineDays => $composableBuilder(
    column: $table.spendingBaselineDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allowanceDefaultMode => $composableBuilder(
    column: $table.allowanceDefaultMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryGoalId => $composableBuilder(
    column: $table.primaryGoalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paydayAnchorRecurringIncomeId => $composableBuilder(
    column: $table.paydayAnchorRecurringIncomeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultPaydayBehavior => $composableBuilder(
    column: $table.defaultPaydayBehavior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paydayEnabled => $composableBuilder(
    column: $table.paydayEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get billsEnabled => $composableBuilder(
    column: $table.billsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get overspendEnabled => $composableBuilder(
    column: $table.overspendEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cycleResetEnabled => $composableBuilder(
    column: $table.cycleResetEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nightlyCloseoutEnabled => $composableBuilder(
    column: $table.nightlyCloseoutEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nightlyCloseoutTime => $composableBuilder(
    column: $table.nightlyCloseoutTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$SaplingDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rolloverResetType => $composableBuilder(
    column: $table.rolloverResetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spendingBaselineDays => $composableBuilder(
    column: $table.spendingBaselineDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allowanceDefaultMode => $composableBuilder(
    column: $table.allowanceDefaultMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryGoalId => $composableBuilder(
    column: $table.primaryGoalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paydayAnchorRecurringIncomeId =>
      $composableBuilder(
        column: $table.paydayAnchorRecurringIncomeId,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get defaultPaydayBehavior => $composableBuilder(
    column: $table.defaultPaydayBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paydayEnabled => $composableBuilder(
    column: $table.paydayEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get billsEnabled => $composableBuilder(
    column: $table.billsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get overspendEnabled => $composableBuilder(
    column: $table.overspendEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cycleResetEnabled => $composableBuilder(
    column: $table.cycleResetEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nightlyCloseoutEnabled => $composableBuilder(
    column: $table.nightlyCloseoutEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nightlyCloseoutTime => $composableBuilder(
    column: $table.nightlyCloseoutTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rolloverResetType => $composableBuilder(
    column: $table.rolloverResetType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spendingBaselineDays => $composableBuilder(
    column: $table.spendingBaselineDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get allowanceDefaultMode => $composableBuilder(
    column: $table.allowanceDefaultMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryGoalId => $composableBuilder(
    column: $table.primaryGoalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paydayAnchorRecurringIncomeId =>
      $composableBuilder(
        column: $table.paydayAnchorRecurringIncomeId,
        builder: (column) => column,
      );

  GeneratedColumn<String> get defaultPaydayBehavior => $composableBuilder(
    column: $table.defaultPaydayBehavior,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get paydayEnabled => $composableBuilder(
    column: $table.paydayEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get billsEnabled => $composableBuilder(
    column: $table.billsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get overspendEnabled => $composableBuilder(
    column: $table.overspendEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cycleResetEnabled => $composableBuilder(
    column: $table.cycleResetEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get nightlyCloseoutEnabled => $composableBuilder(
    column: $table.nightlyCloseoutEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nightlyCloseoutTime => $composableBuilder(
    column: $table.nightlyCloseoutTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$SaplingDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$SaplingDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> rolloverResetType = const Value.absent(),
                Value<int> spendingBaselineDays = const Value.absent(),
                Value<String> allowanceDefaultMode = const Value.absent(),
                Value<String?> primaryGoalId = const Value.absent(),
                Value<String?> paydayAnchorRecurringIncomeId =
                    const Value.absent(),
                Value<String> defaultPaydayBehavior = const Value.absent(),
                Value<bool> paydayEnabled = const Value.absent(),
                Value<bool> billsEnabled = const Value.absent(),
                Value<bool> overspendEnabled = const Value.absent(),
                Value<bool> cycleResetEnabled = const Value.absent(),
                Value<bool> nightlyCloseoutEnabled = const Value.absent(),
                Value<String> nightlyCloseoutTime = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                baseCurrency: baseCurrency,
                rolloverResetType: rolloverResetType,
                spendingBaselineDays: spendingBaselineDays,
                allowanceDefaultMode: allowanceDefaultMode,
                primaryGoalId: primaryGoalId,
                paydayAnchorRecurringIncomeId: paydayAnchorRecurringIncomeId,
                defaultPaydayBehavior: defaultPaydayBehavior,
                paydayEnabled: paydayEnabled,
                billsEnabled: billsEnabled,
                overspendEnabled: overspendEnabled,
                cycleResetEnabled: cycleResetEnabled,
                nightlyCloseoutEnabled: nightlyCloseoutEnabled,
                nightlyCloseoutTime: nightlyCloseoutTime,
                onboardingCompleted: onboardingCompleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> rolloverResetType = const Value.absent(),
                Value<int> spendingBaselineDays = const Value.absent(),
                Value<String> allowanceDefaultMode = const Value.absent(),
                Value<String?> primaryGoalId = const Value.absent(),
                Value<String?> paydayAnchorRecurringIncomeId =
                    const Value.absent(),
                Value<String> defaultPaydayBehavior = const Value.absent(),
                Value<bool> paydayEnabled = const Value.absent(),
                Value<bool> billsEnabled = const Value.absent(),
                Value<bool> overspendEnabled = const Value.absent(),
                Value<bool> cycleResetEnabled = const Value.absent(),
                Value<bool> nightlyCloseoutEnabled = const Value.absent(),
                Value<String> nightlyCloseoutTime = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                baseCurrency: baseCurrency,
                rolloverResetType: rolloverResetType,
                spendingBaselineDays: spendingBaselineDays,
                allowanceDefaultMode: allowanceDefaultMode,
                primaryGoalId: primaryGoalId,
                paydayAnchorRecurringIncomeId: paydayAnchorRecurringIncomeId,
                defaultPaydayBehavior: defaultPaydayBehavior,
                paydayEnabled: paydayEnabled,
                billsEnabled: billsEnabled,
                overspendEnabled: overspendEnabled,
                cycleResetEnabled: cycleResetEnabled,
                nightlyCloseoutEnabled: nightlyCloseoutEnabled,
                nightlyCloseoutTime: nightlyCloseoutTime,
                onboardingCompleted: onboardingCompleted,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$SaplingDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String type,
      required double amount,
      required DateTime date,
      Value<String?> categoryId,
      Value<String?> label,
      Value<String?> note,
      Value<String?> linkedBillId,
      Value<String?> linkedRecurringIncomeId,
      Value<String?> linkedSplitEntryId,
      Value<String?> incomePostingType,
      Value<String?> source,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<double> amount,
      Value<DateTime> date,
      Value<String?> categoryId,
      Value<String?> label,
      Value<String?> note,
      Value<String?> linkedBillId,
      Value<String?> linkedRecurringIncomeId,
      Value<String?> linkedSplitEntryId,
      Value<String?> incomePostingType,
      Value<String?> source,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$SaplingDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedBillId => $composableBuilder(
    column: $table.linkedBillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedRecurringIncomeId => $composableBuilder(
    column: $table.linkedRecurringIncomeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedSplitEntryId => $composableBuilder(
    column: $table.linkedSplitEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomePostingType => $composableBuilder(
    column: $table.incomePostingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$SaplingDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedBillId => $composableBuilder(
    column: $table.linkedBillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedRecurringIncomeId => $composableBuilder(
    column: $table.linkedRecurringIncomeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedSplitEntryId => $composableBuilder(
    column: $table.linkedSplitEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomePostingType => $composableBuilder(
    column: $table.incomePostingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get linkedBillId => $composableBuilder(
    column: $table.linkedBillId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedRecurringIncomeId => $composableBuilder(
    column: $table.linkedRecurringIncomeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedSplitEntryId => $composableBuilder(
    column: $table.linkedSplitEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get incomePostingType => $composableBuilder(
    column: $table.incomePostingType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$SaplingDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(
    _$SaplingDatabase db,
    $TransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> linkedBillId = const Value.absent(),
                Value<String?> linkedRecurringIncomeId = const Value.absent(),
                Value<String?> linkedSplitEntryId = const Value.absent(),
                Value<String?> incomePostingType = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amount: amount,
                date: date,
                categoryId: categoryId,
                label: label,
                note: note,
                linkedBillId: linkedBillId,
                linkedRecurringIncomeId: linkedRecurringIncomeId,
                linkedSplitEntryId: linkedSplitEntryId,
                incomePostingType: incomePostingType,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required double amount,
                required DateTime date,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> linkedBillId = const Value.absent(),
                Value<String?> linkedRecurringIncomeId = const Value.absent(),
                Value<String?> linkedSplitEntryId = const Value.absent(),
                Value<String?> incomePostingType = const Value.absent(),
                Value<String?> source = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                date: date,
                categoryId: categoryId,
                label: label,
                note: note,
                linkedBillId: linkedBillId,
                linkedRecurringIncomeId: linkedRecurringIncomeId,
                linkedSplitEntryId: linkedSplitEntryId,
                incomePostingType: incomePostingType,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$SaplingDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      Value<String> defaultLabel,
      Value<bool> isSystem,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> defaultLabel,
      Value<bool> isSystem,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$SaplingDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultLabel => $composableBuilder(
    column: $table.defaultLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$SaplingDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultLabel => $composableBuilder(
    column: $table.defaultLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get defaultLabel => $composableBuilder(
    column: $table.defaultLabel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            Category,
            BaseReferences<_$SaplingDatabase, $CategoriesTable, Category>,
          ),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$SaplingDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> defaultLabel = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                defaultLabel: defaultLabel,
                isSystem: isSystem,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> defaultLabel = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                defaultLabel: defaultLabel,
                isSystem: isSystem,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$SaplingDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String name,
      required double targetAmount,
      required DateTime targetDate,
      Value<String> savingStyle,
      Value<int> priorityOrder,
      Value<bool> isArchived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> targetAmount,
      Value<DateTime> targetDate,
      Value<String> savingStyle,
      Value<int> priorityOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer
    extends Composer<_$SaplingDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savingStyle => $composableBuilder(
    column: $table.savingStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priorityOrder => $composableBuilder(
    column: $table.priorityOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$SaplingDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savingStyle => $composableBuilder(
    column: $table.savingStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priorityOrder => $composableBuilder(
    column: $table.priorityOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get savingStyle => $composableBuilder(
    column: $table.savingStyle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priorityOrder => $composableBuilder(
    column: $table.priorityOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$SaplingDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$SaplingDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> targetAmount = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<String> savingStyle = const Value.absent(),
                Value<int> priorityOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                targetAmount: targetAmount,
                targetDate: targetDate,
                savingStyle: savingStyle,
                priorityOrder: priorityOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double targetAmount,
                required DateTime targetDate,
                Value<String> savingStyle = const Value.absent(),
                Value<int> priorityOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                targetAmount: targetAmount,
                targetDate: targetDate,
                savingStyle: savingStyle,
                priorityOrder: priorityOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$SaplingDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$RecurringIncomesTableCreateCompanionBuilder =
    RecurringIncomesCompanion Function({
      required String id,
      required String name,
      Value<String> frequency,
      required DateTime nextPaydayDate,
      Value<double?> expectedAmount,
      Value<String> paydayBehavior,
      Value<bool> isPaydayAnchorEligible,
      Value<bool> isPaydayAnchor,
      Value<bool> reminderEnabled,
      Value<String?> reminderTime,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RecurringIncomesTableUpdateCompanionBuilder =
    RecurringIncomesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> frequency,
      Value<DateTime> nextPaydayDate,
      Value<double?> expectedAmount,
      Value<String> paydayBehavior,
      Value<bool> isPaydayAnchorEligible,
      Value<bool> isPaydayAnchor,
      Value<bool> reminderEnabled,
      Value<String?> reminderTime,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RecurringIncomesTableFilterComposer
    extends Composer<_$SaplingDatabase, $RecurringIncomesTable> {
  $$RecurringIncomesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextPaydayDate => $composableBuilder(
    column: $table.nextPaydayDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paydayBehavior => $composableBuilder(
    column: $table.paydayBehavior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaydayAnchorEligible => $composableBuilder(
    column: $table.isPaydayAnchorEligible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaydayAnchor => $composableBuilder(
    column: $table.isPaydayAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurringIncomesTableOrderingComposer
    extends Composer<_$SaplingDatabase, $RecurringIncomesTable> {
  $$RecurringIncomesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextPaydayDate => $composableBuilder(
    column: $table.nextPaydayDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paydayBehavior => $composableBuilder(
    column: $table.paydayBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaydayAnchorEligible => $composableBuilder(
    column: $table.isPaydayAnchorEligible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaydayAnchor => $composableBuilder(
    column: $table.isPaydayAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringIncomesTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $RecurringIncomesTable> {
  $$RecurringIncomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get nextPaydayDate => $composableBuilder(
    column: $table.nextPaydayDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get expectedAmount => $composableBuilder(
    column: $table.expectedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paydayBehavior => $composableBuilder(
    column: $table.paydayBehavior,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaydayAnchorEligible => $composableBuilder(
    column: $table.isPaydayAnchorEligible,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaydayAnchor => $composableBuilder(
    column: $table.isPaydayAnchor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecurringIncomesTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $RecurringIncomesTable,
          RecurringIncome,
          $$RecurringIncomesTableFilterComposer,
          $$RecurringIncomesTableOrderingComposer,
          $$RecurringIncomesTableAnnotationComposer,
          $$RecurringIncomesTableCreateCompanionBuilder,
          $$RecurringIncomesTableUpdateCompanionBuilder,
          (
            RecurringIncome,
            BaseReferences<
              _$SaplingDatabase,
              $RecurringIncomesTable,
              RecurringIncome
            >,
          ),
          RecurringIncome,
          PrefetchHooks Function()
        > {
  $$RecurringIncomesTableTableManager(
    _$SaplingDatabase db,
    $RecurringIncomesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$RecurringIncomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$RecurringIncomesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$RecurringIncomesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<DateTime> nextPaydayDate = const Value.absent(),
                Value<double?> expectedAmount = const Value.absent(),
                Value<String> paydayBehavior = const Value.absent(),
                Value<bool> isPaydayAnchorEligible = const Value.absent(),
                Value<bool> isPaydayAnchor = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringIncomesCompanion(
                id: id,
                name: name,
                frequency: frequency,
                nextPaydayDate: nextPaydayDate,
                expectedAmount: expectedAmount,
                paydayBehavior: paydayBehavior,
                isPaydayAnchorEligible: isPaydayAnchorEligible,
                isPaydayAnchor: isPaydayAnchor,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> frequency = const Value.absent(),
                required DateTime nextPaydayDate,
                Value<double?> expectedAmount = const Value.absent(),
                Value<String> paydayBehavior = const Value.absent(),
                Value<bool> isPaydayAnchorEligible = const Value.absent(),
                Value<bool> isPaydayAnchor = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RecurringIncomesCompanion.insert(
                id: id,
                name: name,
                frequency: frequency,
                nextPaydayDate: nextPaydayDate,
                expectedAmount: expectedAmount,
                paydayBehavior: paydayBehavior,
                isPaydayAnchorEligible: isPaydayAnchorEligible,
                isPaydayAnchor: isPaydayAnchor,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurringIncomesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $RecurringIncomesTable,
      RecurringIncome,
      $$RecurringIncomesTableFilterComposer,
      $$RecurringIncomesTableOrderingComposer,
      $$RecurringIncomesTableAnnotationComposer,
      $$RecurringIncomesTableCreateCompanionBuilder,
      $$RecurringIncomesTableUpdateCompanionBuilder,
      (
        RecurringIncome,
        BaseReferences<
          _$SaplingDatabase,
          $RecurringIncomesTable,
          RecurringIncome
        >,
      ),
      RecurringIncome,
      PrefetchHooks Function()
    >;
typedef $$BillsTableCreateCompanionBuilder =
    BillsCompanion Function({
      required String id,
      required String name,
      required double amount,
      Value<String> frequency,
      required DateTime nextDueDate,
      required String categoryId,
      Value<String> defaultLabel,
      Value<bool> autopay,
      Value<bool> reminderEnabled,
      Value<int> reminderLeadTimeDays,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BillsTableUpdateCompanionBuilder =
    BillsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> amount,
      Value<String> frequency,
      Value<DateTime> nextDueDate,
      Value<String> categoryId,
      Value<String> defaultLabel,
      Value<bool> autopay,
      Value<bool> reminderEnabled,
      Value<int> reminderLeadTimeDays,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BillsTableFilterComposer
    extends Composer<_$SaplingDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultLabel => $composableBuilder(
    column: $table.defaultLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autopay => $composableBuilder(
    column: $table.autopay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderLeadTimeDays => $composableBuilder(
    column: $table.reminderLeadTimeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BillsTableOrderingComposer
    extends Composer<_$SaplingDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultLabel => $composableBuilder(
    column: $table.defaultLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autopay => $composableBuilder(
    column: $table.autopay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderLeadTimeDays => $composableBuilder(
    column: $table.reminderLeadTimeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillsTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
    column: $table.nextDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultLabel => $composableBuilder(
    column: $table.defaultLabel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autopay =>
      $composableBuilder(column: $table.autopay, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderLeadTimeDays => $composableBuilder(
    column: $table.reminderLeadTimeDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BillsTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $BillsTable,
          Bill,
          $$BillsTableFilterComposer,
          $$BillsTableOrderingComposer,
          $$BillsTableAnnotationComposer,
          $$BillsTableCreateCompanionBuilder,
          $$BillsTableUpdateCompanionBuilder,
          (Bill, BaseReferences<_$SaplingDatabase, $BillsTable, Bill>),
          Bill,
          PrefetchHooks Function()
        > {
  $$BillsTableTableManager(_$SaplingDatabase db, $BillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<DateTime> nextDueDate = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> defaultLabel = const Value.absent(),
                Value<bool> autopay = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderLeadTimeDays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion(
                id: id,
                name: name,
                amount: amount,
                frequency: frequency,
                nextDueDate: nextDueDate,
                categoryId: categoryId,
                defaultLabel: defaultLabel,
                autopay: autopay,
                reminderEnabled: reminderEnabled,
                reminderLeadTimeDays: reminderLeadTimeDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double amount,
                Value<String> frequency = const Value.absent(),
                required DateTime nextDueDate,
                required String categoryId,
                Value<String> defaultLabel = const Value.absent(),
                Value<bool> autopay = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderLeadTimeDays = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                frequency: frequency,
                nextDueDate: nextDueDate,
                categoryId: categoryId,
                defaultLabel: defaultLabel,
                autopay: autopay,
                reminderEnabled: reminderEnabled,
                reminderLeadTimeDays: reminderLeadTimeDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BillsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $BillsTable,
      Bill,
      $$BillsTableFilterComposer,
      $$BillsTableOrderingComposer,
      $$BillsTableAnnotationComposer,
      $$BillsTableCreateCompanionBuilder,
      $$BillsTableUpdateCompanionBuilder,
      (Bill, BaseReferences<_$SaplingDatabase, $BillsTable, Bill>),
      Bill,
      PrefetchHooks Function()
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      required String id,
      required String name,
      Value<String?> handle,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> handle,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PersonsTableFilterComposer
    extends Composer<_$SaplingDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonsTableOrderingComposer
    extends Composer<_$SaplingDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, BaseReferences<_$SaplingDatabase, $PersonsTable, Person>),
          Person,
          PrefetchHooks Function()
        > {
  $$PersonsTableTableManager(_$SaplingDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> handle = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion(
                id: id,
                name: name,
                handle: handle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> handle = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion.insert(
                id: id,
                name: name,
                handle: handle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, BaseReferences<_$SaplingDatabase, $PersonsTable, Person>),
      Person,
      PrefetchHooks Function()
    >;
typedef $$SplitEntriesTableCreateCompanionBuilder =
    SplitEntriesCompanion Function({
      required String id,
      required DateTime date,
      required String description,
      required double totalAmount,
      required String paidBy,
      Value<String?> linkToExpenseTransactionId,
      Value<String> status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SplitEntriesTableUpdateCompanionBuilder =
    SplitEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String> description,
      Value<double> totalAmount,
      Value<String> paidBy,
      Value<String?> linkToExpenseTransactionId,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SplitEntriesTableFilterComposer
    extends Composer<_$SaplingDatabase, $SplitEntriesTable> {
  $$SplitEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidBy => $composableBuilder(
    column: $table.paidBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkToExpenseTransactionId => $composableBuilder(
    column: $table.linkToExpenseTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitEntriesTableOrderingComposer
    extends Composer<_$SaplingDatabase, $SplitEntriesTable> {
  $$SplitEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidBy => $composableBuilder(
    column: $table.paidBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkToExpenseTransactionId => $composableBuilder(
    column: $table.linkToExpenseTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitEntriesTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $SplitEntriesTable> {
  $$SplitEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paidBy =>
      $composableBuilder(column: $table.paidBy, builder: (column) => column);

  GeneratedColumn<String> get linkToExpenseTransactionId => $composableBuilder(
    column: $table.linkToExpenseTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SplitEntriesTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $SplitEntriesTable,
          SplitEntry,
          $$SplitEntriesTableFilterComposer,
          $$SplitEntriesTableOrderingComposer,
          $$SplitEntriesTableAnnotationComposer,
          $$SplitEntriesTableCreateCompanionBuilder,
          $$SplitEntriesTableUpdateCompanionBuilder,
          (
            SplitEntry,
            BaseReferences<_$SaplingDatabase, $SplitEntriesTable, SplitEntry>,
          ),
          SplitEntry,
          PrefetchHooks Function()
        > {
  $$SplitEntriesTableTableManager(
    _$SaplingDatabase db,
    $SplitEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SplitEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SplitEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SplitEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> paidBy = const Value.absent(),
                Value<String?> linkToExpenseTransactionId =
                    const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitEntriesCompanion(
                id: id,
                date: date,
                description: description,
                totalAmount: totalAmount,
                paidBy: paidBy,
                linkToExpenseTransactionId: linkToExpenseTransactionId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String description,
                required double totalAmount,
                required String paidBy,
                Value<String?> linkToExpenseTransactionId =
                    const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SplitEntriesCompanion.insert(
                id: id,
                date: date,
                description: description,
                totalAmount: totalAmount,
                paidBy: paidBy,
                linkToExpenseTransactionId: linkToExpenseTransactionId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $SplitEntriesTable,
      SplitEntry,
      $$SplitEntriesTableFilterComposer,
      $$SplitEntriesTableOrderingComposer,
      $$SplitEntriesTableAnnotationComposer,
      $$SplitEntriesTableCreateCompanionBuilder,
      $$SplitEntriesTableUpdateCompanionBuilder,
      (
        SplitEntry,
        BaseReferences<_$SaplingDatabase, $SplitEntriesTable, SplitEntry>,
      ),
      SplitEntry,
      PrefetchHooks Function()
    >;
typedef $$SplitSharesTableCreateCompanionBuilder =
    SplitSharesCompanion Function({
      required String id,
      required String splitEntryId,
      required String personId,
      required double shareAmount,
      Value<int> rowid,
    });
typedef $$SplitSharesTableUpdateCompanionBuilder =
    SplitSharesCompanion Function({
      Value<String> id,
      Value<String> splitEntryId,
      Value<String> personId,
      Value<double> shareAmount,
      Value<int> rowid,
    });

class $$SplitSharesTableFilterComposer
    extends Composer<_$SaplingDatabase, $SplitSharesTable> {
  $$SplitSharesTableFilterComposer({
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

  ColumnFilters<String> get splitEntryId => $composableBuilder(
    column: $table.splitEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shareAmount => $composableBuilder(
    column: $table.shareAmount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SplitSharesTableOrderingComposer
    extends Composer<_$SaplingDatabase, $SplitSharesTable> {
  $$SplitSharesTableOrderingComposer({
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

  ColumnOrderings<String> get splitEntryId => $composableBuilder(
    column: $table.splitEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shareAmount => $composableBuilder(
    column: $table.shareAmount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SplitSharesTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $SplitSharesTable> {
  $$SplitSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get splitEntryId => $composableBuilder(
    column: $table.splitEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<double> get shareAmount => $composableBuilder(
    column: $table.shareAmount,
    builder: (column) => column,
  );
}

class $$SplitSharesTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $SplitSharesTable,
          SplitShare,
          $$SplitSharesTableFilterComposer,
          $$SplitSharesTableOrderingComposer,
          $$SplitSharesTableAnnotationComposer,
          $$SplitSharesTableCreateCompanionBuilder,
          $$SplitSharesTableUpdateCompanionBuilder,
          (
            SplitShare,
            BaseReferences<_$SaplingDatabase, $SplitSharesTable, SplitShare>,
          ),
          SplitShare,
          PrefetchHooks Function()
        > {
  $$SplitSharesTableTableManager(_$SaplingDatabase db, $SplitSharesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SplitSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SplitSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SplitSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> splitEntryId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<double> shareAmount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitSharesCompanion(
                id: id,
                splitEntryId: splitEntryId,
                personId: personId,
                shareAmount: shareAmount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String splitEntryId,
                required String personId,
                required double shareAmount,
                Value<int> rowid = const Value.absent(),
              }) => SplitSharesCompanion.insert(
                id: id,
                splitEntryId: splitEntryId,
                personId: personId,
                shareAmount: shareAmount,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SplitSharesTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $SplitSharesTable,
      SplitShare,
      $$SplitSharesTableFilterComposer,
      $$SplitSharesTableOrderingComposer,
      $$SplitSharesTableAnnotationComposer,
      $$SplitSharesTableCreateCompanionBuilder,
      $$SplitSharesTableUpdateCompanionBuilder,
      (
        SplitShare,
        BaseReferences<_$SaplingDatabase, $SplitSharesTable, SplitShare>,
      ),
      SplitShare,
      PrefetchHooks Function()
    >;
typedef $$DailyCloseoutsTableCreateCompanionBuilder =
    DailyCloseoutsCompanion Function({
      required String id,
      required DateTime date,
      required String result,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DailyCloseoutsTableUpdateCompanionBuilder =
    DailyCloseoutsCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String> result,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DailyCloseoutsTableFilterComposer
    extends Composer<_$SaplingDatabase, $DailyCloseoutsTable> {
  $$DailyCloseoutsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyCloseoutsTableOrderingComposer
    extends Composer<_$SaplingDatabase, $DailyCloseoutsTable> {
  $$DailyCloseoutsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyCloseoutsTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $DailyCloseoutsTable> {
  $$DailyCloseoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyCloseoutsTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $DailyCloseoutsTable,
          DailyCloseout,
          $$DailyCloseoutsTableFilterComposer,
          $$DailyCloseoutsTableOrderingComposer,
          $$DailyCloseoutsTableAnnotationComposer,
          $$DailyCloseoutsTableCreateCompanionBuilder,
          $$DailyCloseoutsTableUpdateCompanionBuilder,
          (
            DailyCloseout,
            BaseReferences<
              _$SaplingDatabase,
              $DailyCloseoutsTable,
              DailyCloseout
            >,
          ),
          DailyCloseout,
          PrefetchHooks Function()
        > {
  $$DailyCloseoutsTableTableManager(
    _$SaplingDatabase db,
    $DailyCloseoutsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$DailyCloseoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$DailyCloseoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$DailyCloseoutsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCloseoutsCompanion(
                id: id,
                date: date,
                result: result,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String result,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyCloseoutsCompanion.insert(
                id: id,
                date: date,
                result: result,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyCloseoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $DailyCloseoutsTable,
      DailyCloseout,
      $$DailyCloseoutsTableFilterComposer,
      $$DailyCloseoutsTableOrderingComposer,
      $$DailyCloseoutsTableAnnotationComposer,
      $$DailyCloseoutsTableCreateCompanionBuilder,
      $$DailyCloseoutsTableUpdateCompanionBuilder,
      (
        DailyCloseout,
        BaseReferences<_$SaplingDatabase, $DailyCloseoutsTable, DailyCloseout>,
      ),
      DailyCloseout,
      PrefetchHooks Function()
    >;
typedef $$RecoveryPlansTableCreateCompanionBuilder =
    RecoveryPlansCompanion Function({
      required String id,
      required DateTime createdAt,
      required String triggerTransactionId,
      required double overspendAmount,
      required String planType,
      Value<String> parameters,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$RecoveryPlansTableUpdateCompanionBuilder =
    RecoveryPlansCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<String> triggerTransactionId,
      Value<double> overspendAmount,
      Value<String> planType,
      Value<String> parameters,
      Value<String> status,
      Value<int> rowid,
    });

class $$RecoveryPlansTableFilterComposer
    extends Composer<_$SaplingDatabase, $RecoveryPlansTable> {
  $$RecoveryPlansTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triggerTransactionId => $composableBuilder(
    column: $table.triggerTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get overspendAmount => $composableBuilder(
    column: $table.overspendAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planType => $composableBuilder(
    column: $table.planType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parameters => $composableBuilder(
    column: $table.parameters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecoveryPlansTableOrderingComposer
    extends Composer<_$SaplingDatabase, $RecoveryPlansTable> {
  $$RecoveryPlansTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerTransactionId => $composableBuilder(
    column: $table.triggerTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get overspendAmount => $composableBuilder(
    column: $table.overspendAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planType => $composableBuilder(
    column: $table.planType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parameters => $composableBuilder(
    column: $table.parameters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecoveryPlansTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $RecoveryPlansTable> {
  $$RecoveryPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get triggerTransactionId => $composableBuilder(
    column: $table.triggerTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get overspendAmount => $composableBuilder(
    column: $table.overspendAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planType =>
      $composableBuilder(column: $table.planType, builder: (column) => column);

  GeneratedColumn<String> get parameters => $composableBuilder(
    column: $table.parameters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$RecoveryPlansTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $RecoveryPlansTable,
          RecoveryPlan,
          $$RecoveryPlansTableFilterComposer,
          $$RecoveryPlansTableOrderingComposer,
          $$RecoveryPlansTableAnnotationComposer,
          $$RecoveryPlansTableCreateCompanionBuilder,
          $$RecoveryPlansTableUpdateCompanionBuilder,
          (
            RecoveryPlan,
            BaseReferences<
              _$SaplingDatabase,
              $RecoveryPlansTable,
              RecoveryPlan
            >,
          ),
          RecoveryPlan,
          PrefetchHooks Function()
        > {
  $$RecoveryPlansTableTableManager(
    _$SaplingDatabase db,
    $RecoveryPlansTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$RecoveryPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$RecoveryPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$RecoveryPlansTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> triggerTransactionId = const Value.absent(),
                Value<double> overspendAmount = const Value.absent(),
                Value<String> planType = const Value.absent(),
                Value<String> parameters = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecoveryPlansCompanion(
                id: id,
                createdAt: createdAt,
                triggerTransactionId: triggerTransactionId,
                overspendAmount: overspendAmount,
                planType: planType,
                parameters: parameters,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required String triggerTransactionId,
                required double overspendAmount,
                required String planType,
                Value<String> parameters = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecoveryPlansCompanion.insert(
                id: id,
                createdAt: createdAt,
                triggerTransactionId: triggerTransactionId,
                overspendAmount: overspendAmount,
                planType: planType,
                parameters: parameters,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecoveryPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $RecoveryPlansTable,
      RecoveryPlan,
      $$RecoveryPlansTableFilterComposer,
      $$RecoveryPlansTableOrderingComposer,
      $$RecoveryPlansTableAnnotationComposer,
      $$RecoveryPlansTableCreateCompanionBuilder,
      $$RecoveryPlansTableUpdateCompanionBuilder,
      (
        RecoveryPlan,
        BaseReferences<_$SaplingDatabase, $RecoveryPlansTable, RecoveryPlan>,
      ),
      RecoveryPlan,
      PrefetchHooks Function()
    >;
typedef $$SchedulerMetadataTableCreateCompanionBuilder =
    SchedulerMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SchedulerMetadataTableUpdateCompanionBuilder =
    SchedulerMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SchedulerMetadataTableFilterComposer
    extends Composer<_$SaplingDatabase, $SchedulerMetadataTable> {
  $$SchedulerMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchedulerMetadataTableOrderingComposer
    extends Composer<_$SaplingDatabase, $SchedulerMetadataTable> {
  $$SchedulerMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchedulerMetadataTableAnnotationComposer
    extends Composer<_$SaplingDatabase, $SchedulerMetadataTable> {
  $$SchedulerMetadataTableAnnotationComposer({
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

class $$SchedulerMetadataTableTableManager
    extends
        RootTableManager<
          _$SaplingDatabase,
          $SchedulerMetadataTable,
          SchedulerMetadataData,
          $$SchedulerMetadataTableFilterComposer,
          $$SchedulerMetadataTableOrderingComposer,
          $$SchedulerMetadataTableAnnotationComposer,
          $$SchedulerMetadataTableCreateCompanionBuilder,
          $$SchedulerMetadataTableUpdateCompanionBuilder,
          (
            SchedulerMetadataData,
            BaseReferences<
              _$SaplingDatabase,
              $SchedulerMetadataTable,
              SchedulerMetadataData
            >,
          ),
          SchedulerMetadataData,
          PrefetchHooks Function()
        > {
  $$SchedulerMetadataTableTableManager(
    _$SaplingDatabase db,
    $SchedulerMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SchedulerMetadataTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$SchedulerMetadataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SchedulerMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulerMetadataCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SchedulerMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchedulerMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$SaplingDatabase,
      $SchedulerMetadataTable,
      SchedulerMetadataData,
      $$SchedulerMetadataTableFilterComposer,
      $$SchedulerMetadataTableOrderingComposer,
      $$SchedulerMetadataTableAnnotationComposer,
      $$SchedulerMetadataTableCreateCompanionBuilder,
      $$SchedulerMetadataTableUpdateCompanionBuilder,
      (
        SchedulerMetadataData,
        BaseReferences<
          _$SaplingDatabase,
          $SchedulerMetadataTable,
          SchedulerMetadataData
        >,
      ),
      SchedulerMetadataData,
      PrefetchHooks Function()
    >;

class $SaplingDatabaseManager {
  final _$SaplingDatabase _db;
  $SaplingDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$RecurringIncomesTableTableManager get recurringIncomes =>
      $$RecurringIncomesTableTableManager(_db, _db.recurringIncomes);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$SplitEntriesTableTableManager get splitEntries =>
      $$SplitEntriesTableTableManager(_db, _db.splitEntries);
  $$SplitSharesTableTableManager get splitShares =>
      $$SplitSharesTableTableManager(_db, _db.splitShares);
  $$DailyCloseoutsTableTableManager get dailyCloseouts =>
      $$DailyCloseoutsTableTableManager(_db, _db.dailyCloseouts);
  $$RecoveryPlansTableTableManager get recoveryPlans =>
      $$RecoveryPlansTableTableManager(_db, _db.recoveryPlans);
  $$SchedulerMetadataTableTableManager get schedulerMetadata =>
      $$SchedulerMetadataTableTableManager(_db, _db.schedulerMetadata);
}
