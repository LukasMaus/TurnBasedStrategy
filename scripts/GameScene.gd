extends Node2D

enum PlayerTurn {Player, Enemy}
var active_player: PlayerTurn = PlayerTurn.Player
var selected_unit
@onready var in_action = false

var player_unit_positions = []
var enemy_unit_positions = []
@onready var map_node = $Map
@onready var ui_node = $HUD
@onready var cursor = $Cursor
@onready var cursor_tile = Vector2(0, 0)
var cursor_tile_information

var defence_buff_value = 3
var avoid_buff_value = 20

func _ready():
	_initialize_unit_positions()
	map_node._set_units_to_solid(player_unit_positions, enemy_unit_positions)
	ui_node._initialize_ui(player_unit_positions.size(), enemy_unit_positions.size())
	Eventmanager.selectUnit.connect(_on_select_unit)
	Eventmanager.unselectUnit.connect(_on_unselect_unit)
	Eventmanager.endTurn.connect(_on_next_turn)
	Eventmanager.unitMoveStart.connect(_set_in_action.bind(true))
	Eventmanager.unitMoveEnd.connect(_set_in_action.bind(false))
	Eventmanager.newUnitPosition.connect(_on_new_unit_position)

func _process(_delta):
	if cursor_tile != Globals._get_tile_id(get_global_mouse_position()):
		_update_cursor()
	if in_action == false:
		_check_input()

func _check_input():
	if Input.is_action_just_pressed("unselect_unit"):
		_on_unselect_unit()
	if Input.is_action_just_pressed("unit_move") and selected_unit != null and selected_unit.unit_tile != cursor_tile and selected_unit.already_moved == false and selected_unit.team == active_player:
		var movement_path = map_node.movement_preview.points
		if movement_path.size() != 0:
			var destination = movement_path[movement_path.size() - 1] / Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE)
			if _check_unit_position(active_player, destination) == true:
				print("Tile occupied by own unit")
			else:
				#checks if the movement_path is viable
				if map_node._check_for_reachable_tile(cursor_tile):
					selected_unit._move(movement_path)
		else:
			print("No path to destination")

func _on_select_unit(selected_unit_new):
	if in_action == false:
		_on_unselect_unit()
		selected_unit = selected_unit_new
		selected_unit._unit_selected()
		ui_node._select_unit(selected_unit)
		if selected_unit.already_moved == false and selected_unit.already_acted == false:
			map_node._calculate_reachable_tiles(selected_unit)
			map_node._update_movement_preview(selected_unit.unit_tile, cursor_tile)
			if selected_unit.team == active_player:
				map_node._toggle_movement_preview(true)

func _on_unselect_unit():
	if selected_unit != null:
		selected_unit._unit_unselected()
		ui_node._unselect_unit()
	selected_unit = null
	map_node._toggle_movement_preview(false)
	map_node._clear_reachable_tiles()

func _update_cursor():
	var mouse_tile =  Globals._get_tile_id(get_global_mouse_position())
	var map_size = map_node.map_size
	#checks if cursor is within borders of the map
	if mouse_tile.x >= 0 and mouse_tile.x < map_size.x and mouse_tile.y >= 0 and mouse_tile.y < map_size.y:
		cursor.position = Globals._calculate_tile(get_global_mouse_position())
		cursor_tile = mouse_tile
		cursor_tile_information = map_node._get_tile_information(cursor_tile)
		ui_node._update_terrain_info(cursor_tile_information, defence_buff_value, avoid_buff_value)
		if selected_unit != null:
			map_node._update_movement_preview(selected_unit.unit_tile, cursor_tile)

func _on_next_turn():
	var active_player_units
	var unactive_player_units
	if active_player == 1:
		active_player = PlayerTurn.Player
		active_player_units = player_unit_positions
		unactive_player_units = enemy_unit_positions
	else:
		active_player = PlayerTurn.Enemy
		active_player_units = enemy_unit_positions
		unactive_player_units = player_unit_positions
	_on_unselect_unit()
	map_node._set_units_to_solid(active_player_units, unactive_player_units)
	Eventmanager.emit_signal("nextTurnStarted", active_player)

func _set_in_action(in_action_state):
	in_action = in_action_state

func _initialize_unit_positions():
	var unit_array = _get_unit_array(0)
	for i in map_node.get_child(0).get_child_count():
		unit_array.append(map_node.get_child(0).get_child(i).unit_tile)
	print("Player unit positions: " + str(unit_array))
	unit_array = _get_unit_array(1)
	for i in map_node.get_child(1).get_child_count():
		unit_array.append(map_node.get_child(1).get_child(i).unit_tile)
	print("Enemy unit positions: " + str(unit_array))

#updates the unit_position_array with the new position of the unit and erases the old position
func _on_new_unit_position(player, unit_position_old, unit_position_new):
	var unit_array = _get_unit_array(player)
	unit_array.erase(unit_position_old)
	unit_array.append(unit_position_new)
	#print("Player " + str(player) + " unit positions: " + str(unit_array))

#checks if the position is occupied by another unit of the player
func _check_unit_position(player, unit_position):
	var unit_array = _get_unit_array(player)
	var space_occupied = unit_array.find(unit_position)
	if space_occupied == -1:
		return false
	else:
		return true

func _get_unit_array(player):
	var unit_array
	if player == 0:
		unit_array = player_unit_positions
	else:
		unit_array = enemy_unit_positions
	return unit_array
