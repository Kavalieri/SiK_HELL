# ==========================
# STATS_MODIFIER.gd
# ==========================
class_name STATS_MODIFIER_c extends Node
# ==========================
# Signals
# ==========================

# ==========================
# Multiplicadores Ajustables
# ==========================
@export var damage_multiplier: float = 1.0
@export var crit_multiplier: float = 1.0
@export var attack_speed_multiplier: float = 1.0
@export var health_multiplier: float = 1.0
@export var defense_multiplier: float = 1.0
@export var precision_multiplier: float = 1.0
@export var dodge_multiplier: float = 1.0
@export var luck_multiplier: float = 1.0

# ==========================
# Aplicar Modificadores a los Stats
# ==========================
func modificar_stat(valor: float, tipo: String) -> float:
	match tipo:
		"damage":
			return valor * damage_multiplier
		"crit":
			return valor * crit_multiplier
		"attack_speed":
			return valor * attack_speed_multiplier
		"health":
			return valor * health_multiplier
		"defense":
			return valor * defense_multiplier
		"precision":
			return valor * precision_multiplier
		"dodge":
			return valor * dodge_multiplier
		"luck":
			return valor * luck_multiplier
		_:
			return valor  # Si el tipo no es reconocido, devolver sin cambios
