import '../systems/save_system.dart';

/// Lightweight dual-language (English & Turkish) localization dictionary (Clauses 663–666).
/// Keeps UI strings punchy, short, and centralized without external dependencies.
class AppLocalization {
  AppLocalization._();

  static String get currentLanguage {
    try {
      return SaveSystem.currentSave.language;
    } catch (_) {
      return 'en';
    }
  }

  static bool get isTurkish => currentLanguage == 'tr';

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'wave': 'WAVE',
      'boss_incoming': 'BOSS INCOMING',
      'boss_incoming_sub': 'BRUTE WARLORD APPROACHING!',
      'merge': 'MERGE',
      'retry': 'RETRY',
      'add_unit': 'ADD UNIT',
      'base_hp': 'BASE HP',
      'coins': 'COINS',
      'victory': 'VICTORY',
      'defeat': 'DEFEAT',
      'game_over': 'GAME OVER',
      'paused': 'PAUSED',
      'resume': 'RESUME',
      'settings': 'SETTINGS',
      'language': 'LANGUAGE',
      'max': 'MAX',
      'locked': 'LOCKED',
      'scrap': 'SCRAP',
      'supply_drop': 'SUPPLY DROP',
      'second_chance': 'SECOND CHANCE',
      'extra_scrap': 'EXTRA SCRAP',
      'play': 'PLAY',
      'main_menu': 'MAIN MENU',
      'upgrades': 'PERMANENT UPGRADES',
      'back': 'BACK',
      'apply_close': 'APPLY & CLOSE',
      'master_vol': 'MASTER VOLUME',
      'sfx_vol': 'SFX VOLUME',
      'vibration': 'VIBRATION & HAPTICS',
      'damage_numbers': 'DAMAGE NUMBERS',
      'wipe_data': 'RESET ALL PROGRESS',
      'round': 'ROUND',
    },
    'tr': {
      'wave': 'DALGA',
      'boss_incoming': 'BOSS GELİYOR',
      'boss_incoming_sub': 'MUTANT ELEBAŞI YAKLAŞIYOR!',
      'merge': 'BİRLEŞTİR',
      'retry': 'TEKRAR OYNA',
      'add_unit': 'ASKER AL',
      'base_hp': 'ÜS CANI',
      'coins': 'ALTIN',
      'victory': 'ZAFER',
      'defeat': 'YENİLGİ',
      'game_over': 'OYUN BİTTİ',
      'paused': 'DURAKLATILDI',
      'resume': 'DEVAM ET',
      'settings': 'AYARLAR',
      'language': 'DİL',
      'max': 'MAKS',
      'locked': 'KİLİTLİ',
      'scrap': 'HURDA',
      'supply_drop': 'İKMAL PAKETİ',
      'second_chance': 'İKİNCİ ŞANS',
      'extra_scrap': 'EKSTRA HURDA',
      'play': 'OYNA',
      'main_menu': 'ANA MENÜ',
      'upgrades': 'KALICI GELİŞTİRMELER',
      'back': 'GERİ',
      'apply_close': 'UYGULA VE KAPAT',
      'master_vol': 'ANA SES',
      'sfx_vol': 'EFEKT SESİ',
      'vibration': 'TİTREŞİM',
      'damage_numbers': 'HASAR SAYILARI',
      'wipe_data': 'TÜM İLERLEMEYİ SIFIRLA',
      'round': 'TUR',
    },
  };

  /// Looks up localized string by key for the active language.
  static String text(String key) {
    final lang = currentLanguage;
    final dict = _strings[lang] ?? _strings['en']!;
    return dict[key] ?? _strings['en']?[key] ?? key;
  }

  /// Formatted helper for wave display: "WAVE 5" or "DALGA 5" (Clause 666)
  static String waveText(int wave) {
    return '${text('wave')} $wave';
  }

  /// Formatted helper for round display in Boss Rush: "ROUND 1/5" or "TUR 1/5"
  static String roundText(int current, int total) {
    return '${text('round')} $current/$total';
  }
}
