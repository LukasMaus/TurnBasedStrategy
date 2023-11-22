extends CharacterBody2D

class_name Unit

@export_group("Characters Stats")
@export var character_class : Unit_Class
enum Behaviours {SEEK, GUARD, HOLD}
@export var behaviour : Behaviours
var player : Player
var team : int
var map : Map
#which player if currently moving
var active_player : Player

@export_group("Custom Stats")
@export var hp_max : int
@export var hp_cur : int
@export var attack : int
@export var dexterity : int
@export var speed : int
@export var defence : int
@export var resistance : int
@export var movement : int
var bst #base_stat_total
@export_enum ("right", "left", "up", "down") var direction : String
@export var Equip_Weapon_2 : bool

#chances based on units main stats
var hit_chance
var avoid_chance
var crit_chance

@onready var attack_bonus = 0
@onready var dexterity_bonus = 0
@onready var speed_bonus = 0
@onready var defence_bonus = 0
@onready var resistance_bonus = 0
@onready var movement_bonus = 0

#chances based on units stats, equipped weapon and terrain
var hit_chance_bonus
var avoid_chance_bonus
var crit_chance_bonus

#buffs based on terrain
@onready var terrain_defence_bonus = 0
@onready var terrain_resistance_bonus = 0
@onready var terrain_avoid_bonus = 0
@onready var terrain_dex_bonus = 0

var equipped_weapon : Weapon
var weapon_1 : Weapon
var weapon_2 : Weapon

#attack range of unit factoring in both weapons
var min_range
var max_range

@onready var heal_uses = 1
@onready var heal_value = 15

var unit_name
#number of the tile the unit stands on
var unit_tile
var unit_tile_previous
var unit_active

var avoid_threshhold = 30
enum Defensive_Types {NIMBLE, STURDY}
var defensive_type : Defensive_Types

var selected = false
var already_moved = false
var already_acted = false

@onready var sprite = $Sprite
@onready var hp_bar = $HPBar
@onready var anim_p = $AnimationPlayer
var damage_text = preload("res://scenes/FloatingText.tscn")

@onready var action_state = "idle"

var tiles_reachable : Array
var tiles_attackable : Array
var detection_range : Array
var possible_targets: Array
var possible_turns : Array

var enemy_units : Array

var movement_pattern
var action_pattern
var chosen_action_id

func _ready():
	Eventmanager.nextTurnStarted.connect(_on_next_turn_started)
	anim_p.animation_finished.connect(_on_animation_finished)

func _initialize_unit():
	unit_active = true
	_update_unit_tile()
	_initialize_unit_stats()
	_play_animation()

func _initialize_unit_stats():
	unit_name = get_name() + " | " + character_class.unit_name
	team = player.number - 1
	if team == 0:
		sprite.texture = character_class.texture_player
	else:
		sprite.texture = character_class.texture_enemy
	
	weapon_1 = character_class.weapon_1
	weapon_2 = character_class.weapon_2
	if Equip_Weapon_2 == true:
		equipped_weapon = weapon_2
	else:
		equipped_weapon = weapon_1
	
	#sets stats of the unit to class default values if not defined otherwise
	if hp_max == 0:
		hp_max = character_class.base_hp
	if hp_cur == 0:
		hp_cur = hp_max
	if attack == 0:
		attack = character_class.base_atk + weapon_1.attack
	else:
		attack += weapon_1.attack
	if dexterity == 0:
		dexterity = character_class.base_dex
	if speed == 0:
		speed = character_class.base_spd + weapon_1.weight * (-1)
	else:
		speed += weapon_1.weight * (-1)
	if defence == 0:
		defence = character_class.base_def
	if resistance == 0:
		resistance = character_class.base_res
	if movement == 0:
		movement = character_class.movement
	if direction == "":
		direction = "right"
	
	hit_chance = dexterity * 2 + weapon_1.hit_chance
	avoid_chance = speed * 2
	crit_chance = int(float(dexterity) / 2) + weapon_1.crit_chance
	
	if weapon_1.min_range <= weapon_2.min_range:
		min_range = weapon_1.min_range
	else:
		min_range = weapon_2.min_range
		
	if weapon_1.max_range >= weapon_2.max_range:
		max_range = weapon_1.max_range
	else:
		max_range = weapon_2.max_range
	bst = hp_max + attack + dexterity + speed + defence + resistance
	
	_initialize_health_bar()

