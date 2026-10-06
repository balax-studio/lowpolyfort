import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../managers/game_manager.dart';
import '../common/brutalist_button.dart';

/// Modal dialog presented when Base HP reaches zero, offering a single 50% HP revive (Clauses 462–480, 512).
class SecondChanceDialog extends StatelessWidget {
  final GameManager gameManager;

  const SecondChanceDialog({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    final isShowing = gameManager.isRewardedAdShowing;

    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: GameColors.background,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: GameColors.ink, width: 4.0),
          boxShadow: const [
            BoxShadow(
              color: GameColors.ink,
              offset: Offset(8, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: GameColors.punchRed,
                border: Border.all(color: GameColors.ink, width: 2.5),
              ),
              child: const Text(
                'BASE DESTROYED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'SECOND CHANCE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            const Text(
              'RESTORE 50% BASE HP',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enemies freeze for 3 seconds upon return.\nCurrent combat and wave state are preserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),

            // Watch Ad CTA Button
            BrutalistButton(
              label: isShowing ? 'CONNECTING...' : 'WATCH AD • CONTINUE',
              backgroundColor: isShowing ? Colors.grey : GameColors.electricLime,
              textColor: GameColors.ink,
              fullWidth: true,
              onPressed: isShowing ? () {} : gameManager.claimSecondChance,
            ),
            const SizedBox(height: 14),

            // Clear End Run Option (Clause 468, 469)
            TextButton(
              onPressed: isShowing ? null : gameManager.dismissSecondChance,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'END RUN',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
