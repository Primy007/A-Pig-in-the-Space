extends Area2D
class_name FileText

# Configurazione del testo
@export var text_content: String = "Default text content"
@export var collected: bool = false

# Segnali
signal file_collected(content: String)  # ✅ Cambiato per passare solo il contenuto

# Riferimenti ai nodi
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Aggiungi al gruppo dei file di testo
	add_to_group("filetext")
	
	# Connetti il segnale di collisione
	body_entered.connect(_on_body_entered)
	
	# Se già raccolto, nascondi
	if collected:
		hide()

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
	
	# RIMUOVI QUESTA PARTE (il DialogueManager gestirà tutto):
	# var textbox = get_tree().get_first_node_in_group("textbox")
	# if textbox:
	#     textbox.add_system_message("File raccolto: " + text_content)
	
	# Nascondi o rimuovi l'oggetto
	queue_free()

func set_text_content(content: String):
	"""Imposta il contenuto del testo"""
	text_content = content
