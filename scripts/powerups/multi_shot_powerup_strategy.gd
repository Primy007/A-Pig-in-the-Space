class_name MultiShotPowerUpStrategy
extends BasePowerUpStrategy

@export var extra_bullets: int = 2
@export var spread_angle: float = 15.0

# ID univoco per identificare il tipo di power-up
const POWERUP_ID = "multi_shot"

func apply_to_player(player: CharacterBody2D) -> void:
	player.has_multi_shot = true
	player.multi_shot_count = extra_bullets
	player.multi_shot_spread = spread_angle

func remove_from_player(player: CharacterBody2D) -> void:
	player.has_multi_shot = false

func get_powerup_id() -> String:
	return POWERUP_ID
