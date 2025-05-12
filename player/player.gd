extends CharacterBody3D

@export var _rotation_speed := 12.0
@export var _movement_speed: float = 5.5

@onready var _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _last_movement_direction := Vector3.FORWARD

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	_move_controller(delta)
	_apply_gravity(delta)


func _move_controller(delta: float) -> void:
	var horizontal: float = Input.get_axis("ui_right", "ui_left")
	var vertical: float = Input.get_axis("ui_down", "ui_up")

	var camera_basis = get_viewport().get_camera_3d().basis
	var direction: Vector3 = (camera_basis * Vector3(-horizontal, 0.0, -vertical)).normalized()

	if direction == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, _movement_speed)
		velocity.z = move_toward(velocity.z, 0.0, _movement_speed)
	else:
		velocity = Vector3(direction.x, 0.0, direction.z) * _movement_speed

	if direction.length() > 0.2:
		_last_movement_direction = direction
	var target_angle := atan2(-_last_movement_direction.x, -_last_movement_direction.z)
	$Armature/Skeleton3D.global_rotation.y = lerp_angle($Armature/Skeleton3D.rotation.y, target_angle, _rotation_speed * delta)

	#var ground_speed: float = velocity.length()

	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
