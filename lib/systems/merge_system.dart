import 'package:flame/components.dart';
import '../constants/game_balance.dart';
import '../components/hero_component.dart';
import '../components/vfx_component.dart';
import '../components/damage_text_component.dart';
import '../managers/audio_manager.dart';
import '../managers/camera_feedback_manager.dart';
import '../game/base_defense_game.dart';

/// Handles validation, level promotion, and tactile visual effects during unit merging.
///
/// ponytail: Direct choreography sequence without multi-stage animation controllers.
class MergeSystem {
  final BaseDefenseGame game;

  MergeSystem(this.game);

  bool canMerge(HeroComponent a, HeroComponent b) {
    if (a == b) return false;
    if (a.heroClass != b.heroClass) return false;
    if (a.level != b.level) return false;
    if (a.level >= GameBalance.maxUnitLevel) return false;
    return true;
  }

  void executeMerge({
    required HeroComponent sourceHero,
    required HeroComponent targetHero,
  }) {
    if (!canMerge(sourceHero, targetHero)) return;

    // 1. Vacate source slot
    sourceHero.slot.currentHero = null;
    sourceHero.removeFromParent();

    // 2. Promote target unit
    targetHero.level += 1;
    targetHero.scale.setAll(0.8); // Kickstart scale bounce 0.8 -> 1.18 -> 1.0 (Clause 762)
    targetHero.resetAttackCooldown(); // Ready to fire immediately (Clause 196)

    // 3. Audio & Haptics sync (Clause 762, 821–822)
    AudioManager.instance.playMerge();
    game.triggerCameraShakePreset(CameraShakePreset.small);

    // 4. VFX: Radial burst scaled by unit level (Clauses 762–765)
    game.add(
      MergeBurstVFXComponent(
        position: targetHero.position.clone(),
        targetLevel: targetHero.level,
      ),
    );

    // 5. Floating "LEVEL X" or "MAX LEVEL" text (Clauses 762, 766)
    final mergeText = (targetHero.level >= 8)
        ? 'MAX LEVEL!\n★ 8'
        : 'LEVEL ${targetHero.level}!\n★ ${targetHero.level}';
    game.add(
      DamageTextComponent(
        text: mergeText,
        position: targetHero.position.clone()..y -= 20,
        isCrit: true,
      ),
    );

    // 6. Check interactive tutorial
    if (game.gameManager.tutorialStep == 3) {
      game.gameManager.advanceTutorialStep(4);
    }
  }
}
