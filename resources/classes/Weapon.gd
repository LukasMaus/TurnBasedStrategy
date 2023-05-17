extends Resource

class_name Weapon

@export var weapon_name : String :
	get:
		return weapon_name
	set(value):
		weapon_name = value

@export var weapon_type : String :
	get:
		return weapon_type
	set(value):
		weapon_type = value

@export var attack : int :
	get:
		return attack
	set(value):
		attack = value

@export var hit_chance : int :
	get:
		return hit_chance
	set(value):
		hit_chance = value

@export var weight : int :
	get:
		return weight
	set(value):
		weight = value

@export var damage_type : String :
	get:
		return damage_type
	set(value):
		damage_type = value

@export var min_range : int :
	get:
		return min_range
	set(value):
		min_range = value

@export var max_range : int :
	get:
		return max_range
	set(value):
		max_range = value

@export var target : String :
	get:
		return target
	set(value):
		target = value
