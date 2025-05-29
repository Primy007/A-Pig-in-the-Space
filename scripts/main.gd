extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Aggiungi il manager per gli indicatori dei nemici
	var indicator_manager = preload("res://scenes/HUD/indicator_manager.tscn").instantiate()
	add_child(indicator_manager)
	
	# Aggiungi il manager per gli indicatori dei file di testo
	var filetext_indicator_manager = preload("res://scenes/HUD/filetext_indicator_manager.tscn").instantiate()
	add_child(filetext_indicator_manager)  # ✅ CORRETTO: aggiungi filetext_indicator_manager

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
