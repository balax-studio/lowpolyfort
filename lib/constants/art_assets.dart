import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import '../models/hero_data.dart';
import '../models/enemy_data.dart';

/// Centralized art asset paths and registries for Pre-Rendered Low-Poly 2.5D visual layer (Clauses 951, 966).
class WorldArtAssets {
  static const String arenaGround = 'assets/art/world/arena/arena_ground.webp';
  static const String defensePad = 'assets/art/world/slots/defense_pad.webp';
  static const String mainBase = 'assets/art/world/base/main_base.webp';
  static const String warningLight = 'assets/art/world/base/warning_light.webp';

  // Props (Clauses 916, 952)
  static const String sandbags = 'assets/art/world/props/sandbags.webp';
  static const String crate = 'assets/art/world/props/crate.webp';
  static const String barrel = 'assets/art/world/props/barrel.webp';
  static const String radar = 'assets/art/world/props/radar.webp';
  static const String lamp = 'assets/art/world/props/lamp.webp';
  static const String grass = 'assets/art/world/props/grass.webp';
}

/// Visual definition and socket configuration for friendly units (Clauses 967–969).
class UnitVisualDefinition {
  final String bodyAsset;
  final String weaponAsset;
  final String powerAccentAsset;
  final Vector2 bodySize;
  final Vector2 weaponSocketOffset;
  final Vector2 muzzleSocketOffset;
  final Vector2 shadowSize;

  const UnitVisualDefinition({
    required this.bodyAsset,
    required this.weaponAsset,
    required this.powerAccentAsset,
    required this.bodySize,
    required this.weaponSocketOffset,
    required this.muzzleSocketOffset,
    required this.shadowSize,
  });
}

class UnitArtAssets {
  static final Map<HeroClass, UnitVisualDefinition> definitions = {
    HeroClass.rifleman: UnitVisualDefinition(
      bodyAsset: 'assets/art/units/rifleman/body.webp',
      weaponAsset: 'assets/art/units/rifleman/weapon.webp',
      powerAccentAsset: 'assets/art/units/rifleman/power_accent.webp',
      bodySize: Vector2(72, 72),
      weaponSocketOffset: Vector2(10, -8),
      muzzleSocketOffset: Vector2(0, -22),
      shadowSize: Vector2(40, 18),
    ),
    HeroClass.shotgunner: UnitVisualDefinition(
      bodyAsset: 'assets/art/units/shotgunner/body.webp',
      weaponAsset: 'assets/art/units/shotgunner/weapon.webp',
      powerAccentAsset: 'assets/art/units/shotgunner/power_accent.webp',
      bodySize: Vector2(76, 76),
      weaponSocketOffset: Vector2(12, -6),
      muzzleSocketOffset: Vector2(0, -18),
      shadowSize: Vector2(46, 20),
    ),
    HeroClass.sniper: UnitVisualDefinition(
      bodyAsset: 'assets/art/units/sniper/body.webp',
      weaponAsset: 'assets/art/units/sniper/weapon.webp',
      powerAccentAsset: 'assets/art/units/sniper/power_accent.webp',
      bodySize: Vector2(70, 74),
      weaponSocketOffset: Vector2(8, -10),
      muzzleSocketOffset: Vector2(0, -30),
      shadowSize: Vector2(36, 16),
    ),
    HeroClass.heavyGunner: UnitVisualDefinition(
      bodyAsset: 'assets/art/units/heavy_gunner/body.webp',
      weaponAsset: 'assets/art/units/heavy_gunner/weapon.webp',
      powerAccentAsset: 'assets/art/units/heavy_gunner/power_accent.webp',
      bodySize: Vector2(82, 82),
      weaponSocketOffset: Vector2(14, -4),
      muzzleSocketOffset: Vector2(0, -26),
      shadowSize: Vector2(52, 22),
    ),
  };

  /// Power accent layer opacity scaling with level (Clause 928).
  static double getPowerAccentOpacity(int level) {
    switch (level) {
      case 1:
        return 0.00;
      case 2:
        return 0.15;
      case 3:
        return 0.25;
      case 4:
        return 0.35;
      case 5:
        return 0.45;
      case 6:
        return 0.60;
      case 7:
        return 0.75;
      case 8:
        return 1.00;
      default:
        return level > 8 ? 1.00 : 0.00;
    }
  }
}

