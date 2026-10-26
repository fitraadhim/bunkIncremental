extends Node2D
## Main — orkestrasi level, wave, spawn zombie, drop, dan input global.
##
## Alur baru:
##   1. Game mulai siang hari (GameState.fase == "siang")
##   2. Pemain jalan ke Detektor, tekan E → LevelSelector muncul
##   3. Pilih level → _mulai_level() → fase = "malam" → zombie mulai spawn
##   4. Setelah semua wave level selesai → fase kembali "siang"

const ZOMBIE_SCENE := preload("res://scenes/entities/zombie.tscn")
const PICKUP_SCENE := preload("res://scenes/entities/pickup.tscn")
const LEVEL_1 := preload("res://data/level/level_1.tres")

@export var interval_spawn: float = 0.9
@export var jeda_antar_wave: float = 5.0
@export var posisi_spawn_x: float = 668.0
@export var posisi_tanah_y: float = 260.0
@export var jeda_kunci_tab: float = 0.25
@export var jarak_pintu_bunker: float = 190.0
@export var jarak_detektor: float = 52.0
@export var batas_pemain_kiri: float = 104.0
@export var batas_pemain_kanan: float = 622.0

@onready var entitas: Node2D = $Entities
@onready var pemain = $Player
@onready var hud = $UI/HUD
@onready var skill_panel = $UI/SkillPanel
@onready var level_selector = $UI/LevelSelector
@onready var dunia: Node2D = $World
@onready var pagar: Node2D = $Pagar
@onready var interior: Node2D = $Interior
@onready var mount_depan: Node2D = $MountDepan
@onready var detektor: Node2D = $Detektor

var _sisa_spawn: int = 0
var _timer_spawn: float = 0.0
var _timer_jeda: float = 0.0
var _menunggu_wave: bool = false
var _ulang_wave: bool = false
var _kunci_tab: float = 0.0
## Data level yang sedang dimainkan.
var _level_data: Resource = null


func _ready() -> void:
	if not SaveManager.berhasil_muat:
		GameState.beri_paket_awal()
		GameState.pesan.emit(
			"Welcome to the bunker. It's quiet for now.",
			Color(0.92, 0.82, 0.52)
		)

	GameState.pesan.connect(hud.tampilkan_pesan)
	hud.hubungkan_pemain(pemain)
	skill_panel.ditutup.connect(_on_panel_ditutup)

	# LevelSelector diisi dengan data level yang tersedia.
	level_selector.daftar_level = [LEVEL_1]
	level_selector.level_dipilih.connect(_on_level_dipilih)
	level_selector.ditutup.connect(_on_panel_ditutup)

	# Mount point disembunyikan secara default (hanya muncul saat mode pasang turret).
	mount_depan.visible = false

	# Mulai dalam keadaan siang.
	_atur_fase_siang()


func _process(delta: float) -> void:
	_kunci_tab = maxf(0.0, _kunci_tab - delta)
	_tangani_input()
	if pemain.di_dalam:
		_tangani_tangga()
	if GameState.fase == "malam":
		_proses_wave(delta)
		_cek_bunker()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _tangani_input() -> void:
	if _kunci_tab > 0.0 or skill_panel.visible or level_selector.visible:
		return

	# Tab / K membuka skill tree dari mana saja.
	if Input.is_action_just_pressed("buka_panel") or Input.is_action_just_pressed("buka_skill"):
		_kunci_tab = jeda_kunci_tab
		skill_panel.buka()
		return

	if Input.is_action_just_pressed("interaksi"):
		_tangani_interaksi()


func _tangani_interaksi() -> void:
	# Di dalam bunker: cek NPC dulu, lalu pintu.
	if pemain.di_dalam:
		var jenis_npc: String = interior.npc_di_dekat(pemain.global_position)
		if jenis_npc != "":
			_buka_ui_npc(jenis_npc)
			return
		_coba_keluar_bunker()
		return

	# Di luar: detektor → masuk bunker → pesan.
	if detektor != null and detektor.dalam_jangkauan(pemain.global_position):
		if GameState.fase == "malam":
			GameState.pesan.emit("A wave is in progress!", Color(1.0, 0.45, 0.32))
		else:
			_kunci_tab = jeda_kunci_tab
			level_selector.buka()
		return

	if pemain.global_position.x < jarak_pintu_bunker:
		_masuk_bunker()
	else:
		GameState.pesan.emit("Move closer to the bunker door", Color(0.7, 0.75, 0.82))


