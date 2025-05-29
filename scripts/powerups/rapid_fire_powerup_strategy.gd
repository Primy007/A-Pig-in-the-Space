class_name RapidFirePowerUpStrategy
extends BasePowerUpStrategy

@export var fire_rate_boost_percentage: float = 50.0

const POWERUP_ID = "rapid_fire"

func apply_to_player(player: CharacterBody2D) -> void:
	# Attiva il rapid fire
	player.has_rapid_fire = true
	
	# Calcola il nuovo fire rate (più basso = più veloce)
	var boost_multiplier = (100 - fire_rate_boost_percentage) / 100.0
	player.modified_fire_rate = player.FIRE_RATE * boost_multiplier
	
	print("Rapid Fire attivato! Fire rate: ", player.modified_fire_rate)

func remove_from_player(player: CharacterBody2D) -> void:
	# Disattiva il rapid fire
	player.has_rapid_fire = false
	player.modified_fire_rate = player.FIRE_RATE
	
	print("Rapid Fire disattivato!")

func get_powerup_id() -> String:
	return POWERUP_ID
