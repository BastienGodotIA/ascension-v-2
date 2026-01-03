extends Control

const SCENE_HUB: String = "res://scenes/hub.tscn"

# Permet de déplacer facilement le spawner dans l’arborescence sans casser le script
@export var spawner_path: NodePath = NodePath("World/EnemySpawner")

# --- UI (RUN)
@onready var lbl_timer: Label = get_node_or_null("Margin/VBox/LabelTimer") as Label
@onready var lbl_rewards: Label = get_node_or_null("Margin/VBox/LabelRewards") as Label
@onready var lbl_wave: Label = get_node_or_null("Margin/VBox/LabelWave") as Label
@onready var lbl_kills: Label = get_node_or_null("Margin/VBox/LabelKills") as Label
@onready var lbl_run_earnings: Label = get_node_or_null("Margin/VBox/LabelRunEarnings") as Label

@onready var btn_sim_kill: Button = get_node_or_null("Margin/VBox/ButtonSimKill") as Button
@onready var btn_end_run: Button = get_node_or_null("Margin/VBox/ButtonEndRun") as Button
@onready var btn_back_hub: Button = get_node_or_null("Margin/VBox/ButtonBackHub") as Button

# --- Timer run
@onready var run_timer: Timer = get_node_or_null("RunTimer") as Timer

# --- Spawner
@onready var spawner: EnemySpawner = get_node_or_null(spawner_path) as EnemySpawner

# --- End screen
@onready var end_panel: PanelContainer = get_node_or_null("EndPanel") as PanelContainer
@onready var end_summary: Label = get_node_or_null("EndPanel/EndMargin/EndVBox/EndSummary") as Label
@onready var btn_back_hub_end: Button = get_node_or_null("EndPanel/EndMargin/EndVBox/EndButtons/ButtonBackHubEnd") as Button
@onready var btn_restart_run: Button = get_node_or_null("EndPanel/EndMargin/EndVBox/EndButtons/ButtonRestartRun") as Button

# =========================================================
# CONFIG RUN
# =========================================================
var run_duration_sec: int = 12
var kills_per_wave: int = 5

# Bonus fin (coffre) dépendant de la vague atteinte
var end_bonus_gold_per_wave: int = 15
var end_bonus_xp_per_wave: int = 5

# =========================================================
# STATE RUN
# =========================================================
var time_left: int = 0
var wave_level: int = 1
var kills: int = 0

# Gains "en run"
var run_gold_earned: int = 0
var run_xp_earned: int = 0

# Snapshot départ (debug)
var start_gold: int = 0
var start_xp: int = 0
var start_level: int = 1

var _ended: bool = false
var _bank_applied: bool = false

func _ready() -> void:
	Log.i("RUN", "Run ready ▶️ (v1.8)")

	Log.d("RUN", "Nodes check", {
		"lbl_timer": lbl_timer != null,
		"lbl_rewards": lbl_rewards != null,
		"lbl_wave": lbl_wave != null,
		"lbl_kills": lbl_kills != null,
		"lbl_run_earnings": lbl_run_earnings != null,
		"btn_sim_kill": btn_sim_kill != null,
		"btn_end": btn_end_run != null,
		"btn_back": btn_back_hub != null,
		"run_timer": run_timer != null,
		"spawner": spawner != null,
		"spawner_path": str(spawner_path),
		"end_panel": end_panel != null,
		"end_summary": end_summary != null,
		"end_back": btn_back_hub_end != null,
		"end_restart": btn_restart_run != null
	})

	_connect_buttons()
	_setup_run_timer()
	_setup_spawner()
	_log_signal_state()

	if end_panel != null:
		end_panel.visible = false
		Log.ok("RUN", "EndPanel hidden at start ✅")

	_start_run()

