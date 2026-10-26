extends Node
## Simulator keseimbangan. Menjalankan game tanpa jendela dengan bot
## sederhana, lalu mencetak ringkasan progres.
##
##   godot --headless --path . tools/simulasi.tscn -- --menit=10
##   godot --headless --path . tools/simulasi.tscn -- --menit=30 --strategi=ekonomi
##
## Strategi:
##   tempur  — bot hanya menembak, tidak pernah jual/beli (baseline)
##   ekonomi — bot jual minyak, nyalakan generator, produksi peluru
##
## Tujuannya bukan menguji kode, tapi melihat apakah kurva progresinya masuk akal.

const SKALA_WAKTU := 6.0
const LAPOR_TIAP := 60.0

var _menit: float = 10.0
var _strategi: String = "ekonomi"

var _utama: Node
var _pemain: Node
var _waktu_game: float = 0.0
var _timer_lapor: float = 0.0
var _log: Array = []

var _zombie_terakhir: int = 0
var _wave_terakhir: int = 1
var _uang_terakhir: int = 0
var _frame: int = 0
var _waktu_mulai_ms: int = 0
var _batas_detik: float = 0.0
var _waktu_tembak_terakhir: float = 0.0
var _tembakan: int = 0
var _tembakan_awal: int = 0
var _zombie_dibunuh_awal: int = 0


func _ready() -> void:
	_baca_argumen()
	Engine.time_scale = SKALA_WAKTU
	_waktu_mulai_ms = Time.get_ticks_msec()
	GameState.reset_penuh()
	GameState.beri_paket_awal()

	_utama = preload("res://scenes/main.tscn").instantiate()
	add_child(_utama)
	await get_tree().process_frame

	_pemain = _utama.get_node("Player")
	print("=== SIMULASI: %.0f menit, strategi '%s' ===" % [_menit, _strategi])
	print("%8s %6s %8s %8s %8s %8s %8s %8s" % [
		"waktu", "wave", "bunuh", "minyak", "logam", "uang", "9mm", "bunker"
	])


func _process(delta: float) -> void:
	_frame += 1
	# Engine.time_scale sudah mempercepat simulasi, jadi delta di sini adalah
	# waktu game yang sebenarnya.
	var dt := delta
	_waktu_game += dt
	_timer_lapor += dt

	_bot_bertindak(dt)
	_lapor_berkala()

	if _batas_detik > 0.0 and (Time.get_ticks_msec() - _waktu_mulai_ms) / 1000.0 > _batas_detik:
		print("Batas waktu nyata tercapai setelah %d frame." % _frame)
		_ringkasan()
		get_tree().quit(0)
		return

	if _waktu_game >= _menit * 60.0:
		_ringkasan()
		get_tree().quit(0)


# ---------------------------------------------------------------------------

func _bot_bertindak(delta: float) -> void:
	# Bidik zombie terdekat (dengan prediksi gerak) dan tembak terus.
	var target = _zombie_terdekat()
	_pemain.target_bidik = target
	_pemain.target_titik = _titik_bidik_maju(target)
	if target != null:
		_pemain._coba_tembak()

	_bot_bergerak(delta)

	if _strategi != "ekonomi":
		return

	# Nyalakan generator kalau ada minyak dan daya menipis.
	if not GameState.generator_aktif and GameState.minyak > 3 and GameState.listrik < 8.0:
		GameState.set_generator(true)

	# Isi antrean pabrik kalau logam cukup.
	if GameState.logam >= 2 and GameState.antrean_pabrik.size() < 2:
		GameState.antre_peluru("9mm")

	# Jual kelebihan minyak, tapi sisakan untuk bahan bakar.
	if GameState.minyak > 12:
		GameState.jual_minyak(GameState.minyak - 10)

	# Perbaiki bunker kalau rusak dan uang cukup.
	if GameState.hp_bunker < 70.0 and GameState.uang >= GameState.biaya_perbaikan():
		GameState.beli_perbaikan(25.0)

	# Pakai medkit kalau sekarat.
	if GameState.hp_pemain < 45.0:
		GameState.pakai_obat()


## Prediksi posisi zombie saat peluru tiba (lead shot), supaya bot tidak
## selalu menembak di belakang target.
func _titik_bidik_maju(target):
	if target == null or not is_instance_valid(target):
		return null
	var asal: Vector2 = _pemain.muzzle.global_position
	var pos: Vector2 = target.global_position + Vector2(0, -14)
	var jarak: float = asal.distance_to(pos)
	var waktu_tempuh: float = jarak / 520.0
	var kecepatan_zombie: Vector2 = target.velocity
	return pos + kecepatan_zombie * waktu_tempuh


