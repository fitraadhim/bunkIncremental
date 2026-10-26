extends Node
## GameState — pusat data runtime.
##
## Aturan main: TIDAK ADA script lain yang boleh mengubah angka resource
## secara langsung. Semua lewat fungsi di sini, supaya HUD dan sistem lain
## bisa ikut update lewat sinyal.
##
## process_mode = ALWAYS artinya produksi pabrik, harga pasar, dan pembakaran
## minyak tetap berjalan walau game di-pause (misal saat terminal dibuka).

signal resource_berubah
signal peluru_berubah(kaliber: String, jumlah: int)
signal hp_pemain_berubah(sekarang: float, maks: float)
signal hp_bunker_berubah(sekarang: float, maks: float)
signal listrik_berubah(sekarang: float, maks: float)
signal wave_berubah(nomor: int, sisa: int)
signal pabrik_berubah
signal generator_berubah
signal pesan(teks: String, warna: Color)

const HP_PEMAIN_MAKS := 100.0
const HP_BUNKER_MAKS := 100.0
const LISTRIK_MAKS := 30.0
const JEDA_REFRESH_HARGA := 60.0
const KAPASITAS_ANTREAN := 5
const JEDA_BARA := 2.0
const LISTRIK_PER_BARA := 10.0

# --- Resource ---
var minyak: int = 0
var logam: int = 0
var obat: int = 0
var uang: int = 0

# --- Amunisi (kaliber -> jumlah) ---
var peluru: Dictionary = {"9mm": 0}

# --- Kondisi ---
var hp_pemain: float = HP_PEMAIN_MAKS
var hp_bunker: float = HP_BUNKER_MAKS

# --- Wave ---
var wave: int = 1
var zombie_hidup: int = 0
var zombie_total_wave: int = 0
var wave_aktif: bool = false

# --- Listrik & pabrik ---
var listrik: float = 0.0
var generator_aktif: bool = false
var antrean_pabrik: Array = []
var _akumulator_bara: float = 0.0

# --- Pasar ---
var harga_minyak: float = Ekonomi.HARGA_DASAR
var sisa_refresh_harga: float = JEDA_REFRESH_HARGA
var tren_harga: String = "flat"

