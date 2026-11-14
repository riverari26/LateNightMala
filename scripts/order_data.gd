
extends Node

# =====================================
# KATLYNE'S ORDER DATA
# =====================================

# The ingredients Katlyne requested.
const REQUIRED_ORDER = {
	"Sliced Beef": 2,
	"Mushroom": 2,
	"Tomato": 1,
	"Chili Pepper": 1
}

# How many ingredients the player has collected.
var collected: Dictionary = {}


# =====================================
# INITIALIZATION
# =====================================

func _ready() -> void:
	reset_collected()


# =====================================
# RESET COLLECTED INGREDIENTS
# =====================================

func reset_collected() -> void:
	collected.clear()

	for ingredient in REQUIRED_ORDER:
		collected[ingredient] = 0


# =====================================
# FORMAT THE CUSTOMER'S ORDER
# =====================================

func format_order() -> String:
	var lines := PackedStringArray()

	for ingredient in REQUIRED_ORDER:
		var amount = REQUIRED_ORDER[ingredient]
		lines.append("%s x %d" % [ingredient, amount])

	return "\n".join(lines)


# =====================================
# FORMAT COLLECTION PROGRESS
# =====================================

func format_progress() -> String:
	var lines := PackedStringArray()

	for ingredient in REQUIRED_ORDER:
		var amount = REQUIRED_ORDER[ingredient]
		var current = collected.get(ingredient, 0)

		lines.append(
			"%s: %d / %d" % [ingredient, current, amount]
		)

	return "\n".join(lines)


# =====================================
# COUNT TOTAL REQUIRED INGREDIENTS
# =====================================

func total_required() -> int:
	var total: int = 0

	for ingredient in REQUIRED_ORDER:
		total += int(REQUIRED_ORDER[ingredient])

	return total


# =====================================
# COUNT TOTAL COLLECTED INGREDIENTS
# =====================================

func total_collected() -> int:
	var total: int = 0

	for ingredient in REQUIRED_ORDER:
		total += int(collected.get(ingredient, 0))

	return total


# =====================================
# CHECK IF THE ORDER IS COMPLETE
# =====================================

func is_complete() -> bool:
	for ingredient in REQUIRED_ORDER:
		var have: int = int(collected.get(ingredient, 0))
		var need: int = int(REQUIRED_ORDER[ingredient])

		if have < need:
			return false

	return true


# =====================================
# GET INDIVIDUAL COLLECTED INGREDIENTS
# =====================================

func get_collected_items() -> Array[String]:
	var items: Array[String] = []

	for ingredient in REQUIRED_ORDER:
		var quantity: int = int(collected.get(ingredient, 0))

		for i in range(quantity):
			items.append(str(ingredient))

	return items
