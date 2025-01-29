extends Area2D
class_name class_nivel1

# ==========================
# Referencias de Escenas
# ==========================
@export var enemy_scene: PackedScene
@export var resultado_scene: PackedScene

# ==========================
# Variables Internas
# ==========================
var debug_visible: bool = false  # Estado de visibilidad de las etiquetas debug
var player: CharacterBody2D
var save_data: Dictionary = {}
var phase: int = 1
var points: int = 0
@onready var limites = $limites  # Nodo de límites para el jugador
@onready var enemy_spawn = $enemy_spawn  # Nodo de área de spawn de enemigos

# ==========================
# Señales
# ==========================
signal victoria
signal game_over

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	SYSLOG.debug_log("Nivel inicializado.", "NIVEL")
	_verificar_zonas()
	_cargar_datos_guardado()
	_inicializar_phase_y_points()  # Añadida inicialización
	_cargar_personaje()
	_cargar_enemigos()


# ==========================
# Verificación de Nodos
# ==========================
func _verificar_zonas() -> void:
	if not limites or not limites.shape:
		SYSLOG.error_log("El nodo 'limites' no está configurado o no tiene forma.", "NIVEL")
	if not enemy_spawn or not enemy_spawn.shape:
		SYSLOG.error_log("El nodo 'enemy_spawn' no está configurado o no tiene forma.", "NIVEL")

# ==========================
# Cargar Datos de Guardado
# ==========================
func _cargar_datos_guardado() -> void:
	save_data = SAVE.load_game()
	if save_data.is_empty():
		SYSLOG.error_log("No se pudo cargar el archivo de guardado o está vacío.", "NIVEL")
		return
	SYSLOG.debug_log("Datos de guardado cargados: %s" % save_data, "NIVEL")

# ==========================
# Carga de Personaje con Estadísticas
# ==========================
func _cargar_personaje() -> void:
	# Identificar el savegame y personaje seleccionados
	var selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	var pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)
	var pj_stats = save_data[selected_savegame_key][pj_selected_key]

	# Validar la existencia de la escena del personaje
	var pj_scene_path = "res://scenes/pj/%s.tscn" % pj_selected_key
	if not ResourceLoader.exists(pj_scene_path):
		SYSLOG.error_log("La escena del personaje '%s' no existe." % pj_selected_key, "NIVEL")
		return

	# Instanciar personaje
	player = load(pj_scene_path).instantiate()
	if not player:
		SYSLOG.error_log("No se pudo instanciar el personaje.", "NIVEL")
		return
	add_child(player)

	# Verificar que el nodo tiene un hijo con `AnimatedSprite2D` (u otro nodo necesario)
	var sprite = player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		SYSLOG.error_log("El personaje no tiene un nodo 'AnimatedSprite2D'.", "NIVEL")
		return

	# Cargar estadísticas base del personaje desde su script
	var base_stats = {
		"health": player.health,
		"damage": player.damage,
		"defense": player.defense,
		"energy": player.energy,
		"speed": player.speed,
		"attack_speed": player.attack_speed,
		"luck": player.luck,
		"crit": player.crit,
		"precision": player.precision,
		"dodge": player.dodge
	}

	# Aplicar modificaciones desde el archivo de guardado
	player.health = base_stats["health"] + pj_stats["mod_health"]
	player.damage = base_stats["damage"] + pj_stats["mod_damage"]
	player.defense = base_stats["defense"] + pj_stats["mod_defense"]
	player.energy = base_stats["energy"]
	player.speed = base_stats["speed"]
	player.attack_speed = base_stats["attack_speed"] + pj_stats["mod_attack_speed"]
	player.luck = base_stats["luck"] + pj_stats["mod_luck"]
	player.crit = base_stats["crit"] + pj_stats["mod_crit"]
	player.precision = base_stats["precision"] + pj_stats["mod_precision"]
	player.dodge = base_stats["dodge"] + pj_stats["mod_dodge"]

	# Pasar el ataque seleccionado al personaje
	var attack_value = pj_stats.get("attack_value", [])
	if attack_value.size() > 0:
		var attack_name = attack_value[0]
		player.projectile_scene = load("res://scenes/attack/%s.tscn" % attack_name)  # Asignar el ataque como escena cargada
		SYSLOG.debug_log("Ataque '%s' configurado para el personaje." % attack_name, "NIVEL")
	else:
		SYSLOG.error_log("No se encontró un valor de ataque en el archivo de guardado.", "NIVEL")

	# Posicionar el personaje en el nivel
	player.global_position = Vector2(300, 300)
	player.add_to_group("pj")

	# Asegurar que el sprite está visible y configurado
	sprite.visible = true
	sprite.play("idle")  # Configura la animación inicial si existe

	# Debug de estadísticas cargadas
	SYSLOG.debug_log("Personaje cargado con estadísticas finales: %s" % {
		"health": player.health,
		"damage": player.damage,
		"defense": player.defense,
		"energy": player.energy,
		"speed": player.speed,
		"attack_speed": player.attack_speed,
		"luck": player.luck,
		"crit": player.crit,
		"precision": player.precision,
		"dodge": player.dodge
	}, "NIVEL")
	
	SYSLOG.debug_log("Jerarquía de nodos tras instanciar al personaje:", "NIVEL")
	for child in get_children():
		SYSLOG.debug_log("Nodo hijo: %s" % child.name, "NIVEL")

