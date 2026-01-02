# res://scripts/game/game_state.gd
# =========================================================
# 🧠 GameState.gd (Autoload)
# ---------------------------------------------------------
# Objectif :
# - Stocker les données persistantes (entre runs)
# - Inventaire permanent (items achetés shop)
# - Equipement (par slot)
# - Calcul stats finales via StatsRuntime
# =========================================================
extends Node

const Log = preload("res://scripts/core/log.gd")
const StatsRuntime = preload("res://scripts/game/stats_runtime.gd")

# ---------------------------------------------------------
# 💰 Currencies / progression
# ---------------------------------------------------------
var gold: int = 0
var gems: int = 0

var xp: int = 0
var level: int = 1

# ---------------------------------------------------------
# 🎒 Inventaire / équipement
# - owned_items : dictionnaire { item_id: true }
# - equipped : { slot_code: item_id }
#   slot_code = ex: "SWORD", "ARMOR", "NECKLACE", ...
# ---------------------------------------------------------
var owned_items: Dictionary = {}
var equipped: Dictionary = {}

# ---------------------------------------------------------
# 📊 Cache stats (recalculé quand besoin)
# ---------------------------------------------------------
var _final_stats: Dictionary = {}
var _stats_dirty: bool = true

func _ready() -> void:
	Log.i("GAME", "GameState ready ✅")

	# Initialiser les slots (depuis equipement_slots.csv)
	_init_slots()

	# Exemple: donner un item de base si tu veux (optionnel)
	# grant_item("ITEM_SWORD_001")
	# equip_item("SWORD", "ITEM_SWORD_001")

	_recompute_stats_if_needed()

func _init_slots() -> void:
	Log.i("GAME", "Init slots depuis equipement_slots")

	# On initialise equipped avec tous les codes de slots connus
	for code in DataScore.slots_by_id.keys():
		if not equipped.has(code):
			equipped[code] = ""  # rien équipé au départ

	Log.ok("GAME", "Slots init", {"count": equipped.size()})

func mark_dirty_stats() -> void:
	_stats_dirty = true

func _recompute_stats_if_needed() -> void:
	if not _stats_dirty:
		return

	Log.i("GAME", "Recompute stats finales")
	_final_stats = StatsRuntime.compute_final_stats(equipped)
	_stats_dirty = false
	Log.ok("GAME", "Stats recalculées ✅", {"count": _final_stats.size()})

# ---------------------------------------------------------
# 🔎 Accès stats
# ---------------------------------------------------------
func get_stat(stat_id: String) -> float:
	_recompute_stats_if_needed()
	return float(_final_stats.get(stat_id, 0.0))

func get_all_stats() -> Dictionary:
	_recompute_stats_if_needed()
	return _final_stats

# ---------------------------------------------------------
# 🎒 Inventaire
# ---------------------------------------------------------
func grant_item(item_id: String) -> void:
	if item_id.strip_edges() == "":
		Log.w("GAME", "grant_item: item_id vide")
		return

	if owned_items.has(item_id):
		Log.d("GAME", "Item déjà possédé", {"item_id": item_id})
		return

	# Vérif que l’item existe en data
	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("GAME", "grant_item: item introuvable en data", {"item_id": item_id})
		return

	owned_items[item_id] = true
	Log.ok("GAME", "Item ajouté à l’inventaire 🎒", {"item_id": item_id})

func owns_item(item_id: String) -> bool:
	return owned_items.has(item_id)

# ---------------------------------------------------------
# 🛡️ Equipement
# ---------------------------------------------------------
func equip_item(slot_code: String, item_id: String) -> void:
	slot_code = slot_code.strip_edges()
	item_id = item_id.strip_edges()

	if slot_code == "":
		Log.w("GAME", "equip_item: slot_code vide")
		return

	if not equipped.has(slot_code):
		Log.e("GAME", "equip_item: slot inconnu", {"slot": slot_code})
		return

	if item_id == "":
		# déséquipe
		equipped[slot_code] = ""
		mark_dirty_stats()
		Log.ok("GAME", "Slot déséquipé", {"slot": slot_code})
		return

	# Vérif possession
	if not owns_item(item_id):
		Log.w("GAME", "equip_item: item non possédé", {"item_id": item_id})
		return

	# Vérif cohérence item -> slot
	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("GAME", "equip_item: item introuvable en data", {"item_id": item_id})
		return

	var item_slot_code: String = str(item.get("Slot_Code", item.get("Slot", ""))).strip_edges()
	if item_slot_code != "" and item_slot_code != slot_code:
		Log.w("GAME", "equip_item: slot mismatch", {
			"slot": slot_code,
			"item": item_id,
			"item_slot": item_slot_code
		})
		# On bloque pour éviter incohérence
		return

	equipped[slot_code] = item_id
	mark_dirty_stats()

	Log.ok("GAME", "Item équipé 🛡️", {"slot": slot_code, "item_id": item_id})

# ---------------------------------------------------------
# 🛒 Shop (simple)
# Plus tard : shop_amelioration.csv, rareté, refresh, etc.
# ---------------------------------------------------------
func try_buy_item(item_id: String) -> bool:
	item_id = item_id.strip_edges()
	if item_id == "":
		return false

	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("SHOP", "Buy: item introuvable", {"item_id": item_id})
		return false

	if owns_item(item_id):
		Log.w("SHOP", "Buy: déjà possédé", {"item_id": item_id})
		return false

	# Prix Or
	var price_or = item.get("Prix_Or", null)
	var price: int = 0
	if price_or != null:
		price = int(price_or)

	Log.i("SHOP", "Tentative achat", {"item_id": item_id, "price_or": price, "gold": gold})

	if gold < price:
		Log.w("SHOP", "Or insuffisant 💸", {"need": price, "have": gold})
		return false

	gold -= price
	grant_item(item_id)
	Log.ok("SHOP", "Achat OK 🛒", {"item_id": item_id, "gold_left": gold})

	return true
