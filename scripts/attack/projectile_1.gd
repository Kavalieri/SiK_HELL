# ==========================
# projectile_1.gd 
# ==========================
class_name projectile_1 extends Area2D

# ==========================
# Propiedades Exportadas
# ==========================
@export var damage: int = 10
@export var precision: float = 0
@export var crit: float = 0
@export var speed: float = 300
@export var distance: float = 500
@export var max_hits: int = 1
@export var energy_cost: float = 10
@export var rotation_speed: float = 5.0  # 🔹 Velocidad de rotación

var direction: Vector2 = Vector2.ZERO
var is_active: bool = false
var hits: int = 0
var lanzador: Node = null
var traveled_distance: float = 0.0
var has_exploded: bool = false  # 🔹 Para evitar múltiples explosiones simultáneas

# ==========================
# Referencias de Nodos
# ==========================
@onready var collision_shape = $CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D

# ==========================
# Inicialización
# ==========================
func initialize(direccion: Vector2, lanzador_nodo: Node) -> void:
	direction = direccion.normalized()
	lanzador = lanzador_nodo
	is_active = true
	hits = 0
	has_exploded = false
	traveled_distance = 0.0
	self.set_process(true)
	self.show()

	# Restaurar colisiones y animación inicial
	collision_shape.set_deferred("disabled", false)  # 🔹 Asegurar que se reactiva al disparar
	animated_sprite.frame = 0
	animated_sprite.stop()
	animated_sprite.flip_h = direction.x < 0

	SYSLOG.debug_log("Proyectil inicializado. Dirección: %s, Lanzador: %s." % [direction, lanzador.name], "PROJECTILE")

func _ready() -> void:
	add_to_group("projectile")
	self.connect("body_entered", Callable(self, "_on_body_entered"))
	self.connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

# ==========================
# Movimiento y Ciclo de Vida
# ==========================
func _process(delta: float) -> void:
	if not is_active:
		return  # No procesar si el proyectil está inactivo

	# 🔹 Aplicar rotación constante al proyectil mientras esté activo
	rotation += rotation_speed * delta

	# Mover el proyectil
	var move_distance = direction * speed * delta
	position += move_distance
	traveled_distance += move_distance.length()

	# Verificar si ha superado la distancia máxima
	if traveled_distance >= distance:
		SYSLOG.debug_log("Proyectil superó la distancia máxima de %d píxeles." % distance, "PROJECTILE")
		_deshabilitar()

# ==========================
# Colisión con Enemigos
# ==========================
func _on_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("enemy"):
		SYSLOG.error_log("Cuerpo no válido o no pertenece al grupo 'enemy'.", "PROJECTILE")
		return

	# Asegurar que el proyectil no impacte más veces de las permitidas
	if hits >= max_hits:
		return

	# Calcular daño y procesar impacto
	COMBAT.pj_attack_damage(self, body)
	hits += 1
	SYSLOG.debug_log("Proyectil impactó al enemigo: %s. Hits: %d/%d." % [body.name, hits, max_hits], "PROJECTILE")

	# 🔹 Deshabilitar colisión antes de la animación de explosión
	if hits >= max_hits:
		collision_shape.set_deferred("disabled", true)  # 🔹 Desactivar colisión inmediatamente
		SYSLOG.debug_log("Proyectil alcanzó su máximo de impactos. Colisión desactivada.", "PROJECTILE")

	# 🔹 Activar animación de explosión si es el primer impacto
	if not has_exploded:
		has_exploded = true
		animated_sprite.play("explosion", true)

# ==========================
# Verificar Salida de Pantalla
# ==========================
func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		SYSLOG.debug_log("Proyectil salió de la pantalla visible.", "PROJECTILE")
		_deshabilitar()

# ==========================
# Animación Terminada
# ==========================
func _on_animation_finished() -> void:
	if animated_sprite.animation == "explosion":
		SYSLOG.debug_log("Animación de explosión finalizada. Desactivando proyectil.", "PROJECTILE")
		_deshabilitar()

# ==========================
# Desactivación
# ==========================
func _deshabilitar() -> void:
	if not is_active:
		return

	is_active = false
	hide()
	set_process(false)
	traveled_distance = 0.0
	rotation = 0  # 🔹 Restablecer rotación para el siguiente disparo
	collision_shape.set_deferred("disabled", false)  # 🔹 Reactivar colisión para el siguiente disparo
	animated_sprite.stop()
	animated_sprite.frame = 0
	SYSLOG.debug_log("Proyectil devuelto a la pool.", "PROJECTILE")
	COMBAT.deactivate_projectile(self)

func launch_at(target_position: Vector2, lanzador_nodo: Node) -> void:
	initialize((target_position - global_position).normalized(), lanzador_nodo)
	self.show()  # Asegurarse de que el proyectil sea visible
	SYSLOG.debug_log("Proyectil lanzado a posición: %s desde lanzador: %s" % [target_position, lanzador_nodo.name], "PROJECTILE")
