extends Node

@export var ball_scene : PackedScene

#game variables
var ball_images := []
var cue_ball
const START_POS := Vector2(890, 340)
const MAX_POWER := 8.0
var taking_shot : bool
const MOVE_THRESHOLD := 5.0
var cue_ball_potted : bool
var potted := []
var lives : int
var shots : int

# Called when the node enters the scene tree for the first time.
func _ready():
	load_images()
	new_game()
	$Table/Pockets.body_entered.connect(potted_ball)
	$Hud/ResultPanel/RestartButton.pressed.connect(new_game)

func load_images():
	for i in range(1, 17, 1):
		var filename = str("res://assets/ball_", i, ".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)

func new_game():
	#reset variables
	lives = 3
	shots = 0
	$LivesLabel.text = "LIVES: " + str(lives)
	$ShotsLabel.text = "SHOTS: " + str(shots)
	cue_ball_potted = false
	clear_balls()
	generate_balls()
	reset_cue_ball()
	show_cue()
	get_tree().paused = false
	$Hud.hide()

func clear_balls():
	get_tree().call_group("balls", "queue_free")
	for b in potted:
		b.queue_free()
	potted.clear()

func generate_balls():
	#setup game balls
	var count : int = 0
	var rows : int = 5
	var dia = 36
	for col in range(5):
		for row in range(rows):
			var b = ball_scene.instantiate()
			var pos = Vector2(250 + (col * (dia)), 267 + (row * (dia)) + (col * dia / 2))
			add_child(b)
			b.position = pos
			b.get_node("Sprite2D").texture = ball_images[count]
			count += 1
		rows -= 1

func remove_cue_ball():
	var old_b = cue_ball
	remove_child(old_b)
	old_b.queue_free()

func reset_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball)
	cue_ball.position = START_POS
	cue_ball.get_node("Sprite2D").texture = ball_images.back()
	taking_shot = false

func show_cue():
	$Cue.set_process(true)
	$Cue.position = cue_ball.position
	$PowerBar.position.x = cue_ball.position.x - (0.5 * $PowerBar.size.x)
	$PowerBar.position.y = cue_ball.position.y + $PowerBar.size.y
	$Cue.show()
	$PowerBar.show()

func hide_cue():
	$Cue.set_process(false)
	$Cue.hide()
	$PowerBar.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var moving := false
	#check that all balls have stopped moving
	for b in get_tree().get_nodes_in_group("balls"):
		if (b.linear_velocity.length() > 0.0
		and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
	if not moving:
		#check if the cue ball has been potted and reset it
		if cue_ball_potted:
			reset_cue_ball()
			cue_ball_potted = false
		if not taking_shot:
			taking_shot = true
			show_cue()
	else:
		if taking_shot:
			taking_shot = false
			hide_cue()

func _on_cue_shoot(power):
	cue_ball.apply_central_impulse(power)
	shots += 1
	$ShotsLabel.text = "SHOTS: " + str(shots)

func potted_ball(body):
	if body == cue_ball:
		lives -= 1
		$LivesLabel.text = "LIVES: " + str(lives)
		cue_ball_potted = true
		remove_cue_ball()
		if lives == 0:
			game_over("lose")
	else:
		#create new sprite to show potted ball
		var b = Sprite2D.new()
		add_child(b)
		b.texture = body.get_node("Sprite2D").texture
		potted.append(b)
		b.position = Vector2(50 * potted.size(), 725)
		body.queue_free()
		#check for win condition
		if potted.size() == 15:
			game_over("win")

func game_over(outcome):
	hide_cue()
	get_tree().paused = true
	$Hud.show()
	if outcome == "win":
		$Hud/ResultPanel/ResultLabel.text = "YOU WIN!"
	else:
		$Hud/ResultPanel/ResultLabel.text = "GAME OVER!"
