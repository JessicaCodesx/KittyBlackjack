extends Control 

# UI Elements
@onready var player_nickname_label = $PlayerNicknameLabel
@onready var player_balance_label = $PlayerBalanceLabel
@onready var dealer_cards_container = $DealerCardsContainer
@onready var player_cards_container = $PlayerCardsContainer
@onready var bet_input = $BetInput
@onready var place_bet_button = $PlaceBetButton
@onready var exit_button = $ExitButton
@onready var dealer_sprite = $DealerSprite
@onready var hit_button = $HitButton
@onready var stand_button = $StandButton
@onready var double_down_button = $DoubleDownButton
@onready var bet_again_button = $BetAgainButton
@onready var dealer_hand_total_label = $DealerHandTotal
@onready var player_hand_total_label = $PlayerHandTotal


# Player Data
var player_bet = 0
var shuffled_deck = []
var game_started = false  # Prevents dealing cards before betting
var player_hand = []
var dealer_hand = []
var win_streak = 0  # tracks consecutive wins
var player_blackjack = false  # true only if the player's initial 2 cards total 21
var has_hit = false

# Dealer card management
var dealer_hidden_card_sprite: TextureRect  # stores the face-down card sprite
var dealer_second_card: String               # stores the actual second card name
var dealer_revealed = false
var dealer_hidden_value = 0
var dealer_visible_total = 0  # Sum of dealer cards that are face-up
var dealer_blackjack = false  # true if dealer's initial two cards total 21

# Round & Idle management
var round_count = 0         # counts completed rounds
var eating_round = false    # true if this round should show "eating" from bet placement until results
var idle_time = 0
var in_result_phase = false   # locks result animations until new bet

# Suits & Ranks for Deck
var suits = ["Spades", "Hearts", "Diamonds", "Clubs"]
var ranks = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]

# Deck Dictionary: Maps card names to their file paths
var deck = {}

# Counters for card positioning
var player_card_count = 0
var dealer_card_count = 0

# ==============================
# PROCESS: Handle Idle Timer & Animation
# ==============================
func _process(delta):
	# Only update idle animations if not in result phase.
	if in_result_phase:
		return
	idle_time += delta
	if idle_time >= 20:
		dealer_sprite.play("sleeping")
	elif idle_time >= 10:
		dealer_sprite.play("sleepy")
	else:
		# Ensure it's playing "idle" if not overridden by an eating round.
		if not eating_round and dealer_sprite.animation != "idle":
			dealer_sprite.play("idle")

# Resets idle timer and, if not in result phase, set dealer animation back to idle
func resetIdle():
	idle_time = 0
	if not in_result_phase and not eating_round:
		dealer_sprite.play("idle")

# ==============================
# 🎮 GAME START - WAIT FOR BET BEFORE DEALING CARDS
# ==============================
func _ready():
	Global.player_max_money = 500
	# Set up deck dynamically.
	setup_deck()
	
	# Ensure dealer sprite is visible and playing idle.
	dealer_sprite.visible = true
	dealer_sprite.show()
	dealer_sprite.play("idle")
	
	# Set the player's nickname.
	player_nickname_label.text = "Player: " + Global.player_nickname
	
	# Set the initial balance.
	update_player_balance()
	
	# Shuffle the deck.
	shuffled_deck.shuffle()
	
	# Hide game elements until bet is placed.
	dealer_cards_container.visible = false
	player_cards_container.visible = false
	bet_again_button.visible = false
	hit_button.disabled = true
	stand_button.disabled = true
	double_down_button.disabled = true
	
	# Connect buttons.
	place_bet_button.pressed.connect(_on_PlaceBetButton_pressed)
	exit_button.pressed.connect(_on_ExitButton_pressed)
	hit_button.pressed.connect(_on_HitButton_pressed)
	stand_button.pressed.connect(_on_StandButton_pressed)
	double_down_button.pressed.connect(_on_DoubleDownButton_pressed)
	bet_again_button.pressed.connect(_on_BetAgainButton_pressed)
	
	if Global.player_max_money <= 0:
		place_bet_button.disabled = true
		player_balance_label.text = "Game Over! Balance: $0"

