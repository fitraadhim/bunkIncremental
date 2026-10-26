extends CharacterBody2D
## Player — karakter yang dikendalikan pemain.
##
## Fase manual: pemain wajib menembak sendiri. Nanti di fase otomasi
## (skill tree) pemain boleh diam dan membiarkan turret bekerja.

signal magasin_berubah(isi: int, kapasitas: int, cadangan: int)
signal jatuh
signal bangkit

const PELURU_SCENE := preload("res://scenes/entities/peluru.tscn")
const TEKSTUR_KILATAN := preload("res://art/placeholder/kilatan.png")
const TEKSTUR_TEBASAN := preload("res://art/placeholder/tebasan.png")

@export var kecepatan: float = 115.0
@export var batas_kiri: float = 104.0
@export var batas_kanan: float = 622.0
@export var waktu_bangkit: float = 3.0

var senjata_tembak: Senjata
var senjata_tebas: Senjata

## Kalau diisi, pemain membidik node ini alih-alih kursor mouse.
## Dipakai oleh simulator/uji otomatis, dan nanti oleh modul auto-aim.
var target_bidik: Node2D = null

## Titik bidik eksplisit (Vector2). Prioritas tertinggi di atas target_bidik.
var target_titik: Variant = null

var isi_magasin: int = 0

var _y_tanah: float = 260.0
var _timer_tembak: float = 0.0
var _timer_tebas: float = 0.0
var _sisa_reload: float = 0.0
var _sedang_reload: bool = false
var _sudah_peringatan: bool = false
var _arah_hadap: int = 1
var _mati: bool = false
var _sisa_bangkit: float = 0.0

## Statistik runtime (tidak disimpan). Berguna untuk balancing & debugging.
var jumlah_tembakan: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	add_to_group("pemain")
	_y_tanah = global_position.y
	senjata_tembak = Data.ambil_senjata("pistol")
	senjata_tebas = Data.ambil_senjata("parang")
	isi_magasin = senjata_tembak.kapasitas_magasin
	GameState.peluru_berubah.connect(_on_peluru_berubah)
	_kirim_magasin()


func _physics_process(delta: float) -> void:
	_timer_tembak = maxf(0.0, _timer_tembak - delta)
	_timer_tebas = maxf(0.0, _timer_tebas - delta)

	if _mati:
		_sisa_bangkit -= delta
		if _sisa_bangkit <= 0.0:
			_bangkit_kembali()
		return

	_perbarui_arah()
	_gerak()
	_perbarui_reload(delta)

	if Input.is_action_pressed("tembak"):
		_coba_tembak()
	if Input.is_action_just_pressed("tebas"):
		_coba_tebas()
	if Input.is_action_just_pressed("pakai_obat"):
		GameState.pakai_obat()


func apakah_mati() -> bool:
	return _mati


# ---------------------------------------------------------------------------
# Gerak & bidik
# ---------------------------------------------------------------------------

func _gerak() -> void:
	var arah := Input.get_axis("gerak_kiri", "gerak_kanan")
	velocity.x = arah * kecepatan
	velocity.y = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, batas_kiri, batas_kanan)
	global_position.y = _y_tanah


func _perbarui_arah() -> void:
	var tujuan := _titik_bidik()
	_arah_hadap = 1 if tujuan.x >= global_position.x else -1
	sprite.flip_h = _arah_hadap < 0
	muzzle.position.x = absf(muzzle.position.x) * _arah_hadap


## Titik yang sedang dibidik: target_titik, lalu target_bidik, lalu kursor mouse.
func _titik_bidik() -> Vector2:
	if target_titik is Vector2:
		return target_titik
	if target_bidik != null and is_instance_valid(target_bidik):
		return target_bidik.global_position
	return get_global_mouse_position()


# ---------------------------------------------------------------------------
# Menembak
# ---------------------------------------------------------------------------

func _coba_tembak() -> void:
	if _sedang_reload or _timer_tembak > 0.0:
		return
	if isi_magasin <= 0:
		_mulai_reload()
		return
	_tembak()


func _tembak() -> void:
	_timer_tembak = senjata_tembak.cooldown
	isi_magasin -= 1
	jumlah_tembakan += 1
	_kirim_magasin()

	var asal := muzzle.global_position
	var arah := (_titik_bidik() - asal).normalized()
	if arah == Vector2.ZERO:
		arah = Vector2(_arah_hadap, 0.0)

	var wadah := get_tree().get_first_node_in_group("wadah_entitas")
	if wadah == null:
		wadah = get_parent()

	var peluru_baru := PELURU_SCENE.instantiate()
	peluru_baru.global_position = asal
	peluru_baru.arah = arah
	peluru_baru.damage = senjata_tembak.damage
	wadah.add_child(peluru_baru)

	_munculkan_kilatan(asal)

	if isi_magasin <= 0:
		_mulai_reload()


