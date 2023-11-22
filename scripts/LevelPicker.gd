extends Control

var map_path = "res://scenes/maps/"
var preview_path = "res://assets/map_preview/"
var game_scene_path = "res://scenes/GameScene.tscn"
var selected_map : Map_Data

@onready var level_type = get_node("%LevelType")
@onready var level_name = get_node("%LevelName")
@onready var levels = get_node("%Levels")

@export var pages_number = 3
@onready var current_page = 1

func _on_exit_pressed():
	get_tree().quit()

func _on_level_mouse_entered(button_number):
	selected_map = _get_map_data(button_number)
	_set_page_data()
	_set_map_preview(button_number)

func _on_level_pressed(button_number):
	_on_level_mouse_entered(button_number)
	if selected_map != null:
		Eventmanager.emit_signal("newGame", selected_map)
	else:
		print("No map selected.")

func _on_next_page_pressed():
	if current_page < pages_number:
		current_page += 1
	else:
		current_page = 1
	_set_page_data()
	_set_map_preview(1)
	level_name.text = ""

func _get_map_data(map_number):
	var map_data = Map_Data.new()
	map_data.map = load(map_path + str((current_page - 1) * 4 + map_number) + ".tscn").instantiate()
	map_data.map_name = map_data.map.map_name
	return map_data

func _set_page_data():
	match current_page:
		1:
			level_type.text = "Training:"
		2:
			level_type.text = "Challanges:"
		3:
			level_type.text = "AI Tests"
		
	if selected_map != null:
		level_name.text = selected_map.map_name
	
	for i in levels.get_child_count():
		var level_number = (current_page - 1) * 4 + i + 1
		levels.get_child(i).text = "Level " + str(level_number)

func _set_map_preview(button_number):
	var level_number = (current_page - 1) * 4 + button_number
	var map_texture = load(preview_path + str(level_number) + ".png")
	get_node("%Preview").texture = map_texture
