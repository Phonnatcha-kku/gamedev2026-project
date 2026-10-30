extends MeshInstance3D

## ตำแหน่งที่ต้องการให้ Player ไปเกิดใหม่ (ปรับใน Inspector ได้)
@export var respawn_position: Vector3 = Vector3(0, 2, 0)

## เลือกว่าจะใช้วิธี Reload ด่านใหม่ทั้งหมด หรือแค่ย้ายพิกัด Player
@export var reload_scene_on_death: bool = false


func _ready() -> void:
	# ค้นหาโหนด Area3D ที่เป็นลูก แล้วเชื่อมต่อสัญญาณ body_entered อัตโนมัติ
	var area = get_node_or_null("Area3D")
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		push_warning("ไม่พบ Area3D ใต้ MeshInstance3D กรุณาสร้าง Area3D และ CollisionShape3D")


func _on_body_entered(body: Node3D) -> void:
	# ตรวจสอบว่าโหนดที่เข้ามาชนอยู่ใน Group "player" หรือไม่
	if body.is_in_group("Player"):
		respawn_player(body)


func respawn_player(player: Node3D) -> void:
	if reload_scene_on_death:
		# แบบที่ 1: โหลดฉากปัจจุบันใหม่ทั้งหมด
		get_tree().reload_current_scene()
	else:
		# แบบที่ 2: ย้ายตำแหน่ง Player ไปยังจุดเกิด
		player.global_position = respawn_position
		
		# หาก Player มีความเร็วสะสมตกค้าง (เช่น CharacterBody3D) ให้รีเซ็ตเป็น 0
		if "velocity" in player:
			player.velocity = Vector3.ZERO
