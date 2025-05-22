extends Node

class_name PowerUpManager

# Singleton per gestire i power-up globalmente
static var instance: PowerUpManager

# Segnali per notificare i cambiamenti dei power-up
signal powerup_collected(strategy: BasePowerUpStrategy)
signal powerup_expired(strategy: BasePowerUpStrategy)

# Scene dei power-up precaricate
var powerup_scenes: Dictionary = {}

# Riferimenti
var player: CharacterBody2D
var spawner: PowerUpSpawner
var ui: PowerUpUI

func _ready():
	# Imposta il singleton
	if instance == null:
		instance = self
	else:
		queue_free()
		return
	
	# Precarga le scene dei power-up
	_preload_powerup_scenes()
	
	# Cerca i componenti necessari
	_find_components()

func _preload_powerup_scenes():
	# Qui puoi precaricare tutte le scene di power-up
	# Esempio:
	# powerup_scenes["speed"] = preload("res://scenes/powerups/speed_powerup.tscn")
	# powerup_scenes["damage"] = preload("res://scenes/powerups/damage_powerup.tscn")
	# powerup_scenes["pierce"] = preload("res://scenes/powerups/pierce_powerup.tscn")
	pass

func _find_components():
	# Trova il player
	player = get_tree().get_first_node_in_group("player")
	
	# Trova lo spawner (se esiste)
	spawner = get_tree().get_first_node_in_group("powerup_spawner")
	
	# Trova la UI (se esiste)
	ui = get_tree().get_first_node_in_group("powerup_ui")

# Funzione per applicare un power-up al player
func apply_powerup_to_player(strategy: BasePowerUpStrategy):
	if !player:
		return
		
	# Applica al giocatore
	strategy.apply_to_player(player)
	
	# Aggiungi alla lista degli attivi
	if !player.active_powerups.has(strategy):
		player.active_powerups.append(strategy)
	
	# Emetti il segnale
	powerup_collected.emit(strategy)
	
	# Se ha una durata, imposta un timer
	if strategy.duration > 0:
		var timer = Timer.new()
		timer.wait_time = strategy.duration
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func(): _remove_powerup_from_player(strategy, timer))
		timer.start()

# Funzione per rimuovere un power-up dal player
func _remove_powerup_from_player(strategy: BasePowerUpStrategy, timer: Timer):
	if !player:
		return
		
	# Rimuovi l'effetto
	strategy.remove_from_player(player)
	
	# Rimuovi dalla lista degli attivi
	if player.active_powerups.has(strategy):
		player.active_powerups.erase(strategy)
	
	# Emetti il segnale
	powerup_expired.emit(strategy)
	
	# Pulisci il timer
	if timer:
		timer.queue_free()

# Funzione per forzare lo spawn di un power-up
func spawn_powerup(powerup_type: String, position: Vector2 = Vector2.ZERO):
	if !spawner or !powerup_scenes.has(powerup_type):
		return
		
	spawner.force_spawn_powerup(powerup_scenes[powerup_type], position)

# Funzione per ottenere tutti i power-up attivi
func get_active_powerups() -> Array:
	if player:
		return player.active_powerups
	return []

# Funzione per verificare se un tipo di power-up è attivo
func has_powerup_type(powerup_class: String) -> bool:
	if !player:
		return false
		
	for powerup in player.active_powerups:
		if powerup.get_script().get_global_name() == powerup_class:
			return true
	return false

# Funzione per pulire tutti i power-up (utile per game over, cambio livello, etc.)
func clear_all_powerups():
	if player:
		for strategy in player.active_powerups.duplicate():
			_remove_powerup_from_player(strategy, null)
	
	if spawner:
		spawner.clear_all_powerups()
