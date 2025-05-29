extends CanvasLayer
class_name FiletextIndicatorManager

# Scena dell'indicatore
@export var indicator_scene: PackedScene

# Tracciamento degli indicatori attivi
var active_indicators: Dictionary = {}

# Configurazione
@export var check_frequency: float = 0.5  # Controlla nuovi file di testo ogni 0.5 secondi

# Timer per controlli periodici
var check_timer: float = 0.0

func _ready():
	# Metti questo layer dietro gli altri elementi dell'HUD
	layer = 1

func _process(delta):
	check_timer += delta
	
	if check_timer >= check_frequency:
		check_timer = 0.0
		_check_for_filetexts()
		_cleanup_indicators()

func _check_for_filetexts():
	"""Controlla se ci sono nuovi file di testo da tracciare"""
	var filetexts = get_tree().get_nodes_in_group("filetext")
	
	for filetext in filetexts:
		if !active_indicators.has(filetext):
			_create_indicator_for_filetext(filetext)

func _create_indicator_for_filetext(filetext: Node2D):
	"""Crea un nuovo indicatore per un file di testo"""
	if !indicator_scene:
		printerr("FiletextIndicatorManager: Nessuna scena indicatore assegnata!")
		return
	
	var indicator = indicator_scene.instantiate()
	add_child(indicator)
	indicator.setup(filetext)
	
	active_indicators[filetext] = indicator
	
	# SOLUZIONE: Usa un callable lambda che ignora gli argomenti del segnale
	if filetext.has_signal("file_collected"):
		filetext.file_collected.connect(func(_arg1 = null, _arg2 = null): _remove_indicator_for_filetext(filetext))

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
		if !is_instance_valid(filetext):
			filetexts_to_remove.append(filetext)
	
	for filetext in filetexts_to_remove:
		var indicator = active_indicators[filetext]
		if is_instance_valid(indicator):
			indicator.queue_free()
		active_indicators.erase(filetext)

func clear_all_indicators():
	"""Rimuove tutti gli indicatori (utile per cambi di livello)"""
	for indicator in active_indicators.values():
		if is_instance_valid(indicator):
			indicator.queue_free()
	active_indicators.clear()
