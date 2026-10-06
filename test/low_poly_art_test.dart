import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:poly_fort/constants/art_assets.dart';
import 'package:poly_fort/models/hero_data.dart';
import 'package:poly_fort/models/enemy_data.dart';
import 'package:poly_fort/components/defense_slot_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pre-Rendered Low-Poly 2.5D Art Migration Tests (Clauses 883–1056)', () {
    test('UnitArtAssets registers exactly 4 friendly unit definitions (Clauses 930–934)', () {
      expect(UnitArtAssets.definitions.length, equals(4));
      expect(UnitArtAssets.definitions.containsKey(HeroClass.rifleman), isTrue);
      expect(UnitArtAssets.definitions.containsKey(HeroClass.shotgunner), isTrue);
      expect(UnitArtAssets.definitions.containsKey(HeroClass.sniper), isTrue);
      expect(UnitArtAssets.definitions.containsKey(HeroClass.heavyGunner), isTrue);

      for (final entry in UnitArtAssets.definitions.entries) {
        final def = entry.value;
        expect(def.bodyAsset, isNotEmpty);
        expect(def.weaponAsset, isNotEmpty);
        expect(def.powerAccentAsset, isNotEmpty);
        expect(def.bodySize.x, greaterThan(0));
        expect(def.bodySize.y, greaterThan(0));
        expect(def.shadowSize.x, greaterThan(0));
        expect(def.shadowSize.y, greaterThan(0));
      }
    });

    test('Power accent mask opacity matches exact Clause 928 specs', () {
      expect(UnitArtAssets.getPowerAccentOpacity(1), equals(0.00));
      expect(UnitArtAssets.getPowerAccentOpacity(2), equals(0.15));
      expect(UnitArtAssets.getPowerAccentOpacity(3), equals(0.25));
      expect(UnitArtAssets.getPowerAccentOpacity(4), equals(0.35));
      expect(UnitArtAssets.getPowerAccentOpacity(5), equals(0.45));
      expect(UnitArtAssets.getPowerAccentOpacity(6), equals(0.60));
      expect(UnitArtAssets.getPowerAccentOpacity(7), equals(0.75));
      expect(UnitArtAssets.getPowerAccentOpacity(8), equals(1.00));
      // Out of bounds clamps safely
      expect(UnitArtAssets.getPowerAccentOpacity(0), equals(0.00));
      expect(UnitArtAssets.getPowerAccentOpacity(9), equals(1.00));
    });

    test('EnemyArtAssets registers all 6 archetypes with 6-frame loops and Clause 938 FPS', () {
      expect(EnemyArtAssets.definitions.length, equals(6));
      expect(EnemyArtAssets.definitions[EnemyType.basic]!.animationFps, equals(8));
      expect(EnemyArtAssets.definitions[EnemyType.runner]!.animationFps, equals(12));
      expect(EnemyArtAssets.definitions[EnemyType.tank]!.animationFps, equals(6));
      expect(EnemyArtAssets.definitions[EnemyType.swarm]!.animationFps, equals(12));
      expect(EnemyArtAssets.definitions[EnemyType.shielded]!.animationFps, equals(8));
      expect(EnemyArtAssets.definitions[EnemyType.boss]!.animationFps, equals(6));

      for (final def in EnemyArtAssets.definitions.values) {
        expect(def.frameCount, equals(6)); // Clause 937
        expect(def.walkAsset, isNotEmpty);
        expect(def.visualSize.x, greaterThan(0));
        expect(def.visualSize.y, greaterThan(0));
        expect(def.shadowSize.x, greaterThan(0));
        expect(def.shadowSize.y, greaterThan(0));
      }

      // Shielded enemy has dedicated shield asset (Clause 941, 952)
      expect(EnemyArtAssets.definitions[EnemyType.shielded]!.shieldAsset, isNotNull);
      expect(EnemyArtAssets.definitions[EnemyType.shielded]!.shieldAsset, contains('shield.webp'));
    });

    test('DefenseSlotComponent row perspective scaling matches Clause 904', () {
      expect(DefenseSlotComponent.getPerspectiveScale(0), equals(0.92)); // Rear
      expect(DefenseSlotComponent.getPerspectiveScale(1), equals(1.00)); // Middle
      expect(DefenseSlotComponent.getPerspectiveScale(2), equals(1.08)); // Front
    });

    test('All 29 manifest art assets exist on disk (Clauses 952, 1008, 1054)', () {
      final requiredAssets = [
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
        // 4 Units x 3 (body, weapon, power_accent)
        for (final def in UnitArtAssets.definitions.values) ...[
          def.bodyAsset,
          def.weaponAsset,
          def.powerAccentAsset,
        ],
        // 6 Enemies walk + 1 shield = 7
        for (final def in EnemyArtAssets.definitions.values) ...[
          def.walkAsset,
          if (def.shieldAsset != null) def.shieldAsset!,
        ],
      ];

      expect(requiredAssets.length, equals(29));

      final missing = <String>[];
      for (final assetPath in requiredAssets) {
        final file = File(assetPath);
        if (!file.existsSync()) {
          missing.add(assetPath);
        }
      }

      expect(missing, isEmpty, reason: 'Missing assets: $missing');
    });
  });
}
