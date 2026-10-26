extends Node2D
## Main — orkestrasi wave, spawn zombie, drop, dan input global.

const ZOMBIE_SCENE := preload("res://scenes/entities/zombie.tscn")
const PICKUP_SCENE := preload("res://scenes/entities/pickup.tscn")

@export var interval_spawn: float = 0.9
@export var jeda_antar_wave: float = 5.0
@export var posisi_spawn_x: float = 668.0
@export var posisi_tanah_y: float = 260.0
@export var jeda_kunci_tab: float = 0.25
@export var jarak_pintu_bunker: float = 190.0
## Batas gerak pemain di dunia luar. Disimpan di sini supaya saat keluar dari
## bunker kita bisa mengembalikannya tanpa menebak angka.
@export var batas_pemain_kiri: float = 104.0
@export var batas_pemain_kanan: float = 622.0

@onready var entitas: Node2D = $Entities
@onready var pemain = $Player
@onready var hud = $UI/HUD
@onready var terminal = $UI/Terminal
@onready var skill_panel = $UI/SkillPanel
@onready var dunia: Node2D = $World
@onready var pagar: Node2D = $Pagar
@onready var interior: Node2D = $Interior
@onready var mount_depan: Node2D = $MountDepan

var _sisa_spawn: int = 0
var _timer_spawn: float = 0.0
var _timer_jeda: float = 0.0
var _menunggu_wave: bool = false
var _ulang_wave: bool = false
var _kunci_tab: float = 0.0


func _ready() -> void:
	if not SaveManager.berhasil_muat:
		GameState.beri_paket_awal()
		GameState.pesan.emit(
			"Welcome to the bunker. Survive the night.",
			Color(0.92, 0.82, 0.52)
		)

	GameState.pesan.connect(hud.tampilkan_pesan)
	hud.hubungkan_pemain(pemain)
	terminal.ditutup.connect(_on_terminal_ditutup)
	skill_panel.ditutup.connect(_on_panel_ditutup)
	_mulai_wave()


func _process(delta: float) -> void:
	_kunci_tab = maxf(0.0, _kunci_tab - delta)
	_tangani_input()
	if pemain.di_dalam:
		_tangani_tangga()
	_proses_wave(delta)
	_cek_bunker()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _tangani_input() -> void:
	if _kunci_tab > 0.0 or terminal.visible or skill_panel.visible:
		return

	if Input.is_action_just_pressed("buka_panel"):
		_buka_terminal()
	elif Input.is_action_just_pressed("buka_skill"):
		_kunci_tab = jeda_kunci_tab
		skill_panel.buka()
	elif Input.is_action_just_pressed("interaksi"):
		_tangani_interaksi()


## E dipakai untuk dua hal: masuk/keluar bunker, dan membuka terminal kalau
## pemain berdiri dekat pintu dari luar. Terminal tetap bisa dibuka dengan Tab
## di mana saja, termasuk saat di dalam bunker.
func _tangani_interaksi() -> void:
	if pemain.di_dalam:
		_coba_keluar_bunker()
		return

	if pemain.global_position.x < jarak_pintu_bunker:
		_masuk_bunker()
	else:
		GameState.pesan.emit("Move closer to the bunker door", Color(0.7, 0.75, 0.82))


func _masuk_bunker() -> void:
	pemain.masuk_bunker(
		interior.posisi_masuk(),
		interior.BATAS_KIRI,
		interior.BATAS_KANAN,
		1
	)
	interior.masuk()
	dunia.visible = false
	pagar.visible = false
	entitas.visible = false
	mount_depan.visible = false
	hud.atur_petunjuk_terlihat(false)
	GameState.pesan.emit("Inside the bunker. Time keeps moving.", Color(0.85, 0.80, 0.62))


func _coba_keluar_bunker() -> void:
	if pemain.lantai >= 2:
		GameState.pesan.emit("Climb down the stairs first", Color(0.7, 0.75, 0.82))
		return
	if not interior.di_zona_pintu(pemain.global_position.x):
		GameState.pesan.emit("Move to the door to leave", Color(0.7, 0.75, 0.82))
		return
	_keluar_bunker()


func _keluar_bunker() -> void:
	pemain.keluar_bunker(Vector2(150.0, posisi_tanah_y), batas_pemain_kiri, batas_pemain_kanan)
	interior.keluar()
	dunia.visible = true
	pagar.visible = true
	entitas.visible = true
	mount_depan.visible = true
	hud.atur_petunjuk_terlihat(true)
	GameState.pesan.emit("Back outside", Color(0.85, 0.80, 0.62))


## Naik/turun lantai. Hanya bisa dari zona tangga, dan lantai 2 tetap
## terkunci sampai Tower Access dibeli.
func _tangani_tangga() -> void:
	if not interior.di_zona_tangga(pemain.global_position.x):
		return

	if not interior.lantai_2_terbuka():
		if Input.is_action_just_pressed("gerak_atas"):
			GameState.pesan.emit(
				"The stairwell is sealed — Tower Access required",
				Color(1.0, 0.62, 0.30)
			)
		return

	if Input.is_action_just_pressed("gerak_atas") and pemain.lantai == 1:
		pemain.pindah_lantai(2, interior.posisi_naik())
		GameState.pesan.emit("Up to the tower floor", Color(0.85, 0.80, 0.62))
	elif Input.is_action_just_pressed("gerak_bawah") and pemain.lantai == 2:
		pemain.pindah_lantai(1, interior.posisi_turun())
		GameState.pesan.emit("Back on the ground floor", Color(0.85, 0.80, 0.62))


