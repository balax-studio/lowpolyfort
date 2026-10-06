import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../game/base_defense_game.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// In-game pause modal with Restart confirmation and Settings navigation (Clause 140).
class PauseDialog extends StatelessWidget {
  final BaseDefenseGame game;
  final VoidCallback onOpenSettings;

  const PauseDialog({
    super.key,
    required this.game,
    required this.onOpenSettings,
  });

  void _confirmRestart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: BrutalistCard(
            backgroundColor: GameColors.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrutalistBadge(
                  text: 'CONFIRM RESTART',
                  backgroundColor: GameColors.punchRed,
                  textColor: Colors.white,
                  fontSize: 14,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Abandon current run and deploy again?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: BrutalistButton(
                        label: 'CANCEL',
                        backgroundColor: GameColors.surfaceSubtle,
                        fontSize: 13,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrutalistButton(
                        label: 'RESTART',
                        backgroundColor: GameColors.punchRed,
                        textColor: Colors.white,
                        fontSize: 13,
                        onPressed: () {
                          Navigator.pop(ctx);
                          game.resetGameForNewRun();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gm = game.gameManager;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: BrutalistCard(
          backgroundColor: GameColors.background,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrutalistBadge(
                text: 'MISSION PAUSED',
                backgroundColor: GameColors.acidYellow,
                icon: Icons.pause,
                fontSize: 16,
              ),
              const SizedBox(height: 22),

              BrutalistButton(
                label: 'RESUME BATTLE',
                icon: Icons.play_arrow,
                backgroundColor: GameColors.electricLime,
                fullWidth: true,
                fontSize: 16,
                onPressed: () => gm.resumeGame(),
              ),
              const SizedBox(height: 12),

              BrutalistButton(
                label: 'RESTART RUN',
                icon: Icons.refresh,
                backgroundColor: GameColors.surface,
                fullWidth: true,
                fontSize: 15,
                onPressed: () => _confirmRestart(context),
              ),
              const SizedBox(height: 12),

              BrutalistButton(
                label: 'SETTINGS',
                icon: Icons.settings,
                backgroundColor: GameColors.surface,
                fullWidth: true,
                fontSize: 15,
                onPressed: onOpenSettings,
              ),
              const SizedBox(height: 12),

              BrutalistButton(
                label: 'QUIT TO MENU',
                icon: Icons.home,
                backgroundColor: GameColors.punchRed,
                textColor: Colors.white,
                fullWidth: true,
                fontSize: 15,
                onPressed: () => gm.returnToMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
