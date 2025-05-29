class_name RapidFirePowerUpStrategy
extends BasePowerUpStrategy

# Riduzione del cooldown tra i colpi
@export var fire_rate_boost_percentage: float = 50.0

# Riferimento al valore originale della fire rate
var original_fire_rate: float

func apply_to_player(player: CharacterBody2D) -> void:
	# CORREZIONE: Salva il valore originale usando una proprietà dinamica
	# dato che FIRE_RATE è una costante
	original_fire_rate = player.FIRE_RATE
	
	# Crea una proprietà dinamica per la fire rate modificata
	player.set("modified_fire_rate", original_fire_rate * (1 - fire_rate_boost_percentage / 100))
	
	# Imposta un flag per indicare che la fire rate è modificata
	player.set("has_rapid_fire", true)

func remove_from_player(player: CharacterBody2D) -> void:
	# Rimuovi le proprietà dinamiche
	player.set("has_rapid_fire", false)
	if player.has_method("remove_meta"):
		player.remove_meta("modified_fire_rate")

# NOTA: Il player.gd dovrà essere modificato per utilizzare modified_fire_rate quando has_rapid_fire è true
