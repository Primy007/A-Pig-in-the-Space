class_name SpeedBulletStrategy
extends BasePowerUpStrategy

# Incremento della velocità del proiettile
@export var speed_increase: float = 300.0

const POWERUP_ID = "speed_bullet"

func apply_to_bullet(bullet: Area2D) -> void:
	# Incrementa la velocità del proiettile
	bullet.speed += speed_increase

func get_powerup_id() -> String:
	return POWERUP_ID
