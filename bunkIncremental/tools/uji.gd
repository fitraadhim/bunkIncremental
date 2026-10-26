extends Node
## Uji otomatis logika inti. Jalankan:
##   godot --headless --path . tools/uji.tscn
##
## Kalau semua lolos, exit code 0. Kalau ada yang gagal, exit code 1.

var _lulus: int = 0
var _gagal: int = 0


func _ready() -> void:
	print("=== BUNKER INCREMENTAL — TEST SUITE ===")

	_uji_ekonomi()
	_uji_produksi()
	_uji_formatter()
	_uji_skill()
	_uji_pagar()
	await _uji_interior()
	_uji_game_state()
	await _uji_combat()

	print("--------------------------------------")
	print("LULUS: %d   GAGAL: %d" % [_lulus, _gagal])
	if _gagal > 0:
		print("HASIL: GAGAL")
		get_tree().quit(1)
	else:
		print("HASIL: SEMUA LOLOS")
		get_tree().quit(0)


# ---------------------------------------------------------------------------

func _cek(nama: String, kondisi: bool, detail: String = "") -> void:
	if kondisi:
		_lulus += 1
		print("  [OK]   %s" % nama)
	else:
		_gagal += 1
		print("  [FAIL] %s %s" % [nama, detail])


func _cek_dekat(nama: String, nilai: float, harapan: float, toleransi: float = 0.001) -> void:
	_cek(nama, absf(nilai - harapan) <= toleransi, "(dapat %.4f, harap %.4f)" % [nilai, harapan])


# ---------------------------------------------------------------------------

func _uji_ekonomi() -> void:
	print("\n[Ekonomi]")

	var harga := Ekonomi.HARGA_DASAR
	for i in range(500):
		harga = Ekonomi.harga_berikutnya(harga)
		if harga < Ekonomi.HARGA_MIN or harga > Ekonomi.HARGA_MAKS:
			break
	_cek("harga selalu di dalam batas", harga >= Ekonomi.HARGA_MIN and harga <= Ekonomi.HARGA_MAKS,
		"(dapat %.2f)" % harga)

	_cek("jual 0 minyak = 0 uang", Ekonomi.nilai_jual(0, 2.0) == 0)
	_cek("jual 10 minyak @2.0 = 20", Ekonomi.nilai_jual(10, 2.0) == 20)
	_cek("jual 3 minyak @1.55 = 4 (dibulatkan bawah)", Ekonomi.nilai_jual(3, 1.55) == 4)
	_cek("tren naik", Ekonomi.tren(2.0, 2.5) == "up")
	_cek("tren turun", Ekonomi.tren(2.5, 2.0) == "down")
	_cek("tren datar", Ekonomi.tren(2.0, 2.0) == "flat")


func _uji_produksi() -> void:
	print("\n[Produksi]")

	var resep_map: Dictionary = Data.resep_peluru
	var resep: ResepPeluru = resep_map["9mm"]
	var antrean: Array = [Produksi.buat_item(resep)]

	_cek_dekat("item baru punya sisa waktu penuh", float(antrean[0]["sisa"]), resep.waktu)

	# Tanpa daya: tidak ada progres.
	var hasil := Produksi.proses(antrean, 0.5, 0.0, resep_map)
	_cek("tanpa daya tidak ada progres", float(antrean[0]["sisa"]) == resep.waktu)
	_cek_dekat("tanpa daya tidak memakai listrik", float(hasil["daya_terpakai"]), 0.0)

	# Dengan daya: progres jalan.
	hasil = Produksi.proses(antrean, 0.5, 10.0, resep_map)
	_cek_dekat("dengan daya progres jalan", float(antrean[0]["sisa"]), resep.waktu - 0.5)
	_cek_dekat("konsumsi listrik sesuai resep", float(hasil["daya_terpakai"]), resep.listrik * 0.5)

	# Selesaikan.
	hasil = Produksi.proses(antrean, 5.0, 10.0, resep_map)
	_cek("antrean selesai mengembalikan kaliber", hasil["selesai"].has("9mm"))
	_cek("antrean kosong setelah selesai", antrean.is_empty())

	_cek("sisa slot awal = batas", Produksi.sisa_slot([], 5) == 5)
	_cek("sisa slot penuh = 0", Produksi.sisa_slot([{}, {}, {}, {}, {}], 5) == 0)

	var antrean2: Array = [Produksi.buat_item(resep)]
	Produksi.proses(antrean2, 1.0, 10.0, resep_map)
	_cek_dekat("progres 50%", Produksi.progres(antrean2, resep_map), 0.5, 0.01)