# ==============================
# 💰 PLAYER BETS BEFORE GAME STARTS
# ==============================
func _on_PlaceBetButton_pressed():
	resetIdle()
	in_result_phase = false   # New bet resets result phase.
	# Determine if this round is an "eating" round.
	# (Every 3 rounds: i.e. if (round_count + 1) % 3 == 0.)
	eating_round = ((round_count + 1) % 3 == 0)
	if eating_round:
		# Immediately play the "eating" animation.
		dealer_sprite.play("eating")
	
	var bet_text = bet_input.text.strip_edges(true, true)
	
	# Validate input.
	if not bet_text.is_valid_int():
		return
	
	var bet_amount = int(bet_text)
	
	# Check that the bet is within the player's balance.
	if bet_amount <= 0 or bet_amount > Global.player_max_money:
		return
	
	# Deduct the bet and store it.
	player_bet = bet_amount
	Global.player_max_money -= player_bet
	update_player_balance()
	
	# Hide bet input and button.
	bet_input.visible = false
	place_bet_button.visible = false
	
	# Show game elements.
	dealer_cards_container.visible = true
	player_cards_container.visible = true
	
	# Enable action buttons.
	hit_button.disabled = false
	stand_button.disabled = false
	double_down_button.disabled = false
	
	# Start the game.
	start_game()

# ==============================
# DEALING CARDS
# ==============================
func start_game():
	resetIdle()
	game_started = true  # Allow game logic to proceed.
	
	# Reset counters, totals, and flags.
	player_card_count = 0
	dealer_card_count = 0
	dealer_visible_total = 0
	dealer_revealed = false
	player_blackjack = false
	dealer_blackjack = false
	has_hit = false
	
	# Clear previous hands.
	player_hand.clear()
	dealer_hand.clear()
	
	# --- DEAL CARDS FOR BOTH PLAYER AND DEALER ---
	# Deal two cards to the player.
	var player_card_1 = draw_card()
	var player_card_2 = draw_card()
	display_card(player_card_1, true)
	display_card(player_card_2, true)
	
	# Deal two cards to the dealer.
	var dealer_card_1 = draw_card()
	var dealer_card_2 = draw_card()
	# Display the first dealer card.
	display_card(dealer_card_1, false)
	# Hide the second dealer card.
	hide_dealer_second_card(dealer_card_2)
	Global.hidden_dealer_card = load(deck[dealer_card_2])
	
	# --- CHECK FOR BLACKJACK ---
	if get_hand_value(player_hand) == 21 and player_hand.size() == 2:
		player_blackjack = true
	if get_hand_value(dealer_hand) == 21 and dealer_hand.size() == 2:
		dealer_blackjack = true
	
	# If any blackjack condition is met, reveal the dealer’s card and end the round.
	if player_blackjack or dealer_blackjack:
		reveal_dealer_card(dealer_second_card)
		
		# Determine outcome:
		# Both have blackjack => push (tie)
		if player_blackjack and dealer_blackjack:
			end_round(null)
		# Only the player has blackjack => win with blackjack payout
		elif player_blackjack:
			end_round(true, true)
		# Only the dealer has blackjack => loss
		else:
			end_round(false)
		return

	# If no blackjack, the game continues normally.


# ==============================
# GENERATE THE DECK
# ==============================
func setup_deck():
	for suit in suits:
		for rank in ranks:
			var card_name = rank + "_" + suit
			deck[card_name] = "res://assets/cards/" + card_name + ".png"
			shuffled_deck.append(card_name)

# ==============================
# DRAW A CARD
# ==============================
func draw_card():
	if shuffled_deck.size() == 0:
		print("Deck is empty! Reshuffling...")
		reshuffle_deck()
	return shuffled_deck.pop_front()

func reshuffle_deck():
	shuffled_deck.clear()
	setup_deck()
	shuffled_deck.shuffle()

