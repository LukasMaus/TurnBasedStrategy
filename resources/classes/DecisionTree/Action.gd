extends DecisionTreeNode

class_name Action

enum MovementPatterns {FLEE, STAY, ASSAULT}
var movement_pattern : MovementPatterns
enum Actions {ATTACK, HEAL, WAIT}
var action : Actions

#sets the moevement pattern and action to take
func _set_action_data():
	pass

#end of the tree reached - return the movement pattern and action
func makeDecision(u : Unit) -> DecisionTreeNode:
	unit = u
	_set_action_data()
	return self
