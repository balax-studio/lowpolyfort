import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'hero_data.dart';
import '../constants/game_balance.dart';

/// Persistent player save data structure with versioning for safe schema migrations.
/// Covers meta-progression, unit unlock tracking, and user preferences (Clauses 104-115, 138, 658, 661, 664).
class PlayerSave {
  static const int currentVersion = 1;

  final int saveVersion;
  final int totalScrap;
  final int highestWave;
  final int totalKills;
  final int totalBossesKilled;
  final int runsPlayed;
  final bool tutorialCompleted;

  // Permanent Upgrades (Clauses 106–111, 646)
  final int permBaseHpLevel; // +50 Base HP per level
  final int permStartingCoinsLevel; // +10 starting coins per level
  final int permDamageLevel; // +2% global damage per level
  final int permAttackSpeedLevel; // +1.5% global attack speed per level
  final int permCritLevel; // +0.5% global crit chance per level
  final int permBountyLevel; // +2% coin bonus per level

  // User Settings (Clause 138, 664)
  final double masterVolume;
  final double sfxVolume;
  final double musicVolume;
  final bool vibrationEnabled;
  final bool showDamageNumbers;
  final String language; // 'en' or 'tr' (Clause 663, 664)

  // Announced unit unlocks (to show "NEW UNIT UNLOCKED!" banner once)
  final List<String> announcedUnitUnlocks;

  // Game Modes Progression & Scores (Clauses 285, 288, 318, 349, 366–368)
  final bool chaosUnlocked;
  final bool bossRushUnlocked;
  final int bestChaosWave;
  final int bestBossRushRound; // 0 to 5

  // Rewarded Ads Rolling 24-Hour Timestamps (Clauses 442-443, 546-547)
  final List<int> rewardedAdCompletionTimestamps;

  const PlayerSave({
    this.saveVersion = currentVersion,
    this.totalScrap = 0,
    this.highestWave = 1,
    this.totalKills = 0,
    this.totalBossesKilled = 0,
    this.runsPlayed = 0,
    this.tutorialCompleted = false,
    this.permBaseHpLevel = 0,
    this.permStartingCoinsLevel = 0,
    this.permDamageLevel = 0,
    this.permAttackSpeedLevel = 0,
    this.permCritLevel = 0,
    this.permBountyLevel = 0,
    this.masterVolume = 1.0,
    this.sfxVolume = 1.0,
    this.musicVolume = 1.0,
    this.vibrationEnabled = true,
    this.showDamageNumbers = true,
    this.language = 'en',
    this.announcedUnitUnlocks = const [],
    this.chaosUnlocked = false,
    this.bossRushUnlocked = false,
    this.bestChaosWave = 0,
    this.bestBossRushRound = 0,
    this.rewardedAdCompletionTimestamps = const [],
  });

  /// Automatically discovers device locale for language default (Clause 664)
  static String getDefaultLanguage() {
    try {
      // ponytail: inspect device locale via stdlib Platform without third-party dependencies
      final locale = Platform.localeName.toLowerCase();
      if (locale.startsWith('tr')) return 'tr';
    } catch (_) {}
    return 'en';
  }

  /// Dynamically computes which units are unlocked based on highest wave milestone (Clause 115)
  List<HeroClass> get unlockedHeroClasses {
    final list = <HeroClass>[HeroClass.rifleman];
    if (highestWave >= GameBalance.unlockWaveShotgunner) {
      list.add(HeroClass.shotgunner);
    }
    if (highestWave >= GameBalance.unlockWaveSniper) {
      list.add(HeroClass.sniper);
    }
    if (highestWave >= GameBalance.unlockWaveHeavyGunner) {
      list.add(HeroClass.heavyGunner);
    }
    return list;
  }

  bool isHeroUnlocked(HeroClass heroClass) {
    return unlockedHeroClasses.contains(heroClass);
  }

  /// Number of completed rewarded ads within the rolling 24-hour window (Clauses 442–443)
  int get completedAdsInRolling24h {
    final cutoff = DateTime.now().toUtc().millisecondsSinceEpoch - (24 * 60 * 60 * 1000);
    return rewardedAdCompletionTimestamps.where((t) => t >= cutoff).length;
  }