# ==============================
# DISPLAY A CARD
# ==============================
func display_card(card_name, is_player):
	resetIdle()
	if card_name in deck:
		var card_texture = load(deck[card_name])
		var card_sprite = TextureRect.new()
		card_sprite.texture = card_texture
		card_sprite.custom_minimum_size = Vector2(100, 150)
		
		var card_value = get_card_value(card_name)
		var max_cards = 3
		var spacing = 80
		
		if is_player:
			var x_position = min(player_card_count, max_cards - 1) * spacing
			card_sprite.position = Vector2(x_position, 0)
			player_cards_container.add_child(card_sprite)
			player_card_count += 1
			player_hand.append(card_value)
		else:
			var x_position = min(dealer_card_count, max_cards - 1) * spacing
			card_sprite.position = Vector2(x_position, 0)
			dealer_cards_container.add_child(card_sprite)
			dealer_hand.append(card_value)
			# This card is face-up; add its value to the visible total.
			dealer_visible_total += card_value
		dealer_card_count += 1
		update_hand_totals()

# ==============================
# HIDE DEALER'S SECOND CARD
# ==============================
func hide_dealer_second_card(card_name):
	resetIdle()
	dealer_second_card = card_name
	# Store the hidden card's value separately.
	dealer_hidden_value = get_card_value(card_name)
	dealer_revealed = false
	
	dealer_hidden_card_sprite = TextureRect.new()
	dealer_hidden_card_sprite.texture = load("res://assets/cards/BackCard.png")
	dealer_hidden_card_sprite.custom_minimum_size = Vector2(100, 150)
	dealer_hidden_card_sprite.position = Vector2(min(dealer_card_count, 4) * 80, 0)
	dealer_cards_container.add_child(dealer_hidden_card_sprite)
	dealer_card_count += 1
	# Add the card to the full dealer hand for calculations,
	# but do NOT add its value to dealer_visible_total.
	dealer_hand.append(get_card_value(card_name))

# ==============================
# REVEAL DEALER'S HIDDEN CARD (only once)
# ==============================
func reveal_dealer_card(card_name):
	resetIdle()
	# Only reveal if not already revealed.
	if dealer_revealed:
		return
	
	if dealer_hidden_card_sprite and dealer_second_card in deck:
		# Remove the face-down sprite.
		dealer_cards_container.remove_child(dealer_hidden_card_sprite)
		dealer_hidden_card_sprite.queue_free()
		
		# Create and display the revealed card sprite at the same position.
		var card_texture = load(deck[card_name])
		var revealed_card_sprite = TextureRect.new()
		revealed_card_sprite.texture = card_texture
		revealed_card_sprite.custom_minimum_size = Vector2(100, 150)
		revealed_card_sprite.position = dealer_hidden_card_sprite.position
		dealer_cards_container.add_child(revealed_card_sprite)
		
		dealer_revealed = true
		# Now add the hidden card's value to the visible total.
		dealer_visible_total += dealer_hidden_value
		update_hand_totals()
		
		# If the dealer has blackjack, play the "dance" animation.
		if dealer_blackjack:
			dealer_sprite.play("dance")

# ==============================
# HAND VALUE CALCULATIONS & UI UPDATE
# ==============================
func get_card_value(card_name):
	var rank = card_name.split("_")[0]
	if rank == "Ace":
		return 11
	elif rank in ["King", "Queen", "Jack"]:
		return 10
	else:
		return int(rank)

func get_hand_value(hand):
	var total = 0
	var ace_count = 0
	for value in hand:
		total += value
		if value == 11:
			ace_count += 1
	while total > 21 and ace_count > 0:
		total -= 10
		ace_count -= 1
	return total

func update_hand_totals():
	player_hand_total_label.text = "Player Total: " + str(get_hand_value(player_hand))
	if dealer_revealed:
		dealer_hand_total_label.text = "Dealer Total: " + str(get_hand_value(dealer_hand))
	else:
		dealer_hand_total_label.text = "Dealer Total: " + str(dealer_visible_total)

# ==============================
# PLAYER ACTIONS
# ==============================
func _on_HitButton_pressed():
	resetIdle()
	var new_card = draw_card()
	display_card(new_card, true)
	
	has_hit = true
	double_down_button.disabled = true
	
	var player_total = get_hand_value(player_hand)
	if player_total == 21:
		# Use player_blackjack only if it was a true blackjack.
		end_round(true, player_blackjack)
	elif player_total > 21:
		end_round(false)

