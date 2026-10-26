extends Node
## Alat bantu developer: jalankan game sebentar lalu simpan screenshot
## ke user://layar.png. Bukan bagian dari game.
##
##   godot --path . tools/tangkap.tscn
##   godot --path . tools/tangkap.tscn -- --terminal --tab=factory
##
## Semua argumen setelah "--" dibaca sebagai opsi tambahan.

const TUNGGU_DETIK := 2.5

var _buka_terminal: bool = false
var _buka_skill: bool = false
var _tab: String = "market"
var _nama: String = "layar"
## Skrip penyiapan state, misal "generator" untuk menyalakan generator
## dengan minyak dan antrean pabrik supaya tab POWER tidak tampak kosong.
var _siapkan: String = ""
## id skill yang mau dipilih di panel skill saat screenshot.
var _pilih_skill: String = ""


func _ready() -> void:
	_baca_argumen()

	var utama = preload("res://scenes/main.tscn").instantiate()
	add_child(utama)

	await get_tree().create_timer(0.2).timeout
	_siapkan_state(utama)

	if _buka_terminal:
		var terminal = utama.get_node("UI/Terminal")
		terminal.buka()
		terminal._ganti_tab(_tab)
	elif _buka_skill:
		var panel = utama.get_node("UI/SkillPanel")
		panel.buka()
		if _pilih_skill != "":
			panel._terpilih = _pilih_skill
			panel._perbarui_detail()
			panel.queue_redraw()

	await get_tree().create_timer(TUNGGU_DETIK).timeout
	await RenderingServer.frame_post_draw

	var gambar := get_viewport().get_texture().get_image()
	var jalur := "user://%s.png" % _nama
	var galat := gambar.save_png(jalur)
	if galat != OK:
		push_error("Gagal menyimpan screenshot: %d" % galat)
	else:
		print("Screenshot tersimpan di: ", ProjectSettings.globalize_path(jalur))

	get_tree().quit()


func _siapkan_state(utama: Node) -> void:
	match _siapkan:
		"generator":
			GameState.minyak = 24
			GameState.logam = 18
			GameState.uang = 240
			GameState.listrik = 0.0
			GameState.antre_peluru("9mm")
			GameState.antre_peluru("9mm")
			GameState.set_generator(true)
			for i in range(20):
				GameState._tick_generator(0.1)
				GameState._tick_pabrik(0.1)
		"idle":
			GameState.minyak = 24
			GameState.listrik = GameState.listrik_maks()
			GameState.set_generator(true)
			GameState._tick_generator(0.1)
		"skill":
			# Beberapa skill sudah dibeli supaya panel tidak tampak kosong.
			GameState.uang = 640
			for id in ["steady_aim", "quick_hands", "reinforced_door", "second_line", "haggler"]:
				SkillTree._dimiliki[id] = true
			SkillTree._invalidasi()
			SkillTree.skill_berubah.emit()
		"skill_baru":
			GameState.uang = 1200
		"pagar":
			GameState.uang = 320
			GameState.minyak = 12
			GameState.hp_pagar = GameState.pagar_hp_maks() * 0.55
			GameState.hp_bunker = GameState.hp_bunker_maks() * 0.8
			GameState.wave = 8
			GameState.hp_pagar_berubah.emit(GameState.hp_pagar, GameState.pagar_hp_maks())
			GameState.hp_bunker_berubah.emit(GameState.hp_bunker, GameState.hp_bunker_maks())
			_spawn_zombie_dekat(utama, 500.0)
			_spawn_zombie_dekat(utama, 516.0)
			_spawn_zombie_dekat(utama, 534.0)
		"interior":
			GameState.uang = 420
			GameState.minyak = 18
			GameState.hp_pemain = 42.0
			GameState.hp_pemain_berubah.emit(GameState.hp_pemain, GameState.HP_PEMAIN_MAKS)
			utama._masuk_bunker()
			utama.pemain.global_position = Vector2(228.0, 264.0)
		"interior_lantai_2":
			GameState.uang = 120
			for id in ["reinforced_door", "tower_access"]:
				SkillTree._dimiliki[id] = true
			SkillTree._invalidasi()
			SkillTree.skill_berubah.emit()
			utama._masuk_bunker()
			utama.pemain.pindah_lantai(2, utama.interior.posisi_naik())
			utama.pemain.global_position = Vector2(390.0, 170.0)


func _spawn_zombie_dekat(utama: Node, x: float) -> void:
	if utama == null:
		return
	var zombie = preload("res://scenes/entities/zombie.tscn").instantiate()
	zombie.wave_ke = GameState.wave
	zombie.position = Vector2(x, 260.0)
	var entitas := utama.get_node_or_null("Entities")
	if entitas != null:
		entitas.add_child(zombie)
		GameState.catat_zombie_lahir()


func _baca_argumen() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--terminal":
			_buka_terminal = true
		elif arg == "--skill":
			_buka_skill = true
		elif arg.begins_with("--tab="):
			_tab = arg.split("=")[1]
		elif arg.begins_with("--pilih="):
			_pilih_skill = arg.split("=")[1]
		elif arg.begins_with("--nama="):
			_nama = arg.split("=")[1]
		elif arg.begins_with("--siapkan="):
			_siapkan = arg.split("=")[1]
