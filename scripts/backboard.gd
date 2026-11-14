
extends Control

# ==========================================
# LATE NIGHT MALA - BACKBOARD TOSS
# ==========================================

# Canvas size
const SCREEN_SIZE = Vector2(1280, 720)

# Position where ingredients are launched
const LAUNCH_POINT = Vector2(235, 525)

# Physics settings
const GRAVITY = 700.0
const THROW_POWER = 5.0
const MAX_DRAG = 210.0
const INGREDIENT_RADIUS = 16.0
const BOUNCE_STRENGTH = 0.9

# Kitchen collision areas
const BOARD_RECT = Rect2(1090, 205, 22, 345)
const GLASS_RECT = Rect2(635, 405, 18, 235)

# Hotpot areas
const MILD_RECT = Rect2(700, 550, 160, 90)
const SPICY_RECT = Rect2(860, 550, 160, 90)

# Inventory
var ingredients: Array[String] = []
var current_index: int = 0

# Slingshot controls
var dragging: bool = false
var drag_position: Vector2 = LAUNCH_POINT
var trajectory_points: Array[Vector2] = []

# Active projectile
var projectile: RigidBody2D = null
var shot_active: bool = false
var touched_backboard: bool = false
var shot_timer: float = 0.0

# Stage state
var stage_complete: bool = false

# Interface
var progress_label: Label
var status_label: Label
var current_label: Label
var tray_labels: Array[Label] = []
var continue_button: Button


# ==========================================
# INITIALIZE STAGE
# ==========================================

func _ready() -> void:
	# Hide the old Part 4 placeholder visuals.
	if has_node("ColorRect"):
		$ColorRect.hide()

	if has_node("StageInfo"):
		$StageInfo.hide()

	# Retrieve ingredients from the conveyor.
	ingredients = OrderData.get_collected_items()

	_create_interface()
	_create_physics_world()

	if not OrderData.is_complete():
		stage_complete = true
		status_label.text = (
            "Please finish collecting Katlyne's "
			+ "ingredients in Stage 1 first."
		)
	else:
		_update_interface()

	queue_redraw()


# ==========================================
# CREATE LABEL HELPER
# ==========================================

func _make_label(
	label_text: String,
	label_position: Vector2,
	font_size: int,
	font_color: Color
) -> Label:
	var new_label = Label.new()

	new_label.text = label_text
	new_label.position = label_position
	new_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	new_label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	new_label.add_theme_color_override(
		"font_color",
		font_color
	)

	add_child(new_label)

	return new_label


# ==========================================
# CREATE GAME INTERFACE
# ==========================================

func _create_interface() -> void:
	var cream = Color("#FFE8CC")

	_make_label(
		"STAGE 2 - THE BACKBOARD TOSS",
		Vector2(30, 20),
		30,
		cream
	)

	progress_label = _make_label(
		"0 / 6",
		Vector2(1100, 25),
		28,
		cream
	)

	status_label = _make_label(
		"Ready to cook?",
		Vector2(35, 110),
		23,
		cream
	)

	_make_label(
		"Click the ingredient, pull DOWN-LEFT, then release.",
		Vector2(35, 151),
		19,
		Color("#F9C99C")
	)

	current_label = _make_label(
		"",
		Vector2(40, 467),
		22,
		cream
	)

	_make_label(
		"MILD",
		Vector2(747, 573),
		19,
		Color("#4B3025")
	)

	_make_label(
		"SPICY",
		Vector2(904, 573),
		19,
		Color("#FFF2D8")
	)

	_make_label(
		"BOUNCE BACK!",
		Vector2(1045, 175),
		20,
		Color("#FFD18A")
	)

	# Six ingredient slots at the bottom.
	for i in range(6):
		var tray_label = _make_label(
			"",
			Vector2(42 + i * 203, 672),
			15,
			cream
		)

		tray_labels.append(tray_label)

	# Continue button appears after all shots succeed.
	continue_button = Button.new()
	continue_button.text = "CONTINUE TO SERVING"
	continue_button.position = Vector2(466, 285)
	continue_button.size = Vector2(350, 70)

	continue_button.add_theme_font_size_override(
		"font_size",
		22
	)

	add_child(continue_button)

	continue_button.hide()

	continue_button.pressed.connect(
		_continue_to_serving
	)


# ==========================================
# CREATE STATIC PHYSICS WALL
# ==========================================

