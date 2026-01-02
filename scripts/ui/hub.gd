# res://scripts/ui/hub.gd
# =========================================================
# 🏠 HUB UI (Phase 1 - fonctionnel + Equip popup)
# ---------------------------------------------------------
# Affiche gold/xp/level
# Affiche slots + item équipé
# Bouton Shop / Run
# + Equip : bouton par slot -> popup -> sélection item -> Game.equip_item()
# =========================================================
extends Control

const Log = preload("res://scripts/core/log.gd")

const SCENE_SHOP := "res://scenes/shop.tscn"

# --- Top stats
@onready var lbl_gold: Label = $Margin/VBox/TopStats/LabelGold
@onready var lbl_xp: Label = $Margin/VBox/TopStats/LabelXP
@onready var lbl_level: Label = $Margin/VBox/TopStats/LabelLevel

# --- Slots list (on remplit dynamiquement)
@onready var slots_list: VBoxContainer = $Margin/VBox/ScrollSlots/SlotsList

# --- Bottom buttons
@onready var btn_shop: Button = $Margin/VBox/BottomButtons/ButtonShop
@onready var btn_run: Button = $Margin/VBox/BottomButtons/ButtonRun

# --- Equip popup
@onready var equip_popup: PopupPanel = $EquipPopup
@onready var equip_title: Label = $EquipPopup/EquipMargin/EquipVBox/EquipTitle
@onready var equip_list: ItemList = $EquipPopup/EquipMargin/EquipVBox/EquipItemList
@onready var btn_cancel: Button = $EquipPopup/EquipMargin/EquipVBox/EquipButtons/ButtonCancel

var _equip_target_slot_code: String = ""
var _equip_target_slot_name: String = ""

func _ready() -> void:
	Log.i("UI", "HUB ready 🏠")

	# Petit log utile : prouve que tes achats sont bien dans l'inventaire
	Log.d("UI", "Owned items snapshot", {"count": Game.owned_items.size()})

	_connect_buttons()
	_connect_equip_popup()
	_refresh_all()

func _connect_buttons() -> void:
	if not btn_shop.pressed.is_connected(_on_shop_pressed):
		btn_shop.pressed.connect(_on_shop_pressed)
	if not btn_run.pressed.is_connected(_on_run_pressed):
		btn_run.pressed.connect(_on_run_pressed)

	Log.ok("UI", "Boutons connectés", {"shop": true, "run": true})

func _connect_equip_popup() -> void:
	# Double-clic / Entrée sur une ligne => équipe
	if not equip_list.item_activated.is_connected(_on_equip_item_activated):
		equip_list.item_activated.connect(_on_equip_item_activated)

	# Bouton fermer
	if not btn_cancel.pressed.is_connected(_on_equip_cancel_pressed):
		btn_cancel.pressed.connect(_on_equip_cancel_pressed)

	Log.ok("UI", "Equip popup connectée", {"item_activated": true, "cancel": true})

func _refresh_all() -> void:
	_refresh_top_stats()
	_refresh_slots()

func _refresh_top_stats() -> void:
	lbl_gold.text = "💰 Or : " + str(Game.gold)
	lbl_xp.text = "✨ XP : " + str(Game.xp)
	lbl_level.text = "🏅 Level : " + str(Game.level)

	Log.d("UI", "TopStats refresh", {"gold": Game.gold, "xp": Game.xp, "level": Game.level})

