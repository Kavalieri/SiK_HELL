# ==========================
# nivel_1.gd
# ==========================
class_name nivel_1 extends Area2D

# ==========================
# Variables Internas
# ==========================
@onready var limites = $limites  
@onready var level_hud = $level_hud  
@onready var resultado = $resultado  

# ==========================
# Inicialización
# ==========================
func _ready() -> void:
	add_to_group("nivel")

	# 🔹 Agregar resultado al grupo para facilitar su acceso desde LEVEL_MANAGER
	if resultado:
		resultado.add_to_group("resultado")
		SYSLOG.debug_log("Nodo de resultado añadido al grupo correctamente.", "NIVEL")
	else:
		SYSLOG.error_log("No se encontró el nodo resultado en la escena.", "NIVEL")

	# 🔹 Inicializar el nivel desde LEVEL_MANAGER
	LEVEL_MANAGER.initialize_level()

# ==========================
# Manejar la eliminación de todos los enemigos
# ==========================
func _on_all_enemies_defeated():
	LEVEL_MANAGER.manejar_resultado("victoria")

# ==========================
# Restricción del Movimiento del Jugador
# ==========================
func _physics_process(_delta: float) -> void:
	var player = get_tree().get_nodes_in_group("pj")[0] if get_tree().get_nodes_in_group("pj").size() > 0 else null
	if player and limites:
		_restringir_movimiento(player)

func _restringir_movimiento(player: CharacterBody2D) -> void:
	if not player or not limites or not limites.shape:
		SYSLOG.error_log("No se puede restringir movimiento: Nodo 'limites' o 'player' no válido.", "NIVEL")
		return
	
	var extents = limites.shape.extents
	var bounds = Rect2(limites.global_position - extents, extents * 2)

	var clamped_position = Vector2(
		clamp(player.global_position.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clamp(player.global_position.y, bounds.position.y, bounds.position.y + bounds.size.y)
	)

	if player.global_position != clamped_position:
		SYSLOG.debug_log("Reubicando al jugador dentro de los límites: %s" % clamped_position, "NIVEL")
		player.global_position = clamped_position
