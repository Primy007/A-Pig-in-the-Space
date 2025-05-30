extends Control

@onready var studio_label: Label = $StudioLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

# Durata delle animazioni in secondi
const FADE_IN_DURATION = 1.0
const DISPLAY_DURATION = 2.0
const FADE_OUT_DURATION = 1.0
const SCENE_TRANSITION_DURATION = 1.0

func _ready():
	# Imposta il setup iniziale
	setup_initial_state()
	
	# Avvia la sequenza di animazioni
	start_splash_sequence()

func setup_initial_state():
	# Il testo inizia trasparente
	studio_label.modulate.a = 0.0
	
	# L'overlay inizia trasparente (schermo visibile)
	fade_overlay.modulate.a = 0.0
	fade_overlay.color = Color.BLACK

func start_splash_sequence():
	# Sequenza: Fade in del testo → Attesa → Fade out del testo → Transizione alla scena principale
	
	# 1. Fade in del testo
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(studio_label, "modulate:a", 1.0, FADE_IN_DURATION)
	fade_in_tween.tween_interval(DISPLAY_DURATION)
	
	# 2. Fade out del testo
	fade_in_tween.tween_property(studio_label, "modulate:a", 0.0, FADE_OUT_DURATION)
	
	# 3. Fade to black
	fade_in_tween.tween_property(fade_overlay, "modulate:a", 1.0, SCENE_TRANSITION_DURATION)
	
	# 4. Carica la scena principale
	fade_in_tween.tween_callback(load_main_scene)

func load_main_scene():
	# Cambia alla scena principale
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# Permetti di saltare la splash screen premendo un tasto
func _input(event):
	if event.is_pressed():
		skip_splash()

func skip_splash():
	# Ferma tutti i tween attivi
	get_tree().create_tween().kill()
	
	# Vai direttamente alla scena principale
	load_main_scene()