# ---------------------------------------------------------
# 🛡️ Slots + bouton Équiper (créé dynamiquement)
# ---------------------------------------------------------
func _refresh_slots() -> void:
	for c in slots_list.get_children():
		c.queue_free()

	# DataScore.slots_by_id = { "SWORD": {row}, "ARMOR": {row}, ... }
	if DataScore.slots_by_id.size() == 0:
		Log.w("DATA", "Aucun slot trouvé (equipement_slots.csv ?) ⚠️")
		return

	var slot_codes: Array[String] = _get_sorted_slot_codes()

	for code in slot_codes:
		var slot_row: Dictionary = DataScore.slots_by_id.get(code, {})
		var slot_name: String = str(slot_row.get("Slot", code)).strip_edges()

		# Item équipé sur ce slot
		var equipped_id: String = str(Game.equipped.get(code, "")).strip_edges()

		var equipped_name: String = "—"
		if equipped_id != "":
			var item: Dictionary = DataScore.get_item(equipped_id)
			equipped_name = "(introuvable)" if item.is_empty() else str(item.get("Nom", equipped_id))

		# UI row
		var row := HBoxContainer.new()
		row.name = "Row_" + code
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)

		var lbl_slot := Label.new()
		lbl_slot.text = "🧩 " + slot_name + " [" + code + "]"
		lbl_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var lbl_item := Label.new()
		lbl_item.text = "🛡️ " + equipped_name
		lbl_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn_equip := Button.new()
		btn_equip.text = "Équiper"
		btn_equip.custom_minimum_size = Vector2(110, 0)
		btn_equip.pressed.connect(Callable(self, "_on_equip_pressed").bind(code, slot_name))

		row.add_child(lbl_slot)
		row.add_child(lbl_item)
		row.add_child(btn_equip)

		slots_list.add_child(row)

	Log.ok("UI", "Slots refresh", {"count": slot_codes.size()})

func _get_sorted_slot_codes() -> Array[String]:
	var arr: Array[String] = []
	for k in DataScore.slots_by_id.keys():
		arr.append(str(k))
	arr.sort() # tri simple (SWORD, ARMOR, ...)
	return arr

# ---------------------------------------------------------
# 🛒 / ▶️ Buttons
# ---------------------------------------------------------
func _on_shop_pressed() -> void:
	Log.i("UI", "Go Shop 🛒", {"from": "HUB"})
	var err: Error = get_tree().change_scene_to_file(SCENE_SHOP)
	if err != OK:
		Log.e("UI", "change_scene_to_file failed", {"scene": SCENE_SHOP, "err": err})

func _on_run_pressed() -> void:
	Log.w("GAME", "RUN placeholder (pas encore implémenté) ▶️")

# ---------------------------------------------------------
# 🧩 Equip flow
# ---------------------------------------------------------
func _on_equip_pressed(slot_code: String, slot_name: String) -> void:
	_equip_target_slot_code = slot_code
	_equip_target_slot_name = slot_name

	Log.i("UI", "Open Equip popup 🧩", {"slot": slot_code})

	equip_title.text = "🧩 Équiper : " + slot_name + " [" + slot_code + "]"
	_fill_equip_list(slot_code)

	equip_popup.popup_centered()

func _fill_equip_list(slot_code: String) -> void:
	equip_list.clear()

	# Option : déséquiper
	equip_list.add_item("— Déséquiper (slot vide)")
	equip_list.set_item_metadata(0, "")

	var added: int = 0

	for item_id in DataScore.items_by_id.keys():
		var iid: String = str(item_id)

		# On ne propose que les items possédés
		if not Game.owns_item(iid):
			continue

		var item: Dictionary = DataScore.get_item(iid)
		if item.is_empty():
			continue

		# Slot de l'item
		var item_slot: String = str(item.get("Slot_Code", item.get("Slot", ""))).strip_edges()
		if item_slot != slot_code:
			continue

		var item_name: String = str(item.get("Nom", iid))
		var rare: String = str(item.get("Rareté", item.get("Rarete_Code", ""))).strip_edges()

		var line: String = item_name
		if rare != "":
			line += "  [" + rare + "]"

		var idx: int = equip_list.item_count
		equip_list.add_item(line)
		equip_list.set_item_metadata(idx, iid)

		added += 1

	Log.ok("UI", "Equip list filled", {"slot": slot_code, "count": added})

func _on_equip_item_activated(index: int) -> void:
	if _equip_target_slot_code == "":
		Log.w("UI", "Equip activate sans slot cible ⚠️")
		return

	var meta: Variant = equip_list.get_item_metadata(index)
	var item_id: String = str(meta).strip_edges()

	if item_id == "":
		Log.i("GAME", "Unequip slot", {"slot": _equip_target_slot_code})
		Game.equip_item(_equip_target_slot_code, "")
	else:
		Log.i("GAME", "Equip selected", {"slot": _equip_target_slot_code, "item_id": item_id})
		Game.equip_item(_equip_target_slot_code, item_id)

	equip_popup.hide()
	_refresh_all()

func _on_equip_cancel_pressed() -> void:
	Log.d("UI", "Equip popup cancel")
	equip_popup.hide()