func _update_unit_bonus():
	attack_bonus = equipped_weapon.attack - weapon_1.attack
	dexterity_bonus = terrain_dex_bonus
	speed_bonus = equipped_weapon.weight * (-1) - weapon_1.weight * (-1)
	defence_bonus = terrain_defence_bonus
	resistance_bonus = terrain_resistance_bonus
	
	hit_chance_bonus = equipped_weapon.hit_chance - weapon_1.hit_chance + dexterity_bonus * 2
	avoid_chance_bonus = terrain_avoid_bonus
	crit_chance_bonus = equipped_weapon.crit_chance - weapon_1.crit_chance
	_set_defense_type()
	
	Eventmanager.emit_signal("unitStatsUpdated", self)

func _set_defense_type():
	if avoid_chance + avoid_chance_bonus >= avoid_threshhold:
		defensive_type = Defensive_Types.NIMBLE #focuses on avoid buffs
	else:
		defensive_type = Defensive_Types.STURDY #focuses on defensive buffs

func _update_unit_tile():
	unit_tile_previous = unit_tile
	unit_tile = Globals._get_tile_id(self.get_global_position())
	Eventmanager.emit_signal("newUnitPosition", self)

func _on_unit_clicked(_viewport, event, _shape_idx):
	if event.is_action_pressed("select_unit") and selected == false:
		print(unit_name + " is clicked")
		Eventmanager.emit_signal("clickedUnit", self)

func _on_unit_hovered():
	#print(str(unit_name) + " hovered.")
	Eventmanager.emit_signal("hoverUnit", self)

func _on_unit_unhovered():
	#print(str(unit_name) + " unhovered.")
	Eventmanager.emit_signal("unhoverUnit", self)

func _unit_selected():
	selected = true
	print(unit_name + " was selected.")
	#print(tiles_attackable)

func _unit_unselected():
	selected = false
	if already_moved == true and already_acted == false:
		_reset_unit()
	#print(unit_name + " was unselected.")

func _on_next_turn_started(next_player):
	_free_unit_actions()
	if player == active_player:
		if selected == true:
			_reset_unit()
		if unit_active == false:
			queue_free()
	active_player = next_player

func _free_unit_actions():
	already_moved = false
	already_acted = false
	tiles_reachable.clear()
	tiles_attackable.clear()
	sprite.self_modulate = Color(1, 1, 1)

func _move(move_info : Move_Info):
	var path = move_info.movement_path
	var tween = create_tween()
	var path_size = path.size() - 1
	var mov_speed = 0.2
	_set_action_state("move")
	Eventmanager.emit_signal("unitMove", true)
	for i in path_size:
		tween.tween_callback(self._set_unit_direction.bind(path[i], path[i + 1]))
		tween.tween_callback(self._play_animation)
		tween.tween_property(self, "position", path[i + 1], mov_speed)
	already_moved = true
	await get_tree().create_timer(path_size * mov_speed).timeout
	#updates position manually since the tween is not pixel perfect which can lead to misscalculation during _update_unit_tile()
	self.position = path[path.size() - 1]
	_set_action_state("idle")
	_play_animation()
	_update_unit_tile()
	print(unit_name + " moved to tile: " + str(unit_tile))
	Eventmanager.emit_signal("unitMove", false)

func _reset_unit():
	if already_moved == true and already_acted == false:
		self.position = unit_tile_previous * Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE)
		_update_unit_tile()
		already_moved = false
		print(unit_name + " has been reset.")

