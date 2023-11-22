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
@onready var menu_screen = get_node("%MenuScreen")
@onready var evaluation = get_node("%Evaluation")

#ui colors
@onready var player_1_color = Color("#2e43fb")
@onready var player_2_color = Color("#df0020")
@onready var buff_color = Color("#00cd38")
@onready var debuff_color = Color("#df0020")
@onready var neutral_color = Color("#ffffff")
@onready var disabled_color = Color("#777777")

var selected_unit : Unit
var hovered_unit : Unit
var active_player : Player
@onready var in_action_mode = false
@onready var in_attack_mode = false

func _ready():
	Eventmanager.nextTurnStarted.connect(_on_next_turn_started)
	Eventmanager.hoverUnit.connect(_on_hover_unit)
	Eventmanager.unhoverUnit.connect(_on_unhover_unit)
	Eventmanager.unitStatsUpdated.connect(_on_unit_stats_updated)
	Eventmanager.gameEnded.connect(_on_game_ended)

#gets called in _ready() function of GameScene
func _initialize_ui(debug_mode, starting_player, p_unit_count, e_unit_count):
	active_player = starting_player
	player_units.modulate = player_1_color
	player_units_count.text = str(p_unit_count)
	player_units_count.modulate = player_1_color
	enemy_units.modulate = player_2_color
	enemy_units_count.text = str(e_unit_count)
	enemy_units_count.modulate = player_2_color
	menu_screen.visible = false
	if debug_mode == true:
		evaluation.visible = true
		get_node("%TerrainSeperator2").visible = true
		get_node("%Threat").visible = true
	_toggle_action_menu(false)
	_toggle_unit_info()
	_toggle_combat_preview()
	_on_next_turn_started(active_player)

func _on_game_ended(winningPlayerNumber):
	var text
	if winningPlayerNumber == 0:
		text = "Victory!"
	else:
		text = "Defeat!"
	menu_screen.get_child(0).text = text
	_toggle_menu_button()

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

func _toggle_menu_button():
	menu_screen.visible = not menu_screen.visible
	get_tree().paused = not get_tree().paused

func _toggle_action_menu(visibility_state : bool):
	if visibility_state == true and selected_unit.player == active_player and active_player.control == "Player" and selected_unit.already_acted == false:
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

func _toggle_end_turn_button(visibility_state : bool):
	end_turn.visible = visibility_state

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
	if in_attack_mode == true and selected_unit.player != hovered_unit.player:
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

func _set_in_action_mode(action_mode_state : bool):
	in_action_mode = action_mode_state
	if in_action_mode == true:
		action_menu.visible = false
		end_turn.visible = false
	elif active_player.control == "Player":
		action_menu.visible = true
		end_turn.visible = true
	else:
		pass

func _set_in_attack_mode(attack_mode_state : bool):
	in_attack_mode = attack_mode_state
	if in_attack_mode == true:
		end_turn.visible = false
	else:
		end_turn.visible = true

func _on_main_menu_pressed():
	Eventmanager.emit_signal("mainMenu")

func _on_weapon_pressed(weapon_number):
	selected_unit._equip_weapon(weapon_number)
	_update_stat_info("all")
	Eventmanager.emit_signal("setAttackMode", true)

func _on_heal_pressed():
	if get_node("%Heal").disabled == false:
		selected_unit._heal()
		_unselect_unit()
	else:
		print("Heal action not available.")

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
	if active_player.control == "Player":
		_update_player_info("Player Turn")
		_toggle_end_turn_button(true)
	else:
		_update_player_info("AI Turn")
		_toggle_action_menu(false)
		_toggle_end_turn_button(false)
	if player_info.modulate == player_1_color:
		player_info.modulate = player_2_color
	else:
		player_info.modulate = player_1_color

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

func _update_unit_stats(unit : Unit, stat):
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
			_set_unit_stat(get_node("%Atk"), unit.attack, unit.attack_bonus)
		"dex":
			_set_unit_stat(get_node("%Dex"), unit.dexterity, unit.dexterity_bonus)
		"spd":
			_set_unit_stat(get_node("%Spd"), unit.speed, unit.speed_bonus)
		"def":
			_set_unit_stat(get_node("%Def"), unit.defence, unit.defence_bonus)
		"res":
			_set_unit_stat(get_node("%Res"), unit.resistance, unit.resistance_bonus)
		"range":
			if unit.equipped_weapon.min_range == unit.equipped_weapon.max_range:
				get_node("%Range").text = str(unit.equipped_weapon.max_range)
			else:
				get_node("%Range").text = str(unit.equipped_weapon.min_range) + " - " + str(unit.equipped_weapon.max_range)
		"hit_rate":
			_set_unit_stat(get_node("%HitRate"), unit.hit_chance, unit.hit_chance_bonus)
		"avoid":
			_set_unit_stat(get_node("%Avoid"), unit.avoid_chance, unit.avoid_chance_bonus)
		"crit_rate":
			_set_unit_stat(get_node("%CritRate"), unit.crit_chance, unit.crit_chance_bonus)
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
			_update_unit_stats(unit, "range")
			_update_unit_stats(unit, "hit_rate")
			_update_unit_stats(unit, "avoid")
			_update_unit_stats(unit, "crit_rate")
		_:
			print("No stat specified for update")

