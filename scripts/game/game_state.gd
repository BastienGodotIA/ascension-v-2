# res://scripts/game/game_state.gd
# =========================================================
# 🧠 GameState.gd (Autoload)
# ---------------------------------------------------------
# Rôle (important à comprendre) :
# - C'est la "mémoire du jeu" entre les scènes (HUB / SHOP / RUN).
# - Il stocke : or, gems, xp, level, inventaire permanent, équipement.
# - Il déclenche le recalcul des stats finales via StatsRuntime.
#
# Pourquoi en Autoload ?
# - Parce que tu veux garder ces infos même quand tu changes de scène.
#   (HUB -> SHOP -> HUB -> RUN, etc.)
# =========================================================
extends Node

# ---------------------------------------------------------
# 🪵 Logger standard (format emoji / niveaux / tags)
# ---------------------------------------------------------
const Log = preload("res://scripts/core/log.gd")

# ---------------------------------------------------------
# 📊 Calculateur de stats (base + bonus équipement)
# - C'est un script avec fonctions "static"
# ---------------------------------------------------------
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
#   => simple : si la clé existe, tu possèdes l'item.
#
# - equipped : { slot_code: item_id }
#   slot_code = "SWORD", "ARMOR", "NECKLACE", ...
#   item_id = "ITEM_SWORD_001", ...
# ---------------------------------------------------------
var owned_items: Dictionary = {}
var equipped: Dictionary = {}

# ---------------------------------------------------------
# 📊 Cache stats (recalculé seulement quand besoin)
# - _stats_dirty = true => il faut recalculer
# - _final_stats contient le résultat (float par stat_id)
# ---------------------------------------------------------
var _final_stats: Dictionary = {}
var _stats_dirty: bool = true

# =========================================================
# 🎬 Lifecycle
# =========================================================
func _ready() -> void:
	# 🚀 Ce log prouve que l'autoload est bien vivant
	Log.i("GAME", "GameState ready ✅")

	# -----------------------------------------------------
	# 🎮 DEV ONLY : seed d'or pour tester la boutique
	# -----------------------------------------------------
	# Problème : tant que RUN n'existe pas, tu ne gagnes pas d'or,
	# donc tu ne peux pas tester la boutique.
	#
	# Solution : en mode debug (éditeur), si gold est à 0,
	# on met 999 pour pouvoir acheter.
	#
	# Sécurité :
	# - OS.is_debug_build() => uniquement quand tu lances depuis l'éditeur
	# - gold <= 0 => n'écrase pas une future progression / sauvegarde
	if OS.is_debug_build() and gold <= 0:
		gold = 999
		Log.w("GAME", "DEV seed gold injected 💰", {"gold": gold})

	# -----------------------------------------------------
	# 🧩 Init des slots d'équipement
	# -----------------------------------------------------
	_init_slots()

	# -----------------------------------------------------
	# 📊 Recalcul initial des stats finales
	# -----------------------------------------------------
	_recompute_stats_if_needed()

# =========================================================
# 🧩 Slots / Equipment init
# =========================================================
func _init_slots() -> void:
	# Rôle :
	# - Préparer "equipped" avec tous les slots connus depuis le CSV
	# - Comme ça, l'UI peut afficher tous les slots même si vide.
	Log.i("GAME", "Init slots depuis equipement_slots")

	# Sécurité : si DataScore n'a pas de slots, on log et on stop.
	if DataScore.slots_by_id.size() == 0:
		Log.w("DATA", "slots_by_id vide, init slots impossible ⚠️", {"count": 0})
		return

	# On initialise equipped avec tous les codes de slots connus
	for code in DataScore.slots_by_id.keys():
		if not equipped.has(code):
			equipped[code] = ""  # rien équipé au départ

	Log.ok("GAME", "Slots init", {"count": equipped.size()})

# =========================================================
# 📊 Stats runtime (dirty flag)
# =========================================================
func mark_dirty_stats() -> void:
	# Rôle :
	# - Dire "les stats ne sont plus à jour"
	# - Ex : quand tu équipes un item, tes stats changent.
	_stats_dirty = true