# --- Statistik (untuk layar akhir / prestige nanti) ---
var statistik: Dictionary = {
	"zombie_dibunuh": 0,
	"minyak_terkumpul": 0,
	"uang_didapat": 0,
	"peluru_dibuat": 0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_tick_pasar(delta)
	_tick_generator(delta)
	_tick_pabrik(delta)


# ---------------------------------------------------------------------------
# Tick sistem
# ---------------------------------------------------------------------------

func _tick_pasar(delta: float) -> void:
	sisa_refresh_harga -= delta
	if sisa_refresh_harga > 0.0:
		return
	sisa_refresh_harga += JEDA_REFRESH_HARGA
	var lama := harga_minyak
	harga_minyak = Ekonomi.harga_berikutnya(lama)
	tren_harga = Ekonomi.tren(lama, harga_minyak)


func _tick_generator(delta: float) -> void:
	if not generator_aktif:
		return
	if listrik >= LISTRIK_MAKS:
		_akumulator_bara = 0.0
		return
	if minyak <= 0:
		generator_aktif = false
		generator_berubah.emit()
		pesan.emit("Generator stopped — out of crude oil", Color(1.0, 0.45, 0.3))
		return

	_akumulator_bara += delta
	if _akumulator_bara < JEDA_BARA:
		return

	_akumulator_bara -= JEDA_BARA
	minyak -= 1
	listrik = minf(listrik + LISTRIK_PER_BARA, LISTRIK_MAKS)
	resource_berubah.emit()
	listrik_berubah.emit(listrik, LISTRIK_MAKS)


func _tick_pabrik(delta: float) -> void:
	if antrean_pabrik.is_empty():
		return

	var hasil := Produksi.proses(antrean_pabrik, delta, listrik, Data.resep_peluru)

	if float(hasil["daya_terpakai"]) > 0.0:
		listrik = maxf(0.0, listrik - float(hasil["daya_terpakai"]))
		listrik_berubah.emit(listrik, LISTRIK_MAKS)

	for kaliber in hasil["selesai"]:
		var resep: ResepPeluru = Data.resep_peluru.get(kaliber)
		if resep == null:
			continue
		tambah_peluru(kaliber, resep.hasil)
		statistik["peluru_dibuat"] += resep.hasil
		pesan.emit("+%d %s rounds produced" % [resep.hasil, kaliber], Color(0.6, 0.9, 0.6))

	if not hasil["selesai"].is_empty():
		pabrik_berubah.emit()


# ---------------------------------------------------------------------------
# Resource
# ---------------------------------------------------------------------------

func tambah_resource(jenis: String, jumlah: int) -> void:
	if jumlah <= 0:
		return
	match jenis:
		"minyak":
			minyak += jumlah
			statistik["minyak_terkumpul"] += jumlah
		"logam":
			logam += jumlah
		"obat":
			obat += jumlah
		"uang":
			uang += jumlah
			statistik["uang_didapat"] += jumlah
		_:
			return
	resource_berubah.emit()


func kurangi_resource(jenis: String, jumlah: int) -> bool:
	if jumlah <= 0:
		return true
	var cukup := false
	match jenis:
		"minyak":
			cukup = minyak >= jumlah
			if cukup:
				minyak -= jumlah
		"logam":
			cukup = logam >= jumlah
			if cukup:
				logam -= jumlah
		"obat":
			cukup = obat >= jumlah
			if cukup:
				obat -= jumlah
		"uang":
			cukup = uang >= jumlah
			if cukup:
				uang -= jumlah
	if cukup:
		resource_berubah.emit()
	return cukup


## Jual minyak ke pasar. Mengembalikan jumlah uang yang didapat.
func jual_minyak(jumlah: int) -> int:
	var banyak := mini(jumlah, minyak)
	if banyak <= 0:
		return 0
	var dapat := Ekonomi.nilai_jual(banyak, harga_minyak)
	minyak -= banyak
	uang += dapat
	statistik["uang_didapat"] += dapat
	resource_berubah.emit()
	return dapat


# ---------------------------------------------------------------------------
# Amunisi
# ---------------------------------------------------------------------------

func tambah_peluru(kaliber: String, jumlah: int) -> void:
	peluru[kaliber] = int(peluru.get(kaliber, 0)) + jumlah
	peluru_berubah.emit(kaliber, int(peluru[kaliber]))


func kurangi_peluru(kaliber: String, jumlah: int) -> bool:
	var punya := int(peluru.get(kaliber, 0))
	if punya < jumlah:
		return false
	peluru[kaliber] = punya - jumlah
	peluru_berubah.emit(kaliber, int(peluru[kaliber]))
	return true


func jumlah_peluru(kaliber: String) -> int:
	return int(peluru.get(kaliber, 0))


# ---------------------------------------------------------------------------
# Kondisi
# ---------------------------------------------------------------------------

func terima_damage_pemain(jumlah: float) -> void:
	hp_pemain = maxf(0.0, hp_pemain - jumlah)
	hp_pemain_berubah.emit(hp_pemain, HP_PEMAIN_MAKS)


func pulihkan_pemain(jumlah: float) -> void:
	hp_pemain = minf(HP_PEMAIN_MAKS, hp_pemain + jumlah)
	hp_pemain_berubah.emit(hp_pemain, HP_PEMAIN_MAKS)


func terima_damage_bunker(jumlah: float) -> void:
	hp_bunker = maxf(0.0, hp_bunker - jumlah)
	hp_bunker_berubah.emit(hp_bunker, HP_BUNKER_MAKS)


func perbaiki_bunker(jumlah: float) -> void:
	hp_bunker = minf(HP_BUNKER_MAKS, hp_bunker + jumlah)
	hp_bunker_berubah.emit(hp_bunker, HP_BUNKER_MAKS)


## Biaya perbaikan naik seiring wave, supaya memperbaiki bunker terasa
## seperti keputusan ekonomi dan bukan tombol gratis.
func biaya_perbaikan() -> int:
	return 10 + wave * 3


## Beli perbaikan bunker sebanyak `jumlah` HP. Mengembalikan HP yang didapat.
func beli_perbaikan(jumlah: float) -> float:
	var kurang := HP_BUNKER_MAKS - hp_bunker
	if kurang <= 0.5:
		pesan.emit("The bunker is already at full strength", Color(0.7, 0.75, 0.82))
		return 0.0

	var biaya := biaya_perbaikan()
	if uang < biaya:
		pesan.emit("Not enough money for repairs", Color(1.0, 0.6, 0.3))
		return 0.0

	uang -= biaya
	var didapat := minf(jumlah, kurang)
	perbaiki_bunker(didapat)
	resource_berubah.emit()
	pesan.emit("Bunker repaired +%d HP" % int(didapat), Color(0.6, 0.9, 0.6))
	return didapat


## Pakai satu medkit. Mengembalikan true kalau berhasil.
func pakai_obat() -> bool:
	if obat <= 0:
		pesan.emit("No medkits left", Color(1.0, 0.6, 0.3))
		return false
	if hp_pemain >= HP_PEMAIN_MAKS - 0.5:
		pesan.emit("You are already at full health", Color(0.7, 0.75, 0.82))
		return false

	obat -= 1
	pulihkan_pemain(35.0)
	resource_berubah.emit()
	pesan.emit("Medkit used  +35 HP", Color(0.6, 0.9, 0.6))
	return true


# ---------------------------------------------------------------------------
# Pabrik & generator
# ---------------------------------------------------------------------------

func antre_peluru(kaliber: String) -> bool:
	var resep: ResepPeluru = Data.resep_peluru.get(kaliber)
	if resep == null:
		return false
	if Produksi.sisa_slot(antrean_pabrik, KAPASITAS_ANTREAN) <= 0:
		pesan.emit("Production queue is full", Color(1.0, 0.6, 0.3))
		return false
	if logam < resep.logam:
		pesan.emit("Not enough scrap metal", Color(1.0, 0.6, 0.3))
		return false

	logam -= resep.logam
	antrean_pabrik.append(Produksi.buat_item(resep))
	resource_berubah.emit()
	pabrik_berubah.emit()
	return true


func set_generator(aktif: bool) -> void:
	if aktif and minyak <= 0:
		pesan.emit("No crude oil to burn", Color(1.0, 0.6, 0.3))
		return
	generator_aktif = aktif
	_akumulator_bara = 0.0
	generator_berubah.emit()


# ---------------------------------------------------------------------------
# Wave
# ---------------------------------------------------------------------------

func mulai_wave_baru() -> void:
	zombie_total_wave = 4 + wave
	zombie_hidup = 0
	wave_aktif = true
	wave_berubah.emit(wave, zombie_hidup)


func catat_zombie_lahir() -> void:
	zombie_hidup += 1
	wave_berubah.emit(wave, zombie_hidup)


func catat_zombie_mati() -> void:
	zombie_hidup = maxi(0, zombie_hidup - 1)
	statistik["zombie_dibunuh"] += 1
	wave_berubah.emit(wave, zombie_hidup)


# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------

## Paket awal untuk pemain baru. Tanpa ini pemain tidak punya peluru sama
## sekali di malam pertama dan tidak bisa membunuh zombie (deadlock).
func beri_paket_awal() -> void:
	peluru["9mm"] = 24
	_kirim_semua_sinyal()


func reset_penuh() -> void:
	minyak = 0
	logam = 0
	obat = 0
	uang = 0
	peluru = {"9mm": 0}
	hp_pemain = HP_PEMAIN_MAKS
	hp_bunker = HP_BUNKER_MAKS
	wave = 1
	zombie_hidup = 0
	zombie_total_wave = 0
	wave_aktif = false
	listrik = 0.0
	generator_aktif = false
	antrean_pabrik.clear()
	harga_minyak = Ekonomi.HARGA_DASAR
	sisa_refresh_harga = JEDA_REFRESH_HARGA
	statistik = {"zombie_dibunuh": 0, "minyak_terkumpul": 0, "uang_didapat": 0, "peluru_dibuat": 0}
	_kirim_semua_sinyal()


func _kirim_semua_sinyal() -> void:
	resource_berubah.emit()
	peluru_berubah.emit("9mm", int(peluru.get("9mm", 0)))
	hp_pemain_berubah.emit(hp_pemain, HP_PEMAIN_MAKS)
	hp_bunker_berubah.emit(hp_bunker, HP_BUNKER_MAKS)
	listrik_berubah.emit(listrik, LISTRIK_MAKS)
	wave_berubah.emit(wave, zombie_hidup)
	pabrik_berubah.emit()
	generator_berubah.emit()


# ---------------------------------------------------------------------------
# Simpan / muat
# ---------------------------------------------------------------------------

func ke_dict() -> Dictionary:
	return {
		"minyak": minyak,
		"logam": logam,
		"obat": obat,
		"uang": uang,
		"peluru": peluru.duplicate(),
		"hp_pemain": hp_pemain,
		"hp_bunker": hp_bunker,
		"wave": wave,
		"listrik": listrik,
		"generator_aktif": generator_aktif,
		"antrean_pabrik": antrean_pabrik.duplicate(true),
		"harga_minyak": harga_minyak,
		"sisa_refresh_harga": sisa_refresh_harga,
		"statistik": statistik.duplicate(),
	}


func dari_dict(data: Dictionary) -> void:
	minyak = int(data.get("minyak", 0))
	logam = int(data.get("logam", 0))
	obat = int(data.get("obat", 0))
	uang = int(data.get("uang", 0))

	var peluru_masuk: Dictionary = data.get("peluru", {})
	for kaliber in peluru_masuk.keys():
		peluru[str(kaliber)] = int(peluru_masuk[kaliber])

	hp_pemain = float(data.get("hp_pemain", HP_PEMAIN_MAKS))
	hp_bunker = float(data.get("hp_bunker", HP_BUNKER_MAKS))
	wave = maxi(1, int(data.get("wave", 1)))
	listrik = float(data.get("listrik", 0.0))
	generator_aktif = bool(data.get("generator_aktif", false))

	antrean_pabrik.clear()
	for item in data.get("antrean_pabrik", []):
		if item is Dictionary and item.has("kaliber"):
			antrean_pabrik.append({"kaliber": str(item["kaliber"]), "sisa": float(item.get("sisa", 0.0))})

	harga_minyak = float(data.get("harga_minyak", Ekonomi.HARGA_DASAR))
	sisa_refresh_harga = float(data.get("sisa_refresh_harga", JEDA_REFRESH_HARGA))

	var stat: Dictionary = data.get("statistik", {})
	for kunci in statistik.keys():
		statistik[kunci] = int(stat.get(kunci, 0))

	_kirim_semua_sinyal()
