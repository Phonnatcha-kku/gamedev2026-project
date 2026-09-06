extends Node3D

func _ready() -> void:
	# ตรวจและซ่อมแซม Scale ของทุกโหนดในฉากนี้ทันทีที่โหลดเสร็จ
	fix_all_zero_scales(self)

func fix_all_zero_scales(node: Node) -> void:
	if node is Node3D:
		var s = node.scale
		var fixed = false
		
		# เช็กและดันค่าให้พ้นจาก 0
		if is_zero_approx(s.x):
			s.x = 0.001
			fixed = true
		if is_zero_approx(s.y):
			s.y = 0.001
			fixed = true
		if is_zero_approx(s.z):
			s.z = 0.001
			fixed = true
			
		if fixed:
			node.scale = s
			print("🛠️ แก้ไข Scale ให้อัตโนมัติที่โหนด: ", node.get_path())

	# วนลูปไปตรวจลูกๆ ทุกระดับชั้น
	for child in node.get_children():
		fix_all_zero_scales(child)
