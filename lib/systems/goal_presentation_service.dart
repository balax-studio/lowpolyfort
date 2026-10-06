import 'package:flutter/material.dart';
import '../constants/game_balance.dart';
import '../constants/game_colors.dart';
import '../models/hero_data.dart';
import '../models/player_save.dart';

/// Presentation data model for the single prioritized Next Goal (Clauses 180–183, 256–257).
/// Pure display data container with zero gameplay side-effects.
class NextGoalInfo {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;

  const NextGoalInfo({
    required this.title,
    this.subtitle,
    required this.icon,
    this.accentColor = GameColors.acidYellow,
  });
}

/// Pure presentation helper resolving the single highest-priority goal (Clause 182).
/// Priority Order:
/// 1. Boss very close (1 wave away)
/// 2. Upgrade very close (after this wave or 1 wave away)
/// 3. Close to New Best Wave (within 1 wave of high score)
/// 4. Close to Unit Unlock milestone (within 1–2 waves)
/// 5. Fallback: Boss countdown in X waves.
class GoalPresentationService {
  GoalPresentationService._();

  static NextGoalInfo resolveNextGoal({
    required int currentWave,
    required int highestWave,
    required PlayerSave save,
  }) {
    // Distance to next boss wave (5, 10, 15, 20...)
    final nextBossWave = ((currentWave / GameBalance.bossInterval).ceil()) * GameBalance.bossInterval;
    final wavesToBoss = nextBossWave - currentWave;

    // 1. Boss very close (Clause 182: Priority 1)
    if (wavesToBoss == 0) {
      return const NextGoalInfo(
        title: 'BOSS WAVE — SURVIVE!',
        subtitle: 'DEFEAT THE WARLORD',
        icon: Icons.warning,
        accentColor: GameColors.punchRed,
      );
    }
    if (wavesToBoss == 1) {
      return const NextGoalInfo(
        title: 'BOSS NEXT WAVE!',
        subtitle: 'PREPARE DEFENSES',
        icon: Icons.warning_amber,
        accentColor: GameColors.punchRed,
      );
    }

    // 2. Upgrade very close (Clause 182: Priority 2)
    final wavesToUpgrade = GameBalance.upgradeInterval - (currentWave % GameBalance.upgradeInterval);
    if (wavesToUpgrade == GameBalance.upgradeInterval) {
      return const NextGoalInfo(
        title: 'UPGRADE AFTER THIS WAVE!',
        subtitle: '3-CARD DRAFT READY',
        icon: Icons.auto_awesome,
        accentColor: GameColors.electricLime,
      );
    }
    if (wavesToUpgrade == 1) {
      return const NextGoalInfo(
        title: 'UPGRADE IN 1 WAVE',
        subtitle: 'SURVIVE TO DRAFT',
        icon: Icons.auto_awesome,
        accentColor: GameColors.electricLime,
      );
    }

    // 3. Close to New Best Wave (Clause 182: Priority 3)
    if (highestWave > 1 && currentWave >= highestWave) {
      return NextGoalInfo(
        title: 'NEW BEST: WAVE $currentWave!',
        subtitle: 'PUSH THE RECORD',
        icon: Icons.military_tech,
        accentColor: GameColors.electricLime,
      );
    }
    if (highestWave > 1 && currentWave == highestWave - 1) {
      return const NextGoalInfo(
        title: 'NEW BEST IN 1 WAVE!',
        subtitle: 'TIE YOUR RECORD',
        icon: Icons.military_tech,
        accentColor: GameColors.electricLime,
      );
    }

    // 4. Close to Unit Unlock milestone (Clause 182: Priority 4)
    if (!save.isHeroUnlocked(HeroClass.shotgunner) && currentWave >= 3 && currentWave < 5) {
      final diff = 5 - currentWave;
      return NextGoalInfo(
        title: diff == 1 ? '1 WAVE TO SHOTGUNNER!' : '$diff WAVES TO SHOTGUNNER',
        subtitle: 'UNLOCKS AT WAVE 5',
        icon: Icons.scatter_plot,
        accentColor: GameColors.techBlue,
      );
    }
    if (!save.isHeroUnlocked(HeroClass.sniper) && currentWave >= 8 && currentWave < 10) {
      final diff = 10 - currentWave;
      return NextGoalInfo(
        title: diff == 1 ? '1 WAVE TO SNIPER!' : '$diff WAVES TO SNIPER',
        subtitle: 'UNLOCKS AT WAVE 10',
        icon: Icons.gps_fixed,
        accentColor: GameColors.techBlue,
      );
    }
    if (!save.isHeroUnlocked(HeroClass.heavyGunner) && currentWave >= 13 && currentWave < 15) {
      final diff = 15 - currentWave;
      return NextGoalInfo(
        title: diff == 1 ? '1 WAVE TO HEAVY GUNNER!' : '$diff WAVES TO HEAVY GUNNER',
        subtitle: 'UNLOCKS AT WAVE 15',
        icon: Icons.all_inclusive,
        accentColor: GameColors.techBlue,
      );
    }

    // 5. Fallback: Distance to next boss or general progress (Clause 182: Priority 5)
    return NextGoalInfo(
      title: 'BOSS IN $wavesToBoss WAVES',
      subtitle: 'WAVE $currentWave IN PROGRESS',
      icon: Icons.shield,
      accentColor: GameColors.acidYellow,
    );
  }

  /// Resolves the upcoming meta unlock banner for the Main Menu and Game Over screen (Clause 203, 204, 255)
  static NextGoalInfo resolveNextUnlockGoal(PlayerSave save) {
    if (save.highestWave < GameBalance.unlockWaveShotgunner) {
      final rem = GameBalance.unlockWaveShotgunner - save.highestWave;
      return NextGoalInfo(
        title: 'NEXT UNLOCK: SHOTGUNNER',
        subtitle: 'REACH WAVE 5 ($rem ${rem == 1 ? 'WAVE' : 'WAVES'} AWAY)',
        icon: Icons.scatter_plot,
        accentColor: GameColors.techBlue,
      );
    }
    if (save.highestWave < GameBalance.unlockWaveSniper) {
      final rem = GameBalance.unlockWaveSniper - save.highestWave;
      return NextGoalInfo(
        title: 'NEXT UNLOCK: SNIPER',
        subtitle: 'REACH WAVE 10 ($rem ${rem == 1 ? 'WAVE' : 'WAVES'} AWAY)',
        icon: Icons.gps_fixed,
        accentColor: GameColors.techBlue,
      );
    }
    if (save.highestWave < GameBalance.unlockWaveHeavyGunner) {
      final rem = GameBalance.unlockWaveHeavyGunner - save.highestWave;
      return NextGoalInfo(
        title: 'NEXT UNLOCK: HEAVY GUNNER',
        subtitle: 'REACH WAVE 15 ($rem ${rem == 1 ? 'WAVE' : 'WAVES'} AWAY)',
        icon: Icons.all_inclusive,
        accentColor: GameColors.techBlue,
      );
    }
    return NextGoalInfo(
      title: 'ALL SPECIALISTS UNLOCKED',
      subtitle: 'RECORD: WAVE ${save.highestWave}',
      icon: Icons.military_tech,
      accentColor: GameColors.electricLime,
    );
  }
}