func _uji_formatter() -> void:
	print("\n[Formatter]")
	_cek("42 tetap 42", Formatter.angka(42) == "42")
	_cek("999 tetap 999", Formatter.angka(999) == "999")
	_cek("1000 jadi 1.00K", Formatter.angka(1000) == "1.00K", "(dapat %s)" % Formatter.angka(1000))
	_cek("1_234_567 jadi 1.23M", Formatter.angka(1234567) == "1.23M", "(dapat %s)" % Formatter.angka(1234567))
	_cek("harga 2 desimal", Formatter.harga(2.1) == "2.10")
	_cek("waktu 65 detik = 1:05", Formatter.waktu(65.0) == "1:05")


# ---------------------------------------------------------------------------

func _uji_skill() -> void:
	print("\n[Skill]")

	SkillTree.reset()
	GameState.reset_penuh()
	GameState.uang = 0

	# --- Katalog ---
	_cek("pohon punya 15 skill", SkillTree.semua().size() == 15,
		"(dapat %d)" % SkillTree.semua().size())
	_cek("ada 5 cabang", SkillTree.DAFTAR_CABANG.size() == 5)
	var per_cabang_lengkap := true
	for cabang in SkillTree.DAFTAR_CABANG:
		if SkillTree.per_cabang(cabang).size() != 3:
			per_cabang_lengkap = false
	_cek("tiap cabang punya 3 tier", per_cabang_lengkap)

	# --- Tanpa skill, nilai turunan = nilai dasar ---
	_cek_dekat("tanpa skill HP bunker = 100", GameState.hp_bunker_maks(), 100.0)
	_cek_dekat("tanpa skill baterai = 30", GameState.listrik_maks(), 30.0)
	_cek_dekat("tanpa skill power per oil = 10", GameState.listrik_per_bara(), 10.0)
	_cek("tanpa skill slot antrean = 5", GameState.kapasitas_antrean() == 5)
	_cek_dekat("tanpa skill jeda pasar = 60", GameState.jeda_refresh_harga(), 60.0)
	_cek_dekat("tanpa skill pengali damage = 1", GameState.pengali_damage(), 1.0)

	# --- Uang kurang ---
	_cek("tidak bisa beli tanpa uang", SkillTree.bisa_beli("steady_aim") == false)
	_cek("alasan: uang", SkillTree.alasan_tidak_bisa("steady_aim") == "uang")
	_cek("beli gagal tanpa uang", SkillTree.beli("steady_aim") == false)
	_cek("skill tidak masuk daftar", SkillTree.sudah_dimiliki("steady_aim") == false)

	# --- Prasyarat ---
	GameState.uang = 99999
	_cek("tier 2 terkunci sebelum tier 1",
		SkillTree.alasan_tidak_bisa("quick_hands") == "prasyarat")
	_cek("beli tier 1 berhasil", SkillTree.beli("steady_aim") == true)
	_cek("skill tercatat dimiliki", SkillTree.sudah_dimiliki("steady_aim"))
	_cek("tidak bisa beli dua kali", SkillTree.alasan_tidak_bisa("steady_aim") == "dimiliki")
	_cek_dekat("Steady Aim +20% damage", GameState.pengali_damage(), 1.2)
	_cek("uang terpotong sesuai biaya", GameState.uang == 99999 - 120,
		"(dapat %d)" % GameState.uang)

	# --- Efek bertumpuk ---
	_cek("beli tier 2 setelah prasyarat", SkillTree.beli("quick_hands") == true)
	_cek_dekat("Quick Hands reload -25%", GameState.pengali_reload(), 0.75)

	# --- Efek yang mengubah kapasitas ---
	var hp_sebelum := GameState.hp_bunker
	_cek("beli Reinforced Door", SkillTree.beli("reinforced_door") == true)
	_cek_dekat("HP bunker maks jadi 125", GameState.hp_bunker_maks(), 125.0)
	_cek_dekat("HP bunker ikut naik 25", GameState.hp_bunker, hp_sebelum + 25.0, 0.01)

	_cek("beli Second Line", SkillTree.beli("second_line") == true)
	_cek("slot antrean jadi 6", GameState.kapasitas_antrean() == 6)

	_cek("beli Haggler", SkillTree.beli("haggler") == true)
	_cek_dekat("harga jual +10%", GameState.pengali_harga_jual(), 1.1)
	_cek_dekat("harga efektif ikut naik", GameState.harga_jual_efektif(),
		GameState.harga_minyak * 1.1)

	# --- Jual minyak memakai harga efektif ---
	GameState.minyak = 10
	GameState.harga_minyak = 2.0
	var dapat := GameState.jual_minyak(10)
	_cek("jual 10 oil @2.0 x1.1 = $22", dapat == 22, "(dapat %d)" % dapat)

	# --- Baterai & power per oil ---
	_cek("beli Tower Access", SkillTree.beli("tower_access") == true)
	_cek_dekat("Tower Access membuka lantai 2", SkillTree.efek_total("buka_lantai_2"), 1.0)
	_cek("beli Fuel Injector", SkillTree.beli("fuel_injector") == true)
	_cek_dekat("power per oil jadi 12", GameState.listrik_per_bara(), 12.0)
	_cek("beli Backup Generator", SkillTree.beli("backup_generator") == true)
	_cek_dekat("baterai jadi 45", GameState.listrik_maks(), 45.0)

	# --- Generator memakai power per oil yang baru ---
	GameState.listrik = 0.0
	GameState.minyak = 10
	GameState._sisa_bara = 0.0
	GameState.antrean_pabrik.clear()
	GameState.set_generator(true)
	for i in range(100):
		GameState._tick_generator(0.1)
	# 90 tick x 0.5 power = 45 power (baterai penuh), 45/12 = 3.75 oil
	# -> 3 oil terpotong, 0.75 masih di mesin.
	_cek("generator memakai power per oil baru",
		GameState.minyak == 7, "(dapat %d)" % GameState.minyak)
	_cek_dekat("baterai terisi sampai 45", GameState.listrik, 45.0, 0.5)
	GameState.set_generator(false)

	# --- Efek produksi ---
	_cek("beli Salvage Press", SkillTree.beli("scrap_saver") == true)
	_cek_dekat("hasil produksi +25%", GameState.pengali_hasil_produksi(), 1.25)
	_cek("beli Overclock", SkillTree.beli("overclock") == true)
	_cek_dekat("kecepatan produksi +30%", GameState.pengali_kecepatan_produksi(), 1.3)

	GameState.reset_penuh()
	GameState.logam = 10
	GameState.listrik = 45.0
	GameState.peluru["9mm"] = 0
	GameState.antre_peluru("9mm")
	var sebelum_produksi := GameState.jumlah_peluru("9mm")
	for i in range(20):
		GameState._tick_pabrik(0.1)
	# 2 detik / 1.3 = 1.54 detik -> selesai dalam 2 detik, hasil 5 x 1.25 = 6
	_cek("produksi selesai lebih cepat", GameState.antrean_pabrik.is_empty())
	_cek("hasil batch jadi 6 peluru", GameState.jumlah_peluru("9mm") - sebelum_produksi == 6,
		"(dapat %d)" % (GameState.jumlah_peluru("9mm") - sebelum_produksi))

	# --- Simpan / muat skill ---
	GameState.uang = 500
	var dict := GameState.ke_dict()
	_cek("save menyimpan daftar skill", dict.has("skill_dimiliki"))
	var jumlah_skill := SkillTree.jumlah_dimiliki()
	SkillTree.reset()
	_cek("reset mengosongkan skill", SkillTree.jumlah_dimiliki() == 0)
	GameState.dari_dict(dict)
	_cek("muat mengembalikan skill", SkillTree.jumlah_dimiliki() == jumlah_skill,
		"(dapat %d, harap %d)" % [SkillTree.jumlah_dimiliki(), jumlah_skill])
	_cek_dekat("efek pulih setelah muat", GameState.hp_bunker_maks(), 125.0)
	_cek_dekat("baterai pulih setelah muat", GameState.listrik_maks(), 45.0)

	# --- Save lama tanpa field skill tetap aman ---
	SkillTree.reset()
	var dict_lama := GameState.ke_dict()
	dict_lama.erase("skill_dimiliki")
	GameState.dari_dict(dict_lama)
	_cek("save tanpa skill_dimiliki tidak error", SkillTree.jumlah_dimiliki() == 0)
	_cek_dekat("save lama: HP bunker kembali 100", GameState.hp_bunker_maks(), 100.0)

	SkillTree.reset()
	GameState.reset_penuh()


