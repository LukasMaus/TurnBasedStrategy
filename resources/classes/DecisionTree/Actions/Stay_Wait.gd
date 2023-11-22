extends Action

class_name Action_Stay_Wait

func _set_action_data():
	movement_pattern = MovementPatterns.STAY
	action = Actions.WAIT
