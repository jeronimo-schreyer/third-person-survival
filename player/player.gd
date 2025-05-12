extends CharacterBody3D

@export var _rotation_speed := 12.0
@export var _movement_speed: float = 5.5

@onready var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _last_movement_direction := Vector3.FORWARD

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	_debug_draw()


func _on_grounded_state_physics_processing(delta: float) -> void:
	_move_controller(delta)
	_apply_gravity(delta)


func _move_controller(delta: float) -> void:
	# get input
	var horizontal: float = Input.get_axis("ui_right", "ui_left")
	var vertical: float = Input.get_axis("ui_down", "ui_up")

	# apply camera orientation
	var camera_basis = get_viewport().get_camera_3d().basis
	var direction: Vector3 = (camera_basis * Vector3(-horizontal, 0.0, -vertical)).normalized()

	# set movement vector
	if direction == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, _movement_speed)
		velocity.z = move_toward(velocity.z, 0.0, _movement_speed)
	else:
		velocity = Vector3(direction.x, 0.0, direction.z) * _movement_speed

	# orient skin mesh
	if direction.length() > 0.2:
		_last_movement_direction = direction
	var target_angle := atan2(-_last_movement_direction.x, -_last_movement_direction.z)
	$Armature.global_rotation.y = lerp_angle($Armature.rotation.y, target_angle, _rotation_speed * delta)

	# update state machine
	$States.set_expression_property("velocity", velocity)

	# apply movement
	move_and_slide()



func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta


func _debug_draw():
	# origin
	DebugDraw3D.draw_gizmo($Armature.global_transform * Transform3D.FLIP_Z)

	# velocity
	DebugDraw3D.draw_arrow_ray(
		$Armature.global_transform.origin + Vector3.UP,
		velocity, .2, Color.YELLOW, 0.1
	)
