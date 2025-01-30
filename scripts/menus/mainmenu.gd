# ==========================
# mainmenu.gd 
# ==========================
class_name class_mainmenu_menu extends Control

# ==========================
# Buttons 
# ==========================
func _on_cargar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/selsave.tscn")

func _on_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/options.tscn")

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/confirmar.tscn")
