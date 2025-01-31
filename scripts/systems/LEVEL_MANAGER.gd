# ==========================
# LEVEL_MANAGER.gd
# ==========================
class_name LEVEL_MANAGER_c extends Node

# ==========================
# Signals
# ==========================
signal phase_updated(new_phase: int)

# ==========================
# Variables Internas
# ==========================
var player: CharacterBody2D
var phase: int = 1
var save_data: Dictionary = {}
var points: int = 0  # 🔹 Puntos acumulados en el nivel
var previous_phase_points: int = 0  # 🔹 Puntos obtenidos en la última fase
@export var enemy_growth_percentage: float = 1.1  # 🔹 Incremento del 10% por defecto

@onready var level_hud = get_tree().get_first_node_in_group("level_hud")

# ==========================
# Inicialización del Nivel
# ==========================
func initialize_level():
	phase = SAVE.get_phase()
	SYSLOG.debug_log("LEVEL_MANAGER: Inicializando nivel en fase %d.", "LEVEL_MANAGER")

	# 🔹 Antes de resetear `points`, guardar los puntos previos para mostrar en `resultado.gd`
	previous_phase_points = points  

	# 🔹 Resetear puntos SOLO al inicio de cada nivel
	points = 0  

# 🔹 Notificar al HUD que reinicie la visualización de puntos de fase
	if level_hud:
		level_hud.reiniciar_puntos_fase()

	SYSLOG.debug_log("Fase iniciada - Puntos previos: %d | Puntos actuales: %d" % [previous_phase_points, points], "LEVEL_MANAGER")

	# 🔹 Obtener el total de puntos guardados antes de iniciar la fase
	var selected_savegame_key = SAVE.get_current_savegame_key()
	if selected_savegame_key != "":
		points = SAVE.game_data[selected_savegame_key].get("save_points", 0)

	SYSLOG.debug_log("Puntos inicializados: %d | Puntos anteriores: %d" % [points, previous_phase_points], "LEVEL_MANAGER")

	# 🔹 Verificar si el jugador sigue en la escena antes de instanciar uno nuevo
	var jugadores = get_tree().get_nodes_in_group("pj")
	if jugadores.size() > 0:
		player = jugadores[0]
		SYSLOG.debug_log("Se reutiliza el jugador existente.", "LEVEL_MANAGER")
	else:
		player = PLAYER_MANAGER.load_player()
		if player:
			var nivel = get_tree().get_nodes_in_group("nivel")[0] if get_tree().get_nodes_in_group("nivel").size() > 0 else null
			if nivel:
				nivel.add_child(player)
				player.global_position = Vector2(300, 300)
				player.add_to_group("pj")
				SYSLOG.debug_log("Jugador añadido correctamente.", "LEVEL_MANAGER")

	# 🔹 Conectar señal de muerte del jugador
	if not player.is_connected("pj_muerto", Callable(self, "_on_pj_muerto")):
		player.connect("pj_muerto", Callable(self, "_on_pj_muerto"))

	# 🔹 Configurar y generar enemigos
	ENEMY_SPAWNER.configure_spawner()
	ENEMY_SPAWNER.spawn_enemies()

	# 🔹 Conectar la señal de victoria
	if not ENEMY_SPAWNER.is_connected("all_enemies_defeated", Callable(self, "_on_all_enemies_defeated")):
		ENEMY_SPAWNER.connect("all_enemies_defeated", Callable(self, "_on_all_enemies_defeated"))

	# 🔹 Conectar la señal de muerte de cada enemigo
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_connected("enemy_defeated", Callable(self, "_on_enemy_defeated")):
			enemy.connect("enemy_defeated", Callable(self, "_on_enemy_defeated"))

	# ✅ Ahora sí actualizamos el HUD, pero con un pequeño delay
	await get_tree().process_frame  
	_actualizar_hud()
	emit_signal("phase_updated", phase)
	level_hud.actualizar_phase(phase)
	SYSLOG.debug_log("Fase iniciada correctamente: %d" % phase, "LEVEL_MANAGER")

# ==========================
# Incrementar Puntos Durante el Nivel
# ==========================
func incrementar_puntos(amount: int) -> void:
	points += amount
	_actualizar_hud()

	# 🔹 Guardar puntos en tiempo real
	guardar_puntos()

	SYSLOG.debug_log("Puntos incrementados en %d. Total: %d" % [amount, points], "LEVEL_MANAGER")

