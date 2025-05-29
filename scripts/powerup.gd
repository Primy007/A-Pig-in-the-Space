extends Area2D

class_name PowerUp

@export var power_up_strategy: BasePowerUpStrategy
@export var label: Label
@export var sprite: Sprite2D
@export var particles: GPUParticles2D
@export var pickup_sound: AudioStreamPlayer

# Variables per l'animazione
var rotate_speed = 1.0
var bob_height = 5.0
var bob_speed = 2.0
var initial_position = Vector2.ZERO
var time_passed = 0.0

func _ready():
	initial_position = position
	
	if power_up_strategy and sprite:
		sprite.texture = power_up_strategy.texture
	
	if power_up_strategy and label:
		label.text = power_up_strategy.upgrade_text
	
	body_entered.connect(_on_body_entered)

func _process(delta):
	time_passed += delta
	sprite.rotation += rotate_speed * delta
	position.y = initial_position.y + sin(time_passed * bob_speed) * bob_height

func _on_body_entered(body):
	if body.is_in_group("player"):
		apply_powerup(body)
		
		if pickup_sound:
			pickup_sound.play()
		
		if particles:
			particles.emitting = true
			particles.reparent(get_tree().root)
		
		queue_free()

func apply_powerup(player):
	if !power_up_strategy:
		return
		
	# Usa il nuovo sistema del player
	player.add_powerup(power_up_strategy)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$VisibleOnScreenNotifier2D/Timer.start()

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$VisibleOnScreenNotifier2D/Timer.stop()

func _on_timer_timeout() -> void:
	queue_free()
