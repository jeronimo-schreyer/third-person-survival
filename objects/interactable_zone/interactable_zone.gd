@tool
class_name InteractableZone
extends Area3D


signal noticed
signal unnoticed


## Enable or disable interactable zone
@export var enabled : bool = true: set = _set_enabled


## Interaction distance
@export var interaction_distance : float = 0.3: set = _set_interaction_distance


# Add support for is_xr_class on XRTools classes
func is_xr_class(_name : String) -> bool:
	return _name == "InteractableZone"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set collision shape radius
	if has_node("CollisionShape3D") and "radius" in $CollisionShape3D.shape:
		$CollisionShape3D.shape.radius = interaction_distance


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Skip if in editor or not enabled
	if Engine.is_editor_hint() or not enabled:
		return


# interactabkle zone can be interacted with?
func can_interact() -> bool:
	# Refuse if not enabled
	if not enabled:
		return false

	return true


# Called when the enabled property has been modified
func _set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if is_inside_tree():
		$CollisionShape3D.disabled = !p_enabled


# Called when the grab distance has been modified
func _set_interaction_distance(new_value: float) -> void:
	interaction_distance = new_value
	if is_inside_tree() and "radius" in $CollisionShape3D.shape:
		$CollisionShape3D.shape.radius = interaction_distance


func _on_area_entered(_area: Area3D) -> void:
	noticed.emit()


func _on_area_exited(_area: Area3D) -> void:
	unnoticed.emit()