## Bot berjalan seperti pemain wajar: menjaga jarak dari zombie, mundur kalau
## terlalu dekat, maju kalau terlalu jauh, dan menyimpang untuk memungut drop.
func _bot_bergerak(delta: float) -> void:
	var langkah: float = 110.0 * delta
	var z = _zombie_terdekat()

	if z != null and is_instance_valid(z):
		var selisih: float = z.global_position.x - _pemain.global_position.x
		var jarak: float = absf(selisih)
		if jarak < 82.0:
			# Terlalu dekat: mundur ke kiri.
			_pemain.global_position.x -= langkah
			return
		if jarak > 170.0:
			# Terlalu jauh: maju supaya masuk jangkauan nyaman.
			_pemain.global_position.x += signf(selisih) * langkah
			return

	var drop = _pickup_terdekat()
	if drop == null or not is_instance_valid(drop):
		return
	var selisih_drop: float = drop.global_position.x - _pemain.global_position.x
	if absf(selisih_drop) < 6.0:
		return
	_pemain.global_position.x += signf(selisih_drop) * langkah


func _pickup_terdekat():
	var terdekat = null
	var jarak_terdekat := 1e9
	for p in get_tree().get_nodes_in_group("pickup"):
		if not is_instance_valid(p):
			continue
		var j: float = absf(p.global_position.x - _pemain.global_position.x)
		if j < jarak_terdekat:
			jarak_terdekat = j
			terdekat = p
	return terdekat


func _zombie_terdekat():
	var terdekat = null
	var jarak_terdekat := 1e9
	for z in get_tree().get_nodes_in_group("zombie"):
		if not is_instance_valid(z):
			continue
		var j: float = absf(z.global_position.x - _pemain.global_position.x)
		if j < jarak_terdekat:
			jarak_terdekat = j
			terdekat = z
	return terdekat


func _lapor_berkala() -> void:
	if _timer_lapor < LAPOR_TIAP:
		return
	_timer_lapor -= LAPOR_TIAP
	_catat()


func _catat() -> void:
	var baris := "%8s %6d %8d %8d %8d %8d %8d %8.0f" % [
		Formatter.waktu(_waktu_game),
		GameState.wave,
		GameState.statistik["zombie_dibunuh"],
		GameState.minyak,
		GameState.logam,
		GameState.uang,
		GameState.jumlah_peluru("9mm"),
		GameState.hp_bunker,
	]
	print(baris)
	_log.append(baris)


func _ringkasan() -> void:
	_catat()
	print("")
	print("=== RINGKASAN ===")
	print("Waktu game     : %s" % Formatter.waktu(_waktu_game))
	print("Wave tercapai  : %d" % GameState.wave)
	print("Zombie dibunuh : %d" % GameState.statistik["zombie_dibunuh"])
	print("Tembakan       : %d  (%.1f peluru per kill)" % [
		_pemain.jumlah_tembakan,
		float(_pemain.jumlah_tembakan) / maxf(1.0, float(GameState.statistik["zombie_dibunuh"]))
	])
	print("Total uang     : $%d" % GameState.statistik["uang_didapat"])
	print("Minyak kumpul  : %d" % GameState.statistik["minyak_terkumpul"])
	print("Minyak terbakar: %d" % GameState.statistik["minyak_terbakar"])
	print("Peluru dibuat  : %d" % GameState.statistik["peluru_dibuat"])

	# Efisiensi bahan bakar: power yang benar-benar terpakai per 1 oil.
	# Idealnya mendekati 10 (1 oil = 10 power) kalau tidak ada yang terbuang.
	var terbakar := float(GameState.statistik["minyak_terbakar"])
	if terbakar > 0.0:
		print("Daya terpakai  : %.1f" % GameState.statistik["daya_terpakai"])
		print("Efisiensi      : %.2f power terpakai per oil (ideal %.0f)" % [
			float(GameState.statistik["daya_terpakai"]) / terbakar,
			GameState.LISTRIK_PER_BARA,
		])
	else:
		print("Efisiensi      : tidak ada minyak terbakar")
	print("Bunker HP      : %.0f / %.0f" % [GameState.hp_bunker, GameState.HP_BUNKER_MAKS])
	print("Pemain HP      : %.0f / %.0f" % [GameState.hp_pemain, GameState.HP_PEMAIN_MAKS])


func _baca_argumen() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--menit="):
			_menit = float(arg.split("=")[1])
		elif arg.begins_with("--strategi="):
			_strategi = arg.split("=")[1]
		elif arg.begins_with("--batas="):
			_batas_detik = float(arg.split("=")[1])
