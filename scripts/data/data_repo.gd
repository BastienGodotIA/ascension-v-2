extends Node
# =========================================================
# 🗄️ DATA REPO (autoload = DataScore)
# =========================================================

const LOG      = preload("res://scripts/core/log.gd")
const CSV      = preload("res://scripts/data/csv_loader.gd")
const SCHEMAS  = preload("res://scripts/data/data_schemas.gd")

const TABLES := {
	"Stats_Economie": {"path": "res://data/export/stats_economie.csv", "id_col": "ID"},
	"Leveling": {"path": "res://data/export/leveling.csv", "id_col": "ID"},
	"Equipement_Slots": {"path": "res://data/export/equipement_slots.csv", "id_col": "Code"},
	"Items_Equipements": {"path": "res://data/export/items_equipements.csv", "id_col": "ID"},
}

var tables_cache: Dictionary = {}

var stats_table: Dictionary = {}
var leveling_table: Dictionary = {}
var slots_table: Dictionary = {}
var items_table: Dictionary = {}

# ⚠️ Utilisés par d'autres scripts via DataScore.stats_by_id / slots_by_id / items_by_id
var stats_by_id: Dictionary = {}
var leveling_by_id: Dictionary = {}
var slots_by_id: Dictionary = {}
var items_by_id: Dictionary = {}


func _ready() -> void:
	LOG.i("DATA", "🚀📚 DataRepo _ready() -> reload_all()")
	reload_all()


func reload_all() -> void:
	LOG.i("DATA", "🔄📦 reload_all() --- START ---")

	tables_cache.clear()
	stats_table = {}
	leveling_table = {}
	slots_table = {}
	items_table = {}

	stats_by_id = {}
	leveling_by_id = {}
	slots_by_id = {}
	items_by_id = {}

	_load_table("Stats_Economie")
	_load_table("Leveling")
	_load_table("Equipement_Slots")
	_load_table("Items_Equipements")

	LOG.ok("DATA", "✅📦 reload_all() --- DONE ---")

	# Petit résumé (DEBUG) : visible seulement si DEBUG_TAG_ALLOWLIST contient "DATA"
	LOG.d("DATA", "📌 Stats_Economie:%drows" % int(stats_by_id.size()))
	LOG.d("DATA", "📌 Leveling:%drows" % int(leveling_by_id.size()))
	LOG.d("DATA", "📌 Equipement_Slots:%drows" % int(slots_by_id.size()))
	LOG.d("DATA", "📌 Items_Equipements:%drows" % int(items_by_id.size()))


func _load_table(label: String) -> void:
	if not TABLES.has(label):
		LOG.e("DATA", "❌ Table inconnue: %s" % label)
		return

	var cfg: Dictionary = TABLES[label]
	var path: String = str(cfg.get("path", ""))
	var id_col: String = str(cfg.get("id_col", "ID"))

	LOG.i("DATA", "🟦 Chargement %s ->%s" % [label, path])

	var table: Dictionary = CSV.load_table(path, ";", id_col)

	# Appliquer schema si présent
	var schema: Dictionary = SCHEMAS.get_schema(label)
	if schema.size() > 0:
		table = CSV.apply_schema(table, schema, label)

	# Errors ?
	var errors: Array = table.get("errors", [])
	if errors.size() > 0:
		LOG.w("DATA", "⚠️ %s : %d erreur(s)" % [label, errors.size()])
		_print_errors(label, errors)
		return

	# Cache + alias "table" / "by_id"
	tables_cache[label] = table

	match label:
		"Stats_Economie":
			stats_table = table
			stats_by_id = table.get("by_id", {})
		"Leveling":
			leveling_table = table
			leveling_by_id = table.get("by_id", {})
		"Equipement_Slots":
			slots_table = table
			slots_by_id = table.get("by_id", {})
		"Items_Equipements":
			items_table = table
			items_by_id = table.get("by_id", {})
		_:
			pass

	LOG.ok("DATA", "✅🟢 %s: OK" % label)


func _print_errors(label: String, errors: Array) -> void:
	for e in errors:
		LOG.e("DATA", "%s | %s" % [label, str(e)])


# ---------------------------------------------------------
# ✅ Helpers (appelés depuis le reste du jeu via DataScore)
# ---------------------------------------------------------
func get_stat(id: String) -> Dictionary:
	return stats_by_id.get(id, {})


func get_level_rule(id: String) -> Dictionary:
	return leveling_by_id.get(id, {})


func get_slot(code: String) -> Dictionary:
	return slots_by_id.get(code, {})


func get_item(id: String) -> Dictionary:
	return items_by_id.get(id, {})


func get_table(label: String) -> Dictionary:
	return tables_cache.get(label, {})
