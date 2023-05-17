extends Resource

class_name Weapon_Type

@export var weapon_type_name : String :
	get:
		return weapon_type_name
	set(value):
		weapon_type_name = value

#declaring the weapon strength as a weapon_type data type results in a bug with recursion
#more information on Godot Github #73589
@export var weapon_type_strength : String :
	get:
		return weapon_type_strength
	set(value):
		weapon_type_strength = value

@export var weapon_type_weakness : String :
	get:
		return weapon_type_weakness
	set(value):
		weapon_type_weakness = value
