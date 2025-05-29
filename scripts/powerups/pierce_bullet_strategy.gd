class_name PierceBulletStrategy
extends BasePowerUpStrategy

# Incremento del numero di nemici attraversati
@export var additional_pierce: int = 2

const POWERUP_ID = "pierce_bullet"

func apply_to_bullet(bullet: Area2D) -> void:
	# Aumenta il numero massimo di penetrazioni del proiettile
	bullet.max_penetration += additional_pierce

func get_powerup_id() -> String:
	return POWERUP_ID
