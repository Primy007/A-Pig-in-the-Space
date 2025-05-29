extends Control
class_name EnemyIndicator

# Riferimenti ai nodi
@onready var arrow_sprite: Sprite2D = $ArrowSprite
@onready var alert_icon: Sprite2D = $AlertIcon
@onready var distance_label: Label = $DistanceLabel

# Configurazione
@export var margin_from_edge: float = 50.0
@export var update_frequency: float = 0.1  # Aggiorna ogni 0.1 secondi per performance

# Variabili interne
var target_enemy: Node2D
var player: Node2D
var screen_size: Vector2
var update_timer: float = 0.0

func _ready():
	# Ottieni riferimenti
	player = get_tree().get_first_node_in_group("player")
	screen_size = get_viewport().get_visible_rect().size
	
	# Nascondi inizialmente
	visible = false

func _process(delta):
	update_timer += delta
	
	# Aggiorna solo ogni update_frequency secondi per ottimizzare
	if update_timer >= update_frequency:
		update_timer = 0.0
		_update_indicator()

func setup(enemy: Node2D):
	"""Configura l'indicatore per un nemico specifico"""
	target_enemy = enemy
	visible = true

func _update_indicator():
	# Verifica se il nemico e il player esistono ancora
	if !is_instance_valid(target_enemy) or !is_instance_valid(player):
		queue_free()
		return
	
	# Calcola se il nemico è visibile sullo schermo
	var camera = get_viewport().get_camera_2d()
	if !camera:
		return
		
	var enemy_screen_pos = camera.to_screen_coords_no_centering(target_enemy.global_position)
	
	# Se il nemico è visibile, nascondi l'indicatore
	if _is_enemy_on_screen(enemy_screen_pos):
		visible = false
		return
	else:
		visible = true
	
	# Calcola la posizione dell'indicatore sui bordi dello schermo
	var indicator_pos = _calculate_edge_position(enemy_screen_pos)
	global_position = indicator_pos
	
	# Ruota la freccia verso il nemico
	_rotate_arrow_to_enemy()
	
	# Aggiorna la distanza
	_update_distance()

func _is_enemy_on_screen(enemy_screen_pos: Vector2) -> bool:
	"""Verifica se il nemico è visibile sullo schermo"""
	return enemy_screen_pos.x >= 0 and enemy_screen_pos.x <= screen_size.x and \
		   enemy_screen_pos.y >= 0 and enemy_screen_pos.y <= screen_size.y

func _calculate_edge_position(enemy_screen_pos: Vector2) -> Vector2:
	"""Calcola la posizione dell'indicatore sui bordi dello schermo"""
	var center = screen_size * 0.5
	var direction = (enemy_screen_pos - center).normalized()
	
	# Calcola l'intersezione con i bordi dello schermo
	var edge_pos: Vector2
	
	# Margini utilizzabili
	var left_margin = margin_from_edge
	var right_margin = screen_size.x - margin_from_edge
	var top_margin = margin_from_edge
	var bottom_margin = screen_size.y - margin_from_edge
	
	# Trova quale bordo interseca per primo
	var t_x = INF
	var t_y = INF
	
	if direction.x != 0:
		if direction.x > 0:
			t_x = (right_margin - center.x) / direction.x
		else:
			t_x = (left_margin - center.x) / direction.x
	
	if direction.y != 0:
		if direction.y > 0:
			t_y = (bottom_margin - center.y) / direction.y
		else:
			t_y = (top_margin - center.y) / direction.y
	
	# Usa il tempo minimo (primo bordo raggiunto)
	var t = min(t_x, t_y)
	edge_pos = center + direction * t
	
	# Assicurati che rimanga nei limiti
	edge_pos.x = clamp(edge_pos.x, left_margin, right_margin)
	edge_pos.y = clamp(edge_pos.y, top_margin, bottom_margin)
	
	return edge_pos

func _rotate_arrow_to_enemy():
	"""Ruota la freccia per puntare verso il nemico"""
	var direction_to_enemy = (target_enemy.global_position - player.global_position).normalized()
	arrow_sprite.rotation = direction_to_enemy.angle() + PI/2

func _update_distance():
	"""Aggiorna il testo della distanza"""
	var distance = player.global_position.distance_to(target_enemy.global_position)
	distance_label.text = str(int(distance)) + "m"
