extends MeshInstance3D

func _ready() -> void:
	var area = get_node_or_null("Area3D")
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		push_warning("ไม่พบ Area3D ใต้ MeshInstance3D")


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		respawn_player(body)
		
func respawn_player(player: Node3D) -> void:
	# ตรวจสอบตัวสะกดในเครื่องหมายคำพูดให้ครบถ้วน
	var respawn_point = get_tree().get_first_node_in_group("spawn_point") as Marker3D
	
	if respawn_point:
		player.global_position = respawn_point.global_position
		player.global_rotation.y = respawn_point.global_rotation.y
		
		if "velocity" in player:
			player.velocity = Vector3.ZERO
	else:
		push_error("ไม่พบ Marker3D ที่อยู่ใน Group 'spawn_point' ในด่านนี้!")
