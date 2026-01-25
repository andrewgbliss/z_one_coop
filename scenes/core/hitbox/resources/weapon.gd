class_name Weapon extends Resource

@export var damage_min: int = 0
@export var damage_max: int = 0
@export var attack_rate: float = 0.5 # Cooldown time between shots
@export var stamina_cost: float = 0.0
@export var projectile: String = "" # SpawnManager entity key
@export var max_ammo: int = 0
@export var unlimited_ammo: bool = false
@export var ammo: int = 0
@export var spread: int = 1
@export var spread_angle: float = 0.3
@export var screen_shake_amount: float = 0.0
@export var burst_size: int = 1 # Number of shots in a burst
@export var burst_cooldown: float = 0.0 # Cooldown time after a burst

signal ammo_changed(ammo_change: int, max_ammo: int)

# Runtime cooldown tracking (not saved)
var _cooldown_time_elapsed: float = 999.0 # Start high so weapon is ready
var _is_on_cooldown: bool = false

# Burst cooldown system
var _burst_count: int = 0 # Track shots fired in current burst
var _burst_cooldown_time_elapsed: float = 999.0 # Start high so no burst cooldown initially
var _is_on_burst_cooldown: bool = false

func update_cooldown(delta: float) -> void:
	_cooldown_time_elapsed += delta
	_is_on_cooldown = _cooldown_time_elapsed <= attack_rate
	
	# Update burst cooldown timer (only increment if we're on cooldown)
	if _is_on_burst_cooldown:
		_burst_cooldown_time_elapsed += delta
		_is_on_burst_cooldown = _burst_cooldown_time_elapsed <= burst_cooldown
		# Reset timer when cooldown expires (burst_count already reset when cooldown started)
		if not _is_on_burst_cooldown:
			_burst_cooldown_time_elapsed = 999.0 # Reset to high value like initial state

func is_on_cooldown() -> bool:
	return _is_on_cooldown

func reset_cooldown() -> void:
	_cooldown_time_elapsed = 0.0
	_is_on_cooldown = true

func has_ammo() -> bool:
	return unlimited_ammo or ammo > 0

func is_on_burst_cooldown() -> bool:
	return _is_on_burst_cooldown

func can_fire() -> bool:
	# If we're on burst cooldown, can't fire
	if is_on_burst_cooldown():
		return false
	# If we've reached the burst limit, can't fire (this should trigger burst cooldown)
	if _burst_count >= burst_size:
		return false
	return not is_on_cooldown() and has_ammo() and projectile != ""

func consume_ammo() -> void:
	if not unlimited_ammo and ammo > 0:
		ammo -= 1
		ammo_changed.emit(ammo, max_ammo)

func add_ammo(amount: int) -> void:
	if unlimited_ammo:
		return
	ammo += amount
	if ammo > max_ammo:
		ammo = max_ammo
	ammo_changed.emit(ammo, max_ammo)

func fire() -> void:
	"""Call this when firing the weapon. Handles cooldown reset and ammo consumption."""
	consume_ammo()
	reset_cooldown()
	
	# Track burst count
	_burst_count += 1
	
	# If we've fired enough shots, start burst cooldown immediately
	if _burst_count >= burst_size:
		_burst_cooldown_time_elapsed = 0.0
		_is_on_burst_cooldown = true
		_burst_count = 0 # Reset immediately so next burst can start after cooldown

func save():
	var data = {}
	data["damage_min"] = damage_min
	data["damage_max"] = damage_max
	data["attack_rate"] = attack_rate
	data["stamina_cost"] = stamina_cost
	data["projectile"] = projectile
	data["max_ammo"] = max_ammo
	data["unlimited_ammo"] = unlimited_ammo
	data["ammo"] = ammo
	data["spread"] = spread
	data["spread_angle"] = spread_angle
	data["screen_shake_amount"] = screen_shake_amount
	data["burst_size"] = burst_size
	data["burst_cooldown"] = burst_cooldown
	return data

func restore(data):
	if data.has("damage_min"):
		damage_min = data["damage_min"]
	if data.has("damage_max"):
		damage_max = data["damage_max"]
	if data.has("attack_rate"):
		attack_rate = data["attack_rate"]
	if data.has("stamina_cost"):
		stamina_cost = data["stamina_cost"]
	if data.has("projectile"):
		projectile = data["projectile"]
	if data.has("max_ammo"):
		max_ammo = data["max_ammo"]
	if data.has("unlimited_ammo"):
		unlimited_ammo = data["unlimited_ammo"]
	if data.has("ammo"):
		ammo = data["ammo"]
	if data.has("spread"):
		spread = data["spread"]
	if data.has("spread_angle"):
		spread_angle = data["spread_angle"]
	if data.has("screen_shake_amount"):
		screen_shake_amount = data["screen_shake_amount"]
	if data.has("burst_size"):
		burst_size = data["burst_size"]
	if data.has("burst_cooldown"):
		burst_cooldown = data["burst_cooldown"]
