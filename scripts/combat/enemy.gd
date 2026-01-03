extends Node2D
class_name Enemy

const Log = preload("res://scripts/core/log.gd")

signal reached_kill_x(enemy_id: String)

@export var enemy_id: String = "E000"
@export var move_speed: float = 250.0
@export var kill_x: float = 220.0
@export var source: String = "spawner_auto"

var _active: bool = false

func init_from_spawner(p_enemy_id: String, p_move_speed: float, p_kill_x: float, p_source: String) -> void:
	enemy_id = p_enemy_id
	move_speed = p_move_speed
	kill_x = p_kill_x
	source = p_source

func activate() -> void:
	_active = true
	Log.d("ENEMY", "Activate", {
		"enemy_id": enemy_id,
		"move_speed": move_speed,
		"kill_x": kill_x,
		"source": source,
		"pos": str(global_position)
	})

func _process(delta: float) -> void:
	if not _active:
		return

	global_position.x += move_speed * delta

	if global_position.x >= kill_x:
		_active = false
		Log.d("ENEMY", "Reached kill_x ✅", {
			"enemy_id": enemy_id,
			"source": source,
			"pos": str(global_position)
		})
		reached_kill_x.emit(enemy_id)
		queue_free()
