extends Area3D

@export var next_scene : PackedScene

func _on_body_entered(body):
	if body.is_in_group("Player") and next_scene != null:
		if AudioManager and AudioManager.has_node("level_complete_sfx"):
			AudioManager.level_complete_sfx.play()
		
		# เปลี่ยนไปด่านถัดไปแบบปลอดภัยด้วย call_deferred
		get_tree().call_deferred("change_scene_to_packed", next_scene)