# ---------------------------------------------------------
# CONNECT / SETUP
# ---------------------------------------------------------
func _connect_buttons() -> void:
	if btn_sim_kill == null:
		Log.w("RUN", "ButtonSimKill absent ⚠️ (debug manual kill)")
	else:
		if not btn_sim_kill.pressed.is_connected(_on_sim_kill_pressed):
			btn_sim_kill.pressed.connect(_on_sim_kill_pressed)
		Log.ok("RUN", "ButtonSimKill connecté ✅", {"text": btn_sim_kill.text})

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

	# EndPanel buttons
	if btn_back_hub_end != null:
		if not btn_back_hub_end.pressed.is_connected(_on_endpanel_back_pressed):
			btn_back_hub_end.pressed.connect(_on_endpanel_back_pressed)
		Log.ok("RUN", "ButtonBackHubEnd connecté ✅")
	else:
		Log.w("RUN", "ButtonBackHubEnd absent ⚠️")

	if btn_restart_run != null:
		if not btn_restart_run.pressed.is_connected(_on_restart_pressed):
			btn_restart_run.pressed.connect(_on_restart_pressed)
		Log.ok("RUN", "ButtonRestartRun connecté ✅")
	else:
		Log.w("RUN", "ButtonRestartRun absent ⚠️")

func _setup_run_timer() -> void:
	if run_timer == null:
		Log.e("RUN", "RunTimer manquant ❌", {"expected": "RunTimer (Timer)"})
		return

	run_timer.wait_time = 1.0
	run_timer.one_shot = false
	run_timer.autostart = false

	if not run_timer.timeout.is_connected(_on_run_tick):
		run_timer.timeout.connect(_on_run_tick)

	Log.ok("RUN", "RunTimer prêt ✅", {"wait": run_timer.wait_time, "one_shot": run_timer.one_shot})

func _setup_spawner() -> void:
	if spawner == null:
		Log.e("COMBAT", "EnemySpawner manquant ❌", {"expected": str(spawner_path)})
		return

	# Connexion signal "enemy_killed"
	if not spawner.enemy_killed.is_connected(_on_enemy_killed):
		spawner.enemy_killed.connect(_on_enemy_killed)

	Log.ok("COMBAT", "Spawner connecté ✅", {
		"spawn_every_sec": spawner.spawn_every_sec,
		"base_gold": spawner.base_gold,
		"base_xp": spawner.base_xp,
		"spawn_visuals": spawner.spawn_visuals
	})

func _log_signal_state() -> void:
	Log.d("UI", "Signal state", {
		"simkill_connected": btn_sim_kill != null and btn_sim_kill.pressed.is_connected(_on_sim_kill_pressed),
		"end_connected": btn_end_run != null and btn_end_run.pressed.is_connected(_on_end_run_pressed),
		"back_connected": btn_back_hub != null and btn_back_hub.pressed.is_connected(_on_back_hub_pressed),
		"end_back_connected": btn_back_hub_end != null and btn_back_hub_end.pressed.is_connected(_on_endpanel_back_pressed),
		"restart_connected": btn_restart_run != null and btn_restart_run.pressed.is_connected(_on_restart_pressed),
	})

# ---------------------------------------------------------
# RUN FLOW
# ---------------------------------------------------------
func _start_run() -> void:
	_ended = false
	_bank_applied = false

	time_left = run_duration_sec
	wave_level = 1
	kills = 0
	run_gold_earned = 0
	run_xp_earned = 0

	start_gold = Game.gold
	start_xp = Game.xp
	start_level = Game.level

	if end_panel != null:
		end_panel.visible = false

	if btn_end_run != null:
		btn_end_run.disabled = false

	_refresh_ui_full()

	Log.i("RUN", "RUN START 🚀", {
		"duration_sec": run_duration_sec,
		"kills_per_wave": kills_per_wave,
		"start_gold": start_gold,
		"start_xp": start_xp,
		"start_level": start_level
	})

	# Start run timer
	if run_timer != null:
		run_timer.start()
		Log.ok("RUN", "RunTimer started ⏱️", {"time_left": time_left})

	# Start spawner auto
	if spawner != null:
		spawner.reset()
		spawner.start()
		Log.ok("COMBAT", "Spawner START ✅")