func _recompute_stats_if_needed() -> void:
	# Si rien n'a changé, on ne recalcule pas (gain perf + logs propres)
	if not _stats_dirty:
		return

	# Log clair : on sait quand un recalcul arrive
	Log.i("GAME", "Recompute stats finales")

	# StatsRuntime lit DataScore et utilise equipped
	_final_stats = StatsRuntime.compute_final_stats(equipped)

	_stats_dirty = false
	Log.ok("GAME", "Stats recalculées ✅", {"count": _final_stats.size()})

# =========================================================
# 🔎 Accès stats (API simple pour le reste du jeu)
# =========================================================
func get_stat(stat_id: String) -> float:
	# Assure que les stats sont à jour
	_recompute_stats_if_needed()

	# Retour par défaut : 0.0 si stat absente
	return float(_final_stats.get(stat_id, 0.0))

func get_all_stats() -> Dictionary:
	# Assure que les stats sont à jour
	_recompute_stats_if_needed()
	return _final_stats

# =========================================================
# 🎒 Inventaire
# =========================================================
func grant_item(item_id: String) -> void:
	item_id = item_id.strip_edges()

	if item_id == "":
		Log.w("GAME", "grant_item: item_id vide")
		return

	# Déjà possédé => on ne fait rien
	if owned_items.has(item_id):
		Log.d("GAME", "Item déjà possédé", {"item_id": item_id})
		return

	# Vérif que l’item existe en data (sécurité)
	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("GAME", "grant_item: item introuvable en data", {"item_id": item_id})
		return

	owned_items[item_id] = true
	Log.ok("GAME", "Item ajouté à l’inventaire 🎒", {"item_id": item_id})

func owns_item(item_id: String) -> bool:
	item_id = item_id.strip_edges()
	return owned_items.has(item_id)

# =========================================================
# 🛡️ Equipement
# =========================================================
func equip_item(slot_code: String, item_id: String) -> void:
	slot_code = slot_code.strip_edges()
	item_id = item_id.strip_edges()

	if slot_code == "":
		Log.w("GAME", "equip_item: slot_code vide")
		return

	# Vérif que le slot existe
	if not equipped.has(slot_code):
		Log.e("GAME", "equip_item: slot inconnu", {"slot": slot_code})
		return

	# Si item_id vide => déséquipage
	if item_id == "":
		equipped[slot_code] = ""
		mark_dirty_stats()
		Log.ok("GAME", "Slot déséquipé", {"slot": slot_code})
		return

	# Vérif possession
	if not owns_item(item_id):
		Log.w("GAME", "equip_item: item non possédé", {"item_id": item_id})
		return

	# Vérif que l’item existe
	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("GAME", "equip_item: item introuvable en data", {"item_id": item_id})
		return

	# Vérif cohérence item -> slot
	# On lit Slot_Code (préféré), sinon Slot (fallback)
	var item_slot_code: String = str(item.get("Slot_Code", item.get("Slot", ""))).strip_edges()
	if item_slot_code != "" and item_slot_code != slot_code:
		Log.w("GAME", "equip_item: slot mismatch", {
			"slot": slot_code,
			"item": item_id,
			"item_slot": item_slot_code
		})
		return

	# Equip
	equipped[slot_code] = item_id
	mark_dirty_stats()

	Log.ok("GAME", "Item équipé 🛡️", {"slot": slot_code, "item_id": item_id})

# =========================================================
# 🛒 Shop (simple V1)
# =========================================================
func try_buy_item(item_id: String) -> bool:
	item_id = item_id.strip_edges()
	if item_id == "":
		return false

	# Récup data item
	var item: Dictionary = DataScore.get_item(item_id)
	if item.is_empty():
		Log.e("SHOP", "Buy: item introuvable", {"item_id": item_id})
		return false

	# Déjà possédé
	if owns_item(item_id):
		Log.w("SHOP", "Buy: déjà possédé", {"item_id": item_id})
		return false

	# Prix Or (si vide => 0)
	var price_or = item.get("Prix_Or", null)
	var price: int = 0
	if price_or != null:
		price = int(price_or)

	Log.i("SHOP", "Tentative achat", {"item_id": item_id, "price_or": price, "gold": gold})

	# Pas assez d'or
	if gold < price:
		Log.w("SHOP", "Or insuffisant 💸", {"need": price, "have": gold})
		return false

	# Paiement + ajout inventaire
	gold -= price
	grant_item(item_id)

	Log.ok("SHOP", "Achat OK 🛒", {"item_id": item_id, "gold_left": gold})
	return true
