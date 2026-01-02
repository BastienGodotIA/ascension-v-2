# res://scripts/ui/hub.gd
# =========================================================
# 🏠 HUB UI (Phase 1 - fonctionnel)
# ---------------------------------------------------------
# Objectif :
# - Afficher Or / XP / Level
# - Lister les slots d'équipement + item équipé
# - Bouton "🛒 Boutique" (ouvre Shop.tscn)
# - Bouton "▶️ Run" (placeholder)
#
# Règles projet :
# - ✅ commentaires partout (pédagogique)
# - 🪵 logs emoji standard via Log.gd
# - Pas de déco / assets (phase 2)
# =========================================================
extends Control

# ---------------------------------------------------------
# 🪵 Logger standard (emoji + niveau + tag)
# ---------------------------------------------------------
const Log = preload("res://scripts/core/log.gd")

# ---------------------------------------------------------
# 📌 Chemins de scènes (transition simple)
# ---------------------------------------------------------
const SCENE_SHOP := "res://scenes/Shop.tscn"
# (RUN viendra plus tard) :
# const SCENE_RUN := "res://scenes/Run.tscn"

# ---------------------------------------------------------
# 🧷 Références UI (récupérées au _ready)
# ---------------------------------------------------------
@onready var lbl_gold: Label = $Margin/VBox/TopStats/LabelGold
@onready var lbl_xp: Label = $Margin/VBox/TopStats/LabelXP
@onready var lbl_level: Label = $Margin/VBox/TopStats/LabelLevel

@onready var slots_list: VBoxContainer = $Margin/VBox/ScrollSlots/SlotsList

@onready var btn_shop: Button = $Margin/VBox/BottomButtons/ButtonShop
@onready var btn_run: Button = $Margin/VBox/BottomButtons/ButtonRun

# ---------------------------------------------------------
# 🎬 READY
# ---------------------------------------------------------
func _ready() -> void:
	# Log d'arrivée scène
	Log.i("UI", "HUB ready 🏠")

	# Sécurité : si les datas ne sont pas chargées, on le signale.
	# (Normalement OK car DataScore est autoload et reload_all() au _ready)
	if DataScore.items_by_id.size() == 0:
		Log.w("DATA", "DataScore.items_by_id vide (import pas fait ?) ⚠️")

	# Connecte les boutons
	_connect_buttons()

	# Rafraîchit tout l'affichage
	_refresh_all()

# ---------------------------------------------------------
# 🔌 Connexions boutons
# ---------------------------------------------------------
func _connect_buttons() -> void:
	# 🛒 Boutique
	if not btn_shop.pressed.is_connected(_on_shop_pressed):
		btn_shop.pressed.connect(_on_shop_pressed)

	# ▶️ Run (placeholder)
	if not btn_run.pressed.is_connected(_on_run_pressed):
		btn_run.pressed.connect(_on_run_pressed)

	Log.ok("UI", "Boutons connectés", {"shop": true, "run": true})

# ---------------------------------------------------------
# 🔄 Refresh global (top stats + slots)
# ---------------------------------------------------------
func _refresh_all() -> void:
	_refresh_top_stats()
	_refresh_slots()

# ---------------------------------------------------------
# 💰 / ⭐ Top stats
# ---------------------------------------------------------
func _refresh_top_stats() -> void:
	# Mise à jour labels (format ultra simple)
	lbl_gold.text = "💰 Or : " + str(Game.gold)
	lbl_xp.text = "✨ XP : " + str(Game.xp)
	lbl_level.text = "🏅 Level : " + str(Game.level)

	Log.d("UI", "TopStats refresh", {"gold": Game.gold, "xp": Game.xp, "level": Game.level})

# ---------------------------------------------------------
# 🛡️ Slots d'équipement
# ---------------------------------------------------------
func _refresh_slots() -> void:
	# Nettoyage de la liste (on reconstruit pour rester simple)
	for c in slots_list.get_children():
		c.queue_free()

	# Si aucun slot : warning + stop
	if DataScore.slots_rows.size() == 0:
		Log.w("DATA", "Aucun slot trouvé (equipement_slots.csv ?) ⚠️")
		return

	# Pour chaque slot (ordre CSV) : afficher "Slot (CODE)" + item équipé
	for slot_row in DataScore.slots_rows:
		# Récup valeurs utiles
		var code: String = str(slot_row.get("Code", "")).strip_edges()
		var slot_name: String = str(slot_row.get("Slot", "")).strip_edges()

		# Sécurité
		if code == "":
			continue

		# ID item équipé (ou vide)
		var equipped_id: String = str(Game.equipped.get(code, "")).strip_edges()

		# Nom item équipé
		var equipped_name: String = "—"
		if equipped_id != "":
			var item: Dictionary = DataScore.get_item(equipped_id)
			if item.is_empty():
				equipped_name = "(introuvable)"
			else:
				equipped_name = str(item.get("Nom", equipped_id))

		# ---- UI row ----
		var row := HBoxContainer.new()
		row.name = "Row_" + code
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)

		# Label slot
		var lbl_slot := Label.new()
		lbl_slot.text = "🧩 " + slot_name + " [" + code + "]"
		lbl_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Label equipped
		var lbl_item := Label.new()
		lbl_item.text = "🛡️ " + equipped_name
		lbl_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Ajout dans la row
		row.add_child(lbl_slot)
		row.add_child(lbl_item)

		# Ajout à la liste
		slots_list.add_child(row)

	Log.ok("UI", "Slots refresh", {"count": DataScore.slots_rows.size()})

# ---------------------------------------------------------
# 🛒 Bouton Shop
# ---------------------------------------------------------
func _on_shop_pressed() -> void:
	Log.i("UI", "Go Shop 🛒", {"from": "HUB"})

	# Transition simple vers Shop.tscn
	var err: Error = get_tree().change_scene_to_file(SCENE_SHOP)
	if err != OK:
		Log.e("UI", "change_scene_to_file failed", {"scene": SCENE_SHOP, "err": err})

# ---------------------------------------------------------
# ▶️ Bouton RUN (placeholder)
# ---------------------------------------------------------
func _on_run_pressed() -> void:
	# Pas encore implémenté : on log, et on ne change pas de scène.
	Log.w("GAME", "RUN placeholder (pas encore implémenté) ▶️")

	# Future :
	# var err: Error = get_tree().change_scene_to_file(SCENE_RUN)
	# if err != OK:
	# 	Log.e("GAME", "Run scene load failed", {"scene": SCENE_RUN, "err": err})
