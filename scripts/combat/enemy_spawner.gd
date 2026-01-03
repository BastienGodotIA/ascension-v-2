# enemy_spawner.gd
extends Node
class_name EnemySpawner

const Log = preload("res://scripts/core/log.gd")

signal enemy_killed(base_gold: int, base_xp: int, source: String, enemy_id: String)

@export var spawn_every_sec: float = 1.0
@export var base_gold: int = 8
@export var base_xp: int = 4

# (optionnel) visuel
@export var enemy_scene: PackedScene
@export var spawn_visuals: bool = false
@export var enemies_container_path: NodePath = ^"../Enemies"

@onready var spawn_timer: Timer = get_node_or_null("SpawnTimer") as Timer
var _running := false
var spawn_count := 0
var _enemies_container: Node = null

func _ready() -> void:
	Log.i("COMBAT", "EnemySpawner ready 👾")
	_enemies_container = get_node_or_null(enemies_container_path)

	Log.d("COMBAT", "Spawner nodes check", {
		"spawn_timer": spawn_timer != null,
		"enemies_container": _enemies_container != null,
		"enemy_scene": enemy_scene != null,
		"spawn_visuals": spawn_visuals
	})

	if spawn_timer == null:
		Log.e("COMBAT", "SpawnTimer manquant ❌", {"expected":"EnemySpawner/SpawnTimer"})
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

func reset() -> void:
	spawn_count = 0
	Log.d("COMBAT", "Spawner reset 🔄", {"spawn_count": spawn_count})

func start() -> void:
	if spawn_timer == null:
		Log.e("COMBAT", "start() impossible ❌", {"reason":"no timer"})
		return
	_running = true
	Log.i("COMBAT", "Spawner START ▶️", {"every_sec": spawn_timer.wait_time})
	spawn_timer.start()

func stop() -> void:
	_running = false
	if spawn_timer != null:
		spawn_timer.stop()
	Log.i("COMBAT", "Spawner STOP ⏹️")

func simulate_manual_kill(source: String = "manual_btn") -> void:
	Log.i("COMBAT", "Manual kill requested 💀", {"source": source})
	_spawn_and_kill(source)


func _on_spawn_timeout() -> void:
	if not _running:
		return
	_spawn_and_kill("spawner_auto")

func _spawn_and_kill(source: String) -> void:
	spawn_count += 1
	var enemy_id := "E%03d" % spawn_count

	# 1) Spawn visuel (optionnel)
	var enemy_node: Node = null
	if spawn_visuals and enemy_scene != null and _enemies_container != null:
		enemy_node = enemy_scene.instantiate()
		_enemies_container.add_child(enemy_node)

		# évite le coin bas-gauche + accumulation (placeholder)
		if enemy_node is Node2D:
			(enemy_node as Node2D).position = Vector2(80, 80 + (spawn_count % 5) * 40)
		elif enemy_node is Control:
			var c := enemy_node as Control
			c.set_anchors_preset(Control.PRESET_TOP_LEFT)
			c.position = Vector2(80, 80 + (spawn_count % 5) * 40)

	Log.d("COMBAT", "Spawn event 👾", {
		"enemy_id": enemy_id,
		"source": source,
		"base_gold": base_gold,
		"base_xp": base_xp,
		"spawn_visuals": spawn_visuals
	})

	# 2) IMPORTANT : on émet le kill (c’est ça qui fait monter kills/or/xp dans run.gd)
	emit_signal("enemy_killed", base_gold, base_xp, source, enemy_id)

	# 3) Cleanup visuel immédiat (sinon ça duplique et reste à l’écran)
	if enemy_node != null:
		enemy_node.queue_free()
