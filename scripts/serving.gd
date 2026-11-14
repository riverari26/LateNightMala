
extends Control

# ==========================================
# LATE NIGHT MALA - SERVING AND FLASHBACK
# ==========================================

# Optional artwork.
# The game works even if these files do not exist.
const RESTAURANT_ART = "res://assets/backgrounds/serving_counter.png"
const BEDROOM_ART = "res://assets/backgrounds/katlyne_bedroom.png"
const RETURN_ART = "res://assets/backgrounds/restaurant_return.png"

# Optional background music.
const RAIN_MUSIC = "res://assets/audio/rainy_night.ogg"
const SAD_MUSIC = "res://assets/audio/sad_piano.ogg"


# ==========================================
# COMPLETE STORY
# ==========================================

const STORY = [
	{
		"scene": "restaurant",
		"speaker": "Narrator",
		"text": "The rain continues outside. You carefully place the steaming bowl of mala in front of Katlyne."
	},
	{
		"scene": "restaurant",
		"speaker": "Katlyne",
		"text": "It smells wonderful... I haven't eaten something like this in so long."
	},
	{
		"scene": "restaurant",
		"speaker": "Narrator",
		"text": "Katlyne lifts her spoon and takes her first bite. Suddenly, her eyes widen. That familiar taste... it's just like her mother's cooking."
	},
	{
		"scene": "bedroom",
		"speaker": "Narrator",
		"text": "Everything disappears. The restaurant, the rain, the hotpot... Katlyne is suddenly sitting in her childhood bedroom, years in the past."
	},
	{
		"scene": "bedroom",
		"speaker": "Mom (downstairs)",
		"text": "Katlyne, honey! Come downstairs! I made your favorite mala for dinner!"
	},
	{
		"scene": "bedroom",
		"speaker": "Young Katlyne",
		"text": "Coming, Mom! Did you put extra mushrooms in mine?"
	},
	{
		"scene": "bedroom",
		"speaker": "Mom (downstairs)",
		"text": "Of course I did, sweetheart! Now hurry before it gets cold!"
	},
	{
		"scene": "bedroom",
		"speaker": "Narrator",
		"text": "The house feels warm. The smell of mala fills the hallway. For just a moment, everything is exactly how it used to be."
	},
	{
		"scene": "bedroom",
		"speaker": "Young Katlyne",
		"text": "I'm coming! I love you, Mom!"
	},
	{
		"scene": "bedroom",
		"speaker": "Narrator",
		"text": "Her mother's laughter echoes from downstairs. Then the familiar room slowly begins to fade..."
	},
	{
		"scene": "return",
		"speaker": "Narrator",
		"text": "The bedroom disappears. Katlyne is back at the restaurant. The bowl is still warm in her hands, but tears are rolling down her cheeks."
	},
	{
		"scene": "return",
		"speaker": "Katlyne",
		"text": "Mom...?"
	},
	{
		"scene": "return",
		"speaker": "Katlyne",
		"text": "For a second, I thought I could hear her calling me downstairs again."
	},
	{
		"scene": "return",
		"speaker": "Chef",
		"text": "Take your time. There's no rush."
	},
	{
		"scene": "return",
		"speaker": "Katlyne",
		"text": "It's been a week since she passed away. I keep wishing I could have one more dinner with her."
	},
	{
		"scene": "return",
		"speaker": "Katlyne",
		"text": "But this... this tastes just like the mala she used to make. I didn't think I'd ever feel that warmth again."
	},
	{
		"scene": "return",
		"speaker": "Katlyne",
		"text": "I still miss her. I think I always will. But maybe I can carry the little things she left me into tomorrow."
	},
	{
		"scene": "return",
		"speaker": "Narrator",
		"text": "Katlyne takes another bite. This time, she smiles through her tears. Outside, the rain begins to slow."
	}
]


# ==========================================
# GAME STATE
# ==========================================

