
extends Control

# UI REFERENCES
@onready var speaker_label: Label = $MarginContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: Label = $MarginContainer/VBoxContainer/DialogueLabel

@onready var choice_left: Button = $MarginContainer/VBoxContainer/ChoiceRow/ChoiceLeft
@onready var choice_right: Button = $MarginContainer/VBoxContainer/ChoiceRow/ChoiceRight

@onready var order_panel: PanelContainer = $MarginContainer/VBoxContainer/OrdelPanel
@onready var order_heading: Label = $MarginContainer/VBoxContainer/OrdelPanel/OrderVBox/OrderHeading
@onready var order_list: Label = $MarginContainer/VBoxContainer/OrdelPanel/OrderVBox/OrderList


# STORY DATA
const DIALOGUE = [
	{
		"speaker": "Katlyne",
		"text": "Hey... are you still open? I know it's really late.",
		"left": "Of course!",
		"right": "Come on in."
	},
	{
		"speaker": "Katlyne",
		"text": "Thank you. I didn't really know where else to go tonight.",
		"left": "Rough night?",
		"right": "Want to talk about it?"
	},
	{
		"speaker": "Katlyne",
		"text": "My mom passed away just a week ago. Everything has felt so different without her.",
		"left": "I'm so sorry.",
		"right": "That must be difficult."
	},
	{
		"speaker": "Katlyne",
		"text": "She used to make mala for me whenever I had a bad day. It was always my favorite.",
		"left": "That sounds lovely.",
		"right": "She sounds wonderful."
	},
	{
		"speaker": "Katlyne",
		"text": "I was walking past your stall when I smelled the broth. It reminded me of our kitchen.",
		"left": "Would you like some?",
		"right": "I can make you a bowl."
	},
	{
		"speaker": "Katlyne",
		"text": "Really? I haven't had much of an appetite lately... but I think I'd like to try.",
		"left": "What would you like?",
		"right": "Tell me your favorite."
	},
	{
		"speaker": "Katlyne",
		"text": "Two sliced beef, two mushrooms, one tomato, and one chili pepper. All in spicy red broth, please.",
		"left": "Got it!",
		"right": "Sounds delicious!",
		"show_order": true
	},
	{
		"speaker": "Katlyne",
		"text": "Thanks, chef. Mom used to call me downstairs whenever dinner was ready... I really miss that.",
		"left": "I'll make it special.",
		"right": "I'll do my best."
	}
]


# GAME STATE
var dialogue_index: int = 0
var order_confirmed: bool = false


func _ready() -> void:
	order_panel.hide()

	choice_left.pressed.connect(_on_left_pressed)
	choice_right.pressed.connect(_on_right_pressed)

	_show_current_dialogue()


# DISPLAY CURRENT DIALOGUE
func _show_current_dialogue() -> void:
	var current: Dictionary = DIALOGUE[dialogue_index]

	speaker_label.text = current["speaker"]
	dialogue_label.text = current["text"]

	choice_left.text = current["left"]
	choice_right.text = current["right"]

	if current.get("show_order", false):
		_show_order_panel()


# ADVANCE THE STORY
func _advance_dialogue() -> void:
	dialogue_index += 1

	if dialogue_index >= DIALOGUE.size():
		_show_order_summary()
	else:
		_show_current_dialogue()


# DISPLAY KATLYNE'S ORDER
func _show_order_panel() -> void:
	order_heading.text = "KATLYNE'S ORDER"

	order_list.text = (
		OrderData.format_order()
		+ "\nBroth: Spicy Red"
	)

	order_panel.show()


# FINAL DIALOGUE SCREEN
func _show_order_summary() -> void:
	order_confirmed = true

	speaker_label.text = "Chef's Note"

	dialogue_label.text = (
        "Time to make Katlyne's mala! "
		+ "Collect the ingredients she requested "
		+ "and prepare them for the hotpot."
	)

	_show_order_panel()

	choice_left.text = "START COOKING"
	choice_right.text = "REVIEW ORDER"


# LEFT BUTTON
func _on_left_pressed() -> void:
	if order_confirmed:
		_start_cooking()
	else:
		_advance_dialogue()


# RIGHT BUTTON
func _on_right_pressed() -> void:
	if order_confirmed:
		_review_order()
	else:
		_advance_dialogue()


# REPEAT ORDER INSTRUCTIONS
func _review_order() -> void:
	speaker_label.text = "Chef's Note"

	dialogue_label.text = (
        "Collect exactly the ingredients listed above. "
		+ "Avoid collecting anything Katlyne didn't request."
	)


# TRANSITION TO THE CONVEYOR STAGE
func _start_cooking() -> void:
	OrderData.reset_collected()

	get_tree().change_scene_to_file(
        "res://scenes/minigames/conveyor.tscn"
	)
