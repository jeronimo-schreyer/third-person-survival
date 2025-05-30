@tool
extends Node3D


@export var mouse_sensitivity: float = 0.05

@export_range(-89, 0, 1, "degrees") var min_pitch: float = -89.9
@export_range( 0, 89, 1, "degrees") var max_pitch: float = 50

@export var follow_speed: float = 3.0

@export_node_path("Node3D") var follow_target
@export_node_path("Node3D") var look_at_pivot

@export_range(0, 50, 0.01) var target_depth := 3.0 :
	set (v):
		target_depth = v
		if look_at_pivot != null and has_node(look_at_pivot):
			_look_at_target.position.z = -v

@export_range(0, 10, 0.01) var spring_arm_length := 1.0 :
	set (v):
		spring_arm_length = v
		if has_node("SpringArm3D"):
			$SpringArm3D.spring_length = v

@export_range(0, 10, 0.01) var spring_arm_height := 2.0 :
	set (v):
		spring_arm_height = v
		if has_node("SpringArm3D"):
			$SpringArm3D.position.y = v

@export_range(-90, 90, 1, "degrees") var side_offset = 0.0 :
	set (v):
		side_offset = v
		rotation_degrees.y = v

@export var camera_resource : Camera3DResource :
	set (v):
		camera_resource = v
		if has_node("SpringArm3D/PhantomCamera3D"):
			$SpringArm3D/PhantomCamera3D.camera_3d_resource = v

@export var priority: int = 0 :
	set (v):
		priority = v
		if has_node("SpringArm3D/PhantomCamera3D"):
			$SpringArm3D/PhantomCamera3D.priority = v

@export var mouse_captured = true :
	set (v):
		mouse_captured = v
		if not Engine.is_editor_hint():# and is_active:
			Input.mouse_mode = \
				Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

			if v and is_inside_tree():
				# remove ui focus if capturing mouse
				var current_focus_control = get_viewport().gui_get_focus_owner()
				if current_focus_control:
					current_focus_control.release_focus()

var _follow_target
var _look_at_pivot
var _look_at_target


func _ready() -> void:
	if not Engine.is_editor_hint():
		mouse_captured = mouse_captured

	if look_at_pivot:
		_look_at_pivot = get_node(look_at_pivot)
		_look_at_target = _look_at_pivot.get_child(0)

	if follow_target:
		_follow_target = get_node(follow_target)
		$SpringArm3D.add_excluded_object(_follow_target)


func _physics_process(delta: float) -> void:
	if _follow_target:
		global_position = global_position.move_toward(
			_follow_target.global_position,
			follow_speed * delta
		)

func _unhandled_input(event) -> void:
	if not Engine.is_editor_hint():# and is_active:
		# trigger whenever the mouse moves
		if event is InputEventMouseMotion and mouse_captured:
			var _rotation_degrees = $SpringArm3D.rotation_degrees

			# change the X rotation and clamp pitch
			_rotation_degrees.x -= event.relative.y * mouse_sensitivity
			_rotation_degrees.x = clampf(_rotation_degrees.x, min_pitch, max_pitch)

			# change the Y rotation value
			_rotation_degrees.y -= event.relative.x * mouse_sensitivity

			$SpringArm3D.rotation_degrees = _rotation_degrees

			if $SpringArm3D/PhantomCamera3D.is_active():
				_look_at_pivot.rotation_degrees = _rotation_degrees
				_look_at_target.position.z = -target_depth / cos(deg_to_rad(_rotation_degrees.x))

		# for now, release mouse when escaping
		elif event is InputEventKey:
			if not event.echo and event.pressed:
				match event.keycode:
					KEY_ESCAPE:
						mouse_captured = !mouse_captured


func _on_became_active() -> void:
	if not Engine.is_editor_hint():
		_look_at_pivot.position.y = spring_arm_height
		_look_at_target.position.z = -target_depth / cos(deg_to_rad($SpringArm3D.rotation_degrees.x))


func _on_became_inactive() -> void:
	if not Engine.is_editor_hint():
		pass#is_active = true


func _debug_draw():
	var _s = DebugDraw3D.new_scoped_config().set_no_depth_test(true)
	DebugDraw3D.draw_sphere(_look_at_target.global_position)
