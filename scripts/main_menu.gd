class_name MainMenu
extends Control

@onready var play_button = $MarginContainer/HBoxContainer/VBoxContainer/Play_Button as Button
@onready var options_button = $MarginContainer/HBoxContainer/VBoxContainer/Options_Button as Button
@onready var exit_button = $MarginContainer/HBoxContainer/VBoxContainer/Exit_Button as Button
@onready var options_menu = $Options_menu as OptionsMenu
@onready var margin_container = $MarginContainer as MarginContainer

@export var start_level = preload("res://scenes/splash_screen.tscn") as PackedScene

func _ready() :
	handle_connecting_signals()


func on_play_pressed() -> void:
	get_tree().change_scene_to_packed(start_level)


func on_options_pressed() -> void:
	margin_container.visible = false
	options_menu.set_process(true)
	options_menu.visible = true


func on_exit_pressed() -> void:
	get_tree().quit()


func on_exit_options_menu() -> void:
	margin_container.visible = true
	options_menu.visible = false


func handle_connecting_signals() -> void:
	play_button.button_down.connect(on_play_pressed)
	options_button.button_down.connect(on_options_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	options_menu.exit_options_menu.connect(on_exit_options_menu)
