import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../models/hero_data.dart';
import '../../systems/save_system.dart';
import '../../game/base_defense_game.dart';
import '../common/brutalist_button.dart';

/// Diagnostic panel for fast-cycle development testing and QA.
class DebugPanel extends StatefulWidget {
  final BaseDefenseGame game;

  const DebugPanel({super.key, required this.game});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final gm = widget.game.gameManager;

    if (!_isOpen) {
      return Positioned(
        top: 50,
        right: 14,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(color: GameColors.ink, offset: Offset(2, 2)),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.punchRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: GameColors.ink, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () => setState(() => _isOpen = true),
            child: const Text('DEBUG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ),
      );
    }

    return Positioned(
      top: 45,
      right: 14,
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GameColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: GameColors.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DEBUG PANEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _isOpen = false),
                ),
              ],
            ),
            const Divider(color: GameColors.ink, thickness: 1.5),

            _buildDebugBtn('+1000 Coins', () => gm.economy.debugAddCoins(1000)),
            _buildDebugBtn('Spawn Boss', () => widget.game.debugSpawnBoss()),
            _buildDebugBtn('Skip Wave', () => gm.debugSkipWave()),
            _buildDebugBtn('Kill All Enemies', () => widget.game.debugKillAllEnemies()),
            _buildDebugBtn('Add Rifleman L1', () => widget.game.debugAddUnit(HeroClass.rifleman, 1)),
            _buildDebugBtn('Add Sniper L1', () => widget.game.debugAddUnit(HeroClass.sniper, 1)),
            _buildDebugBtn('Damage Base 250', () => gm.damageBase(250)),
            _buildDebugBtn('Heal Base 250', () => gm.healBase(250)),
            _buildDebugBtn('Trigger Game Over', () => gm.debugKillBase()),
            _buildDebugBtn('Reset Save Data', () async {
              await SaveSystem.resetAll();
              setState(() {});
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugBtn(String label, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: BrutalistButton(
        label: label,
        fontSize: 10,
        verticalPadding: 6,
        horizontalPadding: 8,
        backgroundColor: GameColors.surface,
        onPressed: action,
      ),
    );
  }
}
