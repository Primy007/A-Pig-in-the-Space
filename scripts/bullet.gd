extends Area2D

var speed = 750  # Velocità del proiettile
var direction = Vector2.ZERO  # Direzione predefinita (verrà sovrascritta)

func _ready():
	# Ruota lo sprite nella direzione del movimento
	rotation = direction.angle() + PI/2  # Aggiusta in base all'orientamento iniziale


func _physics_process(delta):
	position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()  # Distrugge il proiettile quando esce dallo schermo

func _on_body_entered(body):
	if body.is_in_group("enemies"):  # Esempio: distrugge i nemici
		body.queue_free()
	queue_free()  # Distrugge il proiettile dopo una collisione
