extends Control

class_name PowerUpIcon

# Riferimenti ai nodi UI
@onready var icon_texture: TextureRect = $IconTexture
@onready var timer_label: Label = $TimerLabel
@onready var progress_bar: ProgressBar = $ProgressBar

# Riferimento alla strategia del power-up
var powerup_strategy: BasePowerUpStrategy
var start_time: float
var current_time: float

func setup(strategy: BasePowerUpStrategy):
	powerup_strategy = strategy
	start_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
	
	# Configura l'icona
	if icon_texture:
		icon_texture.texture = strategy.texture
	
	# Configura la progress bar
	if progress_bar and strategy.duration > 0:
		progress_bar.max_value = strategy.duration
		progress_bar.value = strategy.duration
		progress_bar.visible = true
	else:
		if progress_bar:
			progress_bar.visible = false
	
	# Configura il timer label
	if timer_label:
		if strategy.duration > 0:
			timer_label.visible = true
		else:
			timer_label.text = "∞"
			timer_label.visible = true

func _process(delta):
	if !powerup_strategy:
		return
		
	# Se il power-up ha una durata, aggiorna il timer
	if powerup_strategy.duration > 0:
		current_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
		var elapsed_time = current_time - start_time
		var remaining_time = max(0, powerup_strategy.duration - elapsed_time)
		
		# Aggiorna il label del timer
		if timer_label:
			timer_label.text = str(int(remaining_time))
		
		# Aggiorna la progress bar
		if progress_bar:
			progress_bar.value = remaining_time
			
			# Cambia colore quando il tempo sta per scadere
			if remaining_time < powerup_strategy.duration * 0.2:
				progress_bar.modulate = Color.RED
			elif remaining_time < powerup_strategy.duration * 0.5:
				progress_bar.modulate = Color.YELLOW
			else:
				progress_bar.modulate = Color.GREEN
