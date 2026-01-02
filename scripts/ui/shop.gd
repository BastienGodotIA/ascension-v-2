# res://scripts/ui/shop.gd
# =========================================================
# 🛒 SHOP UI (Phase 1 - fonctionnel)
# ---------------------------------------------------------
# Objectif :
# - Lister les items (depuis DataScore.items_by_id)
# - Afficher Nom / Rareté / Prix (Or)
# - Bouton "Acheter" -> Game.try_buy_item(item_id)
# - Bouton "Retour HUB"
#
# Règles projet :
# - ✅ commentaires partout (pédagogique)
# - 🪵 logs emoji standard via Log.gd
# - Pas de déco / assets (phase 2)
# =========================================================
extends Control

const Log = preload("res://scripts/core/log.gd")
const SCENE_HUB := "res://scenes/HUB.tscn"

@onready var lbl_gold: Label = $Margin/VBox/TopBar/LabelGold
@onready var items_list: VBoxContainer = $Margin/VBox/ScrollItems/ItemsList
@onready var btn_back: Button = $Margin/VBox/BottomButtons/ButtonBack

# Cache des lignes pour refresh ciblé
var _row_cache: Dictionary = {} # { item_id: {"row":HBoxContainer,"btn":Button,"status":Label,"price":int} }

func _ready() -> void:
	Log.i("SHOP", "Shop ready 🛒")

	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)

	_build_items_list()
	_refresh_all_rows()
	_refresh_top_bar()

func _refresh_top_bar() -> void:
	lbl_gold.text = "💰 Or : " + str(Game.gold)
	Log.d("SHOP", "TopBar refresh", {"gold": Game.gold})

func _build_items_list() -> void:
	for c in items_list.get_children():
		c.queue_free()
	_row_cache.clear()

	if DataScore.items_by_id.size() == 0:
		Log.w("DATA", "Aucun item en data (items_equipements.csv ?) ⚠️")
		return

	var ids: Array[String] = _get_sorted_item_ids()

	for item_id in ids:
		var item: Dictionary = DataScore.get_item(item_id)
		if item.is_empty():
			continue

		var item_name: String = str(item.get("Nom", item_id))
		
		var rarete: String = str(item.get("Rareté", "?"))
		var price: int = _get_item_price_or(item)

		var row := HBoxContainer.new()
		row.name = "Row_" + item_id
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)

		var lbl_name := Label.new()
		lbl_name.text = item_name
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl_rarete := Label.new()
		lbl_rarete.text = "✨ " + rarete
		lbl_rarete.custom_minimum_size = Vector2(140, 0)

		var lbl_price := Label.new()
		lbl_price.text = "💰 " + str(price)
		lbl_price.custom_minimum_size = Vector2(90, 0)

		var lbl_status := Label.new()
		lbl_status.text = "—"
		lbl_status.custom_minimum_size = Vector2(70, 0)

		var btn_buy := Button.new()
		btn_buy.text = "Acheter"
		btn_buy.custom_minimum_size = Vector2(110, 0)
		btn_buy.pressed.connect(Callable(self, "_on_buy_pressed").bind(item_id))

		row.add_child(lbl_name)
		row.add_child(lbl_rarete)
		row.add_child(lbl_price)
		row.add_child(lbl_status)
		row.add_child(btn_buy)

		items_list.add_child(row)

		_row_cache[item_id] = {
			"row": row,
			"btn": btn_buy,
			"status": lbl_status,
			"price": price,
		}

	Log.ok("SHOP", "Items list built", {"count": ids.size()})

func _get_item_price_or(item: Dictionary) -> int:
	var raw = item.get("Prix_Or", null)
	if raw == null:
		return 0

	var s: String = str(raw).strip_edges()
	if s == "":
		return 0

	return int(raw)

func _get_sorted_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in DataScore.items_by_id.keys():
		ids.append(str(k))

	var r_rank: Dictionary = {
		"COMMON": 0,
		"RARE": 1,
		"EPIC": 2,
		"LEGENDARY": 3,
	}

	ids.sort_custom(func(a: String, b: String) -> bool:
		var ia: Dictionary = DataScore.get_item(a)
		var ib: Dictionary = DataScore.get_item(b)

		var slot_a: String = str(ia.get("Slot_Code", ia.get("Slot", "")))
		var slot_b: String = str(ib.get("Slot_Code", ib.get("Slot", "")))

		var ra: String = str(ia.get("Rarete_Code", ia.get("Rareté", "")))
		var rb: String = str(ib.get("Rarete_Code", ib.get("Rareté", "")))

		var rank_a: int = int(r_rank.get(ra, 99))
		var rank_b: int = int(r_rank.get(rb, 99))

		var pa: int = _get_item_price_or(ia)
		var pb: int = _get_item_price_or(ib)

		if slot_a != slot_b:
			return slot_a < slot_b
		if rank_a != rank_b:
			return rank_a < rank_b
		if pa != pb:
			return pa < pb
		return a < b
	)

	return ids

func _refresh_row(item_id: String) -> void:
	if not _row_cache.has(item_id):
		return

	var entry: Dictionary = _row_cache[item_id]
	var btn: Button = entry.get("btn", null)
	var lbl_status: Label = entry.get("status", null)
	var price: int = int(entry.get("price", 0))

	if btn == null or lbl_status == null:
		return

	var owned: bool = Game.owns_item(item_id)

	if owned:
		btn.disabled = true
		lbl_status.text = "✅"
		return

	if Game.gold < price:
		btn.disabled = true
		lbl_status.text = "💸"
		return

	btn.disabled = false
	lbl_status.text = "—"

func _refresh_all_rows() -> void:
	for item_id in _row_cache.keys():
		_refresh_row(str(item_id))
	Log.d("SHOP", "Rows refresh", {"count": _row_cache.size()})

func _on_buy_pressed(item_id: String) -> void:
	var item: Dictionary = DataScore.get_item(item_id)
	Log.i("SHOP", "Buy pressed", {"item_id": item_id, "name": str(item.get("Nom", "?"))})

	var ok_buy: bool = Game.try_buy_item(item_id)

	_refresh_top_bar()
	_refresh_row(item_id)

	if ok_buy:
		Log.ok("SHOP", "Achat OK (UI refresh) ✅", {"item_id": item_id, "gold": Game.gold})
	else:
		Log.w("SHOP", "Achat refusé (voir logs GameState) ⚠️", {"item_id": item_id, "gold": Game.gold})

func _on_back_pressed() -> void:
	Log.i("UI", "Retour HUB", {"from": "SHOP"})

	var err: Error = get_tree().change_scene_to_file(SCENE_HUB)
	if err != OK:
		Log.e("UI", "change_scene_to_file failed", {"scene": SCENE_HUB, "err": err})
