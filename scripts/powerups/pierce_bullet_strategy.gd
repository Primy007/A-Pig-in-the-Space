class_name PierceBulletStrategy
extends BasePowerUpStrategy

# Incremento del numero di nemici attraversati
@export var additional_pierce: int = 2

func apply_to_bullet(bullet: Area2D) -> void:
	# Aumenta il numero massimo di penetrazioni del proiettile
	bullet.max_penetration += additional_pierce
