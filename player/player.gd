extends CharacterBody3D


@export var _rotation_speed := 12.0
@export var _acceleration: float
@export var _walk_speed: float
@export var _run_speed: float

@onready var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mesh_direction := Vector3.FORWARD
var speed: float
var crouched := false
var aiming := false
var target_aim_position := Vector3.ZERO


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
		get_real_velocity() * 2.0, .2, Color.YELLOW, 0.1
	)

	if aiming:
		DebugDraw3D.draw_sphere(target_aim_position)


func _on_airborne_state_entered() -> void:
	$AnimationTree.set("parameters/conditions/is_falling", true)
	$AnimationTree.set("parameters/conditions/is_grounded", false)


func _on_grounded_state_entered() -> void:
	$AnimationTree.set("parameters/conditions/is_falling", false)
	$AnimationTree.set("parameters/conditions/is_grounded", true)


func _on_grounded_state_physics_processing(delta: float) -> void:
	# get input
	var h_input := Input.get_axis("ui_left", "ui_right")
	var v_input := Input.get_axis("ui_up", "ui_down")
	var direction := Vector3(h_input, 0.0, v_input)

	# apply camera orientation
	direction = direction.rotated(Vector3.UP, get_viewport().get_camera_3d().rotation.y).normalized()

	# set movement vector
	var max_speed = speed
	if (crouched or aiming) and max_speed > _walk_speed:
		max_speed = _walk_speed

	velocity.x = move_toward(velocity.x, direction.x * max_speed, _acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * max_speed, _acceleration * delta)

	# orient skin mesh
	if direction.length() > 0.2:
		if not aiming:
			mesh_direction = direction
		else:
			mesh_direction = Vector3.FORWARD.rotated(Vector3.UP,
				get_viewport().get_camera_3d().rotation.y).normalized()
	var target_angle := atan2(-mesh_direction.x, -mesh_direction.z)
	$Armature.global_rotation.y = lerp_angle($Armature.rotation.y, target_angle, _rotation_speed * delta)

	# update animation tree properties
	var velocity_normalized = velocity.length() / _run_speed if get_real_velocity().length() > 0.1 else Vector3.ZERO
	var computed_direction = Vector2(h_input, -v_input) * velocity_normalized if get_real_velocity().length() > 0.1 else Vector2.ZERO
	$AnimationTree.set("parameters/ground/movement/stand/walk/blend_position", velocity_normalized)
	$AnimationTree.set("parameters/ground/movement/stand/strafe/blend_position", computed_direction)
	$AnimationTree.set("parameters/ground/movement/crouch/walk/blend_position", velocity_normalized)
	$AnimationTree.set("parameters/ground/movement/crouch/strafe/blend_position", computed_direction)

	# update other properties
	$Armature/Skeleton3D/SpineLookAt.active = aiming
	$Armature/Skeleton3D/HeadLookAt.active = aiming
	if aiming:
		var space_state = get_world_3d().direct_space_state
		var camera = get_viewport().get_camera_3d()
		var mouse_position = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_position)
		target_aim_position = from + camera.project_ray_normal(mouse_position) * 5.0
		var query = PhysicsRayQueryParameters3D.create(from, target_aim_position, 0xffffff, [self])
		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			target_aim_position = result.position
		$LookAtTarget.global_transform.origin = target_aim_position


func _on_grounded_state_unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.physical_keycode:
			KEY_SHIFT:
				if event.is_pressed():
					speed = _run_speed
				else:
					speed = _walk_speed

			KEY_CTRL:
				if event.is_pressed() and not event.is_echo():
					crouched = !crouched
					$AnimationTree.set("parameters/ground/movement/conditions/is_standing", !crouched)
					$AnimationTree.set("parameters/ground/movement/conditions/is_crouched", crouched)

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				aiming = event.is_pressed()

				# Tween between states
				var aiming_properties = [
					"parameters/ground/movement/stand/aiming/blend_amount",
					"parameters/ground/movement/crouch/aiming/blend_amount",
				]

				for aiming_property in aiming_properties:
					var t = get_tree().create_tween()
					t.tween_property($AnimationTree, aiming_property, 1.0 if aiming else 0.0, 0.06).from_current()


func _on_grounded_state_exited() -> void:
	aiming = false
