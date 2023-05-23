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
@onready var combat_info = get_node("%CombatInfo")

#ui colors
@onready var player_color = Color("#2e43fb")
@onready var enemy_color = Color("#df0020")
@onready var buff_color = Color("#00cd38")
@onready var debuff_color = Color("#df0020")
@onready var neutral_color = Color("#ffffff")
@onready var disabled_color = Color("#777777")

var selected_unit : Unit
var hovered_unit : Unit
var active_player
@onready var in_attack_mode = false

func _ready():
	Eventmanager.nextTurnStarted.connect(_on_next_turn_started)
	Eventmanager.hoverUnit.connect(_on_hover_unit)
	Eventmanager.unhoverUnit.connect(_on_unhover_unit)
	Eventmanager.unitStatsUpdated.connect(_on_unit_stats_updated)

#gets called in _ready() function of GameScene
func _initialize_ui(p_unit_count, e_unit_count):
	player_units.modulate = player_color
	player_units_count.text = str(p_unit_count)
	player_units_count.modulate = player_color
	enemy_units.modulate = enemy_color
	enemy_units_count.text = str(e_unit_count)
	enemy_units_count.modulate = enemy_color
	_toggle_action_menu(false)
	_toggle_unit_info()
	_toggle_combat_preview()
	_on_next_turn_started(0)

func _disable_button(button, button_state : bool):
	if button_state == true:
		button.disabled = true
		button.modulate = disabled_color
	else:
		button.disabled = false
		button.modulate = neutral_color

func _toggle_unit_info():
	if hovered_unit != null or selected_unit != null:
		unit_info.visible = true
	else:
		unit_info.visible = false

func _toggle_action_menu(visibility_state : bool):
	if visibility_state == true and selected_unit.team == active_player and selected_unit.already_acted == false:
		var heal_uses = selected_unit.heal_uses
		if heal_uses == 0 or selected_unit.hp_cur == selected_unit.hp_max:
			_disable_button(get_node("%Heal"), true)
		else:
			_disable_button(get_node("%Heal"), false)
		get_node("%Weapon1").text = selected_unit.weapon_1.weapon_name
		get_node("%Weapon1").tooltip_text = _set_weapon_tooltip(selected_unit.weapon_1)
		get_node("%Weapon2").text = selected_unit.weapon_2.weapon_name
		get_node("%Weapon2").tooltip_text = _set_weapon_tooltip(selected_unit.weapon_2)
		get_node("%Heal").tooltip_text = "Unit heals itself for " + str(selected_unit.heal_value) + " HP"
		get_node("%HealUses").text = str(heal_uses)
		
		action_menu.visible = true
	else:
		action_menu.visible = false

func _select_unit(unit):
	selected_unit = unit
	_toggle_action_menu(true)
	_update_stat_info("all")
	_toggle_unit_info()

func _unselect_unit():
	_toggle_action_menu(false)
	selected_unit = null
	_toggle_unit_info()

func _on_hover_unit(unit):
	hovered_unit = unit
	_update_stat_info("all")
	_toggle_unit_info()
	if in_attack_mode == true and selected_unit.team != hovered_unit.team:
		_set_combat_preview(selected_unit, hovered_unit)
		_toggle_combat_preview()

func _on_unhover_unit(unit):
	if hovered_unit == unit:
		hovered_unit = null
		_update_stat_info("all")
		_toggle_unit_info()
		_toggle_combat_preview()

func _set_weapon_tooltip(weapon : Weapon):
	var w_name = weapon.weapon_name
	var atk = str(weapon.attack)
	var hit = str(weapon.hit_chance)
	var crit = str(weapon.crit_chance)
	var weight = str(weapon.weight)
	var w_range
	if weapon.min_range == weapon.max_range:
		w_range = str(weapon.min_range)
	else:
		w_range = str(weapon.min_range) + " - " + str(weapon.max_range)
		
	var weapon_tooltip = "Unit equips " + w_name + ":\n
	Attack: " + atk + "
	Hit Chance: " + hit + "
	Critical Chance: " + crit + "
	Weight: " + weight + "
	Range: " + w_range
	
	return weapon_tooltip

func _on_weapon_pressed(weapon_number):
	selected_unit._equip_weapon(weapon_number)
	_update_stat_info("all")
	Eventmanager.emit_signal("setAttackMode", true)

