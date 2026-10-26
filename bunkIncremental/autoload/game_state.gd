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
signal hp_pagar_berubah(sekarang: float, maks: float)
signal listrik_berubah(sekarang: float, maks: float)
signal wave_berubah(nomor: int, sisa: int)
signal pabrik_berubah
signal generator_berubah
signal pesan(teks: String, warna: Color)
signal fase_berubah(fase: String)
signal level_selesai(level: int)

## --- Nilai DASAR -----------------------------------------------------------
## Ini BUKAN angka yang dipakai game. Skill tree bisa menambah atau mengurangi
## semuanya, jadi sistem lain wajib memanggil fungsi turunan di bawah
## (hp_bunker_maks(), listrik_maks(), dst). Memakai konstanta ini langsung
## adalah cara paling gampang bikin HUD menampilkan "125 / 100".
const HP_PEMAIN_MAKS := 100.0
const HP_BUNKER_DASAR := 100.0
const POWER_MAKS_DASAR := 30.0
const JEDA_REFRESH_DASAR := 60.0
const SLOT_ANTREAN_DASAR := 5
const PAGAR_HP_DASAR := 200.0

## Generator mengisi baterai sebesar 5 power/detik, tapi bahan bakar dibakar
## SEBANDING dengan daya yang benar-benar masuk. Dengan begitu 1 crude oil
## selalu menghasilkan tepat power_per_oil() — tidak ada yang terbuang saat
## baterai hampir penuh.
const LAJU_DAYA := 5.0
const POWER_PER_OIL_DASAR := 10.0

# --- Resource ---
var minyak: int = 0
var logam: int = 0
var obat: int = 0
var uang: int = 0

# --- Amunisi (kaliber -> jumlah) ---
var peluru: Dictionary = {"9mm": 0}

# --- Kondisi ---
var hp_pemain: float = HP_PEMAIN_MAKS
var hp_bunker: float = HP_BUNKER_DASAR
## HP pagar. 0 berarti pagar jebol dan zombie langsung menuju pintu bunker.
var hp_pagar: float = PAGAR_HP_DASAR

# --- Wave ---
var wave: int = 1
var zombie_hidup: int = 0
var zombie_total_wave: int = 0
var wave_aktif: bool = false

## Status fase: "siang" = belum mulai level, "malam" = level aktif (zombie ada).
var fase: String = "siang"
## Level yang sedang dimainkan (1 = tutorial).
var level_aktif: int = 0
## Wave ke berapa di dalam level ini (1-based).
var wave_dalam_level: int = 0
## Berapa wave total level ini.
var wave_total_level: int = 0

# --- Listrik & pabrik ---
var listrik: float = 0.0
var generator_aktif: bool = false
var antrean_pabrik: Array = []
## Minyak pecahan yang sudah masuk ke mesin tapi belum mencapai 1 unit.
var _sisa_bara: float = 0.0
## "stopped" | "idle" | "running"
var _status_generator: String = "stopped"
## Laju daya yang masuk ke baterai pada tick terakhir (power/detik).
## Dipakai UI untuk menampilkan konsumsi minyak yang sebenarnya.
var _laju_daya_terakhir: float = 0.0

# --- Pasar ---
var harga_minyak: float = Ekonomi.HARGA_DASAR
var sisa_refresh_harga: float = JEDA_REFRESH_DASAR
var tren_harga: String = "flat"

# --- Statistik (untuk layar akhir / prestige nanti) ---
var statistik: Dictionary = {
	"zombie_dibunuh": 0,
	"minyak_terkumpul": 0,
	"minyak_terbakar": 0,
	"daya_terpakai": 0.0,
	"uang_didapat": 0,
	"peluru_dibuat": 0,
}

## HP maksimum terakhir yang sudah disinkronkan. Dipakai untuk memberi bonus
## HP saat skill menambah kapasitas bunker.
var _hp_bunker_maks_terakhir: float = HP_BUNKER_DASAR
var _hp_pagar_maks_terakhir: float = PAGAR_HP_DASAR


# ---------------------------------------------------------------------------
# Nilai turunan skill
#
# Semua angka yang bisa dipengaruhi skill dihitung di sini. Jangan menyimpannya
# di variabel global — hitung ulang saat dipakai, supaya tidak ada angka basi
# setelah pemain membeli skill.
# ---------------------------------------------------------------------------

