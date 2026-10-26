extends "res://scenes/world/npc_base.gd"
## NPC Generator Tech — atur generator dan power.

const WARNA_BAJU := Color(0.28, 0.30, 0.26)
const WARNA_KULIT := Color(0.74, 0.58, 0.44)
const WARNA_HELM := Color(0.95, 0.76, 0.32)
const WARNA_KACAMATA := Color(0.30, 0.50, 0.60)


func _ready() -> void:
	super._ready()
	nama_npc = "Tech"
	teks_interaksi = "[E] Generator"


func _gambar_bodi(bob_y: float) -> void:
	var y := bob_y

	# Badan (rompi mekanik).
	draw_rect(Rect2(-6.0, y - 22.0, 12.0, 14.0), WARNA_BAJU)
	# Detail rompi — garis-garis alat.
	draw_rect(Rect2(-4.0, y - 20.0, 3.0, 8.0), Color(0.40, 0.44, 0.36))
	draw_rect(Rect2(1.0, y - 18.0, 3.0, 5.0), Color(0.40, 0.44, 0.36))
	# Kepala.
	draw_rect(Rect2(-5.0, y - 32.0, 10.0, 10.0), WARNA_KULIT)
	# Helm keselamatan.
	draw_rect(Rect2(-6.0, y - 36.0, 12.0, 6.0), WARNA_HELM)
	draw_rect(Rect2(-6.0, y - 32.0, 12.0, 2.0), WARNA_HELM)
	# Kacamata.
	draw_rect(Rect2(-4.0, y - 29.0, 3.0, 2.0), WARNA_KACAMATA)
	draw_rect(Rect2(1.0, y - 29.0, 3.0, 2.0), WARNA_KACAMATA)
	# Lengan.
	draw_rect(Rect2(-10.0, y - 21.0, 4.0, 10.0), WARNA_KULIT)
	draw_rect(Rect2(6.0, y - 21.0, 4.0, 10.0), WARNA_KULIT)
	# Kunci pas di tangan kanan (kecil).
	draw_rect(Rect2(7.0, y - 14.0, 6.0, 3.0), Color(0.60, 0.58, 0.50))
	# Kaki.
	draw_rect(Rect2(-5.0, y - 8.0, 4.0, 8.0), Color(0.20, 0.20, 0.18))
	draw_rect(Rect2(1.0, y - 8.0, 4.0, 8.0), Color(0.20, 0.20, 0.18))