# ---------------------------------------------------------------------------

func _uji_pagar() -> void:
	print("\n[Pagar]")

	SkillTree.reset()
	GameState.reset_penuh()

	# --- Kondisi awal ---
	_cek_dekat("pagar mulai penuh", GameState.hp_pagar, 200.0)
	_cek("pagar dianggap hidup", GameState.pagar_hidup())
	_cek("tidak perlu perbaikan saat penuh", GameState.biaya_perbaikan_pagar() == 0)

	# --- Menerima damage ---
	GameState.terima_damage_pagar(30.0)
	_cek_dekat("damage pagar 30 -> 170", GameState.hp_pagar, 170.0)
	_cek("pagar masih hidup", GameState.pagar_hidup())
	var biaya_rusak := GameState.biaya_perbaikan_pagar()
	_cek("perbaikan sebagian berbiaya", biaya_rusak > 0, "(dapat %d)" % biaya_rusak)

	# --- Jebol ---
	GameState.terima_damage_pagar(500.0)
	_cek_dekat("HP pagar tidak negatif", GameState.hp_pagar, 0.0)
	_cek("pagar jebol", GameState.pagar_hidup() == false)
	var biaya_jebol := GameState.biaya_perbaikan_pagar()
	_cek("bangun ulang lebih mahal daripada menambal", biaya_jebol > biaya_rusak,
		"(jebol %d, tambal %d)" % [biaya_jebol, biaya_rusak])

	# --- Damage saat sudah jebol tidak error ---
	GameState.terima_damage_pagar(10.0)
	_cek_dekat("damage saat jebol diabaikan", GameState.hp_pagar, 0.0)

	# --- Uang kurang ---
	GameState.uang = 0
	var hp_sebelum := GameState.hp_pagar
	_cek_dekat("tidak bisa bangun tanpa uang", GameState.beli_perbaikan_pagar(), 0.0)
	_cek_dekat("HP pagar tidak berubah", GameState.hp_pagar, hp_sebelum)

	# --- Bangun ulang ---
	GameState.uang = 500
	var didapat := GameState.beli_perbaikan_pagar()
	_cek_dekat("bangun ulang mengembalikan HP penuh", GameState.hp_pagar, 200.0)
	_cek_dekat("HP yang didapat = 200", didapat, 200.0)
	_cek("uang terpotong", GameState.uang == 500 - biaya_jebol,
		"(dapat %d, harap %d)" % [GameState.uang, 500 - biaya_jebol])
	_cek("tidak bisa bayar dua kali saat penuh", GameState.biaya_perbaikan_pagar() == 0)

	# --- Barbed Wire menambah ketahanan ---
	GameState.uang = 99999
	SkillTree.beli("reinforced_door")
	SkillTree.beli("barbed_wire")
	_cek_dekat("Barbed Wire +60% HP pagar", GameState.pagar_hp_maks(), 320.0)
	_cek_dekat("HP pagar ikut naik", GameState.hp_pagar, 320.0)
	_cek("harga bangun ulang ikut naik", GameState.biaya_perbaikan_pagar() == 0)

	# --- Simpan / muat ---
	GameState.terima_damage_pagar(70.0)
	var dict := GameState.ke_dict()
	GameState.reset_penuh()
	GameState.dari_dict(dict)
	_cek_dekat("round-trip save: HP pagar", GameState.hp_pagar, 250.0)
	_cek_dekat("round-trip save: maks pagar", GameState.pagar_hp_maks(), 320.0)

	# --- Save lama tanpa hp_pagar ---
	SkillTree.reset()
	var dict_lama := GameState.ke_dict()
	dict_lama.erase("hp_pagar")
	GameState.dari_dict(dict_lama)
	_cek_dekat("save lama: pagar penuh", GameState.hp_pagar, 200.0)

	GameState.reset_penuh()


