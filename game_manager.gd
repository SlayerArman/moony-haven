extends Node

var score: int = 0
const TOTAL_COLLECTIBLES: int = 12

var win_label: Label

func add_score():
	score += 1
	if score >= TOTAL_COLLECTIBLES:
		win_game()

func win_game():
	if win_label:
		win_label.text = "Moony Haven!"
		win_label.visible = true
	
	get_tree().paused = true
