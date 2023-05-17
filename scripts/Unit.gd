extends CharacterBody2D

@export_group("Characters Stats")
@export_enum ("Player", "Enemy") var team = 0
@export_enum ("Soldier", "Lancer", "Warrior", "Archer", "Mage") var character_class : String = "Soldier"
@export var hp_max : int
@export var hp_cur : int
@export var attack : int
@export var dexterity : int
@export var speed : int
@export var defence : int
@export var resistance : int
@export var movement : int
@onready var min_range = 1
@onready var max_range = 1

@onready  var attack_bonus = -3
@onready  var dexterity_bonus = 0
@onready  var speed_bonus = 0
@onready var defence_bonus = +5
@onready var resistance_bonus = 0
@onready var movement_bonus = +8
@onready var max_range_bonus = 0

#weapon stats
#weapon 1
var weapon_1 : Weapon
var weapon_1_name : String
var weapon_1_type : String
var weapon_1_atk : int
var weapon_1_hit_chance : int
var weapon_1_crit : int
var weapon_1_weight : int
var weapon_1_dmg_type : String
var weapon_1_min_range : int
var weapon_1_may_range : int
var weapon_1_target : String

#weapon 2
var weapon_2_name : String
var weapon_2_type : String
var weapon_2_atk : int
var weapon_2_hit_chance : int
var weapon_2_crit : int
var weapon_2_weight : int
var weapon_2_dmg_type : String
var weapon_2_min_range : int
var weapon_2_may_range : int
var weapon_2_target : String

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
	_update_unit_tile()
	$Sprite.texture = load("res://assets/spritesheets/" + character_class + "_" + str(team) + ".png")
	
	_initialize_unit_stats()
	_initialize_unit_weapons()
	
	Eventmanager.nextTurnStarted.connect(_on_next_turn_started)

func _initialize_unit_stats():
	#sets stats of the unit to GameData values if not defined otherwise
	if hp_max == 0:
		hp_max = GameData.class_data[character_class]["base_hp"]
	if hp_cur == 0:
		hp_cur = hp_max
	if attack == 0:
		attack = GameData.class_data[character_class]["base_atk"]
	if dexterity == 0:
		dexterity = GameData.class_data[character_class]["base_dex"]
	if speed == 0:
		speed = GameData.class_data[character_class]["base_spd"]
	if defence == 0:
		defence = GameData.class_data[character_class]["base_def"]
	if resistance == 0:
		resistance = GameData.class_data[character_class]["base_res"]
	if movement == 0:
		movement = GameData.class_data[character_class]["movement"]

func _initialize_unit_weapons():
	pass

func _update_unit_tile():
	unit_tile_previous = unit_tile
	unit_tile = Globals._get_tile_id(self.get_global_position())
	Eventmanager.emit_signal("newUnitPosition", team, unit_tile_previous, unit_tile)

func _on_unit_clicked(_viewport, event, _shape_idx):
	if event.is_action_pressed("select_unit") and selected == false:
		Eventmanager.emit_signal("selectUnit", self)

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

func _move(path):
	var tween = create_tween()
	var path_size = path.size() - 1
	var mov_speed = 0.2
	Eventmanager.emit_signal("unitMoveStart")
	for i in path_size:
		tween.tween_property(self, "position", path[i + 1], mov_speed)
	already_moved = true
	await get_tree().create_timer(path_size * mov_speed).timeout
	#updates position manually since the tween is not pixel perfect which can lead to misscalculation during _update_unit_tile()
	self.position = path[path.size() - 1]
	_update_unit_tile()
	print(unit_name + " moved to tile: " + str(unit_tile))
	Eventmanager.emit_signal("unitMoveEnd")

func _reset_unit():
	if already_moved == true and already_acted == false:
		position = unit_tile_previous * Vector2(Globals.TILE_SIZE, Globals.TILE_SIZE)
		_update_unit_tile()
		already_moved = false
		print(unit_name + " has been reset.")

func _heal():
	if heal_uses > 0:
		if hp_cur == hp_max:
			print("HP already full.")
		elif hp_cur + heal_value >= hp_max:
			hp_cur = hp_max
			heal_uses -= 1
			_wait()
		else:
			hp_cur += heal_value
			heal_uses -= 1
			_wait()
		print("Heal uses: " + str(heal_uses))

func _wait():
	already_moved = true
	already_acted = true
	unit_tile_previous = unit_tile
	$Sprite.self_modulate = Color(0.5, 0.5, 0.5)
	print(unit_name + " waits.")
	Eventmanager.emit_signal("unselectUnit")
