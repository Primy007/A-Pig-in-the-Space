# health_item.gd - HEALTH ITEM OTTIMIZZATO
extends Area2D

# --- CONFIGURAZIONE ---
@export var health_restore_amount: int = 25  # Quantità di salute da ripristinare
@export var pickup_radius: float = 150.0    # Raggio di attrazione automatica
@export var move_speed: float = 300.0       # Velocità di movimento verso il player
@export var bob_amplitude: float = 10.0     # Ampiezza del movimento su/giù
@export var bob_speed: float = 3.0          # Velocità del movimento ondulatorio
@export var lifetime: float = 30.0          # Tempo prima che scompaia (0 = infinito)

# --- STATO INTERNO ---
var player: CharacterBody2D
var is_attracted: bool = false
var is_collected: bool = false
var initial_position: Vector2
var time_alive: float = 0.0

# --- NODE REFERENCES ---
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var pickup_sfx = $PickupSFX
@onready var attract_area = $AttractArea
@onready var lifetime_timer = $LifetimeTimer

func _ready():
	# Setup gruppi
	add_to_group("health_items")
	add_to_group("pickups")
	
	# Setup segnali
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Setup area di attrazione se esiste
	if attract_area:
		attract_area.body_entered.connect(_on_attract_area_body_entered)
		attract_area.body_exited.connect(_on_attract_area_body_exited)
	
	# Setup timer lifetime
	if lifetime > 0:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.one_shot = true
		lifetime_timer.timeout.connect(_expire)
		lifetime_timer.start()
	
	# Salva posizione iniziale per il bobbing
	initial_position = global_position
	
	# Trova il player
	_find_player()
	
	print("Health Item creato - Healing: ", health_restore_amount)

func _physics_process(delta):
	if is_collected:
		return
		
	time_alive += delta
	
	# Movimento di attrazione verso il player
	if is_attracted and is_instance_valid(player):
		_move_towards_player(delta)
	else:
		# Movimento ondulatorio quando non è attratto
		_apply_bobbing_motion(delta)
	
	# Controllo automatico per il player nelle vicinanze
	_check_player_proximity()

func _find_player():
	"""Trova il riferimento al player"""
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Riprova dopo un frame se il player non è ancora pronto
		call_deferred("_find_player")

func _move_towards_player(delta):
	"""Muove l'item verso il player quando è attratto"""
	if not is_instance_valid(player):
		is_attracted = false
		return
	
	var direction = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)
	
	# Accelera man mano che si avvicina
	var speed_multiplier = clamp(1.0 + (1.0 - distance / pickup_radius), 1.0, 3.0)
	global_position += direction * move_speed * speed_multiplier * delta

func _apply_bobbing_motion(delta):
	"""Applica il movimento ondulatorio su/giù"""
	var bob_offset = sin(time_alive * bob_speed) * bob_amplitude
	global_position.y = initial_position.y + bob_offset

func _check_player_proximity():
	"""Controlla se il player è abbastanza vicino per l'attrazione automatica"""
	if is_attracted or not is_instance_valid(player):
		return
		
	var distance = global_position.distance_to(player.global_position)
	if distance <= pickup_radius:
		_start_attraction()

func _start_attraction():
	"""Inizia l'attrazione verso il player"""
	if not is_attracted:
		is_attracted = true
		# Effetto visivo di attrazione (opzionale)
		_play_attraction_effect()

func _play_attraction_effect():
	"""Effetto visivo quando l'item viene attratto"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Leggero ingrandimento
	tween.tween_property(sprite, "scale", sprite.scale * 1.2, 0.2)
	tween.tween_property(sprite, "scale", sprite.scale, 0.2).set_delay(0.2)
	
	# Effetto di luminosità
	tween.tween_property(sprite, "modulate", Color.WHITE * 1.5, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1).set_delay(0.1)

func _on_body_entered(body):
	"""Chiamato quando un corpo entra nell'area principale"""
	if body.is_in_group("player") and not is_collected:
		_collect_item(body)

func _on_area_entered(area):
	"""Chiamato quando un'area entra nell'area principale (es. player con Area2D)"""
	if area.is_in_group("player") and not is_collected:
		_collect_item(area)

func _on_attract_area_body_entered(body):
	"""Chiamato quando il player entra nell'area di attrazione"""
	if body.is_in_group("player"):
		_start_attraction()

func _on_attract_area_body_exited(body):
	"""Chiamato quando il player esce dall'area di attrazione"""
	if body.is_in_group("player") and not is_collected:
		is_attracted = false

func _collect_item(collector):
	"""Raccoglie l'health item e cura il player"""
	if is_collected:
		return
		
	is_collected = true
	
	# Verifica che sia effettivamente il player
	if not collector.is_in_group("player"):
		return
	
	# Controlla se il player ha già la salute massima
	if collector.current_health >= collector.max_health:
		print("Player già a salute massima, health item non raccolto")
		is_collected = false
		return
	
	# Applica la cura
	var old_health = collector.current_health
	collector.current_health = min(collector.current_health + health_restore_amount, collector.max_health)
	var actual_healing = collector.current_health - old_health
	
	# Aggiorna la barra della salute
	if collector.has_method("update_health_bar"):
		collector.update_health_bar()
	
	print("Health Item raccolto - Curato: ", actual_healing, " HP")
	
	# Effetti di raccolta
	_play_pickup_effects()
	
	# Notifica il GameManager per statistiche (opzionale)
	if has_node("/root/GameManager"):
		GameManager._on_health_item_collected(actual_healing)
	
	# Rimuovi l'item
	call_deferred("_destroy_item")

func _play_pickup_effects():
	"""Riproduce gli effetti audio/visivi di raccolta"""
	# Disabilita collision per evitare doppia raccolta
	collision_shape.set_deferred("disabled", true)
	
	# Audio
	if pickup_sfx:
		pickup_sfx.play()
	
	# Effetto visivo di raccolta
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Ingrandimento e fade out
	tween.tween_property(sprite, "scale", sprite.scale * 2.0, 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	# Movimento verso l'alto
	tween.tween_property(self, "global_position", global_position + Vector2(0, -50), 0.3)

func _destroy_item():
	"""Distrugge l'item in modo sicuro"""
	# Aspetta che l'audio finisca se sta suonando
	if pickup_sfx and pickup_sfx.playing:
		await pickup_sfx.finished
	
	# Rimuovi dai gruppi
	remove_from_group("health_items")
	remove_from_group("pickups")
	
	# Elimina l'oggetto
	queue_free()

func _expire():
	"""Chiamato quando l'item scade per timeout"""
	print("Health Item scaduto dopo ", lifetime, " secondi")
	
	# Effetto di fade out per scadenza
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	_destroy_item()

# --- METODI PUBBLICI ---
func set_health_amount(amount: int):
	"""Imposta la quantità di salute da ripristinare"""
	health_restore_amount = max(1, amount)

func set_lifetime(time: float):
	"""Imposta il tempo di vita dell'item"""
	lifetime = time
	if lifetime_timer and lifetime > 0:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.start()

func force_attract():
	"""Forza l'attrazione dell'item verso il player"""
	_start_attraction()

# --- UTILITY ---
func get_distance_to_player() -> float:
	"""Restituisce la distanza dal player"""
	if is_instance_valid(player):
		return global_position.distance_to(player.global_position)
	return -1.0
