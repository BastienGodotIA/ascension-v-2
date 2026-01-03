# res://scripts/combat/enemy.gd
extends Area2D

const Log = preload("res://scripts/core/log.gd")

signal killed(enemy_id: String, source: String, base_gold: int, base_xp: int, reason: String)

@export var enemy_id: String = "E000"
@export var source: String = "spawner_auto"
@export var base_gold: int = 8
@export var base_xp: int = 4

@export var move_speed: float = 250.0        # vitesse vers la gauche (placeholder "run")
@export var lifetime_sec: float = 999.0      # si tu veux tuer au timer plus tard
@export var kill_x: float = 220.0            # ligne "player hit" (x écran)
@export var despawn_x: float = -200.0        # sécurité

var _age: float = 0.0
var _dead: bool = false

func configure(p_id: String, p_source: String, p_gold: int, p_xp: int, p_speed: float, p_kill_x: float) -> void:
	enemy_id = p_id
	source = p_source
	base_gold = p_gold
	base_xp = p_xp
	move_speed = p_speed
	kill_x = p_kill_x
	Log.d("COMBAT", "Enemy configured", {
		"enemy_id": enemy_id, "src": source,
		"gold": base_gold, "xp": base_xp,
		"speed": move_speed, "kill_x": kill_x
	})

func _ready() -> void:
	Log.i("COMBAT", "Enemy spawn ✅", {
		"enemy_id": enemy_id, "src": source,
		"pos": str(global_position)
	})

func _physics_process(delta: float) -> void:
	if _dead:
		return

	_age += delta
	global_position.x -= move_speed * delta

	# Placeholder "combat" : quand l'ennemi atteint la ligne du joueur -> kill
	if global_position.x <= kill_x:
		die("reached_player_line")
		return

	# sécurité si ça part trop loin
	if global_position.x <= despawn_x:
		die("despawn_left")
		return

	# optionnel: kill au timer si tu veux
	if lifetime_sec < 999.0 and _age >= lifetime_sec:
		die("lifetime_end")

func die(reason: String) -> void:
	if _dead:
		return
	_dead = true

	Log.i("COMBAT", "Enemy killed 💥", {
		"enemy_id": enemy_id, "src": source, "reason": reason,
		"base_gold": base_gold, "base_xp": base_xp
	})

	emit_signal("killed", enemy_id, source, base_gold, base_xp, reason)
	queue_free()
