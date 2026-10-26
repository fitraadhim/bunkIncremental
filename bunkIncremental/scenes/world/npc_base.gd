extends Node2D
## NPC dasar — animasi idle + zona interaksi.

signal interaksi_diminta

const JARAK_INTERAKSI := 40.0
const WARNA_LABEL := Color(0.95, 0.76, 0.32)
const WARNA_REDUP := Color(0.52, 0.56, 0.62)

## Nama NPC, dipakai label dan UI.
@export var nama_npc: String = "NPC"
## Teks petunjuk di bawah sprite.
@export var teks_interaksi: String = "[E] Talk"

var _font: Font
var _waktu: float = 0.0
## Offset Y animasi idle saat ini.
var _bob: float = 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	add_to_group("npc")


func _process(delta: float) -> void:
	_waktu += delta
	_bob = sin(_waktu * PI) * 1.4
	queue_redraw()


func dalam_jangkauan(posisi_pemain: Vector2) -> bool:
	return global_position.distance_to(posisi_pemain) <= JARAK_INTERAKSI


## Override di subclass untuk menggambar bodi NPC.
func _gambar_bodi(_bob_y: float) -> void:
	pass


func _draw() -> void:
	_gambar_bodi(_bob)
	# Label nama + petunjuk.
	draw_string(
		_font, Vector2(-24.0, 14.0), nama_npc,
		HORIZONTAL_ALIGNMENT_CENTER, 48.0, 8, WARNA_LABEL
	)
	draw_string(
		_font, Vector2(-24.0, 24.0), teks_interaksi,
		HORIZONTAL_ALIGNMENT_CENTER, 48.0, 7, WARNA_REDUP
	)
