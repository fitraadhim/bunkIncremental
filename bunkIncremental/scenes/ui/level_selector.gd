extends Control
## Panel pemilihan level. Muncul saat pemain berinteraksi dengan detektor zombie.

signal level_dipilih(level_id: int)
signal ditutup

const WARNA_BG := Color(0.08, 0.09, 0.10, 0.96)
const WARNA_BORDER := Color(0.95, 0.76, 0.32)
const WARNA_TEKS := Color(0.87, 0.89, 0.92)
const WARNA_REDUP := Color(0.52, 0.56, 0.62)
const WARNA_AKSEN := Color(0.95, 0.76, 0.32)
const WARNA_BAIK := Color(0.55, 0.88, 0.55)

## Data level yang tersedia. Diisi dari luar sebelum buka().
var daftar_level: Array = []

var _font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("jeda") or event.is_action_pressed("buka_panel"):
		tutup()
		get_viewport().set_input_as_handled()


func buka() -> void:
	visible = true
	get_tree().paused = true
	queue_redraw()


func tutup() -> void:
	visible = false
	get_tree().paused = false
	ditutup.emit()


func _draw() -> void:
	if not visible:
		return

	# Latar gelap penuh
	draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.75))

	# Panel tengah
	var pw := 360.0
	var ph := 240.0
	var px := (640.0 - pw) * 0.5
	var py := (360.0 - ph) * 0.5
	draw_rect(Rect2(px, py, pw, ph), WARNA_BG)

	# Border
	draw_rect(Rect2(px, py, pw, 1), WARNA_BORDER)
	draw_rect(Rect2(px, py + ph - 1, pw, 1), WARNA_BORDER)
	draw_rect(Rect2(px, py, 1, ph), WARNA_BORDER)
	draw_rect(Rect2(px + pw - 1, py, 1, ph), WARNA_BORDER)

	# Sudut militer
	draw_line(Vector2(px, py), Vector2(px + 10, py), WARNA_AKSEN, 2)
	draw_line(Vector2(px, py), Vector2(px, py + 10), WARNA_AKSEN, 2)
	draw_line(Vector2(px + pw, py), Vector2(px + pw - 10, py), WARNA_AKSEN, 2)
	draw_line(Vector2(px + pw, py), Vector2(px + pw, py + 10), WARNA_AKSEN, 2)
	draw_line(Vector2(px, py + ph), Vector2(px + 10, py + ph), WARNA_AKSEN, 2)
	draw_line(Vector2(px, py + ph), Vector2(px, py + ph - 10), WARNA_AKSEN, 2)
	draw_line(Vector2(px + pw, py + ph), Vector2(px + pw - 10, py + ph), WARNA_AKSEN, 2)
	draw_line(Vector2(px + pw, py + ph), Vector2(px + pw, py + ph - 10), WARNA_AKSEN, 2)

	# Judul
	draw_string(_font, Vector2(px + pw * 0.5 - 80, py + 28),
		"ZOMBIE DETECTOR  //  SELECT MISSION",
		HORIZONTAL_ALIGNMENT_CENTER, 160, 11, WARNA_AKSEN)

	draw_line(Vector2(px + 12, py + 38), Vector2(px + pw - 12, py + 38), WARNA_BORDER, 1)

	# Daftar level
	var y_item := py + 56.0
	for i in range(daftar_level.size()):
		var lv = daftar_level[i]
		_gambar_kartu_level(lv, px + 16, y_item, pw - 32, 64)
		y_item += 74.0

	# Tutup
	draw_string(_font, Vector2(px + pw * 0.5 - 60, py + ph - 14),
		"ESC / TAB  to close",
		HORIZONTAL_ALIGNMENT_CENTER, 120, 8, WARNA_REDUP)


func _gambar_kartu_level(lv: Resource, x: float, y: float, lebar: float, tinggi: float) -> void:
	# Background kartu
	draw_rect(Rect2(x, y, lebar, tinggi), Color(0.12, 0.14, 0.15))
	draw_rect(Rect2(x, y, lebar, 1), Color(0.3, 0.3, 0.28))

	# Nama
	draw_string(_font, Vector2(x + 10, y + 18),
		lv.nama.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 200, 10, WARNA_TEKS)

	# Deskripsi
	draw_string(_font, Vector2(x + 10, y + 32),
		lv.deskripsi, HORIZONTAL_ALIGNMENT_LEFT, lebar - 20, 8, WARNA_REDUP)

	# Info wave
	draw_string(_font, Vector2(x + 10, y + 48),
		"%d waves  ·  difficulty: tutorial" % lv.jumlah_wave,
		HORIZONTAL_ALIGNMENT_LEFT, 200, 8, WARNA_BAIK)

	# Tombol START (drawn as highlight zone)
	var btn_x := x + lebar - 72.0
	var btn_y := y + (tinggi - 20.0) * 0.5
	draw_rect(Rect2(btn_x, btn_y, 64, 20), Color(0.95, 0.76, 0.32, 0.15))
	draw_rect(Rect2(btn_x, btn_y, 64, 1), WARNA_AKSEN)
	draw_rect(Rect2(btn_x, btn_y + 19, 64, 1), WARNA_AKSEN)
	draw_string(_font, Vector2(btn_x + 32, btn_y + 14),
		"START", HORIZONTAL_ALIGNMENT_CENTER, 64, 9, WARNA_AKSEN)


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cek_klik(event.position)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cek_klik(event.position)


func _cek_klik(pos: Vector2) -> void:
	var pw := 360.0
	var ph := 240.0
	var px := (640.0 - pw) * 0.5
	var py := (360.0 - ph) * 0.5
	var y_item := py + 56.0

	for i in range(daftar_level.size()):
		var lv = daftar_level[i]
		var lebar := pw - 32
		var btn_x := px + 16 + lebar - 72.0
		var btn_y := y_item + (64.0 - 20.0) * 0.5
		var rect := Rect2(btn_x, btn_y, 64, 20)
		if rect.has_point(pos):
			tutup()
			level_dipilih.emit(lv.id)
			return
		y_item += 74.0
