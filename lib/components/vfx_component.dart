import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../constants/game_colors.dart';
import '../constants/visual_feedback_config.dart';

/// Brief spark flash upon bullet impact.
class ImpactFlashVFXComponent extends PositionComponent {
  final Color color;
  double _elapsed = 0.0;
  static const double duration = 0.12;

  ImpactFlashVFXComponent({
    required Vector2 position,
    required this.color,
  }) : super(
          position: position,
          priority: 70,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final p = (_elapsed / duration).clamp(0.0, 1.0);
    final r = 10.0 * (1.0 - p);
    final paint = Paint()
      ..color = color.withValues(alpha: 1.0 - p)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, r, paint);
    canvas.drawCircle(Offset.zero, r * 0.5, Paint()..color = Colors.white);
  }
}

/// Particle puff when an enemy dies (Clause 751: colored particles, smoke, dust, no blood).
class DeathPuffVFXComponent extends PositionComponent {
  final Color color;
  final bool isLarge;
  double _elapsed = 0.0;
  late final List<_PuffParticle> _particles;

  DeathPuffVFXComponent({
    required Vector2 position,
    required this.color,
    this.isLarge = false,
  }) : super(
          position: position,
          priority: 75,
        ) {
    final count = isLarge ? 14 : 8;
    final random = Random();
    _particles = List.generate(count, (i) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 40.0 + random.nextDouble() * (isLarge ? 90.0 : 60.0);
      final size = 3.5 + random.nextDouble() * (isLarge ? 7.0 : 3.5);
      final isShard = i % 2 == 0;
      return _PuffParticle(
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        initialSize: size,
        rotation: random.nextDouble() * pi,
        rotSpeed: (random.nextDouble() - 0.5) * 10.0,
        isShard: isShard,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final maxDur = isLarge ? 0.35 : 0.24;
    if (_elapsed >= maxDur) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final maxDur = isLarge ? 0.35 : 0.24;
    final p = (_elapsed / maxDur).clamp(0.0, 1.0);
    final alpha = (1.0 - p).clamp(0.0, 1.0);

    for (final part in _particles) {
      final currentPos = part.velocity * _elapsed;
      final currentSize = part.initialSize * (1.0 - p * 0.7);

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(part.rotation + part.rotSpeed * _elapsed);

      if (part.isShard) {
        // Faceted low-poly debris shard (Clause 1081)
        final shardRect = Rect.fromCenter(
          center: Offset.zero,
          width: currentSize * 1.6,
          height: currentSize * 1.6,
        );
        final paint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawRect(shardRect, paint);
        canvas.drawRect(
          shardRect,
          Paint()
            ..color = GameColors.ink.withValues(alpha: alpha * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      } else {
        // Soft impact dust puff
        final dustColor = Color.lerp(color, const Color(0xFFCBD5E1), 0.5)!;
        final paint = Paint()
          ..color = dustColor.withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, currentSize, paint);
      }

      canvas.restore();
    }
  }
}

class _PuffParticle {
  final Offset velocity;
  final double initialSize;
  final double rotation;
  final double rotSpeed;
  final bool isShard;
  _PuffParticle({
    required this.velocity,
    required this.initialSize,
    required this.rotation,
    required this.rotSpeed,
    required this.isShard,
  });
}

/// Saturated white/cyan/yellow radial burst when two units are merged (Clauses 761–766).
///
/// ponytail: Level-scaled particles (14 to 26) with 550ms lifetime for rich merge feel.
class MergeBurstVFXComponent extends PositionComponent {
  final int targetLevel;
  double _elapsed = 0.0;
  static const double duration = VisualFeedbackConfig.mergeSequenceDuration;
  late final List<_MergeParticle> _particles;

  MergeBurstVFXComponent({
    required Vector2 position,
    this.targetLevel = 2,
  }) : super(
          position: position,
          priority: 95,
        ) {
    int count;
    if (targetLevel >= 8) {
      count = VisualFeedbackConfig.mergeParticlesMaxLevel;
    } else if (targetLevel >= 5) {
      count = VisualFeedbackConfig.mergeParticlesHighLevel;
    } else {
      count = VisualFeedbackConfig.mergeParticlesStandard;
    }

    final random = Random();
    final colors = [
      Colors.white,
      GameColors.techBlue, // Cyan
      GameColors.acidYellow, // Acid yellow
    ];

    _particles = List.generate(count, (i) {
      final angle = (i * 2 * pi / count) + (random.nextDouble() * 0.3 - 0.15);
      final speed = 40.0 + random.nextDouble() * 60.0;
      final particleColor = colors[i % colors.length];
      return _MergeParticle(
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: particleColor,
        size: 3.5 + random.nextDouble() * 3.0,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = (1.0 - t).clamp(0.0, 1.0);

    // Expanding radial shockwave ring (Clause 762)
    final ringRadius = 15.0 + t * 45.0;
    final ringPaint = Paint()
      ..color = GameColors.acidYellow.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 * (1.0 - t * 0.7);
    canvas.drawCircle(Offset.zero, ringRadius, ringPaint);

    // Max Level special gold ring (Clause 766)
    if (targetLevel >= 8) {
      final maxRingPaint = Paint()
        ..color = GameColors.gold.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(Offset.zero, ringRadius * 1.25, maxRingPaint);
    }

    // Radiating energy rays
    final rayPaint = Paint()
      ..color = GameColors.gold.withValues(alpha: opacity)
      ..strokeWidth = 3.0;

    const rays = 8;
    for (int i = 0; i < rays; i++) {
      final angle = (i * pi) / (rays / 2);
      final inner = 8.0 + t * 15.0;
      final outer = 22.0 + t * 40.0;
      canvas.drawLine(
        Offset(cos(angle) * inner, sin(angle) * inner),
        Offset(cos(angle) * outer, sin(angle) * outer),
        rayPaint,
      );
    }

    // Radial particles
    for (final p in _particles) {
      final currentPos = p.velocity * _elapsed;
      final currentSize = p.size * (1.0 - t);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentPos, currentSize, paint);
    }
  }
}

class _MergeParticle {
  final Offset velocity;
  final Color color;
  final double size;
  _MergeParticle({required this.velocity, required this.color, required this.size});
}

/// Ground shockwave for Boss ground-slams and heavy impacts.
class ShockwaveVFXComponent extends PositionComponent {
  final Color color;
  double _elapsed = 0.0;
  static const double duration = 0.4;

  ShockwaveVFXComponent({
    required Vector2 position,
    required this.color,
  }) : super(
          position: position,
          priority: 45,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = (1.0 - t).clamp(0.0, 1.0);

    // Elliptical ground ring (perspective compression)
    final rx = 20.0 + t * 50.0;
    final ry = rx * 0.45;

    final shockPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1.0 - t);

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      shockPaint,
    );
  }
}