func hp_bunker_maks() -> float:
	return HP_BUNKER_DASAR + SkillTree.efek_total("hp_bunker_tambah")


func listrik_maks() -> float:
	return POWER_MAKS_DASAR + SkillTree.efek_total("listrik_maks_tambah")


func listrik_per_bara() -> float:
	return POWER_PER_OIL_DASAR + SkillTree.efek_total("power_per_oil_tambah")


func kapasitas_antrean() -> int:
	return SLOT_ANTREAN_DASAR + int(SkillTree.efek_total("slot_pabrik_tambah"))


func jeda_refresh_harga() -> float:
	var persen := SkillTree.efek_total("refresh_harga_persen")
	return maxf(5.0, JEDA_REFRESH_DASAR * (1.0 + persen / 100.0))


func pagar_hp_maks() -> float:
	var persen := SkillTree.efek_total("hp_pagar_persen")
	return PAGAR_HP_DASAR * (1.0 + persen / 100.0)


## Pengali damage senjata pemain (1.0 = tanpa skill).
func pengali_damage() -> float:
	return 1.0 + SkillTree.efek_total("damage_persen") / 100.0


## Pengali waktu reload. < 1.0 berarti lebih cepat.
func pengali_reload() -> float:
	return maxf(0.25, 1.0 + SkillTree.efek_total("reload_persen") / 100.0)


## Pengali kecepatan produksi pabrik (1.0 = tanpa skill).
func pengali_kecepatan_produksi() -> float:
	return 1.0 + SkillTree.efek_total("kecepatan_produksi_persen") / 100.0


## Pengali jumlah peluru per batch produksi.
func pengali_hasil_produksi() -> float:
	return 1.0 + SkillTree.efek_total("hasil_persen") / 100.0


## Pengali harga jual minyak.
func pengali_harga_jual() -> float:
	return 1.0 + SkillTree.efek_total("harga_jual_persen") / 100.0


## Harga per unit yang benar-benar diterima pemain (sudah termasuk skill).
func harga_jual_efektif() -> float:
	return harga_minyak * pengali_harga_jual()


## Nilai jual sejumlah minyak pada harga efektif saat ini.
func nilai_jual(jumlah: int) -> int:
	return Ekonomi.nilai_jual(jumlah, harga_jual_efektif())


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hp_bunker_maks_terakhir = hp_bunker_maks()
	_hp_pagar_maks_terakhir = pagar_hp_maks()
	SkillTree.skill_berubah.connect(_on_skill_berubah)


## Saat skill berubah, kapasitas bunker bisa naik. Beri selisihnya sebagai HP
## gratis supaya membeli upgrade tidak terasa seperti penalti.
func _on_skill_berubah() -> void:
	var baru := hp_bunker_maks()
	var selisih := baru - _hp_bunker_maks_terakhir
	if selisih > 0.0 and hp_bunker > 0.0:
		hp_bunker = minf(baru, hp_bunker + selisih)
	_hp_bunker_maks_terakhir = baru
	hp_bunker_berubah.emit(hp_bunker, baru)

	# Barbed Wire menambah ketahanan pagar. Kalau pagar masih berdiri, beri
	# bonus HP yang sama supaya upgrade tidak terasa seperti penalti.
	var pagar_baru := pagar_hp_maks()
	if hp_pagar > 0.0:
		hp_pagar = minf(pagar_baru, hp_pagar + maxf(0.0, pagar_baru - _hp_pagar_maks_terakhir))
	_hp_pagar_maks_terakhir = pagar_baru
	hp_pagar_berubah.emit(hp_pagar, pagar_baru)

	listrik_berubah.emit(listrik, listrik_maks())


func _process(delta: float) -> void:
	_tick_pasar(delta)
	_tick_generator(delta)
	_tick_pabrik(delta)
	_tick_regen(delta)


## Auto Patch: memulihkan HP bunker sedikit demi sedikit.
func _tick_regen(delta: float) -> void:
	var laju := SkillTree.efek_total("regen_bunker")
	if laju <= 0.0:
		return
	var maks := hp_bunker_maks()
	if hp_bunker >= maks - 0.01:
		return
	hp_bunker = minf(maks, hp_bunker + laju * delta)
	hp_bunker_berubah.emit(hp_bunker, maks)