# ==========================
# Restricción del Movimiento del Jugador
# ==========================
func _physics_process(delta: float) -> void:
	if player and limites:
		_restringir_movimiento()
	_actualizar_debug_labels()
	_verificar_estado_nivel()

func _restringir_movimiento() -> void:
	if not player or not limites or not limites.shape:
		SYSLOG.error_log("No se puede restringir movimiento: Nodo 'limites' o 'player' no válido.", "NIVEL")
		return
	
	if limites.shape is RectangleShape2D:
		var extents = limites.shape.extents
		var bounds = Rect2(limites.global_position - extents, extents * 2)

		var clamped_position = Vector2(
			clamp(player.global_position.x, bounds.position.x, bounds.position.x + bounds.size.x),
			clamp(player.global_position.y, bounds.position.y, bounds.position.y + bounds.size.y)
		)

		# Solo actualizar la posición si es diferente a la actual
		if player.global_position != clamped_position:
			SYSLOG.debug_log("Reubicando al jugador dentro de los límites: %s" % clamped_position, "NIVEL")
			player.global_position = clamped_position

# ==========================
# Generar Posición del Enemigo
# ==========================
func _generar_posicion_enemigo() -> Vector2:
	if enemy_spawn.shape is RectangleShape2D:
		var extents = enemy_spawn.shape.extents
		var bounds = Rect2(enemy_spawn.global_position - extents, extents * 2)
		return Vector2(
			randi_range(bounds.position.x, bounds.position.x + bounds.size.x),
			randi_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
	return Vector2.ZERO

# ==========================
# Gestión de Enemigos
# ==========================
func _cargar_enemigos() -> void:
	if not enemy_scene:
		SYSLOG.error_log("La escena del enemigo no está configurada.", "NIVEL")
		return

	for i in range(COMBAT.enemy_count):
		var enemy = enemy_scene.instantiate()
		if not enemy:
			SYSLOG.error_log("No se pudo instanciar el enemigo %d." % i, "NIVEL")
			continue

		enemy.add_to_group("enemy")
		enemy.connect("enemy_defeated", Callable(self, "_incrementar_points"))  # Conexión añadida

		var health_bar = enemy.get_node_or_null("health_bar")
		if health_bar:
			health_bar.max_value = enemy.health
			health_bar.value = enemy.health

		var enemy_position = _generar_posicion_enemigo()
		enemy.global_position = enemy_position
		add_child(enemy)

		SYSLOG.debug_log("Enemigo instanciado en posición %s con salud: %d." % [enemy_position, enemy.health], "NIVEL")


# ==========================
# Verificar Estado del Nivel
# ==========================
func _verificar_estado_nivel() -> void:
	if player.health <= 0:
		player.health = 0
#		SYSLOG.debug_log("Game Over", "NIVEL")
		_temporizador_escena_resultado("game_over")
	elif get_tree().get_nodes_in_group("enemy").size() == 0:
#		SYSLOG.debug_log("Victoria alcanzada.", "NIVEL")
		_temporizador_escena_resultado("victoria")

func _temporizador_escena_resultado(resultado: String) -> void:
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "_cargar_resultado_scene").bind(resultado))
	timer.start()

