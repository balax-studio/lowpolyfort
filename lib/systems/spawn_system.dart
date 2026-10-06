import 'package:flame/components.dart';
import '../constants/game_config.dart';
import '../constants/game_balance.dart';
import '../models/enemy_data.dart';
import '../models/wave_data.dart';
import '../components/enemy_component.dart';
import '../game/base_defense_game.dart';

/// Schedules and emits advancing horde units along 5 tactical lanes.
/// Enforces maxEnemiesAlive soft-cap and mid-wave boss warnings (Clauses 74, 76, 83).
class SpawnSystem {
  final BaseDefenseGame game;
  final List<WaveSpawnEntry> _queue = [];
  double _timer = 0.0;
  bool _isFinished = false;

  SpawnSystem(this.game);

  bool get isFinished => _isFinished && _queue.isEmpty;

  void startWave(WaveDefinition waveDef) {
    _queue.clear();
    _queue.addAll(waveDef.spawns);
    _queue.sort((a, b) => a.delaySeconds.compareTo(b.delaySeconds));
    _timer = 0.0;
    _isFinished = false;
  }

  void update(double dt) {
    if (_queue.isEmpty) {
      _isFinished = true;
      return;
    }

    _timer += dt;

    // Clause 83: Soft-cap maxEnemiesAlive (40) to preserve 60 FPS mobile performance
    if (game.activeEnemies.length >= GameBalance.maxEnemiesAlive) {
      return;
    }

    while (_queue.isNotEmpty && _queue.first.delaySeconds <= _timer) {
      if (game.activeEnemies.length >= GameBalance.maxEnemiesAlive) {
        break;
      }
      final entry = _queue.removeAt(0);
      _spawnEnemy(entry);
    }
  }

  void _spawnEnemy(WaveSpawnEntry entry) {
    // 5 lane X coordinates across 450px width
    final laneWidth = GameConfig.virtualWidth / GameConfig.spawnLanes;
    final spawnX = (entry.laneIndex * laneWidth) + (laneWidth / 2);
    final spawnY = GameConfig.topSpawnY;

    if (entry.triggerWarningBeforeSpawn) {
      game.gameManager.triggerMidWaveBossWarning();
      game.triggerCameraShake(4.0, 0.4);
    }

    final def = EnemyDefinition.registry[entry.enemyType]!;
    final enemy = EnemyComponent(
      definition: def,
      wave: game.gameManager.currentWave,
      laneIndex: entry.laneIndex,
      spawnPosition: Vector2(spawnX, spawnY),
      hpMultiplier: entry.hpMultiplier,
      speedMultiplier: entry.speedMultiplier,
      coinMultiplier: entry.coinMultiplier,
      visualScale: entry.visualScale,
      baseDamageMultiplier: entry.damageMultiplier,
      customCoinReward: entry.customCoinReward,
    );

    game.addEnemy(enemy);
  }

  void clear() {
    _queue.clear();
    _isFinished = true;
  }
}
