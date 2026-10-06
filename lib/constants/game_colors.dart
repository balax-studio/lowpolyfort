import 'package:flutter/material.dart';

/// Centralized color palette for Poly Fort.
/// Enforces separation between Neo-Brutalist UI and Low-Poly battlefield styles.
class GameColors {
  GameColors._();

  // --- NEO-BRUTALIST UI PALETTE ---
  static const Color background = Color(0xFFF4F0E6); // Warm paper-like canvas
  static const Color ink = Color(0xFF151515); // Pure deep ink black
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFEBE6D8);

  static const Color acidYellow = Color(0xFFFFE500); // Primary action / Coin / Highlight
  static const Color electricLime = Color(0xFFB9FF38); // Success / Upgrade / Wave
  static const Color punchRed = Color(0xFFFF4F4F); // Danger / Base HP / Boss alert
  static const Color techBlue = Color(0xFF5DA9FF); // Units / Shield / Info
  static const Color vividOrange = Color(0xFFFF7648); // Warning / Critical / Shotgun
  static const Color cyberPurple = Color(0xFFB388FF); // Epic / Heavy Gunner / Scrap
  static const Color gold = Color(0xFFFFD700);

  // --- 2.5D LOW-POLY WORLD & BATTLEFIELD PALETTE ---
  // Ground & Outpost
  static const Color groundBase = Color(0xFF8B9287);
  static const Color groundHighlight = Color(0xFFA2A99E);
  static const Color groundShadow = Color(0xFF6F756B);
  static const Color roadMarking = Color(0xFFE5D57B);
  static const Color sandbagBase = Color(0xFFC4B184);
  static const Color sandbagShadow = Color(0xFFA39167);
  static const Color metalBarrier = Color(0xFF5C636B);

  // Units
  static const Color unitSkin = Color(0xFFFFD2A6);
  static const Color unitSkinShadow = Color(0xFFD6A578);
  static const Color riflemanUniform = Color(0xFF3B82F6);
  static const Color shotgunnerUniform = Color(0xFFF97316);
  static const Color sniperUniform = Color(0xFF10B981);
  static const Color heavyGunnerUniform = Color(0xFF8B5CF6);
  static const Color unitDropShadow = Color(0x55000000);

  // Enemies
  static const Color enemyBasic = Color(0xFF48BB78);
  static const Color enemyRunner = Color(0xFFF59E0B);
  static const Color enemyTank = Color(0xFFDC2626);
  static const Color enemySwarm = Color(0xFF06B6D4);
  static const Color enemyShielded = Color(0xFF3B82F6);
  static const Color enemyShieldRing = Color(0xFF60A5FA);
  static const Color enemyBoss = Color(0xFF7C3AED);

  // Base
  static const Color baseConcrete = Color(0xFF4A5568);
  static const Color baseMetal = Color(0xFF2D3748);
  static const Color baseAccent = Color(0xFFE53E3E);

  // VFX
  static const Color muzzleFlash = Color(0xFFFFF07A);
  static const Color bulletTracer = Color(0xFFFFE066);
  static const Color critGold = Color(0xFFFFD700);
}