func _cargar_resultado_scene(resultado: String) -> void:
	SYSLOG.debug_log("Cargando escena de resultado: %s..." % resultado, "NIVEL")
	_guardar_progreso(resultado)  # Guardar progreso antes de cargar la escena de resultados
	get_tree().paused = true

	if not resultado_scene:
		SYSLOG.error_log("La escena de resultado no está configurada.", "NIVEL")
		return

	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	var resultado_instance = resultado_scene.instantiate()
	canvas_layer.add_child(resultado_instance)

	# Obtener datos del progreso
	var selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	var pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)
	var current_phase = phase
	var next_phase = current_phase if resultado == "game_over" else current_phase + 1
	var total_points = save_data[selected_savegame_key][pj_selected_key]["points"]
	var enemies_next_level = next_phase * 2

	# Actualizar contenido de la etiqueta del resultado
	var resultado_label = resultado_instance.get_node("CenterContainer/VBoxContainer/resultado")
	if resultado == "victoria":
		resultado_label.text = "¡VICTORIA!\n" + \
			"Siguiente fase: %d\n" % next_phase + \
			"Puntos ganados: %d\n" % points + \
			"Puntos totales: %d\n" % total_points + \
			"Enemigos próximo nivel: %d" % enemies_next_level
	else:
		resultado_label.text = "GAME OVER\n" + \
			"Fase alcanzada: %d\n" % current_phase + \
			"Puntos ganados: %d\n" % points + \
			"Puntos totales: %d\n" % total_points + \
			"Enemigos próximo nivel: %d" % enemies_next_level

	# Configurar botones
	resultado_instance.get_node("CenterContainer/VBoxContainer/HBoxContainer/continuar").connect("pressed", Callable(self, "_reiniciar_nivel_con_incremento" if resultado == "victoria" else "_reiniciar_nivel_sin_incremento"))
	resultado_instance.get_node("CenterContainer/VBoxContainer/HBoxContainer/terminar").connect("pressed", Callable(self, "_volver_a_menu"))
	resultado_instance.get_node("CenterContainer/VBoxContainer/HBoxContainer/reset").connect("pressed", Callable(self, "_reiniciar_desde_phase_1"))

	SYSLOG.debug_log("Menú de resultado cargado sobre la escena del nivel.", "NIVEL")

# ==========================
# Gestión de Reinicios y Limpieza
# ==========================
func _reiniciar_nivel_con_incremento() -> void:
	#_limpiar_proyectiles()
	_limpiar_escena()
	get_tree().paused = false
	COMBAT.enemy_count *= 2
	SYSLOG.debug_log("Reiniciando nivel con %d enemigos..." % COMBAT.enemy_count, "NIVEL")
	get_tree().reload_current_scene()

func _reiniciar_nivel_sin_incremento() -> void:
	_limpiar_escena()
	#_limpiar_proyectiles()
	get_tree().paused = false
	SYSLOG.debug_log("Reiniciando nivel con el mismo número de enemigos.", "NIVEL")
	get_tree().reload_current_scene()
	
func _reiniciar_desde_phase_1() -> void:
	SYSLOG.debug_log("Reiniciando nivel desde phase 1.", "NIVEL")

	# Restablecer la phase a 1 en el savegame
	var selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	var pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)
	
	save_data[selected_savegame_key][pj_selected_key]["phase"] = 1
	
	# Guardar los cambios
	SAVE.save_game()
	
	# Reiniciar enemigos y nivel
	COMBAT.enemy_count = 2  # En phase 1, el número inicial de enemigos
	_limpiar_escena()
	get_tree().reload_current_scene()
	

func _volver_a_menu() -> void:
	_limpiar_escena()
	#_limpiar_proyectiles()
	SYSLOG.debug_log("Volviendo al menú principal.", "NIVEL")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/pregame.tscn")

#func _limpiar_proyectiles() -> void:
	#if not COMBAT.projectile_pool:
		#SYSLOG.error_log("No se pudo limpiar proyectiles: pool no inicializada.", "NIVEL")
		#return
#
	#for projectile in COMBAT.projectile_pool:
		#if projectile and not projectile.is_queued_for_deletion():
			#projectile.queue_free()
#
	#SYSLOG.debug_log("Proyectiles eliminados correctamente.", "NIVEL")

# ==========================
# Actualizar Debug Labels
# ==========================
func _actualizar_debug_labels() -> void:
	var pj_label = get_node_or_null("pj_1")
	if pj_label:
		pj_label.visible = debug_visible
		if player:
			pj_label.text = "DEBUG Pj_1:\n" + \
				"health: %d\n" % player.health + \
				"damage: %d\n" % player.damage + \
				"speed: %d\n" % player.speed + \
				"attack_speed: %.2f\n" % player.attack_speed + \
				"defense: %d\n" % player.defense + \
				"energy: %d" % player.energy

	var enemy_label = get_node_or_null("enemy_1")
	var enemy = get_tree().get_nodes_in_group("enemy")[0] if get_tree().get_nodes_in_group("enemy").size() > 0 else null
	if enemy_label:
		enemy_label.visible = debug_visible
		if enemy:
			enemy_label.text = "DEBUG enemy_1:\n" + \
				"health: %d\n" % enemy.health + \
				"damage: %d\n" % enemy.damage + \
				"speed: %d\n" % enemy.speed + \
				"attack_speed: %.2f\n" % enemy.attack_speed + \
				"defense: %d" % enemy.defense
# ==========================
# Gestión de Entrada
# ==========================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		debug_visible = not debug_visible  # Alternar el estado de visibilidad
		_actualizar_debug_labels()  # Aplicar la visibilidad
		SYSLOG.debug_log("Visibilidad de debug alternada a: %s" % debug_visible, "NIVEL")

