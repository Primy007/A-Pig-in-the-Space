extends CharacterBody2D  # o Area2D se usi quello

var max_health = 100
var current_health = 100

@onready var health_bar = $HealthBar  # Cambia se ha un altro nome o percorso

func _ready():
	update_health_bar()

func take_damage(damage):
	current_health -= damage
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()

	if current_health <= 0:
		die()

func update_health_bar():
	health_bar.value = current_health

func die():
	queue_free()  # O animazione di morte, esplosione, ecc.