# ---------------------------------------------------------------------------

func _uji_interior() -> void:
	print("\n[Interior]")

	SkillTree.reset()
	GameState.reset_penuh()

	var utama = preload("res://scenes/main.tscn").instantiate()
	add_child(utama)
	await get_tree().process_frame

	var interior = utama.interior
	var pemain = utama.pemain
	_cek("node interior ada", interior != null)
	_cek("interior tersembunyi di awal", interior.visible == false)
	_cek("pemain mulai di luar", pemain.di_dalam == false)

	# --- Lantai 2 terkunci tanpa skill ---
	_cek("lantai 2 terkunci tanpa Tower Access", interior.lantai_2_terbuka() == false)

	# --- Masuk bunker ---
	utama._masuk_bunker()
	await get_tree().process_frame
	_cek("masuk: pemain di dalam", pemain.di_dalam == true)
	_cek("masuk: interior terlihat", interior.visible == true)
	_cek("masuk: dunia disembunyikan", utama.dunia.visible == false)
	_cek("masuk: pagar disembunyikan", utama.pagar.visible == false)
	_cek("masuk: mulai di lantai 1", pemain.lantai == 1)
	_cek_dekat("masuk: posisi Y lantai 1", pemain.global_position.y, interior.Y_LANTAI_1)

	# --- Tidak bisa menembak di dalam ---
	var peluru_sebelum := GameState.jumlah_peluru("9mm")
	pemain._coba_tembak()
	_cek("di dalam tidak bisa menembak", GameState.jumlah_peluru("9mm") == peluru_sebelum)

	# --- Naik tangga tetap gagal tanpa skill ---
	pemain.global_position = interior.posisi_turun()
	utama._tangani_tangga()
	_cek("tanpa skill tetap di lantai 1", pemain.lantai == 1)

	# --- Beli Tower Access, lalu naik ---
	GameState.uang = 9999
	SkillTree.beli("reinforced_door")
	SkillTree.beli("tower_access")
	_cek("Tower Access terbuka", interior.lantai_2_terbuka() == true)

	# _tangani_tangga membaca input; panggil logika lantai langsung.
	pemain.pindah_lantai(2, interior.posisi_naik())
	_cek("naik ke lantai 2", pemain.lantai == 2)
	_cek_dekat("posisi Y lantai 2", pemain.global_position.y, interior.Y_LANTAI_2)

	# --- Tidak bisa keluar dari lantai 2 ---
	utama._coba_keluar_bunker()
	_cek("tidak bisa keluar dari lantai 2", pemain.di_dalam == true)

	# --- Turun, lalu keluar dari pintu ---
	pemain.pindah_lantai(1, interior.posisi_turun())
	pemain.global_position = Vector2(400.0, interior.Y_LANTAI_1)
	utama._coba_keluar_bunker()
	_cek("tidak bisa keluar jauh dari pintu", pemain.di_dalam == true)

	pemain.global_position = Vector2(80.0, interior.Y_LANTAI_1)
	utama._coba_keluar_bunker()
	_cek("keluar: pemain di luar", pemain.di_dalam == false)
	_cek("keluar: interior tersembunyi", interior.visible == false)
	_cek("keluar: dunia terlihat", utama.dunia.visible == true)
	_cek_dekat("keluar: posisi Y dunia", pemain.global_position.y, utama.posisi_tanah_y)

	# --- Zona kasur ---
	_cek("zona kasur", interior.di_zona_kasur(200.0))
	_cek("bukan zona kasur", interior.di_zona_kasur(400.0) == false)

	# --- Regenerasi di kasur ---
	GameState.hp_pemain = 20.0
	utama._masuk_bunker()
	pemain.global_position = Vector2(200.0, interior.Y_LANTAI_1)
	pemain.lantai = 1
	var hp_awal := GameState.hp_pemain
	for i in range(20):
		interior._tick_kasur(0.1)
	_cek("kasur memulihkan HP", GameState.hp_pemain > hp_awal,
		"(%.1f -> %.1f)" % [hp_awal, GameState.hp_pemain])

	# --- Regenerasi tidak jalan di lantai 2 ---
	var hp_lantai2 := GameState.hp_pemain
	pemain.lantai = 2
	for i in range(20):
		interior._tick_kasur(0.1)
	_cek("kasur tidak jalan di lantai 2", GameState.hp_pemain == hp_lantai2)

	# --- Zombie mengabaikan pemain di dalam ---
	GameState.hp_pagar = 0.0
	var zombie = utama.ZOMBIE_SCENE.instantiate()
	zombie.wave_ke = 1
	utama.get_node("Entities").add_child(zombie)
	pemain.lantai = 1
	pemain.di_dalam = true
	zombie.global_position = Vector2(pemain.global_position.x + 20.0, 260.0)
	var target = zombie._cari_target()
	_cek("zombie tidak mengejar pemain di dalam bunker",
		target != null and not target.is_in_group("pemain"))
	zombie.queue_free()
	GameState.perbaiki_pagar(GameState.pagar_hp_maks())

	utama.queue_free()
	await get_tree().process_frame
	SkillTree.reset()
	GameState.reset_penuh()


