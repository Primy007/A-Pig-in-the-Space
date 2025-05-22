class_name RapidFirePowerUpStrategy
extends BasePowerUpStrategy

# Riduzione del cooldown tra i colpi
@export var fire_rate_boost_percentage: float = 50.0

# Riferimento al valore originale della fire rate
var original_fire_rate: float

func apply_to_player(player: CharacterBody2D) -> void:
	# Salva il valore originale prima di modificarlo
	original_fire_rate = player.FIRE_RATE
	
	# Riduce il cooldown tra i colpi (aumenta la frequenza di fuoco)
	player.FIRE_RATE = original_fire_rate * (1 - fire_rate_boost_percentage / 100)

func remove_from_player(player: CharacterBody2D) -> void:
	# Ripristina il valore originale
	player.FIRE_RATE = original_fire_rate
