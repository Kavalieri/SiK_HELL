# ==========================
# ENEMY_SPAWNER.gd
# ==========================
class_name class_ENEMY_SPAWNER extends Node

# ==========================
# Señales
# ==========================
signal all_enemies_defeated

# ==========================
# Propiedades Exportadas
# ==========================
@export var enemy_scenes: Dictionary = {
	"basic": preload("res://scenes/enemies/enemy_1.tscn"),
	"fast": preload("res://scenes/enemies/enemy_1.tscn"),
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
var enemies = []
var phase: int = 1  # Se actualizará desde `nivel_X.gd`
var enemy_spawn_areas = []  # Lista de todas las zonas de spawn
var save_data: Dictionary = {}

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	SYSLOG.debug_log("ENEMY_SPAWNER inicializado.", "ENEMY_SPAWNER")

	# Buscar todas las áreas de spawn en la escena actual con nombres "enemy_spawn_1", "enemy_spawn_2", ...
	var all_spawn_areas = get_tree().current_scene.get_children()
	for node in all_spawn_areas:
		if node is Area2D and node.name.begins_with("enemy_spawn_"):
			enemy_spawn_areas.append(node)

	# ✅ Construir la lista de nombres de forma compatible con GDScript
	if enemy_spawn_areas.is_empty():
		SYSLOG.error_log("No se encontraron áreas de spawn en la escena.", "ENEMY_SPAWNER")
	else:
		var area_names_list = []
		for area in enemy_spawn_areas:
			area_names_list.append(area.name)  # Agregamos cada nombre a la lista

		var area_names_string = ", ".join(area_names_list)  # Convertimos la lista en string
		SYSLOG.debug_log("Se encontraron %d áreas de spawn: [%s]" % [enemy_spawn_areas.size(), area_names_string], "ENEMY_SPAWNER")

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
	var max_enemies = LEVEL_MANAGER.get_enemy_count_for_phase()
	SYSLOG.debug_log("Generando %d enemigos..." % max_enemies, "ENEMY_SPAWNER")

	var available_enemies = enemy_distribution.get(phase, ["basic"])
	for i in range(max_enemies):
		var enemy_type = available_enemies.pick_random()
		var enemy = enemy_scenes[enemy_type].instantiate()
		enemy.global_position = _generar_posicion_enemigo()
		get_tree().current_scene.add_child(enemy)
		enemies.append(enemy)

		# 🔹 Conectar la señal de muerte del enemigo
		if not enemy.is_connected("enemy_defeated", Callable(self, "_on_enemy_defeated")):
			enemy.connect("enemy_defeated", Callable(self, "_on_enemy_defeated").bind(enemy))

	SYSLOG.debug_log("Enemigos generados correctamente.", "ENEMY_SPAWNER")
	
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
func _on_enemy_defeated(enemy: Node) -> void:
	SYSLOG.debug_log("ENEMY_SPAWNER: Enemigo derrotado: %s" % enemy.name, "ENEMY_SPAWNER")

	# Remover enemigo de la lista
	if enemy in enemies:
		enemies.erase(enemy)

	# Si no quedan enemigos, emitir la señal de victoria
	if enemies.size() == 0:
		SYSLOG.debug_log("Todos los enemigos han sido eliminados. Emitiendo all_enemies_defeated.", "ENEMY_SPAWNER")
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
