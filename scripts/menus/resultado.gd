# ==========================
# resultado.gd
# ==========================
class_name class_resultado_menu extends Control

# ==========================
# Buttons
# ==========================
func _on_continuar_pressed() -> void:
	pass


func _on_terminar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")
