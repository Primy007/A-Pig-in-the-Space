# player.gd - VERSIONE AGGIORNATA
extends CharacterBody2D

# --- CONSTANTS ---
const FIRE_RATE: float = 0.2
const SHOOT_EFFECT_DURATION: float = 0.16
const HIT_SHAKE_STRENGTH: float = 18.0  # Valore per quando il player viene colpito
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
@onready var fire_loop_sfx = $FireLoopSFX

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

# --- POWER-UPS ---
# Usa un Dictionary per tracciare i power-up attivi per ID
var active_powerups = {}
var powerup_timers = {}  # Traccia i timer per ogni power-up

# --- RAPID FIRE POWER-UP ---
var has_rapid_fire: bool = false
var modified_fire_rate: float = FIRE_RATE

# Multi-shot
var has_multi_shot: bool = false
var multi_shot_count: int = 2
var multi_shot_spread: float = 15.0
# Shield
var has_shield: bool = false
var shield_health: int = 0

# Variabili per altri power-up possono essere aggiunte qui

# --- POWER-UP INDICATORS ---
#@onready var powerup_icons_container = $PowerupIconsContainer

# --- GAME MANAGER REFERENCE ---
var game_manager: Node

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
	
	# Inizializza il gruppo del player
	add_to_group("player")
	
	print("Player aggiunto al gruppo 'player'")
	
func _physics_process(delta):
	if is_dying:
		return
		
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
	is_thrusting = Input.is_action_pressed("move_forward")  # "ui_select" is spacebar by default
	
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
		# Ferma l'audio loop quando l'animazione si ferma
		fire_loop_sfx.stop()

func _handle_shooting():
	if Input.is_action_pressed("fire") && can_shoot:
		shoot()
		can_shoot = false
		
		# Usa direttamente la variabile
		var current_fire_rate = modified_fire_rate if has_rapid_fire else FIRE_RATE
		
		await get_tree().create_timer(current_fire_rate).timeout
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
		if has_multi_shot:
			_fire_multi_shot()
		else:
			_fire_single_bullet()
			
		_show_shoot_effect()
		# Rimossa la chiamata a apply_screen_shake per il tiro

func _fire_single_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle_marker.global_position
	bullet.direction = -muzzle_marker.global_transform.y
	get_tree().current_scene.add_child(bullet)
	
	# Applica i powerup al proiettile
	_apply_powerups_to_bullet(bullet)

func _fire_multi_shot():
	# Calcola l'angolo base
	var base_direction = -muzzle_marker.global_transform.y
	var total_bullets = 1 + (multi_shot_count * 2)  # centrale + laterali
	
	# Se abbiamo un numero dispari, includi il proiettile centrale
	if total_bullets % 2 == 1:
		var center_bullet = bullet_scene.instantiate()
		center_bullet.global_position = muzzle_marker.global_position
		center_bullet.direction = base_direction
		get_tree().current_scene.add_child(center_bullet)
		_apply_powerups_to_bullet(center_bullet)
	
	# Calcola l'angolo per i proiettili laterali
	var spread_rad = deg_to_rad(multi_shot_spread)
	
	# Crea i proiettili laterali simmetricamente
	for i in range(multi_shot_count):
		var angle = spread_rad * (i + 1)
		
		# Proiettile a sinistra
		var left_bullet = bullet_scene.instantiate()
		left_bullet.global_position = muzzle_marker.global_position
		left_bullet.direction = base_direction.rotated(-angle)
		get_tree().current_scene.add_child(left_bullet)
		_apply_powerups_to_bullet(left_bullet)
		
		# Proiettile a destra
		var right_bullet = bullet_scene.instantiate()
		right_bullet.global_position = muzzle_marker.global_position
		right_bullet.direction = base_direction.rotated(angle)
		get_tree().current_scene.add_child(right_bullet)
		_apply_powerups_to_bullet(right_bullet)

