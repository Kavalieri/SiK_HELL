class_name class_COMBAT extends Node

# ==========================
# Configuración del Pool de Proyectiles
# ==========================
@export var pool_size: int = 50
var projectile_pools = {}  # Diccionario para almacenar múltiples pools (por tipo de proyectil)
var projectile_pool: Array[Node] = []
var enemy_count: int = 1
var lanzador = null

# ==========================
# Inicialización del Pool
# ==========================
func _inicializar_pool(projectile_scene: PackedScene) -> void:
	if not projectile_scene:
		SYSLOG.error_log("La escena base del proyectil no está configurada.", "COMBAT")
		return

	# Si la pool para este tipo de proyectil no existe, crearla
	if not projectile_pools.has(projectile_scene):
		projectile_pools[projectile_scene] = []

	# Crear proyectiles y añadirlos a la pool correspondiente
	var pool = projectile_pools[projectile_scene]
	while pool.size() < pool_size:
		var projectile = projectile_scene.instantiate()
		projectile.set_meta("scene", projectile_scene)  # Definir el metadato 'scene'
		projectile.hide()
		projectile.is_active = false
		add_child(projectile)
		pool.append(projectile)

	SYSLOG.debug_log("Pool inicializada para la escena: %s." % projectile_scene.resource_path, "COMBAT")



# ==========================
# Obtener Proyectil de la Pool
# ==========================
func _get_projectile(projectile_scene: PackedScene) -> Node:
	if not projectile_pools.has(projectile_scene):
		_inicializar_pool(projectile_scene)

	var pool = projectile_pools[projectile_scene]
	for projectile in pool:
		if not projectile.is_active:
			projectile.is_active = true
			projectile.show()
			return projectile

	SYSLOG.error_log("No hay proyectiles disponibles para la escena: %s." % projectile_scene.resource_path, "COMBAT")
	return null

# ==========================
# Desactivar Proyectiles
# ==========================
func deactivate_projectile(projectile: Node) -> void:
	if not projectile:
		SYSLOG.error_log("Intento de desactivar un proyectil nulo.", "COMBAT")
		return

	var pool = projectile_pools.get(projectile.get_meta("scene"), [])
	if pool and projectile in pool:
		SYSLOG.debug_log("Proyectil devuelto a la pool y restaurado.", "COMBAT")
	else:
		SYSLOG.error_log("Intento de desactivar un proyectil no registrado en la pool.", "COMBAT")

