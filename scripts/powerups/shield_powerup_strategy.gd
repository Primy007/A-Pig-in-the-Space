class_name ShieldPowerUpStrategy
extends BasePowerUpStrategy

# Quantità di danno che lo scudo può assorbire
@export var shield_amount: int = 50
# Texture dello scudo da mostrare sul player
@export var shield_texture: Texture2D
# Velocità di lampeggio (secondi per ciclo completo)
@export var blink_speed: float = 1.5
# Opacità minima e massima per il lampeggio
@export var min_alpha: float = 0.3
@export var max_alpha: float = 1.0

const POWERUP_ID = "shield"

func apply_to_player(player: CharacterBody2D) -> void:
	# Aggiungiamo uno scudo al giocatore
	player.has_shield = true
	player.shield_health = shield_amount
	
	# Creiamo e aggiungiamo l'effetto visivo dello scudo
	create_shield_effect(player)

func remove_from_player(player: CharacterBody2D) -> void:
	# Rimuoviamo lo scudo
	player.has_shield = false
	player.shield_health = 0
	
	# Rimuoviamo l'effetto visivo 
	remove_shield_effect(player)

func create_shield_effect(player: CharacterBody2D) -> void:
	# Rimuovi l'effetto precedente se esiste
	remove_shield_effect(player)
	
	# Crea un nuovo sprite per lo scudo
	var shield_sprite = Sprite2D.new()
	shield_sprite.name = "ShieldEffect"
	shield_sprite.texture = shield_texture
	shield_sprite.z_index = 2 # Dietro al player sprite
	shield_sprite.modulate.a = max_alpha  # Imposta l'opacità iniziale
	
	# Aggiungi il nodo al player
	player.add_child(shield_sprite)
	
	# Crea le animazioni
	create_shield_animations(shield_sprite)

func create_shield_animations(shield_sprite: Sprite2D) -> void:
	# Animazione di lampeggio (opacità)
	var blink_tween = shield_sprite.create_tween()
	blink_tween.set_loops()
	# Crea un ciclo: da max_alpha a min_alpha, poi da min_alpha a max_alpha
	blink_tween.tween_property(shield_sprite, "modulate:a", min_alpha, blink_speed / 2.0)
	blink_tween.tween_property(shield_sprite, "modulate:a", max_alpha, blink_speed / 2.0)

func remove_shield_effect(player: CharacterBody2D) -> void:
	if player.has_node("ShieldEffect"):
		player.get_node("ShieldEffect").queue_free()

func get_powerup_id() -> String:
	return POWERUP_ID