func _set_unit_stat(node, base_value, bonus_value):
	node.text = str(base_value + bonus_value)
	node.modulate = _set_stat_color(bonus_value)

func _set_stat_color(bonus_value):
	var color : Color
	if bonus_value > 0:
		color = buff_color
	elif bonus_value < 0:
		color = debuff_color
	else:
		color = neutral_color
	return color

func _update_terrain_info(terrain_information : Terrain_Info):
	var buff_active : bool
	var debuff_active : bool
	get_node("%TerrainName").text = terrain_information.tile_name
	if terrain_information.movement_cost == 0:
		get_node("%TerrainMovCost").text = ""
		get_node("%TerrainMovCostValue").text = ""
		get_node("%Impassable").text = "Impassable"
	else:
		get_node("%TerrainMovCost").text = "Mov:"
		get_node("%TerrainMovCostValue").text = str(terrain_information.movement_cost)
		get_node("%Impassable").text = ""
	
	get_node("%Threat").text = str(terrain_information.threat)
	
	#sets values for buff label
	if terrain_information.buff_defence == true:
		buff_active = true
		get_node("%TerrainBuff").text = "Def/Res: "
		get_node("%TerrainBuffValue").text = "+" + str(terrain_information.buff_defence_value)
	elif terrain_information.buff_avoid == true:
		buff_active = true
		get_node("%TerrainBuff").text = "Avo: "
		get_node("%TerrainBuffValue").text = "+" + str(terrain_information.buff_avoid_value)
	elif terrain_information.buff_dex == true:
		buff_active = true
		get_node("%TerrainBuff").text = "Dex: "
		get_node("%TerrainBuffValue").text = "+" + str(terrain_information.buff_dex_value)
	else:
		buff_active = false
		get_node("%TerrainBuff").text = ""
		get_node("%TerrainBuffValue").text = ""
	
	#sets values for debuff label
	if terrain_information.debuff_resistance == true:
		debuff_active = true
		get_node("%TerrainDebuff").text = "Res: "
		get_node("%TerrainDebuffValue").text = "-" + str(terrain_information.debuff_resistance_value)
	elif terrain_information.debuff_avoid == true:
		debuff_active = true
		get_node("%TerrainDebuff").text = "Avo: "
		get_node("%TerrainDebuffValue").text = "-" + str(terrain_information.debuff_avoid_value)
	elif terrain_information.debuff_dex == true:
		debuff_active = true
		get_node("%TerrainDebuff").text = "Dex: "
		get_node("%TerrainDebuffValue").text = "-" + str(terrain_information.debuff_dex_value)
	else:
		debuff_active = false
		get_node("%TerrainDebuff").text = ""
		get_node("%TerrainDebuffValue").text = ""
	
	#sets separator if terrain has buffs and debuffs
	if buff_active == true and debuff_active == true:
		get_node("%TerrainSeperator").text = "|"
	else:
		get_node("%TerrainSeperator").text = ""

func _toggle_combat_preview():
	if selected_unit != null and hovered_unit != null:
		combat_info.visible = true
		evaluation.visible = true
	else:
		combat_info.visible = false
		evaluation.visible = false

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
	evaluation.text = str(combat_data.initiating_unit.evaluation_score)
	
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
	var color_init
	var color_target
	var initiating_atk_multiplier = 1
	var target_atk_multiplier = 1
	
	if data.initiating_unit.unit.team == 0:
		color_init = player_1_color
		color_target = player_2_color
	else:
		color_init = player_2_color
		color_target = player_1_color
		
	if data.initiating_unit.follow_up == true:
		initiating_atk_multiplier = 2
	if data.target_unit.follow_up == true:
		target_atk_multiplier = 2
	
	var atk_init = data.initiating_unit.atk * initiating_atk_multiplier
	var atk_target = data.target_unit.atk * target_atk_multiplier
	var hp_init_post = data.initiating_unit.hp - atk_target
	var hp_target_post = data.target_unit.hp - atk_init
	
	_set_preview_bar(get_node("%HPPlayer"), color_init, hp_init_post, data.initiating_unit.hp)
	_set_preview_bar(get_node("%HPEnemy"), color_target, hp_target_post, data.target_unit.hp)
	_set_preview_bar(get_node("%AtkPlayer"), color_init, atk_init, atk_init + atk_target)
	_set_preview_bar(get_node("%AtkEnemy"), color_target, atk_target, atk_init + atk_target)
	_set_preview_bar(get_node("%HitPlayer"), color_init, data.initiating_unit.hit_chance, 100)
	_set_preview_bar(get_node("%HitEnemy"), color_target, data.target_unit.hit_chance, 100)
	_set_preview_bar(get_node("%CritPlayer"), color_init, data.initiating_unit.crit_chance, 100)
	_set_preview_bar(get_node("%CritEnemy"), color_target, data.target_unit.crit_chance, 100)

func _set_preview_bar(bar : TextureProgressBar, color : Color, progress : int, max_value : int):
	bar.tint_progress = color
	bar.max_value = max_value
	bar.value = progress

