extends Decision

class_name Decision_Heal_Available

func getTestValue() -> int:
	return unit.heal_uses

#checks if the unit still possesses a heal charge
func getBranch():
	if getTestValue() > 0:
		return Action_Stay_Heal
	else:
		return Action_Flee_Wait
