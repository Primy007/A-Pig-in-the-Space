extends CharacterBody2D

var is_dying: bool = false


# --- Configurazione esposta ---
@export var speed: float = 200
@export var stop_distance_x: float = 800  # Distanza orizzontale per fermarsi
@export var stop_distance_y: float = 500  # Distanza verticale per fermarsi
@export var flee_distance: float = 300    # Distanza euclidea per iniziare a fuggire
@export var flee_speed: float = 150
@export var fire_rate: float = 1.0
@export var bullet_scene: PackedScene
@export var muzzle_markers: Array[Marker2D] = []
@export var max_health = 100
@export var current_health = 100

# --- Riferimenti ai nodi ---
@onready var animation_flying = $Enemy_flying
@onready var attack_cooldown = $AttackCooldown
@onready var player = get_tree().get_first_node_in_group("player")
@onready var health_bar = $HealthBar

func _ready():
	animation_flying.play("Normal")
	_validate_setup()
	update_health_bar()

func _process(delta):
	var offset = Vector2(-55, -80)  # regola Y a piacere
	# sposto la barra in coordinate globali
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

func take_damage(damage):
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()

	if current_health <= 0 and not is_dying:
		is_dying = true
		_handle_dead()

func _handle_dead():
	attack_cooldown.stop()                   # se vuoi fermare il timer
	# (facoltativo) rimuovi il nemico dal gruppo “enemies”:
	remove_from_group("enemies")
	 # Az zero tutti i layer di collisione del CharacterBody2D
	collision_layer = 0
	collision_mask = 0
	
	health_bar.visible = false
	
	# suono di morte
	$DeathSFX.play()
	
	#fa partire l'animazione
	animation_flying.play("Explosion")
	await animation_flying.animation_finished
	#lo elimina
	die()

func update_health_bar():
	health_bar.value = current_health

func die():
	queue_free()  # O animazione di morte, esplosione, ecc.
