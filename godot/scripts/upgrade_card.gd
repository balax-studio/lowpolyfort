class_name UpgradeCard
extends RefCounted

## Roguelite Upgrade Card model.
## Source of truth: Flutter lib/models/upgrade_data.dart (Clause 88).

enum UpgradeRarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum UpgradeType {
	HEAVY_AMMO,
	RAPID_FIRE,
	LONG_BARRELS,
	CRITICAL_TRAINING,
	FORTIFIED_BASE,
	FIELD_REPAIR,
	BOUNTY_HUNTER,
	ARMOR_PIERCING
}

var id: String = ""
var title: String = ""
var description: String = ""
var rarity: UpgradeRarity = UpgradeRarity.COMMON
var type: UpgradeType = UpgradeType.HEAVY_AMMO
var value_multiplier: float = 0.0

func _init(p_id: String, p_title: String, p_desc: String, p_rarity: UpgradeRarity, p_type: UpgradeType, p_val: float) -> void:
	id = p_id
	title = p_title
	description = p_desc
	rarity = p_rarity
	type = p_type
	value_multiplier = p_val

func get_rarity_color() -> Color:
	match rarity:
		UpgradeRarity.COMMON:
			return Color.WHITE
		UpgradeRarity.RARE:
			return Color(0.2, 0.6, 1.0) # Tech Blue
		UpgradeRarity.EPIC:
			return Color(0.7, 0.3, 0.9) # Cyber Purple
		UpgradeRarity.LEGENDARY:
			return Color(1.0, 0.85, 0.1) # Acid Yellow
	return Color.WHITE

func get_rarity_label() -> String:
	match rarity:
		UpgradeRarity.COMMON:
			return "COMMON"
		UpgradeRarity.RARE:
			return "RARE"
		UpgradeRarity.EPIC:
			return "EPIC"
		UpgradeRarity.LEGENDARY:
			return "LEGENDARY"
	return "COMMON"

static var _pool: Array[UpgradeCard] = []

static func get_pool() -> Array[UpgradeCard]:
	if _pool.is_empty():
		_pool = [
			UpgradeCard.new("heavy_ammo", "HEAVY AMMO", "+15% UNIT DAMAGE", UpgradeRarity.COMMON, UpgradeType.HEAVY_AMMO, 0.15),
			UpgradeCard.new("rapid_fire", "RAPID FIRE", "+10% ATTACK SPEED", UpgradeRarity.COMMON, UpgradeType.RAPID_FIRE, 0.10),
			UpgradeCard.new("long_barrels", "LONG BARRELS", "+12% WEAPON RANGE", UpgradeRarity.RARE, UpgradeType.LONG_BARRELS, 0.12),
			UpgradeCard.new("critical_training", "CRITICAL TRAINING", "+5% CRITICAL CHANCE", UpgradeRarity.RARE, UpgradeType.CRITICAL_TRAINING, 0.05),
			UpgradeCard.new("fortified_base", "FORTIFIED BASE", "+200 BASE HP & REPAIR", UpgradeRarity.COMMON, UpgradeType.FORTIFIED_BASE, 200.0),
			UpgradeCard.new("field_repair", "FIELD REPAIR", "+30% BASE HP REPAIR", UpgradeRarity.RARE, UpgradeType.FIELD_REPAIR, 0.30),
			UpgradeCard.new("bounty_hunter", "BOUNTY HUNTER", "+15% ENEMY COIN REWARDS", UpgradeRarity.RARE, UpgradeType.BOUNTY_HUNTER, 0.15),
			UpgradeCard.new("armor_piercing", "ARMOR PIERCING", "+20% VS TANK & SHIELDED", UpgradeRarity.EPIC, UpgradeType.ARMOR_PIERCING, 0.20),
		]
	return _pool
