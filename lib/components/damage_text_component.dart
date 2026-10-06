import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/game_balance.dart';
import '../constants/game_colors.dart';

/// Floating damage number with elevation and fade-out.
class DamageTextComponent extends PositionComponent {
  final String text;
  final bool isCrit;

  double _elapsed = 0.0;
  static const double duration = GameBalance.floatingTextDurationSeconds;

  DamageTextComponent({
    required this.text,
    required Vector2 position,
    required this.isCrit,
  }) : super(
          position: position,
          priority: 80,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Rise upward
    position.y -= dt * (isCrit ? 42.0 : 32.0);

    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final scaleFactor = isCrit ? (1.35 - progress * 0.2) : (1.0 - progress * 0.15);

    canvas.save();
    canvas.scale(scaleFactor);

    final textColor = isCrit ? GameColors.critGold : Colors.white;

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor.withValues(alpha: opacity),
        fontSize: isCrit ? 16 : 13,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: opacity),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}
