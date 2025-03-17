extends Control

@onready var leaderboard_button = $LeaderboardButton
@onready var start_button = $StartButton
@onready var exit_button = $ExitButton
@onready var help_button = $HelpButton
@onready var nickname_input = $NicknameInput
@onready var error_message = $ErrorMessage

func _ready():

	start_button.disabled = true
	error_message.visible = false  # Hide error message initially

	start_button.pressed.connect(_on_StartButton_pressed)
	leaderboard_button.pressed.connect(_on_LeaderboardButton_pressed)
	exit_button.pressed.connect(_on_ExitButton_pressed)
	help_button.pressed.connect(_on_HelpButton_pressed)
	nickname_input.text_changed.connect(_on_NicknameInput_text_changed)

# Enable Start button when text is entered
func _on_NicknameInput_text_changed(new_text):
	var is_empty = new_text.strip_edges(true, true).length() == 0
	start_button.disabled = is_empty
	
	if not is_empty:
		hide_error_message()

# Show the error message when no nickname is entered
func show_error_message():
	print("show_error_message() called!")  # Debugging
	error_message.text = "Please enter a nickname!"
	error_message.visible = true  # Ensure it's visible
	error_message.modulate.a = 1  # Force visibility

# Hide the error message
func hide_error_message():
	print("hide_error_message() called!")  # Debugging
	error_message.visible = false  # Hide error
	error_message.modulate.a = 0  # Ensure it's fully hidden

# Function when Start Game is pressed
func _on_StartButton_pressed():
	var nickname = nickname_input.text.strip_edges(true, true)

	if nickname.is_empty():
		print("Nickname is empty, showing error message!")  # Debugging
		show_error_message()
	else:
		print("Nickname entered:", nickname)  # Debugging
		hide_error_message()
		Global.player_nickname = nickname
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

# Leaderboard Button function
func _on_LeaderboardButton_pressed():
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")

# Exit Game Button function
func _on_ExitButton_pressed():
	get_tree().quit()

func _on_HelpButton_pressed():
	get_tree().change_scene_to_file("res://scenes/Help.tscn")
