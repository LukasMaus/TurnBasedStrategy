extends Decision

class_name Decision_Detection_Range

func getTestValue() -> bool:
	#calculates detection range based on behaviour of the unit
	unit._get_detection_range()
	#calculates possible targets based on the detection range
	unit.possible_targets = unit._get_possible_targets(unit.detection_range, true)
	
	if unit.possible_targets.is_empty() != true:
		return true
	else:
		return false

func getBranch():
	if getTestValue() == true:
		return Decision_Sensible_Fight
	else:
		return Action_Stay_Wait