# ==========================
# Inicializar Phase y Points
# ==========================
func _inicializar_phase_y_points() -> void:
	var selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	var pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)
	
	# Inicializar variables
	phase = save_data[selected_savegame_key][pj_selected_key].get("phase", 1)
	points = 0  # Reiniciar los puntos al inicio del nivel o fase
	
	# Actualizar etiquetas
	_actualizar_label_phase()
	_actualizar_label_points()
	
	# Actualizar enemigos según la fase
	COMBAT.enemy_count = phase * 2
	SYSLOG.debug_log("Fase inicializada: %d, Puntos reiniciados a 0." % phase, "NIVEL")


# ==========================
# Incrementar Points
# ==========================
func _incrementar_points() -> void:
	points += 1
	_actualizar_label_points()
	SYSLOG.debug_log("Puntos incrementados en esta fase: %d." % points, "NIVEL")

	
# ==========================
# Guardar Progreso
# ==========================
func _guardar_progreso(resultado: String) -> void:
	var selected_savegame_key = "savegame%d" % save_data.get("savegame_value", 1)
	var pj_selected_key = "pj_%d" % save_data[selected_savegame_key].get("pj_value", 1)

	# Obtener datos actuales
	var current_phase = phase
#	var current_total_points = save_data[selected_savegame_key][pj_selected_key].get("points", 0)
	var max_phase = save_data[selected_savegame_key][pj_selected_key].get("max_phase", 1)
	var global_points = save_data[selected_savegame_key].get("save_points", 0)

	# Actualizar talentos individuales (points del personaje)
	#save_data[selected_savegame_key][pj_selected_key]["points"] = current_total_points + points

	# Actualizar puntos globales (save_points)
	save_data[selected_savegame_key]["save_points"] = global_points + points

	# Actualizar fase máxima si corresponde
	if current_phase > max_phase:
		save_data[selected_savegame_key][pj_selected_key]["max_phase"] = current_phase
		SYSLOG.debug_log("Actualizando max_phase a %d para %s." % [current_phase, pj_selected_key], "NIVEL")

	# Si es una victoria, avanzar a la siguiente fase
	if resultado == "victoria":
		save_data[selected_savegame_key][pj_selected_key]["phase"] = current_phase + 1

	# Guardar los cambios en el archivo de guardado
	SAVE.save_game()
	SYSLOG.debug_log("Progreso guardado: Save Points: %d, Fase Guardada: %d, Máxima Fase: %d." % 
		[save_data[selected_savegame_key]["save_points"], 
#		 save_data[selected_savegame_key][pj_selected_key]["points"], 
		 save_data[selected_savegame_key][pj_selected_key]["phase"], 
		 save_data[selected_savegame_key][pj_selected_key]["max_phase"]], "NIVEL")




# ==========================
# Actualizar Etiqueta Phase
# ==========================
func _actualizar_label_phase() -> void:
	var label_phase = $CanvasLayer/phase
	if label_phase:
		label_phase.text = "FASE: %d" % phase
		SYSLOG.debug_log("Etiqueta de fase actualizada: %d." % phase, "NIVEL")
	else:
		SYSLOG.error_log("No se encontró la etiqueta 'phase'.", "NIVEL")

# ==========================
# Actualizar Etiqueta Points
# ==========================
func _actualizar_label_points() -> void:
	var label_points = $CanvasLayer/points
	if label_points:
		label_points.text = "Puntos: %d" % points
		SYSLOG.debug_log("Etiqueta de puntos actualizada: %d." % points, "NIVEL")
	else:
		SYSLOG.error_log("No se encontró la etiqueta 'points'.", "NIVEL")
		
func _limpiar_escena() -> void:
	# Eliminar al jugador si existe
	if player and not player.is_queued_for_deletion():
		SYSLOG.debug_log("Eliminando al jugador de la escena.", "NIVEL")
		player.queue_free()
		player = null
	
	# Eliminar todos los enemigos
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy and not enemy.is_queued_for_deletion():
			SYSLOG.debug_log("Eliminando enemigo: %s" % enemy.name, "NIVEL")
			enemy.queue_free()

	# Eliminar proyectiles
	if not COMBAT.projectile_pool:
		SYSLOG.error_log("No se pudo limpiar proyectiles: pool no inicializada.", "NIVEL")
		return
	for projectile in COMBAT.projectile_pool:
		if projectile and not projectile.is_queued_for_deletion():
			SYSLOG.debug_log("Eliminando proyectil de la pool.", "NIVEL")
			projectile.queue_free()

	SYSLOG.debug_log("Escena limpiada correctamente.", "NIVEL")
