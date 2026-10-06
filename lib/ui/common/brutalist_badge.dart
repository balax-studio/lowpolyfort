import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';

/// Compact high-contrast status pill or tag badge.
class BrutalistBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;

  const BrutalistBadge({
    super.key,
    required this.text,
    this.backgroundColor = GameColors.acidYellow,
    this.textColor = GameColors.ink,
    this.icon,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(color: GameColors.ink, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: GameColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: fontSize + 2),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
