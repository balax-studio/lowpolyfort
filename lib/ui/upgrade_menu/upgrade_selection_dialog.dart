import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../models/upgrade_data.dart';
import '../../managers/game_manager.dart';
import '../common/brutalist_card.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// Roguelite 3-Card Tactical Upgrade selection modal.
/// Features snappy 200ms staggered card entry and punchy select feedback (Clauses 772–774).
///
/// ponytail: Single animation controller with staggered interval tweens for the 3 cards.
class UpgradeSelectionDialog extends StatefulWidget {
  final GameManager gameManager;

  const UpgradeSelectionDialog({super.key, required this.gameManager});

  @override
  State<UpgradeSelectionDialog> createState() => _UpgradeSelectionDialogState();
}

class _UpgradeSelectionDialogState extends State<UpgradeSelectionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  int? _selectedCardIndex;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220), // 150–250ms (Clause 772)
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _handleSelect(UpgradeCard card, int index) {
    setState(() => _selectedCardIndex = index);
    // 50ms tactile punch before dismissing to game (Clause 773–774)
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) {
        widget.gameManager.chooseUpgrade(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.gameManager.pendingUpgrades;

    return PopScope(
      canPop: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Badge
              const BrutalistBadge(
                text: 'TACTICAL PROMOTION',
                backgroundColor: GameColors.acidYellow,
                icon: Icons.military_tech,
                fontSize: 16,
              ),
              const SizedBox(height: 8),
              const Text(
                'CHOOSE 1 REINFORCEMENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),

              // Staggered Upgrade Cards (Clauses 772–774)
              for (int i = 0; i < cards.length; i++)
                _buildAnimatedCard(cards[i], i, cards.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(UpgradeCard card, int index, int total) {
    // 10–20ms stagger per card (Clause 772)
    final startInterval = (index * 0.15).clamp(0.0, 0.7);
    final endInterval = (startInterval + 0.35).clamp(0.0, 1.0);

    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
      ),
    );

    final isSelected = _selectedCardIndex == index;
    final scaleVal = isSelected ? 1.03 : 1.0;

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: AnimatedScale(
          scale: scaleVal,
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOutBack,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _buildCardItem(card, index),
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(UpgradeCard card, int index) {
    return BrutalistCard(
      backgroundColor: GameColors.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rarity Tag
              BrutalistBadge(
                text: card.rarityLabel,
                backgroundColor: card.rarityColor,
                fontSize: 10,
              ),
              Icon(card.icon, color: GameColors.ink, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.title,
            style: const TextStyle(
              color: GameColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.description,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          BrutalistButton(
            label: 'SELECT',
            fullWidth: true,
            backgroundColor: GameColors.electricLime,
            fontSize: 14,
            verticalPadding: 10,
            onPressed: () => _handleSelect(card, index),
          ),
        ],
      ),
    );
  }
}
