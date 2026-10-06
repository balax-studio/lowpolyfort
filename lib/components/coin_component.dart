import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/game_colors.dart';
import '../constants/game_config.dart';

/// Animated coin drop that pops from fallen enemies and flies to the top HUD.
class CoinComponent extends PositionComponent {
  final int coinValue;

  double _elapsed = 0.0;
  static const double duration = 0.75;
  late Vector2 _startPos;
  late Vector2 _targetPos;
  late Vector2 _arcPeak;

  CoinComponent({
    required Vector2 spawnPosition,
    required this.coinValue,
  }) : super(
          position: spawnPosition.clone(),
          size: Vector2(16, 16),
          anchor: Anchor.center,
          priority: 85,
        ) {
    _startPos = spawnPosition.clone();
    _targetPos = Vector2(GameConfig.virtualWidth - 50, 40); // Top-right HUD
    // Control point for quadratic bezier curve pop
    _arcPeak = Vector2(
      (_startPos.x + _targetPos.x) / 2 + (Random().nextDouble() * 40 - 20),
      min(_startPos.y, _targetPos.y) - 60,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final t = (_elapsed / duration).clamp(0.0, 1.0);

    // Quadratic Bezier arc: B(t) = (1-t)^2 P0 + 2(1-t)t P1 + t^2 P2
    final invT = 1.0 - t;
    position.x = invT * invT * _startPos.x + 2 * invT * t * _arcPeak.x + t * t * _targetPos.x;
    position.y = invT * invT * _startPos.y + 2 * invT * t * _arcPeak.y + t * t * _targetPos.y;

    if (t >= 1.0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final t = (_elapsed / duration).clamp(0.0, 1.0);

    // Spinning gold coin
    final spin = sin(_elapsed * 12).abs();
    const r = 8.0;

    final coinRect = Rect.fromCenter(center: Offset.zero, width: (r * 2) * max(0.2, spin), height: r * 2);
    canvas.drawOval(coinRect, Paint()..color = GameColors.acidYellow);

    // Coin border
    canvas.drawOval(
      coinRect,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Embossed inner symbol
    if (spin > 0.4) {
      canvas.drawCircle(Offset.zero, 3.0, Paint()..color = Colors.white.withValues(alpha: 0.6));
    }

    // Small floating text pop (Clause 752)
    if (t < 0.65) {
      final popOpacity = (1.0 - (t / 0.65)).clamp(0.0, 1.0);
      final textSpan = TextSpan(
        text: '+$coinValue',
        style: TextStyle(
          color: GameColors.acidYellow.withValues(alpha: popOpacity),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: popOpacity),
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(12, -8));
    }
  }
}
