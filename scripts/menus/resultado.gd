# ==========================
# resultado.gd
# ==========================
class_name class_resultado extends Control

# ==========================
# Referencias Internas
# ==========================
@onready var resultado_label: Label = $CanvasLayer/VBoxContainer/resultado
@onready var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer")
@onready var continuar_button: Button = $CanvasLayer/VBoxContainer/HBoxContainer/continuar

# ==========================
# Mostrar la Pantalla de Resultado
# ==========================
func mostrar_resultado(resultado: String):
	SYSLOG.debug_log("Mostrando resultado para %s.", "RESULT_MANAGER")

	if resultado_label == null:
		SYSLOG.error_log("No se encontró el nodo de texto resultado_label.", "RESULT_MANAGER")
		return  

	if canvas_layer:
		canvas_layer.visible = true  
	else:
		SYSLOG.error_log("No se encontró el CanvasLayer en resultado.tscn.", "RESULT_MANAGER")

	get_tree().paused = true  

	# 🔹 Obtener datos de progreso
	var save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado.", "RESULT_MANAGER")
		return

	var selected_savegame_key = SAVE.get_current_savegame_key()
	var current_phase = SAVE.get_phase()
	var next_phase = current_phase if resultado == "game_over" else current_phase + 1
	var total_points = save_data[selected_savegame_key]["save_points"]

	# 🔹 Obtener cantidad de enemigos en el siguiente nivel
	var enemies_next_level = LEVEL_MANAGER.get_enemy_count_for_phase()

	# 🔹 Obtener puntos de este nivel desde el HUD
	var hud = get_tree().get_nodes_in_group("level_hud")[0] if get_tree().get_nodes_in_group("level_hud").size() > 0 else null
	var level_points = hud.points if hud else 0

	LEVEL_MANAGER.guardar_progreso(resultado)

	if resultado == "victoria":
		resultado_label.text = "¡VICTORIA!\n\n" + \
			"Enemigos en el siguiente nivel: %d\n" % enemies_next_level + \
			"Puntos obtenidos en este nivel: %d\n" % level_points + \
			"Puntos totales: %d" % total_points
		continuar_button.text = "Continuar"
	else:
		resultado_label.text = "GAME OVER\n\n" + \
			"Fase alcanzada: %d\n" % current_phase + \
			"Puntos obtenidos en este nivel: %d\n" % level_points + \
			"Puntos totales: %d" % total_points
		continuar_button.text = "Reintentar"

# ==========================
# Señales conectadas desde el Inspector
# ==========================
func _on_reset_pressed() -> void:
	SYSLOG.debug_log("Botón RESET presionado. Reiniciando desde fase 1.", "RESULT_MANAGER")

	# 🔹 Ocultar el menú antes de reiniciar
	canvas_layer.visible = false
	get_tree().paused = false  

	LEVEL_MANAGER.reiniciar_desde_phase_1()

func _on_continuar_pressed() -> void:
	SYSLOG.debug_log("Botón CONTINUAR/REINTENTAR presionado. Reiniciando nivel.", "RESULT_MANAGER")

	# 🔹 Ocultar el menú antes de reiniciar
	canvas_layer.visible = false
	get_tree().paused = false  

	LEVEL_MANAGER.reiniciar_nivel()

func _on_terminar_pressed() -> void:
	SYSLOG.debug_log("Botón TERMINAR presionado. Volviendo al menú principal.", "RESULT_MANAGER")

	# 🔹 Ocultar el menú antes de volver al menú
	canvas_layer.visible = false
	get_tree().paused = false  

	LEVEL_MANAGER.volver_a_menu()
