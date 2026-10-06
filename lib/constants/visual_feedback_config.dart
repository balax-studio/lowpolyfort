import 'package:flutter/material.dart';

/// Centralized configuration for visual feedback timings, particle budgets,
/// camera impulses, and presentation parameters (Clauses 873–874).
///
/// ponytail: Single point of configuration for all juice timings to prevent magic numbers.
abstract class VisualFeedbackConfig {
  // --- Unit Visuals (Clauses 736–744) ---
  static const double unitIdleBobDuration = 1.4; // 1.2–1.8s
  static const double unitIdleBobAmplitude = 2.5; // 2–3px
  static const double targetingEaseDuration = 0.12; // 80–150ms
  static const double dragInertialTiltMaxDeg = 4.5; // 3–5 degrees
  static const double dragElevationY = 6.0; // 4–8px

  // --- Weapon Recoil & Muzzle (Clauses 739–743) ---
  static const double riflemanFlashDuration = 0.06;
  static const double shotgunnerFlashDuration = 0.09;
  static const double sniperFlashDuration = 0.07;
  static const double heavyFlashDuration = 0.04;

  // --- Enemy Feedback (Clauses 745–751) ---
  static const double hitFlashDuration = 0.06; // 40–70ms
  static const double hitSquashDuration = 0.08; // 60–100ms
  static const double hitSquashScaleX = 1.03; // +3%
  static const double hitSquashScaleY = 0.97; // -3%
  static const double enemySpawnDuration = 0.20; // 150–250ms
  static const double enemyDeathDissolveDuration = 0.20; // 150–250ms

  // --- Merge Choreography (Clauses 761–766) ---
  static const double mergeSequenceDuration = 0.55; // 450–650ms
  static const double mergeCompressionDuration = 0.10; // 80–120ms
  static const int mergeParticlesStandard = 14; // 12–18
  static const int mergeParticlesHighLevel = 20; // 18–24
  static const int mergeParticlesMaxLevel = 26; // 24–30

  // --- Damage Numbers & Throttling (Clauses 767–769, 805) ---
  static const double damageTextDuration = 0.60; // 0.45–0.75s
  static const int maxVisibleFloatingTexts = 14; // 12–16 max
  static const double damageBatchWindowSeconds = 0.10; // 100ms throttle for rapid hits

  // --- Banners & UI Motion (Clauses 770–774, 806) ---
  static const double waveBannerDuration = 0.85; // 700–1000ms
  static const double bossWarningDuration = 1.2; // 1.0–1.5s
  static const double bossDefeatDuration = 0.90; // 700–1100ms
  static const double uiTransitionDurationMs = 200.0; // 150–250ms
  static const double coinCountUpDurationSmall = 0.15; // 100–200ms
  static const double coinCountUpDurationBoss = 0.30; // 250–400ms

  // --- Camera Shake Presets (Clauses 799–801) ---
  static const double shakeMicroDuration = 0.06; // 40–70ms
  static const double shakeMicroIntensity = 2.0;

  static const double shakeSmallDuration = 0.10; // 80–120ms
  static const double shakeSmallIntensity = 4.0;

  static const double shakeMediumDuration = 0.15; // 120–180ms
  static const double shakeMediumIntensity = 6.5;

  // --- Particle Budget (Clauses 803–804) ---
  static const int maxActiveParticles = 60; // 40–60 active small particles cap
  static const double particleLifetimeMin = 0.20;
  static const double particleLifetimeMax = 0.80;

  // --- Mode Accent Colors (Clauses 788–790) ---
  static const Color normalAccent = Color(0xFF00E5FF); // Blue / Cyan
  static const Color chaosRushAccent = Color(0xFFFF5252); // Orange / Red
  static const Color chaosRichAccent = Color(0xFFFFD700); // Gold
  static const Color chaosRapidAccent = Color(0xFF00E5FF); // Cyan
  static const Color chaosGiantsAccent = Color(0xFF9C27B0); // Purple
  static const Color bossRushAccent = Color(0xFFFF3D00); // Red / Orange
}
