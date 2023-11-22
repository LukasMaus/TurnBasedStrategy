extends Action

class_name Action_Flee_Wait

func _set_action_data():
	movement_pattern = MovementPatterns.FLEE
	action = Actions.WAIT
