# ==========================
# resultado.gd
# ==========================
class_name resultado extends Control

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

	if not resultado_label:
		SYSLOG.error_log("No se encontró el nodo de texto resultado_label.", "RESULT_MANAGER")
		return  

	if canvas_layer:
		canvas_layer.visible = true  
	else:
		SYSLOG.error_log("No se encontró el CanvasLayer en resultado.tscn.", "RESULT_MANAGER")

	get_tree().paused = true  

	# 🔹 Esperar un frame antes de leer el guardado para asegurar sincronización
	await get_tree().process_frame  
	await get_tree().process_frame  

	# 🔹 Obtener datos actualizados después de guardar progreso
	var save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado.", "RESULT_MANAGER")
		return

	var selected_savegame_key = SAVE.get_current_savegame_key()
	var current_phase = SAVE.get_phase()

	# 🔹 Leer correctamente los puntos guardados en `SAVE.game_data`
	var total_points = SAVE.game_data[selected_savegame_key].get("save_points", 0)

	# 🔹 Obtener los puntos ganados en la última fase desde `LEVEL_MANAGER`
	var previous_phase_points = LEVEL_MANAGER.previous_phase_points

	# 🔹 Mostrar la interfaz con la información correcta
	if resultado == "victoria":
		resultado_label.text = "¡VICTORIA!\n\n" + \
			"Fase siguiente: %d\n" % (current_phase) + \
			"Enemigos en la siguiente fase: %d\n" % LEVEL_MANAGER.get_enemy_count_for_phase() + \
			"Puntos obtenidos en esta fase: %d\n" % previous_phase_points + \
			"Puntos totales acumulados: %d" % total_points
	else:
		resultado_label.text = "GAME OVER\n\n" + \
			"Fase alcanzada: %d\n" % current_phase + \
			"Puntos obtenidos en esta fase: %d\n" % previous_phase_points + \
			"Puntos totales acumulados: %d" % total_points

	# 🔹 Log de depuración para confirmar los datos mostrados
	SYSLOG.debug_log("Resultado mostrado: %s | Puntos Fase: %d | Puntos Totales: %d" % 
		[resultado, previous_phase_points, total_points], "RESULT_MANAGER")

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
