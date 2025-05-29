extends CanvasLayer
class_name EnemyIndicatorManager

# Scena dell'indicatore
@export var indicator_scene: PackedScene

# Tracciamento degli indicatori attivi
var active_indicators: Dictionary = {}

# Configurazione
@export var check_frequency: float = 0.5  # Controlla nuovi nemici ogni 0.5 secondi

# Timer per controlli periodici
var check_timer: float = 0.0

func _ready():
	# Assicurati che questo CanvasLayer sia sopra gli altri
	layer = 100

func _process(delta):
	check_timer += delta
	
	if check_timer >= check_frequency:
		check_timer = 0.0
		_check_for_enemies()
		_cleanup_indicators()

func _check_for_enemies():
	"""Controlla se ci sono nuovi nemici da tracciare"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if !active_indicators.has(enemy):
			_create_indicator_for_enemy(enemy)

func _create_indicator_for_enemy(enemy: Node2D):
	"""Crea un nuovo indicatore per un nemico"""
	if !indicator_scene:
		printerr("EnemyIndicatorManager: Nessuna scena indicatore assegnata!")
		return
	
	var indicator = indicator_scene.instantiate()
	add_child(indicator)
	indicator.setup(enemy)
	
	active_indicators[enemy] = indicator

func _cleanup_indicators():
	"""Rimuove gli indicatori per nemici che non esistono più"""
	var enemies_to_remove = []
	
	for enemy in active_indicators.keys():
		if !is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
	
	for enemy in enemies_to_remove:
		var indicator = active_indicators[enemy]
		if is_instance_valid(indicator):
			indicator.queue_free()
		active_indicators.erase(enemy)

func clear_all_indicators():
	"""Rimuove tutti gli indicatori (utile per cambi di livello)"""
	for indicator in active_indicators.values():
		if is_instance_valid(indicator):
			indicator.queue_free()
	active_indicators.clear()