func _mulai_reload() -> void:
	if _sedang_reload or isi_magasin >= senjata_tembak.kapasitas_magasin:
		return
	var cadangan := GameState.jumlah_peluru(senjata_tembak.kaliber)
	if cadangan <= 0:
		if not _sudah_peringatan:
			_sudah_peringatan = true
			GameState.pesan.emit("Out of 9mm — craft rounds at the Factory (Tab)", Color(1.0, 0.55, 0.35))
		return
	_sedang_reload = true
	_sisa_reload = senjata_tembak.waktu_reload


func _perbarui_reload(delta: float) -> void:
	if not _sedang_reload:
		return
	_sisa_reload -= delta
	if _sisa_reload > 0.0:
		return

	var cadangan := GameState.jumlah_peluru(senjata_tembak.kaliber)
	var butuh := senjata_tembak.kapasitas_magasin - isi_magasin
	var ambil := mini(butuh, cadangan)
	if ambil > 0:
		GameState.kurangi_peluru(senjata_tembak.kaliber, ambil)
		isi_magasin += ambil
	_sedang_reload = false
	_sisa_reload = 0.0
	_sudah_peringatan = false
	_kirim_magasin()


func _on_peluru_berubah(_kaliber: String, _jumlah: int) -> void:
	_kirim_magasin()


func _kirim_magasin() -> void:
	magasin_berubah.emit(
		isi_magasin,
		senjata_tembak.kapasitas_magasin,
		GameState.jumlah_peluru(senjata_tembak.kaliber)
	)


# ---------------------------------------------------------------------------
# Machete
# ---------------------------------------------------------------------------

func _coba_tebas() -> void:
	if _timer_tebas > 0.0:
		return
	_timer_tebas = senjata_tebas.cooldown

	var korban: Array = []
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var selisih: Vector2 = zombie.global_position - global_position
		if absf(selisih.x) > senjata_tebas.jangkauan_tebas:
			continue
		if absf(selisih.y) > 22.0:
			continue
		if absf(selisih.x) > 4.0 and signf(selisih.x) != float(_arah_hadap):
			continue
		korban.append(zombie)

	for zombie in korban:
		zombie.terima_damage(senjata_tebas.damage)

	_munculkan_tebasan()


# ---------------------------------------------------------------------------
# Efek visual
# ---------------------------------------------------------------------------

func _munculkan_kilatan(pos: Vector2) -> void:
	var kilatan := Sprite2D.new()
	kilatan.texture = TEKSTUR_KILATAN
	kilatan.global_position = pos
	kilatan.z_index = 6
	kilatan.scale = Vector2(1.0, 1.0)
	get_parent().add_child(kilatan)
	var tw := create_tween()
	tw.tween_property(kilatan, "modulate:a", 0.0, 0.07)
	tw.tween_callback(kilatan.queue_free)


func _munculkan_tebasan() -> void:
	var tebasan := Sprite2D.new()
	tebasan.texture = TEKSTUR_TEBASAN
	tebasan.global_position = global_position + Vector2(12.0 * _arah_hadap, -12.0)
	tebasan.flip_h = _arah_hadap < 0
	tebasan.z_index = 6
	get_parent().add_child(tebasan)
	var tw := create_tween()
	tw.tween_property(tebasan, "modulate:a", 0.0, 0.16)
	tw.tween_callback(tebasan.queue_free)


# ---------------------------------------------------------------------------
# Kondisi
# ---------------------------------------------------------------------------

func terima_damage(jumlah: float) -> void:
	if _mati:
		return
	GameState.terima_damage_pemain(jumlah)
	sprite.modulate = Color(1.8, 0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	if GameState.hp_pemain <= 0.0:
		_jatuh()


func _jatuh() -> void:
	_mati = true
	_sisa_bangkit = waktu_bangkit
	velocity = Vector2.ZERO
	modulate = Color(1.0, 1.0, 1.0, 0.45)
	GameState.pesan.emit("You are down... recovering", Color(1.0, 0.35, 0.3))
	jatuh.emit()


func _bangkit_kembali() -> void:
	_mati = false
	modulate = Color.WHITE
	global_position = Vector2(150.0, _y_tanah)
	GameState.pulihkan_pemain(GameState.HP_PEMAIN_MAKS * 0.5)
	GameState.pesan.emit("Back on your feet", Color(0.6, 0.9, 0.6))
	bangkit.emit()
