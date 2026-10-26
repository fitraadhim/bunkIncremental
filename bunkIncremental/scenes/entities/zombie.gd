extends CharacterBody2D
## Zombie — berjalan ke kiri menuju bunker, menyerang pemain kalau kebetulan
## berada di jalurnya. HP naik 18% per malam.

signal mati(zombie: Node2D)

const SKALA_HP_PER_WAVE := 1.12

## Diisi oleh main.gd sebelum add_child().
## pengali_hp dan pengali_kecepatan dari level data.
var pengali_hp: float = 1.0
var pengali_kecepatan: float = 1.0
var wave_ke: int = 1

var data: Musuh
var hp: float = 20.0
var hp_maks: float = 20.0

var _timer_serang: float = 0.0
var _mati: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("zombie")
	data = Data.ambil_musuh("zombie_biasa")

	var pengali_wave := pow(SKALA_HP_PER_WAVE, maxi(0, wave_ke - 1))
	hp_maks = data.hp * pengali_wave * pengali_hp
	hp = hp_maks
	scale = Vector2.ONE * data.skala
	_timer_serang = randf_range(0.2, 0.7)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _mati:
		return

	_timer_serang = maxf(0.0, _timer_serang - delta)

	var target = _cari_target()
	if target == null:
		velocity.x = -data.kecepatan
		move_and_slide()
		return

	var selisih: float = target.global_position.x - global_position.x
	if absf(selisih) > 13.0:
		velocity.x = signf(selisih) * data.kecepatan
		velocity.y = 0.0
		move_and_slide()
		sprite.flip_h = velocity.x > 0.0
	else:
		velocity.x = 0.0
		_serang(target)


func _cari_target():
	var pagar = _pagar_hidup()

	var pemain = get_tree().get_first_node_in_group("pemain")
	if pemain != null and is_instance_valid(pemain):
		# Pemain di dalam bunker tidak bisa dijangkau sama sekali.
		if not pemain.apakah_mati() and not pemain.di_dalam:
			# Pemain di belakang pagar tidak bisa dijangkau: zombie harus
			# menghancurkan pagar dulu. Tanpa cek ini, zombie akan berdiri
			# menempel pagar sambil mengabaikannya.
			var terjangkau := true
			if pagar != null:
				terjangkau = pemain.global_position.x > pagar.global_position.x
			if terjangkau and absf(pemain.global_position.x - global_position.x) < 90.0:
				return pemain

	if pagar != null:
		return pagar
	return get_tree().get_first_node_in_group("bunker")


## Pagar terdekat yang masih berdiri, atau null.
func _pagar_hidup():
	if not GameState.pagar_hidup():
		return null
	var pagar = get_tree().get_first_node_in_group("pagar")
	if pagar == null or not is_instance_valid(pagar):
		return null
	if not pagar.visible:
		return null
	return pagar


func _serang(target) -> void:
	if _timer_serang > 0.0:
		return
	_timer_serang = data.jeda_serang

	if target.is_in_group("pemain"):
		target.terima_damage(data.damage)
	elif target.is_in_group("pagar"):
		target.terima_damage(data.damage)
	else:
		GameState.terima_damage_bunker(data.damage)


# ---------------------------------------------------------------------------
# Menerima damage
# ---------------------------------------------------------------------------

func terima_damage(jumlah: float) -> void:
	if _mati:
		return
	hp -= jumlah
	queue_redraw()
	_flash()
	if hp <= 0.0:
		_hancur()


func _flash() -> void:
	sprite.modulate = Color(1.8, 1.8, 1.8)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _hancur() -> void:
	_mati = true
	remove_from_group("zombie")
	GameState.catat_zombie_mati()
	mati.emit(self)
	queue_free()


# ---------------------------------------------------------------------------
# Health bar
# ---------------------------------------------------------------------------

func _draw() -> void:
	if _mati or hp >= hp_maks:
		return
	var lebar := 18.0
	var rasio := clampf(hp / hp_maks, 0.0, 1.0)
	draw_rect(Rect2(-lebar * 0.5, -31.0, lebar, 3.0), Color(0.0, 0.0, 0.0, 0.75))
	draw_rect(Rect2(-lebar * 0.5, -31.0, lebar * rasio, 3.0), Color(0.84, 0.24, 0.2))