# ---------------------------------------------------------------------------
# Tick sistem
# ---------------------------------------------------------------------------

func _tick_pasar(delta: float) -> void:
	sisa_refresh_harga -= delta
	if sisa_refresh_harga > 0.0:
		return
	sisa_refresh_harga += jeda_refresh_harga()
	var lama := harga_minyak
	harga_minyak = Ekonomi.harga_berikutnya(lama)
	tren_harga = Ekonomi.tren(lama, harga_minyak)


func _tick_generator(delta: float) -> void:
	if not generator_aktif:
		return

	# Baterai penuh: generator tetap menyala tapi tidak membakar apa pun.
	var ruang := listrik_maks() - listrik
	if ruang <= 0.001:
		_laju_daya_terakhir = 0.0
		_set_status_generator("idle")
		return

	# _sisa_bara = bahan bakar yang SUDAH terbakar tapi belum dipotong dari
	# stok (pecahan menuju 1 unit). Jadi yang benar-benar tersisa adalah
	# minyak - _sisa_bara, BUKAN minyak + _sisa_bara. Versi lama memakai
	# penjumlahan; akibatnya saat minyak = 1 dan pecahan 0.8, satu tick bisa
	# membakar 0.8 lagi dan menghasilkan minyak = -1 (ditemukan lewat
	# simulator 20 menit).
	var tersedia := maxf(0.0, float(minyak) - _sisa_bara)
	if tersedia <= 0.0001:
		_sisa_bara = 0.0
		_laju_daya_terakhir = 0.0
		generator_aktif = false
		_set_status_generator("stopped")
		pesan.emit("Generator stopped — out of crude oil", Color(1.0, 0.45, 0.3))
		return

	# Daya dibatasi oleh ruang baterai; bahan bakar dihitung DARI daya itu,
	# bukan dari waktu. Inilah yang membuat 1 oil selalu = 10 power.
	var daya := minf(LAJU_DAYA * delta, ruang)
	var bakar := minf(daya / listrik_per_bara(), tersedia)
	daya = bakar * listrik_per_bara()

	# Kumpulkan pecahan minyak, potong stok hanya saat sudah genap 1 unit.
	_sisa_bara += bakar
	while _sisa_bara >= 1.0:
		_sisa_bara -= 1.0
		minyak -= 1
		statistik["minyak_terbakar"] += 1
		resource_berubah.emit()

	# Jaring pengaman: stok tidak boleh minus walau ada pembulatan aneh.
	if minyak < 0:
		minyak = 0
		_sisa_bara = 0.0

	_laju_daya_terakhir = daya / maxf(delta, 0.0001)
	listrik = minf(listrik + daya, listrik_maks())
	listrik_berubah.emit(listrik, listrik_maks())
	_set_status_generator("running")


## Status generator untuk UI: "stopped", "idle" (baterai penuh), "running".
func status_generator() -> String:
	if not generator_aktif:
		return "stopped"
	if listrik >= listrik_maks() - 0.001:
		return "idle"
	return "running"


## Perkiraan konsumsi minyak per detik saat ini, berdasarkan laju pengisian
## daya yang benar-benar terjadi pada tick terakhir.
func konsumsi_minyak_per_detik() -> float:
	if not generator_aktif:
		return 0.0
	if status_generator() == "idle":
		return 0.0
	return _laju_daya_terakhir / listrik_per_bara()


func _set_status_generator(baru: String) -> void:
	if _status_generator == baru:
		return
	_status_generator = baru
	generator_berubah.emit()


