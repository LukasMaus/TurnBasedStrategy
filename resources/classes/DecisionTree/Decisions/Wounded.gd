extends Decision

class_name Decision_Wounded

var hpMinValue : int
var hpCurValue : int

func getTestValue():
	hpCurValue = unit.hp_cur
	hpMinValue = int(unit.hp_max * 0.25)

#checks how much hp the unit is missing
func getBranch():
	getTestValue()
	if hpCurValue <= hpMinValue:
		return Decision_Heal_Available
	else:
		return Decision_Detection_Range
