extends Node2D

var player_1 : Player
var player_2 : Player
var active_player : Player
var inactive_player : Player
var selected_unit : Unit
var game_active : bool
@onready var in_action = false	#true if animation is currently playing
@onready var in_attack_mode = false #true if character is looking for target to attack

@onready var map_node : Map = $Map
@onready var ui_node = $HUD
@onready var cursor = $Cursor
@onready var cursor_tile = Vector2(0, 0)
var cursor_tile_information

@export var debug_mode : bool
var anomaly : bool

func _ready():
	_initialize_players(map_node.blue_player_control, map_node.red_player_control)
	active_player = player_1
	inactive_player = player_2
	map_node._set_units_to_solid(active_player.unit_positions, inactive_player.unit_positions)
	ui_node._initialize_ui(debug_mode, active_player, player_1.units.size(), player_2.units.size())
	Eventmanager.clickedUnit.connect(_on_clicked_unit)
	Eventmanager.unselectUnit.connect(_on_unselect_unit)
	Eventmanager.endTurn.connect(_on_next_turn)
	Eventmanager.unitMove.connect(_set_in_action)
	Eventmanager.unitKilled.connect(_on_unit_killed)
	Eventmanager.setAttackMode.connect(_on_set_attack_mode)
	Eventmanager.newUnitPosition.connect(_on_new_unit_position)
	Eventmanager.getEnemyUnits.connect(_on_get_enemy_units)
	game_active = true
	if active_player.control == "AI":
		await get_tree().create_timer(1.0).timeout
		_start_ai_turn()

func _process(_delta):
	if cursor_tile != Globals._get_tile_id(get_global_mouse_position()):
		_update_cursor()
	_check_input()

func _check_input():
	if Input.is_action_just_pressed("menu"):
		ui_node._toggle_menu_button()
	
	if active_player.control == "Player" and in_action == false:
		if Input.is_action_just_pressed("unselect_unit"):
			_on_unselect_unit()
		if Input.is_action_just_pressed("unit_move") and selected_unit != null and selected_unit.unit_tile != cursor_tile and selected_unit.already_moved == false and selected_unit.player == active_player:
			if _mouse_within_bounds() == true:
				var movement_path = map_node.movement_preview.points
				if movement_path.size() != 0:
					var destination = movement_path[movement_path.size() - 1] / Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE)
					if _check_unit_position(destination) == true:
						print("Tile occupied by own unit")
					else:
						#checks if the movement_path is viable
						if cursor_tile in selected_unit.tiles_reachable:
							var move_info = Move_Info.new()
							move_info.movement_path = movement_path
							selected_unit._move(move_info)
				else:
					print("No path to destination")
		if Input.is_action_just_pressed("action_weapon_1") and selected_unit != null and selected_unit.already_acted == false and selected_unit.player == active_player:
			ui_node._on_weapon_pressed(1)
		if Input.is_action_just_pressed("action_weapon_2") and selected_unit != null and selected_unit.already_acted == false and selected_unit.player == active_player:
			ui_node._on_weapon_pressed(2)
		if Input.is_action_just_pressed("action_heal") and selected_unit != null and selected_unit.already_acted == false and selected_unit.player == active_player:
			ui_node._on_heal_pressed()
		if Input.is_action_just_pressed("action_wait") and selected_unit != null and selected_unit.already_acted == false and selected_unit.player == active_player:
			ui_node._on_wait_pressed()

func _on_clicked_unit(clicked_unit : Unit):
	if in_action == false:
		if in_attack_mode == true and _check_valid_attack_target(selected_unit, clicked_unit) == true:
			_initiate_combat(selected_unit, clicked_unit)
		else:
			_on_select_unit(clicked_unit)

func _on_select_unit(selected_unit_new : Unit):
	_on_unselect_unit()
	selected_unit = selected_unit_new
	selected_unit._unit_selected()
	ui_node._select_unit(selected_unit)
	if selected_unit.already_moved == false and selected_unit.already_acted == false:
		if selected_unit.player == player_1:
			map_node._set_units_to_solid(player_1.unit_positions, player_2.unit_positions)
		else:
			map_node._set_units_to_solid(player_2.unit_positions, player_1.unit_positions)
		map_node._calculate_reachable_tiles(selected_unit)
		map_node._paint_tiles(selected_unit)
		map_node._update_movement_preview(selected_unit.unit_tile, cursor_tile)
		if selected_unit.player == active_player and selected_unit.player.control == "Player":
			map_node._toggle_movement_preview(true)

