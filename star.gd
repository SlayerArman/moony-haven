extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

var is_collected: bool = false

func _ready() -> void:
	animated_sprite.play("Star")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_collected:
		is_collected = true
		collision_shape.set_deferred("disabled", true)
		animated_sprite.play("Collected")
		GameManager.add_score()
		
		await animated_sprite.animation_finished
		
		queue_free()