# ==========================
# Guardar Puntos en Tiempo Real
# ==========================
func guardar_puntos() -> void:
	var selected_savegame_key = SAVE.get_current_savegame_key()
	if selected_savegame_key == "":
		SYSLOG.error_log("No se pudo obtener savegame.", "LEVEL_MANAGER")
		return

	# 🔹 Obtener los puntos actuales almacenados en `save_points`
	var global_points = SAVE.game_data[selected_savegame_key].get("save_points", 0)

	# 🔹 Calcular la diferencia de puntos obtenidos en esta fase
	var diferencia_puntos = points - global_points

	# 🔹 Evitar sumas erróneas (asegurar que solo sumamos la diferencia positiva)
	if diferencia_puntos > 0:
		SAVE.game_data[selected_savegame_key]["save_points"] += diferencia_puntos
		SYSLOG.debug_log("Puntos guardados correctamente - Total en save: %d (incremento de %d)" % 
			[SAVE.game_data[selected_savegame_key]["save_points"], diferencia_puntos], "LEVEL_MANAGER")
	else:
		SYSLOG.debug_log("No se detectaron nuevos puntos para guardar.", "LEVEL_MANAGER")

	# 🔹 Guardar los datos actualizados
	SAVE.save_game()

# ==========================
# Manejar la Muerte de un Enemigo
# ==========================
func _on_enemy_defeated(enemy_points: int) -> void:
	if typeof(enemy_points) != TYPE_INT:
		SYSLOG.error_log("ERROR: Se recibió un valor incorrecto en _on_enemy_defeated. Tipo recibido: %s" % typeof(enemy_points), "LEVEL_MANAGER")
		return  # 🔹 Evitar errores en caso de tipo incorrecto

	# 🔹 Sumar correctamente los puntos del enemigo
	points += enemy_points

	# 🔹 Guardar puntos correctamente sin reescribir valores
	guardar_puntos()

	# 🔹 Actualizar el HUD en tiempo real
	_actualizar_hud()

	SYSLOG.debug_log("Enemigo derrotado. Puntos sumados: %d. Total actual: %d" % [enemy_points, points], "LEVEL_MANAGER")

	# 🔹 Verificar si quedan enemigos en la escena
	var remaining_enemies = get_tree().get_nodes_in_group("enemy")
	if remaining_enemies.size() == 0:
		_on_all_enemies_defeated()

# ==========================
# Manejo del Resultado del Nivel
# ==========================
func manejar_resultado(resultado: String):
	SYSLOG.debug_log("LEVEL_MANAGER: Procesando resultado %s.", "LEVEL_MANAGER")

	# 🔹 Guardar progreso antes de pausar el juego (evita duplicaciones)
	if resultado == "victoria":
		guardar_progreso(resultado)

	# 🔹 Esperar un frame antes de pausar para asegurar que los datos se escribieron
	await get_tree().process_frame  

	get_tree().paused = true

	var resultado_nodo = get_tree().get_nodes_in_group("resultado")
	if resultado_nodo.size() > 0:
		resultado_nodo[0].mostrar_resultado(resultado)
	else:
		SYSLOG.error_log("No se encontró el nodo de resultado en la escena.", "LEVEL_MANAGER")

# ==========================
# Guardar Progreso con Puntos Actualizados
# ==========================
func guardar_progreso(resultado: String):
	var selected_savegame_key = SAVE.get_current_savegame_key()
	var selected_pj_key = SAVE.get_current_pj_key()

	if selected_savegame_key == "" or selected_pj_key == "":
		SYSLOG.error_log("No se pudo obtener el savegame actual.", "LEVEL_MANAGER")
		return

	# 🔹 Guardar los puntos en tiempo real antes de actualizar la fase
	guardar_puntos()

	# 🔹 Si el jugador ganó, avanzar a la siguiente fase
	if resultado == "victoria":
		SAVE.game_data[selected_savegame_key][selected_pj_key]["phase"] += 1
		phase = SAVE.game_data[selected_savegame_key][selected_pj_key]["phase"]

	# 🔹 Guardar los datos actualizados y esperar 1 frame para asegurar que los cambios estén escritos
	SAVE.save_game()
	await get_tree().process_frame  

	SYSLOG.debug_log("Fase guardada correctamente: %d | Puntos Totales: %d" % 
		[phase, SAVE.game_data[selected_savegame_key]["save_points"]], "LEVEL_MANAGER")

# ==========================
# Reinicio de Nivel
# ==========================
func reiniciar_nivel():
	SYSLOG.debug_log("LEVEL_MANAGER: Reiniciando nivel.", "LEVEL_MANAGER")

	# 🔹 Guardar progreso antes de reiniciar
	guardar_progreso("game_over")

	# 🔹 Ocultar el menú antes de reiniciar
	var resultado_nodo = get_tree().get_nodes_in_group("resultado")
	if resultado_nodo.size() > 0:
		resultado_nodo[0].canvas_layer.visible = false

	# 🔹 Desconectar señales activas
	if player and player.is_connected("pj_muerto", Callable(self, "_on_pj_muerto")):
		player.disconnect("pj_muerto", Callable(self, "_on_pj_muerto"))

	if ENEMY_SPAWNER.is_connected("all_enemies_defeated", Callable(self, "_on_all_enemies_defeated")):
		ENEMY_SPAWNER.disconnect("all_enemies_defeated", Callable(self, "_on_all_enemies_defeated"))

	# 🔹 Limpiar la escena antes de regenerar
	get_tree().paused = false  
	limpiar_escena()
	await get_tree().process_frame  

	# 🔹 Asegurar que la referencia del jugador sea nula antes de reinstanciar
	player = null  

	# 🔹 Reinstanciar jugador y enemigos tras la limpieza
	initialize_level()

