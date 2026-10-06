import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../game/base_defense_game.dart';
import '../../models/game_mode_data.dart';
import '../../systems/save_system.dart';
import '../../systems/goal_presentation_service.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// Neo-Brutalist run summary modal parameterized for all 3 modes (Clauses 204–207, 319, 345, 346, 394).
class GameOverDialog extends StatelessWidget {
  final BaseDefenseGame game;
  final VoidCallback onOpenArmory;

  const GameOverDialog({
    super.key,
    required this.game,
    required this.onOpenArmory,
  });

  @override
  Widget build(BuildContext context) {
    final gm = game.gameManager;
    final save = SaveSystem.currentSave;
    final mode = gm.activeMode;
    final isBossRushVictory = gm.isBossRushVictory;

    // Mode-specific headers & labels (Clauses 319, 345, 346, 394)
    final String bannerText;
    final Color bannerBg;
    final Color bannerTextColor;
    final IconData bannerIcon;
    final String scoreTitle;
    final String bestScoreLabel;

    if (mode == GameMode.bossRush) {
      if (isBossRushVictory) {
        bannerText = 'BOSS RUSH CLEARED!';
        bannerBg = GameColors.electricLime;
        bannerTextColor = GameColors.ink;
        bannerIcon = Icons.military_tech;
      } else {
        bannerText = 'BOSS RUSH OVER';
        bannerBg = GameColors.punchRed;
        bannerTextColor = Colors.white;
        bannerIcon = Icons.shield_outlined;
      }
      scoreTitle = '${gm.bossesDefeatedThisRun} / 5 BOSSES';
      bestScoreLabel = 'ALL-TIME BEST: ${save.bestBossRushRound} / 5';
    } else if (mode == GameMode.chaos) {
      bannerText = 'CHAOS RUN';
      bannerBg = GameColors.acidYellow;
      bannerTextColor = GameColors.ink;
      bannerIcon = Icons.bolt;
      scoreTitle = 'WAVE ${gm.currentWave}';
      bestScoreLabel = 'ALL-TIME BEST: WAVE ${save.bestChaosWave}';
    } else {
      bannerText = 'RUN OVER';
      bannerBg = GameColors.punchRed;
      bannerTextColor = Colors.white;
      bannerIcon = Icons.shield_outlined;
      scoreTitle = 'WAVE ${gm.currentWave}';
      bestScoreLabel = 'ALL-TIME BEST: WAVE ${save.highestWave}';
    }

    final isNewBest = gm.isNewHighScore;
    final nextMilestone = GoalPresentationService.resolveNextUnlockGoal(save);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: BrutalistCard(
          backgroundColor: GameColors.background,
          padding: const EdgeInsets.all(22.0),
          borderWidth: 4.0,
          shadowOffset: 6.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header Banner
              BrutalistBadge(
                text: bannerText,
                backgroundColor: bannerBg,
                textColor: bannerTextColor,
                icon: bannerIcon,
                fontSize: 16,
              ),
              const SizedBox(height: 14),

              // 2. Wave / Bosses Reached & Best Callout
              Text(
                scoreTitle,
                style: const TextStyle(
                  color: GameColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),

              if (isNewBest)
                const BrutalistBadge(
                  text: '★ NEW BEST RECORD! ★',
                  backgroundColor: GameColors.electricLime,
                  icon: Icons.military_tech,
                  fontSize: 12,
                )
              else
                Text(
                  bestScoreLabel,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 18),

              // 3. Mode Context / Milestone Card (Clauses 204, 207, 322, 350)
              if (mode == GameMode.normal)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: GameColors.ink,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: GameColors.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, offset: Offset(3, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: nextMilestone.accentColor,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: GameColors.ink, width: 1.5),
                        ),
                        child: Icon(nextMilestone.icon, color: GameColors.ink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextMilestone.title,
                              style: TextStyle(
                                color: nextMilestone.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextMilestone.subtitle ?? 'NEXT MILESTONE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (mode == GameMode.chaos)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: GameColors.ink,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: GameColors.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, offset: Offset(3, 3)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: GameColors.acidYellow, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHAOS BONUS EARNED',
                              style: TextStyle(
                                color: GameColors.acidYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '+10% SCRAP BONUS APPLIED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: GameColors.ink,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: GameColors.ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, offset: Offset(3, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBossRushVictory ? Icons.military_tech : Icons.whatshot,
                        color: isBossRushVictory ? GameColors.electricLime : GameColors.punchRed,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBossRushVictory ? 'ALL 5 BOSSES CLEARED!' : '5 BOSS CHALLENGE',
                              style: TextStyle(
                                color: isBossRushVictory ? GameColors.electricLime : GameColors.acidYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isBossRushVictory
                                  ? '+10 COMPLETION SCRAP BONUS (50 TOTAL)'
                                  : 'DEFEAT ALL 5 FOR COMPLETION BONUS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // 4. Compact Run Earnings Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactStat('${gm.killsThisRun}', 'KILLS'),
                  _buildCompactStat('${gm.economy.totalCoinsEarned}', 'COINS'),
                  _buildCompactStat('+${gm.scrapEarnedThisRun}', 'SCRAP', color: GameColors.cyberPurple),
                ],
              ),
              // 4.5. Extra Scrap Rewarded Ad Option (Clauses 481–491, 513)
              if (gm.canOfferExtraScrap) ...[
                BrutalistButton(
                  label: gm.isRewardedAdShowing
                      ? 'CONNECTING...'
                      : 'WATCH AD • +${gm.scrapEarnedThisRun} SCRAP',
                  icon: Icons.ondemand_video,
                  backgroundColor: gm.isRewardedAdShowing ? Colors.grey : GameColors.electricLime,
                  fullWidth: true,
                  fontSize: 14,
                  verticalPadding: 12,
                  onPressed: gm.isRewardedAdShowing ? null : gm.claimExtraScrap,
                ),
                const SizedBox(height: 12),
              ] else if (gm.extraScrapAwardedThisRun) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: GameColors.electricLime,
                    border: Border.all(color: GameColors.ink, width: 2.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DOUBLE SCRAP AWARDED! (+${gm.scrapEarnedThisRun * 2} TOTAL)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GameColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 5. Single Dominant CTA: RETRY / REPLAY (Clauses 205, 362–364, 792)
              BrutalistButton(
                label: isBossRushVictory ? 'REPLAY' : 'RETRY',
                icon: Icons.refresh,
                backgroundColor: GameColors.acidYellow,
                fullWidth: true,
                fontSize: 20,
                verticalPadding: 16,
                pulseOnce: true,
                onPressed: () => game.resetGameForNewRun(),
              ),
              const SizedBox(height: 10),

              // 6. Subdued Secondary Actions Row (Clause 255)
              Row(
                children: [
                  Expanded(
                    child: BrutalistButton(
                      label: 'UPGRADES',
                      icon: Icons.upgrade,
                      backgroundColor: GameColors.surface,
                      fontSize: 13,
                      verticalPadding: 10,
                      onPressed: onOpenArmory,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BrutalistButton(
                      label: 'MAIN MENU',
                      icon: Icons.home,
                      backgroundColor: GameColors.surfaceSubtle,
                      fontSize: 13,
                      verticalPadding: 10,
                      onPressed: () => gm.returnToMenu(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? GameColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
