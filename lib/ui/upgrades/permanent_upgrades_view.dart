import 'package:flutter/material.dart';
import '../../constants/game_balance.dart';
import '../../constants/game_colors.dart';
import '../../models/player_save.dart';
import '../../systems/save_system.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// Permanent Meta-Progression Shop (Clauses 105–112).
/// Players invest Scrap earned from surviving waves and killing bosses into permanent stat upgrades.
class PermanentUpgradesView extends StatefulWidget {
  final VoidCallback onClose;

  const PermanentUpgradesView({super.key, required this.onClose});

  @override
  State<PermanentUpgradesView> createState() => _PermanentUpgradesViewState();
}

class _PermanentUpgradesViewState extends State<PermanentUpgradesView> {
  PlayerSave get save => SaveSystem.currentSave;

  void _upgradePerk(String perkKey) {
    int currentLevel;
    switch (perkKey) {
      case 'base_armor':
        currentLevel = save.permBaseHpLevel;
        break;
      case 'starting_cash':
        currentLevel = save.permStartingCoinsLevel;
        break;
      case 'unit_training':
        currentLevel = save.permDamageLevel;
        break;
      case 'rapid_training':
        currentLevel = save.permAttackSpeedLevel;
        break;
      case 'luck':
        currentLevel = save.permCritLevel;
        break;
      case 'bounty':
        currentLevel = save.permBountyLevel;
        break;
      default:
        return;
    }

    // Clauses 646, 647: Max level is strictly 5
    if (currentLevel >= GameBalance.maxPermUpgradeLevel) return;

    final cost = GameBalance.getPermanentUpgradeCost(currentLevel);
    if (save.totalScrap < cost) return;

    PlayerSave updated;
    switch (perkKey) {
      case 'base_armor':
        updated = save.copyWith(
          totalScrap: save.totalScrap - cost,
          permBaseHpLevel: save.permBaseHpLevel + 1,
        );
        break;
      case 'starting_cash':
        updated = save.copyWith(
          totalScrap: save.totalScrap - cost,
          permStartingCoinsLevel: save.permStartingCoinsLevel + 1,
        );
        break;
      case 'unit_training':
        updated = save.copyWith(
          totalScrap: save.totalScrap - cost,
          permDamageLevel: save.permDamageLevel + 1,
        );
        break;
      case 'rapid_training':
        updated = save.copyWith(
          totalScrap: save.totalScrap - cost,
          permAttackSpeedLevel: save.permAttackSpeedLevel + 1,
        );
        break;
      case 'luck':
        updated = save.copyWith(
          totalScrap: save.totalScrap - cost,
          permCritLevel: save.permCritLevel + 1,
        );
        break;
      case 'bounty':
        updated = save.copyWith(
          totalScrap: save.totalScrap - cost,
          permBountyLevel: save.permBountyLevel + 1,
        );
        break;
      default:
        return;
    }

    SaveSystem.save(updated);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                  text: 'PERMANENT UPGRADES',
                  backgroundColor: GameColors.cyberPurple,
                  textColor: Colors.white,
                  icon: Icons.upgrade,
                  fontSize: 15,
                ),
                BrutalistBadge(
                  text: '${save.totalScrap} SCRAP',
                  backgroundColor: GameColors.acidYellow,
                  icon: Icons.build_circle,
                  fontSize: 15,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Perk List (Clauses 105–111)
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPerkCard(
                    title: 'BASE ARMOR',
                    description: '+50 Starting Base HP per level',
                    currentLevel: save.permBaseHpLevel,
                    perkKey: 'base_armor',
                    icon: Icons.shield,
                  ),
                  _buildPerkCard(
                    title: 'STARTING CASH',
                    description: '+10 Starting Coins each deployment',
                    currentLevel: save.permStartingCoinsLevel,
                    perkKey: 'starting_cash',
                    icon: Icons.monetization_on,
                  ),
                  _buildPerkCard(
                    title: 'UNIT TRAINING',
                    description: '+2.0% Squad damage per level',
                    currentLevel: save.permDamageLevel,
                    perkKey: 'unit_training',
                    icon: Icons.whatshot,
                  ),
                  _buildPerkCard(
                    title: 'RAPID TRAINING',
                    description: '+1.5% Squad attack speed per level',
                    currentLevel: save.permAttackSpeedLevel,
                    perkKey: 'rapid_training',
                    icon: Icons.speed,
                  ),
                  _buildPerkCard(
                    title: 'LUCK',
                    description: '+0.5% Critical strike chance per level',
                    currentLevel: save.permCritLevel,
                    perkKey: 'luck',
                    icon: Icons.track_changes,
                  ),
                  _buildPerkCard(
                    title: 'BOUNTY',
                    description: '+2.0% Extra coin rewards from fallen foes',
                    currentLevel: save.permBountyLevel,
                    perkKey: 'bounty',
                    icon: Icons.savings,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Close Button
            BrutalistButton(
              label: 'BACK TO MENU',
              icon: Icons.arrow_back,
              backgroundColor: GameColors.electricLime,
              fullWidth: true,
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkCard({
    required String title,
    required String description,
    required int currentLevel,
    required String perkKey,
    required IconData icon,
  }) {
    final isMax = currentLevel >= GameBalance.maxPermUpgradeLevel;
    final cost = isMax ? 0 : GameBalance.getPermanentUpgradeCost(currentLevel);
    final canAfford = !isMax && (save.totalScrap >= cost);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: BrutalistCard(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GameColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: GameColors.ink, width: 2),
              ),
              child: Icon(icon, color: GameColors.ink, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: GameColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        isMax ? 'LVL 5 (MAX)' : 'LVL $currentLevel',
                        style: TextStyle(
                          color: isMax ? GameColors.electricLime : GameColors.cyberPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            BrutalistButton(
              label: isMax ? 'MAX' : '$cost SCRAP',
              backgroundColor: isMax
                  ? GameColors.surfaceSubtle
                  : (canAfford ? GameColors.acidYellow : GameColors.surfaceSubtle),
              textColor: isMax ? const Color(0xFF64748B) : GameColors.ink,
              fontSize: 12,
              horizontalPadding: 10,
              verticalPadding: 8,
              onPressed: canAfford ? () => _upgradePerk(perkKey) : null,
            ),
          ],
        ),
      ),
    );
  }
}