# Funzione per aggiungere un power-up
func add_powerup(strategy: BasePowerUpStrategy) -> void:
	if not strategy:
		print("ERRORE: Strategy power-up null")
		return
		
	var powerup_id = strategy.get_powerup_id()
	
	# Controllo se il power-up è già attivo
	if active_powerups.has(powerup_id):
		remove_powerup(powerup_id)
	
	# Applica il power-up con controllo errori
	if strategy.has_method("apply_to_player"):
		strategy.apply_to_player(self)
		active_powerups[powerup_id] = strategy
		
		# Timer solo se durata > 0
		if strategy.duration > 0:
			var timer = Timer.new()
			timer.wait_time = strategy.duration
			timer.one_shot = true
			timer.timeout.connect(_on_powerup_expired.bind(powerup_id))
			
			# Aggiunge il timer alla scena invece che al player
			if get_tree().current_scene:
				get_tree().current_scene.add_child(timer)
				powerup_timers[powerup_id] = timer
				timer.start()
			else:
				print("ERRORE: Impossibile aggiungere timer power-up")
	else:
		print("ERRORE: Strategy non ha il metodo apply_to_player")


# Funzione per rimuovere un power-up
func remove_powerup(powerup_id: String) -> void:
	if !active_powerups.has(powerup_id):
		return
		
	var strategy = active_powerups[powerup_id]
	strategy.remove_from_player(self)
	active_powerups.erase(powerup_id)
	
	# Rimuovi il timer se esiste
	if powerup_timers.has(powerup_id):
		var timer = powerup_timers[powerup_id]
		if is_instance_valid(timer):
			timer.queue_free()
		powerup_timers.erase(powerup_id)

# Callback per quando un power-up scade
func _on_powerup_expired(powerup_id: String) -> void:
	remove_powerup(powerup_id)

# Modifica la funzione _apply_powerups_to_bullet
func _apply_powerups_to_bullet(bullet):
	for strategy in active_powerups.values():
		strategy.apply_to_bullet(bullet)

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
	if is_dying:
		return
		
	# Se il giocatore ha lo scudo, il danno viene assorbito prima
	if has_shield and shield_health > 0:
		shield_health -= damage
		
		# Se lo scudo è stato distrutto dal danno
		if shield_health <= 0:
			# Rimuovi il power-up dello scudo (questo farà sparire l'effetto visivo)
			remove_powerup("shield")
			
			# Se c'è danno residuo, applicalo alla salute
			var excess_damage = -shield_health
			if excess_damage > 0:
				current_health -= excess_damage
				current_health = clamp(current_health, 0, max_health)
				update_health_bar()
				apply_screen_shake(HIT_SHAKE_STRENGTH, HIT_SHAKE_DURATION)
		return
	
	# Danno normale se non c'è scudo
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()
	
	# Aggiungi l'effetto di tremore della telecamera quando il giocatore viene colpito
	apply_screen_shake(HIT_SHAKE_STRENGTH, HIT_SHAKE_DURATION)

	if current_health <= 0 and not is_dying:
		is_dying = true
		_handle_dead()

func _handle_dead():
	# Pulisci i power-up in modo più sicuro
	for powerup_id in active_powerups.keys():
		remove_powerup(powerup_id)
	
	# Notifica GameManager usando l'autoload
	if has_node("/root/GameManager"):
		GameManager.on_player_died()
	else:
		print("ERRORE: GameManager autoload non trovato")
	
	_play_death_animation()

func _play_death_animation():
	# Disabilita controlli
	set_physics_process(false)
	
	# Rimuovi dai gruppi
	remove_from_group("player")
	
	# Ferma le animazioni attuali
	animation_flying.stop()
	animation_fire.stop()
	fire_loop_sfx.stop()
	
	# Animazione di esplosione/morte
	#if animation_flying.has_animation("Explosion"):
		#animation_flying.play("Explosion")
		#await animation_flying.animation_finished
	#else:
		# Animazione di fade out se non c'è animazione di esplosione
		#var tween = create_tween()
		#tween.tween_property(self, "modulate:a", 0.0, 1.0)
		#await tween.finished
	
	# Non eliminare il player immediatamente - la morte screen gestisce il restart
	visible = false

func update_health_bar():
	if health_bar:
		health_bar.value = current_health

func die():
	queue_free()

# --- SIGNAL HANDLERS ---
# Modifica la funzione _on_fire_sprite_animation_finished
func _on_fire_sprite_animation_finished():
	match fire_state:
		FireState.SPARK:
			if _is_moving():
				fire_state = FireState.FIRE_LOOP
				animation_fire.play("fire_loop")
				# Avvia l'audio loop quando inizia l'animazione loop
				fire_loop_sfx.play()
			else:
				fire_state = FireState.STOP
				animation_fire.play("fire_stop")
		FireState.STOP:
			$Fire_Sprite.visible = false
			fire_state = FireState.OFF
			# Assicurati che l'audio sia fermato quando l'animazione finisce completamente
			fire_loop_sfx.stop()
