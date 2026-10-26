extends Node2D
## World — latar belakang, siluet reruntuhan, dan tanah.
##
## Semuanya digambar lewat _draw() supaya belum perlu aset parallax.
## Nanti di fase polish tinggal ganti dengan ParallaxBackground + sprite asli.

const TEKSTUR_TANAH := preload("res://art/placeholder/ground_tile.png")

const LEBAR_LAYAR := 640.0
const Y_TANAH := 260.0
const TINGGI_TANAH := 16.0

## True saat fase siang (tidak ada zombie).
var _siang: bool = false

## Vector4(x, y, lebar, tinggi) — semua berakhir di Y_TANAH.
const GEDUNG: Array = [
	Vector4(18, 196, 46, 64),
	Vector4(72, 170, 30, 90),
	Vector4(108, 210, 54, 50),
	Vector4(176, 182, 26, 78),
	Vector4(214, 202, 60, 58),
	Vector4(288, 160, 34, 100),
	Vector4(330, 198, 48, 62),
	Vector4(392, 178, 28, 82),
	Vector4(430, 206, 62, 54),
	Vector4(506, 188, 32, 72),
	Vector4(552, 200, 50, 60),
	Vector4(612, 176, 28, 84),
]


func _ready() -> void:
	GameState.fase_berubah.connect(_on_fase_berubah)
	_siang = GameState.fase == "siang"
	queue_redraw()


func _on_fase_berubah(fase: String) -> void:
	_siang = fase == "siang"
	queue_redraw()


func atur_siang(aktif: bool) -> void:
	_siang = aktif
	queue_redraw()


func _draw() -> void:
	_gambar_langit()
	_gambar_bulan()
	_gambar_reruntuhan()
	_gambar_tanah()


func _gambar_langit() -> void:
	if _siang:
		# Langit siang: gradien biru terang ke biru muda.
		var atas := Color(0.36, 0.56, 0.88)
		var bawah := Color(0.62, 0.78, 0.96)
		var langkah := 16
		var tinggi_band := Y_TANAH / float(langkah)
		for i in range(langkah):
			var t := float(i) / float(langkah - 1)
			draw_rect(Rect2(0.0, i * tinggi_band, LEBAR_LAYAR, tinggi_band + 1.0), atas.lerp(bawah, t))
	else:
		# Langit malam: gradien gelap biru-hitam.
		var atas := Color(0.05, 0.06, 0.09)
		var bawah := Color(0.17, 0.15, 0.17)
		var langkah := 16
		var tinggi_band := Y_TANAH / float(langkah)
		for i in range(langkah):
			var t := float(i) / float(langkah - 1)
			draw_rect(Rect2(0.0, i * tinggi_band, LEBAR_LAYAR, tinggi_band + 1.0), atas.lerp(bawah, t))


func _gambar_bulan() -> void:
	if _siang:
		# Siang: gambar matahari.
		draw_circle(Vector2(500.0, 48.0), 22.0, Color(1.0, 0.95, 0.70, 0.9))
		draw_circle(Vector2(500.0, 48.0), 18.0, Color(1.0, 0.98, 0.82, 1.0))
		# Sinar matahari pendek.
		for i in range(8):
			var sudut := deg_to_rad(i * 45.0)
			var awal := Vector2(500.0, 48.0) + Vector2(cos(sudut), sin(sudut)) * 26.0
			var akhir := Vector2(500.0, 48.0) + Vector2(cos(sudut), sin(sudut)) * 34.0
			draw_line(awal, akhir, Color(1.0, 0.92, 0.60, 0.7), 2.0)
	else:
		# Malam: bulan.
		draw_circle(Vector2(430.0, 54.0), 30.0, Color(0.85, 0.86, 0.78, 0.06))
		draw_circle(Vector2(430.0, 54.0), 19.0, Color(0.88, 0.88, 0.80, 0.16))
		draw_circle(Vector2(430.0, 54.0), 13.0, Color(0.93, 0.92, 0.84, 0.42))


func _gambar_reruntuhan() -> void:
	var gelap := Color(0.09, 0.09, 0.12)
	var jendela := Color(0.98, 0.78, 0.36, 0.55)
	var jendela_redup := Color(0.55, 0.46, 0.28, 0.28)

	for g in GEDUNG:
		var r := Rect2(g.x, g.y, g.z, g.w)
		draw_rect(r, gelap)

		# jendela kecil yang sebagian masih menyala
		var kolom := int(r.size.x / 12.0)
		var baris := int(r.size.y / 16.0)
		for bx in range(kolom):
			for by in range(baris):
				var cx := r.position.x + 4.0 + bx * 12.0
				var cy := r.position.y + 6.0 + by * 16.0
				if cx + 4.0 > r.end.x or cy + 5.0 > r.end.y:
					continue
				var sisa := (bx * 7 + by * 13 + int(g.x)) % 11
				if sisa == 0:
					draw_rect(Rect2(cx, cy, 4.0, 5.0), jendela)
				elif sisa < 3:
					draw_rect(Rect2(cx, cy, 4.0, 5.0), jendela_redup)


func _gambar_tanah() -> void:
	draw_texture_rect(TEKSTUR_TANAH, Rect2(0.0, Y_TANAH, LEBAR_LAYAR, TINGGI_TANAH), true)

	# Foreground: tanah gelap yang menutupi kaki supaya terasa ada kedalaman.
	draw_rect(
		Rect2(0.0, Y_TANAH + TINGGI_TANAH, LEBAR_LAYAR, 360.0 - (Y_TANAH + TINGGI_TANAH)),
		Color(0.09, 0.07, 0.06)
	)

	# Puing kecil di garis tanah.
	var puing := Color(0.16, 0.13, 0.11)
	var x := 4.0
	while x < LEBAR_LAYAR:
		var tinggi := 2.0 + float(int(x) % 3)
		draw_rect(Rect2(x, Y_TANAH + TINGGI_TANAH - tinggi, 3.0, tinggi), puing)
		x += 11.0
