extends Node

const FIREBASE_URL = "https://kittyblackjack-5c5c4-default-rtdb.firebaseio.com/leaderboard.json"


var player_nickname = ""
var player_max_money = 500  # Default starting balance
var leaderboard_data = []  # Stores top 10 players
var hidden_dealer_card: Texture = null  # Store as a Texture instead of a string


func update_max_money(new_amount):
	if new_amount > player_max_money:
		player_max_money = new_amount

func save_to_leaderboard():
	leaderboard_data.append({
		"nickname": player_nickname,
		"max_money": player_max_money
	})
	
	# Sort by highest money
	leaderboard_data.sort_custom(func(a, b): return a["max_money"] > b["max_money"])
	
	# Keep only top 10 scores
	if leaderboard_data.size() > 10:
		leaderboard_data.resize(10)