func _equip_weapon(weapon_number):
	equipped_weapon = get("weapon_" + str(weapon_number))
	_update_unit_bonus()

func _heal():
	if heal_uses > 0:
		if hp_cur == hp_max:
			print("HP already full.")
		else:
			_change_hp(heal_value, "heal")
			heal_uses -= 1
			print("Unit heals itself.")
			_end_turn()
			Eventmanager.emit_signal("clickedUnit", self)
	else:
		print("No uses of heal available.")

func _wait():
	print(unit_name + " waits.")
	_end_turn()
	Eventmanager.emit_signal("clickedUnit", self)

func _end_turn():
	already_moved = true
	already_acted = true
	unit_tile_previous = unit_tile
	sprite.self_modulate = Color(0.5, 0.5, 0.5)

func _change_hp(amount, hit_type):
	var lethal = false
	_instance_damage_text(amount, hit_type)
	if hit_type != "heal":
		hp_cur -= amount
		if hp_cur <= 0:
			lethal = true
			_kill_unit()
	else:
		hp_cur += amount
		if hp_cur > hp_max:
			hp_cur = hp_max
	_update_health_bar()
	Eventmanager.emit_signal("attackEnded", lethal)

func _initialize_health_bar():
	hp_bar.min_value = 0
	hp_bar.max_value = hp_max
	hp_bar.value = hp_cur

func _update_health_bar():
	hp_bar.value = hp_cur

func _kill_unit():
	print(unit_name + " has been killed.")
	unit_active = false
	player.units.erase(self)
	player.unit_positions.erase(unit_tile)
	hp_bar.visible = false
	_set_action_state("death")
	_play_animation()
	await get_tree().create_timer(anim_p.get_current_animation_length()).timeout
	self.visible = false
	Eventmanager.emit_signal("unitKilled", self)

func _instance_damage_text(amount, type):
	var text = damage_text.instantiate()
	text.amount = amount
	text.type = type
	add_child(text)

func _set_terrain_info(terrain_info : Terrain_Info):
	if terrain_info.buff_defence == true:
		terrain_defence_bonus = terrain_info.buff_defence_value
		terrain_resistance_bonus = terrain_info.buff_defence_value
	elif terrain_info.debuff_resistance == true:
		terrain_defence_bonus = 0
		terrain_resistance_bonus = terrain_info.debuff_resistance_value * (-1)
	else:
		terrain_defence_bonus = 0
		terrain_resistance_bonus = 0
	
	if terrain_info.buff_avoid == true:
		terrain_avoid_bonus = terrain_info.buff_avoid_value
	elif terrain_info.debuff_avoid == true:
		terrain_avoid_bonus = terrain_info.debuff_avoid_value * (-1)
	else:
		terrain_avoid_bonus = 0
	
	if terrain_info.buff_dex == true:
		terrain_dex_bonus = terrain_info.buff_dex_value
	elif terrain_info.debuff_dex == true:
		terrain_dex_bonus = terrain_info.debuff_dex_value * (-1)
	else:
		terrain_dex_bonus = 0
	
	_update_unit_bonus()

func _set_action_state(action_state_value):
	action_state = action_state_value

func _set_unit_direction(initial_tile, destination_tile):
	var distance = initial_tile - destination_tile
	#destination is further in x direction then y
	if abs(distance.x) >= abs(distance.y):
		#destination is located to the right of the unit
		if distance.x <= 0:
			direction = "right"
		#destination is located to the left of the unit
		else:
			direction = "left"
	#destiantion is further in y direction then x direction
	else:
		#destination is located under the unit
		if distance.y <= 0:
			direction = "down"
		#destination is located above the unit
		else:
			direction = "up"

