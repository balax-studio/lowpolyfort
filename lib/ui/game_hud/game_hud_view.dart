import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../constants/game_balance.dart';
import '../../constants/visual_feedback_config.dart';
import '../../managers/game_manager.dart';
import '../../game/base_defense_game.dart';
import '../../models/game_mode_data.dart';
import '../../models/enemy_data.dart';
import '../../components/enemy_component.dart';
import '../common/brutalist_button.dart';
import '../common/brutalist_badge.dart';

/// The active battle HUD overlay presenting stats, single prioritized next goal,
/// live celebration alerts, and tactile unit purchase affordances (Clauses 180–183, 199–201, 229, 236, 753, 779–780, 788–789).
class GameHudView extends StatefulWidget {
  final BaseDefenseGame game;

  const GameHudView({super.key, required this.game});

  @override
  State<GameHudView> createState() => _GameHudViewState();
}

class _GameHudViewState extends State<GameHudView> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _hpPulseController;
  late final AnimationController _affordPopController;
  late final AnimationController _coinPulseController;
  late final Animation<double> _coinPulseAnimation;

  int _lastDisplayedCoins = 0;
  bool _prevCanAfford = false;
  String? _toastMessage;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _hpPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _affordPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Coin count-up container pulse (Clause 753: scale 1.0 -> 1.08 -> 1.0)
    _coinPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _coinPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_coinPulseController);

    _lastDisplayedCoins = widget.game.gameManager.economy.displayedCoins;
    _prevCanAfford = widget.game.gameManager.economy.canAffordUnit;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _hpPulseController.dispose();
    _affordPopController.dispose();
    _coinPulseController.dispose();
    super.dispose();
  }

  void _triggerShakeAndToast(String message) {
    setState(() {
      _toastMessage = message;
    });
    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  void _handleUnitPurchase() {
    final game = widget.game;
    final gm = game.gameManager;

    if (game.isBoardFull) {
      _triggerShakeAndToast('BOARD FULL — MERGE UNITS');
      return;
    }

    if (!gm.economy.canAffordUnit) {
      _triggerShakeAndToast('NOT ENOUGH COINS');
      return;
    }

    final success = game.buyAndSpawnUnit();
    if (!success) {
      _triggerShakeAndToast('CANNOT DEPLOY');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.game.gameManager,
        widget.game.gameManager.economy,
      ]),
      builder: (context, _) {
        final gm = widget.game.gameManager;
        final economy = gm.economy;

        final isBoardFull = widget.game.isBoardFull;
        final canAfford = economy.canAffordUnit;
        final isButtonEnabled = canAfford && !isBoardFull;

        // Clause 236: One-shot afford pop when coins cross the threshold
        if (canAfford && !_prevCanAfford) {
          _affordPopController.forward(from: 0.0);
        }
        _prevCanAfford = canAfford;

        // Clause 753: Coin container scale pulse on reward
        if (economy.displayedCoins > _lastDisplayedCoins) {
          _coinPulseController.forward(from: 0.0);
        }
        _lastDisplayedCoins = economy.displayedCoins;

        return SafeArea(
          child: Stack(
            children: [
              // Screen Tint during Boss Warning (Clauses 779–780)
              if (gm.showMidWaveWarning)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.16),
                    ),
                  ),
                ),

              // 1. TOP BAR
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Wave / Boss Badge
                        if (gm.activeMode == GameMode.bossRush)
                          BrutalistBadge(
                            text: 'BOSS ${gm.bossRushRound} / 5',
                            backgroundColor: GameColors.punchRed,
                            textColor: Colors.white,
                            icon: Icons.whatshot,
                            fontSize: 13,
                          )
                        else ...[
                          BrutalistBadge(
                            text: 'WAVE ${gm.currentWave}',
                            backgroundColor: GameColors.electricLime,
                            icon: Icons.flag,
                            fontSize: 13,
                          ),
                          if (gm.activeMode == GameMode.chaos &&
                              gm.activeChaosModifier.type != ChaosModifierType.none) ...[
                            const SizedBox(width: 4),
                            BrutalistBadge(
                              text: gm.activeChaosModifier.title,
                              backgroundColor: GameColors.acidYellow,
                              textColor: GameColors.ink,
                              icon: Icons.bolt,
                              fontSize: 9,
                            ),
                          ],
                        ],

                        // Base HP Bar (Clause 100 & 229: pulses with danger border when below 30%)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: _buildBaseHpGauge(gm),
                          ),
                        ),

                        // Coin Counter with Scale Pulse (Clause 753)
                        ScaleTransition(
                          scale: _coinPulseAnimation,
                          child: BrutalistBadge(
                            text: '${economy.displayedCoins}',
                            backgroundColor: GameColors.acidYellow,
                            icon: Icons.monetization_on,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Single Prioritized Next Goal Pill (Clauses 180–183, 215)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildNextGoalPill(gm),
                    ),
                  ],
                ),
              ),

              // Active Boss HP Bar (Clause 340)
              Builder(builder: (context) {
                final activeBoss = widget.game.activeEnemies
                    .where((e) => e.definition.type == EnemyType.boss && !e.isDead && e.isMounted)
                    .firstOrNull;
                if (activeBoss != null && gm.state == GameState.playing) {
                  return Positioned(
                    top: 75,
                    left: 20,
                    right: 20,
                    child: _buildBossHpBar(activeBoss),
                  );
                }
                return const SizedBox.shrink();
              }),

              // 2. BOSS WARNING & WAVE COUNTDOWN BANNER (Clauses 74, 76, 84, 315, 329)
              if (gm.state == GameState.preparingWave)
                Positioned(
                  top: 75,
                  left: 20,
                  right: 20,
                  child: _buildWaveStatusBanner(gm),
                ),

              // Mode Unlock Banner (Clauses 284, 287)
              if (gm.newModeUnlockedBannerText != null)
                Positioned(
                  top: 85,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: GameColors.electricLime,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: GameColors.ink, width: 3.5),
                      boxShadow: const [
                        BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: GameColors.ink, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          gm.newModeUnlockedBannerText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: GameColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Mid-Wave Boss Warning Banner (Clause 76)
              if (gm.showMidWaveWarning)
                Positioned(
                  top: 85,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: GameColors.punchRed,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: GameColors.ink, width: 3.5),
                      boxShadow: const [
                        BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'WARNING: BOSS INCOMING!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Boss Defeated Banner (Clauses 122, 981)
              if (gm.bossDefeatedBannerText != null)
                Positioned(
                  top: 85,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.72,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: GameColors.electricLime,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GameColors.ink, width: 3.5),
                          boxShadow: const [
                            BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'BOSS DEFEATED!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gm.bossDefeatedBannerText!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GameColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Live In-Combat New Best Banner (Clauses 199–201)
              if (gm.liveNewBestBannerText != null)
                Positioned(
                  top: 85,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: GameColors.electricLime,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: GameColors.ink, width: 3.5),
                      boxShadow: const [
                        BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.military_tech, color: GameColors.ink, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          gm.liveNewBestBannerText!,
                          style: const TextStyle(
                            color: GameColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Floating Toast Feedback (Clauses 58, 165: "NOT ENOUGH COINS", "BOARD FULL")
              if (_toastMessage != null)
                Positioned(
                  bottom: 84,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: GameColors.punchRed,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: GameColors.ink, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: GameColors.ink, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Text(
                        _toastMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),

              // Supply Drop Ad Offer Card (Clauses 449–461, 511)
              if (gm.canOfferSupplyDrop && !isBoardFull)
                Positioned(
                  bottom: 84,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: GestureDetector(
                      onTap: gm.isRewardedAdShowing ? null : gm.claimSupplyDrop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: GameColors.acidYellow,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GameColors.ink, width: 3.0),
                          boxShadow: const [
                            BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flight_takeoff, color: GameColors.ink, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'SUPPLY DROP',
                                  style: TextStyle(
                                    color: GameColors.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  gm.isRewardedAdShowing
                                      ? 'CONNECTING...'
                                      : 'WATCH AD • +${gm.economy.nextUnitCost} COINS',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. BOTTOM ACTION BAR (+ UNIT BUTTON)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Main + UNIT Button with shake & afford pop (Clauses 58, 236)
                    Expanded(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_shakeController, _affordPopController]),
                        builder: (context, child) {
                          final shakeVal = sin(_shakeController.value * pi * 4) * 6.0;
                          final popVal = sin(_affordPopController.value * pi) * 0.06;
                          return Transform.translate(
                            offset: Offset(shakeVal, 0),
                            child: Transform.scale(
                              scale: 1.0 + popVal,
                              child: child,
                            ),
                          );
                        },
                        child: BrutalistButton(
                          label: isBoardFull
                              ? 'BOARD FULL'
                              : '+ UNIT   ${economy.nextUnitCost}',
                          icon: Icons.person_add,
                          backgroundColor: isButtonEnabled
                              ? GameColors.electricLime
                              : const Color(0xFFD6D1C4),
                          textColor: GameColors.ink,
                          fontSize: 16,
                          verticalPadding: 16,
                          onPressed: _handleUnitPurchase,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pause / Menu Button (Clause 140)
                    Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.ink,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: GameColors.surface,
                          foregroundColor: GameColors.ink,
                          side: const BorderSide(color: GameColors.ink, width: 3.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.pause, size: 24),
                        onPressed: () => gm.pauseGame(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Single Prioritized Next Goal Pill (Clauses 180–183)
  Widget _buildNextGoalPill(GameManager gm) {
    final goal = gm.nextGoal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: GameColors.ink,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: goal.accentColor, width: 1.6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(goal.icon, color: goal.accentColor, size: 13),
          const SizedBox(width: 6),
          Text(
            goal.title,
            style: TextStyle(
              color: goal.accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseHpGauge(GameManager gm) {
    final hpPct = gm.baseHpPercentage;
    final currentHp = gm.baseHp.round();
    final maxHp = gm.maxBaseHp.round();
    final isLowHp = hpPct < 0.30;

    return AnimatedBuilder(
      animation: _hpPulseController,
      builder: (context, _) {
        final pulseBorderColor = isLowHp
            ? Color.lerp(GameColors.ink, GameColors.punchRed, _hpPulseController.value)!
            : GameColors.ink;

        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: GameColors.ink,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: pulseBorderColor, width: isLowHp ? 3.2 : 2.8),
            boxShadow: [
              BoxShadow(
                color: isLowHp ? GameColors.punchRed.withValues(alpha: 0.4) : GameColors.ink,
                offset: const Offset(2, 2),
                blurRadius: isLowHp ? 4 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // HP Fill
              FractionallySizedBox(
                widthFactor: hpPct,
                child: Container(
                  decoration: BoxDecoration(
                    color: isLowHp ? GameColors.punchRed : const Color(0xFFE53E3E),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              // HP Text Label (Clause 100)
              Center(
                child: Text(
                  'BASE $currentHp / $maxHp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaveStatusBanner(GameManager gm) {
    final countdown = gm.countdownRemaining.ceil();

    if (gm.activeMode == GameMode.bossRush) {
      final isFinal = gm.bossRushRound >= GameBalance.bossRushTotalRounds;
      final roundTitle = isFinal ? 'FINAL BOSS' : 'ROUND ${gm.bossRushRound} / 5';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GameColors.punchRed,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: GameColors.ink, width: 3.5),
          boxShadow: const [
            BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              roundTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PREPARE YOUR DEFENSE (${countdown}s)',
              style: const TextStyle(
                color: GameColors.acidYellow,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            BrutalistButton(
              label: 'START NOW',
              icon: Icons.fast_forward,
              backgroundColor: GameColors.acidYellow,
              textColor: GameColors.ink,
              fontSize: 12,
              verticalPadding: 6,
              onPressed: () => gm.skipPrepCountdown(),
            ),
          ],
        ),
      );
    }

    if (gm.activeMode == GameMode.chaos && gm.activeChaosModifier.type != ChaosModifierType.none) {
      Color chaosAccent = GameColors.acidYellow;
      Color chaosTextColor = GameColors.ink;
      switch (gm.activeChaosModifier.type) {
        case ChaosModifierType.rushHour:
          chaosAccent = VisualFeedbackConfig.chaosRushAccent;
          chaosTextColor = Colors.white;
          break;
        case ChaosModifierType.toughCrowd:
          chaosAccent = const Color(0xFFFF9100);
          chaosTextColor = GameColors.ink;
          break;
        case ChaosModifierType.swarmWave:
          chaosAccent = const Color(0xFF76FF03);
          chaosTextColor = GameColors.ink;
          break;
        case ChaosModifierType.richWave:
          chaosAccent = VisualFeedbackConfig.chaosRichAccent;
          chaosTextColor = GameColors.ink;
          break;
        case ChaosModifierType.rapidFire:
          chaosAccent = VisualFeedbackConfig.chaosRapidAccent;
          chaosTextColor = GameColors.ink;
          break;
        case ChaosModifierType.giants:
          chaosAccent = VisualFeedbackConfig.chaosGiantsAccent;
          chaosTextColor = Colors.white;
          break;
        case ChaosModifierType.none:
          break;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: chaosAccent,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: GameColors.ink, width: 3.5),
          boxShadow: const [
            BoxShadow(color: GameColors.ink, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              gm.activeChaosModifier.title,
              style: TextStyle(
                color: chaosTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              gm.activeChaosModifier.subtitle,
              style: TextStyle(
                color: chaosTextColor.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    // Normal mode & fallback
    final isBoss = gm.isBossIncoming;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isBoss ? GameColors.punchRed : GameColors.acidYellow,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: GameColors.ink, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: GameColors.ink,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBoss) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'WARNING: BOSS INCOMING!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text(
            (gm.currentWave == 1)
                ? 'STARTING IN $countdown...'
                : 'WAVE ${gm.currentWave}',
            style: TextStyle(
              color: isBoss ? Colors.white : GameColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossHpBar(EnemyComponent boss) {
    final hpPct = (boss.currentHp / boss.maxHp).clamp(0.0, 1.0);
    final pctText = (hpPct * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GameColors.punchRed, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BRUTE BOSS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$pctText%',
                style: const TextStyle(
                  color: GameColors.acidYellow,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: hpPct,
              minHeight: 8,
              backgroundColor: const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(GameColors.punchRed),
            ),
          ),
        ],
      ),
    );
  }
}
