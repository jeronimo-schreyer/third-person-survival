@tool
extends PhantomCamera3D

@export var mouse_sensitivity: float = 0.05

@export var min_yaw: float = 0
@export var max_yaw: float = 360

@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

@export var mouse_captured = true :
	set (v):
		mouse_captured = v
		if not Engine.is_editor_hint():
			Input.mouse_mode = \
				Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

			if v and is_inside_tree():
				# remove ui focus if capturing mouse
				var current_focus_control = get_viewport().gui_get_focus_owner()
				if current_focus_control:
					current_focus_control.release_focus()


func _init() -> void:
	if not Engine.is_editor_hint():
		mouse_captured = mouse_captured


func _unhandled_input(event) -> void:
	if not Engine.is_editor_hint():
		# trigger whenever the mouse moves
		if event is InputEventMouseMotion and mouse_captured:

			var pcam_rotation_degrees: Vector3

			# assigns the current 3D rotation of the SpringArm3D node - to start off where it is in the editor
			pcam_rotation_degrees = get_third_person_rotation_degrees()

			# change the X rotation.
			pcam_rotation_degrees.x -= event.relative.y * mouse_sensitivity

			# clamp the rotation in the X axis so it can go over or under the target
			pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)

			# change the Y rotation value
			pcam_rotation_degrees.y -= event.relative.x * mouse_sensitivity

			# sets the rotation to fully loop around its target, but without going below or exceeding 0 and 360 degrees respectively
			pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_yaw, max_yaw)

			# change the SpringArm3D node's rotation and rotate around its target
			set_third_person_rotation_degrees(pcam_rotation_degrees)

		elif event is InputEventKey:
			if not event.echo and event.pressed:
				match event.keycode:
					KEY_ESCAPE:
						mouse_captured = !mouse_captured
