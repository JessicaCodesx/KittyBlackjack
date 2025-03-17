extends Button

func _ready():
	# Connect signals for hover, press, and release
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	button_up.connect(_on_released)

# Hover effect - Button grows slightly
func _on_mouse_entered():
	create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

# Reset size when mouse leaves
func _on_mouse_exited():
	create_tween().tween_property(self, "scale", Vector2(1, 1), 0.1)

# Press effect - Button shrinks slightly
func _on_pressed():
	create_tween().tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	print("Button pressed")
	SfxManager.play_click()

# Release effect - Return to hover size
func _on_released():
	create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.05)
