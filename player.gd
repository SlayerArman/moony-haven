extends CharacterBody2D

const SPEED = 120.0
const JUMP_VELOCITY = -250.0
const DOUBLE_JUMP_VELOCITY = -200

@export var fall_limit_y: float = 9999999
@export var interact_label: Label

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jump = false
var fade_tween: Tween
var is_prompt_active: bool = false

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

func _process(delta):
	check_tile_under_player()
	
	if is_prompt_active and Input.is_action_just_pressed("Interact"):
		on_interact()

func check_tile_under_player():
	if not interact_label:
		interact_label = get_tree().current_scene.get_node_or_null("InteractLabel")
	if not interact_label:
		return
		
	var tilemap = get_tree().current_scene.get_node_or_null("Interactables")
	if not tilemap:
		if is_prompt_active:
			hide_prompt_with_fade()
		return
	
	var player_tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	var tile_data = tilemap.get_cell_tile_data(player_tile_pos)
	
	if tile_data != null:
		if not is_prompt_active:
			show_prompt()
	else:
		if is_prompt_active:
			hide_prompt_with_fade()

func show_prompt():
	is_prompt_active = true

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	var x_offset = interact_label.size.x / 2.0
	interact_label.global_position = global_position + Vector2(-x_offset, -40.0)

	interact_label.modulate.a = 1.0
	interact_label.visible = true

func hide_prompt_with_fade():
	is_prompt_active = false

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_interval(2.0)
	fade_tween.tween_property(interact_label, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func(): interact_label.visible = false)

func on_interact():
	print("Interacted with tile!")

func restart_scene():
	get_tree().reload_current_scene()
