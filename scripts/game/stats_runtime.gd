# res://scripts/game/stats_runtime.gd
extends RefCounted

static func compute_final_stats(equipped: Dictionary) -> Dictionary:
	# 1) Base stats
	var base: Dictionary = _build_base_stats()

	# 2) Bonus équipement (placeholder simple)
	# Pour l’instant : on ne calcule pas de vrais bonus ici.
	# (On le fera plus tard quand on aura figé la structure des items/stats)
	return base

static func _build_base_stats() -> Dictionary:
	var base: Dictionary = {}

	# On part des rows de stats_economie
	if DataScore.stats_by_id.size() == 0:
		# Pas de Log ici pour éviter bruit + dépendances
		return base

	for id in DataScore.stats_by_id.keys():
		var row: Dictionary = DataScore.get_stat(id)
		if row.is_empty():
			continue

		var vb: Variant = row.get("Valeur_Base", null)
		if vb == null:
			continue

		base[id] = float(vb)

	return base
