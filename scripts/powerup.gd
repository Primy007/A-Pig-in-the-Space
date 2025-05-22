extends Area2D

class_name PowerUp

# Riferimento alla strategia di power-up
@export var power_up_strategy: BasePowerUpStrategy
# Riferimento agli elementi visivi
@export var label: Label
@export var sprite: Sprite2D
# Particelle per effetto visivo
@export var particles: GPUParticles2D
# Suono da riprodurre quando viene raccolto
@export var pickup_sound: AudioStreamPlayer

# Variables per l'animazione
var rotate_speed = 1.0
var bob_height = 5.0
var bob_speed = 2.0
var initial_position = Vector2.ZERO
var time_passed = 0.0

func _ready():
	# Configurazione iniziale
	initial_position = position
	
	# Impostazione grafica
	if power_up_strategy and sprite:
		sprite.texture = power_up_strategy.texture
	
	if power_up_strategy and label:
		label.text = power_up_strategy.upgrade_text
	
	# Connessione segnale
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Effetto rotazione e "galleggiamento"
	time_passed += delta
	
	# Rotazione
	sprite.rotation += rotate_speed * delta
	
	# Effetto di galleggiamento
	position.y = initial_position.y + sin(time_passed * bob_speed) * bob_height

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Il player ha raccolto il power-up
		apply_powerup(body)
		
		# Effetti visivi e sonori
		if pickup_sound:
			pickup_sound.play()
		
		if particles:
			particles.emitting = true
			particles.reparent(get_tree().root)
			
		# Auto-distruzione dopo l'applicazione
		queue_free()

func apply_powerup(player):
	if power_up_strategy:
		# Applica al giocatore
		power_up_strategy.apply_to_player(player)
		
		# Aggiungi la strategia all'array di power-up attivi del player
		if !player.active_powerups.has(power_up_strategy):
			player.active_powerups.append(power_up_strategy)
		
		# Se il power-up ha una durata, imposta un timer per rimuoverlo
		if power_up_strategy.duration > 0:
			var timer = Timer.new()
			timer.wait_time = power_up_strategy.duration
			timer.one_shot = true
			player.add_child(timer)
			timer.timeout.connect(func(): remove_powerup(player, power_up_strategy))
			timer.start()

func remove_powerup(player, strategy):
	# Rimuovi la strategia dall'array di power-up attivi
	if player.active_powerups.has(strategy):
		player.active_powerups.erase(strategy)
	
	# Rimuovi l'effetto dal player
	strategy.remove_from_player(player)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	pass # Replace with function body.
