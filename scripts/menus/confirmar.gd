# ==========================
# confirmar.gd 
# ==========================
class_name class_confirmar_menu extends Control

# ==========================
# Buttons
# ==========================
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_no_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/mainmenu.tscn")


func _on_si_pressed() -> void:
	get_tree().quit()
