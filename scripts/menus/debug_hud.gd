# ==========================
# debug_hud.gd
# ==========================
class_name debug_hud extends Control

# ==========================
# Referencias de Nodos del Debug HUD
# ==========================
@onready var debug_layer = $debug_hud  # 🔹 CanvasLayer que se oculta y muestra
@onready var pj_label = $debug_hud/pj_1
@onready var enemy_label = $debug_hud/enemy_1

# ==========================
# Variables Internas
# ==========================
var debug_visible: bool = false  # 🔹 Estado inicial (invisible)

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	add_to_group("debug_hud")  # 🔹 Asegurar que está en el grupo correcto
	debug_layer.visible = debug_visible  # 🔹 Ocultar al inicio
	SYSLOG.debug_log("DEBUG HUD inicializado y oculto.", "DEBUG_HUD")

# ==========================
# Capturar Entrada del Usuario
# ==========================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.as_text_key_label() == "º":
			debug_visible = !debug_visible
			debug_layer.visible = debug_visible
			SYSLOG.debug_log("DEBUG HUD toggled: %s" % str(debug_visible), "DEBUG_HUD")

			# 🔹 Si el debug está visible, actualizar la información
			if debug_visible:
				actualizar_debug()

# ==========================
# Actualizar Información del Debug HUD
# ==========================
func actualizar_debug() -> void:
	if not debug_visible:
		return  # 🔹 Solo actualizar si el debug está visible

	# 🔹 Obtener el jugador activo
	var player = get_tree().get_nodes_in_group("pj")[0] if get_tree().get_nodes_in_group("pj").size() > 0 else null
	if not player:
		SYSLOG.error_log("No se encontró el jugador para mostrar en el debug.", "DEBUG_HUD")
		pj_label.text = "No se encontró el jugador."
	else:
		# 🔹 Actualizar stats del jugador
		pj_label.text = "DEBUG Pj_1:\n" + \
			"Health: %d\n" % player.health + \
			"Damage: %d\n" % player.damage + \
			"Speed: %d\n" % player.speed + \
			"Attack Speed: %.2f\n" % player.attack_speed + \
			"Defense: %d\n" % player.defense + \
			"Energy: %d\n" % player.energy + \
			"Precision: %d\n" % player.precision + \
			"Critical: %d\n" % player.crit + \
			"Dodge: %d\n" % player.dodge

	# 🔹 Obtener el enemigo más cercano al jugador
	var closest_enemy = _get_closest_enemy(player)
	if closest_enemy:
		enemy_label.text = "DEBUG Enemy:\n" + \
			"Health: %d\n" % closest_enemy.health + \
			"Damage: %d\n" % closest_enemy.damage + \
			"Speed: %d\n" % closest_enemy.speed + \
			"Attack Speed: %.2f\n" % closest_enemy.attack_speed + \
			"Defense: %d\n" % closest_enemy.defense + \
			"Precision: %d\n" % closest_enemy.precision + \
			"Critical: %d\n" % closest_enemy.crit + \
			"Dodge: %d\n" % closest_enemy.dodge
	else:
		enemy_label.text = "No hay enemigos visibles."
		SYSLOG.error_log("No se encontró enemigo para mostrar en el debug.", "DEBUG_HUD")

# ==========================
# Obtener el Enemigo Más Cercano
# ==========================
func _get_closest_enemy(player: Node) -> Node:
	if not player:
		return null

	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return null

	var closest_enemy = null
	var min_distance = INF  # Iniciamos con una distancia infinita

	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue  # Evitar enemigos nulos o eliminados

		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_enemy = enemy

	return closest_enemy

# ==========================
# Refrescar Debug HUD Cada Segundo
# ==========================
func _process(_delta: float) -> void:
	if debug_visible:
		actualizar_debug()  # 🔹 Solo actualizar si está activo
