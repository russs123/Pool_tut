extends Sprite2D

signal shoot

var power : float = 0.0
var power_dir : int = 1

func _process(_delta):
	#use mouse to rotate the cue
	var mouse_pos := get_viewport().get_mouse_position()
	look_at(mouse_pos)
	#check for mouse clicks
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		power += 0.1 * power_dir
		if power >= get_parent().MAX_POWER:
			power_dir = -1
		elif power <= 0:
			power_dir = 1
	else:
		power_dir = 1
		if power > 0:
			var dir = mouse_pos - position
			shoot.emit(power * dir)
			power = 0
