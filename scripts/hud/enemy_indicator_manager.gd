extends CanvasLayer
class_name EnemyIndicatorManager

# Scena dell'indicatore
@export var indicator_scene: PackedScene

# Tracciamento degli indicatori attivi
var active_indicators: Dictionary = {}
var player: Node2D

# Configurazione
@export var check_frequency: float = 0.5
@export var margin_from_edge: float = 50.0

# Timer per controlli periodici
var check_timer: float = 0.0

func _ready():
	layer = 1
	# Carica la scena dell'indicatore se non assegnata
	if not indicator_scene:
		var indicator_path = "res://scenes/hud/enemy_indicator.tscn"
		if ResourceLoader.exists(indicator_path):
			indicator_scene = load(indicator_path)

func _process(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	check_timer += delta
	
	if check_timer >= check_frequency:
		check_timer = 0.0
		_check_for_enemies()
		_cleanup_indicators()

func _check_for_enemies():
	"""Controlla se ci sono nuovi nemici da tracciare"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not active_indicators.has(enemy):
			_create_indicator_for_enemy(enemy)

func _create_indicator_for_enemy(enemy: Node2D):
	"""Crea un nuovo indicatore per un nemico"""
	if not indicator_scene:
		return
	
	var indicator = indicator_scene.instantiate()
	add_child(indicator)
	indicator.setup(enemy)
	
	active_indicators[enemy] = indicator

func _cleanup_indicators():
	"""Rimuove gli indicatori per nemici che non esistono più"""
	var enemies_to_remove = []
	
	for enemy in active_indicators.keys():
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
	
	for enemy in enemies_to_remove:
		var indicator = active_indicators[enemy]
		if is_instance_valid(indicator):
			indicator.queue_free()
		active_indicators.erase(enemy)

func clear_all_indicators():
	"""Rimuove tutti gli indicatori"""
	for indicator in active_indicators.values():
		if is_instance_valid(indicator):
			indicator.queue_free()
	active_indicators.clear()
