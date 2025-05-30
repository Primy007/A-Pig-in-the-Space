# textbox.gd - Sistema di dialoghi ottimizzato e sicuro
extends CanvasLayer

# Nodi della UI
@onready var textbox_container: MarginContainer = $TextboxContainer
@onready var start_label: Label = $TextboxContainer/MarginContainer/VBoxContainer/Start
@onready var end_label: Label = $TextboxContainer/MarginContainer/VBoxContainer/HBoxContainer/End
@onready var text_label: Label = $TextboxContainer/MarginContainer/VBoxContainer/HBoxContainer/Label
@onready var typing_timer: Timer = $Timer
@onready var player_texture: TextureRect = $PlayerTexture
@onready var captain_texture: TextureRect = $CaptainTexture

# Timer personalizzati (creati dinamicamente)
var delay_timer: Timer
var auto_advance_timer: Timer

# Variabili del testo
var full_text: String = ""
var current_char_index: int = 0
var typing_speed: float = 0.05

# Stati e controllo
enum DialogueState {
	IDLE,
	TYPING,
	WAITING_FOR_INPUT,
	PROCESSING_QUEUE
}

enum SpeakerType {
	PLAYER,
	CAPTAIN, 
	NARRATOR,
	SYSTEM
}

var current_state: DialogueState = DialogueState.IDLE
var dialogue_queue: Array[DialogueData] = []
var current_dialogue: DialogueData
var is_ready: bool = false

# Classe per gestire i dati del dialogo
class DialogueData:
	var text: String
	var speaker: SpeakerType
	var delay_before: float
	var auto_advance: bool
	var auto_advance_time: float
	
	func _init(p_text: String, p_speaker: SpeakerType = SpeakerType.NARRATOR, 
			   p_delay: float = 0.0, p_auto: bool = false, p_auto_time: float = 2.5):
		text = p_text
		speaker = p_speaker
		delay_before = p_delay
		auto_advance = p_auto
		auto_advance_time = p_auto_time

# Segnali
signal dialogue_started
signal dialogue_finished
signal dialogue_line_completed
signal textbox_hidden
signal textbox_shown

func _ready():
	add_to_group("textbox")
	_setup_initial_state()
	_create_custom_timers()
	_connect_signals()
	
	# Attendi un frame per essere sicuri che tutto sia inizializzato
	await get_tree().process_frame
	is_ready = true
	_debug_print("Textbox system ready")

func _setup_initial_state():
	"""Configura lo stato iniziale"""
	current_state = DialogueState.IDLE
	hide_textbox()
	_debug_print("Initial state setup complete")

func _create_custom_timers():
	"""Crea i timer personalizzati in modo sicuro"""
	# Timer per i delay
	delay_timer = Timer.new()
	delay_timer.name = "DelayTimer"
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_on_delay_timer_timeout)
	add_child(delay_timer)
	
	# Timer per l'auto-advance
	auto_advance_timer = Timer.new()
	auto_advance_timer.name = "AutoAdvanceTimer"
	auto_advance_timer.one_shot = true
	auto_advance_timer.timeout.connect(_on_auto_advance_timer_timeout)
	add_child(auto_advance_timer)
	
	_debug_print("Custom timers created")

func _connect_signals():
	"""Connette i segnali in modo sicuro"""
	if typing_timer:
		if not typing_timer.timeout.is_connected(_on_typing_timer_timeout):
			typing_timer.timeout.connect(_on_typing_timer_timeout)
		typing_timer.wait_time = typing_speed

func _process(_delta):
	if not is_ready:
		return
		
	_handle_input()
	_process_dialogue_queue()

func _handle_input():
	"""Gestisce l'input del giocatore"""
	if not Input.is_action_just_pressed("proceed"):
		return
		
	match current_state:
		DialogueState.TYPING:
			_skip_typing()
		DialogueState.WAITING_FOR_INPUT:
			_advance_to_next_dialogue()

