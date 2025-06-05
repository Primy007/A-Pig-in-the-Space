extends Control
class_name FiletextIndicator

# Riferimenti ai nodi
@onready var arrow_sprite: Sprite2D = $ArrowSprite
@onready var file_icon: Sprite2D = $FileIcon
@onready var distance_label: Label = $DistanceLabel

# Configurazione
@export var margin_from_edge: float = 50.0

# Variabili interne
var target_filetext: Node2D
var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	visible = false

func _process(_delta):
	_update_indicator()

func setup(filetext: Node2D):
	"""Configura l'indicatore per un file di testo specifico"""
	target_filetext = filetext
	visible = true

func _update_indicator():
	# Verifica validità
	if not is_instance_valid(target_filetext) or not is_instance_valid(player):
		queue_free()
		return
	
	# Usa la camera attuale
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	# Calcola se il file di testo è sullo schermo
	if _is_filetext_visible_simple():
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

func _is_filetext_visible_simple() -> bool:
	"""Metodo semplificato per verificare se il file di testo è visibile"""
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
	
	var filetext_pos = target_filetext.global_position
	
	return filetext_pos.x >= left and filetext_pos.x <= right and \
		   filetext_pos.y >= top and filetext_pos.y <= bottom

func _position_indicator():
	"""Posiziona l'indicatore sui bordi dello schermo"""
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size * 0.5
	
	# Direzione verso il file di testo
	var direction = (target_filetext.global_position - player.global_position).normalized()
	
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
	"""Ruota la freccia verso il file di testo"""
	var direction = (target_filetext.global_position - player.global_position).normalized()
	arrow_sprite.rotation = direction.angle() + PI/2
	
	# Posiziona l'icona dietro la freccia
	file_icon.position = -direction * 40.0

func _update_distance():
	"""Aggiorna la distanza"""
	var distance = player.global_position.distance_to(target_filetext.global_position)
	# Converti in "metri" per display
	var distance_m = max(0, (distance - 500) / 10)
	distance_label.text = str(int(distance_m)) + "m"