func _tick_pabrik(delta: float) -> void:
	if antrean_pabrik.is_empty():
		return

	# Overclock mempercepat proses, bukan menghemat daya: konsumsi per peluru
	# tetap sama karena Produksi.proses memakai delta yang sama untuk waktu
	# dan daya.
	var delta_pabrik := delta * pengali_kecepatan_produksi()
	var hasil := Produksi.proses(antrean_pabrik, delta_pabrik, listrik, Data.resep_peluru)

	if float(hasil["daya_terpakai"]) > 0.0:
		listrik = maxf(0.0, listrik - float(hasil["daya_terpakai"]))
		statistik["daya_terpakai"] += float(hasil["daya_terpakai"])
		listrik_berubah.emit(listrik, listrik_maks())

	for kaliber in hasil["selesai"]:
		var resep: ResepPeluru = Data.resep_peluru.get(kaliber)
		if resep == null:
			continue
		# Salvage Press menambah jumlah per batch, bukan mengurangi scrap.
		var jumlah := maxi(1, int(round(resep.hasil * pengali_hasil_produksi())))
		tambah_peluru(kaliber, jumlah)
		statistik["peluru_dibuat"] += jumlah
		pesan.emit("+%d %s rounds produced" % [jumlah, kaliber], Color(0.6, 0.9, 0.6))

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
	var dapat := nilai_jual(banyak)
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
	hp_bunker_berubah.emit(hp_bunker, hp_bunker_maks())


func terima_damage_pagar(jumlah: float) -> void:
	if hp_pagar <= 0.0:
		return
	hp_pagar = maxf(0.0, hp_pagar - jumlah)
	hp_pagar_berubah.emit(hp_pagar, pagar_hp_maks())
	if hp_pagar <= 0.0:
		pesan.emit("The fence is down! Zombies are at the door", Color(1.0, 0.32, 0.26))


func pagar_hidup() -> bool:
	return SkillTree.sudah_dimiliki("barbed_wire") and hp_pagar > 0.0


func perbaiki_pagar(jumlah: float) -> void:
	var maks := pagar_hp_maks()
	hp_pagar = minf(maks, hp_pagar + jumlah)
	hp_pagar_berubah.emit(hp_pagar, maks)


## Biaya membangun ulang pagar. Lebih murah kalau hanya perlu menambal,
## lebih mahal kalau pagar sudah rata dengan tanah.
func biaya_perbaikan_pagar() -> int:
	var maks := pagar_hp_maks()
	var kurang := maks - hp_pagar
	if kurang <= 0.5:
		return 0
	if hp_pagar <= 0.0:
		return 40 + wave * 6
	# Menambal sebagian: harga proporsional terhadap kerusakan.
	return maxi(5, int(ceil(kurang / maks * (30 + wave * 4))))


func beli_perbaikan_pagar() -> float:
	var maks := pagar_hp_maks()
	var kurang := maks - hp_pagar
	if kurang <= 0.5:
		pesan.emit("The fence is already intact", Color(0.7, 0.75, 0.82))
		return 0.0

	var biaya := biaya_perbaikan_pagar()
	if uang < biaya:
		pesan.emit("Not enough money to rebuild the fence", Color(1.0, 0.6, 0.3))
		return 0.0

	uang -= biaya
	perbaiki_pagar(kurang)
	resource_berubah.emit()
	pesan.emit("Fence repaired +%d HP" % int(kurang), Color(0.6, 0.9, 0.6))
	return kurang


func perbaiki_bunker(jumlah: float) -> void:
	hp_bunker = minf(hp_bunker_maks(), hp_bunker + jumlah)
	hp_bunker_berubah.emit(hp_bunker, hp_bunker_maks())


## Biaya perbaikan naik seiring wave, supaya memperbaiki bunker terasa
## seperti keputusan ekonomi dan bukan tombol gratis.
func biaya_perbaikan() -> int:
	return 10 + wave * 3


## Beli perbaikan bunker sebanyak `jumlah` HP. Mengembalikan HP yang didapat.
func beli_perbaikan(jumlah: float) -> float:
	var kurang := hp_bunker_maks() - hp_bunker
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
	if Produksi.sisa_slot(antrean_pabrik, kapasitas_antrean()) <= 0:
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
	if aktif and minyak <= 0 and _sisa_bara <= 0.0001:
		pesan.emit("No crude oil to burn", Color(1.0, 0.6, 0.3))
		return
	generator_aktif = aktif
	if not aktif:
		_sisa_bara = 0.0
		_laju_daya_terakhir = 0.0
	_set_status_generator(status_generator())


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
	_hp_bunker_maks_terakhir = hp_bunker_maks()
	hp_bunker = hp_bunker_maks()
	_hp_pagar_maks_terakhir = pagar_hp_maks()
	hp_pagar = pagar_hp_maks()
	wave = 1
	zombie_hidup = 0
	zombie_total_wave = 0
	wave_aktif = false
	listrik = 0.0
	generator_aktif = false
	_sisa_bara = 0.0
	_status_generator = "stopped"
	_laju_daya_terakhir = 0.0
	antrean_pabrik.clear()
	harga_minyak = Ekonomi.HARGA_DASAR
	sisa_refresh_harga = jeda_refresh_harga()
	statistik = {
		"zombie_dibunuh": 0,
		"minyak_terkumpul": 0,
		"minyak_terbakar": 0,
		"daya_terpakai": 0.0,
		"uang_didapat": 0,
		"peluru_dibuat": 0,
	}
	_kirim_semua_sinyal()


