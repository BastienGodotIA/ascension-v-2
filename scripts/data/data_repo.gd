# =========================================================
# 🧠 DATA REPO (autoload)
# ---------------------------------------------------------
# Rôle :
#  - Charger toutes les tables CSV dans la RAM
#  - Fournir accès rapide par ID
#  - Afficher des logs très clairs (emoji + détails)
#
# Tu l'ajoutes dans :
#  Project Settings -> Autoload
#  Name : DataScore (ou Data, comme tu veux)
#  Path : res://scripts/data/data_repo.gd
# =========================================================
extends Node

# 📦 preloads : on évite les class_name pour éviter conflits / cache
const CSVLoader = preload("res://scripts/data/csv_loader.gd")
const DataSchemas = preload("res://scripts/data/data_schemas.gd")

# Dossier d'export (pratique)
const EXPORT_DIR := "res://data/export/"

# ---------------------------------------------------------
# ✅ Tables chargées
# ---------------------------------------------------------
var stats_rows: Array = []
var stats_by_id: Dictionary = {}

var leveling_rows: Array = []
var leveling_by_id: Dictionary = {}

var slots_rows: Array = []
var slots_by_id: Dictionary = {} # clé = Code (copié aussi en ID)

var items_rows: Array = []
var items_by_id: Dictionary = {}


# ---------------------------------------------------------
# 🎬 Au lancement : on charge tout
# ---------------------------------------------------------
func _ready() -> void:
	print("🚀📚 [DATA] DataRepo _ready() -> reload_all()")
	reload_all()


# ---------------------------------------------------------
# 🔄 Recharger toutes les tables (pratique si tu changes un CSV)
# ---------------------------------------------------------
func reload_all() -> void:
	print("🔄📦 [DATA] reload_all() --- START ---")

	_load_stats_economie()
	_load_leveling()
	_load_equipement_slots()
	_load_items_equipements()

	print("✅📦 [DATA] reload_all() --- DONE ---")
	print("📌 [DATA] Stats_Economie:", stats_by_id.size(), "rows")
	print("📌 [DATA] Leveling:", leveling_by_id.size(), "rows")
	print("📌 [DATA] Equipement_Slots:", slots_by_id.size(), "rows")
	print("📌 [DATA] Items_Equipements:", items_by_id.size(), "rows")


# ---------------------------------------------------------
# 🧭 Helper : choisir un fichier existant (cas Windows/Linux)
# - sur Windows, la casse est tolérée
# - sur Linux, il faut la bonne casse
# -> on tente plusieurs noms possibles
# ---------------------------------------------------------
func _pick_existing(candidates: Array[String]) -> String:
	for p in candidates:
		if FileAccess.file_exists(p):
			return p
	return ""


# ---------------------------------------------------------
# 📌 Charger stats_economie
# ---------------------------------------------------------
func _load_stats_economie() -> void:
	var path := EXPORT_DIR + "stats_economie.csv"
	print("🟦 [DATA] Chargement Stats_Economie ->", path)

	var t: Dictionary = CSVLoader.load_table(path, ";", "ID")
	t = CSVLoader.apply_schema(t, DataSchemas.STATS_ECONOMIE, "Stats_Economie")

	stats_rows = t["rows"]
	stats_by_id = t["by_id"]

	_print_errors_if_any("Stats_Economie", t)


# ---------------------------------------------------------
# 📌 Charger leveling
# ---------------------------------------------------------
func _load_leveling() -> void:
	var path := EXPORT_DIR + "leveling.csv"
	print("🟦 [DATA] Chargement Leveling ->", path)

	var t: Dictionary = CSVLoader.load_table(path, ";", "ID")
	t = CSVLoader.apply_schema(t, DataSchemas.LEVELING, "Leveling")

	leveling_rows = t["rows"]
	leveling_by_id = t["by_id"]

	_print_errors_if_any("Leveling", t)


# ---------------------------------------------------------
# 📌 Charger equipement_slots (clé = Code)
# ---------------------------------------------------------
func _load_equipement_slots() -> void:
	# On tente 2 noms possibles (au cas où)
	var path := _pick_existing([
		EXPORT_DIR + "equipement_slots.csv",
		EXPORT_DIR + "Equipement_Slots.csv"
	])

	print("🟦 [DATA] Chargement Equipement_Slots ->", path)

	if path == "":
		push_warning("⚠️ [DATA] equipement_slots.csv introuvable dans data/export/")
		slots_rows = []
		slots_by_id = {}
		return

	# 🔑 id_col = "Code"
	var t: Dictionary = CSVLoader.load_table(path, ";", "Code")
	t = CSVLoader.apply_schema(t, DataSchemas.EQUIPEMENT_SLOTS, "Equipement_Slots")

	slots_rows = t["rows"]
	slots_by_id = t["by_id"]

	_print_errors_if_any("Equipement_Slots", t)


# ---------------------------------------------------------
# 📌 Charger items_equipements (ID)
# ---------------------------------------------------------
func _load_items_equipements() -> void:
	# Plusieurs noms possibles selon export
	var path := _pick_existing([
		EXPORT_DIR + "items_equipements.csv",
		EXPORT_DIR + "Items_Equipements.csv"
	])

	print("🟦 [DATA] Chargement Items_Equipements ->", path)

	if path == "":
		push_warning("⚠️ [DATA] items_equipements.csv introuvable dans data/export/")
		items_rows = []
		items_by_id = {}
		return

	var t: Dictionary = CSVLoader.load_table(path, ";", "ID")
	t = CSVLoader.apply_schema(t, DataSchemas.ITEMS_EQUIPEMENTS, "Items_Equipements")

	items_rows = t["rows"]
	items_by_id = t["by_id"]

	_print_errors_if_any("Items_Equipements", t)


# ---------------------------------------------------------
# 🧯 Afficher les erreurs (si présentes)
# ---------------------------------------------------------
func _print_errors_if_any(label: String, t: Dictionary) -> void:
	var errs: Array = t.get("errors", [])
	if errs.size() > 0:
		push_warning("⚠️📛 [DATA] %s: %d erreur(s) (voir Output)" % [label, errs.size()])
		for e in errs:
			print("📛 [DATA][ERR] ", e)
	else:
		print("✅🟢 [DATA] %s: OK" % label)


# ---------------------------------------------------------
# 🔎 Helpers d'accès (pour ton futur gameplay)
# ---------------------------------------------------------
func get_stat(id: String) -> Dictionary:
	return stats_by_id.get(id, {})

func get_level_rule(id: String) -> Dictionary:
	return leveling_by_id.get(id, {})

func get_slot(code: String) -> Dictionary:
	# code = ex: "SLOT_WEAPON"
	return slots_by_id.get(code, {})

func get_item(id: String) -> Dictionary:
	return items_by_id.get(id, {})
