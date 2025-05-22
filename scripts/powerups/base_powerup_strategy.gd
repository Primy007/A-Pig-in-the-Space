class_name BasePowerUpStrategy
extends Resource

# Icona del power-up da mostrare
@export var texture: Texture2D
# Testo descrittivo del power-up
@export var upgrade_text: String = "Power-Up"
# Durata del power-up in secondi (0 = permanente)
@export var duration: float = 10.0

# Metodo principale per applicare il power-up al proiettile
func apply_to_bullet(bullet: Area2D) -> void:
	# Da implementare nelle classi derivate
	pass
	
# Metodo principale per applicare il power-up al giocatore
func apply_to_player(player: CharacterBody2D) -> void:
	# Da implementare nelle classi derivate
	pass
	
# Metodo per rimuovere l'effetto dal giocatore
func remove_from_player(player: CharacterBody2D) -> void:
	# Da implementare nelle classi derivate
	pass
