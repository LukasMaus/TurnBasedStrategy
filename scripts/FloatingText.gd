extends Marker2D

@onready var label = get_node("Label")
@onready var tween = create_tween()
var amount = 0
var type = ""
@onready var max_size = Vector2(1, 1)
var velocity = Vector2(0, 0)
var text_color : Color

@onready var heal_color = Color("#00cd38")
@onready var damage_color = Color("#df0020")
@onready var miss_color = Color("#ffffff")

func _ready():

	match type:
		"miss":
			amount = "MISS"
			text_color = miss_color
		"hit":
			text_color = damage_color
		"critical":
			max_size = Vector2(1.5, 1.5)
			text_color = damage_color
		"heal":
			text_color = heal_color
		_:
			print("Type not specified for floating text.")
			return
	
	self.modulate = text_color
	label.set_text(str(amount))
	
	randomize()

	var side_movement = randi() % 49 - 24
	velocity = Vector2(side_movement, 25)
	
	tween.tween_property(self, "scale", max_size, 0.4)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_callback(self._on_tween_finished)

func _process(delta):
	position -= velocity * delta

func _on_tween_finished():
	self.queue_free()
