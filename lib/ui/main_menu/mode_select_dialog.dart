import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../models/game_mode_data.dart';
import '../../systems/save_system.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// Neo-Brutalist Mode Select overlay presented when Chaos or Boss Rush is unlocked (Clauses 291–296).
/// Strictly renders the 3 game modes: NORMAL, CHAOS, and BOSS RUSH.
class ModeSelectDialog extends StatefulWidget {
  final ValueChanged<GameMode> onSelectMode;
  final VoidCallback onClose;

  const ModeSelectDialog({
    super.key,
    required this.onSelectMode,
    required this.onClose,
  });

  @override
  State<ModeSelectDialog> createState() => _ModeSelectDialogState();
}

class _ModeSelectDialogState extends State<ModeSelectDialog> with TickerProviderStateMixin {
  late final AnimationController _shakeChaosController;
  late final AnimationController _shakeBossRushController;

  @override
  void initState() {
    super.initState();
    _shakeChaosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _shakeBossRushController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _shakeChaosController.dispose();
    _shakeBossRushController.dispose();
    super.dispose();
  }

  void _triggerLockedShake(GameMode mode) {
    if (mode == GameMode.chaos) {
      _shakeChaosController.forward(from: 0.0);
    } else if (mode == GameMode.bossRush) {
      _shakeBossRushController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveSystem.currentSave;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: BrutalistCard(
          backgroundColor: GameColors.background,
          padding: const EdgeInsets.all(20.0),
          borderWidth: 4.0,
          shadowOffset: 6.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrutalistBadge(
                    text: 'SELECT MODE',
                    backgroundColor: GameColors.acidYellow,
                    textColor: GameColors.ink,
                    icon: Icons.sports_esports,
                    fontSize: 15,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: GameColors.ink, size: 24),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. NORMAL MODE CARD (Clause 293)
              _buildModeCard(
                title: 'NORMAL',
                subtitle: 'BUILD • MERGE • SURVIVE',
                recordLabel: 'BEST WAVE: ${save.highestWave}',
                isUnlocked: true,
                accentColor: GameColors.electricLime,
                onPlay: () => widget.onSelectMode(GameMode.normal),
              ),
              const SizedBox(height: 12),

              // 2. CHAOS MODE CARD (Clause 294, 296)
              AnimatedBuilder(
                animation: _shakeChaosController,
                builder: (context, child) {
                  final offset = sin(_shakeChaosController.value * pi * 4) * 6.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: _buildModeCard(
                  title: 'CHAOS',
                  subtitle: save.chaosUnlocked
                      ? 'EVERY WAVE CHANGES THE RULES'
                      : 'DEFEAT NORMAL WAVE 5 BOSS',
                  recordLabel: save.chaosUnlocked ? 'BEST WAVE: ${save.bestChaosWave}' : null,
                  isUnlocked: save.chaosUnlocked,
                  accentColor: GameColors.acidYellow,
                  onPlay: save.chaosUnlocked
                      ? () => widget.onSelectMode(GameMode.chaos)
                      : () => _triggerLockedShake(GameMode.chaos),
                ),
              ),
              const SizedBox(height: 12),

              // 3. BOSS RUSH CARD (Clause 295, 296)
              AnimatedBuilder(
                animation: _shakeBossRushController,
                builder: (context, child) {
                  final offset = sin(_shakeBossRushController.value * pi * 4) * 6.0;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: _buildModeCard(
                  title: 'BOSS RUSH',
                  subtitle: save.bossRushUnlocked
                      ? '5 BOSSES • ONE RUN'
                      : 'DEFEAT NORMAL WAVE 10 BOSS',
                  recordLabel: save.bossRushUnlocked ? 'BEST: ${save.bestBossRushRound} / 5' : null,
                  isUnlocked: save.bossRushUnlocked,
                  accentColor: GameColors.punchRed,
                  onPlay: save.bossRushUnlocked
                      ? () => widget.onSelectMode(GameMode.bossRush)
                      : () => _triggerLockedShake(GameMode.bossRush),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required String? recordLabel,
    required bool isUnlocked,
    required Color accentColor,
    required VoidCallback onPlay,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isUnlocked ? GameColors.surface : const Color(0xFFE2DDD2),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: GameColors.ink, width: 3.0),
        boxShadow: isUnlocked
            ? const [BoxShadow(color: GameColors.ink, offset: Offset(3, 3))]
            : const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isUnlocked ? GameColors.ink : const Color(0xFF64748B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: GameColors.ink, width: 1.5),
                  ),
                  child: const Text(
                    'AVAILABLE',
                    style: TextStyle(
                      color: GameColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: GameColors.ink, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isUnlocked ? const Color(0xFF334155) : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (recordLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              recordLabel,
              style: const TextStyle(
                color: GameColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 10),
          BrutalistButton(
            label: isUnlocked ? 'PLAY' : 'LOCKED',
            icon: isUnlocked ? Icons.play_arrow : Icons.lock,
            backgroundColor: isUnlocked ? accentColor : const Color(0xFF94A3B8),
            textColor: isUnlocked ? (accentColor == GameColors.punchRed ? Colors.white : GameColors.ink) : Colors.white,
            fullWidth: true,
            fontSize: 14,
            verticalPadding: 10,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
