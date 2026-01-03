# res://scripts/game/stats_runtime.gd
# =========================================================
# 📊 StatsRuntime.gd
# ---------------------------------------------------------
# Objectif :
# - Construire les stats finales du joueur
# - Base (stats_economie) + Bonus équipement (items_equipements)
#
# IMPORTANT :
# - On ne "devine" pas des règles complexes ici.
# - On fait un calcul simple additive pour commencer.
# - Plus tard on pourra gérer multiplicateurs, caps, etc.
# =========================================================
extends RefCounted
# ---------------------------------------------------------
# 🔧 Construit une table "base_stats" depuis DataScore.stats_by_id
# - On ne prend que les stats qui ont une Valeur_Base non vide
# ---------------------------------------------------------
static func build_base_stats() -> Dictionary:
	var base: Dictionary = {}

	Log.i("STATS", "Construction base_stats depuis stats_economie")

	for id in DataScore.stats_by_id.keys():
		var row: Dictionary = DataScore.get_stat(id)

		# 🔎 Valeur_Base peut être null (on ignore dans ce cas)
		var vb = row.get("Valeur_Base", null)
		if vb == null:
			continue

		# ✅ On stocke en float
		base[id] = float(vb)

	Log.ok("STATS", "base_stats construit", {"count": base.size()})
	return base

# ---------------------------------------------------------
# 🧩 Applique les bonus des items équipés
# - equipped = { "SWORD": "ITEM_SWORD_001", "ARMOR": "ITEM_ARMOR_003", ... }
# - Retourne un dictionnaire bonus par stat_id
# ---------------------------------------------------------
static func compute_equipment_bonuses(equipped: Dictionary) -> Dictionary:
	var bonuses: Dictionary = {}
	Log.i("STATS", "Calcul bonus équipement", {"slots": equipped.size()})

	for slot_code in equipped.keys():
		var item_id: String = str(equipped[slot_code]).strip_edges()
		if item_id == "":
			continue

		var item: Dictionary = DataScore.get_item(item_id)
		if item.is_empty():
			Log.w("STATS", "Item introuvable (equip)", {"slot": slot_code, "item_id": item_id})
			continue

		# Bonus principal
		var stat1_id: String = str(item.get("Stat_Principale_ID", "")).strip_edges()
		var val1 = item.get("Valeur_Principale", null)

		# Bonus secondaire
		var stat2_id: String = str(item.get("Stat_Secondaire_ID", "")).strip_edges()
		var val2 = item.get("Valeur_Secondaire", null)

		# 🧪 Logs
		Log.d("STATS", "Equip slot", {
			"slot": slot_code,
			"item": item_id,
			"stat1": stat1_id,
			"val1": val1,
			"stat2": stat2_id,
			"val2": val2
		})

		# Appliquer bonus 1
		if stat1_id != "" and val1 != null:
			var add1: float = float(val1)
			bonuses[stat1_id] = float(bonuses.get(stat1_id, 0.0)) + add1

		# Appliquer bonus 2
		if stat2_id != "" and val2 != null:
			var add2: float = float(val2)
			bonuses[stat2_id] = float(bonuses.get(stat2_id, 0.0)) + add2

	Log.ok("STATS", "Bonus équipement calculés", {"count": bonuses.size()})
	return bonuses

# ---------------------------------------------------------
# ✅ Construit les stats finales :
# final = base + bonuses
# ---------------------------------------------------------
static func compute_final_stats(equipped: Dictionary) -> Dictionary:
	Log.i("STATS", "Compute stats finales")

	var base: Dictionary = build_base_stats()
	var bonuses: Dictionary = compute_equipment_bonuses(equipped)

	# Copie base -> final
	var final: Dictionary = {}
	for k in base.keys():
		final[k] = float(base[k])

	# Ajoute bonus
	for stat_id in bonuses.keys():
		final[stat_id] = float(final.get(stat_id, 0.0)) + float(bonuses[stat_id])

	Log.ok("STATS", "Stats finales prêtes", {"count": final.size()})
	return final
