extends CharacterBody2D

# --- Configurazione esposta ---
@export var speed: float = 200
@export var stop_distance_x: float = 800  # Distanza orizzontale per fermarsi
@export var stop_distance_y: float = 500  # Distanza verticale per fermarsi
@export var flee_distance: float = 300    # Distanza euclidea per iniziare a fuggire
@export var flee_speed: float = 150
@export var fire_rate: float = 1.0
@export var bullet_scene: PackedScene
@export var muzzle_markers: Array[Marker2D] = []

# --- Riferimenti ai nodi ---
@onready var animation_flying = $Enemy_flying
@onready var attack_cooldown = $AttackCooldown
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	animation_flying.play("Normal")
	_validate_setup()

func _physics_process(delta):
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	
	_handle_movement()
	_rotate_towards_player()
	
	if _in_attack_range() && attack_cooldown.is_stopped():
		_shoot()
		attack_cooldown.start(fire_rate)

# --- Metodi privati ---
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