func _create_wall(
	wall_name: String,
	rectangle: Rect2,
	bounce_amount: float
) -> void:
	var wall = StaticBody2D.new()
	wall.name = wall_name

	wall.position = (
		rectangle.position + rectangle.size / 2.0
	)

	var shape_node = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()

	rectangle_shape.size = rectangle.size
	shape_node.shape = rectangle_shape

	wall.add_child(shape_node)

	var material = PhysicsMaterial.new()
	material.bounce = bounce_amount
	material.friction = 0.0

	wall.physics_material_override = material

	add_child(wall)


# ==========================================
# CREATE SOUP DETECTION AREA
# ==========================================

func _create_soup_area(
	area_name: String,
	rectangle: Rect2,
	broth_name: String
) -> void:
	var area = Area2D.new()
	area.name = area_name

	area.position = (
		rectangle.position + rectangle.size / 2.0
	)

	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 1

	var shape_node = CollisionShape2D.new()
	var rectangle_shape = RectangleShape2D.new()

	rectangle_shape.size = rectangle.size
	shape_node.shape = rectangle_shape

	area.add_child(shape_node)
	add_child(area)

	area.body_entered.connect(
		_on_soup_entered.bind(broth_name)
	)


# ==========================================
# CREATE PHYSICS WORLD
# ==========================================

func _create_physics_world() -> void:
	# Wooden backboard: bouncy.
	_create_wall(
		"BounceBoard",
		BOARD_RECT,
		1.0
	)

	# Glass guard: stops direct throws.
	_create_wall(
		"GlassGuard",
		GLASS_RECT,
		0.0
	)

	# Two soup targets.
	_create_soup_area(
		"MildSoup",
		MILD_RECT,
        "Mild"
	)

	_create_soup_area(
		"SpicySoup",
		SPICY_RECT,
        "Spicy"
	)


# ==========================================
# DRAW THE KITCHEN
# ==========================================

func _draw() -> void:
	# Background
	draw_rect(
		Rect2(Vector2.ZERO, SCREEN_SIZE),
		Color("#302332")
	)

	# Restaurant back wall
	draw_rect(
		Rect2(0, 90, 1280, 550),
		Color("#49313A")
	)

	# Upper interface bar
	draw_rect(
		Rect2(0, 0, 1280, 90),
		Color("#261C28")
	)

	# Wooden prep counter
	draw_rect(
		Rect2(25, 548, 525, 20),
		Color("#A66E50")
	)

	# Glass sneeze guard
	draw_rect(
		GLASS_RECT,
		Color(0.70, 0.88, 0.96, 0.45)
	)

	draw_line(
		GLASS_RECT.position,
		GLASS_RECT.position + Vector2(0, GLASS_RECT.size.y),
		Color("#CDE7EC"),
		3.0
	)

	# Backboard
	draw_rect(
		BOARD_RECT,
		Color("#B67B54")
	)

	draw_rect(
		BOARD_RECT,
		Color("#F2C58E"),
		false,
		3.0
	)

	# Hotpot outer frame
	draw_rect(
		Rect2(691, 541, 338, 108),
		Color("#D9AB7F")
	)

	# Mild broth
	draw_rect(
		MILD_RECT,
		Color("#F3C88A")
	)

	# Spicy red broth
	draw_rect(
		SPICY_RECT,
		Color("#C64739")
	)

	# Divider between soups
	draw_line(
		Vector2(860, 550),
		Vector2(860, 640),
		Color("#5A362F"),
		5.0
	)

	# Bottom counter
	draw_rect(
		Rect2(0, 643, 1280, 77),
		Color("#32232C")
	)

	# Inventory slot backgrounds
	for i in range(6):
		draw_rect(
			Rect2(30 + i * 203, 660, 192, 48),
			Color("#654448")
		)

	# Draw the next ingredient ready to throw.
	if not shot_active and not stage_complete:
		if current_index < ingredients.size():
			var ingredient_name = ingredients[current_index]

			draw_circle(
				LAUNCH_POINT,
				22,
				_ingredient_color(ingredient_name)
			)

			draw_arc(
				LAUNCH_POINT,
				27,
				0,
				TAU,
				32,
				Color("#FFE5B5"),
				3.0
			)

	# Slingshot aiming preview
	if dragging:
		draw_line(
			LAUNCH_POINT,
			drag_position,
			Color("#F6A57D"),
			2.0
		)

		for point in trajectory_points:
			draw_circle(
				point,
				3.5,
				Color("#FFE7B4")
			)


# ==========================================
# INGREDIENT COLORS
# ==========================================