func _on_StandButton_pressed():
	resetIdle()
	# When the player stands, proceed with the dealer's turn.
	dealer_turn()

# New: Double Down Action
func _on_DoubleDownButton_pressed():
	resetIdle()
	
	if has_hit:
		return
	# Ensure the player has enough funds to double down.
	if Global.player_max_money < player_bet:
		return  # Optionally, show an error message.
	
	# Deduct an additional amount equal to the original bet.
	Global.player_max_money -= player_bet
	# Double the bet.
	player_bet *= 2
	update_player_balance()
	
	# Disable further player actions.
	hit_button.disabled = true
	stand_button.disabled = true
	double_down_button.disabled = true
	
	# Deal exactly one additional card to the player.
	var new_card = draw_card()
	display_card(new_card, true)
	
	# After receiving the card, automatically start the dealer's turn.
	dealer_turn()

# ==============================
# DEALER TURN: REVEAL THEN HIT UNTIL 17+
# ==============================
func dealer_turn():
	resetIdle()
	# First, reveal the hidden dealer card.
	reveal_dealer_card(dealer_second_card)
	update_hand_totals()
	
	# Draw cards until the dealer's full hand total is at least 17.
	while get_hand_value(dealer_hand) < 17:
		await get_tree().create_timer(1).timeout  # delay for visual effect
		var new_card = draw_card()
		display_card(new_card, false)
		update_hand_totals()
	
	# Evaluate the outcome.
	var dealer_total = get_hand_value(dealer_hand)
	var player_total = get_hand_value(player_hand)
	
	if dealer_total > 21:
		end_round(true)
	elif player_total > dealer_total:
		end_round(true)
	elif player_total == dealer_total:
		end_round(null)
	else:
		end_round(false)

# ==============================
# END ROUND: PAYOUT OR LOSS & RESULT ANIMATIONS
# ==============================
func end_round(player_won, blackjack = false):
	resetIdle()
	in_result_phase = true  # Lock result animations until a new bet.
	
	hit_button.disabled = true
	stand_button.disabled = true
	double_down_button.disabled = true
	bet_again_button.visible = true
	
	# Ensure the dealer's hidden card is revealed.
	reveal_dealer_card(dealer_second_card)
	
	# Outcome processing:
	# - If the player wins, they receive double their bet (or 2.5× if they had blackjack)
	#   and the dealer plays "sad" unless the win streak is 3+ (then "crying").
	# - If it's a push, the bet is refunded.
	# - If the player loses, nothing is added and the dealer plays "excited".
	if player_won == true:
		if blackjack:
			Global.player_max_money += floor(player_bet * 2.5)
			win_streak += 1
		else:
			Global.player_max_money += player_bet * 2
			win_streak += 1
		if win_streak >= 3:
			dealer_sprite.play("crying")
		else:
			dealer_sprite.play("sad")
	elif player_won == null:
		Global.player_max_money += player_bet
		# No special animation for a push.
	else:
		win_streak = 0
		dealer_sprite.play("excited")
	
	# For eating rounds, the "eating" animation is active until results;
	# now that results are shown, the result animation (sad/excited/crying) takes over.
	eating_round = false
	
	round_count += 1
	update_player_balance()
	update_leaderboard()

	
	# If the player's balance reaches 0, play "dance".
	if Global.player_max_money <= 0:
		dealer_sprite.play("dance")
		player_balance_label.text = "Game Over! Balance: $0"
		bet_again_button.visible = false

# ==============================
# BET AGAIN / RESET GAME
# ==============================
func _on_BetAgainButton_pressed():
	resetIdle()
	in_result_phase = false  # Unlock result animations for a new bet.
	eating_round = false      # Reset eating round flag.
	if Global.player_max_money <= 0:
		return  # Prevent play with 0 balance.
	
	# Reset game state while keeping the balance.
	game_started = false
	player_bet = 0
	player_hand.clear()
	dealer_hand.clear()
	player_card_count = 0
	dealer_card_count = 0
	dealer_blackjack = false
	
	# Clear the UI elements.
	for child in player_cards_container.get_children():
		child.queue_free()
	for child in dealer_cards_container.get_children():
		child.queue_free()
	
	# Reset UI for new bet.
	bet_input.visible = true
	place_bet_button.visible = true
	bet_again_button.visible = false
	hit_button.disabled = true
	stand_button.disabled = true
	double_down_button.disabled = true
	
	update_player_balance()

