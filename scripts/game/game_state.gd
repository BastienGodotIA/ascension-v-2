# res://scripts/game/game_state.gd
# =========================================================
# 🧠 GameState.gd (Autoload)
# ---------------------------------------------------------
# Rôle :
# - Stocke l'état du jeu (or/xp/level/inventaire/équipement)
# - Ne touche JAMAIS à l'UI (pas de NodePath $Margin/... ici)
# - Fournit des fonctions : try_buy_item(), equip_item(), etc.
# =========================================================
extends Node

const Log = preload("res://scripts/core/log.gd")
const StatsRuntime = preload("res://scripts/game/stats_runtime.gd")

# 💰 Currencies / progression
var gold: int = 0
var gems: int = 0
var xp: int = 0
var level: int = 1

# 🎒 Inventaire / équipement
var owned_items: Dictionary = {}   # { item_id: true }
var equipped: Dictionary = {}      # { slot_code: item_id }

# 📊 Cache stats
var _final_stats: Dictionary = {}
var _stats_dirty: bool = true

func _ready() -> void:
	Log.i("GAME", "GameState ready ✅")

	# 🎮 DEV ONLY : seed d'or pour tester la boutique tant que le RUN n'existe pas
	if OS.is_debug_build() and gold <= 0:
		gold = 999
		Log.w("GAME", "DEV seed gold injected 💰", {"gold": gold})

	_init_slots()
	_recompute_stats_if_needed()

# -------------------------
# 🧩 Slots init
# -------------------------
func _init_slots() -> void:
	Log.i("GAME", "Init slots depuis equipement_slots")

	if DataScore.slots_by_id.size() == 0:
		Log.w("DATA", "slots_by_id vide, init slots impossible ⚠️", {"count": 0})
		return

	for code in DataScore.slots_by_id.keys():
		if not equipped.has(code):
			equipped[code] = ""

	Log.ok("GAME", "Slots init", {"count": equipped.size()})

# -------------------------
# 📊 Stats runtime
# -------------------------
func mark_dirty_stats() -> void:
	_stats_dirty = true

func _recompute_stats_if_needed() -> void:
	if not _stats_dirty:
		return

	Log.i("GAME", "Recompute stats finales")
	_final_stats = StatsRuntime.compute_final_stats(equipped)
	_stats_dirty = false
	Log.ok("GAME", "Stats recalculées ✅", {"count": _final_stats.size()})

func get_stat(stat_id: String) -> float:
	_recompute_stats_if_needed()
	return float(_final_stats.get(stat_id, 0.0))

func get_all_stats() -> Dictionary:
	_recompute_stats_if_needed()
	return _final_stats

# -------------------------
# 🎒 Inventaire
# -------------------------
func grant_item(item_id: String) -> void:
	item_id = item_id.strip_edges()
	if item_id == "":
		Log.w("GAME", "grant_item: item_id vide")
		return

	if owned_items.has(item_id):
		Log.d("GAME", "Item déjà possédé", {"item_id": item_id})
		return

	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("GAME", "grant_item: item introuvable en data", {"item_id": item_id})
		return

	owned_items[item_id] = true
	Log.ok("GAME", "Item ajouté à l’inventaire 🎒", {"item_id": item_id})

func owns_item(item_id: String) -> bool:
	return owned_items.has(item_id.strip_edges())

# -------------------------
# 🛡️ Equipement
# -------------------------
func equip_item(slot_code: String, item_id: String) -> void:
	slot_code = slot_code.strip_edges()
	item_id = item_id.strip_edges()

	if slot_code == "":
		Log.w("GAME", "equip_item: slot_code vide")
		return

	if not equipped.has(slot_code):
		Log.e("GAME", "equip_item: slot inconnu", {"slot": slot_code})
		return

	# Déséquiper
	if item_id == "":
		equipped[slot_code] = ""
		mark_dirty_stats()
		Log.ok("GAME", "Slot déséquipé", {"slot": slot_code})
		return

	if not owns_item(item_id):
		Log.w("GAME", "equip_item: item non possédé", {"item_id": item_id})
		return

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
		return

	equipped[slot_code] = item_id
	mark_dirty_stats()
	Log.ok("GAME", "Item équipé 🛡️", {"slot": slot_code, "item_id": item_id})

# -------------------------
# 🛒 Shop V1
# -------------------------
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
# -------------------------
# 🎁 Rewards (RUN placeholder)
# -------------------------
func add_gold(amount: int, reason: String = "") -> void:
	var before: int = gold
	gold += max(0, amount)
	Log.ok("GAME", "Gold added 💰", {"amount": amount, "before": before, "after": gold, "reason": reason})

func add_xp(amount: int, reason: String = "") -> void:
	var before: int = xp
	xp += max(0, amount)
	Log.ok("GAME", "XP added ✨", {"amount": amount, "before": before, "after": xp, "reason": reason})

	# Placeholder leveling (simple, on fera mieux plus tard)
	# Ici on level up tous les 100 XP pour tester l'affichage.
	while xp >= 100:
		xp -= 100
		level += 1
		Log.ok("GAME", "Level UP 🏅", {"level": level, "xp_left": xp})