func _ingredient_color(name: String) -> Color:
	match name:
		"Sliced Beef":
			return Color("#DA8274")

		"Mushroom":
			return Color("#D5AD82")

		"Tomato":
			return Color("#EC6049")

		"Chili Pepper":
			return Color("#D52E33")

		_:
			return Color("#F2DAA4")


# ==========================================
# SLINGSHOT INPUT
# ==========================================

func _input(event: InputEvent) -> void:
	if stage_complete or shot_active:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				# Start dragging only near the ingredient.
				if event.position.distance_to(LAUNCH_POINT) <= 55:
					dragging = true
					drag_position = event.position
					_update_trajectory()
					queue_redraw()

			elif dragging:
				# Release the slingshot.
				dragging = false
				drag_position = event.position

				var launch_velocity = _get_launch_velocity()

				trajectory_points.clear()

				if launch_velocity != Vector2.ZERO:
					_launch_ingredient(launch_velocity)
				else:
					status_label.text = (
                        "Pull DOWN and LEFT before releasing!"
					)

				queue_redraw()

	elif event is InputEventMouseMotion:
		if dragging:
			drag_position = event.position
			_update_trajectory()
			queue_redraw()


# ==========================================
# CALCULATE LAUNCH VELOCITY
# ==========================================

func _get_launch_velocity() -> Vector2:
	var pull = LAUNCH_POINT - drag_position

	pull = pull.limit_length(MAX_DRAG)

	# We want the player to pull down-left.
	if pull.x < 45.0 or pull.y > -20.0:
		return Vector2.ZERO

	return pull * THROW_POWER


# ==========================================
# PREVIEW THE TRAJECTORY
# ==========================================

func _update_trajectory() -> void:
	trajectory_points.clear()

	var velocity = _get_launch_velocity()

	if velocity == Vector2.ZERO:
		return

	var predicted_position = LAUNCH_POINT
	var bounced = false

	var time_step = 0.035

	for i in range(95):
		velocity.y += GRAVITY * time_step

		var next_position = (
			predicted_position + velocity * time_step
		)

		# Approximate the collision against the board.
		var board_face = (
			BOARD_RECT.position.x - INGREDIENT_RADIUS
		)

		if not bounced and velocity.x > 0:
			if (
				predicted_position.x < board_face
				and next_position.x >= board_face
				and next_position.y >= BOARD_RECT.position.y
				and next_position.y <= BOARD_RECT.end.y
			):
				next_position.x = board_face
				velocity.x = -velocity.x * BOUNCE_STRENGTH
				bounced = true

		# Stop preview at the glass.
		if GLASS_RECT.has_point(next_position):
			break

		# Stop preview when reaching either soup.
		if MILD_RECT.has_point(next_position):
			break

		if SPICY_RECT.has_point(next_position):
			break

		# Show every second simulation point.
		if i % 2 == 0:
			trajectory_points.append(next_position)

		predicted_position = next_position

		if predicted_position.y > 720:
			break


# ==========================================
# CREATE AND LAUNCH INGREDIENT
# ==========================================

func _launch_ingredient(
	launch_velocity: Vector2
) -> void:
	if current_index >= ingredients.size():
		return

	shot_active = true
	touched_backboard = false
	shot_timer = 0.0

	var ingredient_name = ingredients[current_index]

	projectile = RigidBody2D.new()
	projectile.name = "FlyingIngredient"

	projectile.position = LAUNCH_POINT
	projectile.mass = 1.0

	# Use a consistent gravity regardless of defaults.
	var default_gravity: float = float(
		ProjectSettings.get_setting(
            "physics/2d/default_gravity"
		)
	)

	projectile.gravity_scale = (
		GRAVITY / maxf(default_gravity, 1.0)
	)

	projectile.lock_rotation = true

	projectile.linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	projectile.linear_damp = 0.0

	projectile.continuous_cd = (
		RigidBody2D.CCD_MODE_CAST_SHAPE
	)

	projectile.contact_monitor = true
	projectile.max_contacts_reported = 6

	# Add its collision shape.
	var collision_node = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()

	circle_shape.radius = INGREDIENT_RADIUS
	collision_node.shape = circle_shape

	projectile.add_child(collision_node)

	# Add a visible circular ingredient.
	var graphic = Polygon2D.new()
	var points = PackedVector2Array()

	for i in range(24):
		var angle = float(i) / 24.0 * TAU

		points.append(
			Vector2(cos(angle), sin(angle))
			* INGREDIENT_RADIUS
		)

	graphic.polygon = points
	graphic.color = _ingredient_color(ingredient_name)

	projectile.add_child(graphic)

	# Abbreviated ingredient label.
	var letter = Label.new()

	letter.text = ingredient_name.substr(0, 1)
	letter.position = Vector2(-7, -13)

	letter.add_theme_font_size_override(
		"font_size",
		20
	)

	letter.add_theme_color_override(
		"font_color",
		Color("#301E25")
	)

	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE

	projectile.add_child(letter)

	# Add bounce material.
	var material = PhysicsMaterial.new()
	material.bounce = BOUNCE_STRENGTH
	material.friction = 0.0

	projectile.physics_material_override = material

	add_child(projectile)

	# Listen for wall collisions.
	projectile.body_entered.connect(
		_on_projectile_collision
	)

	# A one-time impulse launches the ingredient.
	projectile.apply_central_impulse(
		launch_velocity * projectile.mass
	)

	status_label.text = (
        "Ingredient launched! Hit the wooden backboard!"
	)

	queue_redraw()


