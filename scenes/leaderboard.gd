extends Control

@onready var back_button = $BackButton  # Reference the button

func _ready():
	back_button.pressed.connect(_on_BackButton_pressed)  # Connect signal manually

func _on_BackButton_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")  # Go back to main menu