func _kirim_semua_sinyal() -> void:
	resource_berubah.emit()
	peluru_berubah.emit("9mm", int(peluru.get("9mm", 0)))
	hp_pemain_berubah.emit(hp_pemain, HP_PEMAIN_MAKS)
	hp_bunker_berubah.emit(hp_bunker, hp_bunker_maks())
	hp_pagar_berubah.emit(hp_pagar, pagar_hp_maks())
	listrik_berubah.emit(listrik, listrik_maks())
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
		"hp_pagar": hp_pagar,
		"wave": wave,
		"listrik": listrik,
		"generator_aktif": generator_aktif,
		"sisa_bara": _sisa_bara,
		"antrean_pabrik": antrean_pabrik.duplicate(true),
		"harga_minyak": harga_minyak,
		"sisa_refresh_harga": sisa_refresh_harga,
		"statistik": statistik.duplicate(),
		"skill_dimiliki": SkillTree.ke_array(),
	}


func dari_dict(data: Dictionary) -> void:
	# Skill dimuat lebih dulu: hp_bunker_maks(), listrik_maks(), dan
	# jeda_refresh_harga() bergantung padanya, jadi kalau urutannya kebalik
	# nilai HP/power bisa dipotong memakai kapasitas lama.
	SkillTree.dari_array(data.get("skill_dimiliki", []))
	_hp_bunker_maks_terakhir = hp_bunker_maks()

	minyak = int(data.get("minyak", 0))
	logam = int(data.get("logam", 0))
	obat = int(data.get("obat", 0))
	uang = int(data.get("uang", 0))

	var peluru_masuk: Dictionary = data.get("peluru", {})
	for kaliber in peluru_masuk.keys():
		peluru[str(kaliber)] = int(peluru_masuk[kaliber])

	hp_pemain = float(data.get("hp_pemain", HP_PEMAIN_MAKS))
	hp_bunker = float(data.get("hp_bunker", hp_bunker_maks()))
	# Save v1/v2 tidak punya pagar; pemain lama langsung mendapat pagar penuh.
	_hp_pagar_maks_terakhir = pagar_hp_maks()
	hp_pagar = float(data.get("hp_pagar", pagar_hp_maks()))
	wave = maxi(1, int(data.get("wave", 1)))
	listrik = float(data.get("listrik", 0.0))
	generator_aktif = bool(data.get("generator_aktif", false))
	# Save v1 tidak punya field ini; default 0.0 supaya tetap kompatibel.
	_sisa_bara = float(data.get("sisa_bara", 0.0))
	_laju_daya_terakhir = 0.0
	_status_generator = "stopped"
	if generator_aktif:
		_status_generator = "idle" if listrik >= listrik_maks() - 0.001 else "running"

	antrean_pabrik.clear()
	for item in data.get("antrean_pabrik", []):
		if item is Dictionary and item.has("kaliber"):
			antrean_pabrik.append({"kaliber": str(item["kaliber"]), "sisa": float(item.get("sisa", 0.0))})

	harga_minyak = float(data.get("harga_minyak", Ekonomi.HARGA_DASAR))
	sisa_refresh_harga = float(data.get("sisa_refresh_harga", jeda_refresh_harga()))

	var stat: Dictionary = data.get("statistik", {})
	for kunci in statistik.keys():
		# daya_terpakai berupa pecahan, sisanya bilangan bulat.
		if kunci == "daya_terpakai":
			statistik[kunci] = float(stat.get(kunci, 0.0))
		else:
			statistik[kunci] = int(stat.get(kunci, 0))

	_kirim_semua_sinyal()
