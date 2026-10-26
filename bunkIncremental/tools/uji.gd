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
	GameState.listrik = GameState.LISTRIK_MAKS - 1.0
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
	GameState.listrik = GameState.LISTRIK_MAKS
	GameState.minyak = 50
	GameState._sisa_bara = 0.0
	for i in range(100):
		GameState._tick_generator(0.1)
	_cek("generator tidak membakar saat baterai penuh", GameState.minyak == 50,
		"(dapat %d)" % GameState.minyak)
	_cek("status generator idle saat penuh", GameState.status_generator() == "idle")
	_cek_dekat("konsumsi 0 saat idle", GameState.konsumsi_minyak_per_detik(), 0.0)

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
		oil_terbakar * GameState.LISTRIK_PER_BARA, daya_dihasilkan, 1.0)
	_cek("tidak ada minyak terbuang (efisiensi 100%)",
		absf(oil_terbakar * GameState.LISTRIK_PER_BARA - daya_dihasilkan) < 0.5,
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
