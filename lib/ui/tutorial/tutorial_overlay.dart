import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../../managers/game_manager.dart';
import '../common/brutalist_card.dart';

/// Guided step-by-step interactive tutorial overlay.
class TutorialOverlay extends StatelessWidget {
  final GameManager gameManager;

  const TutorialOverlay({super.key, required this.gameManager});

  @override
  Widget build(BuildContext context) {
    final step = gameManager.tutorialStep;
    if (step <= 0 || step > 3) return const SizedBox.shrink();

    String title;
    String subtitle;
    IconData icon;
    Alignment instructionAlignment;

    switch (step) {
      case 1:
        title = 'İLK ASKERİNİ AL';
        subtitle = 'Aşağıdaki + UNIT butonuna dokun!';
        icon = Icons.touch_app;
        instructionAlignment = const Alignment(0, 0.65);
        break;
      case 2:
        title = 'İKİNCİ ASKERİNİ AL';
        subtitle = 'Birleştirmek için bir asker daha satın al.';
        icon = Icons.person_add;
        instructionAlignment = const Alignment(0, 0.65);
        break;
      case 3:
        title = 'AYNI ASKERLERİ BİRLEŞTİR';
        subtitle = 'Bir askeri diğerinin üzerine sürükle ve bırak!\n"DAHA GÜÇLÜ!" Seviye 2 ortaya çıkacak.';
        icon = Icons.merge_type;
        // Clause 1086, 1087: Top area so target merge units remain completely visible
        instructionAlignment = const Alignment(0, -0.68);
        break;
      default:
        return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        children: [
          // Semi-transparent backdrop highlight (softer in step 3 so field is clear)
          Container(color: Colors.black.withValues(alpha: step == 3 ? 0.22 : 0.35)),

          // Drag guidance indicator for Step 3 (Clause 1088)
          if (step == 3) const _TutorialDragGuide(),

          // Tutorial Instruction Banner
          Align(
            alignment: instructionAlignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: BrutalistCard(
                backgroundColor: GameColors.acidYellow,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderWidth: 3.5,
                shadowOffset: 5.0,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GameColors.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(icon, color: GameColors.acidYellow, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: GameColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle, non-intrusive animated drag guidance indicator (Clause 1088).
class _TutorialDragGuide extends StatefulWidget {
  const _TutorialDragGuide();

  @override
  State<_TutorialDragGuide> createState() => _TutorialDragGuideState();
}

class _TutorialDragGuideState extends State<_TutorialDragGuide> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _DragGuidePainter(progress: _controller.value),
        );
      },
    );
  }
}

class _DragGuidePainter extends CustomPainter {
  final double progress;

  _DragGuidePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Relative positioning scaled to viewport size
    final scaleX = size.width / 450.0;
    final scaleY = size.height / 800.0;

    const startXVirtual = 135.0;
    const startYVirtual = 515.0;
    const targetXVirtual = 225.0;
    const targetYVirtual = 515.0;

    final pStart = Offset(startXVirtual * scaleX, (startYVirtual - 10) * scaleY);
    final pEnd = Offset(targetXVirtual * scaleX, (targetYVirtual - 10) * scaleY);

    // Subtle curved path over the units
    final path = Path()
      ..moveTo(pStart.dx, pStart.dy)
      ..quadraticBezierTo(
        (pStart.dx + pEnd.dx) / 2,
        pStart.dy - 35 * scaleY,
        pEnd.dx,
        pEnd.dy,
      );

    // Dotted / dashed track
    final trackPaint = Paint()
      ..color = GameColors.acidYellow.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, trackPaint);

    // Animated dragging pulse dot
    final t = progress;
    final dotX = (1 - t) * (1 - t) * pStart.dx + 2 * (1 - t) * t * ((pStart.dx + pEnd.dx) / 2) + t * t * pEnd.dx;
    final dotY = (1 - t) * (1 - t) * pStart.dy + 2 * (1 - t) * t * (pStart.dy - 35 * scaleY) + t * t * pEnd.dy;

    final pulseRadius = 7.0 + (sin(progress * pi) * 2.5);
    final dotPaint = Paint()..color = GameColors.acidYellow;
    canvas.drawCircle(Offset(dotX, dotY), pulseRadius, dotPaint);
    canvas.drawCircle(
      Offset(dotX, dotY),
      pulseRadius,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Target drop zone subtle pulsing halo (Clause 1088)
    final targetPulse = 26.0 + (sin(progress * 2 * pi).abs() * 4.0);
    canvas.drawCircle(
      pEnd,
      targetPulse,
      Paint()
        ..color = GameColors.electricLime.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DragGuidePainter oldDelegate) => oldDelegate.progress != progress;
}