func _on_heal_pressed():
	selected_unit._heal()
	_unselect_unit()

func _on_wait_pressed():
	selected_unit._wait()
	_unselect_unit()

func _update_player_info(player):
	player_info.text = player

func _update_unit_count(player, amount):
	var label
	if player == 0:
		label = get_node("%PlayerUnitsCount")
	else:
		label = get_node("%EnemyUnitsCount")
	var new_amount = int(label.text) + amount
	label.text = str(new_amount)

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

#checks if the updated stats are stats of the currently displayed unit
func _on_unit_stats_updated(unit):
	if hovered_unit != null and hovered_unit == unit:
		_update_stat_info("all")
	elif hovered_unit == null and selected_unit == unit:
		_update_stat_info("all")
	else:
		pass

func _update_stat_info(stat):
	var unit
	if hovered_unit == null:
		if selected_unit == null:
			#print("No unit selected or hovered")
			return
		else:
			unit = selected_unit
	else:
		unit = hovered_unit
		
	_update_unit_stats(unit, stat)
	_update_unit_bonus(unit, stat)

func _update_unit_stats(unit, stat):
	match stat:
		"name":
			get_node("%Class").text = unit.character_class.unit_name
		"weapon":
			get_node("%Weapon").text = unit.equipped_weapon.weapon_name
		"hp_current":
			var hp_cur = unit.hp_cur
			var hp_max = unit.hp_max
			get_node("%HPCurrent").text = str(hp_cur)
			if hp_cur <= hp_max * 0.4:
				get_node("%HPCurrent").modulate = debuff_color
			else:
				get_node("%HPCurrent").modulate = neutral_color
		"hp_max":
			get_node("%HPMax").text = str(unit.hp_max)
		"atk":
			get_node("%Atk").text = str(unit.attack)
		"dex":
			get_node("%Dex").text = str(unit.dexterity)
		"spd":
			get_node("%Spd").text = str(unit.speed)
		"def":
			get_node("%Def").text = str(unit.defence)
		"res":
			get_node("%Res").text = str(unit.resistance)
		"mov":
			get_node("%Mov").text = str(unit.movement)
		"range":
			if unit.equipped_weapon.min_range == unit.equipped_weapon.max_range:
				get_node("%RangeValue").text = str(unit.equipped_weapon.max_range)
			else:
				get_node("%RangeValue").text = str(unit.equipped_weapon.min_range) + " - " + str(unit.equipped_weapon.max_range)
		"all":
			_update_unit_stats(unit, "name")
			_update_unit_stats(unit, "weapon")
			_update_unit_stats(unit, "hp_current")
			_update_unit_stats(unit, "hp_max")
			_update_unit_stats(unit, "atk")
			_update_unit_stats(unit, "dex")
			_update_unit_stats(unit, "spd")
			_update_unit_stats(unit, "def")
			_update_unit_stats(unit, "res")
			_update_unit_stats(unit, "mov")
			_update_unit_stats(unit, "range")
		_:
			print("No stat specified for update")

func _update_unit_bonus(unit, stat):
	var stat_value
	var stat_node
	
	match stat:
		"atk":
			stat_value = unit.attack_bonus
			stat_node = get_node("%AtkBonus")
			_set_unit_bonus(stat_value, stat_node)
		"dex":
			stat_value = unit.dexterity_bonus
			stat_node = get_node("%DexBonus")
			_set_unit_bonus(stat_value, stat_node)
		"spd":
			stat_value = unit.speed_bonus
			stat_node = get_node("%SpdBonus")
			_set_unit_bonus(stat_value, stat_node)
		"def":
			stat_value = unit.defence_bonus
			stat_node = get_node("%DefBonus")
			_set_unit_bonus(stat_value, stat_node)
		"res":
			stat_value = unit.resistance_bonus
			stat_node = get_node("%ResBonus")
			_set_unit_bonus(stat_value, stat_node)
		"mov":
			stat_value = unit.movement_bonus
			stat_node = get_node("%MovBonus")
			_set_unit_bonus(stat_value, stat_node)
		"all":
			_update_unit_bonus(unit, "atk")
			_update_unit_bonus(unit, "dex")
			_update_unit_bonus(unit, "spd")
			_update_unit_bonus(unit, "def")
			_update_unit_bonus(unit, "res")
			_update_unit_bonus(unit, "mov")
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
		stat_node.text = ""