# ==========================
# Calcular Daño de Ataque de un PJ
# ==========================
func pj_attack_damage(proyectil: Node, objetivo: Node) -> void:
	if not proyectil or not objetivo:
		SYSLOG.error_log("Proyectil o objetivo no válido para el cálculo de daño. %s %s %s " % [proyectil.name, objetivo.name], "COMBAT")
		return

	SYSLOG.debug_log("Iniciando cálculo de daño. Proyectil: %s, Objetivo: %s" % [proyectil.name, objetivo.name], "COMBAT")

	# Obtener estadísticas del proyectil
	var proyectil_damage = proyectil.damage if "damage" in proyectil else 0
	var proyectil_precision = proyectil.precision if "precision" in proyectil else 0
	var proyectil_crit = proyectil.crit if "crit" in proyectil else 0
	SYSLOG.debug_log("Proyectil - Daño: %d, Precisión: %d, Crítico: %d" %
		[proyectil_damage, proyectil_precision, proyectil_crit], "COMBAT")

	# Obtener estadísticas del lanzador
	var pj = proyectil.lanzador if "lanzador" in proyectil else null
	if not pj:
		var lanzador_name = proyectil.lanzador.name if proyectil.lanzador and "name" in proyectil.lanzador else "desconocido"
		var proyectil_name = proyectil.name if proyectil and "name" in proyectil else "desconocido"
		SYSLOG.error_log("No se encontró el lanzador del proyectil %s. Nombre del proyectil: %s" % [lanzador_name, proyectil_name], "COMBAT")
		return

	var pj_damage = pj.damage if "damage" in pj else 0
	var pj_precision = pj.precision if "precision" in pj else 0
	var pj_crit = pj.crit if "crit" in pj else 0
	SYSLOG.debug_log("Lanzador - Daño: %d, Precisión: %d, Crítico: %d" %
		[pj_damage, pj_precision, pj_crit], "COMBAT")

	# Combinar estadísticas y calcular daño
	var damage_base = proyectil_damage + pj_damage
	var precision_total = proyectil_precision + pj_precision
	var crit_total = proyectil_crit + pj_crit

	# Verificar esquiva del objetivo
	var is_dodge = randf() * 100 < objetivo.dodge and randf() * 100 >= precision_total
	SYSLOG.debug_log("Esquiva - Dodge del objetivo: %d, Precisión total del ataque: %d, Resultado: %s" %
		[objetivo.dodge, precision_total, str(is_dodge)], "COMBAT")
	if is_dodge:
		SYSLOG.debug_log("%s esquivó el ataque de %s." % [objetivo.name, proyectil.name], "COMBAT")
		actualizar_enemy_damage_label(objetivo, 0)
		actualizar_pj_damage_label(objetivo, 0)
		return

	# Calcular daño crítico
	var is_crit = randf() * 100 < crit_total
	var total_damage = damage_base * 2 if is_crit else damage_base
	SYSLOG.debug_log("Crítico - Probabilidad: %d, Resultado: %s, Daño crítico: %d" % [crit_total, str(is_crit), total_damage], "COMBAT")

	# Aplicar defensa
	var final_damage = max(0, total_damage - objetivo.defense)
	SYSLOG.debug_log("Defensa del objetivo: %d, Daño final aplicado: %d" % [objetivo.defense, final_damage], "COMBAT")

	# Aplicar daño al objetivo
	recibir_dano(objetivo, final_damage, 0, proyectil)
	SYSLOG.debug_log("%s recibió un ataque de %s. Daño final aplicado: %d" % [objetivo.name, proyectil.name, final_damage], "COMBAT")




# ==========================
# Calcular Daño de un Enemigo
# ==========================
func enemy_attack_damage(origen: Node, objetivo: Node) -> void:
	# Verificar si el jugador puede esquivar
	if randf() * 100 < objetivo.dodge and randf() * 100 >= origen.precision:
		SYSLOG.debug_log("El ataque de %s fue esquivado por %s." % [origen.name, objetivo.name], "COMBAT")
		actualizar_enemy_damage_label(objetivo, 0)  # Mostrar "fallo" como 0
		actualizar_pj_damage_label(objetivo, 0)
		return

	# Calcular daño base del enemigo
	var total_damage = origen.damage
	if randf() * 100 < origen.crit:
		total_damage *= 2  # Aplicar golpe crítico
		SYSLOG.debug_log("¡Golpe crítico! Daño final de %s: %d." % [origen.name, total_damage], "COMBAT")

	# Aplicar defensa del jugador
	var final_damage = max(0, total_damage - objetivo.defense)

	# Aplicar daño y actualizar la salud del jugador
	recibir_dano(objetivo, final_damage, 0, origen)

	# Iniciar el cooldown del ataque
	if "attack_cooldown" in origen:
		origen.attack_cooldown = 1.0  # Cooldown de 1 segundo

	SYSLOG.debug_log("El enemigo %s atacó al jugador %s por %d de daño." % [origen.name, objetivo.name, final_damage], "COMBAT")

