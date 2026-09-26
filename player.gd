extends CharacterBody2D

const SPEED = 120.0
const JUMP_VELOCITY = -250.0
const DOUBLE_JUMP_VELOCITY = -200
const CLIMB_SPEED = 80.0

@export var fall_limit_y: float = 9999999
@export var interact_label: Label

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jump = false
var fade_tween: Tween
var is_prompt_active: bool = false
var is_climbing: bool = false

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	if not interact_label:
		interact_label = get_tree().current_scene.get_node_or_null("CanvasLayer/InteractLabel")
	if interact_label:
		interact_label.visible = false

func _physics_process(delta):
	if is_climbing:
		velocity.x = 0
		velocity.y = -CLIMB_SPEED

		if animated_sprite.sprite_frames.has_animation("Climb"):
			animated_sprite.play("Climb")

		move_and_slide()

		var tilemap = get_tree().current_scene.get_node_or_null("Interactables")
		if tilemap:
			var player_tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
			var tile_data = tilemap.get_cell_tile_data(player_tile_pos)
			if tile_data == null:
				stop_climbing()

		# Jump off the ladder
		if Input.is_action_just_pressed("Jump"):
			stop_climbing()
			velocity.y = JUMP_VELOCITY

		return

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

func _process(_delta):
	if not is_climbing:
		check_tile_under_player()
	
	if is_prompt_active and Input.is_action_just_pressed("Interact"):
		on_interact()

func check_tile_under_player():
	if not interact_label:
		interact_label = get_tree().current_scene.get_node_or_null("CanvasLayer/InteractLabel")
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

	var player_screen_pos = get_global_transform_with_canvas().origin
	var x_offset = interact_label.size.x / 2.0
	interact_label.global_position = player_screen_pos + Vector2(-x_offset, -40.0)
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
	var tilemap = get_tree().current_scene.get_node_or_null("Interactables")
	if not tilemap:
		return

	var player_tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	var tile_data = tilemap.get_cell_tile_data(player_tile_pos)

	if tile_data != null:
		var interact_type = tile_data.get_custom_data("interact_type")

		match interact_type:
			"ladder":
				start_climbing(tilemap, player_tile_pos)
			"chest":
				open_chest(tilemap, player_tile_pos)
			_:
				print("Interacted with default/unassigned tile type: ", interact_type)

func open_chest(tilemap: TileMapLayer, tile_pos: Vector2i):
	print("Opened chest at position: ", tile_pos)
	
	if interact_label:
		interact_label.visible = false
	is_prompt_active = false

func start_climbing(tilemap: TileMapLayer, tile_pos: Vector2i):
	is_climbing = true

	var tile_local_center = tilemap.map_to_local(tile_pos)
	var tile_global_center = tilemap.to_global(tile_local_center)
	global_position.x = tile_global_center.x

	if interact_label:
		interact_label.visible = false
	is_prompt_active = false

func stop_climbing():
	is_climbing = false
	velocity.y = 0

func restart_scene():
	get_tree().reload_current_scene()
