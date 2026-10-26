extends Node2D
## Detektor zombie — alat di depan bunker yang memulai level.
## Pemain tekan E di dekat ini untuk membuka pilihan level.

const WARNA_BODI := Color(0.22, 0.24, 0.22)
const WARNA_LAYAR := Color(0.08, 0.26, 0.14)
const WARNA_AKTIF := Color(0.30, 0.95, 0.44)
const WARNA_REDUP := Color(0.52, 0.56, 0.62)
const WARNA_AKSEN := Color(0.95, 0.76, 0.32)
const WARNA_MALAM := Color(0.95, 0.36, 0.26)

## Jarak maksimum pemain agar bisa berinteraksi.
const JARAK_INTERAKSI := 48.0

var _font: Font
var _pulsa: float = 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	GameState.fase_berubah.connect(_on_fase_berubah)
	queue_redraw()


func _process(delta: float) -> void:
	_pulsa += delta * 2.5
	if _pulsa > TAU:
		_pulsa -= TAU
	queue_redraw()


func _on_fase_berubah(_fase: String) -> void:
	queue_redraw()


func dalam_jangkauan(posisi_pemain: Vector2) -> bool:
	return global_position.distance_to(posisi_pemain) <= JARAK_INTERAKSI


func _draw() -> void:
	var siang := GameState.fase == "siang"

	# Bodi alat — kotak besi kecil di atas tiang.
	draw_rect(Rect2(-8, -38, 16, 28), WARNA_BODI)
	# Layar kecil.
	draw_rect(Rect2(-5, -35, 10, 16), WARNA_LAYAR)

	# Indikator status di layar.
	if siang:
		var kecerahan := (sin(_pulsa) + 1.0) * 0.5
		var warna_pulsa := WARNA_AKTIF.lerp(Color(0, 0.4, 0.1), kecerahan * 0.5)
		draw_rect(Rect2(-3, -33, 6, 12), warna_pulsa)
	else:
		draw_rect(Rect2(-3, -33, 6, 12), WARNA_MALAM)

	# Tiang.
	draw_rect(Rect2(-2, -10, 4, 10), WARNA_BODI)

	# Alas.
	draw_rect(Rect2(-10, -10, 20, 4), WARNA_BODI)

	# Label petunjuk (hanya siang).
	if siang:
		draw_string(
			_font, Vector2(-22, 10), "[E] SCAN",
			HORIZONTAL_ALIGNMENT_CENTER, 44, 7, WARNA_AKSEN
		)
	else:
		draw_string(
			_font, Vector2(-22, 10), "ACTIVE",
			HORIZONTAL_ALIGNMENT_CENTER, 44, 7, WARNA_MALAM
		)
