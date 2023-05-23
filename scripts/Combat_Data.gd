class_name Combat_Data

#calculates all values for cambat between two units
var initiating_unit : Combat_Data_Unit
var target_unit : Combat_Data_Unit
var target_counter : bool

#action order of combat
var action_order = []

func _init():
	initiating_unit = Combat_Data_Unit.new()
	target_unit = Combat_Data_Unit.new()

func _calculate_combat_data(unit_1 : Unit, unit_2 : Unit):
	initiating_unit.unit = unit_1
	target_unit.unit = unit_2
	
	var unit_initiating_defence = _calculate_unit_defence(unit_1, unit_2)
	var unit_target_defence = _calculate_unit_defence(unit_2, unit_1)
	var initiating_avoid_chance = unit_1.avoid_chance
	var target_avoid_chance = unit_2.avoid_chance
	var initiating_weapon_advantage = _calculate_weapon_advantage(unit_1, unit_2)
	var target_weapon_advantage = _calculate_weapon_advantage(unit_2, unit_1)
	
	#combat stats for initating unit
	initiating_unit.hp = unit_1.hp_cur
	initiating_unit.atk = int((unit_1.attack + unit_1.attack_bonus - unit_target_defence) * initiating_weapon_advantage)
	initiating_unit.follow_up = _calculate_follow_up(unit_1, unit_2)
	initiating_unit.hit_chance = clamp(unit_1.hit_chance - target_avoid_chance, 0, 100)
	initiating_unit.crit_chance = clamp(unit_1.crit_chance, 0, 100)
	
	#if target unit is able to couter the attack
	target_counter = _calculate_target_counter()
	
	#combat stats for target_unit
	target_unit.hp = unit_2.hp_cur
	if target_counter == false:
		target_unit.atk = 0
		target_unit.hit_chance = 0
		target_unit.crit_chance = 0
		target_unit.follow_up = false
	else:
		target_unit.atk = int((unit_2.attack + unit_2.attack_bonus - unit_initiating_defence) * target_weapon_advantage)
		target_unit.hit_chance = clamp(unit_2.hit_chance - initiating_avoid_chance, 0, 100)
		target_unit.crit_chance = clamp(unit_2.crit_chance, 0, 100)
		target_unit.follow_up = _calculate_follow_up(unit_2, unit_1)
	
	_calculate_action_order()

#calculates the attack power of the unit based on its attack and the opposing defence value
func _calculate_unit_defence(def_unit : Unit, atk_unit : Unit):
	if atk_unit.equipped_weapon.damage_type.target_stat == "defence":
		return def_unit.defence + def_unit.defence_bonus
	elif atk_unit.equipped_weapon.damage_type.target_stat == "resistance":
		return def_unit.resistance + def_unit.resistance_bonus
	elif atk_unit.equipped_weapon.damage_type.target_stat == "none":
		return 0

#calculates if the unit is able to attack twice
func _calculate_follow_up(unit_1 : Unit, unit_2: Unit):
	if unit_1.speed + unit_1.speed_bonus >= unit_2.speed + unit_2.speed_bonus + 5:
		return true
	else:
		return false

func _calculate_weapon_advantage(unit_1 : Unit, unit_2 : Unit):
	var unit_1_weapon = unit_1.equipped_weapon.weapon_type
	var unit_2_weapon = unit_2.equipped_weapon.weapon_type
	if unit_1_weapon.weapon_type_strength == unit_2_weapon.weapon_type_name:
		return 1.2
	elif unit_1_weapon.weapon_type_weakness == unit_2_weapon.weapon_type_name:
		return 0.8
	else:
		return 1.0

#calculates if the target is in range to retaliate
func _calculate_target_counter():
	var distance_vector = initiating_unit.unit.unit_tile  - target_unit.unit.unit_tile
	var distance = abs(distance_vector.x) + abs(distance_vector.y)
	if distance >= target_unit.unit.equipped_weapon.min_range and distance <= target_unit.unit.equipped_weapon.max_range:
		return true
	else:
		return false

func _calculate_action_order():
	#first strile of the initating unit
	action_order.append(initiating_unit)
	#target unit counters if in range
	if target_counter == true:
		action_order.append(target_unit)
	#initating unit strikes a second time if speed allows for it
	if initiating_unit.follow_up == true:
		action_order.append(initiating_unit)
	#target unit strikes a second time if able to counter and speed allows for it
	if target_counter == true and target_unit.follow_up == true:
		action_order.append(target_unit)
	print(str(action_order))
