extends Control

@onready var transition_player = $TransitionPlayer
@onready var fade_rect = $FadeRect

func _ready():
	fade_rect.modulate.a = 0  # Start fully transparent

# Function to fade out, switch scene, and fade back in
func fade_to_scene(target_scene: String):
	transition_player.play("fade_out")  # Play fade out effect
	await transition_player.animation_finished  # Wait until fade-out ends
	get_tree().change_scene_to_file(target_scene)  # Change scene
	transition_player.play("fade_in")  # Play fade-in effect