func _on_unselect_unit():
	if selected_unit != null:
		selected_unit._unit_unselected()
		ui_node._unselect_unit()
	selected_unit = null
	_on_set_attack_mode(false)
	ui_node._set_in_attack_mode(false)
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
	if active_player == player_1:
		active_player = player_2
		inactive_player = player_1
	else:
		active_player = player_1
		inactive_player = player_2
	map_node._set_units_to_solid(active_player.unit_positions, inactive_player.unit_positions)
	_on_unselect_unit()
	if active_player.control == "AI" and game_active == true:
		_start_ai_turn()
	Eventmanager.emit_signal("nextTurnStarted", active_player)

func _set_in_action(in_action_state):
	in_action = in_action_state
	ui_node._set_in_action_mode(in_action_state)
	#print("In action mode is set to: " + str(in_action))

func _on_set_attack_mode(attack_mode_state):
	in_attack_mode = attack_mode_state
	ui_node._set_in_attack_mode(attack_mode_state)
	if in_attack_mode == true:
		map_node._paint_attack_action(selected_unit)
	else:
		map_node._toggle_movement_preview(true)
	#print("In attack mode is set to: " + str(in_attack_mode))

func _initialize_players(control_player_1, control_player_2):
	player_1 = Player.new()
	player_1.number = 1
	player_1.control = control_player_1
	
	player_2 = Player.new()
	player_2.number = 2
	player_2.control = control_player_2
	
	_initialize_player_units(player_1)
	_initialize_player_units(player_2)
	print("Players initalized")

func _initialize_player_units(player : Player):
	for i in map_node.get_child(player.number - 1).get_child_count():
		var unit = map_node.get_child(player.number - 1).get_child(i)
		unit.player = player
		unit.map = map_node
		unit._initialize_unit()
		player.units.append(unit)
		player.unit_positions.append(unit.unit_tile)
		var terrain_info = map_node._get_tile_information(unit.unit_tile)
		unit._set_terrain_info(terrain_info)
	print("Player " + str(player.number) + " unit positions: " + str(player.unit_positions))

#updates the unit_position_array with the new position of the unit and erases the old position
func _on_new_unit_position(unit : Unit):
	#updates the array with the position of all units of this team
	var unit_array = unit.player.unit_positions
	unit_array.erase(unit.unit_tile_previous)
	unit_array.append(unit.unit_tile)
	
	#determines the information of the new tile the unit stands on and sends it to the unit
	var terrain_info = map_node._get_tile_information(unit.unit_tile)
	unit._set_terrain_info(terrain_info)
	#print("Player " + str(player) + " unit positions: " + str(unit_array))


#checks if the position is occupied by another unit of the player
func _check_unit_position(unit_position):
	var unit_array = active_player.unit_positions
	var space_occupied = unit_array.find(unit_position)
	if space_occupied == -1:
		return false
	else:
		return true

#checks if target is in range of unit and belongs to the correct team
func _check_valid_attack_target(init_unit : Unit, target_unit : Unit):
	var min_range = init_unit.equipped_weapon.min_range
	var max_range = init_unit.equipped_weapon.max_range
	var unit_distance = Globals._get_tile_distance(init_unit.unit_tile, target_unit.unit_tile)
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

func _initiate_combat(init_unit : Unit, tar_unit : Unit):
	var combat_data = Combat_Data.new()
	anomaly = false	#is true if an attack missed or struck critical during combat
	combat_data._calculate_combat_data(init_unit, tar_unit)
	_set_in_action(true)
	map_node._clear_movement_preview()
	
	init_unit._set_unit_direction(init_unit.unit_tile, tar_unit.unit_tile)
	tar_unit._set_unit_direction(tar_unit.unit_tile, init_unit.unit_tile)
	init_unit._play_animation()
	tar_unit._play_animation()
	
	for i in combat_data.action_order.size():
		var acting_unit = combat_data.action_order[i]
		var defending_unit
		if acting_unit == combat_data.initiating_unit:
			defending_unit = combat_data.target_unit
		else:
			defending_unit = combat_data.initiating_unit
		
		if defending_unit.hp > 0 and acting_unit.hp > 0:
			_unit_attack(acting_unit, defending_unit)
		else:
			break
		await get_tree().create_timer(0.8).timeout
	
	_set_in_action(false)
	ui_node._update_stat_info("all")
	init_unit._end_turn()
	Eventmanager.emit_signal("combatFinished")
	_on_unselect_unit()
	

