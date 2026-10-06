import 'dart:math';
import 'enemy_data.dart';
import 'game_mode_data.dart';
import '../constants/game_balance.dart';

class WaveSpawnEntry {
  final EnemyType enemyType;
  final double delaySeconds;
  final int laneIndex; // 0 to 4
  final bool triggerWarningBeforeSpawn;
  final double hpMultiplier;
  final double speedMultiplier;
  final double coinMultiplier;
  final double visualScale;
  final double damageMultiplier;
  final int? customCoinReward;

  const WaveSpawnEntry({
    required this.enemyType,
    required this.delaySeconds,
    required this.laneIndex,
    this.triggerWarningBeforeSpawn = false,
    this.hpMultiplier = 1.0,
    this.speedMultiplier = 1.0,
    this.coinMultiplier = 1.0,
    this.visualScale = 1.0,
    this.damageMultiplier = 1.0,
    this.customCoinReward,
  });
}

class WaveDefinition {
  final int waveNumber;
  final bool isBossWave;
  final List<WaveSpawnEntry> spawns;

  const WaveDefinition({
    required this.waveNumber,
    required this.isBossWave,
    required this.spawns,
  });

  /// Factory generator providing exact hand-crafted rosters for Waves 1–10 (Clauses 73–81)
  /// and intelligent weighted distributions for Wave 11+ (Clause 82), with optional ChaosModifier.
  factory WaveDefinition.generate(int wave, {ChaosModifier? modifier}) {
    final mod = modifier ?? ChaosModifier.none;
    final isBoss = (wave % GameBalance.bossInterval == 0);
    final spawns = <WaveSpawnEntry>[];

    // Seeded Random for reproducible testing & fair gameplay (Clause 167)
    final random = Random(wave * 9973);

    // Dynamic spawn interval (Clauses 83, 637): max(0.85 - 0.02 * (wave - 1), 0.35)
    final baseInterval = GameBalance.getWaveSpawnInterval(wave);

    double currentDelay = 0.6;

    void addSpawns(List<EnemyType> types) {
      List<EnemyType> scaledTypes = types;
      if (mod.enemyCountMultiplier != 1.0) {
        final targetCount = (types.length * mod.enemyCountMultiplier).ceil();
        if (targetCount > types.length) {
          scaledTypes = [];
          for (int i = 0; i < targetCount; i++) {
            scaledTypes.add(types[i % types.length]);
          }
        } else if (targetCount < types.length) {
          scaledTypes = types.sublist(0, max(1, targetCount));
        }
      }

      for (final type in scaledTypes) {
        final lane = random.nextInt(5);
        final interval = (type == EnemyType.swarm) ? (baseInterval * 0.45) : baseInterval;
        currentDelay += interval;
        spawns.add(WaveSpawnEntry(
          enemyType: type,
          delaySeconds: currentDelay,
          laneIndex: lane,
          hpMultiplier: mod.enemyHpMultiplier,
          speedMultiplier: mod.enemySpeedMultiplier,
          coinMultiplier: mod.enemyCoinMultiplier,
          visualScale: mod.enemyScaleMultiplier,
        ));
      }
    }

    if (wave == 1) {
      // Clause 73: 7 Basic
      addSpawns(List.filled(7, EnemyType.basic));
    } else if (wave == 2) {
      // Clause 73: 7 Basic, 2 Runner (introduces Runner)
      final roster = [
        EnemyType.basic, EnemyType.basic, EnemyType.basic,
        EnemyType.runner, EnemyType.basic, EnemyType.basic,
        EnemyType.runner, EnemyType.basic, EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 3) {
      // Clause 73: 8 Basic, 3 Runner (Wave ends in Upgrade Selection)
      final roster = [
        EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.basic, EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 4) {
      // Clause 73: 8 Basic, 3 Runner, 2 Swarm (introduces Swarm)
      final roster = [
        EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.swarm, EnemyType.swarm,
        EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.basic, EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 5) {
      // Clause 74 & 75: 8 Basic, 4 Runner, 3 Swarm + 1 BRUTE BOSS (~40% through wave)
      final firstHalf = [
        EnemyType.basic, EnemyType.runner, EnemyType.basic,
        EnemyType.basic, EnemyType.runner, EnemyType.swarm,
      ];
      addSpawns(firstHalf);

      // Boss Spawn with warning (Clause 74 & 76)
      currentDelay += 1.2;
      spawns.add(WaveSpawnEntry(
        enemyType: EnemyType.boss,
        delaySeconds: currentDelay,
        laneIndex: 2, // Center lane
        triggerWarningBeforeSpawn: true,
        hpMultiplier: mod.enemyHpMultiplier,
        speedMultiplier: mod.enemySpeedMultiplier,
        coinMultiplier: mod.enemyCoinMultiplier,
        visualScale: mod.enemyScaleMultiplier,
      ));
      currentDelay += 1.8;

      final secondHalf = [
        EnemyType.basic, EnemyType.runner, EnemyType.swarm, EnemyType.swarm,
        EnemyType.basic, EnemyType.basic, EnemyType.runner, EnemyType.basic,
        EnemyType.basic,
      ];
      addSpawns(secondHalf);
    } else if (wave == 6) {
      // Clause 77 & 189: 8 Basic, 4 Runner, 3 Tank, 2 Swarm (Sawtooth relief opening, Tank introduced mid-wave)
      final roster = [
        EnemyType.basic, EnemyType.swarm, EnemyType.basic, EnemyType.swarm,
        EnemyType.runner, EnemyType.basic, EnemyType.basic, EnemyType.runner,
        EnemyType.tank, EnemyType.basic, EnemyType.runner, EnemyType.basic,
        EnemyType.runner, EnemyType.tank, EnemyType.basic, EnemyType.tank,
        EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 7) {
      // Clause 78: 7 Basic, 5 Runner, 3 Tank, 4 Swarm (Total 19)
      final roster = [
        EnemyType.basic, EnemyType.runner, EnemyType.tank,
        EnemyType.swarm, EnemyType.swarm, EnemyType.runner, EnemyType.basic,
        EnemyType.tank, EnemyType.swarm, EnemyType.swarm, EnemyType.runner,
        EnemyType.basic, EnemyType.tank, EnemyType.runner, EnemyType.basic,
        EnemyType.basic, EnemyType.runner, EnemyType.basic, EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 8) {
      // Clause 79: 7 Basic, 4 Runner, 4 Tank, 4 Swarm, 2 Shielded (introduces Shielded)
      final roster = [
        EnemyType.basic, EnemyType.runner, EnemyType.shielded,
        EnemyType.tank, EnemyType.swarm, EnemyType.swarm, EnemyType.basic,
        EnemyType.runner, EnemyType.tank, EnemyType.shielded,
        EnemyType.swarm, EnemyType.swarm, EnemyType.basic, EnemyType.runner,
        EnemyType.tank, EnemyType.basic, EnemyType.tank, EnemyType.runner,
        EnemyType.basic, EnemyType.basic, EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 9) {
      // Clause 80: 7 Basic, 4 Runner, 4 Tank, 5 Swarm, 3 Shielded (Total 23)
      final roster = [
        EnemyType.basic, EnemyType.runner, EnemyType.shielded, EnemyType.tank,
        EnemyType.swarm, EnemyType.swarm, EnemyType.basic, EnemyType.runner,
        EnemyType.shielded, EnemyType.tank, EnemyType.swarm, EnemyType.swarm,
        EnemyType.swarm, EnemyType.tank, EnemyType.shielded, EnemyType.basic,
        EnemyType.runner, EnemyType.tank, EnemyType.basic, EnemyType.runner,
        EnemyType.basic, EnemyType.basic, EnemyType.basic,
      ];
      addSpawns(roster);
    } else if (wave == 10) {
      // Clause 81: 7 Basic, 5 Runner, 4 Tank, 5 Swarm, 4 Shielded + Boss (Total 26)
      final firstPart = [
        EnemyType.basic, EnemyType.runner, EnemyType.shielded, EnemyType.tank,
        EnemyType.swarm, EnemyType.swarm, EnemyType.runner, EnemyType.basic,
        EnemyType.shielded, EnemyType.tank,
      ];
      addSpawns(firstPart);

      // Mid-wave Boss
      currentDelay += 1.0;
      spawns.add(WaveSpawnEntry(
        enemyType: EnemyType.boss,
        delaySeconds: currentDelay,
        laneIndex: 2,
        triggerWarningBeforeSpawn: true,
        hpMultiplier: mod.enemyHpMultiplier,
        speedMultiplier: mod.enemySpeedMultiplier,
        coinMultiplier: mod.enemyCoinMultiplier,
        visualScale: mod.enemyScaleMultiplier,
      ));
      currentDelay += 1.5;

      final secondPart = [
        EnemyType.swarm, EnemyType.swarm, EnemyType.swarm,
        EnemyType.tank, EnemyType.shielded, EnemyType.shielded,
        EnemyType.runner, EnemyType.tank, EnemyType.runner, EnemyType.runner,
        EnemyType.basic, EnemyType.basic, EnemyType.basic, EnemyType.basic,
        EnemyType.basic,
      ];
      addSpawns(secondPart);
    } else {
      // Clauses 82, 630–635: Weighted infinite generator for Wave 11+
      final totalCount = (GameBalance.getWaveEnemyCount(wave) * mod.enemyCountMultiplier).ceil();
      final hasBoss = isBoss;

      final types = <EnemyType>[];
      for (int i = 0; i < totalCount; i++) {
        final roll = random.nextDouble();
        types.add(rollWave11PlusEnemy(roll, wave));
      }

      final half = types.length ~/ 2;
      addSpawns(types.sublist(0, half));

      if (hasBoss) {
        currentDelay += 1.0;
        spawns.add(WaveSpawnEntry(
          enemyType: EnemyType.boss,
          delaySeconds: currentDelay,
          laneIndex: 2,
          triggerWarningBeforeSpawn: true,
          hpMultiplier: mod.enemyHpMultiplier,
          speedMultiplier: mod.enemySpeedMultiplier,
          coinMultiplier: mod.enemyCoinMultiplier,
          visualScale: mod.enemyScaleMultiplier,
        ));
        currentDelay += 1.5;
      }

      addSpawns(types.sublist(half));
    }

    return WaveDefinition(
      waveNumber: wave,
      isBossWave: isBoss,
      spawns: spawns,
    );
  }

  /// Evaluates exact weighted distribution for Wave 11+ tiers (Clauses 630–633)
  static EnemyType rollWave11PlusEnemy(double roll, int wave) {
    if (wave <= 20) {
      // Clause 631: Basic 25%, Runner 20%, Tank 15%, Swarm 25%, Shielded 15%
      if (roll < 0.25) return EnemyType.basic;
      if (roll < 0.45) return EnemyType.runner;
      if (roll < 0.60) return EnemyType.tank;
      if (roll < 0.85) return EnemyType.swarm;
      return EnemyType.shielded;
    } else if (wave <= 30) {
      // Clause 632: Basic 15%, Runner 20%, Tank 20%, Swarm 25%, Shielded 20%
      if (roll < 0.15) return EnemyType.basic;
      if (roll < 0.35) return EnemyType.runner;
      if (roll < 0.55) return EnemyType.tank;
      if (roll < 0.80) return EnemyType.swarm;
      return EnemyType.shielded;
    } else {
      // Clause 633: Basic 10%, Runner 20%, Tank 25%, Swarm 20%, Shielded 25%
      if (roll < 0.10) return EnemyType.basic;
      if (roll < 0.30) return EnemyType.runner;
      if (roll < 0.55) return EnemyType.tank;
      if (roll < 0.75) return EnemyType.swarm;
      return EnemyType.shielded;
    }
  }

  /// Factory generator producing exact calibrated Boss Rush rounds (Clauses 324–338).
  factory WaveDefinition.generateBossRushRound(int roundNumber) {
    final roundData = BossRushRoundData.getRound(roundNumber);
    final spawns = <WaveSpawnEntry>[];
    final random = Random(roundNumber * 8191);

    // 1. Boss spawns immediately at delay 0.5s with warning
    spawns.add(WaveSpawnEntry(
      enemyType: EnemyType.boss,
      delaySeconds: 0.5,
      laneIndex: 2,
      triggerWarningBeforeSpawn: true,
      hpMultiplier: roundData.bossHpMultiplier,
      damageMultiplier: roundData.bossDamageMultiplier,
      speedMultiplier: roundData.bossSpeedMultiplier,
      customCoinReward: roundData.bossCoinReward,
    ));

    // 2. Support enemies spawn staggered over the first 4–8 seconds (Clause 338)
    final supportList = <EnemyType>[];
    roundData.supportRoster.forEach((type, count) {
      for (int i = 0; i < count; i++) {
        supportList.add(type);
      }
    });

    if (supportList.isNotEmpty) {
      supportList.shuffle(random);
      const startDelay = 1.2;
      const totalSpan = 6.0; // Staggered between 1.2s and 7.2s
      final step = totalSpan / supportList.length;

      for (int i = 0; i < supportList.length; i++) {
        final type = supportList[i];
        final lane = random.nextInt(5);
        spawns.add(WaveSpawnEntry(
          enemyType: type,
          delaySeconds: startDelay + (i * step),
          laneIndex: lane,
        ));
      }
    }

    return WaveDefinition(
      waveNumber: roundNumber,
      isBossWave: true,
      spawns: spawns,
    );
  }
}
