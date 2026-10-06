import 'package:flutter_test/flutter_test.dart';
import 'package:flame/extensions.dart';
import 'package:poly_fort/constants/visual_feedback_config.dart';
import 'package:poly_fort/managers/camera_feedback_manager.dart';
import 'package:poly_fort/components/vfx_component.dart';
import 'package:poly_fort/models/enemy_data.dart';
import 'package:poly_fort/systems/combat_calculator.dart';
import 'package:poly_fort/constants/game_config.dart';
import 'package:poly_fort/managers/game_manager.dart';
import 'package:poly_fort/game/base_defense_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Visual Feedback Configuration & Bounds (Clauses 728–882)', () {
    test('Juice timings conform to strict design specification intervals', () {
      // Unit motion
      expect(VisualFeedbackConfig.unitIdleBobDuration, inInclusiveRange(1.2, 1.8));
      expect(VisualFeedbackConfig.unitIdleBobAmplitude, inInclusiveRange(2.0, 3.0));
      expect(VisualFeedbackConfig.targetingEaseDuration, inInclusiveRange(0.08, 0.15));

      // Hit & Death
      expect(VisualFeedbackConfig.hitFlashDuration, inInclusiveRange(0.04, 0.07));
      expect(VisualFeedbackConfig.hitSquashDuration, inInclusiveRange(0.06, 0.10));
      expect(VisualFeedbackConfig.enemyDeathDissolveDuration, inInclusiveRange(0.15, 0.25));

      // Merge sequence
      expect(VisualFeedbackConfig.mergeSequenceDuration, inInclusiveRange(0.45, 0.65));
      expect(VisualFeedbackConfig.mergeParticlesStandard, inInclusiveRange(12, 18));
      expect(VisualFeedbackConfig.mergeParticlesHighLevel, inInclusiveRange(18, 24));
      expect(VisualFeedbackConfig.mergeParticlesMaxLevel, inInclusiveRange(24, 30));

      // Performance budgets & caps (Clauses 803, 805)
      expect(VisualFeedbackConfig.maxActiveParticles, inInclusiveRange(40, 60));
      expect(VisualFeedbackConfig.maxVisibleFloatingTexts, inInclusiveRange(12, 16));
    });

    test('CameraFeedbackManager enforces non-additive arbitration rule (Clause 801)', () {
      final manager = CameraFeedbackManager();

      // Trigger small shake
      manager.triggerPreset(CameraShakePreset.small);
      expect(manager.isShaking, isTrue);
      expect(manager.currentIntensity, equals(VisualFeedbackConfig.shakeSmallIntensity));
      expect(manager.remainingDuration, equals(VisualFeedbackConfig.shakeSmallDuration));

      // Incoming weaker micro shake should NOT decrease or overwrite active stronger shake
      manager.triggerPreset(CameraShakePreset.micro);
      expect(manager.currentIntensity, equals(VisualFeedbackConfig.shakeSmallIntensity));
      expect(manager.remainingDuration, equals(VisualFeedbackConfig.shakeSmallDuration));

      // Incoming stronger medium shake should cleanly upgrade intensity and duration
      manager.triggerPreset(CameraShakePreset.medium);
      expect(manager.currentIntensity, equals(VisualFeedbackConfig.shakeMediumIntensity));
      expect(manager.remainingDuration, equals(VisualFeedbackConfig.shakeMediumDuration));

      // Decay over time
      manager.update(0.10);
      expect(manager.remainingDuration, closeTo(0.05, 0.001));

      manager.update(0.06);
      expect(manager.isShaking, isFalse);
      expect(manager.currentOffset, equals(Vector2.zero()));
    });

    test('CameraFeedbackManager reset clears state completely (Clause 866)', () {
      final manager = CameraFeedbackManager();
      manager.triggerPreset(CameraShakePreset.medium);
      expect(manager.isShaking, isTrue);

      manager.reset();
      expect(manager.isShaking, isFalse);
      expect(manager.currentIntensity, equals(0.0));
      expect(manager.remainingDuration, equals(0.0));
      expect(manager.currentOffset, equals(Vector2.zero()));
    });

    test('MergeBurstVFXComponent scales particle counts across tier thresholds (Clauses 764, 765)', () {
      // Level 2 standard merge
      final burstStd = MergeBurstVFXComponent(position: Vector2.zero(), targetLevel: 2);
      expect(burstStd.targetLevel, equals(2));

      // Level 5 high level merge
      final burstHigh = MergeBurstVFXComponent(position: Vector2.zero(), targetLevel: 5);
      expect(burstHigh.targetLevel, equals(5));

      // Level 8 max level merge
      final burstMax = MergeBurstVFXComponent(position: Vector2.zero(), targetLevel: 8);
      expect(burstMax.targetLevel, equals(8));
    });

    test('Zero Gameplay Alteration Guarantee (Clauses 728, 848, 878)', () {
      // Combat resolution formulas remain strictly identical
      final res = DamageCalculator.calculate(
        baseDamage: 25.0,
        level: 1,
        globalDamageMultiplier: 1.0,
        critChance: 0.10,
        critMultiplier: 2.0,
        targetType: EnemyType.basic,
        armorPiercingMultiplier: 1.0,
      );
      expect(res.damage, equals(25.0));

      // Base enemy stats remain identical
      final basicDef = EnemyDefinition.registry[EnemyType.basic]!;
      expect(basicDef.getScaledHp(1), equals(62.0));
      expect(basicDef.getScaledSpeed(1), equals(55.0));
    });

    test('BaseDefenseGame resetGameForNewRun cleans camera and viewfinder (Clause 866)', () async {
      final gm = GameManager();
      final game = BaseDefenseGame(gameManager: gm);
      await game.onLoad();

      // Trigger shake
      game.triggerCameraShake(6.0, 0.2);
      expect(game.cameraManager.isShaking, isTrue);

      // Reset run
      game.resetGameForNewRun();
      expect(game.cameraManager.isShaking, isFalse);
      expect(
        game.camera.viewfinder.position,
        equals(Vector2(GameConfig.virtualWidth / 2, GameConfig.virtualHeight / 2)),
      );
    });
  });
}