func _play_animation():
	var animation_name
	if direction == "left":
		sprite.flip_h = true
		animation_name = "unit_" + action_state + "_right"
	else:
		sprite.flip_h = false
		animation_name = "unit_" + action_state + "_" + direction
	#print("Animation: " + animation_name)
	anim_p.play(animation_name)

func _on_animation_finished(_anim_name):
	_set_action_state("idle")
	_play_animation()

### AI script ###
func _process_ai_turn(enemies : Array):
	enemy_units = enemies
	print("--------")
	print(unit_name + " | " + str(str(unit_tile)))
	_make_decision()								#decides which movement pattern and which action is taken
	_interpret_patterns()							#reduced amount of opssible turns based on movement- and action pattern
	_calculate_turns(-10)							#calculates all possible turns, evaluates them and saves them in possible_turns
	_get_best_turn(5)								#finds out the best turn out of all available
	return possible_turns

#calculates every tile the unit can currently move to
func _calculate_reachable_tiles():
	map._calculate_reachable_tiles(self)

#calculates the tiles it can detect enemies on
func _get_detection_range():
	detection_range.clear()
	match behaviour:
		0:	#SEEK - detects all enemies on map
			for i in enemy_units.size():
				_append_detection_range(enemy_units[i].unit_tile)
		1:	#GUARD - detects enemies in attackable range
			#_calculate_reachable_tiles()
			detection_range = tiles_attackable.duplicate()
		2:	#HOLD - detects enemies in immediate range
			for x in range(-max_range, max_range + 1):
				for y in range(-max_range, max_range + 1):
					#tile is more tiles away then max_range
					if abs(x) + abs(y) > max_range:
						continue
					#tile is fewer tiles away then min_range
					elif abs(x) + abs(y) < min_range:
						continue
					else:
						_append_detection_range(unit_tile + Vector2(x, y))

#appends a tile to the detection range if it is not already in it
func _append_detection_range(tile : Vector2):
	if detection_range.has(tile) == false:
		detection_range.append(tile)

#calculates every enemy the unit can currently target
func _get_possible_targets(examine_range : Array, enemy : bool) -> Array:
	possible_targets.clear()
	var search_array
	if enemy == true:
		search_array = enemy_units
	else:
		search_array = player.units
	for i in search_array.size():
		if examine_range.has(search_array[i].unit_tile) == true and examine_range.find(search_array[i].unit_tile) != examine_range.find(unit_tile):
			possible_targets.append(search_array[i])
	return possible_targets

#calculates movement pattern and action
func _make_decision():
	var root_node = Decision_Wounded.new()
	root_node.unit = self
	var decision : Action
	#starts rekursive decision tree
	decision = root_node.makeDecision(self)
	movement_pattern = decision.MovementPatterns.keys()[decision.movement_pattern]
	action_pattern = decision.Actions.keys()[decision.action]
	print(movement_pattern)
	print(action_pattern)

#restrict certain moves and actions based on movement pattern and action
func _interpret_patterns():
	match str(movement_pattern):
		#unit can only move to the tile it is currently on
		"STAY":
			tiles_reachable.clear()
			tiles_reachable.append(unit_tile)
		#unit can move on every tile in movement range + own tile
		"FLEE":
			tiles_reachable.append(unit_tile)
		#if no unit is in attack range calculates best target to move to
		"ASSAULT":
			print("Possible targets: " + str(possible_targets.size()))
			if possible_targets.is_empty() == true:
				tiles_reachable.clear()
				tiles_reachable.append(_simulate_combat_all_enemies())
	match str(action_pattern):
		"ATTACK":
			chosen_action_id = null
		"HEAL":
			chosen_action_id = 3
		"WAIT":
			chosen_action_id = 4