# ==========================
# Reiniciar Desde la Fase 1
# ==========================
func reiniciar_desde_phase_1():
	SYSLOG.debug_log("LEVEL_MANAGER: Reiniciando desde fase 1.", "LEVEL_MANAGER")

	# 🔹 Guardar progreso antes de resetear
	guardar_progreso("game_over")  # 🔹 SE AÑADE ESTO

	var selected_savegame_key = SAVE.get_current_savegame_key()
	var selected_pj_key = SAVE.get_current_pj_key()

	if selected_savegame_key == "" or selected_pj_key == "":
		SYSLOG.error_log("No se pudo obtener el savegame actual.", "LEVEL_MANAGER")
		return

	# 🔹 Establecer la fase en 1 y guardar el progreso
	SAVE.game_data[selected_savegame_key][selected_pj_key]["phase"] = 1
	SAVE.save_game()
	await get_tree().process_frame  

	reiniciar_nivel()

# ==========================
# Obtener el Número de Enemigos para la Phase Actual
# ==========================
func get_enemy_count_for_phase() -> int:
	var phase_enemy_count = [1, 2, 4, 6, 10, 14]

	if phase <= phase_enemy_count.size():
		return phase_enemy_count[phase - 1]

	var last_enemy_count = phase_enemy_count[-1]
	var new_enemy_count = int(last_enemy_count * enemy_growth_percentage)

	SYSLOG.debug_log("Fase %d -> Generando %d enemigos." % [phase, new_enemy_count], "LEVEL_MANAGER")
	return new_enemy_count

# ==========================
# Limpiar la Escena Antes de Recargar
# ==========================
func limpiar_escena():
	SYSLOG.debug_log("LEVEL_MANAGER: Limpiando la escena antes de recargar.", "LEVEL_MANAGER")

	# 🔹 Eliminar el jugador anterior si sigue en escena
	for pj in get_tree().get_nodes_in_group("pj"):
		if pj:
			pj.queue_free()
			SYSLOG.debug_log("Jugador eliminado correctamente.", "LEVEL_MANAGER")

	# 🔹 Eliminar enemigos
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy:
			enemy.queue_free()

	# 🔹 Desactivar proyectiles en lugar de eliminarlos
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if projectile:
			COMBAT.deactivate_projectile(projectile)

	# 🔹 Reiniciar puntos del HUD
	points = 0
	_actualizar_hud()

	# 🔹 Esperar un frame extra para asegurar que los nodos sean eliminados
	await get_tree().process_frame
	await get_tree().process_frame

	SYSLOG.debug_log("LEVEL_MANAGER: Escena limpiada correctamente.", "LEVEL_MANAGER")
	
# ==========================
# Manejo de la Victoria
# ==========================
func _on_all_enemies_defeated():
	SYSLOG.debug_log("Todos los enemigos han sido derrotados. Victoria activada.", "LEVEL_MANAGER")
	manejar_resultado("victoria")

# ==========================
# Manejo del Game Over
# ==========================
func _on_pj_muerto():
	SYSLOG.debug_log("PJ derrotado. GAME OVER activado.", "LEVEL_MANAGER")
	manejar_resultado("game_over")

# ==========================
# Volver al Menú Principal
# ==========================
func volver_a_menu():
	SYSLOG.debug_log("LEVEL_MANAGER: Volviendo al menú principal.", "LEVEL_MANAGER")

	# 🔹 Guardar progreso antes de salir
	guardar_progreso("game_over")  # 🔹 SE AÑADE ESTO

	# 🔹 Limpiar la escena antes de salir
	limpiar_escena()
	await get_tree().process_frame
	await get_tree().process_frame  # 🔹 Segundo frame extra para evitar residuos

	# 🔹 Despausar el juego antes de cambiar de escena
	get_tree().paused = false  
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")

func _actualizar_hud() -> void:
	if not level_hud or not is_instance_valid(level_hud):
		level_hud = get_tree().get_first_node_in_group("level_hud")  # 🔹 Buscar el HUD manualmente
	
	if level_hud:
		level_hud.actualizar_puntos(points)
#		level_hud.actualizar_phase(phase)
#		SYSLOG.debug_log("HUD actualizado correctamente - Phase: %d, Puntos: %d" % [phase, points], "LEVEL_MANAGER")
	else:
		SYSLOG.error_log("HUD sigue sin encontrarse. No se puede actualizar.", "LEVEL_MANAGER")
