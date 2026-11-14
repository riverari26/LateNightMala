
extends Control

# =====================================
# GAME SETTINGS
# =====================================

const INGREDIENT_TYPES: Array[String] = [
	"Mushroom",
	"Bok Choy",
	"Sliced Beef",
	"Potato",
	"Tomato",
	"Chili Pepper",
	"Shrimp"
]

const ITEM_SIZE = Vector2(146, 54)

const START_SPEED = 170.0
const MAX_SPEED = 350.0
const SPEED_INCREASE = 18.0

const SPAWN_INTERVAL = 1.15
const STUN_DURATION = 1.0


# =====================================
# PREP TRAY SETTINGS (NEW)
# =====================================

# Every individual slot in the preparation tray.
const TRAY_ITEMS: Array[String] = [
	"Sliced Beef",
	"Sliced Beef",
	"Mushroom",
	"Mushroom",
	"Tomato",
	"Chili Pepper"
]

const TRAY_NAMES: Array[String] = [
	"Beef 1",
	"Beef 2",
	"Mushroom 1",
	"Mushroom 2",
	"Tomato",
	"Chili"
]


# =====================================
# NODE REFERENCES
# =====================================

@onready var belt_track: ColorRect = $BeltTrack
@onready var ingredient_layer: Control = $IngredientLayer

@onready var heading: Label = $MarginContainer/VBoxContainer/Heading
@onready var instructions: Label = $MarginContainer/VBoxContainer/Instructions
@onready var order_progress: Label = $MarginContainer/VBoxContainer/OrderProgress
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

@onready var next_button: Button = $MarginContainer/VBoxContainer/NextStageButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

# New preparation tray reference.
@onready var prep_tray: HBoxContainer = $MarginContainer/VBoxContainer/PrepTray


# =====================================
# GAME VARIABLES
# =====================================

var belt_speed: float = START_SPEED
var spawn_timer: float = 0.0
var stun_remaining: float = 0.0

var grab_busy: bool = false
var game_finished: bool = false

var moving_items: Array[Button] = []
var ingredient_bag: Array[String] = []

var chopsticks: Node2D
var chopstick_rest: Vector2

# Stores references to the six tray labels.
var tray_labels: Array[Label] = []


# =====================================
# START THE GAME
# =====================================

func _ready() -> void:
	randomize()

	next_button.hide()

	next_button.pressed.connect(_go_to_next_stage)
	back_button.pressed.connect(_go_back)

	# Allow clicks to reach ingredient buttons.
	ingredient_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBoxContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$MarginContainer/VBoxContainer/Spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Prepare the conveyor and chopsticks.
	_setup_belt()
	_create_chopsticks()
	_refill_bag()

	# NEW: Build the preparation tray.
	_build_prep_tray()

	# Display the order and tray progress.
	_update_order_display()

	heading.text = "STAGE 1 - THE MIDNIGHT CONVEYOR"
	instructions.text = "Click the ingredients Katlyne requested!"
	status_label.text = "Ready? Grab the correct ingredients!"

	_spawn_ingredient()


# =====================================
# CREATE THE BELT
# =====================================

func _setup_belt() -> void:
	belt_track.position = Vector2(
		30,
		size.y * 0.50
	)

	belt_track.size = Vector2(
		size.x - 60,
		220
	)

	belt_track.color = Color(0.35, 0.22, 0.22)
	belt_track.mouse_filter = Control.MOUSE_FILTER_IGNORE


# =====================================
# CREATE VISIBLE CHOPSTICKS
# =====================================

func _create_chopsticks() -> void:
	chopsticks = Node2D.new()
	chopsticks.name = "Chopsticks"

	chopstick_rest = Vector2(
		size.x / 2.0,
		belt_track.position.y - 15.0
	)

	chopsticks.position = chopstick_rest
	add_child(chopsticks)

	# Draw two wooden sticks.
	for side in [-1.0, 1.0]:
		var stick = Line2D.new()

		stick.width = 8.0
		stick.default_color = Color(0.78, 0.52, 0.28)

		stick.add_point(Vector2(side * 16.0, -80.0))
		stick.add_point(Vector2(side * 4.0, 0.0))

		chopsticks.add_child(stick)