/// Visual definition and walk animation parameters for enemy archetypes (Clause 970).
class EnemyVisualDefinition {
  final String walkAsset;
  final int frameCount;
  final double animationFps;
  final Vector2 visualSize;
  final Vector2 shadowSize;
  final String? shieldAsset;

  const EnemyVisualDefinition({
    required this.walkAsset,
    this.frameCount = 6,
    required this.animationFps,
    required this.visualSize,
    required this.shadowSize,
    this.shieldAsset,
  });
}

class EnemyArtAssets {
  static final Map<EnemyType, EnemyVisualDefinition> definitions = {
    EnemyType.basic: EnemyVisualDefinition(
      walkAsset: 'assets/art/enemies/basic/walk.webp',
      animationFps: 8.0,
      visualSize: Vector2(64, 64),
      shadowSize: Vector2(38, 16),
    ),
    EnemyType.runner: EnemyVisualDefinition(
      walkAsset: 'assets/art/enemies/runner/walk.webp',
      animationFps: 12.0,
      visualSize: Vector2(58, 60),
      shadowSize: Vector2(32, 14),
    ),
    EnemyType.tank: EnemyVisualDefinition(
      walkAsset: 'assets/art/enemies/tank/walk.webp',
      animationFps: 6.0,
      visualSize: Vector2(84, 84),
      shadowSize: Vector2(56, 24),
    ),
    EnemyType.swarm: EnemyVisualDefinition(
      walkAsset: 'assets/art/enemies/swarm/walk.webp',
      animationFps: 12.0,
      visualSize: Vector2(48, 48),
      shadowSize: Vector2(26, 12),
    ),
    EnemyType.shielded: EnemyVisualDefinition(
      walkAsset: 'assets/art/enemies/shielded/walk.webp',
      animationFps: 8.0,
      visualSize: Vector2(70, 70),
      shadowSize: Vector2(44, 18),
      shieldAsset: 'assets/art/enemies/shielded/shield.webp',
    ),
    EnemyType.boss: EnemyVisualDefinition(
      walkAsset: 'assets/art/enemies/brute/walk.webp',
      animationFps: 6.0,
      visualSize: Vector2(130, 130),
      shadowSize: Vector2(88, 36),
    ),
  };
}

/// Central Art Asset Manager responsible for preloading and caching images (Clauses 953, 954, 1009, 1010).
/// ponytail: Static map cache to ensure each asset is decoded exactly once.
class ArtAssetManager {
  static final Map<String, Image> _cache = {};
  static final Set<String> _missingLogged = {};
  static bool isPreloaded = false;

  static Image? getImage(String path) => _cache[path];

  /// Preloads all world, unit, and enemy art into the Flame image cache (Clause 1009).
  static Future<void> preloadAll() async {
    if (isPreloaded) return;

    final allPaths = [
      WorldArtAssets.arenaGround,
      WorldArtAssets.defensePad,
      WorldArtAssets.mainBase,
      WorldArtAssets.warningLight,
      WorldArtAssets.sandbags,
      WorldArtAssets.crate,
      WorldArtAssets.barrel,
      WorldArtAssets.radar,
      WorldArtAssets.lamp,
      WorldArtAssets.grass,
      for (final def in UnitArtAssets.definitions.values) ...[
        def.bodyAsset,
        def.weaponAsset,
        def.powerAccentAsset,
      ],
      for (final def in EnemyArtAssets.definitions.values) ...[
        def.walkAsset,
        if (def.shieldAsset != null) def.shieldAsset!,
      ],
    ];

    for (final path in allPaths) {
      try {
        // Load via Flame Images
        final img = await Flame.images.load(path);
        _cache[path] = img;
      } catch (e) {
        if (!_missingLogged.contains(path)) {
          _missingLogged.add(path);
          debugPrint('MISSING ART: $path');
        }
        if (kReleaseMode) {
          throw StateError('CRITICAL RELEASE ASSET MISSING: $path');
        }
      }
    }
    isPreloaded = true;
  }
}
