extends CharacterBody2D

var speed = 500                   # Velocità della navicella
var acceleration = 700            # Accelerazione della navicella
var friction = 600                # Frizione per fermarsi
var rotation_speed = 3            # Velocità di rotazione

@export var bullet_scene: PackedScene    # Scena del proiettile da assegnare nell'editor
var can_shoot = true
var fire_rate = 0.2                      # Tempo fra uno sparo e l'altro (in secondi)

@onready var animation_flying = $Flyng_Sprite
@onready var animation_fire = $Fire_Sprite
@onready var sprite_shoot = $Shoot_effect

enum FireState { OFF, SPARK, FIRE_LOOP, STOP }
var fire_state = FireState.OFF

func _ready():
	$Fire_Sprite.visible = false
	$Shoot_effect.visible = false

# Funzione helper per verificare se il player sta muovendo
func is_moving() -> bool:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") != Vector2.ZERO

# Funzione dedicata all'aggiornamento dell'animazione del fuoco
func update_fire_animation():
	if is_moving():
		if fire_state == FireState.OFF or fire_state == FireState.STOP:
			$Fire_Sprite.visible = true
			animation_fire.play("spark")
			fire_state = FireState.SPARK
	else:
		if (fire_state == FireState.SPARK or fire_state == FireState.FIRE_LOOP) and animation_fire.animation != "fire_stop":
			animation_fire.play("fire_stop")
			fire_state = FireState.STOP

func _physics_process(delta):
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if is_moving():
		# Calcola l'angolo target e ruota gradualmente la navicella
		var target_angle = input_vector.angle() + PI/2
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
		velocity = velocity.move_toward(input_vector.normalized() * speed, acceleration * delta)
		animation_flying.play("Flying")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		animation_flying.stop()
	
	update_fire_animation()
	move_and_slide()
	
	if Input.is_action_pressed("fire") and can_shoot:
		shoot()
		can_shoot = false
		await get_tree().create_timer(fire_rate).timeout
		can_shoot = true

@export var muzzle_marker: Marker2D

func shoot():
	if bullet_scene and muzzle_marker:
		# Instanzia e posiziona il proiettile
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle_marker.global_position
		bullet.direction = -muzzle_marker.global_transform.y
		get_tree().current_scene.add_child(bullet)
		
		# Attiva lo sprite dell'effetto sparo per 0.2 secondi (o il tempo desiderato)
		sprite_shoot.visible = true
		await get_tree().create_timer(0.16).timeout  # Puoi modificare 0.2 con il tempo che preferisci
		sprite_shoot.visible = false

# Callback per il segnale "animation_finished" senza parametri
func _on_fire_sprite_animation_finished():
	match animation_fire.animation:
		"spark":
			if is_moving():
				animation_fire.play("fire_loop")
				fire_state = FireState.FIRE_LOOP
			else:
				animation_fire.play("fire_stop")
				fire_state = FireState.STOP
		"fire_stop":
			$Fire_Sprite.visible = false
			fire_state = FireState.OFF
