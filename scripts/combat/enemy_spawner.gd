extends Node
class_name EnemySpawner

const Log = preload("res://scripts/core/log.gd")

signal enemy_killed(base_gold: int, base_xp: int, source: String, enemy_id: String)

@export var spawn_every_sec: float = 1.0
@export var base_gold: int = 8
@export var base_xp: int = 4

@export var spawn_visuals: bool = true
@export var enemy_scene: PackedScene
@export var enemies_container_path: NodePath = NodePath("../Enemies")

@export var spawn_x: float = 20.0
@export var spawn_y_min: float = 160.0
@export var spawn_y_max: float = 260.0

@export var kill_x: float = 220.0
@export var move_speed: float = 250.0
@export var dir: float = 1.0 # 1 = gauche->droite, -1 = droite->gauche

@export var debug_spawn: bool = true
@export var debug_ready: bool = true

@onready var spawn_timer: Timer = get_node_or_null("SpawnTimer") as Timer

var enemies_container: Node = null
var spawn_count: int = 0
var _running: bool = false

func _ready() -> void:
	Log.i("COMBAT", "EnemySpawner ready 👾")

	enemies_container = get_node_or_null(enemies_container_path)

	if debug_ready:
		Log.d("COMBAT", "Spawner nodes check", {
			"spawn_timer": spawn_timer != null,
			"enemies_container": enemies_container != null,
			"enemy_scene": enemy_scene != null,
			"spawn_visuals": spawn_visuals
		})

	if spawn_timer == null:
		Log.e("COMBAT", "SpawnTimer manquant ❌", {"expected": "EnemySpawner/SpawnTimer (Timer)"})
		return

	spawn_timer.wait_time = max(0.05, spawn_every_sec)
	spawn_timer.one_shot = false
	spawn_timer.autostart = false

	if not spawn_timer.timeout.is_connected(_on_spawn_timeout):
		spawn_timer.timeout.connect(_on_spawn_timeout)

	Log.ok("COMBAT", "SpawnTimer prêt ✅", {
		"wait": spawn_timer.wait_time,
		"one_shot": spawn_timer.one_shot,
		"base_gold": base_gold,
		"base_xp": base_xp
	})

func start() -> void:
	_running = true
	if spawn_timer != null:
		spawn_timer.wait_time = max(0.05, spawn_every_sec)
		spawn_timer.start()

	Log.i("COMBAT", "Spawner START ▶️", {
		"every_sec": spawn_every_sec,
		"spawn_visuals": spawn_visuals
	})

func stop() -> void:
	_running = false
	if spawn_timer != null:
		spawn_timer.stop()
	Log.i("COMBAT", "Spawner STOP ⏹️")

func reset() -> void:
	spawn_count = 0
	if enemies_container != null:
		for c in enemies_container.get_children():
			c.queue_free()
	if debug_spawn:
		Log.d("COMBAT", "Spawner reset 🔄", {"spawn_count": spawn_count})

func _on_spawn_timeout() -> void:
	if not _running:
		return
	_spawn_one("spawner_auto")

func simulate_manual_kill(source: String = "manual_btn") -> void:
	Log.i("COMBAT", "Manual kill requested 💀", {"source": source})
	_spawn_one(source)

func _spawn_one(source: String) -> void:
	spawn_count += 1
	var enemy_id: String = "E%03d" % spawn_count

	if debug_spawn:
		Log.d("COMBAT", "Spawn event 👾", {
			"enemy_id": enemy_id,
			"source": source,
			"base_gold": base_gold,
			"base_xp": base_xp,
			"spawn_visuals": spawn_visuals
		})

	# fallback sécurisé : si visuel impossible, on fait "kill direct" (le run ne casse jamais)
	var can_visual: bool = spawn_visuals and (enemy_scene != null) and (enemies_container != null)

	if not can_visual:
		if spawn_visuals and debug_spawn:
			Log.w("COMBAT", "spawn_visuals=true mais visuel impossible -> fallback kill direct", {
				"enemy_scene": enemy_scene != null,
				"enemies_container": enemies_container != null
			})
		emit_signal("enemy_killed", base_gold, base_xp, source, enemy_id)
		return

	var enemy: Node = enemy_scene.instantiate()
	enemies_container.add_child(enemy)

	var y: float = randf_range(spawn_y_min, spawn_y_max)
	var pos := Vector2(spawn_x, y)

	if enemy is Node2D:
		(enemy as Node2D).global_position = pos

	# écoute l'event de kill remonté par l'ennemi
	if enemy.has_signal("request_kill"):
		if not enemy.request_kill.is_connected(_on_enemy_request_kill):
			enemy.request_kill.connect(_on_enemy_request_kill)

	# activation deferred (safe)
	enemy.call_deferred("activate", {
		"enemy_id": enemy_id,
		"base_gold": base_gold,
		"base_xp": base_xp,
		"source": source,
		"move_speed": move_speed,
		"kill_x": kill_x,
		"dir": dir,
		"pos": pos
	})

	if debug_spawn:
		Log.d("COMBAT", "Enemy visual spawned ✅", {
			"enemy_id": enemy_id,
			"pos": str(pos),
			"move_speed": move_speed,
			"kill_x": kill_x,
			"dir": dir
		})

func _on_enemy_request_kill(gold: int, xp: int, source: String, enemy_id: String) -> void:
	if debug_spawn:
		Log.d("COMBAT", "Enemy reached kill_x -> emit kill", {
			"enemy_id": enemy_id,
			"gold": gold,
			"xp": xp,
			"source": source
		})
	emit_signal("enemy_killed", gold, xp, source, enemy_id)
