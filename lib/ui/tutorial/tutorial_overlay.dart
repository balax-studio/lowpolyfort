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
        instructionAlignment = const Alignment(0, 0.15);
        break;
      default:
        return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        children: [
          // Semi-transparent backdrop highlight
          Container(color: Colors.black.withValues(alpha: 0.35)),

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
