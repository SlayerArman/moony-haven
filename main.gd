extends Node2D

@onready var win_label = $CanvasLayer/WinLabel

func _ready():
	GameManager.win_label = win_label
