extends StaticBody2D

# Parametri per la velocità e la rotazione
var velocity := Vector2.ZERO
var rotation_speed := 0.0
var speed := 0.0

var min_speed = 400.0
var max_speed = 600.0

var min_rotation = 0.01
var max_rotation = 0.08

# Offset per far spawnare l'asteroide fuori dallo schermo
var offset = 50.0

func _ready():
	randomize()  # Assicura numeri casuali diversi a ogni esecuzione

	# Imposta una velocità casuale per l'asteroide
	speed = randf_range(min_speed, max_speed)
	
	# Imposta una velocità di rotazione casuale nel range specificato
	rotation_speed = randf_range(min_rotation, max_rotation)
	# Randomizza anche la direzione della rotazione (orario o antiorario)
	if randi() % 2 == 0:
		rotation_speed *= -1

	# Ottieni le dimensioni della viewport (lo schermo)
	var viewport_rect = get_viewport_rect()

	# Scegli casualmente da quale lato spawnare l'asteroide
	var spawn_side = randi() % 4  # 0: Top, 1: Bottom, 2: Left, 3: Right

	match spawn_side:
		0:  # Top (Spawn sopra lo schermo)
			var spawn_x = randf_range(0, viewport_rect.size.x)
			position = Vector2(spawn_x, -offset)
		
		# Calcola vicinanza ai bordi sinistro/destro (0 = centro, 1 = bordo)
			var edge_proximity = clamp(abs(spawn_x - viewport_rect.size.x/2) / (viewport_rect.size.x/2), 0.0, 1.0)
		
		# Angolo base verso il basso (90°)
			var base_angle = deg_to_rad(90)
		
		# Variazione angolare: ±10° vicino ai bordi, ±45° al centro
			var max_angle_variation = lerp(deg_to_rad(45), deg_to_rad(10), edge_proximity)
			var angle = base_angle + randf_range(-max_angle_variation, max_angle_variation)
		
			velocity = Vector2.RIGHT.rotated(angle) * speed

		1:  # Bottom (Spawn sotto lo schermo)
			var spawn_x = randf_range(0, viewport_rect.size.x)
			position = Vector2(spawn_x, viewport_rect.size.y + offset)
		
			var edge_proximity = clamp(abs(spawn_x - viewport_rect.size.x/2) / (viewport_rect.size.x/2), 0.0, 1.0)
		
		# Angolo base verso l'alto (-90°)
			var base_angle = deg_to_rad(-90)
		
			var max_angle_variation = lerp(deg_to_rad(45), deg_to_rad(10), edge_proximity)
			var angle = base_angle + randf_range(-max_angle_variation, max_angle_variation)
		
			velocity = Vector2.RIGHT.rotated(angle) * speed

		2:  # Left (Spawn a sinistra)
			var spawn_y = randf_range(0, viewport_rect.size.y)
			position = Vector2(-offset, spawn_y)
		
		# Calcola vicinanza ai bordi superiore/inferiore
			var edge_proximity = clamp(abs(spawn_y - viewport_rect.size.y/2) / (viewport_rect.size.y/2), 0.0, 1.0)
		
		# Angolo base verso destra (0°)
			var base_angle = 0.0
		
			var max_angle_variation = lerp(deg_to_rad(45), deg_to_rad(10), edge_proximity)
			var angle = base_angle + randf_range(-max_angle_variation, max_angle_variation)
		
			velocity = Vector2.RIGHT.rotated(angle) * speed

		3:  # Right (Spawn a destra)
			var spawn_y = randf_range(0, viewport_rect.size.y)
			position = Vector2(viewport_rect.size.x + offset, spawn_y)
		
			var edge_proximity = clamp(abs(spawn_y - viewport_rect.size.y/2) / (viewport_rect.size.y/2), 0.0, 1.0)
		
		# Angolo base verso sinistra (180°)
			var base_angle = deg_to_rad(180)
		
			var max_angle_variation = lerp(deg_to_rad(45), deg_to_rad(10), edge_proximity)
			var angle = base_angle + randf_range(-max_angle_variation, max_angle_variation)
		
			velocity = Vector2.RIGHT.rotated(angle) * speed

func _process(delta):
	# Muove l'asteroide in linea retta
	position += velocity * delta
	# Applica la rotazione continua
	rotation += rotation_speed