func _calculate_turns(minimax_evaluation_score : int):
	possible_turns.clear()
	#for every tile the unit can move on
	for i in tiles_reachable.size():
		if player.unit_positions.has(tiles_reachable[i]) == false or tiles_reachable.find(tiles_reachable[i]) == tiles_reachable.find(unit_tile):
			var initial_tile = unit_tile
			var initial_weapon = equipped_weapon
			
			#if the unit does not indend to attack
			if chosen_action_id != null:
				var turn = Turn.new()
				turn.unit = self
				turn.move_tile = tiles_reachable[i]
				turn.action_id = chosen_action_id
				turn.target_unit = self
				turn.combat_data = null
				turn.evaluation = _evaluate_non_combat_turn(turn)
				possible_turns.append(turn)
			#if the unit intends to attack
			else:
				possible_targets = _get_possible_targets(tiles_attackable, true)
				#for every weapon the unit can equip
				for k in range(2):
					_equip_weapon(k+1)
					#if weapon targets enemies
					if equipped_weapon.weapon_type.target != "ally":
						for j in possible_targets.size():
							var turn = Turn.new()
							turn.unit = self
							turn.move_tile = tiles_reachable[i]
							turn = _simulate_combat(turn, possible_targets[j], tiles_reachable[i], k+1)
							#if the evaluation value meets the minimal_evaluation_score
							if turn.evaluation > minimax_evaluation_score:
								possible_turns.append(turn)
					#if weapon targets allies
					else:
						possible_targets = _get_possible_targets(tiles_attackable, false)
						for j in possible_targets.size():
							var turn = Turn.new()
							turn.unit = self
							turn.move_tile = tiles_reachable[i]
							#if the target is not full health
							if possible_targets[j].hp_cur < possible_targets[j].hp_max:
								turn = _simulate_combat(turn, possible_targets[j], tiles_reachable[i], k+1)
							else:
								turn.action_id = 4
								turn.target_unit = self
								turn.combat_data = null
								turn.evaluation = -99 
							#if the evaluation value meets the minimal_evaluation_score
							if turn.evaluation > minimax_evaluation_score:
								possible_turns.append(turn)
						possible_targets = _get_possible_targets(tiles_attackable, true)
				_return_unit_to_initial_values(initial_tile, initial_weapon)

#checks if there is a possible target if unit moves to tile and evaluates if so
func _simulate_combat(turn : Turn, target : Unit, tile : Vector2, weapon_number : int) -> Turn:
	unit_tile = tile
	turn.unit = self
	#if enemy an enemy within range of the weapon
	if _check_enemy_in_range(unit_tile, target.unit_tile, equipped_weapon) == true:
		_set_terrain_info(map._get_tile_information(unit_tile))
		var combat_data = Combat_Data.new()
		combat_data._calculate_combat_data(self, target)
		turn.action_id = weapon_number
		turn.target_unit = target
		turn.combat_data = combat_data
		turn.evaluation = float(combat_data.initiating_unit.evaluation_score)
	#if no enemy is within range of the weapon
	else:
		turn.action_id = 4
		turn.target_unit = self
		turn.combat_data = null
		turn.evaluation = -99
	return turn

