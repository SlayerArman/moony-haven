extends CharacterBody2D

const SPEED = 120.0
const JUMP_VELOCITY = -250.0
const DOUBLE_JUMP_VELOCITY = -200

@export var fall_limit_y: float = 9999999

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jump = false

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_double_jump = true

	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif has_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			has_double_jump = false

	var direction = Input.get_axis("Move Left", "Move Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	update_animation(direction)
	move_and_slide()

	if global_position.y > fall_limit_y:
		restart_scene()

func update_animation(direction):
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if not is_on_floor():
		animated_sprite.play("Jump")
	elif direction != 0:
		animated_sprite.play("Running")
	else:
		animated_sprite.play("Idle")

func restart_scene():
	get_tree().reload_current_scene()
