extends Node

func _ready() -> void:
	print("✅🎬 Main chargé ✅")
	print("📌 Stats count:", DataScore.stats_by_id.size())
	print("📌 Leveling count:", DataScore.leveling_by_id.size())
	print("📌 Slots count:", DataScore.slots_by_id.size())
	print("📌 Items count:", DataScore.items_by_id.size())

	# 🔎 Exemple : récupérer une stat (mets un ID qui existe)
	print("🧪 Exemple STAT_HP :", DataScore.get_stat("STAT_HP_001"))

	# 🔎 Exemple : récupérer un slot (mets un code qui existe)
	print("🧪 Exemple SLOT_WEAPON :", DataScore.get_slot("SLOT_WEAPON"))

	# 🔎 Exemple : récupérer un item (mets un ID qui existe)
	print("🧪 Exemple ITEM_WEAPON_001 :", DataScore.get_item("ITEM_WEAPON_001"))