func _unit_attack(attacking_unit : Combat_Data_Unit, defending_unit : Combat_Data_Unit):
	randomize()
	var hit_type
	var critical_multiplier : int
	var damage_value : int
	anomaly = false
	
	attacking_unit.unit._set_action_state("attack")
	attacking_unit.unit._play_animation()
	if randi() % 100 < attacking_unit.hit_chance:
		if randi() % 100 < attacking_unit.crit_chance:
			hit_type = "critical"
			critical_multiplier = 2
			anomaly = true
		else:
			hit_type = "hit"
			critical_multiplier = 1
		if attacking_unit.hit_type == "heal":
			hit_type = "heal"
		damage_value = attacking_unit.atk * critical_multiplier
		defending_unit.hp -= damage_value
		defending_unit.unit._change_hp(damage_value, hit_type)
	else:
		defending_unit.unit._set_action_state("dodge")
		defending_unit.unit._play_animation()
		hit_type = "miss"
		defending_unit.unit._change_hp(0, hit_type)
		anomaly = true

func _on_unit_killed(unit):
	ui_node._update_unit_count(unit.team, -1)
	ui_node._on_unhover_unit(unit)
	if unit == selected_unit:
		ui_node._unselect_unit()
	_check_winning_condition()

func _check_winning_condition():
	if player_1.unit_positions.is_empty() == true:
		game_active = false
		Eventmanager.emit_signal("gameEnded", 1)
	if player_2.unit_positions.is_empty() == true:
		game_active = false
		Eventmanager.emit_signal("gameEnded", 0)

func _on_get_enemy_units(askingUnit : Unit, searchingRange : Array):
	var searchArray
	if askingUnit.player.number == 1:
		searchArray = player_2.units
	else:
		searchArray = player_1.units
	if searchingRange.is_empty() != true:
		for i in searchArray.size():
			if askingUnit.tiles_attackable.find(searchArray[i].unit_tile) != -1:
				askingUnit.possible_targets.append(searchArray[i])
	else:
		askingUnit.possible_targets = searchArray


### AI script ###
func _start_ai_turn():
	print("***AI turn starts***")
	var unit_turns = []
	
	### tactical analysis
	map_node._tactical_analysis(active_player)
	print("***Tactical analysis finished***")
	
	### decision making and pathfinding
	for i in active_player.units.size():
		var new_turn = active_player.units[i]._process_ai_turn(inactive_player.units)
		unit_turns.append(new_turn)
	print("***Decision making finished***")
	
	### strategy
	#splits turn in attack turns and non-attack turns
	var turns = _split_turns(unit_turns)
	var attack_turns = turns[0]
	var non_attack_turns = turns[1]
	_sort_turns_by_value(attack_turns)
	_sort_turns_by_value(non_attack_turns)
	
	#gather turn sequences and excutes them
	while attack_turns.is_empty() == false:
		#the best found sequence
		var best_turn_sequence : Array
		
		#the current board state
		var current_board : Board = Board.new()
		current_board = current_board._new(attack_turns, [], [], 0, 1, 1.0)
		#finds the best turn sequence with minimax
		var best_board = _minimax(current_board, 3, 0)
		#if no lethal sequence was found, end the minimax
		if best_board.lethal == false:
			break
		best_turn_sequence = best_board.turn_sequence.duplicate()
		print("Minimax Sequence size: " + str(best_turn_sequence.size()))
		
		### turn execution of coordinated actions
		for i in best_turn_sequence.size():
			#executes a turn of the sequence
			_execute_turn(best_turn_sequence[i])
			await Eventmanager.aiTurnFinished
			#removes turns that cannot be taken anymore after the previous turn was taken
			attack_turns = _tidy_up_array(attack_turns, best_turn_sequence[i])
			#if attack during combat missed or crit recalculate the sequence
			if anomaly == true:
				await get_tree().create_timer(0.2).timeout
				break
	print("***Minimax finished***")
	
	### turn execution of remaining turns
	var counter : int
	#turn execution of remaining turns
	turns.clear()
	#rejoins arrays with attack and non-attack actions
	turns.append_array(attack_turns)
	turns.append_array(non_attack_turns)
	#as long as there are still possible turns available
	while turns.is_empty() == false:
		#if move tile of turn is occuppied
		if inactive_player.unit_positions.has(turns[0].move_tile) == true or active_player.unit_positions.has(turns[0].move_tile) == true and active_player.unit_positions.find(turns[0].move_tile) != active_player.unit_positions.find(turns[0].unit.unit_tile):
			counter += 1
			turns.remove_at(0)
			if counter > 50:
				break
		else:
			#execute the turn with the highest evaluation score
			_execute_turn(turns[0])
			#removes turns that cannot be taken anymore after the previous turn was taken
			turns = _tidy_up_array(turns, turns[0])
			await Eventmanager.aiTurnFinished
	
	#ends ai turn
	print("***AI turn ends***")
	Eventmanager.emit_signal("endTurn")