# =====================================
# INGREDIENT SPAWN BAG
# =====================================

func _refill_bag() -> void:
	# Guarantees each required ingredient appears regularly.
	ingredient_bag = [
		"Sliced Beef",
		"Sliced Beef",
		"Mushroom",
		"Mushroom",
		"Tomato",
		"Chili Pepper",
		"Bok Choy",
		"Potato",
		"Shrimp"
	]

	ingredient_bag.shuffle()


# =====================================
# SPAWN A MOVING INGREDIENT
# =====================================

func _spawn_ingredient() -> void:
	if ingredient_bag.is_empty():
		_refill_bag()

	var ingredient_name = ingredient_bag.pop_back()

	var item = Button.new()

	item.text = ingredient_name
	item.custom_minimum_size = ITEM_SIZE
	item.size = ITEM_SIZE
	item.focus_mode = Control.FOCUS_NONE

	item.add_theme_font_size_override("font_size", 18)

	ingredient_layer.add_child(item)

	# Choose one of three lanes.
	var lane = randi_range(0, 2)

	item.position = Vector2(
		size.x + 10,
		belt_track.position.y + 16 + lane * 67
	)

	# Connect clicks to the grabbing logic.
	item.pressed.connect(
		_on_ingredient_pressed.bind(item, ingredient_name)
	)

	moving_items.append(item)


# =====================================
# UPDATE EVERY FRAME
# =====================================

func _process(delta: float) -> void:
	if game_finished:
		return

	# Count down the wrong-grab penalty.
	if stun_remaining > 0.0:
		stun_remaining = maxf(
			0.0,
			stun_remaining - delta
		)

	# Spawn new ingredients.
	spawn_timer += delta

	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		_spawn_ingredient()

	# Move ingredients from right to left.
	for item in moving_items.duplicate():
		if not is_instance_valid(item):
			moving_items.erase(item)
			continue

		item.position.x -= belt_speed * delta

		# Remove ingredients that leave the screen.
		if item.position.x < -ITEM_SIZE.x:
			moving_items.erase(item)
			item.queue_free()


# =====================================
# CLICK AN INGREDIENT
# =====================================

