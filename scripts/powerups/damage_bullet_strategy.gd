class_name DamageBulletStrategy
extends BasePowerUpStrategy

# Incremento del danno per i proiettili
@export var damage_increase: int = 20

func apply_to_bullet(bullet: Area2D) -> void:
	# Aumenta il danno del proiettile
	bullet.damage += damage_increase
