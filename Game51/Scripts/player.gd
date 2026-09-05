# ----------------------------------------------------------------------------------- #
# -------------- FEEL FREE TO USE IN ANY PROJECT, COMMERCIAL OR NON-COMMERCIAL ------ #
# ---------------------- 3D PLATFORMER CONTROLLER BY SD STUDIOS --------------------- #
# ---------------------------- ATTRIBUTION NOT REQUIRED ----------------------------- #
# ----------------------------------------------------------------------------------- #

extends CharacterBody3D

# ---------- CONSTANTS ---------- #
const ANIM_PREFIX = "CharacterArmature|CharacterArmature|CharacterArmature|"

# ---------- VARIABLES ---------- #

@export_category("Player Properties")
@export var walk_speed : float = 3.0
@export var run_speed : float = 6.5
@export var jump_force : float = 6.0
@export var follow_lerp_factor : float = 4.0

@export_group("Game Juice")
@export var jumpStretchSize := Vector3(0.8, 1.2, 0.8)

# Movement States
var current_speed : float = 3.0
var is_grounded = false
var can_double_jump = false
var is_waving = false # ตัวแปรเช็คสถานะกำลังโบกมือ

# Onready Variables
@onready var model = $Panda
@onready var animation = $Panda/AnimationPlayer2
@onready var spring_arm = %Gimbal

@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2

# ---------- FUNCTIONS ---------- #

func _ready():
	# เชื่อมต่อสัญญาณเมื่อแอนิเมชันเล่นจบ เพื่อปลดล็อคสถานะโบกมือ
	animation.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	handle_emote_input()
	get_input(delta)
	handle_jump()
	player_animations()
	
	# Smoothly follow player's position
	spring_arm.position = lerp(spring_arm.position, position, delta * follow_lerp_factor)
	
	# Player Rotation
	if is_moving():
		var look_direction = Vector2(velocity.z, velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * 12)
	
	# Handle Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	move_and_slide()

# รับคำสั่งกดโบกมือ (ปุ่ม Z หรือ Action "wave")
func handle_emote_input():
	var pressed_wave = (Input.is_action_just_pressed("wave") if InputMap.has_action("wave") else false) \
		or (Input.is_physical_key_pressed(KEY_Z) and Input.is_key_label_pressed(KEY_Z))
	
	# ต้องอยู่บนพื้นและไม่ได้กำลังเดิน จึงจะกดโบกมือได้
	if pressed_wave and is_on_floor() and not is_moving() and not is_waving:
		start_wave()

func start_wave():
	is_waving = true
	animation.play(ANIM_PREFIX + "Wave", 0.2)

func _on_animation_finished(anim_name: StringName):
	if anim_name == ANIM_PREFIX + "Wave":
		is_waving = false

# จัดการระบบกระโดด & Double Jump
func handle_jump():
	is_grounded = is_on_floor()
	
	if is_grounded:
		can_double_jump = true
	
	if Input.is_action_just_pressed("jump"):
		# หากกำลัง Wave อยู่แล้วกดกระโดด จะยกเลิก Wave ทันที
		if is_waving:
			is_waving = false
			
		if is_grounded:
			perform_jump()
		elif can_double_jump:
			perform_double_jump()

func perform_jump():
	AudioManager.jump_sfx.pitch_scale = 1.12
	AudioManager.jump_sfx.play()
	
	jumpTween()
	velocity.y = jump_force
	animation.play(ANIM_PREFIX + "Jump")

func perform_double_jump():
	can_double_jump = false
	AudioManager.jump_sfx.pitch_scale = 1.35
	AudioManager.jump_sfx.play()
	
	jumpTween()
	velocity.y = jump_force
	animation.stop()
	animation.play(ANIM_PREFIX + "Jump")

func is_moving():
	return abs(velocity.z) > 0.1 or abs(velocity.x) > 0.1

func jumpTween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", jumpStretchSize, 0.08)
	tween.tween_property(self, "scale", Vector3.ONE, 0.08)

# รับอินพุตการเคลื่อนที่และการเดิน/วิ่ง
func get_input(_delta):
	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_axis("move_left", "move_right")
	move_direction.z = Input.get_axis("move_forward", "move_back")
	
	# ถ้าระหว่าง Wave มีการกดทิศทางเดิน ให้ยกเลิกการโบกมือทันที
	if move_direction != Vector3.ZERO and is_waving:
		is_waving = false
	
	# ตรวจสอบการกดปุ่มวิ่ง
	var is_sprinting = Input.is_action_pressed("sprint")
	current_speed = run_speed if is_sprinting else walk_speed
	
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

# จัดการ State แอนิเมชัน
func player_animations():
	if is_on_floor():
		if is_moving():
			# ขณะเคลื่อนไหว
			if current_speed == run_speed:
				animation.play(ANIM_PREFIX + "Run", 0.3)
				particle_trail.emitting = true
			else:
				animation.play(ANIM_PREFIX + "Walk", 0.3)
				particle_trail.emitting = false
			footsteps.stream_paused = false
		else:
			# ขณะหยุดนิ่ง
			particle_trail.emitting = false
			footsteps.stream_paused = true
			
			# ถ้าไม่ได้กำลัง Wave ถึงจะเล่นท่า Idle ปกติ
			if not is_waving:
				animation.play(ANIM_PREFIX + "Idle", 0.3)
	else:
		# ตอนอยู่กลางอากาศ
		particle_trail.emitting = false
		footsteps.stream_paused = true
		if velocity.y < 0:
			animation.play(ANIM_PREFIX + "Jump_Idle", 0.2)