# ==========================================
# CHECK WALL COLLISIONS
# ==========================================

func _on_projectile_collision(body: Node) -> void:
	if not shot_active:
		return

	if body.name == "BounceBoard":
		touched_backboard = true

		status_label.text = (
            "BOING! Great bank shot! Land in the red broth!"
		)

	elif body.name == "GlassGuard":
		_fail_shot(
            "The glass blocked your throw! Aim higher."
		)


# ==========================================
# CHECK HOTPOT LANDING
# ==========================================

func _on_soup_entered(
	body: Node2D,
	broth_name: String
) -> void:
	if not shot_active:
		return

	if body != projectile:
		return

	# The bank shot is mandatory.
	if not touched_backboard:
		_fail_shot(
            "You must bounce off the backboard first!"
		)
		return

	# Katlyne ordered spicy broth.
	if broth_name == "Spicy":
		_successful_shot()
	else:
		_fail_shot(
            "Oops! That landed in the MILD broth. Try again!"
		)


# ==========================================
# SUCCESSFUL SHOT
# ==========================================

func _successful_shot() -> void:
	_remove_projectile()

	current_index += 1

	status_label.text = (
        "SPLASH! Perfect! Ingredient landed in spicy broth!"
	)

	if current_index >= ingredients.size():
		_complete_stage()
	else:
		_update_interface()


# ==========================================
# FAILED SHOT
# ==========================================

func _fail_shot(message: String) -> void:
	_remove_projectile()

	status_label.text = message

	# Do not increase current_index.
	# Player retries the same ingredient.
	_update_interface()


# ==========================================
# REMOVE ACTIVE PROJECTILE
# ==========================================

func _remove_projectile() -> void:
	shot_active = false
	touched_backboard = false

	if is_instance_valid(projectile):
		projectile.queue_free()

	projectile = null

	queue_redraw()


# ==========================================
# DETECT MISSED THROWS
# ==========================================

func _process(delta: float) -> void:
	if not shot_active:
		return

	shot_timer += delta

	if not is_instance_valid(projectile):
		return

	var pos = projectile.position

	if (
		pos.y > 730
		or pos.x < -50
		or pos.x > 1350
		or shot_timer > 5.0
	):
		_fail_shot(
            "Missed! Adjust your aim and try again."
		)


# ==========================================
# UPDATE INTERFACE
# ==========================================

func _update_interface() -> void:
	progress_label.text = (
		"%d / %d" % [
			current_index,
			ingredients.size()
		]
	)

	if current_index < ingredients.size():
		current_label.text = (
            "THROW: "
			+ ingredients[current_index]
		)
	else:
		current_label.text = "ALL INGREDIENTS COOKED!"

	for i in range(tray_labels.size()):
		if i >= ingredients.size():
			tray_labels[i].text = ""
			continue

		if i < current_index:
			tray_labels[i].text = (
				"DONE: " + ingredients[i]
			)
		elif i == current_index:
			tray_labels[i].text = (
				"NEXT: " + ingredients[i]
			)
		else:
			tray_labels[i].text = ingredients[i]

	queue_redraw()


# ==========================================
# STAGE COMPLETE
# ==========================================

func _complete_stage() -> void:
	stage_complete = true

	status_label.text = (
        "THE HOTPOT IS READY! All six ingredients cooked!"
	)

	_update_interface()

	continue_button.show()

	queue_redraw()


# ==========================================
# CONTINUE TO SERVING
# ==========================================

func _continue_to_serving() -> void:
	get_tree().change_scene_to_file(
        "res://scenes/story/serving.tscn"
	)
