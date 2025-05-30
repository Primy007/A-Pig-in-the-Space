# textbox.gd - Sistema di dialoghi migliorato
extends CanvasLayer

@onready var textbox_container: MarginContainer = $TextboxContainer
@onready var start: Label = $TextboxContainer/MarginContainer/HBoxContainer/Start
@onready var end: Label = $TextboxContainer/MarginContainer/HBoxContainer/End
@onready var label: Label = $TextboxContainer/MarginContainer/HBoxContainer/Label
@onready var timer: Timer = $Timer
@onready var player_texture: TextureRect = $PlayerTexture
@onready var captain_texture: TextureRect = $CaptainTexture

var full_text: String = ""
var current_index: int = 0

enum State {
	READY,
	READING,
	FINISHED
}

enum Speaker {
	PLAYER,
	CAPTAIN,
	NARRATOR,
	SYSTEM
}

# Struttura per i dialoghi
class DialogueEntry:
	var text: String
	var speaker: Speaker
	var delay_before: float = 0.0  # Pausa prima di mostrare questo dialogo
	var auto_advance: bool = false  # Avanza automaticamente dopo un tempo
	var auto_advance_time: float = 2.0
	
	func _init(p_text: String, p_speaker: Speaker = Speaker.NARRATOR, p_delay: float = 0.0, p_auto: bool = false, p_auto_time: float = 2.0):
		text = p_text
		speaker = p_speaker
		delay_before = p_delay
		auto_advance = p_auto
		auto_advance_time = p_auto_time

var current_state = State.READY
var dialogue_queue: Array[DialogueEntry] = []
var current_dialogue: DialogueEntry
var delay_timer: Timer
var auto_advance_timer: Timer

# Segnali per eventi di dialogo
signal dialogue_started
signal dialogue_finished
signal dialogue_line_finished

func _ready():
	add_to_group("textbox")
	print("starting state: READY")
	
	# ✅ PRIMA controlla che il timer esista
	if timer:
		timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	
	# Setup dei timer DOPO che tutti i nodi sono pronti
	_setup_custom_timers()
	
	# Nascondi la textbox all'inizio
	hide_textbox()
	
	# ESEMPI DI DIALOGHI (chiamali dopo che tutto è inizializzato)
	call_deferred("_setup_example_dialogues")

func _setup_custom_timers():
	"""Setup sicuro dei timer personalizzati"""
	# Setup delay timer
	delay_timer = Timer.new()
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_start_current_dialogue)
	add_child(delay_timer)
	
	# Setup auto advance timer
	auto_advance_timer = Timer.new()
	auto_advance_timer.one_shot = true
	auto_advance_timer.timeout.connect(_auto_advance_dialogue)
	add_child(auto_advance_timer)

func _setup_example_dialogues():
	"""Esempi di come usare il sistema di dialoghi"""
	
	# Esempio 1: Dialogo semplice
	add_dialogue("Benvenuto nel gioco!", Speaker.NARRATOR)
	add_dialogue("Ciao! Sono il capitano della nave.", Speaker.CAPTAIN)
	add_dialogue("Salve capitano, sono pronto per l'avventura!", Speaker.PLAYER)
	
	# Esempio 2: Dialogo con pause e auto-avanzamento
	add_dialogue_advanced("Il sistema è in avvio...", Speaker.SYSTEM, 1.0, true, 3.0)
	add_dialogue_advanced("Caricamento completato.", Speaker.SYSTEM, 0.5, true, 2.0)
	
	# Esempio 3: Conversazione complessa
	start_dialogue_sequence([
		DialogueEntry.new("Abbiamo un problema!", Speaker.CAPTAIN, 0.0),
		DialogueEntry.new("Che tipo di problema?", Speaker.PLAYER, 0.5),
		DialogueEntry.new("I sensori rilevano una anomalia.", Speaker.CAPTAIN, 0.0),
		DialogueEntry.new("Dobbiamo investigare.", Speaker.PLAYER, 1.0)
	])

func _process(delta):
	match current_state:
		State.READY:
			if !dialogue_queue.is_empty():
				_process_next_dialogue()
		State.READING:
			if Input.is_action_just_pressed("proceed"):
				if timer:  # ✅ Controlla che il timer esista
					timer.stop()
				label.text = full_text
				end.text = "v"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("proceed") or (current_dialogue and current_dialogue.auto_advance):
				if current_dialogue and current_dialogue.auto_advance and auto_advance_timer:
					auto_advance_timer.stop()
				_advance_dialogue()

# FUNZIONI PUBBLICHE PER AGGIUNGERE DIALOGHI

func add_dialogue(text: String, speaker: Speaker = Speaker.NARRATOR):
	"""Aggiunge un dialogo semplice alla coda"""
	dialogue_queue.push_back(DialogueEntry.new(text, speaker))

