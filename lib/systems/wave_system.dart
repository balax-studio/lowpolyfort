import '../constants/game_balance.dart';
import '../managers/game_manager.dart';
import '../models/wave_data.dart';
import '../models/game_mode_data.dart';
import '../game/base_defense_game.dart';
import 'spawn_system.dart';

/// Coordinates horde wave lifecycles, intermission intervals, and clear conditions.
class WaveSystem {
  final BaseDefenseGame game;
  late final SpawnSystem spawnSystem;

  bool _isWaveActive = false;
  double _intermissionTimer = 0.0;
  bool _isIntermission = false;

  WaveSystem(this.game) {
    spawnSystem = SpawnSystem(game);
  }

  bool get isWaveActive => _isWaveActive;
  bool get isIntermission => _isIntermission;

  void startWave() {
    _isWaveActive = true;
    _isIntermission = false;

    final mode = game.gameManager.activeMode;
    final WaveDefinition waveDef;

    if (mode == GameMode.bossRush) {
      waveDef = WaveDefinition.generateBossRushRound(game.gameManager.bossRushRound);
    } else if (mode == GameMode.chaos) {
      waveDef = WaveDefinition.generate(
        game.gameManager.currentWave,
        modifier: game.gameManager.activeChaosModifier,
      );
    } else {
      waveDef = WaveDefinition.generate(game.gameManager.currentWave);
    }

    spawnSystem.startWave(waveDef);
  }

  void update(double dt) {
    final state = game.gameManager.state;

    if (state == GameState.preparingWave) {
      game.gameManager.updateCountdown(dt);
      if (game.gameManager.state == GameState.playing && !_isWaveActive) {
        startWave();
      }
      return;
    }

    if (state != GameState.playing) return;

    if (_isIntermission) {
      _intermissionTimer -= dt;
      if (_intermissionTimer <= 0) {
        _isIntermission = false;
        game.gameManager.onWaveCleared();
      }
      return;
    }

    if (_isWaveActive) {
      spawnSystem.update(dt);

      // Check if wave is fully cleared
      if (spawnSystem.isFinished && game.activeEnemies.isEmpty) {
        _isWaveActive = false;
        _isIntermission = true;
        _intermissionTimer = GameBalance.waveClearIntermissionSeconds;
      }
    }
  }

  void reset() {
    _isWaveActive = false;
    _isIntermission = false;
    _intermissionTimer = 0.0;
    spawnSystem.clear();
  }
}
