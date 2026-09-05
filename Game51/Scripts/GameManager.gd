extends Node3D

# ---------- VARIABLES ---------- #

var score = 0

# ---------- FUNCTIONS ---------- #

func _ready():
	# node_added alone would miss every node already in the initial scene:
	# the whole main scene is added (firing node_added for all its children)
	# before any autoload's deferred _ready() runs, so connecting here is too
	# late for that first batch. Explicitly walk what's already there, then
	# keep the connection for anything added later (level transitions).
	get_tree().node_added.connect(_on_node_added)
	_scan_existing_nodes(get_tree().root)

func _scan_existing_nodes(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_scan_existing_nodes(child)

# The Web export always runs on the Compatibility renderer, which silently
# ignores SSAO/SSIL/SSR/SDFGI occlusion that the levels are tuned with on
# Forward+ (PC/editor). Losing that contact darkening makes scenes look much
# brighter/washed out on web, so compensate only when Compatibility is active.
func _on_node_added(node: Node) -> void:
	if node is WorldEnvironment:
		_fix_web_brightness(node as WorldEnvironment)
	elif node is DirectionalLight3D:
		_fix_web_performance(node as DirectionalLight3D)

func _fix_web_brightness(world_env: WorldEnvironment) -> void:
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		return
	var env := world_env.environment
	if env == null:
		return
	env.tonemap_exposure *= 0.7
	env.ambient_light_energy *= 0.75
	env.adjustment_brightness *= 0.9
	# Glow is a full extra post-process pass and real-time shadows double the
	# draw calls of every static prop (color pass + shadow pass). Both are
	# expensive on the Compatibility renderer web is forced onto, so cut them
	# entirely on web instead of just toning them down.
	env.glow_enabled = false

func _fix_web_performance(light: DirectionalLight3D) -> void:
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		return
	light.shadow_enabled = false

func _process(_delta):
	show_mouse_cursor()

# Making Cursor visible using "mouse_visible" key which is assigned in Project Settings > Input Map
func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_score():
	score += 1