  /// Appends a new completion timestamp and prunes records older than 24 hours
  PlayerSave withAdCompletion(int timestamp) {
    final cutoff = timestamp - (24 * 60 * 60 * 1000);
    final updated = [...rewardedAdCompletionTimestamps.where((t) => t >= cutoff), timestamp];
    return copyWith(rewardedAdCompletionTimestamps: updated);
  }

  PlayerSave copyWith({
    int? saveVersion,
    int? totalScrap,
    int? highestWave,
    int? totalKills,
    int? totalBossesKilled,
    int? runsPlayed,
    bool? tutorialCompleted,
    int? permBaseHpLevel,
    int? permStartingCoinsLevel,
    int? permDamageLevel,
    int? permAttackSpeedLevel,
    int? permCritLevel,
    int? permBountyLevel,
    double? masterVolume,
    double? sfxVolume,
    double? musicVolume,
    bool? vibrationEnabled,
    bool? showDamageNumbers,
    String? language,
    List<String>? announcedUnitUnlocks,
    bool? chaosUnlocked,
    bool? bossRushUnlocked,
    int? bestChaosWave,
    int? bestBossRushRound,
    List<int>? rewardedAdCompletionTimestamps,
  }) {
    return PlayerSave(
      saveVersion: saveVersion ?? this.saveVersion,
      totalScrap: totalScrap ?? this.totalScrap,
      highestWave: highestWave ?? this.highestWave,
      totalKills: totalKills ?? this.totalKills,
      totalBossesKilled: totalBossesKilled ?? this.totalBossesKilled,
      runsPlayed: runsPlayed ?? this.runsPlayed,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      permBaseHpLevel: permBaseHpLevel ?? this.permBaseHpLevel,
      permStartingCoinsLevel: permStartingCoinsLevel ?? this.permStartingCoinsLevel,
      permDamageLevel: permDamageLevel ?? this.permDamageLevel,
      permAttackSpeedLevel: permAttackSpeedLevel ?? this.permAttackSpeedLevel,
      permCritLevel: permCritLevel ?? this.permCritLevel,
      permBountyLevel: permBountyLevel ?? this.permBountyLevel,
      masterVolume: masterVolume ?? this.masterVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showDamageNumbers: showDamageNumbers ?? this.showDamageNumbers,
      language: language ?? this.language,
      announcedUnitUnlocks: announcedUnitUnlocks ?? this.announcedUnitUnlocks,
      chaosUnlocked: chaosUnlocked ?? this.chaosUnlocked,
      bossRushUnlocked: bossRushUnlocked ?? this.bossRushUnlocked,
      bestChaosWave: bestChaosWave ?? this.bestChaosWave,
      bestBossRushRound: bestBossRushRound ?? this.bestBossRushRound,
      rewardedAdCompletionTimestamps: rewardedAdCompletionTimestamps ?? this.rewardedAdCompletionTimestamps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'saveVersion': saveVersion,
      'totalScrap': totalScrap,
      'highestWave': highestWave,
      'totalKills': totalKills,
      'totalBossesKilled': totalBossesKilled,
      'runsPlayed': runsPlayed,
      'tutorialCompleted': tutorialCompleted,
      'permBaseHpLevel': permBaseHpLevel,
      'permStartingCoinsLevel': permStartingCoinsLevel,
      'permDamageLevel': permDamageLevel,
      'permAttackSpeedLevel': permAttackSpeedLevel,
      'permCritLevel': permCritLevel,
      'permBountyLevel': permBountyLevel,
      'masterVolume': masterVolume,
      'sfxVolume': sfxVolume,
      'musicVolume': musicVolume,
      'vibrationEnabled': vibrationEnabled,
      'showDamageNumbers': showDamageNumbers,
      'language': language,
      'announcedUnitUnlocks': announcedUnitUnlocks,
      'chaosUnlocked': chaosUnlocked,
      'bossRushUnlocked': bossRushUnlocked,
      'bestChaosWave': bestChaosWave,
      'bestBossRushRound': bestBossRushRound,
      'rewardedAdCompletionTimestamps': rewardedAdCompletionTimestamps,
    };
  }

