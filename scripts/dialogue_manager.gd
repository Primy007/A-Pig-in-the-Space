# dialogue_manager.gd - Autoload per gestire i dialoghi globalmente
extends Node

var textbox: CanvasLayer
var dialogue_data: Dictionary = {}

# Enums
enum Speaker {
	PLAYER,
	CAPTAIN,
	NARRATOR,
	SYSTEM
}

func _ready():
	# Trova o crea la textbox
	_find_textbox()

func _find_textbox():
	"""Trova la textbox nella scena o la crea"""
	var textboxes = get_tree().get_nodes_in_group("textbox")
	if textboxes.size() > 0:
		textbox = textboxes[0]

# FUNZIONI PUBBLICHE - USA QUESTE DAI TUOI SCRIPT

func start_intro_dialogue():
	"""Dialogo di introduzione"""
	if !textbox:
		_find_textbox()
		
	textbox.clear_dialogue_queue()
	textbox.add_dialogue("Benvenuto pilota!", Speaker.SYSTEM)
	textbox.add_dialogue("La tua missione è raccogliere tutti i file di testo sparsi nello spazio.", Speaker.CAPTAIN)
	textbox.add_dialogue("Capito! Sono pronto!", Speaker.PLAYER)

func start_file_collected_dialogue():
	"""Dialogo quando raccogli un file"""
	if !textbox:
		return
		
	var messages = [
		"File raccolto con successo!",
		"Dati acquisiti!",
		"Informazioni salvate!",
		"File aggiunto al database!"
	]
	
	textbox.add_system_message(messages[randi() % messages.size()])

func start_mission_complete_dialogue():
	"""Dialogo di fine missione"""
	if !textbox:
		return
		
	textbox.clear_dialogue_queue()
	textbox.add_dialogue("Missione completata!", Speaker.SYSTEM)
	textbox.add_dialogue("Ottimo lavoro pilota!", Speaker.CAPTAIN)
	textbox.add_dialogue("Tutti i file sono stati recuperati.", Speaker.CAPTAIN)
	textbox.add_dialogue("Grazie capitano!", Speaker.PLAYER)

func start_enemy_encounter_dialogue():
	"""Dialogo quando incontri nemici"""
	if !textbox:
		return
		
	textbox.add_dialogue("Attenzione! Nemici rilevati!", Speaker.SYSTEM)
	textbox.add_dialogue("Preparati al combattimento!", Speaker.CAPTAIN)

func start_low_health_dialogue():
	"""Dialogo quando la salute è bassa"""
	if !textbox:
		return
		
	textbox.add_system_message("Attenzione: Salute critica!", true)

func start_powerup_collected_dialogue(powerup_name: String):
	"""Dialogo quando raccogli un power-up"""
	if !textbox:
		return
		
	textbox.add_system_message("Power-up raccolto: " + powerup_name, true)

func start_area_entered_dialogue(area_name: String):
	"""Dialogo quando entri in una nuova area"""
	if !textbox:
		return
		
	textbox.add_dialogue("Entrando in: " + area_name, Speaker.SYSTEM)

# DIALOGHI PREDEFINITI DA DATI

func load_dialogue_from_data(dialogue_id: String):
	"""Carica dialoghi da dati predefiniti"""
	if !dialogue_data.has(dialogue_id):
		print("Dialogo non trovato: ", dialogue_id)
		return
	
	var dialogue_info = dialogue_data[dialogue_id]
	textbox.clear_dialogue_queue()
	
	for line in dialogue_info.lines:
		var speaker = _string_to_speaker(line.speaker)
		var delay = line.get("delay", 0.0)
		var auto_advance = line.get("auto_advance", false)
		
		textbox.add_dialogue_advanced(line.text, speaker, delay, auto_advance)

func _string_to_speaker(speaker_string: String) -> Speaker:
	"""Converte stringa in enum Speaker"""
	match speaker_string.to_lower():
		"player":
			return Speaker.PLAYER
		"captain":
			return Speaker.CAPTAIN
		"system":
			return Speaker.SYSTEM
		_:
			return Speaker.NARRATOR

# CARICAMENTO DATI DIALOGHI

func setup_dialogue_data():
	"""Configura i dati dei dialoghi predefiniti"""
	dialogue_data = {
		"tutorial_start": {
			"lines": [
				{"text": "Benvenuto nel tutorial!", "speaker": "system"},
				{"text": "Usa WASD per muoverti", "speaker": "narrator", "delay": 1.0},
				{"text": "Usa il mouse per mirare", "speaker": "narrator", "delay": 1.0},
				{"text": "Clicca per sparare", "speaker": "narrator", "delay": 1.0}
			]
		},
		"first_enemy": {
			"lines": [
				{"text": "Primo nemico avvistato!", "speaker": "captain"},
				{"text": "Eliminalo rapidamente!", "speaker": "captain", "delay": 0.5}
			]
		},
		"boss_encounter": {
			"lines": [
				{"text": "Rilevato nemico di grandi dimensioni!", "speaker": "system"},
				{"text": "È il boss finale!", "speaker": "captain"},
				{"text": "Sono pronto ad affrontarlo!", "speaker": "player", "delay": 1.0}
			]
		}
	}

# UTILITY

func is_dialogue_active() -> bool:
	"""Controlla se c'è un dialogo attivo"""
	return textbox and textbox.is_dialogue_active()

func stop_all_dialogues():
	"""Ferma tutti i dialoghi"""
	if textbox:
		textbox.clear_dialogue_queue()
		textbox.hide_textbox()