# ==============================
# UPDATE PLAYER BALANCE UI
# ==============================
func update_player_balance():
	player_balance_label.text = "Balance: $" + str(Global.player_max_money)

# (Optional) Default dealer animation if not in result phase.
func play_dealer_animation(blackjack: bool):
	if not in_result_phase:
		if win_streak > 2 or blackjack:
			dealer_sprite.play("cry")
		else:
			dealer_sprite.play("idle")

# ==============================
# EXIT THE GAME
# ==============================
func _on_ExitButton_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn") 
	

# ==============================
# 🌍 FIREBASE LEADERBOARD FUNCTIONALITY
# ==============================

# Fetch leaderboard, check if update is needed, and save new scores
func update_leaderboard():
	print("📡 Fetching leaderboard from Firebase...")
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_leaderboard_response)
	request.request(Global.FIREBASE_URL, [], HTTPClient.METHOD_GET)

# Process leaderboard response
func _on_leaderboard_response(result, response_code, headers, body):
	if response_code == 200:
		var response_text = body.get_string_from_utf8()
		var data = JSON.parse_string(response_text)
		
		if data:
			print("📊 Parsed Leaderboard Data:", data)
			check_and_update_leaderboard(data)
		else:
			print("⚠️ ERROR: Failed to parse leaderboard data.")
	else:
		print("⚠️ ERROR: Failed to fetch leaderboard from Firebase. Response Code:", response_code)

# Checks if the player's score should be in the top 10
func check_and_update_leaderboard(data):
	# Create a dictionary keyed by player nickname.
	var leaderboard_dict = {}
	
	# Convert the incoming data (dictionary or array) into a dictionary keyed by name.
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			var entry = data[key]
			if entry != null and entry.has("name") and entry.has("balance"):
				leaderboard_dict[ entry["name"] ] = entry["balance"]
	elif typeof(data) == TYPE_ARRAY:
		for entry in data:
			if entry != null and entry.has("name") and entry.has("balance"):
				leaderboard_dict[ entry["name"] ] = entry["balance"]
	
	# Get the current player's nickname.
	var current_player = Global.player_nickname
	
	# If the player already has an entry, update it only if the new balance is higher.
	if leaderboard_dict.has(current_player):
		if Global.player_max_money > leaderboard_dict[current_player]:
			leaderboard_dict[current_player] = Global.player_max_money
	else:
		leaderboard_dict[current_player] = Global.player_max_money

	# Convert the dictionary back to an array for sorting.
	var entries = []
	for name in leaderboard_dict.keys():
		entries.append({ "name": name, "balance": leaderboard_dict[name] })
	
	# Sort entries in descending order (highest balance first).
	entries.sort_custom(func(a, b):
		return int(b["balance"] - a["balance"])
	)
	
	# Keep only the top 10 entries.
	while entries.size() > 10:
		entries.pop_back()
	
	# Save the updated leaderboard.
	save_leaderboard(entries)



# Saves the updated leaderboard to Firebase
func save_leaderboard(sorted_entries):
	print("💾 Saving updated leaderboard to Firebase...")

	# Convert the sorted entries array into a dictionary keyed by rank.
	var leaderboard_dict = {}
	for i in range(sorted_entries.size()):
		leaderboard_dict[str(i + 1)] = sorted_entries[i]

	var json_data = JSON.stringify(leaderboard_dict)

	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_save_response)
	request.request(Global.FIREBASE_URL, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, json_data)


# Confirms leaderboard save success
func _on_save_response(result, response_code, headers, body):
	if response_code == 200:
		print("✅ Successfully updated leaderboard.")
	else:
		print("⚠️ ERROR: Failed to update leaderboard. Response Code:", response_code)
