# ==========================
# mainmenu.gd 
# ==========================
class_name mainmenu_menu extends Control

# ==========================
# Buttons 
# ==========================
func _on_cargar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/selsave.tscn")

func _on_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/options.tscn")

func _on_salir_pressed() -> void:
	CONFIRM.mostrar_confirmacion(
		"¿Seguro que quieres salir?",
		func(): get_tree().quit(),  # 🔹 Cierra el juego al presionar "Sí"
		func(): SYSLOG.debug_log("El jugador canceló la salida.", "MAINMENU")
	)
