import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';
import '../common/brutalist_card.dart';

/// Clean Neo-Brutalist loading/splash sequence before transitioning to Main Menu (Clauses 169, 170).
class SplashScreen extends StatefulWidget {
  final VoidCallback onLoaded;

  const SplashScreen({super.key, required this.onLoaded});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    const totalSteps = 20;
    for (int i = 1; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
      if (!mounted) return;
      setState(() {
        _progress = i / totalSteps;
      });
    }
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      widget.onLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrutalistCard(
                backgroundColor: GameColors.acidYellow,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                borderWidth: 4.0,
                shadowOffset: 6.0,
                child: Column(
                  children: [
                    const Icon(Icons.shield, color: GameColors.ink, size: 48),
                    const SizedBox(height: 10),
                    const Text(
                      'POLY FORT',
                      style: TextStyle(
                        color: GameColors.ink,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GameColors.ink,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'INITIALIZING DEFENSE SYSTEMS...',
                        style: TextStyle(
                          color: GameColors.acidYellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Progress Bar
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: GameColors.ink, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: GameColors.ink, offset: Offset(2, 2)),
                  ],
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: GameColors.electricLime,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(_progress * 100).round()}%',
                style: const TextStyle(
                  color: GameColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
