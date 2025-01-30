# ==========================
# pj_1.gd 
# ==========================
class_name class_pj_1 extends CharacterBody2D

# ==========================
# Signals
# ==========================
signal pj_muerto

# ==========================
# Propiedades Exportadas
# ==========================
@export var health: float = 100.0
@export var damage: float = 10.0
@export var attack_speed: float = 3.0  # Velocidad de ataque
@export var crit: float = 5.0  # Probabilidad de golpe crítico (0-100)
@export var precision: float = 10.0  # Probabilidad de ignorar esquiva del enemigo (0-100)

@export var dodge: float = 1.0  # Probabilidad de esquivar ataques (0-100)
@export var defense: float = 10.0

@export var speed: float = 500.0  # Velocidad base
@export var luck: float = 10.0  # Suerte para interacciones aleatorias

@export var energy: float = 100.0
@export var energy_regen_rate: float = 1.0  # Puntos de energía regenerados cada 0.1 segundos

@export var projectile_scene: PackedScene  # Escena del proyectil
@export var dash_distance: float = 200.0  # Distancia que recorrerá el dash
@export var dash_speed: float = 1000.0  # Velocidad del dash

# ==========================
# Variables Internas
# ==========================
var is_attacking: bool = false
var is_dead: bool = false
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_remaining_distance: float = 0.0
var attack_timer: float = 0.0
var movement_direction: Vector2 = Vector2.ZERO
var regen_timer: float = 0.0  # Control del tiempo para regeneración de energía

# ==========================
# Referencias de Nodos
# ==========================
@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_sprite = $dash  # Nodo AnimatedSprite2D para el dash
@onready var collision_shape = $CollisionShape2D
@onready var energy_bar = $energy_bar

# ==========================
# Funciones Principales
# ==========================
func _ready() -> void:
	if projectile_scene:
		SYSLOG.debug_log("Ataque configurado: %s" % projectile_scene.resource_path, "PJ1")
	else:
		SYSLOG.error_log("No se ha configurado un ataque para el personaje.", "PJ1")
		
	if energy_bar:
		energy_bar.max_value = energy
		energy_bar.value = energy

	SYSLOG.debug_log("pj1 inicializado con estadísticas: %s" % {
		"health": health,
		"energy": energy,
		"speed": speed,
		"attack_speed": attack_speed,
		"energy_regen_rate": energy_regen_rate,
	}, "PJ1")

	add_to_group("pj")  # Añadir al grupo 'pj'

func _process(delta: float) -> void:
	if is_dead:
		return

	if is_dashing:
		_handle_dash(delta)
		return

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false

	_handle_energy_regeneration(delta)
	_update_animation()

func _physics_process(delta: float) -> void:
	if is_dead or is_attacking or is_dashing:
		return

	_process_movement()


# ==========================
# Movimiento
# ==========================
func _process_movement() -> void:
	movement_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		movement_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		movement_direction.y += 1
	if Input.is_action_pressed("ui_left"):
		movement_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		movement_direction.x += 1

	movement_direction = movement_direction.normalized()
	velocity = movement_direction * speed
	move_and_slide()

	# Volteo del sprite según la dirección
	if movement_direction.x < 0:
		animated_sprite.flip_h = true
	elif movement_direction.x > 0:
		animated_sprite.flip_h = false

# ==========================
# Dash
# ==========================
func _handle_dash(delta: float) -> void:
	if dash_remaining_distance <= 0:
		_stop_dash()
		return

	# Mover al personaje en la dirección del dash
	var move_distance = dash_direction * dash_speed * delta
	position += move_distance
	dash_remaining_distance -= move_distance.length()

func _start_dash() -> void:
	
	if energy < 30:
		SYSLOG.error_log("Energía insuficiente para dashear.", "PJ1")
		return

	energy = max(energy - 30, 0)
	if energy_bar:
		energy_bar.value = energy
	SYSLOG.debug_log("Energía restante tras el dash: %d." % energy, "PJ1")
	
	if is_dashing or is_dead:
		return

	dash_direction = (get_global_mouse_position() - global_position).normalized()
	dash_remaining_distance = dash_distance
	is_dashing = true

	# Configurar animaciones y orientar según la dirección
	dash_sprite.visible = true
	dash_sprite.play("dash")
	dash_sprite.flip_h = dash_direction.x < 0  # Orientar la animación de dash
	animated_sprite.play("jumpattack")  # Reproducir la animación del personaje durante el dash
	animated_sprite.flip_h = dash_direction.x < 0  # Orientar el personaje

	# Desactivar colisiones
	collision_shape.disabled = true

	SYSLOG.debug_log("Dash iniciado en dirección: %s. Distancia restante: %f." % [dash_direction, dash_remaining_distance], "PJ1")