# ---------------------------------------------------------------------------

func _uji_game_state() -> void:
	print("\n[GameState]")

	GameState.reset_penuh()
	GameState.tambah_resource("minyak", 10)
	_cek("tambah minyak", GameState.minyak == 10)

	var dapat := GameState.jual_minyak(4)
	_cek("jual minyak mengurangi stok", GameState.minyak == 6)
	_cek("jual minyak menambah uang", GameState.uang == dapat and dapat > 0)

	_cek("kurangi resource gagal kalau kurang", GameState.kurangi_resource("logam", 99) == false)
	GameState.tambah_resource("logam", 5)
	_cek("kurangi resource berhasil kalau cukup", GameState.kurangi_resource("logam", 5) == true)
	_cek("logam jadi 0", GameState.logam == 0)

	# Amunisi
	GameState.peluru["9mm"] = 0
	_cek("kurangi peluru gagal saat kosong", GameState.kurangi_peluru("9mm", 1) == false)
	GameState.tambah_peluru("9mm", 10)
	_cek("tambah peluru", GameState.jumlah_peluru("9mm") == 10)
	_cek("kurangi peluru", GameState.kurangi_peluru("9mm", 4) and GameState.jumlah_peluru("9mm") == 6)

	# Pabrik butuh logam
	GameState.logam = 0
	_cek("antre peluru gagal tanpa logam", GameState.antre_peluru("9mm") == false)

	GameState.logam = 3
	_cek("antre peluru berhasil", GameState.antre_peluru("9mm") == true)
	_cek("logam terpotong saat antre", GameState.logam == 2)
	_cek("antrean terisi", GameState.antrean_pabrik.size() == 1)

	# ------------------------------------------------------------------
	# Generator: bahan bakar harus proporsional, tidak boleh terbuang
	# ------------------------------------------------------------------
	GameState.antrean_pabrik.clear()
	GameState.listrik = 0.0
	GameState.minyak = 0
	GameState._sisa_bara = 0.0
	GameState.set_generator(true)
	_cek("generator menolak tanpa minyak", GameState.generator_aktif == false)

	GameState.minyak = 5
	GameState.set_generator(true)
	_cek("generator menyala dengan minyak", GameState.generator_aktif == true)

	# 4 detik pada 5 power/s = 20 power = tepat 2 oil (baterai cap 30, muat).
	for i in range(40):
		GameState._tick_generator(0.1)
	_cek("generator membakar minyak", GameState.minyak == 3, "(dapat %d)" % GameState.minyak)
	_cek_dekat("4 detik menghasilkan 20 power", GameState.listrik, 20.0, 0.5)
	_cek("status generator running", GameState.status_generator() == "running")

	# --- Regresi bug v0.3.0: pembakaran borongan saat baterai hampir penuh ---
	# Isi baterai sampai nyaris penuh, lalu tick sekali. Dulu generator membakar
	# 1 oil utuh (+10) padahal hanya muat sedikit, dan sisanya hilang.
	GameState.listrik = GameState.listrik_maks() - 1.0
	GameState.minyak = 50
	GameState._sisa_bara = 0.0
	var minyak_sebelum := GameState.minyak
	GameState._tick_generator(0.1)   # butuh 0.5 power, muat 1.0
	_cek("tidak membakar 1 oil utuh saat hampir penuh",
		GameState.minyak == minyak_sebelum,
		"(dapat %d, harap %d)" % [GameState.minyak, minyak_sebelum])
	_cek_dekat("hanya membakar pecahan yang diperlukan",
		GameState._sisa_bara, 0.05, 0.011)

	# --- Baterai penuh: nol konsumsi ---
	GameState.listrik = GameState.listrik_maks()
	GameState.minyak = 50
	GameState._sisa_bara = 0.0
	for i in range(100):
		GameState._tick_generator(0.1)
	_cek("generator tidak membakar saat baterai penuh", GameState.minyak == 50,
		"(dapat %d)" % GameState.minyak)
	_cek("status generator idle saat penuh", GameState.status_generator() == "idle")
	_cek_dekat("konsumsi 0 saat idle", GameState.konsumsi_minyak_per_detik(), 0.0)

	# --- Regresi bug: minyak bisa jadi negatif saat stok tinggal pecahan ---
	# Ditemukan lewat simulator 20 menit (minyak tampil -1). Penyebabnya:
	# ketersediaan dihitung minyak + _sisa_bara padahal _sisa_bara adalah
	# bahan bakar yang sudah terpakai, jadi seharusnya minyak - _sisa_bara.
	GameState.reset_penuh()
	GameState.listrik = 0.0
	GameState.minyak = 1
	GameState._sisa_bara = 0.9
	GameState.set_generator(true)
	GameState._tick_generator(10.0)   # minta banyak, tapi sisa cuma 0.1 oil
	_cek("minyak tidak bisa negatif", GameState.minyak >= 0,
		"(dapat %d)" % GameState.minyak)
	_cek("sisa 0.1 oil terpakai habis", GameState.minyak == 0,
		"(dapat %d)" % GameState.minyak)
	_cek_dekat("pecahan kembali ke nol setelah unit terpotong",
		GameState._sisa_bara, 0.0, 0.001)

	# Pecahan harus selalu berada di [0, 1) — kalau tidak, akuntansinya bocor.
	GameState.minyak = 2
	GameState._sisa_bara = 0.55
	GameState.listrik = 0.0
	var bocor := false
	for i in range(200):
		GameState._tick_generator(0.1)
		if GameState._sisa_bara < 0.0 or GameState._sisa_bara >= 1.0:
			bocor = true
			break
	_cek("pecahan bahan bakar tetap di rentang [0,1)", bocor == false,
		"(dapat %.3f)" % GameState._sisa_bara)
	_cek("minyak tidak negatif setelah banyak tick", GameState.minyak >= 0,
		"(dapat %d)" % GameState.minyak)

	# --- Konservasi: oil x 10 == power yang dihasilkan ---
	# Simulasi 2000 tick dengan beban pabrik bergantian. Kalau ada minyak
	# yang terbuang, total daya tidak akan cocok dengan bahan bakar.
	GameState.reset_penuh()
	GameState.minyak = 100
	GameState.logam = 500
	GameState.listrik = 0.0
	GameState._sisa_bara = 0.0
	GameState.set_generator(true)

	var oil_awal := GameState.minyak
	var daya_dihasilkan := 0.0
	for i in range(2000):
		var sebelum := GameState.listrik
		GameState._tick_generator(0.1)
		daya_dihasilkan += maxf(0.0, GameState.listrik - sebelum)
		# Beban pabrik bergantian: berkala ada antrean, lalu kosong.
		if i % 40 == 0 and GameState.logam > 0:
			GameState.antre_peluru("9mm")
		GameState._tick_pabrik(0.1)

	var oil_terbakar := float(oil_awal - GameState.minyak)
	_cek_dekat("1 oil menghasilkan tepat 10 power",
		oil_terbakar * GameState.listrik_per_bara(), daya_dihasilkan, 1.0)
	_cek("tidak ada minyak terbuang (efisiensi 100%)",
		absf(oil_terbakar * GameState.listrik_per_bara() - daya_dihasilkan) < 0.5,
		"(oil %.2f -> %.1f power, tercatat %.1f)" % [oil_terbakar, oil_terbakar * 10.0, daya_dihasilkan])

	# Konservasi daya: yang dihasilkan = yang tersimpan + yang dipakai pabrik.
	_cek_dekat("daya terkonservasi (tersimpan + terpakai = dihasilkan)",
		GameState.listrik + float(GameState.statistik["daya_terpakai"]),
		daya_dihasilkan, 1.0)

	# Produksi jalan memakai listrik
	GameState.antrean_pabrik.clear()
	GameState.listrik = 20.0
	GameState.logam = 5
	GameState.antre_peluru("9mm")
	var listrik_awal := GameState.listrik
	var peluru_awal := GameState.jumlah_peluru("9mm")
	for i in range(30):
		GameState._tick_pabrik(0.1)
	_cek("pabrik selesai memakai listrik", GameState.listrik < listrik_awal)
	_cek("peluru bertambah dari pabrik", GameState.jumlah_peluru("9mm") == peluru_awal + 5,
		"(dapat %d, harap %d)" % [GameState.jumlah_peluru("9mm"), peluru_awal + 5])

	# Save / load round-trip
	GameState.minyak = 7
	GameState.uang = 123
	GameState.listrik = 12.5
	GameState._sisa_bara = 0.42
	var peluru_sebelum_save := GameState.jumlah_peluru("9mm")
	var dict := GameState.ke_dict()
	GameState.reset_penuh()
	GameState.dari_dict(dict)
	_cek("round-trip save: minyak", GameState.minyak == 7)
	_cek("round-trip save: uang", GameState.uang == 123)
	_cek("round-trip save: peluru", GameState.jumlah_peluru("9mm") == peluru_sebelum_save)
	_cek_dekat("round-trip save: sisa_bara", GameState._sisa_bara, 0.42)
	_cek_dekat("round-trip save: listrik", GameState.listrik, 12.5)