# ==========================
# Registro de Daño Recibido
# ==========================
func recibir_dano(objetivo: Node, cantidad: int, defensa: int, origen: Node = null) -> void:
	var dano_recibido = max(0, cantidad - defensa)
	objetivo.health = max(objetivo.health - dano_recibido, 0)  # Salud mínima en 0

	# Actualizar barra de salud
	var health_bar = objetivo.get_node_or_null("health_bar")
	if health_bar:
		health_bar.value = objetivo.health
		actualizar_enemy_damage_label(objetivo, dano_recibido)
		actualizar_pj_damage_label(objetivo, dano_recibido)
		SYSLOG.debug_log("Barra de salud actualizada para %s. Salud actual: %d/%d." % 
			[objetivo.name, objetivo.health, health_bar.max_value], "COMBAT")

	# Registro
	var origen_name = origen.name if origen else "desconocido"
	SYSLOG.debug_log("%s recibió %d de daño de %s. Salud actual: %d." %
		[objetivo.name, dano_recibido, origen_name, objetivo.health], "COMBAT")

	# Verificar si el objetivo ha muerto
	if objetivo.health <= 0:
		morir(objetivo)

# ==========================
# Actualizar Daño Recibido
# ==========================
func actualizar_enemy_damage_label(objetivo: Node, damage: int) -> void:
	# Buscar la etiqueta solo si es relevante
	if not objetivo.has_node("enemy_damage_in"):
		SYSLOG.debug_log("El objetivo %s no tiene una etiqueta 'enemy_damage_in'. Saltando actualización." % objetivo.name, "COMBAT")
		return

	var damage_label = objetivo.get_node("enemy_damage_in") as Label
	if damage_label:
		damage_label.text = "-%d" % damage if damage > 0 else "MISS"  # Mostrar daño o fallo
		damage_label.visible = true

		# Configurar un temporizador para ocultar la etiqueta después de un tiempo
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 1.0  # Duración en segundos antes de ocultar la etiqueta
		timer.connect("timeout", Callable(self, "_ocultar_damage_label").bind(damage_label))
		objetivo.add_child(timer)  # Añadir el temporizador como hijo del objetivo
		timer.start()

# ==========================
# Actualizar Daño Recibido para el Jugador
# ==========================
func actualizar_pj_damage_label(objetivo: Node, damage: int) -> void:
	# Verificar si el jugador tiene la etiqueta 'pj_damage_in'
	if not objetivo.has_node("pj_damage_in"):
		SYSLOG.debug_log("El objetivo %s no tiene una etiqueta 'pj_damage_in'. Saltando actualización." % objetivo.name, "COMBAT")
		return

	# Obtener la etiqueta
	var damage_label = objetivo.get_node("pj_damage_in") as Label
	if damage_label:
		# Configurar el texto de la etiqueta con el daño o 'MISS'
		damage_label.text = "-%d" % damage if damage > 0 else "MISS"
		damage_label.visible = true

		# Configurar un temporizador para ocultar la etiqueta después de un tiempo
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 1.0  # Duración de 1 segundo
		timer.connect("timeout", Callable(self, "_ocultar_damage_label").bind(damage_label))
		objetivo.add_child(timer)  # Añadir el temporizador como hijo del jugador
		timer.start()



# ==========================
# Ocultar Daño Recibido
# ==========================
func _ocultar_damage_label(damage_label: Label) -> void:
	if damage_label:
		damage_label.visible = false

# ==========================
# Manejador de Muerte
# ==========================
func morir(objetivo: Node) -> void:
	if objetivo.has_method("_morir"):
		objetivo._morir()
	else:
		SYSLOG.error_log("El objetivo %s no tiene una función 'morir'." % objetivo.name, "COMBAT")



func curar(objetivo: Node, cantidad: int) -> void:
	objetivo.health += cantidad
	SYSLOG.debug_log("%s se cura %d puntos de salud. Salud actual: %d" % [objetivo.name, cantidad, objetivo.health], "COMBAT")

func regenerar_energia(objetivo: Node, cantidad: int) -> void:
	objetivo.energy += cantidad
	SYSLOG.debug_log("%s regenera %d puntos de energía. Energía actual: %d" % [objetivo.name, cantidad, objetivo.energy], "COMBAT")
