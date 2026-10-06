import 'package:flutter/services.dart';

/// Centralized event-driven audio dispatcher.
/// Allows swapping backend implementations (procedural synth, soundpool, or asset pack)
/// without altering gameplay code.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  bool isMuted = false;
  double sfxVolume = 1.0;

  void toggleMute() {
    isMuted = !isMuted;
  }

  void pauseMusic() {}

  void resumeMusic() {}

  void playUnitShoot() {
    if (isMuted) return;
    // Uses platform haptic / click feedback as responsive native sound cue
    // Can be connected to AudioPlayer asset tracks when audio assets are imported
  }

  void playEnemyHit() {
    if (isMuted) return;
  }

  void playMerge() {
    if (isMuted) return;
    HapticFeedback.mediumImpact();
  }

  void playCoin() {
    if (isMuted) return;
  }

  void playBossWarning() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
  }

  void playBaseDamage() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
  }

  void playGameOver() {
    if (isMuted) return;
    HapticFeedback.vibrate();
  }
}
