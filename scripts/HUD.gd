extends CanvasLayer

#main ui elements
@onready var player_info = get_node("%PlayerInfo")
@onready var player_units = get_node("%PlayerUnits")
@onready var player_units_count = get_node("%PlayerUnitsCount")
@onready var enemy_units = get_node("%EnemyUnits")
@onready var enemy_units_count = get_node("%EnemyUnitsCount")
@onready var action_menu = get_node("%ActionMenu")
@onready var end_turn = get_node("%EndTurn")
@onready var terrain_info = get_node("%TerrainInfo")
@onready var unit_info = get_node("%UnitInfo")

#ui colors
@onready var player_color = Color("#2e43fb")
@onready var enemy_color = Color("#df0020")
@onready var buff_color = Color("#00cd38")
@onready var debuff_color = Color("#df0020")
@onready var neutral_color = Color("#ffffff")
@onready var disabled_color = Color("#777777")

var selected_unit
var hovered_unit
var active_player

func _ready():
	Eventmanager.nextTurnStarted.connect(_on_next_turn_started)

#gets called in _ready() function of GameScene
func _initialize_ui(p_unit_count, e_unit_count):
	player_units.modulate = player_color
	player_units_count.text = str(p_unit_count)
	player_units_count.modulate = player_color
	enemy_units.modulate = enemy_color
	enemy_units_count.text = str(e_unit_count)
	enemy_units_count.modulate = enemy_color
	action_menu.visible = false
	unit_info.visible = false
	_on_next_turn_started(0)

func _disable_button(button, button_state : bool):
	if button_state == true:
		button.disabled = true
		button.modulate = disabled_color
	else:
		button.disabled = false
		button.modulate = neutral_color

func _select_unit(unit):
	selected_unit = unit
	
	if selected_unit.team == active_player and selected_unit.already_acted == false:
		var heal_uses = selected_unit.heal_uses
		if heal_uses == 0 or selected_unit.hp_cur == selected_unit.hp_max:
			_disable_button(get_node("%Heal"), true)
		else:
			_disable_button(get_node("%Heal"), false)
		get_node("%HealUses").text = str(heal_uses)
		action_menu.visible = true
		
	_update_unit_stats("all")
	_update_unit_bonus("all")
	unit_info.visible = true

func _unselect_unit():
	action_menu.visible = false
	unit_info.visible = false
	selected_unit = null

func _on_heal_pressed():
	selected_unit._heal()

func _on_wait_pressed():
	selected_unit._wait()

func _update_player_info(player):
	player_info.text = player

func _on_next_turn_started(next_player):
	active_player = next_player
	match active_player:
		0:
			_update_player_info("Player Turn")
			player_info.modulate = player_color
		1: 
			_update_player_info("Enemy Turn")
			player_info.modulate = enemy_color

func _on_end_turn_pressed():
	Eventmanager.emit_signal("endTurn")

func _update_unit_stats(stat):
	match stat:
		"name":
			get_node("%Class").text = selected_unit.character_class
		"hp_current":
			var hp_cur = selected_unit.hp_cur
			var hp_max = selected_unit.hp_max
			get_node("%HPCurrent").text = str(hp_cur)
			if hp_cur <= hp_max * 0.4:
				get_node("%HPCurrent").modulate = debuff_color
			else:
				get_node("%HPCurrent").modulate = neutral_color
		"hp_max":
			get_node("%HPMax").text = str(selected_unit.hp_max)
		"atk":
			get_node("%Atk").text = str(selected_unit.attack)
		"dex":
			get_node("%Dex").text = str(selected_unit.dexterity)
		"spd":
			get_node("%Spd").text = str(selected_unit.speed)
		"def":
			get_node("%Def").text = str(selected_unit.defence)
		"res":
			get_node("%Res").text = str(selected_unit.resistance)
		"mov":
			get_node("%Mov").text = str(selected_unit.movement)
		"range":
			get_node("%Range").text = str(selected_unit.max_range)
		"all":
			_update_unit_stats("name")
			_update_unit_stats("hp_current")
			_update_unit_stats("hp_max")
			_update_unit_stats("atk")
			_update_unit_stats("dex")
			_update_unit_stats("spd")
			_update_unit_stats("def")
			_update_unit_stats("res")
			_update_unit_stats("mov")
			_update_unit_stats("range")
		_:
			print("No stat specified for update")

func _update_unit_bonus(stat):
	var stat_value
	var stat_node
	match stat:
		"atk":
			stat_value = selected_unit.attack_bonus
			stat_node = get_node("%AtkBonus")
			_set_unit_bonus(stat_value, stat_node)
		"dex":
			stat_value = selected_unit.dexterity_bonus
			stat_node = get_node("%DexBonus")
			_set_unit_bonus(stat_value, stat_node)
		"spd":
			stat_value = selected_unit.speed_bonus
			stat_node = get_node("%SpdBonus")
			_set_unit_bonus(stat_value, stat_node)
		"def":
			stat_value = selected_unit.defence_bonus
			stat_node = get_node("%DefBonus")
			_set_unit_bonus(stat_value, stat_node)
		"res":
			stat_value = selected_unit.resistance_bonus
			stat_node = get_node("%ResBonus")
			_set_unit_bonus(stat_value, stat_node)
		"mov":
			stat_value = selected_unit.movement_bonus
			stat_node = get_node("%MovBonus")
			_set_unit_bonus(stat_value, stat_node)
		"range":
			stat_value = selected_unit.max_range_bonus
			stat_node = get_node("%RangeBonus")
			_set_unit_bonus(stat_value, stat_node)
		"all":
			_update_unit_bonus("atk")
			_update_unit_bonus("dex")
			_update_unit_bonus("spd")
			_update_unit_bonus("def")
			_update_unit_bonus("res")
			_update_unit_bonus("mov")
			_update_unit_bonus("range")
		_:
			print("No stat specified for update")

func _set_unit_bonus(stat_value, stat_node):
	if stat_value > 0:
		stat_node.text = "+" + str(stat_value)
		stat_node.modulate = buff_color
	elif stat_value < 0:
		stat_node.text = str(stat_value)
		stat_node.modulate = debuff_color
	else:
		stat_node.text == ""

func _update_terrain_info(terrain_info, defence_buff_value, avoid_buff_value):
	get_node("%TerrainName").text = terrain_info[0]
	if terrain_info[1] == 0:
		get_node("%TerrainMovCostValue").text = "Impassable"
	else:
		get_node("%TerrainMovCostValue").text = str(terrain_info[1])
		
	if terrain_info[2] == true:
		get_node("%TerrainSeperator").text = "|"
		get_node("%TerrainBuff").text = "Def/Res:"
		get_node("%TerrainBuffValue").text = "+" + str(defence_buff_value)
	elif terrain_info[3] == true:
		get_node("%TerrainSeperator").text = "|"
		get_node("%TerrainBuff").text = "Avoid:"
		get_node("%TerrainBuffValue").text = "+" + str(avoid_buff_value)
	else:
		get_node("%TerrainSeperator").text = ""
		get_node("%TerrainBuff").text = ""
		get_node("%TerrainBuffValue").text = ""