func _stop_dash() -> void:
	is_dashing = false

	# Restaurar estados al finalizar el dash
	dash_sprite.visible = false
	animated_sprite.play("idle")  # Volver a la animación idle
	collision_shape.disabled = false

	SYSLOG.debug_log("Dash finalizado. Posición actual: %s." % global_position, "PJ1")


# ==========================
# Animaciones
# ==========================
func _update_animation() -> void:
	if is_dead:
		animated_sprite.play("dead")
		return

	if is_dashing:
		return  # No cambiar la animación durante el dash

	if is_attacking:
		if not animated_sprite.is_playing() or animated_sprite.animation != "attack":
			animated_sprite.play("attack")
		return

	if movement_direction == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("walk")

# ==========================
# Regeneración de Energía
# ==========================
func _handle_energy_regeneration(delta: float) -> void:
	if energy < 100:  # Si la energía no está al máximo
		regen_timer += delta
		if regen_timer >= 0.1:  # Regenerar cada 0.1 segundos
			regen_timer = 0
			energy = min(energy + energy_regen_rate, 100)
			if energy_bar:
				energy_bar.value = energy

# ==========================
# Entrada de Usuario
# ==========================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not is_attacking and not is_dead:
		_on_attack()

	if event.is_action_pressed("dash") and not is_dashing and not is_dead:
		_start_dash()

func _on_attack() -> void:
	if is_attacking or is_dead:
		return  # Evitar lanzar múltiples proyectiles simultáneamente
		
	if not projectile_scene:
		SYSLOG.error_log("No se ha configurado una escena de proyectil.", "PJ1")
		return

	# Verificar costo de energía del ataque
	var energy_cost = 10  # Por defecto, pero se puede ajustar en el proyectil
	var test_projectile = projectile_scene.instantiate()
	if "energy_cost" in test_projectile:
		energy_cost = test_projectile.energy_cost
	test_projectile.queue_free()

	if energy < energy_cost:
		SYSLOG.error_log("Energía insuficiente para realizar el ataque. Energía requerida: %d, disponible: %d." % [energy_cost, energy], "PJ1")
		return

	# Reducir energía
	energy = max(energy - energy_cost, 0)
	if energy_bar:
		energy_bar.value = energy
	SYSLOG.debug_log("Energía restante tras el ataque: %d." % energy, "PJ1")

	# Obtener proyectil de la pool
	var projectile = COMBAT._get_projectile(projectile_scene)
	if not projectile:
		SYSLOG.error_log("No se pudo obtener un proyectil de la pool.", "PJ1")
		return

	# Configurar el proyectil y lanzarlo
	projectile.global_position = global_position
	projectile.launch_at(get_global_mouse_position(), self)  # Pasar el jugador como origen

	# Agregar log para confirmar el lanzador
	SYSLOG.debug_log("Proyectil lanzado con lanzador: %s." % self.name, "PJ1")

	# Animación del jugador
	is_attacking = true
	attack_timer = 1.0 / attack_speed
	animated_sprite.flip_h = get_global_mouse_position().x < global_position.x
	animated_sprite.play("attack")


# ==========================
# Estados
# ==========================
func _morir() -> void:
	is_dead = true
	animated_sprite.play("dead")
	SYSLOG.debug_log("pj1 ha muerto.", "PJ1")
	emit_signal("pj_muerto")

	if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		animated_sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _on_animation_finished() -> void:
	if animated_sprite.animation == "dead":
		SYSLOG.debug_log("Animación 'dead' finalizada. Pausando el juego.", "PJ1")

func set_health(nueva_salud: int) -> void:
	health = nueva_salud
	if health <= 0:
		_morir()

# ==========================
# Configuración de Ataque
# ==========================
func set_projectile_scene(projectile_path: String) -> void:
	if not ResourceLoader.exists(projectile_path):
		SYSLOG.error_log("El ataque '%s' no existe en la carpeta 'attack'." % projectile_path, "PJ1")
		return

	projectile_scene = load(projectile_path)
	if projectile_scene:
		SYSLOG.debug_log("Ataque configurado correctamente: %s." % projectile_path, "PJ1")
	else:
		SYSLOG.error_log("Error al cargar el ataque desde la ruta: %s." % projectile_path, "PJ1")
