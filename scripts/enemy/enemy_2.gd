# ==========================
# enemy_2.gd 
# ==========================
class_name enemy_2 extends CharacterBody2D 

# ==========================
# Signals 
# ========================== 
signal enemy_defeated(enemy_points: int)

# ==========================
# Propiedades Exportadas
# ==========================
@export var health: float = 100.0
@export var damage: float = 20.0
@export var attack_speed: float = 1.0  # Velocidad de ataque (ataques por segundo)
@export var crit: float = 1.0  # Probabilidad de golpe crítico (0-100)
@export var precision: float = 1.0  # Probabilidad de ignorar esquiva del enemigo (0-100)

@export var dodge: float = 0.0  # Probabilidad de esquivar ataques (0-100)
@export var defense: float = 0.0

@export var speed: float = 200.0  # Velocidad base

@export var enemy_points: int = 1  # 🔹 Puntos que otorga este enemigo al morir

# ==========================
# Variables Internas
# ==========================
var target: CharacterBody2D = null  # Referencia al jugador
var is_dead: bool = false  # Estado del enemigo
var attack_timer: float = 0.0  # Temporizador para ataques continuos

# ==========================
# Referencias de Nodos
# ==========================
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# ==========================
# Funciones Principales
# ==========================
func _ready() -> void:
	add_to_group("enemy")
	SYSLOG.debug_log("Enemigo inicializado. Esperando al jugador...", "ENEMY")

func _process(delta: float) -> void:
	if not target:
		target = _buscar_jugador()
		if target:
			SYSLOG.debug_log("Jugador detectado: %s." % target.name, "ENEMY")
		return  # Esperar al siguiente frame para procesar lógica adicional
	if is_dead:
		return

	_mover_hacia_jugador()
	_actualizar_animacion()
	_verificar_colisiones(delta)

# ==========================
# Movimiento
# ==========================
func _mover_hacia_jugador() -> void:
	if not target:
		SYSLOG.error_log("No se encontró un objetivo para el enemigo.", "ENEMY")
		return

	# Calcular dirección hacia el jugador
	velocity = (target.global_position - global_position).normalized() * speed

	# Usar move_and_slide para mover al enemigo
	move_and_slide()

	# Volteo del sprite según la dirección
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false

# ==========================
# Verificar Colisiones
# ==========================
func _verificar_colisiones(delta: float) -> void:
	# Reducir el temporizador de ataque
	if attack_timer > 0:
		attack_timer -= delta

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if not collision:
			continue

		var collider = collision.get_collider()
		if collider and collider.is_in_group("pj"):
			# Atacar si el temporizador está listo
			if attack_timer <= 0.0:
				attack_timer = 1.0 / attack_speed  # Reiniciar temporizador
				SYSLOG.debug_log("Enemigo atacó al jugador: %s con daño: %d." % [collider.name, damage], "ENEMY")
				COMBAT.enemy_attack_damage(self, collider)

# ==========================
# Animaciones
# ==========================
func _actualizar_animacion() -> void:
	if is_dead:
		animated_sprite.play("dead")
		return

	if velocity.length() > 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

# ==========================
# Estados
# ==========================
func _morir() -> void:
	if is_dead:
		return  # 🔹 Evitar doble ejecución

	is_dead = true
	animated_sprite.play("dead")

	# 🔹 Desactivar la colisión inmediatamente para evitar más impactos
	collision_shape.set_deferred("disabled", true)
	SYSLOG.debug_log("Colisión del enemigo desactivada al morir: %s." % self.name, "ENEMY")

	# 🔹 Emitir la señal correctamente con los puntos
	emit_signal("enemy_defeated", enemy_points)  
	SYSLOG.debug_log("Enemigo derrotado: %s. Puntos otorgados: %d" % [self.name, enemy_points], "ENEMY")

	# 🔹 Notificar directamente a `LEVEL_MANAGER`
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager._on_enemy_defeated(enemy_points)

	# 🔹 Esperar la animación antes de eliminarlo
	await animated_sprite.animation_finished
	queue_free()

func set_health(nueva_salud: int) -> void:
	health = nueva_salud
	if health <= 0:
		_morir()

# ==========================
# Utilidades
# ==========================
func _buscar_jugador() -> CharacterBody2D:
	for node in get_tree().get_nodes_in_group("pj"):
		if node is CharacterBody2D:
			return node
	return null
