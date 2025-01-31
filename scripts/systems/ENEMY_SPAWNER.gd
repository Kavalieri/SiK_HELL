# ==========================
# ENEMY_SPAWNER.gd
# ==========================
class_name ENEMY_SPAWNER_c extends Node

# ==========================
# Señales
# ==========================
signal all_enemies_defeated

# ==========================
# Propiedades Exportadas
# ==========================
@export var enemy_scenes: Dictionary = {
	"basic": preload("res://scenes/enemies/enemy_1.tscn"),
	"fast": preload("res://scenes/enemies/enemy_2.tscn"),
	"strong": preload("res://scenes/enemies/enemy_1.tscn")
}
@export var enemy_distribution: Dictionary = {
	1: ["basic"],
	2: ["basic", "fast"],
	3: ["basic", "fast", "strong"]
}

# ==========================
# Variables Internas
# ==========================
var enemies_alive: int = 0  # 🔹 Contador de enemigos vivos
var enemies = []
var phase: int = 1  # Se actualizará desde `nivel_X.gd`
var enemy_spawn_areas = []  # Lista de todas las zonas de spawn
var save_data: Dictionary = {}

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	SYSLOG.debug_log("ENEMY_SPAWNER inicializado.", "ENEMY_SPAWNER")

# ==========================
# Configuración de Enemigos por Nivel
# ==========================
func configure_spawner():
	phase = SAVE.get_phase()
	SYSLOG.debug_log("Configurando spawner para fase: %d" % phase, "ENEMY_SPAWNER")

	# 🔹 Ajustar la distribución de enemigos según la fase actual
	if not enemy_distribution.has(phase):
		var max_defined_phase = enemy_distribution.keys().max()
		SYSLOG.debug_log("No hay configuración específica para la fase %d. Usando la fase %d en su lugar." % [phase, max_defined_phase], "ENEMY_SPAWNER")
		enemy_distribution[phase] = enemy_distribution[max_defined_phase]

# ==========================
# Generación de Enemigos Basada en `phase`
# ==========================
func spawn_enemies():
	enemies.clear()
	enemies_alive = 0  # 🔹 Resetear contador

	# 🔹 Verificar y detectar zonas de spawn antes de generar enemigos
	_detect_spawn_areas()

	if enemy_spawn_areas.is_empty():
		SYSLOG.error_log("No se pueden generar enemigos porque no hay áreas de spawn.", "ENEMY_SPAWNER")
		return

	var max_enemies = LEVEL_MANAGER.get_enemy_count_for_phase()
	SYSLOG.debug_log("Generando %d enemigos..." % max_enemies, "ENEMY_SPAWNER")

	var available_enemies = _get_enemy_distribution_for_phase(phase)
	for i in range(max_enemies):
		var enemy_type = available_enemies.pick_random()
		var enemy = enemy_scenes[enemy_type].instantiate()
		enemy.global_position = _generar_posicion_enemigo()
		get_tree().current_scene.add_child(enemy)
		enemies.append(enemy)

		# 🔹 Conectar señal de muerte del enemigo
		if not enemy.is_connected("enemy_defeated", Callable(self, "_on_enemy_defeated")):
			enemy.connect("enemy_defeated", Callable(self, "_on_enemy_defeated"))

		# 🔹 Aumentar contador de enemigos vivos
		enemies_alive += 1

	SYSLOG.debug_log("Enemigos generados correctamente. Total enemigos: %d" % enemies_alive, "ENEMY_SPAWNER")

# ==========================
# Buscar las áreas de spawn en tiempo de ejecución
# ==========================
func _detect_spawn_areas():
	enemy_spawn_areas.clear()  # 🔹 Limpiar la lista antes de buscar nuevas áreas

	var nivel_actual = get_tree().get_first_node_in_group("nivel")
	if not nivel_actual:
		SYSLOG.error_log("No se encontró el nodo de nivel en la escena. No se pueden generar enemigos.", "ENEMY_SPAWNER")
		return

	for node in nivel_actual.get_children():
		if node is Area2D and node.name.begins_with("enemy_spawn_"):
			enemy_spawn_areas.append(node)

	if enemy_spawn_areas.is_empty():
		SYSLOG.error_log("No se encontraron áreas de spawn en la escena.", "ENEMY_SPAWNER")
	else:
		_log_spawn_areas()

