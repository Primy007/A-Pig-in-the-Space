extends CharacterBody2D

# --- CONSTANTS ---
const FIRE_RATE: float = 0.2
const SHOOT_EFFECT_DURATION: float = 0.16
const BASE_SHAKE_STRENGTH: float = 5.0  # Ridotto da 14.0
const SHAKE_DURATION: float = 0.15
const HIT_SHAKE_STRENGTH: float = 18.0  # Nuovo valore per quando il player viene colpito
const HIT_SHAKE_DURATION: float = 0.2   # Durata più lunga per l'impatto

# --- MOVEMENT SETTINGS ---
@export var speed: int = 500
@export var acceleration: int = 700
@export var friction: int = 600
@export var rotation_speed: float = 8.0  # Increased for smoother mouse rotation

# --- SHOOTING SETTINGS ---
@export var bullet_scene: PackedScene
@export var muzzle_marker: Marker2D

# --- CAMERA SETTINGS ---
@export var camera_smooth_speed: float = 8.0

# --- NODE REFERENCES ---
@onready var animation_flying = $Flyng_Sprite
@onready var animation_fire = $Fire_Sprite
@onready var sprite_shoot = $Shoot_effect
@onready var camera: Camera2D = $Camera2D

# --- STATE MANAGEMENT ---
enum FireState { OFF, SPARK, FIRE_LOOP, STOP }
var fire_state: FireState = FireState.OFF
var can_shoot: bool = true
var shake_intensity: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO
var is_thrusting: bool = false

# --- HEALTH ---
var is_dying: bool = false
var health_bar: TextureProgressBar
@export var max_health = 100
@export var current_health = 100

func _ready():
	_setup_camera()
	_reset_visuals()

	# Istanzio l'HUD (che è un CanvasLayer)
	var hud = preload("res://scenes/player/player_health_bar.tscn").instantiate()
	get_tree().root.add_child(hud)

	# Prendo la TextureProgressBar al suo interno
	health_bar = hud.get_node("TextureProgressBar")
	health_bar.max_value = max_health
	health_bar.value = current_health

func _physics_process(delta):
	_handle_rotation(delta)
	_handle_movement(delta)
	_update_fire_animation()
	_handle_shooting()
	_apply_camera_effects(delta)
	
	move_and_slide()

# --- PRIVATE METHODS ---
func _is_moving() -> bool:
	return is_thrusting

func _setup_camera():
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smooth_speed
	camera.make_current()
	original_camera_offset = camera.offset

func _reset_visuals():
	$Fire_Sprite.visible = false
	$Shoot_effect.visible = false

func _handle_rotation(delta: float):
	var mouse_pos = get_global_mouse_position()
	var direction = global_position.direction_to(mouse_pos)
	var target_angle = direction.angle() + PI/2
	
	# Smooth rotation towards mouse
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

func _handle_movement(delta: float):
	# Update thrusting state based on spacebar input
	is_thrusting = Input.is_action_pressed("ui_select")  # "ui_select" is spacebar by default
	
	if is_thrusting:
		# Move forward in the direction the ship is facing
		var move_direction = -transform.y  # In Godot, negative Y is forward when rotated 0
		velocity = velocity.move_toward(move_direction * speed, acceleration * delta)
		animation_flying.play("Flying")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if velocity.length() < 10:  # Small threshold to avoid flickering
			animation_flying.stop()

func _update_fire_animation():
	if is_thrusting:
		_handle_moving_animation()
	else:
		_handle_stopping_animation()

func _handle_moving_animation():
	if fire_state in [FireState.OFF, FireState.STOP]:
		$Fire_Sprite.visible = true
		animation_fire.play("spark")
		$SparkSFX.play()
		fire_state = FireState.SPARK

func _handle_stopping_animation():
	if fire_state in [FireState.SPARK, FireState.FIRE_LOOP] && animation_fire.animation != "fire_stop":
		animation_fire.play("fire_stop")
		fire_state = FireState.STOP

func _handle_shooting():
	if Input.is_action_pressed("fire") && can_shoot:
		shoot()
		can_shoot = false
		await get_tree().create_timer(FIRE_RATE).timeout
		can_shoot = true

func _apply_camera_effects(delta: float):
	if shake_intensity > 0:
		camera.offset = original_camera_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerpf(shake_intensity, 0.0, delta * 15.0)

# --- PUBLIC METHODS ---
func shoot():
	if bullet_scene && muzzle_marker:
		_fire_bullet()
		_show_shoot_effect()
		apply_screen_shake(BASE_SHAKE_STRENGTH, SHAKE_DURATION)

func _fire_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle_marker.global_position
	bullet.direction = -muzzle_marker.global_transform.y
	get_tree().current_scene.add_child(bullet)

func _show_shoot_effect():
	sprite_shoot.visible = true
	await get_tree().create_timer(SHOOT_EFFECT_DURATION).timeout
	sprite_shoot.visible = false

func apply_screen_shake(strength: float, duration: float):
	shake_intensity = strength
	var shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	shake_tween.tween_property(self, "shake_intensity", 0.0, duration)
	await shake_tween.finished
	camera.offset = original_camera_offset

func take_damage(damage):
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()
	
	# Aggiungi l'effetto di tremore della telecamera quando il giocatore viene colpito
	apply_screen_shake(HIT_SHAKE_STRENGTH, HIT_SHAKE_DURATION)

	if current_health <= 0 and not is_dying:
		is_dying = true
		_handle_dead()

func _handle_dead():
	die()

func update_health_bar():
	health_bar.value = current_health

func die():
	queue_free()  # O animazione di morte, esplosione, ecc.


# --- SIGNAL HANDLERS ---
func _on_fire_sprite_animation_finished():
	match fire_state:
		FireState.SPARK:
			if _is_moving():
				fire_state = FireState.FIRE_LOOP
				animation_fire.play("fire_loop")
			else:
				fire_state = FireState.STOP
				animation_fire.play("fire_stop")
		FireState.STOP:
			$Fire_Sprite.visible = false
			fire_state = FireState.OFF
