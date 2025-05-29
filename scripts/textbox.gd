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

var current_state = State.READY
var text_queue = []

func _ready():
	add_to_group("textbox")  # Aggiungi questa riga
	print("starting state: READY")
	hide_textbox()
	timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	
	# TEST: metto in coda
	queue_text("First text queued up!")
	queue_text("Second text queued up!")
	queue_text("Third text queued up!")
	queue_text("Fourth text queued up!")
	
	# Avvio il primo testo subito
	if !text_queue.is_empty():
		display_text()

func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if Input.is_action_just_pressed("proceed"):
				timer.stop()
				label.text = full_text
				end.text = "v"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("proceed"):
				if !text_queue.is_empty():
					display_text()
				else:
					hide_textbox()
					change_state(State.READY)

func queue_text(next_text):
	text_queue.push_back(next_text)

func hide_player_texture():
	player_texture.hide()

func show_player_texture():
	player_texture.show()

func hide_textbox():
	start.text = ""
	end.text = ""
	label.text = ""
	textbox_container.hide()
	timer.stop()
	
	player_texture.hide() #provvisorio
	captain_texture.hide()

func show_textbox():
	start.text = "*"
	end.text = ""
	textbox_container.show()
	# Il timer lo avvieremo in show_text()
	
	player_texture.show() #provvisorio
	captain_texture.show()

func display_text():
	var next_text = text_queue.pop_front()
	full_text = next_text
	current_index = 0
	label.text = ""
	change_state(State.READING)
	show_textbox()
	timer.start()

func _on_Timer_timeout():
	if current_index < full_text.length():
		label.text += full_text[current_index]
		current_index += 1
	else:
		# testo completato: mostra l'asterisco di fine e ferma il timer
		end.text = "v"
		timer.stop()
		change_state(State.FINISHED)

func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			print("changing state: READY")
		State.READING:
			print("changing state: READING")
		State.FINISHED:
			print("changing state: FINISHED")
