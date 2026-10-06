import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';

/// High-contrast Neo-Brutalist card container.
class BrutalistCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double shadowOffset;
  final VoidCallback? onTap;

  const BrutalistCard({
    super.key,
    required this.child,
    this.backgroundColor = GameColors.surface,
    this.padding = const EdgeInsets.all(16.0),
    this.borderWidth = 3.5,
    this.shadowOffset = 4.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: GameColors.ink, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: GameColors.ink,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: content,
      );
    }
    return content;
  }
}
