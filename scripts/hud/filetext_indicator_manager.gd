extends CanvasLayer
class_name FiletextIndicatorManager

# Scena dell'indicatore
@export var indicator_scene: PackedScene

# Tracciamento degli indicatori attivi
var active_indicators: Dictionary = {}
var player: Node2D

# Configurazione
@export var check_frequency: float = 0.5

# Timer per controlli periodici
var check_timer: float = 0.0

func _ready():
	layer = 1
	# Carica la scena dell'indicatore se non assegnata
	if not indicator_scene:
		var indicator_path = "res://scenes/hud/filetext_indicator.tscn"
		if ResourceLoader.exists(indicator_path):
			indicator_scene = load(indicator_path)

func _process(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	check_timer += delta
	
	if check_timer >= check_frequency:
		check_timer = 0.0
		_check_for_filetexts()
		_cleanup_indicators()

func _check_for_filetexts():
	"""Controlla se ci sono nuovi file di testo da tracciare"""
	var filetexts = get_tree().get_nodes_in_group("filetext")
	
	for filetext in filetexts:
		if not active_indicators.has(filetext):
			_create_indicator_for_filetext(filetext)

func _create_indicator_for_filetext(filetext: Node2D):
	"""Crea un nuovo indicatore per un file di testo"""
	if not indicator_scene:
		return
	
	var indicator = indicator_scene.instantiate()
	add_child(indicator)
	indicator.setup(filetext)
	
	active_indicators[filetext] = indicator
	
	# Connetti il segnale di raccolta in modo sicuro
	if filetext.has_signal("file_collected"):
		# Usa una connessione che ignora gli argomenti extra
		var callable = func(_content = null): _remove_indicator_for_filetext(filetext)
		filetext.file_collected.connect(callable)

func _remove_indicator_for_filetext(filetext: Node2D):
	"""Rimuove l'indicatore per un filetext specifico"""
	if active_indicators.has(filetext):
		var indicator = active_indicators[filetext]
		if is_instance_valid(indicator):
			indicator.queue_free()
		active_indicators.erase(filetext)

func _cleanup_indicators():
	"""Rimuove gli indicatori per file di testo che non esistono più"""
	var filetexts_to_remove = []
	
	for filetext in active_indicators.keys():
		if not is_instance_valid(filetext):
			filetexts_to_remove.append(filetext)
	
	for filetext in filetexts_to_remove:
		var indicator = active_indicators[filetext]
		if is_instance_valid(indicator):
			indicator.queue_free()
		active_indicators.erase(filetext)

func clear_all_indicators():
	"""Rimuove tutti gli indicatori"""
	for indicator in active_indicators.values():
		if is_instance_valid(indicator):
			indicator.queue_free()
	active_indicators.clear()
