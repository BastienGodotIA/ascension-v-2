extends Control

const Log = preload("res://scripts/core/log.gd")
const SCENE_HUB: String = "res://scenes/hub.tscn"

# --- UI
@onready var lbl_timer: Label = get_node_or_null("Margin/VBox/LabelTimer") as Label
@onready var lbl_rewards: Label = get_node_or_null("Margin/VBox/LabelRewards") as Label
@onready var btn_end_run: Button = get_node_or_null("Margin/VBox/ButtonEndRun") as Button
@onready var btn_back_hub: Button = get_node_or_null("Margin/VBox/ButtonBackHub") as Button

# --- Timer node
@onready var run_timer: Timer = get_node_or_null("RunTimer") as Timer

# --- Config RUN placeholder
var run_duration_sec: int = 10
var time_left: int = 10

var reward_gold: int = 120
var reward_xp: int = 35

var _ended: bool = false

func _ready() -> void:
	Log.i("RUN", "Run ready ▶️ (v1.3 placeholder)")

	# Sanity checks nodes
	Log.d("RUN", "Nodes check", {
		"lbl_timer": lbl_timer != null,
		"lbl_rewards": lbl_rewards != null,
		"btn_end": btn_end_run != null,
		"btn_back": btn_back_hub != null,
		"timer": run_timer != null
	})

	_connect_buttons()
	_setup_timer()
	_start_run()

func _connect_buttons() -> void:
	if btn_end_run == null:
		Log.e("RUN", "Node manquant ❌", {"path": "Margin/VBox/ButtonEndRun"})
	else:
		if not btn_end_run.pressed.is_connected(_on_end_run_pressed):
			btn_end_run.pressed.connect(_on_end_run_pressed)
		Log.ok("RUN", "ButtonEndRun connecté ✅", {"text": btn_end_run.text})

	if btn_back_hub == null:
		Log.e("RUN", "Node manquant ❌", {"path": "Margin/VBox/ButtonBackHub"})
	else:
		if not btn_back_hub.pressed.is_connected(_on_back_hub_pressed):
			btn_back_hub.pressed.connect(_on_back_hub_pressed)
		Log.ok("RUN", "ButtonBackHub connecté ✅", {"text": btn_back_hub.text})

func _setup_timer() -> void:
	if run_timer == null:
		Log.e("RUN", "RunTimer manquant ❌", {"expected": "RunTimer (Timer)"})
		return

	# On force nos valeurs, même si l'inspector diffère
	run_timer.wait_time = 1.0
	run_timer.one_shot = false
	run_timer.autostart = false

	if not run_timer.timeout.is_connected(_on_timer_tick):
		run_timer.timeout.connect(_on_timer_tick)

	Log.ok("RUN", "Timer prêt ✅", {"wait": run_timer.wait_time, "one_shot": run_timer.one_shot})

func _start_run() -> void:
	_ended = false
	time_left = run_duration_sec

	_refresh_ui_full()

	Log.i("RUN", "RUN START 🚀", {
		"duration_sec": run_duration_sec,
		"reward_gold": reward_gold,
		"reward_xp": reward_xp
	})

	if run_timer != null:
		run_timer.start()
		Log.ok("RUN", "Timer started ⏱️", {"time_left": time_left})

func _on_timer_tick() -> void:
	if _ended:
		return

	time_left -= 1
	_refresh_timer_only()

	# Log à chaque tick = max 10 logs si duration=10s (anti-spam OK)
	Log.d("RUN", "Tick ⏱️", {"time_left": time_left})

	if time_left <= 0:
		Log.i("RUN", "RUN END (timer) 🏁")
		_end_run_and_return("timer_end")

func _on_end_run_pressed() -> void:
	if _ended:
		Log.w("RUN", "EndRun press ignoré (déjà fini) ⚠️")
		return

	Log.i("RUN", "Fin de run manuelle 🏁")
	_end_run_and_return("manual_end")

func _on_back_hub_pressed() -> void:
	# Retour debug, sans récompenses (utile en dev)
	Log.w("RUN", "Retour HUB debug (sans rewards) ↩️")
	_go_hub("debug_back_no_rewards")

func _end_run_and_return(reason: String) -> void:
	_ended = true

	if run_timer != null:
		run_timer.stop()
		Log.ok("RUN", "Timer stopped ✅", {"reason": reason})

	# Rewards : centralisées dans GameState
	Log.i("RUN", "Rewards apply 🎁", {"gold": reward_gold, "xp": reward_xp, "reason": reason})
	Game.add_gold(reward_gold, "run_" + reason)
	Game.add_xp(reward_xp, "run_" + reason)

	Log.ok("RUN", "Rewards applied ✅", {"gold_now": Game.gold, "xp_now": Game.xp, "level_now": Game.level})

	_go_hub("end_" + reason)

func _go_hub(reason: String) -> void:
	Log.i("RUN", "Go HUB 🏠", {"reason": reason, "scene": SCENE_HUB})
	var err: Error = get_tree().change_scene_to_file(SCENE_HUB)
	if err != OK:
		Log.e("RUN", "change_scene_to_file failed", {"scene": SCENE_HUB, "err": err})

func _refresh_ui_full() -> void:
	_refresh_timer_only()
	if lbl_rewards != null:
		lbl_rewards.text = "🎁 Récompenses : +" + str(reward_gold) + " or, +" + str(reward_xp) + " XP"

func _refresh_timer_only() -> void:
	if lbl_timer != null:
		lbl_timer.text = "⏱️ Temps : " + str(max(0, time_left)) + "s"