# ---------------------------------------------------------------------------
# UI NPC (terminal lama dipecah per NPC)
# ---------------------------------------------------------------------------

## Buka tab terminal yang sesuai NPC yang diajak bicara.
func _buka_ui_npc(jenis: String) -> void:
	# Terminal lama masih dipakai tapi di-open pada tab tertentu saja.
	var terminal = $UI/Terminal
	_kunci_tab = jeda_kunci_tab
	terminal.buka_tab(jenis)
	terminal.ditutup.connect(_on_panel_ditutup, CONNECT_ONE_SHOT)


# ---------------------------------------------------------------------------
# Bunker enter/exit
# ---------------------------------------------------------------------------

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
	hud.atur_petunjuk_terlihat(false)
	GameState.pesan.emit("Inside the bunker.", Color(0.85, 0.80, 0.62))


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
	hud.atur_petunjuk_terlihat(true)
	GameState.pesan.emit("Back outside", Color(0.85, 0.80, 0.62))


# ---------------------------------------------------------------------------
# Tangga
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Fase siang / malam
# ---------------------------------------------------------------------------

func _atur_fase_siang() -> void:
	GameState.fase = "siang"
	GameState.wave_aktif = false
	GameState.fase_berubah.emit("siang")
	dunia.atur_siang(true)
	GameState.pesan.emit(
		"Daylight. Use the detector to start a mission.",
		Color(0.92, 0.82, 0.52)
	)


func _atur_fase_malam() -> void:
	GameState.fase = "malam"
	GameState.fase_berubah.emit("malam")
	dunia.atur_siang(false)


func _on_level_dipilih(level_id: int) -> void:
	_level_data = LEVEL_1  # Untuk sekarang hanya Level 1.
	_kunci_tab = jeda_kunci_tab
	_mulai_level()


func _mulai_level() -> void:
	if _level_data == null:
		return
	GameState.level_aktif = _level_data.id
	GameState.wave_dalam_level = 0
	GameState.wave_total_level = _level_data.jumlah_wave
	GameState.wave = 1
	_atur_fase_malam()
	GameState.pesan.emit(_level_data.pesan_mulai, Color(0.92, 0.78, 0.45))
	await get_tree().create_timer(1.5).timeout
	_mulai_wave()


func _selesaikan_level() -> void:
	GameState.level_selesai.emit(GameState.level_aktif)
	GameState.pesan.emit(_level_data.pesan_selesai, Color(0.6, 0.92, 0.6))
	await get_tree().create_timer(3.0).timeout
	_atur_fase_siang()


# ---------------------------------------------------------------------------
# Callbacks panel
# ---------------------------------------------------------------------------

func _on_panel_ditutup() -> void:
	_kunci_tab = jeda_kunci_tab


# ---------------------------------------------------------------------------
# Wave
# ---------------------------------------------------------------------------

func _mulai_wave() -> void:
	GameState.wave_dalam_level += 1
	_sisa_spawn = 4 + GameState.wave
	_timer_spawn = 1.0
	_menunggu_wave = false
	GameState.mulai_wave_baru()
	GameState.pesan.emit(
		"Wave %d / %d — %d walkers incoming" % [
			GameState.wave_dalam_level,
			GameState.wave_total_level,
			_sisa_spawn
		],
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
			_mulai_wave()
		else:
			# Cek apakah level selesai.
			if GameState.wave_dalam_level >= GameState.wave_total_level:
				_selesaikan_level()
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
		"Wave %d clear  ·  +$%d" % [GameState.wave_dalam_level, bonus],
		Color(0.6, 0.92, 0.6)
	)
	SaveManager.simpan()
	_menunggu_wave = true
	_timer_jeda = jeda_antar_wave


func _lahirkan_zombie() -> void:
	var zombie = ZOMBIE_SCENE.instantiate()
	zombie.wave_ke = GameState.wave
	# Terapkan pengali level kalau ada.
	if _level_data != null:
		zombie.pengali_hp = _level_data.pengali_hp
		zombie.pengali_kecepatan = _level_data.pengali_kecepatan
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

	GameState.perbaiki_pagar(GameState.pagar_hp_maks())

	_bersihkan_zombie()
	GameState.wave_aktif = false

	if pemain.di_dalam:
		_keluar_bunker()

	GameState.pesan.emit(
		"The bunker was breached! Lost %d oil." % hilang,
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