var beat_index: int = 0
var scene_kind: String = "restaurant"
var transitioning: bool = false
var story_finished: bool = false
var current_music_path: String = ""


# ==========================================
# UI REFERENCES
# ==========================================

var background_art: TextureRect
var scene_label: Label
var scene_note: Label

var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var continue_button: Button

var fade_overlay: ColorRect
var music_player: AudioStreamPlayer


# ==========================================
# START
# ==========================================

func _ready() -> void:
	# Hide the placeholders from Part 5.
	if has_node("Background"):
		$Background.hide()

	if has_node("ServingLabel"):
		$ServingLabel.hide()

	_create_background_layer()
	_create_interface()
	_create_music_player()
	_create_fade_overlay()

	_show_current_beat()


# ==========================================
# CREATE BACKGROUND IMAGE LAYER
# ==========================================

func _create_background_layer() -> void:
	background_art = TextureRect.new()
	background_art.name = "StoryBackground"

	add_child(background_art)

	background_art.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	background_art.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)

	background_art.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


# ==========================================
# CREATE A LABEL
# ==========================================

func _make_label(
	text_value: String,
	pos: Vector2,
	font_size: int,
	text_color: Color
) -> Label:
	var label = Label.new()

	label.text = text_value
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		text_color
	)

	add_child(label)

	return label


# ==========================================
# CREATE CUTSCENE INTERFACE
# ==========================================

func _create_interface() -> void:
	var cream = Color("#FFF0D5")

	scene_label = _make_label(
		"LATE NIGHT MALA",
		Vector2(48, 30),
		30,
		cream
	)

	scene_note = _make_label(
		"",
		Vector2(50, 83),
		19,
		Color("#FFE1B3")
	)

	# Dialogue background.
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"

	dialogue_panel.position = Vector2(48, 482)
	dialogue_panel.size = Vector2(1184, 215)

	add_child(dialogue_panel)

	# Custom dialogue box appearance.
	var panel_style = StyleBoxFlat.new()

	panel_style.bg_color = Color(
		0.15, 0.10, 0.14, 0.94
	)

	panel_style.border_color = Color("#D4A06C")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)

	dialogue_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	# Inner padding.
	var margins = MarginContainer.new()
	dialogue_panel.add_child(margins)

	margins.add_theme_constant_override("margin_left", 22)
	margins.add_theme_constant_override("margin_right", 22)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_bottom", 12)

	var content = VBoxContainer.new()
	margins.add_child(content)

	content.add_theme_constant_override(
		"separation", 7
	)

	# Speaker name.
	speaker_label = Label.new()
	speaker_label.text = "Katlyne"

	speaker_label.add_theme_font_size_override(
		"font_size", 23
	)

	speaker_label.add_theme_color_override(
		"font_color",
		Color("#FFC994")
	)

	content.add_child(speaker_label)

	# Dialogue text.
	dialogue_label = Label.new()
	dialogue_label.text = ""

	dialogue_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	dialogue_label.custom_minimum_size = Vector2(0, 74)

	dialogue_label.add_theme_font_size_override(
		"font_size", 22
	)

	dialogue_label.add_theme_color_override(
		"font_color",
		Color("#FFF0DE")
	)

	content.add_child(dialogue_label)

	# Bottom button row.
	var button_row = HBoxContainer.new()
	content.add_child(button_row)

	var empty_space = Control.new()
	empty_space.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	button_row.add_child(empty_space)

	continue_button = Button.new()
	continue_button.text = "CONTINUE"

	continue_button.custom_minimum_size = (
		Vector2(210, 45)
	)

	continue_button.add_theme_font_size_override(
		"font_size", 19
	)

	button_row.add_child(continue_button)

	continue_button.pressed.connect(
		_on_continue_pressed
	)


# ==========================================
# OPTIONAL BACKGROUND MUSIC
# ==========================================

