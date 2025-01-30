# ==========================
# confirmar2.gd 
# ==========================
class_name class_confirmar_2_menu extends Control

# ==========================
# Funciones principales
# ==========================
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# ==========================
# Buttons
# ==========================
func _on_no_pressed() -> void:
	queue_free()


func _on_si_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")