# ==========================
# Registrar las áreas de spawn encontradas
# ==========================
func _log_spawn_areas():
	var area_names_list = enemy_spawn_areas.map(func(area): return area.name)
	var area_names_string = ", ".join(area_names_list)
	SYSLOG.debug_log("Se encontraron %d áreas de spawn: [%s]" % [enemy_spawn_areas.size(), area_names_string], "ENEMY_SPAWNER")

# ==========================
# Generar Posición Aleatoria de Enemigos en Múltiples Áreas sin `shape`
# ==========================
func _generar_posicion_enemigo() -> Vector2:
	if enemy_spawn_areas.is_empty():
		SYSLOG.error_log("No hay áreas de spawn disponibles para generar enemigos.", "ENEMY_SPAWNER")
		return Vector2.ZERO

	# Seleccionar una zona de spawn aleatoria de la lista disponible
	var selected_spawn_area = enemy_spawn_areas.pick_random()

	# 🔹 Verificar que el área de spawn sigue siendo válida
	if not is_instance_valid(selected_spawn_area):
		SYSLOG.error_log("El área de spawn seleccionada ya no existe.", "ENEMY_SPAWNER")
		return Vector2.ZERO

	# Definir un radio de dispersión aleatoria alrededor del punto de spawn
	var dispersion_range = 50

	var enemy_position = selected_spawn_area.global_position + Vector2(
		randi_range(-dispersion_range, dispersion_range),
		randi_range(-dispersion_range, dispersion_range)
	)

	SYSLOG.debug_log("Enemigo generado en %s en la zona %s." % [enemy_position, selected_spawn_area.name], "ENEMY_SPAWNER")
	return enemy_position

# ==========================
# Manejo de Enemigos Derrotados
# ==========================
func _on_enemy_defeated(enemy_points: int) -> void:
	SYSLOG.debug_log("ENEMY_SPAWNER: Enemigo derrotado. Puntos otorgados: %d" % enemy_points, "ENEMY_SPAWNER")

	# 🔹 Restar al contador de enemigos vivos
	enemies_alive -= 1  
	SYSLOG.debug_log("Enemigos restantes: %d" % enemies_alive, "ENEMY_SPAWNER")

	# 🔹 Verificar si todos los enemigos han sido derrotados
	if enemies_alive <= 0:
		SYSLOG.debug_log("Todos los enemigos eliminados. Emitiendo all_enemies_defeated.", "ENEMY_SPAWNER")
		emit_signal("all_enemies_defeated")

# ==========================
# Reiniciar Enemigos para la Siguiente Fase
# ==========================
func restart_enemy_wave():
	SYSLOG.debug_log("Reiniciando generación de enemigos.", "ENEMY_SPAWNER")
	for enemy in enemies:
		if enemy and not enemy.is_queued_for_deletion():
			enemy.queue_free()
	enemies.clear()
	spawn_enemies()

# ==========================
# Obtener distribución de enemigos por fase
# ==========================
func _get_enemy_distribution_for_phase(phase: int) -> Array:
	if enemy_distribution.has(phase):
		return enemy_distribution[phase]

	var last_phase = enemy_distribution.keys().max()
	var last_distribution = enemy_distribution[last_phase]

	var new_distribution = last_distribution.duplicate()
	new_distribution.append_array(last_distribution)

	enemy_distribution[phase] = new_distribution

	SYSLOG.debug_log("Nueva distribución de enemigos para la fase %d: %s" % [phase, str(new_distribution)], "ENEMY_SPAWNER")
	return new_distribution