#simulates combat with all enemies and returns the tile to move in direction of best enemy to fight
func _simulate_combat_all_enemies():
	var initial_tile = unit_tile
	var initial_weapon = equipped_weapon
	var highest_score : float
	var destination
	for i in enemy_units.size():
		#simulates combat with each unit - weapon 1 - minimal attack range -  no terrain modifiers
		var current_score : float
		var combat_data = Combat_Data.new()
		_equip_weapon(1)
		unit_tile = enemy_units[i].unit_tile + Vector2(0, equipped_weapon.min_range)
		combat_data._calculate_combat_data(self, enemy_units[i])
		
		#calculates a path to the enemy
		map.astar_grid.set_point_solid(enemy_units[i].unit_tile, false)
		var path = map.astar_grid.get_id_path(initial_tile, enemy_units[i].unit_tile)
		var turns_to_reach_enemy = ceil(path.size() / movement)
		map.astar_grid.set_point_solid(enemy_units[i].unit_tile, true)
		
		#gets furthest tile available to move to on the path
		var cost = 0
		for j in path.size() - 1:
			var next_tile_cost = map.astar_grid.get_point_weight_scale(path[j + 1])
			if cost + next_tile_cost <= movement:
				destination = path[j + 1]
				cost += next_tile_cost
		
		#score is determined by evaluation of fight and number of turns to reach the enemy
		if turns_to_reach_enemy != 0:
			current_score = combat_data.initiating_unit.evaluation_score / turns_to_reach_enemy
		else:
			current_score = combat_data.initiating_unit.evaluation_score
		
		#if current score is higher than highest score replace highest score with current
		if possible_targets.is_empty() == true:
			possible_targets.append(enemy_units[i])
			highest_score = current_score
		elif current_score > highest_score:
			possible_targets.clear()
			possible_targets.append(enemy_units[i])
			highest_score = current_score
		else:
			pass
	print(destination)
	_return_unit_to_initial_values(initial_tile, initial_weapon)
	return destination

#evaluates turns who do not take an attack action
func _evaluate_non_combat_turn(turn : Turn) -> float:
	var final_threat : float
	var tile_data_l0 = map.get_cell_tile_data(0, turn.move_tile)
	var tile_data_l1 = map.get_cell_tile_data(1, turn.move_tile)
	var tile_data	#tile containing the data of the tile - can be on layer 0 or 1
	var current_threat = map.threat[map._get_threat_position(turn.move_tile)]
	var threat_multiplier
	#sets thread based on movement pattern
	match str(movement_pattern):
		"STAY":
			final_threat = 0
		"ASSAULT":
			pass
		"FLEE":
			#gets the data of the tile the unit is moving to
			if tile_data_l1 != null:
				tile_data = tile_data_l1
			else:
				tile_data = tile_data_l0
			
			#chechs defensive type of unit and buff of the tile to determine the threat multiplier
			if defensive_type == Defensive_Types.NIMBLE:
				if tile_data.get_custom_data("buff_avoid") == true:	#nimble favors avoid buffs
					threat_multiplier = 0.5
				elif tile_data.get_custom_data("debuff_avoid") == true:	#nimble avoids avoid debuffs
					threat_multiplier = 2
				else:
					threat_multiplier = 1
			else:
				if tile_data.get_custom_data("buff_def/res") == true:	#sturdy favors defensive buffs
					threat_multiplier = 0.5
				elif tile_data.get_custom_data("debuff_res") == true:	#sturdy avoids defensive debuffs
					threat_multiplier = 2
				else:
					threat_multiplier = 1
			#calculates final_thread based on evaluaton of tactical analysis and the multiplier
			final_threat = current_threat * threat_multiplier * (-1)
	return final_threat

func _return_unit_to_initial_values(initial_tile : Vector2, initial_weapon : Weapon):
	unit_tile = initial_tile
	_set_terrain_info(map._get_tile_information(unit_tile))
	equipped_weapon = initial_weapon
	_update_unit_bonus()

#sorts the array by highest evaluation and resizes it to turn_amount
func _get_best_turn(turn_amount : int):
	possible_turns.sort_custom(_sort_turns)
	if possible_turns.size() > turn_amount:
		possible_turns.resize(turn_amount)
	var possible_turns_value : Array
	for i in possible_turns.size():
		possible_turns_value.append(possible_turns[i].evaluation)
	print("Turns by value: " + str(possible_turns_value))

func _sort_turns(turn_a : Turn, turn_b : Turn):
	if turn_a.evaluation > turn_b.evaluation:
		return true
	else:
		return false

func _check_enemy_in_range(test_tile : Vector2, target_tile : Vector2, weapon : Weapon) -> bool:
	var distance = Globals._get_tile_distance(test_tile, target_tile)
	if distance >= weapon.min_range and distance <= weapon.max_range:
		return true
	else:
		return false
