extends Node2D
## Mount point — penanda slot untuk senjata otomatis.
##
## Fase 4 hanya menyediakan slotnya. Belum ada logika menembak: senjata
## otomatis baru masuk fase 5 bersama sistem otomasi. Tujuannya supaya
## pemain melihat "di sini nanti ada turret" sejak awal.

## "depan" atau "lantai_2". Menentukan apakah node butuh Tower Access.
@export var jenis: String = "depan"
## Label yang tampil di bawah heksagon.
@export var label: String = "MOUNT — EMPTY"

const RADIUS := 15.0

const WARNA_AKTIF := Color(0.42, 0.62, 0.40)
const WARNA_MATI := Color(0.28, 0.30, 0.28)
const WARNA_TEKS := Color(0.62, 0.66, 0.62)
const WARNA_REDUP := Color(0.44, 0.47, 0.44)

var _font: Font


func _ready() -> void:
	add_to_group("mount_point")
	_font = ThemeDB.fallback_font
	SkillTree.skill_berubah.connect(_on_skill_berubah)
	visible = terbuka() or jenis != "lantai_2"
	queue_redraw()


func terbuka() -> bool:
	if jenis == "lantai_2":
		return SkillTree.efek_total("buka_lantai_2") > 0.0
	return true


## Mount di ruang yang masih tersegel tidak digambar sama sekali — ruangnya
## memang belum ada, jadi menampilkan slot kosong hanya membingungkan.
func _on_skill_berubah() -> void:
	visible = terbuka() or jenis != "lantai_2"
	queue_redraw()


func _draw() -> void:
	var aktif := terbuka()
	var warna := WARNA_AKTIF if aktif else WARNA_MATI

	# Alas.
	draw_rect(Rect2(-18.0, -5.0, 36.0, 5.0), Color(0.24, 0.25, 0.24))

	# Heksagon putus-putus.
	var pusat := Vector2(0, -RADIUS - 6.0)
	var titik := PackedVector2Array()
	for i in range(7):
		var sudut := deg_to_rad(60.0 * (i % 6) - 30.0)
		titik.append(pusat + Vector2(cos(sudut), sin(sudut)) * RADIUS)
	draw_polyline(titik, warna, 1.0, true)

	# Salib kecil di tengah: "kosong".
	var silang := 4.0
	draw_line(pusat + Vector2(-silang, -silang), pusat + Vector2(silang, silang), warna, 1.0)
	draw_line(pusat + Vector2(-silang, silang), pusat + Vector2(silang, -silang), warna, 1.0)

	var teks := label if aktif else "MOUNT — LOCKED"
	draw_string(
		_font, Vector2(-46.0, -RADIUS * 2.0 - 16.0), teks,
		HORIZONTAL_ALIGNMENT_CENTER, 92.0, 7, WARNA_TEKS if aktif else WARNA_REDUP
	)