  factory PlayerSave.fromMap(Map<String, dynamic> map) {
    // Clause 661: Resilient validation & sanitization
    final highestWave = max(1, map['highestWave'] as int? ?? 1);
    final totalScrap = max(0, map['totalScrap'] as int? ?? 0);
    final totalKills = max(0, map['totalKills'] as int? ?? 0);
    final totalBossesKilled = max(0, map['totalBossesKilled'] as int? ?? 0);
    final runsPlayed = max(0, map['runsPlayed'] as int? ?? 0);

    // Backward compatibility & migration (Clauses 367, 368, 547)
    final chaosUnlocked = map['chaosUnlocked'] as bool? ?? (highestWave >= 5);
    final bossRushUnlocked = map['bossRushUnlocked'] as bool? ?? (highestWave >= 10);
    final bestChaosWave = max(0, map['bestChaosWave'] as int? ?? 0);
    final bestBossRushRound = (map['bestBossRushRound'] as int? ?? 0).clamp(0, 5);

    // Clamped permanent upgrade levels (Clauses 646, 661: clamp 0..5)
    final permBaseHpLevel = (map['permBaseHpLevel'] as int? ?? 0).clamp(0, GameBalance.maxPermUpgradeLevel);
    final permStartingCoinsLevel = (map['permStartingCoinsLevel'] as int? ?? 0).clamp(0, GameBalance.maxPermUpgradeLevel);
    final permDamageLevel = (map['permDamageLevel'] as int? ?? 0).clamp(0, GameBalance.maxPermUpgradeLevel);
    final permAttackSpeedLevel = (map['permAttackSpeedLevel'] as int? ?? 0).clamp(0, GameBalance.maxPermUpgradeLevel);
    final permCritLevel = (map['permCritLevel'] as int? ?? 0).clamp(0, GameBalance.maxPermUpgradeLevel);
    final permBountyLevel = (map['permBountyLevel'] as int? ?? 0).clamp(0, GameBalance.maxPermUpgradeLevel);

    final rawLang = map['language'] as String?;
    final language = (rawLang == 'tr' || rawLang == 'en') ? rawLang! : getDefaultLanguage();

    final rewardedAdCompletionTimestamps = (map['rewardedAdCompletionTimestamps'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [];

    return PlayerSave(
      saveVersion: map['saveVersion'] as int? ?? currentVersion,
      totalScrap: totalScrap,
      highestWave: highestWave,
      totalKills: totalKills,
      totalBossesKilled: totalBossesKilled,
      runsPlayed: runsPlayed,
      tutorialCompleted: map['tutorialCompleted'] as bool? ?? false,
      permBaseHpLevel: permBaseHpLevel,
      permStartingCoinsLevel: permStartingCoinsLevel,
      permDamageLevel: permDamageLevel,
      permAttackSpeedLevel: permAttackSpeedLevel,
      permCritLevel: permCritLevel,
      permBountyLevel: permBountyLevel,
      masterVolume: (map['masterVolume'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0,
      sfxVolume: (map['sfxVolume'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0,
      musicVolume: (map['musicVolume'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
      showDamageNumbers: map['showDamageNumbers'] as bool? ?? true,
      language: language,
      announcedUnitUnlocks: (map['announcedUnitUnlocks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      chaosUnlocked: chaosUnlocked,
      bossRushUnlocked: bossRushUnlocked,
      bestChaosWave: bestChaosWave,
      bestBossRushRound: bestBossRushRound,
      rewardedAdCompletionTimestamps: rewardedAdCompletionTimestamps,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlayerSave.fromJson(String source) {
    try {
      final map = json.decode(source) as Map<String, dynamic>;
      return PlayerSave.fromMap(map);
    } catch (_) {
      return const PlayerSave();
    }
  }
}
