# wave_hud.gd - HUD per il sistema ondate
extends CanvasLayer

@onready var wave_label = $WaveHUD/VBox/WaveLabel
@onready var progress_label = $WaveHUD/VBox/ProgressLabel
@onready var preparation_label = $WaveHUD/VBox/PreparationLabel
@onready var progress_bar = $WaveHUD/VBox/ProgressBar

var preparation_timer: float = 0.0
var is_preparing: bool = false

func _ready():
	# Nascondi l'etichetta di preparazione inizialmente
	preparation_label.visible = false
	
	# Connetti ai segnali del GameManager
	if GameManager:
		GameManager.wave_started.connect(_on_wave_started)
		GameManager.wave_completed.connect(_on_wave_completed)
		GameManager.preparing_next_wave.connect(_on_preparing_next_wave)
		
		# Imposta i valori iniziali
		_update_wave_display()

func _process(delta):
	if is_preparing and preparation_timer > 0:
		preparation_timer -= delta
		preparation_label.text = "Next wave in: " + str(ceil(preparation_timer))
		
		if preparation_timer <= 0:
			is_preparing = false
			preparation_label.visible = false

func _update_wave_display():
	if not GameManager:
		return
		
	var wave_info = GameManager.get_wave_progress()
	
	wave_label.text = "Wave: " + str(wave_info.current_wave)
	
	if wave_info.wave_active:
		progress_label.text = "Enemies: " + str(wave_info.enemies_killed) + "/" + str(wave_info.enemies_total)
		
		# Aggiorna la barra di progresso
		if wave_info.enemies_total > 0:
			progress_bar.value = float(wave_info.enemies_killed) / float(wave_info.enemies_total) * 100
		else:
			progress_bar.value = 0
		
		progress_bar.visible = true
		progress_label.visible = true
	else:
		progress_label.visible = false
		progress_bar.visible = false

func _on_wave_started(wave_number: int):
	print("HUD: Ondata ", wave_number, " iniziata")
	is_preparing = false
	preparation_label.visible = false
	_update_wave_display()

func _on_wave_completed(wave_number: int):
	print("HUD: Ondata ", wave_number, " completata")
	# Mostra brevemente il completamento
	progress_label.text = "WAVE " + str(wave_number) + " COMPLETED!"
	progress_bar.value = 100

func _on_preparing_next_wave(time_left: float):
	print("HUD: Preparando prossima ondata")
	is_preparing = true
	preparation_timer = time_left
	preparation_label.visible = true
	preparation_label.text = "Next wave in: " + str(ceil(time_left))

# Chiamata periodica per aggiornare il progresso durante l'ondata
func _on_timer_timeout():
	_update_wave_display()

# Aggiungi un timer per aggiornamenti periodici
func _enter_tree():
	var update_timer = Timer.new()
	update_timer.wait_time = 0.1  # Aggiorna ogni 100ms
	update_timer.timeout.connect(_on_timer_timeout)
	update_timer.autostart = true
	add_child(update_timer)
