extends Node

# Preload your button click sound effect
var click_sound: AudioStream = preload("res://assets/music/button.mp3")
var audio_player: AudioStreamPlayer

func _ready():
	# Create an AudioStreamPlayer and add it as a child
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	# Optional: adjust volume, etc.
	audio_player.volume_db = 0

func play_click():
	print("Playing button click sound")
	audio_player.stream = click_sound
	audio_player.play()
