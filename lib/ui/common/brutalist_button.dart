import 'package:flutter/material.dart';
import '../../constants/game_colors.dart';

/// A physical, tactile Neo-Brutalist button featuring high contrast,
/// a 3.5px solid black border, and an offset drop-shadow that compresses on click (Clause 791).
///
/// Supports an optional single-shot attention pulse for newly available actions (Clause 792).
class BrutalistButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final bool fullWidth;
  final bool pulseOnce;

  const BrutalistButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = GameColors.acidYellow,
    this.textColor = GameColors.ink,
    this.icon,
    this.fontSize = 16.0,
    this.horizontalPadding = 20.0,
    this.verticalPadding = 14.0,
    this.fullWidth = false,
    this.pulseOnce = false,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_pulseController);

    if (widget.pulseOnce) {
      _pulseController.forward();
    }
  }

  @override
  void didUpdateWidget(BrutalistButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.pulseOnce && widget.pulseOnce) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final bgColor = isEnabled ? widget.backgroundColor : const Color(0xFFC7C3B7);
    final offsetVal = (_isPressed && isEnabled) ? 1.0 : 4.0;
    final translateVal = (_isPressed && isEnabled) ? 3.0 : 0.0;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        child: Transform.translate(
          offset: Offset(translateVal, translateVal),
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
              vertical: widget.verticalPadding,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: GameColors.ink, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: GameColors.ink,
                  offset: Offset(offsetVal, offsetVal),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isEnabled ? widget.textColor : const Color(0xFF7A776F),
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
