extends CharacterBody3D

@export var _rotation_speed := 12.0
@export var _movement_speed: float = 5.5

@onready var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _last_movement_direction := Vector3.FORWARD

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	_debug_draw()


func _physics_process(delta: float) -> void:
	# get input
	var direction := Vector3.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.z = Input.get_axis("ui_up", "ui_down")

	# apply camera orientation
	direction = direction.rotated(Vector3.UP, get_viewport().get_camera_3d().rotation.y).normalized()

	# set movement vector
	velocity.x = move_toward(velocity.x, direction.x * _movement_speed, _movement_speed)
	velocity.z = move_toward(velocity.z, direction.z * _movement_speed, _movement_speed)

	# apply gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# apply movement
	move_and_slide()

	# orient skin mesh
	if direction.length() > 0.2:
		_last_movement_direction = direction
	var target_angle := atan2(-_last_movement_direction.x, -_last_movement_direction.z)
	$Armature.global_rotation.y = lerp_angle($Armature.rotation.y, target_angle, _rotation_speed * delta)

	# update state machine
	$States.set_expression_property("velocity", velocity)
	$States.set_expression_property("is_on_floor", is_on_floor())


func _debug_draw():
	# origin
	DebugDraw3D.draw_gizmo($Armature.global_transform * Transform3D.FLIP_Z)

	# velocity
	DebugDraw3D.draw_arrow_ray(
		$Armature.global_transform.origin + Vector3.UP,
		velocity, .2, Color.YELLOW, 0.1
	)
