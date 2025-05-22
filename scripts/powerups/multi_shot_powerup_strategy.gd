class_name MultiShotPowerUpStrategy
extends BasePowerUpStrategy

# Numero di proiettili aggiuntivi da sparare
@export var extra_bullets: int = 2
# Angolo di spread tra i proiettili in gradi
@export var spread_angle: float = 15.0

func apply_to_player(player: CharacterBody2D) -> void:
	# Aggiungiamo la proprietà per sparare proiettili multipli
	player.has_multi_shot = true
	player.multi_shot_count = extra_bullets
	player.multi_shot_spread = spread_angle

func remove_from_player(player: CharacterBody2D) -> void:
	# Rimuoviamo la proprietà multi-shot
	player.has_multi_shot = false