#split turns with attack and non-attack actions into two arrays
func _split_turns(available_turns : Array) -> Array:
	var attack_turns : Array
	var non_attack_turns : Array
	for i in available_turns.size():
		for j in available_turns[i].size():
			if available_turns[i][j].action_id == 1 or available_turns[i][j].action_id == 2:
				attack_turns.append(available_turns[i][j])
			else:
				non_attack_turns.append(available_turns[i][j])
	return [attack_turns, non_attack_turns]

#sort turns by evaluation value
func _sort_turns_by_value(turns : Array):
	turns.sort_custom(_sort_turns)

func _sort_turns(turn_a : Turn, turn_b : Turn):
	if turn_a.evaluation > turn_b.evaluation:
		return true
	else:
		return false

#removes turns that cannot be taken anymore after the turn in the parameter was taken
func _tidy_up_array(array : Array, turn : Turn):
	var index : Array
	for i in array.size():
		#deletes every move that is carried out by a unit of a previous move, does not target the same unit as the previous move or moves to a tile that has been occuppied by a previous move
		if array[i].unit == turn.unit or array[i].target_unit.unit_active == false or array[i].move_tile == turn.move_tile or active_player.unit_positions.has(turn.move_tile) == true and active_player.unit_positions.find(turn.move_tile) != active_player.unit_positions.find(turn.unit.unit_tile):
			index.append(i)
	index.reverse()
	for j in index.size():
		array.remove_at(index[j])
	return array

#minimax-algorithm
func _minimax(board : Board, maxDepth : int, currentDepth : int) -> Board:
	#check if done recursing - attack is lethal, maxDepth reached or no move possible
	if board.lethal == true or currentDepth == maxDepth or board.possible_moves.is_empty() == true:
		return board
	
	var bestBoard : Board = Board.new()
	#go through each move
	for i in board.possible_moves.size():
		#creates a new board state and advances one move
		var newBoard : Board = Board.new()
		newBoard = newBoard._new(board.possible_moves, board.turn_sequence, board.tiles_moved, board.dmg_total, board.enemy_hp, board.success_chance)
		newBoard._makeMove(board.possible_moves[i])
		
		#recurse
		var currentBoard : Board = Board.new()
		currentBoard = _minimax(newBoard, maxDepth, currentDepth + 1)
		
		#update the best score
		if currentBoard._evaluate() > bestBoard.success_chance:
			bestBoard = bestBoard._new(currentBoard.possible_moves, currentBoard.turn_sequence, currentBoard.tiles_moved, currentBoard.dmg_total, currentBoard.enemy_hp, currentBoard.success_chance)
		
	#return the score and the best move
	return bestBoard

#unit executes a single turn
func _execute_turn(turn : Turn):
	print("Move to: " + str(turn.move_tile) + " | Use action: " + str(turn.action_id) + " | Attack enemy: " + str(turn.target_unit) + " | Evaluation: " + str(turn.evaluation))
	
	#unit movement
	var path = Move_Info.new()
	path.movement_path = map_node._get_path(turn.unit.unit_tile, turn.move_tile)
	if path.movement_path.size() > 1:
		turn.unit._move(path)
		await get_tree().create_timer(0.8).timeout
	
	#unit action
	match turn.action_id:
		1,2:
			if turn.target_unit.unit_active == true:
				turn.unit._equip_weapon(turn.action_id)
				_initiate_combat(turn.unit, turn.target_unit)
				await Eventmanager.combatFinished
		3:
			turn.unit._heal()
		4:
			turn.unit._wait()
		_:
			print("No action id designated within turn.")
	await get_tree().create_timer(0.2).timeout
	print("Unit turn finished.")
	Eventmanager.emit_signal("aiTurnFinished")