func _update_terrain_info(terrain_information):
	get_node("%TerrainName").text = terrain_information.tile_name
	if terrain_information.movement_cost == 0:
		get_node("%TerrainMovCostValue").text = "Impassable"
	else:
		get_node("%TerrainMovCostValue").text = str(terrain_information.movement_cost)
		
	if terrain_information.buff_defence == true:
		get_node("%TerrainSeperator").text = "|"
		get_node("%TerrainBuff").text = "Def/Res:"
		get_node("%TerrainBuffValue").text = "+" + str(terrain_information.buff_defence_value)
	elif terrain_information.buff_avoid == true:
		get_node("%TerrainSeperator").text = "|"
		get_node("%TerrainBuff").text = "Avoid:"
		get_node("%TerrainBuffValue").text = "+" + str(terrain_information.buff_avoid_value)
	else:
		get_node("%TerrainSeperator").text = ""
		get_node("%TerrainBuff").text = ""
		get_node("%TerrainBuffValue").text = ""

func _toggle_combat_preview():
	if selected_unit != null and hovered_unit != null:
		combat_info.visible = true
	else:
		combat_info.visible = false

func _set_combat_preview(unit_player, unit_enemy):
	var combat_data = Combat_Data.new()
	combat_data._calculate_combat_data(unit_player, unit_enemy)
	
	get_node("%InitiatingUnitName").text = unit_player.character_class.unit_name
	get_node("%PlayerHP").text = str(combat_data.initiating_unit.hp)
	get_node("%PlayerAtk").text = str(combat_data.initiating_unit.atk)
	get_node("%PlayerHit").text = str(combat_data.initiating_unit.hit_chance)
	get_node("%PlayerCrit").text = str(combat_data.initiating_unit.crit_chance)
	
	get_node("%TargetUnitName").text = unit_enemy.character_class.unit_name
	get_node("%EnemyHP").text = str(combat_data.target_unit.hp)
	get_node("%EnemyAtk").text = str(combat_data.target_unit.atk)
	get_node("%EnemyHit").text = str(combat_data.target_unit.hit_chance)
	get_node("%EnemyCrit").text = str(combat_data.target_unit.crit_chance)
	
	_format_attack_value(combat_data)
	_format_progress_bars(combat_data)

func _format_attack_value(data : Combat_Data):
	if data.initiating_unit.follow_up == true:
		get_node("%PlayerAtk").horizontal_alignment = 0
		get_node("%PlayerFollowUp").visible = true
	else:
		get_node("%PlayerAtk").horizontal_alignment = 1
		get_node("%PlayerFollowUp").visible = false
	
	if data.target_unit.follow_up == true:
		get_node("%EnemyAtk").horizontal_alignment = 0
		get_node("%EnemyFollowUp").visible = true
	else:
		get_node("%EnemyAtk").horizontal_alignment = 1
		get_node("%EnemyFollowUp").visible = false

func _format_progress_bars(data : Combat_Data):
	var hp_bar_value = (data.initiating_unit.hp * 100) / (data.initiating_unit.hp + data.target_unit.hp)
	var initiating_atk_multiplier = 1
	var target_atk_multiplier = 1
	if data.initiating_unit.follow_up == true:
		initiating_atk_multiplier = 2
	if data.target_unit.follow_up == true:
		target_atk_multiplier = 2
	var atk_bar_value = (data.initiating_unit.atk * initiating_atk_multiplier * 100) / (data.initiating_unit.atk * initiating_atk_multiplier + data.target_unit.atk * target_atk_multiplier)
	var hit_bar_value = (data.initiating_unit.hit_chance * 100) / (data.initiating_unit.hit_chance + data.target_unit.hit_chance)
	var crit_bar_value = (data.initiating_unit.crit_chance * 100) / (data.initiating_unit.crit_chance + data.target_unit.crit_chance)
	
	get_node("%HPBar").value = hp_bar_value
	get_node("%AtkBar").value = atk_bar_value
	get_node("%HitBar").value = hit_bar_value
	get_node("%CritBar").value = crit_bar_value
