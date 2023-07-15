extends Node

var level_picker_path = "res://scenes/LevelPicker.tscn"
var game_scene_path = "res://scenes/GameScene.tscn"
var map_path = "res://scenes/maps/"

func _ready():
	Eventmanager.newGame.connect(_on_new_game)
	Eventmanager.mainMenu.connect(_on_main_menu)

func _on_new_game(map_data):
	_unpause_game()
	get_node("LevelPicker").queue_free()
	var game_scene = load(game_scene_path).instantiate()
	var game_map = map_data.map
	game_scene.get_node("Camera").add_sibling(game_map)
	add_child(game_scene)

func _on_main_menu():
	_unpause_game()
	get_node("GameScene").queue_free()
	var level_picker = load(level_picker_path).instantiate()
	add_child(level_picker)

func _unpause_game():
	get_tree().paused = false
