extends CharacterBody3D


@export var _rotation_speed := 12.0
@export var _acceleration: float
@export var _walk_speed: float
@export var _run_speed: float

@onready var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _last_movement_direction := Vector3.FORWARD
var speed: float


func _ready() -> void:
	speed = _walk_speed


func _process(_delta: float) -> void:
	_debug_draw()


func _physics_process(delta: float) -> void:
	# apply gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# apply movement
	move_and_slide()

	# update state chart
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


func _on_airborne_state_entered() -> void:
	$AnimationTree.set("parameters/conditions/is_falling", true)
	$AnimationTree.set("parameters/conditions/is_grounded", false)


func _on_grounded_state_entered() -> void:
	$AnimationTree.set("parameters/conditions/is_falling", false)
	$AnimationTree.set("parameters/conditions/is_grounded", true)


func _on_grounded_state_physics_processing(delta: float) -> void:
	# get input
	var direction := Vector3(
		Input.get_axis("ui_left", "ui_right"),
		0.0,
		Input.get_axis("ui_up", "ui_down")
	)

	# apply camera orientation
	direction = direction.rotated(Vector3.UP, get_viewport().get_camera_3d().rotation.y).normalized()

	# set movement vector
	velocity.x = move_toward(velocity.x, direction.x * speed, _acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, _acceleration * delta)

	# orient skin mesh
	if direction.length() > 0.2:
		_last_movement_direction = direction
	var target_angle := atan2(-_last_movement_direction.x, -_last_movement_direction.z)
	$Armature.global_rotation.y = lerp_angle($Armature.rotation.y, target_angle, _rotation_speed * delta)

	$AnimationTree.set("parameters/grounded_movement_velocity/blend_position", velocity.length() / _run_speed)


func _on_grounded_state_unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_SHIFT:
		if event.is_pressed():
			speed = _run_speed
		else:
			speed = _walk_speed
