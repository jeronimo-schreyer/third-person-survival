extends Node3D
class_name Interactable


var noticed := false


# Add support for is_xr_class on XRTools classes
func is_xr_class(_name : String) -> bool:
	return _name == "Interactable"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if noticed:
		var aabb = $SM_Prop_Target_03.get_aabb()
		var global_min = $SM_Prop_Target_03.global_transform * aabb.position
		var global_max = $SM_Prop_Target_03.global_transform * (aabb.position + aabb.size)
		DebugDraw3D.draw_aabb_ab(global_min, global_max)


func _on_interactable_zone_noticed() -> void:
	noticed = true


func _on_interactable_zone_unnoticed() -> void:
	noticed = false
