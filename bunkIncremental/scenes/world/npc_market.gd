extends "res://scenes/world/npc_base.gd"
## NPC Market Guy — jual oil, lihat harga pasar.

const WARNA_BAJU := Color(0.36, 0.42, 0.30)
const WARNA_KULIT := Color(0.82, 0.66, 0.50)
const WARNA_RAMBUT := Color(0.22, 0.18, 0.14)
const WARNA_MEJA := Color(0.34, 0.31, 0.26)


func _ready() -> void:
	super._ready()
	nama_npc = "Trader"
	teks_interaksi = "[E] Market"


func _gambar_bodi(bob_y: float) -> void:
	var y := bob_y

	# Meja counter di depan NPC.
	draw_rect(Rect2(-14.0, -2.0, 28.0, 8.0), WARNA_MEJA)
	draw_rect(Rect2(-14.0, -4.0, 28.0, 2.0), Color(0.44, 0.40, 0.32))

	# Badan.
	draw_rect(Rect2(-6.0, y - 22.0, 12.0, 14.0), WARNA_BAJU)
	# Kepala.
	draw_rect(Rect2(-5.0, y - 32.0, 10.0, 10.0), WARNA_KULIT)
	# Rambut.
	draw_rect(Rect2(-5.0, y - 34.0, 10.0, 4.0), WARNA_RAMBUT)
	# Mata.
	draw_rect(Rect2(-3.0, y - 29.0, 2.0, 2.0), Color(0.15, 0.12, 0.10))
	draw_rect(Rect2(1.0, y - 29.0, 2.0, 2.0), Color(0.15, 0.12, 0.10))
	# Lengan.
	draw_rect(Rect2(-10.0, y - 21.0, 4.0, 10.0), WARNA_KULIT)
	draw_rect(Rect2(6.0, y - 21.0, 4.0, 10.0), WARNA_KULIT)
	# Kaki.
	draw_rect(Rect2(-5.0, y - 8.0, 4.0, 8.0), Color(0.24, 0.22, 0.20))
	draw_rect(Rect2(1.0, y - 8.0, 4.0, 8.0), Color(0.24, 0.22, 0.20))
