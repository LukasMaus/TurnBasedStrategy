extends Node2D

enum PlayerTurn {Player, Enemy}
var active_player: PlayerTurn = PlayerTurn.Player
var selected_unit : Unit
@onready var in_action = false	#true if animation is currently playing
@onready var in_attack_mode = false #true if character is looking for target to attack

var player_unit_positions = []
var enemy_unit_positions = []
@onready var map_node = $Map
@onready var ui_node = $HUD
@onready var cursor = $Cursor
@onready var cursor_tile = Vector2(0, 0)
var cursor_tile_information

var defence_buff_value = 3
var avoid_buff_value = 20
var critical_multiplier_value = 2

func _ready():
	_initialize_unit_positions()
	map_node._set_units_to_solid(player_unit_positions, enemy_unit_positions)
	ui_node._initialize_ui(player_unit_positions.size(), enemy_unit_positions.size())
	Eventmanager.clickedUnit.connect(_on_clicked_unit)
	Eventmanager.unselectUnit.connect(_on_unselect_unit)
	Eventmanager.endTurn.connect(_on_next_turn)
	Eventmanager.unitMove.connect(_set_in_action)
	Eventmanager.unitKilled.connect(_on_unit_killed)
	Eventmanager.setAttackMode.connect(_on_set_attack_mode)
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
		if _mouse_within_bounds() == true:
			var movement_path = map_node.movement_preview.points
			if movement_path.size() != 0:
				var destination = movement_path[movement_path.size() - 1] / Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE)
				if _check_unit_position(active_player, destination) == true:
					print("Tile occupied by own unit")
				else:
					#checks if the movement_path is viable
					if map_node._check_for_reachable_tile(cursor_tile):
						var move_info = Move_Info.new()
						move_info.movement_path = movement_path
						selected_unit._move(move_info)
			else:
				print("No path to destination")

func _on_clicked_unit(clicked_unit : Unit):
	if in_action == false:
		if in_attack_mode == true and _check_valid_attack_target(selected_unit, clicked_unit) == true:
			_initate_combat(selected_unit, clicked_unit)
		else:
			_on_select_unit(clicked_unit)

func _on_select_unit(selected_unit_new : Unit):
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
	in_attack_mode = false
	ui_node.in_attack_mode = false
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
		cursor_tile_information.buff_defence_value = defence_buff_value
		cursor_tile_information.buff_avoid_value = avoid_buff_value
		ui_node._update_terrain_info(cursor_tile_information)
		if selected_unit != null:
			map_node._update_movement_preview(selected_unit.unit_tile, cursor_tile)

#checks if the mouse curor is located on the map
func _mouse_within_bounds():
	var map_bounds_right = map_node.map_size.x * Globals.TILE_SIZE
	var map_bounds_bottom = map_node.map_size.y * Globals.TILE_SIZE
	var mouse_position = get_global_mouse_position()
	if mouse_position.x >= 0 and mouse_position.x < map_bounds_right and mouse_position.y >= 0 and mouse_position.y < map_bounds_bottom:
		#print("Mouse within mounds.")
		return true
	else:
		#print("Mouse not within mounds.")
		return false

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
	print("In action mode is set to: " + str(in_action))

func _on_set_attack_mode(attack_mode_state):
	in_attack_mode = attack_mode_state
	ui_node.in_attack_mode = attack_mode_state
	if in_attack_mode == true:
		map_node._calculate_targetable_tiles(selected_unit)
	else:
		map_node._toggle_movement_preview(true)
	print("In attack mode is set to: " + str(in_attack_mode))

func _initialize_unit_positions():
	for i in range(2):
		var unit_array = _get_unit_array(i)
		for j in map_node.get_child(i).get_child_count():
			var unit = map_node.get_child(i).get_child(j)
			unit_array.append(unit.unit_tile)
			var terrain_info = map_node._get_tile_information(unit.unit_tile)
			terrain_info.buff_defence_value = defence_buff_value
			terrain_info.buff_avoid_value = avoid_buff_value
			unit._set_terrain_info(terrain_info)
		print("Player " + str(i) + " unit positions: " + str(unit_array))

#updates the unit_position_array with the new position of the unit and erases the old position
func _on_new_unit_position(unit : Unit):
	#updates the array with the position of all units of this team
	var unit_array = _get_unit_array(unit.team)
	unit_array.erase(unit.unit_tile_previous)
	unit_array.append(unit.unit_tile)
	
	#determines the information of the new tile the unit stands on and sends it to the unit
	var terrain_info = map_node._get_tile_information(unit.unit_tile)
	terrain_info.buff_defence_value = defence_buff_value
	terrain_info.buff_avoid_value = avoid_buff_value
	unit._set_terrain_info(terrain_info)
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

#checks if target is in range of unit and belongs to the correct team
func _check_valid_attack_target(init_unit : Unit, target_unit : Unit):
	var min_range = init_unit.equipped_weapon.min_range
	var max_range = init_unit.equipped_weapon.max_range
	var unit_distance = _get_tile_distance(init_unit.unit_tile, target_unit.unit_tile)
	var weapon_attack_target = init_unit.equipped_weapon.weapon_type.target
	var target_team
	
	if init_unit.team == target_unit.team:
		target_team = "ally"
	else:
		target_team = "enemy"
	
	if weapon_attack_target == target_team:
		if unit_distance >= min_range and unit_distance <= max_range:
			return true
		else:
			return false
	else:
		return false
	

func _get_tile_distance(tile_id_1, tile_id_2):
	var distance_vector = tile_id_1  - tile_id_2
	var distance = abs(distance_vector.x) + abs(distance_vector.y)
	return distance

func _initate_combat(init_unit : Unit, tar_unit : Unit):
	var combat_data = Combat_Data.new()
	combat_data._calculate_combat_data(init_unit, tar_unit)
	_set_in_action(true)
	
	for i in combat_data.action_order.size():
		var acting_unit = combat_data.action_order[i]
		var defending_unit
		if acting_unit == combat_data.initiating_unit:
			defending_unit = combat_data.target_unit
		else:
			defending_unit = combat_data.initiating_unit
			
		if defending_unit.hp >= 0 and acting_unit.hp >= 0:
			print(acting_unit.unit.unit_name + " attacks " + defending_unit.unit.unit_name)
			_unit_attack(acting_unit, defending_unit)
		else:
			pass
	
	map_node._clear_reachable_tiles()
	_set_in_action(false)
	_on_set_attack_mode(false)
	ui_node._update_stat_info("all")
	init_unit._end_turn()

func _unit_attack(attacking_unit : Combat_Data_Unit, defending_unit : Combat_Data_Unit):
	randomize()
	var critical_multiplier
	
	if randi() % 100 < attacking_unit.hit_chance:
		print("hit")
		if randi() % 100 < attacking_unit.crit_chance:
			print("critical hit")
			critical_multiplier = critical_multiplier_value
		else:
			print("normal hit")
			critical_multiplier = 1
		defending_unit.hp -= attacking_unit.atk * critical_multiplier
		defending_unit.unit._set_hp(defending_unit.hp)
	else:
		print("miss")

func _on_unit_killed(unit):
	var unit_array = _get_unit_array(unit.team)
	print(str(unit_array))
	ui_node._update_unit_count(unit.team, -1)
	ui_node._on_unhover_unit(unit)
	unit_array.erase(unit.unit_tile)
	print(str(unit_array))