func _uji_combat() -> void:
	print("\n[Combat]")

	GameState.reset_penuh()
	GameState.peluru["9mm"] = 100

	var utama = preload("res://scenes/main.tscn").instantiate()
	add_child(utama)
	await get_tree().create_timer(1.3).timeout

	var pemain = utama.get_node("Player")
	_cek("player terdaftar di grup", pemain.is_in_group("pemain"))
	_cek("magasin terisi saat start", pemain.isi_magasin == 12, "(dapat %d)" % pemain.isi_magasin)

	var zombie_awal := get_tree().get_nodes_in_group("zombie").size()
	_cek("zombie pertama sudah lahir", zombie_awal >= 1, "(dapat %d)" % zombie_awal)

	var zombie = get_tree().get_nodes_in_group("zombie")[0]
	var hp_awal: float = zombie.hp
	zombie.terima_damage(5.0)
	_cek("zombie menerima damage", zombie.hp < hp_awal)

	var dibunuh_sebelum: int = GameState.statistik["zombie_dibunuh"]
	zombie.terima_damage(9999.0)
	await get_tree().process_frame
	_cek("zombie mati menambah statistik",
		GameState.statistik["zombie_dibunuh"] == dibunuh_sebelum + 1)

	# Drop muncul
	await get_tree().process_frame
	var pickup := get_tree().get_nodes_in_group("pickup")
	_cek("zombie menjatuhkan pickup", pickup.size() >= 2, "(dapat %d)" % pickup.size())

	# Pickup bisa dipungut
	if pickup.size() > 0:
		var item = pickup[0]
		var jenis: String = item.jenis
		var jumlah: int = item.jumlah
		var sebelum := _jumlah_resource(jenis)
		item._on_body_entered(pemain)
		_cek("pickup menambah resource (%s)" % jenis, _jumlah_resource(jenis) == sebelum + jumlah)

	# Zombie menyerang bunker
	GameState.hp_bunker = 100.0
	var zombie_baru = utama.ZOMBIE_SCENE.instantiate()
	zombie_baru.wave_ke = 1
	zombie_baru.position = Vector2(300.0, 260.0)
	utama.get_node("Entities").add_child(zombie_baru)
	await get_tree().process_frame

	var bunker = get_tree().get_first_node_in_group("bunker")
	zombie_baru.global_position = Vector2(bunker.global_position.x + 10.0, bunker.global_position.y)
	zombie_baru._timer_serang = 0.0
	zombie_baru._serang(bunker)
	_cek("zombie merusak bunker", GameState.hp_bunker < 100.0,
		"(dapat %.1f)" % GameState.hp_bunker)

	# ------------------------------------------------------------------
	# Pagar: zombie harus berhenti di pagar, bukan menembus ke pintu
	# ------------------------------------------------------------------
	var pagar = get_tree().get_first_node_in_group("pagar")
	_cek("pagar terpasang di scene", pagar != null)

	if pagar != null:
		GameState.hp_pagar = GameState.pagar_hp_maks()
		var hp_pagar_awal := GameState.hp_pagar

		# Zombie di sebelah kanan pagar, pemain di belakang pagar.
		pemain.global_position = Vector2(120.0, 260.0)
		zombie_baru.global_position = Vector2(pagar.global_position.x + 12.0, 260.0)
		var target = zombie_baru._cari_target()
		_cek("zombie memilih pagar, bukan pemain di belakangnya",
			target != null and target.is_in_group("pagar"),
			"(dapat %s)" % ("null" if target == null else target.name))

		zombie_baru._timer_serang = 0.0
		var bunker_sebelum := GameState.hp_bunker
		zombie_baru._serang(pagar)
		_cek("zombie merusak pagar", GameState.hp_pagar < hp_pagar_awal,
			"(dapat %.1f)" % GameState.hp_pagar)
		_cek("menyerang pagar tidak mengurangi HP bunker",
			absf(GameState.hp_bunker - bunker_sebelum) < 0.01,
			"(bunker %.1f -> %.1f)" % [bunker_sebelum, GameState.hp_bunker])

		# Pemain di depan pagar (sisi zombie) tetap bisa dijadikan target.
		pemain.global_position = Vector2(pagar.global_position.x + 60.0, 260.0)
		zombie_baru.global_position = Vector2(pagar.global_position.x + 100.0, 260.0)
		var target2 = zombie_baru._cari_target()
		_cek("zombie mengejar pemain di luar pagar",
			target2 != null and target2.is_in_group("pemain"))

		# Pagar jebol: zombie lanjut ke bunker. Pemain harus di belakang pagar,
		# kalau tidak zombie tetap mengejarnya (dan itu perilaku yang benar).
		pemain.global_position = Vector2(120.0, 260.0)
		GameState.hp_pagar = 0.0
		var target3 = zombie_baru._cari_target()
		_cek("pagar jebol: zombie beralih ke bunker",
			target3 != null and target3.is_in_group("bunker"),
			"(dapat %s)" % ("null" if target3 == null else target3.name))
		GameState.perbaiki_pagar(GameState.pagar_hp_maks())

	utama.queue_free()
	await get_tree().process_frame


func _jumlah_resource(jenis: String) -> int:
	match jenis:
		"minyak":
			return GameState.minyak
		"logam":
			return GameState.logam
		"obat":
			return GameState.obat
		"uang":
			return GameState.uang
	return -1