func _on_run_tick() -> void:
	if _ended:
		return

	time_left -= 1
	_refresh_timer_only()

	Log.d("RUN", "Tick ⏱️", {"time_left": time_left, "wave": wave_level, "kills": kills})

	if time_left <= 0:
		Log.i("RUN", "RUN END (timer) 🏁")
		_end_run("timer_end")

# ---------------------------------------------------------
# ENEMY KILL EVENT
# ---------------------------------------------------------
func _on_enemy_killed(base_gold: int, base_xp: int, source: String, enemy_id: String) -> void:
	if _ended:
		Log.w("COMBAT", "Kill reçu après fin (ignore) ⚠️", {"enemy_id": enemy_id, "src": source})
		return

	# 1) kill counter
	kills += 1

	# 2) wave progression
	var old_wave: int = wave_level
	if kills_per_wave > 0 and (kills % kills_per_wave) == 0:
		wave_level += 1

	# 3) multipliers stats (bonus additif -> x1.0 + bonus)
	var gold_mult_bonus: float = float(Game.get_stat("STAT_GOLD_GAIN_MULT_001"))
	var xp_mult_bonus: float = float(Game.get_stat("STAT_XP_GAIN_MULT_001"))
	var gold_mult: float = 1.0 + max(0.0, gold_mult_bonus)
	var xp_mult: float = 1.0 + max(0.0, xp_mult_bonus)

	# 4) scaling simple par wave
	var raw_gold: float = float(base_gold + (wave_level * 2))
	var raw_xp: float = float(base_xp + wave_level)

	var final_gold: int = int(round(raw_gold * gold_mult))
	var final_xp: int = int(round(raw_xp * xp_mult))

	run_gold_earned += max(0, final_gold)
	run_xp_earned += max(0, final_xp)

	_refresh_progress_only()

	Log.i("COMBAT", "Enemy killed 💥", {
		"enemy_id": enemy_id,
		"src": source,
		"kills": kills,
		"wave": wave_level,
		"base_gold": base_gold,
		"base_xp": base_xp,
		"final_gold": final_gold,
		"final_xp": final_xp,
		"run_gold": run_gold_earned,
		"run_xp": run_xp_earned,
		"gold_mult": gold_mult,
		"xp_mult": xp_mult
	})

	if wave_level != old_wave:
		Log.ok("COMBAT", "Wave UP 🌊", {"from": old_wave, "to": wave_level, "kills": kills})

# ---------------------------------------------------------
# BUTTONS
# ---------------------------------------------------------
func _on_sim_kill_pressed() -> void:
	Log.d("UI", "CLICK ✅", {"btn": "ButtonSimKill"})
	Log.i("COMBAT", "Manual kill requested 💀", {"source": "btn_sim_kill"})

	if spawner != null:
		# ✅ ICI : on passe une source claire (corrige ton erreur “Too many arguments”)
		spawner.simulate_manual_kill("btn_sim_kill")
	else:
		_on_enemy_killed(8, 4, "manual_fallback", "MANUAL")

func _on_end_run_pressed() -> void:
	Log.d("UI", "CLICK ✅", {"btn": "ButtonEndRun"})
	if _ended:
		Log.w("RUN", "EndRun press ignoré (déjà fini) ⚠️")
		return
	Log.i("RUN", "Fin de run manuelle 🏁")
	_end_run("manual_end")

func _on_back_hub_pressed() -> void:
	Log.d("UI", "CLICK ✅", {"btn": "ButtonBackHub"})
	Log.w("RUN", "Retour HUB debug (sans bank) ↩️")
	_go_hub("debug_back_no_bank")

