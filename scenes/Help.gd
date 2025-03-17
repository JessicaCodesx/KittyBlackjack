extends Control

@onready var rules_container = $RulesContainer
@onready var back_button = $BackButton

const RULES = [
	["WELCOME TO KITTY BLACKJACK!", "Your goal is to get as close to 21 as possible without going over."],
	["1. CARD VALUES", "Face cards (King, Queen, Jack) are worth 10 points. Aces can be worth 1 or 11."],
	["2. BUSTING", "If your total exceeds 21, you bust and lose the round."],
	["3. DEALER RULES", "The dealer must hit until they reach at least 17."],
	["4. BLACKJACK", "A natural blackjack (Ace + 10) pays 1.5x your bet."],
	["5. TIES", "A tie results in a push, and your bet is refunded."],
	["6. DOUBLE DOWN", "You can double down to double your bet after your first two cards."],
	["7. LEADERBOARD", "Track your winnings and try to reach the top of the global leaderboard!"],
	["8. BACK BUTTON", "Press 'Back' to return to the main menu."]
]

func _ready():
	print("📌 Rules scene loaded!")  # Debugging
	back_button.pressed.connect(_on_BackButton_pressed)
	display_rules()

func _on_BackButton_pressed():
	print("🔙 Back button pressed")  # Debugging
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func display_rules():
	# Clear existing labels if any
	for child in rules_container.get_children():
		child.queue_free()

	# Create each rule with styling
	for rule in RULES:
		var title_label = Label.new()
		title_label.text = rule[0]  # Uppercase Pink Title
		title_label.add_theme_font_size_override("font_size", 14)
		title_label.add_theme_color_override("font_color", Color("e981b8"))  # Pink
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Wrap text properly

		var description_label = Label.new()
		description_label.text = rule[1]  # Lowercase Blue Description
		description_label.add_theme_font_size_override("font_size", 12)
		description_label.add_theme_color_override("font_color", Color("5cc2fd"))  # Blue
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Wrap text properly

		# Add **reduced** spacing between rules
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 3)  # **3px spacing instead of 5px**

		# Add both to the container
		rules_container.add_child(title_label)
		rules_container.add_child(description_label)
		rules_container.add_child(spacer)  # Add reduced spacing between rules
