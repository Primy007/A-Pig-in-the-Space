extends Control

class_name PowerUpUI

# Container per le icone dei power-up
@onready var powerup_container: HBoxContainer = $PowerUpContainer

# Scene per l'icona del power-up
var powerup_icon_scene = preload("res://scenes/ui/powerup_icon.tscn")

# Dizionario per tenere traccia delle icone attive
var active_icons: Dictionary = {}

# Riferimento al player
var player: CharacterBody2D

func _ready():
	# Trova il player
	player = get_tree().get_first_node_in_group("player")
	
	# Connette ai segnali del player se necessario
	if player:
		# Qui potresti connettere a segnali personalizzati del player
		# per aggiornare la UI quando i power-up cambiano
		pass

func _process(delta):
	# Aggiorna la UI dei power-up attivi
	if player:
		_update_powerup_display()

func _update_powerup_display():
	# Pulisce le icone non più attive
	for strategy in active_icons.keys():
		if !player.active_powerups.has(strategy):
			_remove_powerup_icon(strategy)
	
	# Aggiunge nuove icone per i power-up attivi
	for strategy in player.active_powerups:
		if !active_icons.has(strategy):
			_add_powerup_icon(strategy)

func _add_powerup_icon(strategy: BasePowerUpStrategy):
	if !powerup_icon_scene:
		return
		
	var icon = powerup_icon_scene.instantiate()
	powerup_container.add_child(icon)
	
	# Configura l'icona
	icon.setup(strategy)
	
	# Memorizza l'icona
	active_icons[strategy] = icon

func _remove_powerup_icon(strategy: BasePowerUpStrategy):
	if active_icons.has(strategy):
		var icon = active_icons[strategy]
		icon.queue_free()
		active_icons.erase(strategy)