# ---------------------------------------------------------
# END / BANK
# ---------------------------------------------------------
func _end_run(reason: String) -> void:
	_ended = true

	# stop timer + spawner
	if run_timer != null:
		run_timer.stop()
	if spawner != null:
		spawner.stop()

	Log.ok("RUN", "Stopped ✅", {"reason": reason, "run_timer": run_timer != null, "spawner": spawner != null})

	if not _bank_applied:
		_bank_applied = true

		var bonus_gold: int = max(0, wave_level * end_bonus_gold_per_wave)
		var bonus_xp: int = max(0, wave_level * end_bonus_xp_per_wave)

		Log.i("RUN", "Bank RUN rewards 🎒->🏦", {
			"run_gold": run_gold_earned,
			"run_xp": run_xp_earned,
			"bonus_gold": bonus_gold,
			"bonus_xp": bonus_xp,
			"wave": wave_level,
			"kills": kills
		})

		Game.add_gold(run_gold_earned + bonus_gold, "run_bank_" + reason)
		Game.add_xp(run_xp_earned + bonus_xp, "run_bank_" + reason)

		Log.ok("RUN", "Bank done ✅", {
			"gold_before": start_gold,
			"gold_after": Game.gold,
			"xp_before": start_xp,
			"xp_after": Game.xp,
			"level_after": Game.level
		})
	else:
		Log.w("RUN", "Bank déjà fait (ignore) ⚠️", {"reason": reason})

	_show_end_screen(reason)

func _show_end_screen(reason: String) -> void:
	if end_panel == null:
		Log.w("RUN", "EndPanel absent -> retour HUB direct ⚠️", {"reason": reason})
		_go_hub("end_" + reason)
		return

	if btn_end_run != null:
		btn_end_run.disabled = true

	if end_summary != null:
		end_summary.text = (
			"🏁 FIN DE RUN\n"
			+ "💀 Kills : " + str(kills) + "\n"
			+ "🌊 Vague : " + str(wave_level) + "\n"
			+ "🎒 Gains run : +" + str(run_gold_earned) + " or, +" + str(run_xp_earned) + " XP\n"
			+ "💰 Total or : " + str(Game.gold) + "\n"
			+ "✨ XP : " + str(Game.xp) + " | 🏅 Level : " + str(Game.level) + "\n"
			+ "📌 reason=" + reason
		)

	Log.i("RUN", "End screen show 🧾", {"reason": reason})
	end_panel.visible = true

func _on_endpanel_back_pressed() -> void:
	Log.d("UI", "CLICK ✅", {"btn": "ButtonBackHubEnd"})
	Log.i("RUN", "EndPanel -> Retour HUB 🏠")
	_go_hub("endpanel_back")

func _on_restart_pressed() -> void:
	Log.d("UI", "CLICK ✅", {"btn": "ButtonRestartRun"})
	Log.i("RUN", "EndPanel -> Restart RUN ▶️")
	_start_run()

func _go_hub(reason: String) -> void:
	Log.i("RUN", "Go HUB 🏠", {"reason": reason, "scene": SCENE_HUB})
	var err: Error = get_tree().change_scene_to_file(SCENE_HUB)
	if err != OK:
		Log.e("RUN", "change_scene_to_file failed", {"scene": SCENE_HUB, "err": err})

# ---------------------------------------------------------
# UI REFRESH
# ---------------------------------------------------------
func _refresh_ui_full() -> void:
	_refresh_timer_only()
	_refresh_progress_only()

	if lbl_rewards != null:
		lbl_rewards.text = "👾 Spawner auto | 💀 bouton debug | Bank fin + bonus vague"

func _refresh_timer_only() -> void:
	if lbl_timer != null:
		lbl_timer.text = "⏱️ Temps : " + str(max(0, time_left)) + "s"

func _refresh_progress_only() -> void:
	if lbl_wave != null:
		lbl_wave.text = "🌊 Vague : " + str(wave_level)
	if lbl_kills != null:
		lbl_kills.text = "💀 Kills : " + str(kills)
	if lbl_run_earnings != null:
		lbl_run_earnings.text = "🎒 Run : +" + str(run_gold_earned) + " or, +" + str(run_xp_earned) + " XP"
"run" 
