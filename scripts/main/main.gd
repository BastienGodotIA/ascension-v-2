extends Node

func _ready() -> void:
	Log.ok("MAIN", "Main chargé ✅")

	# ✅ Exemples d’IDs vus dans ta console
	Log.d("MAIN", "STAT_HP_MAX_001 = %s" % str(DataScore.get_stat("STAT_HP_MAX_001")))
	Log.d("MAIN", "SLOT SWORD = %s" % str(DataScore.get_slot("SWORD")))
	Log.d("MAIN", "ITEM_SWORD_001 = %s" % str(DataScore.get_item("ITEM_SWORD_001")))

	# 💰 Donne un peu d’or pour tester le shop
	Game.gold = 999
	Log.i("MAIN", "Gold set", {"gold": Game.gold})

	# 🎒 Simule achat + equip
	var ok_buy := Game.try_buy_item("ITEM_SWORD_001")
	Log.ok("MAIN", "Buy result", {"ok": ok_buy})

	Game.equip_item("SWORD", "ITEM_SWORD_001")

	# 📊 Stats finales
	var hp := Game.get_stat("STAT_HP_MAX_001")
	Log.ok("MAIN", "HP final", {"hp": hp})