func _buka_terminal() -> void:
	_kunci_tab = jeda_kunci_tab
	terminal.buka()


func _on_terminal_ditutup() -> void:
	_kunci_tab = jeda_kunci_tab


func _on_panel_ditutup() -> void:
	_kunci_tab = jeda_kunci_tab


# ---------------------------------------------------------------------------
# Wave
# ---------------------------------------------------------------------------

func _mulai_wave() -> void:
	_sisa_spawn = 4 + GameState.wave
	_timer_spawn = 1.0
	_menunggu_wave = false
	GameState.mulai_wave_baru()
	GameState.pesan.emit(
		"Night %d — %d walkers incoming" % [GameState.wave, _sisa_spawn],
		Color(0.92, 0.78, 0.45)
	)


func _proses_wave(delta: float) -> void:
	if _menunggu_wave:
		_timer_jeda -= delta
		if _timer_jeda > 0.0:
			return
		_menunggu_wave = false
		if _ulang_wave:
			_ulang_wave = false
		else:
			GameState.wave += 1
		_mulai_wave()
		return

	if _sisa_spawn > 0:
		_timer_spawn -= delta
		if _timer_spawn <= 0.0:
			_timer_spawn = interval_spawn
			_lahirkan_zombie()
			_sisa_spawn -= 1
		return

	if GameState.wave_aktif and GameState.zombie_hidup <= 0:
		_selesaikan_wave()


func _selesaikan_wave() -> void:
	GameState.wave_aktif = false
	var bonus := 10 + GameState.wave * 5
	GameState.tambah_resource("uang", bonus)
	GameState.pesan.emit(
		"Night %d cleared  ·  +$%d bounty" % [GameState.wave, bonus],
		Color(0.6, 0.92, 0.6)
	)
	SaveManager.simpan()
	_menunggu_wave = true
	_timer_jeda = jeda_antar_wave


func _lahirkan_zombie() -> void:
	var zombie = ZOMBIE_SCENE.instantiate()
	zombie.wave_ke = GameState.wave
	zombie.position = Vector2(posisi_spawn_x + randf_range(-8.0, 26.0), posisi_tanah_y)
	zombie.mati.connect(_on_zombie_mati)
	entitas.add_child(zombie)
	GameState.catat_zombie_lahir()


func _on_zombie_mati(zombie) -> void:
	if zombie == null or not is_instance_valid(zombie):
		return

	var data: Musuh = zombie.data
	if data == null:
		return

	# Drop ikut naik seiring wave. Tanpa ini, pendapatan tetap datar
	# sementara HP zombie tumbuh eksponensial, dan pemain mentok permanen.
	var bonus_minyak := int(GameState.wave / 3)
	var bonus_logam := int(GameState.wave / 4)

	var pos: Vector2 = zombie.global_position
	_jatuhkan(pos, "minyak", randi_range(data.drop_minyak.x, data.drop_minyak.y) + bonus_minyak)
	_jatuhkan(pos, "logam", randi_range(data.drop_logam.x, data.drop_logam.y) + bonus_logam)
	if randf() < data.peluang_obat:
		_jatuhkan(pos, "obat", 1)


func _jatuhkan(pos: Vector2, jenis: String, jumlah: int) -> void:
	if jumlah <= 0:
		return
	var pickup = PICKUP_SCENE.instantiate()
	pickup.jenis = jenis
	pickup.jumlah = jumlah
	pickup.position = pos + Vector2(randf_range(-10.0, 10.0), randf_range(-6.0, 0.0))
	entitas.add_child(pickup)


# ---------------------------------------------------------------------------
# Bunker jebol
# ---------------------------------------------------------------------------

func _cek_bunker() -> void:
	if GameState.hp_bunker > 0.0:
		return
	if not GameState.wave_aktif:
		return

	var hilang := int(GameState.minyak * 0.5)
	GameState.minyak -= hilang
	GameState.resource_berubah.emit()

	GameState.hp_bunker = GameState.hp_bunker_maks() * 0.5
	GameState.hp_bunker_berubah.emit(GameState.hp_bunker, GameState.hp_bunker_maks())

	# Malam diulang dari awal, jadi pagar juga dibangun ulang — kalau tidak,
	# pemain yang sudah kehilangan separuh minyak langsung kena tembok kosong.
	GameState.perbaiki_pagar(GameState.pagar_hp_maks())

	_bersihkan_zombie()
	GameState.wave_aktif = false

	# Kalau pemain sedang di dalam, keluarkan paksa — pintu sudah jebol.
	if pemain.di_dalam:
		_keluar_bunker()

	GameState.pesan.emit(
		"The bunker was breached! Lost %d oil. Falling back..." % hilang,
		Color(1.0, 0.32, 0.26)
	)

	_menunggu_wave = true
	_ulang_wave = true
	_timer_jeda = 6.0


func _bersihkan_zombie() -> void:
	for zombie in get_tree().get_nodes_in_group("zombie"):
		zombie.remove_from_group("zombie")
		zombie.queue_free()
	GameState.zombie_hidup = 0
	GameState.wave_berubah.emit(GameState.wave, 0)
