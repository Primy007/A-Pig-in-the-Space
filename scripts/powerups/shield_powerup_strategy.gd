class_name ShieldPowerUpStrategy
extends BasePowerUpStrategy

# Quantità di danno che lo scudo può assorbire
@export var shield_amount: int = 50

const POWERUP_ID = "shield"

func apply_to_player(player: CharacterBody2D) -> void:
	# Aggiungiamo uno scudo al giocatore
	player.has_shield = true
	player.shield_health = shield_amount
	
	# Facciamo apparire un effetto visivo per lo scudo
	# Questa parte potrebbe richiedere la creazione di un nodo shield nel player
	if player.has_node("ShieldEffect"):
		player.get_node("ShieldEffect").visible = true

func remove_from_player(player: CharacterBody2D) -> void:
	# Rimuoviamo lo scudo
	player.has_shield = false
	player.shield_health = 0
	
	# Nascondiamo l'effetto visivo
	if player.has_node("ShieldEffect"):
		player.get_node("ShieldEffect").visible = false

func get_powerup_id() -> String:
	return POWERUP_ID
