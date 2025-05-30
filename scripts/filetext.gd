# filetext.gd - Script aggiornato per integrarsi con il sistema di ondate
extends Area2D
class_name FileText

# Configurazione del testo
@export var text_content: String = "Default text content"
@export var collected: bool = false
@export var is_wave_completion_file: bool = true  # ✅ NUOVO: indica se è un file di completamento ondata

# Segnali
signal file_collected(content: String)

# Riferimenti ai nodi
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Riferimenti ai manager
var wave_manager: Node
var dialogue_manager: Node

func _ready():
	# Aggiungi al gruppo dei file di testo
	add_to_group("filetext")
	
	# Connetti il segnale di collisione
	body_entered.connect(_on_body_entered)
	
	# Trova i manager
	_find_managers()
	
	# Se già raccolto, nascondi
	if collected:
		hide()

func _find_managers():
	"""Trova i manager necessari"""
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	dialogue_manager = get_node("/root/DialogueManager")

func _on_body_entered(body):
	# Verifica se è il player
	if body.is_in_group("player") and not collected:
		collect()

func collect():
	"""Raccoglie il file di testo"""
	if collected:
		return
		
	collected = true
	
	# Emetti il segnale con il contenuto del testo
	file_collected.emit(text_content)
	
	# ✅ GESTIONE MIGLIORATA: Mostra il dialogo in base al tipo di file
	_show_collection_dialogue()
	
	# ✅ NUOVO: Notifica specificamente se è un file di completamento ondata
	if is_wave_completion_file:
		_handle_wave_completion_file()
	
	# Nascondi o rimuovi l'oggetto
	queue_free()

func _show_collection_dialogue():
	"""Mostra il dialogo appropriato per la raccolta del file"""
	var textbox = get_tree().get_first_node_in_group("textbox")
	if textbox:
		if is_wave_completion_file:
			# File di completamento ondata - mostra contenuto come dialogo importante
			textbox.add_dialogue("File di missione raccolto!", textbox.SpeakerType.SYSTEM)
			textbox.add_dialogue(text_content, textbox.SpeakerType.NARRATOR)
			
			# Messaggio del capitano
			if wave_manager and wave_manager.get_current_wave() < wave_manager.get_total_waves():
				textbox.add_dialogue("Preparati per la prossima ondata!", textbox.SpeakerType.CAPTAIN)
			else:
				textbox.add_dialogue("Ottimo lavoro pilota! Missione completata!", textbox.SpeakerType.CAPTAIN)
		else:
			# File normale - messaggio semplice
			textbox.add_system_message("File raccolto: " + text_content)

func _handle_wave_completion_file():
	"""Gestisce la raccolta di un file di completamento ondata"""
	# Usa il DialogueManager per eventi speciali se necessario
	if dialogue_manager:
		dialogue_manager.start_file_collected_dialogue()
	
	# Statistiche o altri effetti speciali possono essere aggiunti qui
	print("[FileText] File di completamento ondata raccolto: ", text_content)

func set_text_content(content: String):
	"""Imposta il contenuto del testo"""
	text_content = content

func set_as_wave_completion_file(content: String):
	"""Configura questo file come file di completamento ondata"""
	is_wave_completion_file = true
	text_content = content

func set_as_regular_file(content: String):
	"""Configura questo file come file normale"""
	is_wave_completion_file = false
	text_content = content

# ✅ NUOVE FUNZIONI UTILITY

func create_wave_completion_file(wave_number: int, custom_content: String = "") -> FileText:
	"""Funzione statica per creare un file di completamento ondata"""
	var default_content = "Ondata " + str(wave_number) + " completata con successo!"
	var content = custom_content if not custom_content.is_empty() else default_content
	
	set_as_wave_completion_file(content)
	return self

func add_collection_effect():
	"""Aggiunge effetti visivi alla raccolta (opzionale)"""
	# Potresti aggiungere una piccola animazione o effetto particellare
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