func _create_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "StoryMusic"
	music_player.volume_db = -10.0

	add_child(music_player)


func _switch_music() -> void:
	var wanted_path = RAIN_MUSIC

	if scene_kind != "restaurant":
		wanted_path = SAD_MUSIC

	if wanted_path == current_music_path:
		return

	current_music_path = wanted_path
	music_player.stop()

	if ResourceLoader.exists(wanted_path):
		var music = load(wanted_path) as AudioStream

		if music != null:
			music_player.stream = music
			music_player.play()


# ==========================================
# CREATE FADE TRANSITION
# ==========================================

func _create_fade_overlay() -> void:
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"

	fade_overlay.color = Color(0, 0, 0, 0)

	add_child(fade_overlay)

	fade_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fade_overlay.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


# ==========================================
# SHOW CURRENT STORY LINE
# ==========================================

func _show_current_beat() -> void:
	var beat: Dictionary = STORY[beat_index]

	var new_scene: String = str(
		beat["scene"]
	)

	if scene_kind != new_scene:
		scene_kind = new_scene
		_switch_music()
	elif current_music_path == "":
		_switch_music()

	speaker_label.text = str(beat["speaker"])
	dialogue_label.text = str(beat["text"])

	continue_button.text = "CONTINUE"

	if scene_kind == "restaurant":
		scene_label.text = "A WARM BOWL"
		scene_note.text = "PRESENT DAY - RAINY MIDNIGHT"

	elif scene_kind == "bedroom":
		scene_label.text = "A DISTANT MEMORY"
		scene_note.text = "YEARS AGO - KATLYNE'S BEDROOM"

	elif scene_kind == "return":
		scene_label.text = "BACK TO THE PRESENT"
		scene_note.text = "A MEMORY THAT NEVER LEFT"

	_load_scene_background()
	queue_redraw()


# ==========================================
# LOAD OPTIONAL ARTWORK
# ==========================================

func _load_scene_background() -> void:
	var path = RESTAURANT_ART

	match scene_kind:
		"bedroom":
			path = BEDROOM_ART

		"return":
			path = RETURN_ART

		"restaurant":
			path = RESTAURANT_ART

		_:
			path = RESTAURANT_ART

	if ResourceLoader.exists(path):
		background_art.texture = (
			load(path) as Texture2D
		)
	else:
		background_art.texture = null


# ==========================================
# DRAW PLACEHOLDER SCENERY
# ==========================================

func _draw() -> void:
	if scene_kind == "bedroom":
		_draw_bedroom()
	elif scene_kind == "ending":
		_draw_ending()
	else:
		_draw_restaurant()


# ==========================================
# PLACEHOLDER RESTAURANT
# ==========================================

func _draw_restaurant() -> void:
	# Restaurant wall.
	draw_rect(
		Rect2(0, 0, 1280, 720),
		Color("#493039")
	)

	# Rainy window.
	draw_rect(
		Rect2(760, 105, 440, 330),
		Color("#253849")
	)

	# Window frames.
	draw_line(
		Vector2(980, 105),
		Vector2(980, 435),
		Color("#A67A62"),
		9
	)

	# Rain streaks.
	for i in range(17):
		var x = 780.0 + float(i * 23)

		draw_line(
			Vector2(x, 155),
			Vector2(x - 15, 210),
			Color(0.65, 0.80, 0.91, 0.45),
			2
		)

	# Countertop.
	draw_rect(
		Rect2(0, 390, 1280, 110),
		Color("#976248")
	)

	# Hotpot bowl.
	draw_circle(
		Vector2(630, 410),
		108,
		Color("#C44E3D")
	)

	draw_arc(
		Vector2(630, 410),
		110,
		0,
		TAU,
		48,
		Color("#E6B47A"),
		9
	)


# ==========================================
# PLACEHOLDER BEDROOM
# ==========================================

