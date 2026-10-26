extends StaticBody2D
## Pagar — lapisan pertahanan di depan pintu bunker.
##
## Zombie berhenti di sini dan menyerang pagar, bukan langsung ke bunker.
## Pemain TIDAK terhalang pagar (ada gerbang), supaya drop zombie yang jatuh
## di garis pagar tetap bisa diambil.
##
## Collision layer 5 (Fence) sengaja terpisah: hanya zombie yang memasukkannya
## ke collision_mask, jadi pemain dan peluru lewat begitu saja.

const TINGGI := 46.0
const LEBAR_TIANG := 4.0

const WARNA_TIANG := Color(0.42, 0.38, 0.32)
const WARNA_KAYU := Color(0.50, 0.45, 0.36)
const WARNA_KAYU_GELAP := Color(0.34, 0.31, 0.26)
const WARNA_RUSAK := Color(0.62, 0.26, 0.20)

@onready var bentuk: CollisionShape2D = $Bentuk

var _getar: float = 0.0


func _ready() -> void:
	add_to_group("pagar")
	GameState.hp_pagar_berubah.connect(_on_hp_berubah)
	_on_hp_berubah(GameState.hp_pagar, GameState.pagar_hp_maks())
	queue_redraw()


func _process(delta: float) -> void:
	if _getar > 0.0:
		_getar = maxf(0.0, _getar - delta * 4.0)
		queue_redraw()


## Dipanggil zombie. Hanya ada di sini supaya raycast peluru yang kebetulan
## mengenai pagar tidak error — peluru memakai mask zombie, jadi tidak kena.
func terima_damage(jumlah: float) -> void:
	if not GameState.pagar_hidup():
		return
	GameState.terima_damage_pagar(jumlah)
	_getar = 1.0
	queue_redraw()


func _on_hp_berubah(sekarang: float, _maks: float) -> void:
	var hidup := sekarang > 0.0
	bentuk.set_deferred("disabled", not hidup)
	visible = hidup
	queue_redraw()


# ---------------------------------------------------------------------------
# Gambar
# ---------------------------------------------------------------------------

func _draw() -> void:
	if not GameState.pagar_hidup():
		return

	var maks := GameState.pagar_hp_maks()
	var rasio := clampf(GameState.hp_pagar / maxf(maks, 0.001), 0.0, 1.0)
	var goyang := sin(_getar * 40.0) * _getar * 1.5

	# Tiga tiang vertikal.
	for i in range(3):
		var x := -14.0 + i * 14.0
		draw_rect(Rect2(x - LEBAR_TIANG * 0.5 + goyang, -TINGGI, LEBAR_TIANG, TINGGI), WARNA_TIANG)
		# Ujung tiang yang diruncingkan.
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - LEBAR_TIANG * 0.5 + goyang, -TINGGI),
				Vector2(x + LEBAR_TIANG * 0.5 + goyang, -TINGGI),
				Vector2(x + goyang, -TINGGI - 6.0),
			]),
			WARNA_TIANG
		)

	# Palang horizontal: dua tebal di luar, tiga tipis di dalam supaya
	# siluetnya terbaca sebagai pagar, bukan tiang gawang.
	draw_rect(Rect2(-22.0 + goyang, -TINGGI + 10.0, 44.0, 4.0), WARNA_KAYU)
	draw_rect(Rect2(-22.0 + goyang, -TINGGI + 26.0, 44.0, 4.0), WARNA_KAYU)
	var palang_y := -TINGGI + 16.0
	while palang_y < -6.0:
		draw_rect(Rect2(-21.0 + goyang, palang_y, 42.0, 2.0), WARNA_KAYU_GELAP)
		palang_y += 5.0

	# Kerusakan digambar sebagai patahan yang makin banyak saat HP turun.
	var patah := int((1.0 - rasio) * 6.0)
	for i in range(patah):
		var px := -18.0 + float(i) * 7.0
		var py := -TINGGI + 12.0 + float(i % 3) * 8.0
		draw_line(Vector2(px, py), Vector2(px + 5.0, py + 4.0), WARNA_RUSAK, 1.5)

	# Kawat berduri: muncul kalau Barbed Wire sudah dibeli.
	if SkillTree.efek_total("hp_pagar_persen") > 0.0:
		var y := -TINGGI + 5.0
		while y < -6.0:
			draw_line(Vector2(-21.0, y), Vector2(21.0, y + 4.0), Color(0.66, 0.66, 0.62, 0.8), 0.8)
			draw_line(Vector2(-21.0, y + 4.0), Vector2(21.0, y), Color(0.66, 0.66, 0.62, 0.8), 0.8)
			y += 9.0

	# Bar HP kecil di atas pagar.
	var lebar := 40.0
	var warna := Color(0.55, 0.85, 0.50)
	if rasio < 0.5:
		warna = Color(0.95, 0.75, 0.30)
	if rasio < 0.25:
		warna = WARNA_RUSAK
	draw_rect(Rect2(-lebar * 0.5, -TINGGI - 12.0, lebar, 3.0), Color(0.0, 0.0, 0.0, 0.7))
	draw_rect(Rect2(-lebar * 0.5, -TINGGI - 12.0, lebar * rasio, 3.0), warna)
