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
var _tab: String = "market"
var _nama: String = "layar"


func _ready() -> void:
	_baca_argumen()

	var utama = preload("res://scenes/main.tscn").instantiate()
	add_child(utama)

	await get_tree().create_timer(0.2).timeout
	if _buka_terminal:
		var terminal = utama.get_node("UI/Terminal")
		terminal.buka()
		terminal._ganti_tab(_tab)

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


func _baca_argumen() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--terminal":
			_buka_terminal = true
		elif arg.begins_with("--tab="):
			_tab = arg.split("=")[1]
		elif arg.begins_with("--nama="):
			_nama = arg.split("=")[1]
