extends Control

@onready var score_container = $ScoreContainer
@onready var back_button = $BackButton

func _ready():
	print("📌 Leaderboard scene loaded!")  # Debugging
	back_button.pressed.connect(_on_BackButton_pressed)
	load_leaderboard()

func _on_BackButton_pressed():
	print("🔙 Back button pressed")  # Debugging
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ==============================
# 🌍 LOAD LEADERBOARD FROM FIREBASE (READ ONLY)
# ==============================
func load_leaderboard():
	print("📂 Loading leaderboard...")  # Debugging
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_load_response)
	request.request(Global.FIREBASE_URL, [], HTTPClient.METHOD_GET)

func _on_load_response(result, response_code, headers, body):
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		print("📊 Raw Response from Firebase:", response_text)  # Debugging
		var data = JSON.parse_string(response_text)
		if data:
			print("📊 Parsed Leaderboard Data:", data)  # Debugging
			display_leaderboard(data)
		else:
			print("⚠️ ERROR: Failed to parse leaderboard data.")
	else:
		print("⚠️ ERROR: Failed to fetch leaderboard from Firebase. Response Code:", response_code)


# ==============================
# 💾 SAVE SCORE TO FIREBASE (CHECK IF IN TOP 10)
# ==============================
func update_leaderboard(player_name, balance):
	load_leaderboard()

	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_check_leaderboard_response)
	request.request(Global.FIREBASE_URL, [], HTTPClient.METHOD_GET)

func _on_check_leaderboard_response(result, response_code, headers, body):
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var data = JSON.parse_string(response_text)
		if data:
			check_and_update_leaderboard(data)
		else:
			print("⚠️ ERROR: Failed to retrieve leaderboard.")
	else:
		print("⚠️ ERROR: Failed to fetch leaderboard from Firebase. Response Code:", response_code)

func check_and_update_leaderboard(data):
	var sorted_entries = []

	# Handle both dictionary and array cases
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			sorted_entries.append(data[key])
	elif typeof(data) == TYPE_ARRAY:
		sorted_entries = data

	# Sort leaderboard by balance (descending)
	sorted_entries.sort_custom(func(a, b): return a["balance"] > b["balance"])

	# Only update leaderboard if player is in the top 10
	if sorted_entries.size() < 10 or Global.player_max_money > sorted_entries[-1]["balance"]:
		save_new_score(Global.player_nickname, Global.player_max_money, sorted_entries)


func save_new_score(player_name, balance, sorted_entries):
	# Remove the lowest-ranked player if already 10
	if sorted_entries.size() >= 10:
		sorted_entries.pop_back()

	# Add new entry
	var leaderboard_entry = {
		"name": player_name,
		"balance": balance
	}
	sorted_entries.append(leaderboard_entry)

	# ✅ Remove any `null` values before saving
	sorted_entries = sorted_entries.filter(func(entry): return entry != null)

	# Convert leaderboard to dictionary format
	var leaderboard_dict = {}
	for i in range(sorted_entries.size()):
		leaderboard_dict[str(i + 1)] = sorted_entries[i]

	# Convert data to JSON
	var json_data = JSON.stringify(leaderboard_dict)

	# Send updated leaderboard to Firebase
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_save_response)
	request.request(Global.FIREBASE_URL, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, json_data)



func _on_save_response(result, response_code, headers, body):
	if response_code == 200:
		print("✅ Successfully updated leaderboard.")
	else:
		print("⚠️ ERROR: Failed to update leaderboard. Response Code:", response_code)

# ==============================
# 🏆 DISPLAY LEADERBOARD
# ==============================
func display_leaderboard(data):
	# Clear existing leaderboard UI elements
	for child in score_container.get_children():
		child.queue_free()

	var sorted_entries = []

	# Handle if Firebase returns an object (keys are IDs)
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			sorted_entries.append(data[key])

	# Handle if Firebase returns an array (direct list)
	elif typeof(data) == TYPE_ARRAY:
		for entry in data:
			if entry != null:  # ✅ Skip null values
				sorted_entries.append(entry)

	# Sort leaderboard by balance (descending)
	sorted_entries.sort_custom(func(a, b): return a["balance"] > b["balance"])

	# Keep only top 10
	if sorted_entries.size() > 10:
		sorted_entries = sorted_entries.slice(0, 10)

	# ✅ Create a VBoxContainer to properly space entries
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)  # Adjusts vertical spacing
	score_container.add_child(vbox)  # Attach to UI container

	# ✅ Display leaderboard properly spaced with colors
	for i in range(sorted_entries.size()):
		var entry = sorted_entries[i]

		# ✅ Create HBoxContainer for structured layout
		var hbox = HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_TOP_WIDE)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 30)  # Adjusts horizontal spacing

		# ✅ Rank Label (E981B8 - Soft Pink)
		var rank_label = Label.new()
		rank_label.text = str(i + 1) + "."
		rank_label.add_theme_font_size_override("font_size", 32)
		rank_label.add_theme_color_override("font_color", Color("e981b8"))

		# ✅ Name Label (5CC2FD - Soft Blue)
		var name_label = Label.new()
		name_label.text = entry["name"]
		name_label.add_theme_font_size_override("font_size", 32)
		name_label.add_theme_color_override("font_color", Color("5cc2fd"))

		# ✅ Score Label (Deep Green)
		var score_label = Label.new()
		score_label.text = "$" + str(entry["balance"])
		score_label.add_theme_font_size_override("font_size", 32)
		score_label.add_theme_color_override("font_color", Color(0.0, 0.4, 0.0))  # Deep Green (Dark Tone)

		# ✅ Add labels to horizontal container
		hbox.add_child(rank_label)
		hbox.add_child(name_label)
		hbox.add_child(score_label)

		# ✅ Add to vertical container
		vbox.add_child(hbox)
