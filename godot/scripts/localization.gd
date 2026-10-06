class_name AppLocalization
extends RefCounted

## Dual-language (English & Turkish) localization dictionary.
## Source of truth: Flutter lib/localization/app_localization.dart (Clauses 663–666).

const STRINGS = {
	"en": {
		"wave": "WAVE",
		"boss_incoming": "BOSS INCOMING",
		"boss_incoming_sub": "BRUTE WARLORD APPROACHING!",
		"merge": "MERGE",
		"retry": "RETRY",
		"add_unit": "ADD UNIT",
		"base_hp": "BASE HP",
		"coins": "COINS",
		"victory": "VICTORY",
		"defeat": "DEFEAT",
		"game_over": "GAME OVER",
		"paused": "PAUSED",
		"resume": "RESUME",
		"settings": "SETTINGS",
		"language": "LANGUAGE",
		"max": "MAX",
		"locked": "LOCKED",
		"scrap": "SCRAP",
		"supply_drop": "SUPPLY DROP",
		"second_chance": "SECOND CHANCE",
		"extra_scrap": "EXTRA SCRAP",
		"play": "PLAY",
		"main_menu": "MAIN MENU",
		"upgrades": "PERMANENT UPGRADES",
		"back": "BACK",
		"apply_close": "APPLY & CLOSE",
		"master_vol": "MASTER VOLUME",
		"sfx_vol": "SFX VOLUME",
		"vibration": "VIBRATION & HAPTICS",
		"damage_numbers": "DAMAGE NUMBERS",
		"wipe_data": "RESET ALL PROGRESS",
		"round": "ROUND",
	},
	"tr": {
		"wave": "DALGA",
		"boss_incoming": "BOSS GELİYOR",
		"boss_incoming_sub": "MUTANT ELEBAŞI YAKLAŞIYOR!",
		"merge": "BİRLEŞTİR",
		"retry": "TEKRAR OYNA",
		"add_unit": "ASKER AL",
		"base_hp": "ÜS CANI",
		"coins": "ALTIN",
		"victory": "ZAFER",
		"defeat": "YENİLGİ",
		"game_over": "OYUN BİTTİ",
		"paused": "DURAKLATILDI",
		"resume": "DEVAM ET",
		"settings": "AYARLAR",
		"language": "DİL",
		"max": "MAKS",
		"locked": "KİLİTLİ",
		"scrap": "HURDA",
		"supply_drop": "İKMAL PAKETİ",
		"second_chance": "İKİNCİ ŞANS",
		"extra_scrap": "EKSTRA HURDA",
		"play": "OYNA",
		"main_menu": "ANA MENÜ",
		"upgrades": "KALICI GELİŞTİRMELER",
		"back": "GERİ",
		"apply_close": "UYGULA VE KAPAT",
		"master_vol": "ANA SES",
		"sfx_vol": "EFEKT SESİ",
		"vibration": "TİTREŞİM",
		"damage_numbers": "HASAR SAYILARI",
		"wipe_data": "TÜM İLERLEMEYİ SIFIRLA",
		"round": "TUR",
	},
}

static func get_current_language() -> String:
	return SaveManager.language if SaveManager != null else "en"

static func is_turkish() -> bool:
	return get_current_language() == "tr"

static func text(key: String, lang: String = "") -> String:
	var l = lang if lang != "" else get_current_language()
	var dict = STRINGS.get(l, STRINGS["en"])
	if dict.has(key):
		return dict[key]
	var en_dict = STRINGS["en"]
	return en_dict.get(key, key)

static func wave_text(wave: int, lang: String = "") -> String:
	return "%s %d" % [text("wave", lang), wave]

static func round_text(current: int, total: int, lang: String = "") -> String:
	return "%s %d/%d" % [text("round", lang), current, total]
