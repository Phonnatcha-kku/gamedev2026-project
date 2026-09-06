extends Area3D

# ---------- VARIABLES ---------- #

# You can change these values from inspector!
@export_category("Properties")
@export var follow_speed := 6
@export var amplitude := 0.2
@export var frequency := 4

var time_passed = 0
var is_in_range = false
var is_collected: bool = false

# Vector
var initial_position := Vector3.ZERO

@onready var player := get_tree().get_first_node_in_group("Player")

# ---------- FUNCTIONS ---------- #

func _ready():
	initial_position = position

func _process(delta):
	coin_hover(delta) # Call the coin_hover function
	rotate_y(deg_to_rad(3))
	
	if is_in_range:
		# สั่งเล่นแอนิเมชันย่อขนาดแค่ "ครั้งเดียว" เมื่อผู้เล่นเข้ามาในระยะ
		if not is_collected:
			is_collected = true
			var tween = create_tween()
			
			# เปลี่ยนจาก Vector3.ZERO เป็น 0.001 เพื่อไม่ให้ Matrix Scale เป็น 0
			tween.tween_property(self, "scale", Vector3(0.001, 0.001, 0.001), 0.4).set_ease(Tween.EASE_IN_OUT)
			
			# พอย่อขนาดเสร็จแล้ว ค่อยสั่งลบเหรียญทิ้ง
			tween.tween_callback(queue_free)
		
		# ให้เหรียญลอยตาม Player ต่อไปในระหว่างที่กำลังหดตัว
		follow_player(delta)
	
# Coin Hover Animation
func coin_hover(delta):
	time_passed += delta
	
	var new_y = initial_position.y + amplitude * sin(frequency * time_passed)
	position.y = new_y

func follow_player(delta):
	position += global_position.direction_to(player.global_position) * follow_speed * delta

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	# Delete The Coin and Add Score
	if body.is_in_group("Player"):
		GameManager.add_score()
		AudioManager.coin_sfx.play()
		queue_free()

func _on_range_body_entered(body):
	if body.is_in_group("Player"):
		is_in_range = true
	else:
		is_in_range = false