func add_dialogue_advanced(text: String, speaker: Speaker, delay: float = 0.0, auto_advance: bool = false, auto_time: float = 2.0):
	"""Aggiunge un dialogo con opzioni avanzate"""
	dialogue_queue.push_back(DialogueEntry.new(text, speaker, delay, auto_advance, auto_time))

func start_dialogue_sequence(dialogues: Array[DialogueEntry]):
	"""Aggiunge una sequenza di dialoghi alla coda"""
	for dialogue in dialogues:
		dialogue_queue.push_back(dialogue)

func add_system_message(text: String, auto_advance: bool = true):
	"""Aggiunge un messaggio di sistema che si chiude automaticamente"""
	add_dialogue_advanced(text, Speaker.SYSTEM, 0.0, auto_advance, 3.0)

func add_narrator_text(text: String):
	"""Aggiunge testo del narratore"""
	add_dialogue(text, Speaker.NARRATOR)

func add_conversation(player_text: String, captain_text: String, delay_between: float = 0.5):
	"""Aggiunge una conversazione tra player e capitano"""
	add_dialogue(player_text, Speaker.PLAYER)
	add_dialogue_advanced(captain_text, Speaker.CAPTAIN, delay_between)

# FUNZIONI INTERNE

func _process_next_dialogue():
	"""Processa il prossimo dialogo nella coda"""
	if dialogue_queue.is_empty():
		return
	
	current_dialogue = dialogue_queue.pop_front()
	
	if current_dialogue.delay_before > 0 and delay_timer:
		delay_timer.wait_time = current_dialogue.delay_before
		delay_timer.start()
	else:
		_start_current_dialogue()

func _start_current_dialogue():
	"""Inizia a mostrare il dialogo corrente"""
	full_text = current_dialogue.text
	current_index = 0
	label.text = ""
	
	_setup_speaker_visuals(current_dialogue.speaker)
	change_state(State.READING)
	show_textbox()
	
	# ✅ Controlla che il timer esista prima di avviarlo
	if timer:
		timer.start()
	
	dialogue_started.emit()

func _setup_speaker_visuals(speaker: Speaker):
	"""Configura le texture in base al parlante"""
	# ✅ Controlla che le texture esistano prima di nasconderle
	if player_texture:
		player_texture.hide()
	if captain_texture:
		captain_texture.hide()
	
	match speaker:
		Speaker.PLAYER:
			if player_texture:
				player_texture.show()
			if start:
				start.text = "PLAYER:"
		Speaker.CAPTAIN:
			if captain_texture:
				captain_texture.show()
			if start:
				start.text = "CAPTAIN:"
		Speaker.NARRATOR:
			if start:
				start.text = "NARRATOR:"
		Speaker.SYSTEM:
			if start:
				start.text = "SYSTEM:"

func _advance_dialogue():
	"""Avanza al prossimo dialogo o chiude la textbox"""
	dialogue_line_finished.emit()
	
	if !dialogue_queue.is_empty():
		_process_next_dialogue()
	else:
		hide_textbox()
		change_state(State.READY)
		dialogue_finished.emit()

func _auto_advance_dialogue():
	"""Avanza automaticamente il dialogo"""
	_advance_dialogue()

func hide_textbox():
	# ✅ Controlla che tutti i nodi esistano prima di usarli
	if start:
		start.text = ""
	if end:
		end.text = ""
	if label:
		label.text = ""
	if textbox_container:
		textbox_container.hide()
	
	# ✅ Controlla che i timer esistano prima di fermarli
	if timer:
		timer.stop()
	if auto_advance_timer:
		auto_advance_timer.stop()
	
	if player_texture:
		player_texture.hide()
	if captain_texture:
		captain_texture.hide()

func show_textbox():
	if end:
		end.text = ""
	if textbox_container:
		textbox_container.show()

func _on_Timer_timeout():
	if current_index < full_text.length():
		if label:
			label.text += full_text[current_index]
		current_index += 1
	else:
		# Testo completato
		if end:
			end.text = "v"
		if timer:
			timer.stop()
		change_state(State.FINISHED)
		
		# Se è auto-advance, avvia il timer
		if current_dialogue and current_dialogue.auto_advance and auto_advance_timer:
			auto_advance_timer.wait_time = current_dialogue.auto_advance_time
			auto_advance_timer.start()

func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			print("changing state: READY")
		State.READING:
			print("changing state: READING")
		State.FINISHED:
			print("changing state: FINISHED")

# FUNZIONI UTILITY

func clear_dialogue_queue():
	"""Svuota la coda dei dialoghi"""
	dialogue_queue.clear()

func is_dialogue_active() -> bool:
	"""Ritorna true se c'è un dialogo attivo"""
	return current_state != State.READY or !dialogue_queue.is_empty()

func skip_current_dialogue():
	"""Salta il dialogo corrente (utile per debug)"""
	if current_state == State.READING:
		if timer:
			timer.stop()
		if label:
			label.text = full_text
		if end:
			end.text = "v"
		change_state(State.FINISHED)