func _draw_bedroom() -> void:
	# Warm bedroom walls.
	draw_rect(
		Rect2(0, 0, 1280, 720),
		Color("#B88778")
	)

	# Floor.
	draw_rect(
		Rect2(0, 400, 1280, 320),
		Color("#805C57")
	)

	# Window.
	draw_rect(
		Rect2(810, 110, 270, 240),
		Color("#EAC6A1")
	)

	draw_rect(
		Rect2(826, 125, 238, 210),
		Color("#8199AD")
	)

	# Window frame.
	draw_line(
		Vector2(944, 125),
		Vector2(944, 335),
		Color("#F4DDC1"),
		7
	)

	# Childhood bed.
	draw_rect(
		Rect2(95, 290, 560, 180),
		Color("#8B5D61")
	)

	draw_rect(
		Rect2(112, 315, 520, 110),
		Color("#E9C3B4")
	)

	# Pillow.
	draw_rect(
		Rect2(135, 310, 145, 75),
		Color("#FFF0DC")
	)

	# Bedroom door.
	draw_rect(
		Rect2(1100, 120, 140, 360),
		Color("#66433E")
	)

	draw_circle(
		Vector2(1215, 305),
		7,
		Color("#F6CE88")
	)


# ==========================================
# ENDING BACKGROUND
# ==========================================

func _draw_ending() -> void:
	draw_rect(
		Rect2(0, 0, 1280, 720),
		Color("#4F343C")
	)

	draw_circle(
		Vector2(640, 325),
		155,
		Color("#D6A278")
	)

	draw_circle(
		Vector2(640, 325),
		128,
		Color("#B94436")
	)


# ==========================================
# CONTINUE BUTTON
# ==========================================

func _on_continue_pressed() -> void:
	if transitioning:
		return

	if story_finished:
		get_tree().change_scene_to_file(
			"res://scenes/menus/main_menu.tscn"
		)
		return

	if beat_index >= STORY.size() - 1:
		_finish_story()
		return

	var next_index = beat_index + 1

	var current_scene = str(
		STORY[beat_index]["scene"]
	)

	var next_scene = str(
		STORY[next_index]["scene"]
	)

	if current_scene != next_scene:
		_fade_to_next_scene(next_index)
	else:
		beat_index = next_index
		_show_current_beat()


# ==========================================
# FADE BETWEEN LOCATIONS
# ==========================================

func _fade_to_next_scene(next_index: int) -> void:
	transitioning = true
	continue_button.disabled = true

	var fade_speed = 0.55

	# Make the sudden memory transition quicker.
	if str(STORY[next_index]["scene"]) == "bedroom":
		fade_speed = 0.20

	var tween = create_tween()

	# Fade to black.
	tween.tween_property(
		fade_overlay,
		"color:a",
		1.0,
		fade_speed
	)

	# Change the story while the screen is black.
	tween.tween_callback(
		_change_beat.bind(next_index)
	)

	# Fade back in.
	tween.tween_property(
		fade_overlay,
		"color:a",
		0.0,
		0.85
	)

	tween.tween_callback(
		_unlock_transition
	)


# ==========================================
# CHANGE STORY BEAT
# ==========================================

func _change_beat(next_index: int) -> void:
	beat_index = next_index
	_show_current_beat()


func _unlock_transition() -> void:
	transitioning = false
	continue_button.disabled = false


# ==========================================
# FINISH THE STORY
# ==========================================

func _finish_story() -> void:
	story_finished = true
	scene_kind = "ending"

	background_art.texture = null

	scene_label.text = "NIGHT 1 COMPLETE"
	scene_note.text = "LATE NIGHT MALA - BOUNCE BACK"

	speaker_label.text = "THE END"

	dialogue_label.text = (
		"Some things can never return. "
		+ "But the love they leave behind can still "
		+ "help us find our way forward. "
		+ "Thank you for playing."
	)

	continue_button.text = "MAIN MENU"

	queue_redraw()