func _process_dialogue_queue():
	"""Processa la coda dei dialoghi"""
	if current_state == DialogueState.IDLE and not dialogue_queue.is_empty():
		current_state = DialogueState.PROCESSING_QUEUE
		_start_next_dialogue()

# =============================================================================
# FUNZIONI PUBBLICHE - API per aggiungere dialoghi
# =============================================================================

func add_dialogue(text: String, speaker: SpeakerType = SpeakerType.NARRATOR):
	"""Aggiunge un dialogo semplice"""
	if text.is_empty():
		_debug_print("Warning: Empty dialogue text")
		return
		
	dialogue_queue.push_back(DialogueData.new(text, speaker))
	_debug_print("Added dialogue: " + text.substr(0, 30) + "...")

func add_system_message(text: String, auto_close: bool = true):
	"""Aggiunge un messaggio di sistema"""
	add_dialogue_advanced(text, SpeakerType.SYSTEM, 0.0, auto_close, 3.0)

func add_dialogue_advanced(text: String, speaker: SpeakerType, delay: float = 0.0, 
						  auto_advance: bool = false, auto_time: float = 2.5):
	"""Aggiunge un dialogo con opzioni avanzate"""
	if text.is_empty():
		_debug_print("Warning: Empty dialogue text")
		return
		
	dialogue_queue.push_back(DialogueData.new(text, speaker, delay, auto_advance, auto_time))

func add_conversation(player_text: String, npc_text: String, speaker: SpeakerType = SpeakerType.CAPTAIN):
	"""Aggiunge una conversazione rapida"""
	add_dialogue(player_text, SpeakerType.PLAYER)
	add_dialogue_advanced(npc_text, speaker, 0.5)

func clear_dialogue_queue():
	"""Svuota la coda dei dialoghi"""
	var count = dialogue_queue.size()
	dialogue_queue.clear()
	_debug_print("Cleared " + str(count) + " dialogues from queue")

func is_dialogue_active() -> bool:
	"""Controlla se il sistema di dialoghi è attivo"""
	return current_state != DialogueState.IDLE or not dialogue_queue.is_empty()

func force_close():
	"""Forza la chiusura del sistema di dialoghi"""
	_stop_all_timers()
	dialogue_queue.clear()
	hide_textbox()
	current_state = DialogueState.IDLE
	_debug_print("Dialogue system force closed")

# =============================================================================
# FUNZIONI INTERNE - Gestione dei dialoghi
# =============================================================================

func _start_next_dialogue():
	"""Inizia il prossimo dialogo nella coda"""
	if dialogue_queue.is_empty():
		_finish_all_dialogues()
		return
	
	current_dialogue = dialogue_queue.pop_front()
	
	if current_dialogue.delay_before > 0.0:
		delay_timer.wait_time = current_dialogue.delay_before
		delay_timer.start()
	else:
		_display_current_dialogue()

func _display_current_dialogue():
	"""Mostra il dialogo corrente"""
	if not current_dialogue:
		_debug_print("Error: No current dialogue to display")
		return
	
	full_text = current_dialogue.text
	current_char_index = 0
	
	_setup_speaker_display(current_dialogue.speaker)
	_clear_text_display()
	show_textbox()
	
	current_state = DialogueState.TYPING
	_start_typing()
	
	dialogue_started.emit()

func _start_typing():
	"""Inizia l'animazione di scrittura"""
	if text_label:
		text_label.text = ""
	if end_label:
		end_label.text = ""
	
	if typing_timer:
		typing_timer.start()

func _skip_typing():
	"""Salta l'animazione di scrittura"""
	if typing_timer:
		typing_timer.stop()
	
	if text_label and not full_text.is_empty():
		text_label.text = full_text
	
	_finish_typing()

func _finish_typing():
	"""Completa l'animazione di scrittura"""
	current_state = DialogueState.WAITING_FOR_INPUT
	
	if end_label:
		end_label.text = "v"
	
	# Setup auto-advance se necessario
	if current_dialogue and current_dialogue.auto_advance:
		auto_advance_timer.wait_time = current_dialogue.auto_advance_time
		auto_advance_timer.start()
	
	dialogue_line_completed.emit()

