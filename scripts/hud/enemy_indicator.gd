extends Control
class_name EnemyIndicator

# Riferimenti ai nodi
@onready var arrow_sprite: Sprite2D = $ArrowSprite
@onready var alert_icon: Sprite2D = $AlertIcon
@onready var distance_label: Label = $DistanceLabel

# Configurazione
@export var margin_from_edge: float = 50.0
@export var max_distance_display: float = 2000.0

# Variabili interne
var target_enemy: Node2D
var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	visible = false

func _process(_delta):
	_update_indicator()

func setup(enemy: Node2D):
	"""Configura l'indicatore per un nemico specifico"""
	target_enemy = enemy
	visible = true

func _update_indicator():
	# Verifica validità
	if not is_instance_valid(target_enemy) or not is_instance_valid(player):
		queue_free()
		return
	
	# Usa la camera attuale
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	# Calcola se il nemico è sullo schermo usando metodo semplificato
	if _is_enemy_visible_simple():
		visible = false
		return
	else:
		visible = true
	
	# Posiziona l'indicatore
	_position_indicator()
	
	# Ruota la freccia
	_rotate_arrow()
	
	# Aggiorna distanza
	_update_distance()

func _is_enemy_visible_simple() -> bool:
	"""Metodo semplificato per verificare se il nemico è visibile"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return false
	
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.global_position
	var zoom = camera.zoom.x  # Usa solo x per semplicità
	
	# Calcola i bounds della camera
	var half_width = (viewport_size.x / zoom) * 0.5
	var half_height = (viewport_size.y / zoom) * 0.5
	
	var left = camera_pos.x - half_width
	var right = camera_pos.x + half_width
	var top = camera_pos.y - half_height
	var bottom = camera_pos.y + half_height
	
	var enemy_pos = target_enemy.global_position
	
	return enemy_pos.x >= left and enemy_pos.x <= right and \
		   enemy_pos.y >= top and enemy_pos.y <= bottom

func _position_indicator():
	"""Posiziona l'indicatore sui bordi dello schermo"""
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size * 0.5
	
	# Direzione verso il nemico
	var direction = (target_enemy.global_position - player.global_position).normalized()
	
	# Calcola posizione sui bordi (metodo semplificato)
	var edge_pos = Vector2.ZERO
	
	# Trova il punto di intersezione più semplice
	var abs_dir_x = abs(direction.x)
	var abs_dir_y = abs(direction.y)
	
	if abs_dir_x > abs_dir_y:
		# Bordo sinistro o destro
		if direction.x > 0:
			edge_pos.x = viewport_size.x - margin_from_edge
		else:
			edge_pos.x = margin_from_edge
		edge_pos.y = center.y + (direction.y / abs_dir_x) * (viewport_size.x * 0.5 - margin_from_edge)
	else:
		# Bordo superiore o inferiore
		if direction.y > 0:
			edge_pos.y = viewport_size.y - margin_from_edge
		else:
			edge_pos.y = margin_from_edge
		edge_pos.x = center.x + (direction.x / abs_dir_y) * (viewport_size.y * 0.5 - margin_from_edge)
	
	# Clamp per sicurezza
	edge_pos.x = clamp(edge_pos.x, margin_from_edge, viewport_size.x - margin_from_edge)
	edge_pos.y = clamp(edge_pos.y, margin_from_edge, viewport_size.y - margin_from_edge)
	
	global_position = edge_pos

func _rotate_arrow():
	"""Ruota la freccia verso il nemico"""
	var direction = (target_enemy.global_position - player.global_position).normalized()
	arrow_sprite.rotation = direction.angle() + PI/2
	
	# Posiziona l'icona dietro la freccia
	alert_icon.position = -direction * 70.0

func _update_distance():
	"""Aggiorna la distanza"""
	var distance = player.global_position.distance_to(target_enemy.global_position)
	# Converti in "metri" per display
	var distance_m = max(0, (distance - 500) / 10)
	distance_label.text = str(int(distance_m)) + "m"
