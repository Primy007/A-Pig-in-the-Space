# enemy_fly.gd - VERSIONE CON SEGNALE DI MORTE
extends CharacterBody2D

var is_dying: bool = false

# --- SEGNALI ---
signal enemy_died

# --- Configurazione esposta ---
@export var speed: float = 200
@export var stop_distance_x: float = 800
@export var stop_distance_y: float = 500
@export var flee_distance: float = 300
@export var flee_speed: float = 150
@export var fire_rate: float = 1.0
@export var bullet_scene: PackedScene
@export var muzzle_markers: Array[Marker2D] = []
@export var max_health = 100
@export var current_health = 100

# Configurazione per health item drop
@export var health_drop_chance: float = 0.15  # 15% chance di drop (più basso dei power-up)
@export var health_item_scene: PackedScene   # Scena dell'health item da droppare

# Configurazione per power-up drop
@export var powerup_drop_chance: float = 0.3
@export var powerup_scenes: Array[PackedScene] = []

# --- Riferimenti ai nodi ---
@onready var animation_flying = $Enemy_flying
@onready var attack_cooldown = $AttackCooldown
@onready var player = get_tree().get_first_node_in_group("player")
@onready var health_bar = $HealthBar

func _ready():
	animation_flying.play("Normal")
	_validate_setup()
	update_health_bar()
	add_to_group("enemies")

func _process(delta):
	var offset = Vector2(-55, -80)
	health_bar.global_position = global_position + offset

func _physics_process(delta):
	if is_dying:
		return
		
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	
	_handle_movement()
	_rotate_towards_player()
	
	if _in_attack_range() && attack_cooldown.is_stopped():
		_shoot()
		attack_cooldown.start(fire_rate)

func _validate_setup():
	if !player:
		printerr("Player non trovato nel gruppo 'player'!")
		queue_free()
	if muzzle_markers.is_empty():
		printerr("Nessun muzzle marker assegnato!")
	if !bullet_scene:
		printerr("Nessuna scena proiettile assegnata!")

func _handle_movement():
	var player_pos = player.global_position
	var direction = (player_pos - global_position).normalized()
	var distance = global_position.distance_to(player_pos)
	
	if distance < flee_distance:
		velocity = -direction * flee_speed
	elif _should_approach():
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _should_approach() -> bool:
	var player_pos = player.global_position
	return (abs(player_pos.x - global_position.x) > stop_distance_x || 
		   abs(player_pos.y - global_position.y) > stop_distance_y)

func _rotate_towards_player():
	var direction = (player.global_position - global_position).normalized()
	rotation = direction.angle() + PI/2

func _in_attack_range() -> bool:
	var player_pos = player.global_position
	return (abs(player_pos.x - global_position.x) < stop_distance_x && 
		   abs(player_pos.y - global_position.y) < stop_distance_y)

func _shoot():
	for marker in muzzle_markers:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = marker.global_position
		bullet.direction = -marker.global_transform.y.normalized()
		get_parent().add_child(bullet)

func take_damage(damage):
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()

	if current_health <= 0 and not is_dying:
		is_dying = true
		_handle_dead()

func _handle_dead():
	attack_cooldown.stop()
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	health_bar.visible = false
	
	# Emetti il segnale PRIMA di aggiungere il punteggio
	enemy_died.emit()
	
	# Usa direttamente GameManager (autoload)
	if GameManager:
		GameManager.add_score(GameManager.points_per_enemy)
	
	# SISTEMA DI DROP OTTIMIZZATO - prima health item, poi power-up
	call_deferred("_try_drop_items")
	
	$DeathSFX.play()
	animation_flying.play("Explosion")
	await animation_flying.animation_finished
	die()

func _try_drop_powerup():
	if randf() <= powerup_drop_chance and !powerup_scenes.is_empty():
		var random_powerup_scene = powerup_scenes.pick_random()
		var powerup = random_powerup_scene.instantiate()
		powerup.global_position = global_position
		get_tree().current_scene.add_child(powerup)

func update_health_bar():
	health_bar.value = current_health

func die():
	queue_free()

func _try_drop_items():
	"""Sistema di drop ottimizzato per health item e power-up"""
	var drop_position = global_position
	var scene_root = get_tree().current_scene
	
	if not scene_root:
		print("ERRORE: Scena corrente non trovata per il drop")
		return
	
	# 1. TENTATIVO DROP HEALTH ITEM (priorità più alta se player ha poca salute)
	var should_drop_health = _should_drop_health_item()
	
	if should_drop_health and health_item_scene:
		var health_item = health_item_scene.instantiate()
		health_item.global_position = drop_position
		scene_root.add_child(health_item)
		print("Health Item droppato!")
		return  # Se droppa health item, non droppa power-up
	
	# 2. TENTATIVO DROP POWER-UP (solo se non ha droppato health item)
	_try_drop_powerup()

func _should_drop_health_item() -> bool:
	"""Determina se droppare un health item basandosi sulla salute del player"""
	# Controlla se esiste la scena dell'health item
	if not health_item_scene:
		return false
	
	# Trova il player
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return false
	
	# Calcola la percentuale di salute del player
	var health_percentage = float(player.current_health) / float(player.max_health)
	
	# Aumenta la probabilità di drop se il player ha poca salute
	var adjusted_chance = health_drop_chance
	
	if health_percentage <= 0.3:      # Salute molto bassa (≤30%)
		adjusted_chance *= 3.0        # Tripla la probabilità
	elif health_percentage <= 0.5:   # Salute bassa (≤50%)
		adjusted_chance *= 2.0        # Raddoppia la probabilità
	elif health_percentage <= 0.7:   # Salute media (≤70%)
		adjusted_chance *= 1.5        # Aumenta del 50%
	
	# Se il player ha salute piena, non droppare health item
	if health_percentage >= 1.0:
		return false
	
	return randf() <= adjusted_chance