func _on_ingredient_pressed(
	item: Button,
	ingredient_name: String
) -> void:

	if game_finished or grab_busy or stun_remaining > 0.0:
		return

	grab_busy = true

	# Pause the selected ingredient.
	moving_items.erase(item)
	item.disabled = true

	var target_position = item.position + ITEM_SIZE / 2.0

	var tween = create_tween()

	# Move chopsticks to the item.
	tween.tween_property(
		chopsticks,
		"position",
		target_position,
		0.12
	).set_trans(Tween.TRANS_SINE)

	# Check the ingredient.
	tween.tween_callback(
		_resolve_grab.bind(item, ingredient_name)
	)

	# Return chopsticks with a rebound.
	tween.tween_property(
		chopsticks,
		"position",
		chopstick_rest,
		0.25
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_callback(_release_grab)


# =====================================
# CHECK THE INGREDIENT
# =====================================

func _resolve_grab(
	item: Button,
	ingredient_name: String
) -> void:

	# Wrong ingredient.
	if not OrderData.REQUIRED_ORDER.has(ingredient_name):
		_wrong_grab(item)
		return

	var have: int = int(
		OrderData.collected[ingredient_name]
	)

	var need: int = int(
		OrderData.REQUIRED_ORDER[ingredient_name]
	)

	# Already collected enough of this ingredient.
	if have >= need:
		_wrong_grab(item)
		return

	# Correct ingredient!
	OrderData.collected[ingredient_name] = have + 1

	item.queue_free()

	# Increase belt speed.
	belt_speed = minf(
		belt_speed + SPEED_INCREASE,
		MAX_SPEED
	)

	status_label.text = "Nice! Collected: " + ingredient_name

	# Update BOTH checklist and prep tray.
	_update_order_display()

	# Check if all six ingredients are collected.
	if _is_order_complete():
		_finish_stage()


# =====================================
# WRONG INGREDIENT
# =====================================

func _wrong_grab(item: Button) -> void:
	stun_remaining = STUN_DURATION

	status_label.text = (
		"BOING! Wrong ingredient! Wait 1 second."
	)

	# Return the ingredient to the conveyor.
	item.disabled = false
	moving_items.append(item)


# =====================================
# RELEASE CHOPSTICKS
# =====================================

func _release_grab() -> void:
	grab_busy = false


# =====================================
# CREATE THE PREP TRAY (NEW)
# =====================================

func _build_prep_tray() -> void:
	# Remove old tray slots if needed.
	for child in prep_tray.get_children():
		prep_tray.remove_child(child)
		child.queue_free()

	tray_labels.clear()

	# Create six individual ingredient slots.
	for i in range(TRAY_ITEMS.size()):
		var slot_panel := PanelContainer.new()

		slot_panel.custom_minimum_size = Vector2(164, 70)
		slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Create a label inside each slot.
		var slot_label := Label.new()

		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		slot_label.add_theme_font_size_override(
			"font_size",
			15
		)

		# Add label inside slot panel.
		slot_panel.add_child(slot_label)

		# Add slot to the preparation tray.
		prep_tray.add_child(slot_panel)

		# Remember the label for updating.
		tray_labels.append(slot_label)

	# Set initial EMPTY / READY states.
	_refresh_prep_tray()


# =====================================
# REFRESH THE PREP TRAY (NEW)
# =====================================

func _refresh_prep_tray() -> void:
	var seen: Dictionary = {}

	for i in range(TRAY_ITEMS.size()):
		var ingredient: String = TRAY_ITEMS[i]

		# Determine which copy of this ingredient.
		var occurrence: int = int(
			seen.get(ingredient, 0)
		) + 1

		seen[ingredient] = occurrence

		# Check how many have been collected.
		var collected_amount: int = int(
			OrderData.collected.get(ingredient, 0)
		)

		# Determine whether this slot is filled.
		var is_filled: bool = (
			collected_amount >= occurrence
		)

		if is_filled:
			tray_labels[i].text = (
				TRAY_NAMES[i] + "\nREADY"
			)

			tray_labels[i].add_theme_color_override(
				"font_color",
				Color(0.45, 0.95, 0.55)
			)
		else:
			tray_labels[i].text = (
				TRAY_NAMES[i] + "\nEMPTY"
			)

			tray_labels[i].add_theme_color_override(
				"font_color",
				Color(0.80, 0.80, 0.80)
			)


# =====================================
# UPDATE ORDER CHECKLIST (UPDATED)
# =====================================

func _update_order_display() -> void:
	var current: int = OrderData.total_collected()
	var required: int = OrderData.total_required()

	order_progress.text = (
		"KATLYNE'S ORDER (%d / %d)\n" % [current, required]
		+ OrderData.format_progress()
	)

	# Update the visual prep tray.
	_refresh_prep_tray()


# =====================================
# CHECK ORDER COMPLETION
# =====================================

func _is_order_complete() -> bool:
	return OrderData.is_complete()


# =====================================
# FINISH STAGE 1
# =====================================

func _finish_stage() -> void:
	game_finished = true

	heading.text = "STAGE 1 COMPLETE!"

	instructions.text = (
		"Perfect! You've collected all six ingredients."
	)

	status_label.text = "Time to cook Katlyne's mala!"

	next_button.show()


# =====================================
# GO TO THE NEXT STAGE
# =====================================

func _go_to_next_stage() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/minigames/backboard.tscn"
	)


# =====================================
# BACK TO STORY
# =====================================

func _go_back() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/story/story.tscn"
	)
