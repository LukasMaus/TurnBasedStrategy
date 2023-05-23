extends CharacterBody2D

class_name Unit

@export_group("Characters Stats")
@export var character_class : Unit_Class
@export_enum ("Player", "Enemy") var team = 0

@export_group("Custom Stats")
@export var hp_max : int
@export var hp_cur : int
@export var attack : int
@export var dexterity : int
@export var speed : int
@export var defence : int
@export var resistance : int
@export var movement : int

#chances based on units main stats
var hit_chance_base
var avoid_chance_base
var crit_chance_base

#chances based on units stats, equipped weapon and terrain
var hit_chance
var avoid_chance
var crit_chance

@onready var attack_bonus = 0
@onready var dexterity_bonus = 0
@onready var speed_bonus = 0
@onready var defence_bonus = 0
@onready var resistance_bonus = 0
@onready var movement_bonus = 0
@onready var terrain_defence_bonus = 0
@onready var terrain_avoid_bonus = 0

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
#which player if currently moving
var active_player = 0

var selected = false
var already_moved = false
var already_acted = false

func _ready():
	unit_name = get_name()
	_initialize_unit_stats()
	_update_unit_tile()
	
	Eventmanager.nextTurnStarted.connect(_on_next_turn_started)

func _initialize_unit_stats():
	if team == 0:
		$Sprite.texture = character_class.texture_player
	else:
		$Sprite.texture = character_class.texture_enemy
	
	#sets stats of the unit to class default values if not defined otherwise
	if hp_max == 0:
		hp_max = character_class.base_hp
	if hp_cur == 0:
		hp_cur = hp_max
	if attack == 0:
		attack = character_class.base_atk
	if dexterity == 0:
		dexterity = character_class.base_dex
	if speed == 0:
		speed = character_class.base_spd
	if defence == 0:
		defence = character_class.base_def
	if resistance == 0:
		resistance = character_class.base_res
	if movement == 0:
		movement = character_class.movement
	
	hit_chance_base = dexterity * 2
	avoid_chance_base = speed * 2
	crit_chance_base = int(float(dexterity) / 2)
	
	weapon_1 = character_class.weapon_1
	weapon_2 = character_class.weapon_2
	equipped_weapon = weapon_1
	
	if weapon_1.min_range <= weapon_2.min_range:
		min_range = weapon_1.min_range
	else:
		min_range = weapon_2.min_range
		
	if weapon_1.max_range >= weapon_2.max_range:
		max_range = weapon_1.max_range
	else:
		max_range = weapon_2.max_range
	_update_unit_bonus()

func _update_unit_bonus():
	attack_bonus = equipped_weapon.attack
	speed_bonus = equipped_weapon.weight * (-1)
	
	defence_bonus = terrain_defence_bonus
	resistance_bonus = terrain_defence_bonus
	
	hit_chance = hit_chance_base + equipped_weapon.hit_chance
	avoid_chance = avoid_chance_base + terrain_avoid_bonus
	crit_chance = crit_chance_base + equipped_weapon.crit_chance
	
	Eventmanager.emit_signal("unitStatsUpdated", self)

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

func _unit_unselected():
	selected = false
	if already_moved == true and already_acted == false:
		_reset_unit()
	#print(unit_name + " was unselected.")

func _on_next_turn_started(next_player):
	active_player = next_player
	if team != active_player:
		if selected == true:
			_reset_unit()
		_free_unit_actions()

func _free_unit_actions():
	already_moved = false
	already_acted = false
	$Sprite.self_modulate = Color(1, 1, 1)

func _move(move_info : Move_Info):
	var path = move_info.movement_path
	var tween = create_tween()
	var path_size = path.size() - 1
	var mov_speed = 0.2
	Eventmanager.emit_signal("unitMove", true)
	for i in path_size:
		tween.tween_property(self, "position", path[i + 1], mov_speed)
	already_moved = true
	await get_tree().create_timer(path_size * mov_speed).timeout
	#updates position manually since the tween is not pixel perfect which can lead to misscalculation during _update_unit_tile()
	self.position = path[path.size() - 1]
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
		elif hp_cur + heal_value >= hp_max:
			hp_cur = hp_max
			heal_uses -= 1
			print("Unit heal itself.")
			_end_turn()
			Eventmanager.emit_signal("clickedUnit", self)
		else:
			hp_cur += heal_value
			heal_uses -= 1
			print("Unit heal itself.")
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
	$Sprite.self_modulate = Color(0.5, 0.5, 0.5)

func _set_hp(new_hp_value):
	hp_cur = new_hp_value
	if hp_cur <= 0:
		_kill_unit()
	elif hp_cur > hp_max:
		hp_cur = hp_max

func _kill_unit():
	print(unit_name + " has been killed.")
	Eventmanager.emit_signal("unitKilled", self)
	queue_free()

func _set_terrain_info(terrain_info):
	if terrain_info.buff_defence == true:
		terrain_defence_bonus = terrain_info.buff_defence_value
	else:
		terrain_defence_bonus = 0
	
	if terrain_info.buff_avoid == true:
		terrain_avoid_bonus = terrain_info.buff_avoid_value
	else:
		terrain_avoid_bonus = 0
		
	_update_unit_bonus()
