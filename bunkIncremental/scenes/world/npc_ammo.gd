extends "res://scenes/world/npc_base.gd"
## NPC Arms Dealer — produksi peluru (factory).

const WARNA_BAJU := Color(0.42, 0.30, 0.22)
const WARNA_KULIT := Color(0.78, 0.62, 0.48)
const WARNA_RAMBUT := Color(0.12, 0.10, 0.08)
const WARNA_IKAT := Color(0.55, 0.26, 0.20)


func _ready() -> void:
	super._ready()
	nama_npc = "Armorer"
	teks_interaksi = "[E] Factory"


func _gambar_bodi(bob_y: float) -> void:
	var y := bob_y

	# Badan (jaket kulit).
	draw_rect(Rect2(-6.0, y - 22.0, 12.0, 14.0), WARNA_BAJU)
	# Ikat pinggang dengan gesper.
	draw_rect(Rect2(-6.0, y - 9.0, 12.0, 3.0), WARNA_IKAT)
	draw_rect(Rect2(-2.0, y - 10.0, 4.0, 4.0), Color(0.80, 0.72, 0.40))
	# Kepala.
	draw_rect(Rect2(-5.0, y - 32.0, 10.0, 10.0), WARNA_KULIT)
	# Rambut lebat.
	draw_rect(Rect2(-5.0, y - 34.0, 10.0, 5.0), WARNA_RAMBUT)
	draw_rect(Rect2(-7.0, y - 31.0, 3.0, 6.0), WARNA_RAMBUT)
	# Mata.
	draw_rect(Rect2(-3.0, y - 29.0, 2.0, 2.0), Color(0.15, 0.12, 0.10))
	draw_rect(Rect2(1.0, y - 29.0, 2.0, 2.0), Color(0.15, 0.12, 0.10))
	# Lengan.
	draw_rect(Rect2(-10.0, y - 21.0, 4.0, 10.0), WARNA_BAJU)
	draw_rect(Rect2(6.0, y - 21.0, 4.0, 10.0), WARNA_BAJU)
	# Tangan memegang selongsong peluru.
	draw_rect(Rect2(-12.0, y - 15.0, 3.0, 8.0), Color(0.70, 0.60, 0.30))
	# Kaki.
	draw_rect(Rect2(-5.0, y - 8.0, 4.0, 8.0), Color(0.18, 0.16, 0.14))
	draw_rect(Rect2(1.0, y - 8.0, 4.0, 8.0), Color(0.18, 0.16, 0.14))
