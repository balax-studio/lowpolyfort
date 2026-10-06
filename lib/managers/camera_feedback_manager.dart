import 'dart:math';
import 'package:flame/extensions.dart';
import '../constants/visual_feedback_config.dart';

enum CameraShakePreset {
  none,
  micro,
  small,
  medium,
}

/// Central arbiter for camera impulses and screen shakes (Clauses 799–801).
/// Enforces non-additive arbitration so simultaneous impulses do not create visual chaos.
///
/// ponytail: Single manager to arbitrate shakes by selecting max intensity/duration.
class CameraFeedbackManager {
  double _shakeIntensity = 0.0;
  double _shakeDuration = 0.0;
  final Random _random = Random();
  final Vector2 _currentOffset = Vector2.zero();

  Vector2 get currentOffset => _currentOffset;
  bool get isShaking => _shakeDuration > 0;
  double get currentIntensity => _shakeIntensity;
  double get remainingDuration => _shakeDuration;

  /// Triggers a preset camera shake following the hierarchy in Clause 800–801.
  void triggerPreset(CameraShakePreset preset) {
    switch (preset) {
      case CameraShakePreset.none:
        break;
      case CameraShakePreset.micro:
        trigger(
          intensity: VisualFeedbackConfig.shakeMicroIntensity,
          duration: VisualFeedbackConfig.shakeMicroDuration,
        );
        break;
      case CameraShakePreset.small:
        trigger(
          intensity: VisualFeedbackConfig.shakeSmallIntensity,
          duration: VisualFeedbackConfig.shakeSmallDuration,
        );
        break;
      case CameraShakePreset.medium:
        trigger(
          intensity: VisualFeedbackConfig.shakeMediumIntensity,
          duration: VisualFeedbackConfig.shakeMediumDuration,
        );
        break;
    }
  }

  /// Arbitrates camera shake by taking the maximum of current and incoming values (Clause 801).
  void trigger({required double intensity, required double duration}) {
    if (duration <= 0 || intensity <= 0) return;

    // Use strongest current shake rather than stacking additively (Clause 801)
    _shakeIntensity = max(_shakeIntensity, intensity);
    _shakeDuration = max(_shakeDuration, duration);
  }

  /// Updates camera shake decay and calculates random offset.
  void update(double dt) {
    if (_shakeDuration > 0) {
      _shakeDuration -= dt;
      if (_shakeDuration <= 0) {
        _shakeDuration = 0.0;
        _shakeIntensity = 0.0;
        _currentOffset.setZero();
      } else {
        final dx = (_random.nextDouble() * 2 - 1) * _shakeIntensity;
        final dy = (_random.nextDouble() * 2 - 1) * _shakeIntensity;
        _currentOffset.setValues(dx, dy);
      }
    } else {
      _currentOffset.setZero();
    }
  }

  /// Resets all camera motion cleanly (Clause 866).
  void reset() {
    _shakeIntensity = 0.0;
    _shakeDuration = 0.0;
    _currentOffset.setZero();
  }
}
