import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../models/hero_data.dart';
import '../../systems/save_system.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// Unit Codex / Armory Showcase (Clauses 117, 118).
/// Displays all 4 combat unit types, their combat ratings, roles, and unlock wave milestones.
class ArmoryView extends StatelessWidget {
  final VoidCallback onClose;

  const ArmoryView({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final save = SaveSystem.currentSave;

    return Container(
      color: Colors.black.withValues(alpha: 0.90),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrutalistBadge(
                  text: 'DEFENDER ARMORY',
                  backgroundColor: GameColors.techBlue,
                  textColor: Colors.white,
                  icon: Icons.shield,
                  fontSize: 15,
                ),
                BrutalistBadge(
                  text: 'BEST WAVE: ${save.highestWave}',
                  backgroundColor: GameColors.electricLime,
                  fontSize: 13,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unit Cards Roster
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: HeroDefinition.registry.values.map((hero) {
                  final isUnlocked = save.isHeroUnlocked(hero.heroClass);
                  return _buildUnitCard(hero, isUnlocked);
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            // Close Button
            BrutalistButton(
              label: 'BACK TO MENU',
              icon: Icons.arrow_back,
              backgroundColor: GameColors.electricLime,
              fullWidth: true,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(HeroDefinition hero, bool isUnlocked) {
    final cardBg = isUnlocked ? GameColors.surface : const Color(0xFFD4D0C5);
    final borderColor = isUnlocked ? GameColors.ink : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: BrutalistCard(
        backgroundColor: cardBg,
        borderWidth: 3.5,
        shadowOffset: 4.0,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit Icon / Silhouette
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isUnlocked ? hero.themeColor : const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: GameColors.ink, offset: Offset(2, 2)),
                ],
              ),
              child: Center(
                child: Icon(
                  isUnlocked ? _getHeroIcon(hero.heroClass) : Icons.lock,
                  color: isUnlocked ? Colors.white : Colors.white70,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hero.name.toUpperCase(),
                        style: TextStyle(
                          color: isUnlocked ? GameColors.ink : const Color(0xFF4B5563),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GameColors.electricLime,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: GameColors.ink, width: 1.5),
                          ),
                          child: const Text(
                            'UNLOCKED',
                            style: TextStyle(
                              color: GameColors.ink,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GameColors.punchRed,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: GameColors.ink, width: 1.5),
                          ),
                          child: Text(
                            'WAVE ${hero.unlockWaveRequirement}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    isUnlocked
                        ? hero.roleDescription
                        : 'SURVIVE TO WAVE ${hero.unlockWaveRequirement} TO DEPLOY THIS SPECIALIST.',
                    style: TextStyle(
                      color: isUnlocked ? const Color(0xFF475569) : const Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stat Pips (Clause 117)
                  if (isUnlocked) ...[
                    _buildStatPips('DAMAGE', _getDamagePips(hero)),
                    const SizedBox(height: 3),
                    _buildStatPips('SPEED', _getSpeedPips(hero)),
                    const SizedBox(height: 3),
                    _buildStatPips('RANGE', _getRangePips(hero)),
                  ] else ...[
                    Text(
                      'STATUS: LOCKED IN REQUISITION',
                      style: TextStyle(
                        color: GameColors.punchRed.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPips(String label, int pips) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: const TextStyle(
              color: GameColors.ink,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final filled = index < pips;
            return Container(
              margin: const EdgeInsets.only(right: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: filled ? GameColors.ink : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: GameColors.ink, width: 1.5),
              ),
            );
          }),
        ),
      ],
    );
  }

  int _getDamagePips(HeroDefinition hero) {
    switch (hero.heroClass) {
      case HeroClass.rifleman:
        return 3;
      case HeroClass.shotgunner:
        return 4;
      case HeroClass.sniper:
        return 5;
      case HeroClass.heavyGunner:
        return 2;
    }
  }

  int _getSpeedPips(HeroDefinition hero) {
    switch (hero.heroClass) {
      case HeroClass.rifleman:
        return 3;
      case HeroClass.shotgunner:
        return 2;
      case HeroClass.sniper:
        return 1;
      case HeroClass.heavyGunner:
        return 5;
    }
  }

  int _getRangePips(HeroDefinition hero) {
    switch (hero.heroClass) {
      case HeroClass.rifleman:
        return 3;
      case HeroClass.shotgunner:
        return 2;
      case HeroClass.sniper:
        return 5;
      case HeroClass.heavyGunner:
        return 3;
    }
  }

  IconData _getHeroIcon(HeroClass heroClass) {
    switch (heroClass) {
      case HeroClass.rifleman:
        return Icons.military_tech;
      case HeroClass.shotgunner:
        return Icons.scatter_plot;
      case HeroClass.sniper:
        return Icons.gps_fixed;
      case HeroClass.heavyGunner:
        return Icons.all_inclusive;
    }
  }
}
