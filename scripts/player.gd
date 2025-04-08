extends CharacterBody2D

# --- CONSTANTS ---
const FIRE_RATE: float = 0.2
const SHOOT_EFFECT_DURATION: float = 0.16
const BASE_SHAKE_STRENGTH: float = 14.0
const SHAKE_DURATION: float = 0.15

# --- MOVEMENT SETTINGS ---
@export var speed: int = 500
@export var acceleration: int = 700
@export var friction: int = 600
@export var rotation_speed: float = 3

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

func _ready():
	_setup_camera()
	_reset_visuals()

func _physics_process(delta):
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	_handle_movement(input_vector, delta)
	_update_fire_animation(input_vector)
	_handle_shooting()
	_apply_camera_effects(delta)
	
	move_and_slide()

# --- PRIVATE METHODS ---
func _is_moving(input_vector: Vector2) -> bool:
	return input_vector != Vector2.ZERO

func _setup_camera():
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_smooth_speed
	camera.make_current()
	original_camera_offset = camera.offset

func _reset_visuals():
	$Fire_Sprite.visible = false
	$Shoot_effect.visible = false

func _handle_movement(input_vector: Vector2, delta: float):
	if input_vector != Vector2.ZERO:
		_rotate_ship(input_vector, delta)
		velocity = velocity.move_toward(input_vector.normalized() * speed, acceleration * delta)
		animation_flying.play("Flying")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		animation_flying.stop()

func _rotate_ship(input_vector: Vector2, delta: float):
	var target_angle = input_vector.angle() + PI/2
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

func _update_fire_animation(input_vector: Vector2):
	if input_vector != Vector2.ZERO:
		_handle_moving_animation()
	else:
		_handle_stopping_animation()

func _handle_moving_animation():
	if fire_state in [FireState.OFF, FireState.STOP]:
		$Fire_Sprite.visible = true
		animation_fire.play("spark")
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

# --- SIGNAL HANDLERS ---
func _on_fire_sprite_animation_finished():
	var current_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	match fire_state:
		FireState.SPARK:
			if _is_moving(current_input):
				fire_state = FireState.FIRE_LOOP
				animation_fire.play("fire_loop")
			else:
				fire_state = FireState.STOP
				animation_fire.play("fire_stop")
		FireState.STOP:
			$Fire_Sprite.visible = false
			fire_state = FireState.OFF
