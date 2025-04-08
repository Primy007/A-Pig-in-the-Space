extends CharacterBody2D

@export var speed: float = 200  # Velocità di movimento
@export var stop_distance: float = 600  # Distanza minima dal player prima di fermarsi
@export var fire_rate: float = 1.0  # Tempo in secondi tra ogni sparo

@onready var animation_flying = $Enemy_flying

var player  # Riferimento al player
var time_since_last_shot: float = 0  # Variabile per il timer tra gli spari

@export var bullet_scene: PackedScene  # Assegna la scena del proiettile nell'editor

@export var muzzle_marker: Marker2D  # Primo marker di sparo
@export var muzzle_marker2: Marker2D  # Secondo marker di sparo

var bullet = preload("res://scenes/EnemyBullet.tscn")

func _ready():
	animation_flying.play("Normal")
	player = get_tree().get_first_node_in_group("player")  # Trova il player nel gruppo
	if player == null:
		queue_free()  # Se il player non esiste, elimina il nemico

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		var distance = global_position.distance_to(player.global_position)

		# Ruota il nemico verso il player
		rotation = direction.angle() + PI / 2  # + PI/2 se l'immagine è orientata in alto

		if distance > stop_distance:  # Si muove solo se è più lontano della stop_distance
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO  # Si ferma
			time_since_last_shot += delta  # Incrementa il timer per sparare
			# Se il timer è maggiore o uguale al fire_rate, spariamo
			if time_since_last_shot >= fire_rate:
				shoot()
				time_since_last_shot = 0  # Reset del timer

# Funzione per sparare da entrambi i marker
func shoot():
	if bullet_scene and muzzle_marker and muzzle_marker2:
		# Crea il proiettile dal primo marker (Marker)
		var bullet1 = bullet_scene.instantiate()
		bullet1.global_position = muzzle_marker.global_position
		bullet1.direction = -muzzle_marker.global_transform.y
		get_tree().current_scene.add_child(bullet1)

		# Crea il proiettile dal secondo marker (Marker2)
		var bullet2 = bullet_scene.instantiate()
		bullet2.global_position = muzzle_marker2.global_position
		bullet2.direction = -muzzle_marker2.global_transform.y
		get_tree().current_scene.add_child(bullet2)
