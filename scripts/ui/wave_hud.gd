# wave_hud.gd - HUD SEMPLIFICATO per ondate immediate
extends CanvasLayer

@onready var wave_label = $WaveHUD/VBox/WaveLabel
@onready var progress_label = $WaveHUD/VBox/ProgressLabel
@onready var progress_bar = $WaveHUD/VBox/ProgressBar

func _ready():
	# Connetti ai segnali del GameManager
	if GameManager:
		GameManager.wave_started.connect(_on_wave_started)
		GameManager.wave_completed.connect(_on_wave_completed)
		
		# Imposta i valori iniziali
		_update_wave_display()

func _process(delta):
	# Aggiorna continuamente il display durante l'ondata attiva
	if GameManager and GameManager.wave_active:
		_update_wave_display()

func _update_wave_display():
	if not GameManager:
		return
		
	var wave_info = GameManager.get_wave_progress()
	
	wave_label.text = "Wave: " + str(wave_info.current_wave)
	
	if wave_info.wave_active:
		# Conta i nemici vivi in tempo reale
		var alive_enemies = get_tree().get_nodes_in_group("enemies").size()
		var total = wave_info.enemies_total
		var spawned = wave_info.get("enemies_spawned", 0)
		
		progress_label.text = "Enemies alive: " + str(alive_enemies) + "/" + str(total) + " (Spawned: " + str(spawned) + ")"
		
		# Barra di progresso basata su nemici rimanenti
		if total > 0:
			progress_bar.value = float(total - alive_enemies) / float(total) * 100
		else:
			progress_bar.value = 0
		
		progress_bar.visible = true
		progress_label.visible = true
	else:
		progress_label.visible = false
		progress_bar.visible = false

func _on_wave_started(wave_number: int):
	print("HUD: Ondata ", wave_number, " iniziata")
	_update_wave_display()

func _on_wave_completed(wave_number: int):
	print("HUD: Ondata ", wave_number, " completata")
	# Mostra brevemente il completamento
	progress_label.text = "WAVE " + str(wave_number) + " COMPLETED!"
	progress_bar.value = 100
	progress_label.visible = true
	progress_bar.visible = true
	
	# Breve pausa per mostrare il completamento
	await get_tree().create_timer(1.5).timeout

# Chiamata periodica per aggiornare il progresso durante l'ondata
func _on_timer_timeout():
	_update_wave_display()

# Timer per aggiornamenti periodici più frequenti
func _enter_tree():
	var update_timer = Timer.new()
	update_timer.wait_time = 0.2  # Aggiorna ogni 200ms
	update_timer.timeout.connect(_on_timer_timeout)
	update_timer.autostart = true
	add_child(update_timer)