func _advance_to_next_dialogue():
	"""Avanza al prossimo dialogo"""
	if auto_advance_timer:
		auto_advance_timer.stop()
	
	current_state = DialogueState.PROCESSING_QUEUE
	_start_next_dialogue()

func _finish_all_dialogues():
	"""Termina tutti i dialoghi e chiude la textbox"""
	hide_textbox()
	current_state = DialogueState.IDLE
	current_dialogue = null
	dialogue_finished.emit()
	_debug_print("All dialogues finished")

# =============================================================================
# FUNZIONI UI - Gestione dell'interfaccia
# =============================================================================

func show_textbox():
	"""Mostra la textbox"""
	if textbox_container:
		textbox_container.show()
		textbox_shown.emit()

func hide_textbox():
	"""Nasconde la textbox"""
	_stop_all_timers()
	_clear_all_display()
	
	if textbox_container:
		textbox_container.hide()
	
	_hide_speaker_textures()
	textbox_hidden.emit()

func _clear_all_display():
	"""Pulisce tutti gli elementi di testo"""
	if start_label:
		start_label.text = ""
	if text_label:
		text_label.text = ""
	if end_label:
		end_label.text = ""

func _clear_text_display():
	"""Pulisce solo il testo principale"""
	if text_label:
		text_label.text = ""
	if end_label:
		end_label.text = ""

func _setup_speaker_display(speaker: SpeakerType):
	"""Configura la visualizzazione in base al parlante"""
	_hide_speaker_textures()
	
	if not start_label:
		return
	
	match speaker:
		SpeakerType.PLAYER:
			start_label.text = "PLAYER:"
			if player_texture:
				player_texture.show()
		SpeakerType.CAPTAIN:
			start_label.text = "CAPTAIN:"
			if captain_texture:
				captain_texture.show()
		SpeakerType.NARRATOR:
			start_label.text = "NARRATOR:"
		SpeakerType.SYSTEM:
			start_label.text = "SYSTEM:"

func _hide_speaker_textures():
	"""Nasconde tutte le texture dei personaggi"""
	if player_texture:
		player_texture.hide()
	if captain_texture:
		captain_texture.hide()

# =============================================================================
# CALLBACK DEI TIMER
# =============================================================================

func _on_typing_timer_timeout():
	"""Callback del timer di scrittura"""
	if current_char_index < full_text.length():
		if text_label:
			text_label.text += full_text[current_char_index]
		current_char_index += 1
	else:
		_finish_typing()

func _on_delay_timer_timeout():
	"""Callback del timer di delay"""
	_display_current_dialogue()

func _on_auto_advance_timer_timeout():
	"""Callback del timer di auto-advance"""
	_advance_to_next_dialogue()

# =============================================================================
# UTILITY E DEBUG
# =============================================================================

func _stop_all_timers():
	"""Ferma tutti i timer"""
	if typing_timer:
		typing_timer.stop()
	if delay_timer:
		delay_timer.stop()
	if auto_advance_timer:
		auto_advance_timer.stop()

func _debug_print(message: String):
	"""Stampa messaggi di debug"""
	print("[Textbox] ", message)

func get_dialogue_queue_size() -> int:
	"""Ritorna il numero di dialoghi in coda"""
	return dialogue_queue.size()

func set_typing_speed(new_speed: float):
	"""Cambia la velocità di scrittura"""
	typing_speed = clamp(new_speed, 0.01, 1.0)
	if typing_timer:
		typing_timer.wait_time = typing_speed

# =============================================================================
# ESEMPI E TEST (rimuovi in produzione)
# =============================================================================

func _test_dialogues():
	"""Funzione di test - rimuovi in produzione"""
	add_dialogue("Benvenuto nel gioco!", SpeakerType.SYSTEM)
	add_dialogue("Ciao pilota! Sono il capitano.", SpeakerType.CAPTAIN)
	add_dialogue("Salve capitano, pronto per la missione!", SpeakerType.PLAYER)
	add_system_message("Sistema di dialoghi attivo", true)
