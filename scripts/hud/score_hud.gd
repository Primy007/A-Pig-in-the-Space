# score_hud.gd
extends CanvasLayer

@onready var score_label = $ScoreLabel

var game_manager: Node

func _ready():
	# Trova il GameManager
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	if game_manager:
		# Connetti al segnale di cambiamento punteggio
		game_manager.score_changed.connect(_on_score_changed)
		# Imposta il riferimento nel GameManager
		game_manager.set_score_label(score_label)
		# Inizializza il punteggio
		score_label.text = "Score: 0"

func _on_score_changed(new_score: int):
	score_label.text = "Score: " + str(new_score)
	
	# Effetto di "pop" quando il punteggio cambia
	_animate_score_change()

func _animate_score_change():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scala il testo leggermente
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
	
	# Cambia colore temporaneamente
	var original_color = score_label.modulate
	tween.tween_property(score_label, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(score_label, "modulate", original_color, 0.1).set_delay(0.1)
