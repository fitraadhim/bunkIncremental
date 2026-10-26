extends StaticBody2D
## Pagar — lapisan pertahanan di depan bunker.
##
## Punya dua mode visual:
## - RERUNTUHAN: skill "barbed_wire" belum dibeli. Tidak menghalangi zombie,
##   hanya visual. Zombie langsung ke bunker.
## - UTUH: setelah "barbed_wire" dibeli. CollisionShape aktif, zombie tertahan.
##
## Posisi di x=250, lebih dekat ke bunker.

const TINGGI := 46.0
const LEBAR_TIANG := 4.0

const WARNA_TIANG := Color(0.42, 0.38, 0.32)
const WARNA_TIANG_RUSAK := Color(0.28, 0.24, 0.20)
const WARNA_KAYU := Color(0.50, 0.45, 0.36)
const WARNA_KAYU_GELAP := Color(0.34, 0.31, 0.26)
const WARNA_RUSAK := Color(0.62, 0.26, 0.20)
const WARNA_KAWAT := Color(0.66, 0.66, 0.62, 0.8)

@onready var bentuk: CollisionShape2D = $Bentuk

var _getar: float = 0.0


func _ready() -> void:
	add_to_group("pagar")
	GameState.hp_pagar_berubah.connect(_on_hp_berubah)
	SkillTree.skill_berubah.connect(_on_skill_berubah)
	_perbarui_collision()
	_on_hp_berubah(GameState.hp_pagar, GameState.pagar_hp_maks())
	queue_redraw()


func _process(delta: float) -> void:
	if _getar > 0.0:
		_getar = maxf(0.0, _getar - delta * 4.0)
		queue_redraw()


## Apakah pagar sudah dibeli lewat skill tree.
func terbuka() -> bool:
	return SkillTree.sudah_dimiliki("barbed_wire")


func _perbarui_collision() -> void:
	var aktif := terbuka() and GameState.pagar_hidup()
	bentuk.set_deferred("disabled", not aktif)


func terima_damage(jumlah: float) -> void:
	if not terbuka():
		return
	if not GameState.pagar_hidup():
		return
	GameState.terima_damage_pagar(jumlah)
	_getar = 1.0
	queue_redraw()


func _on_hp_berubah(sekarang: float, _maks: float) -> void:
	_perbarui_collision()
	queue_redraw()


func _on_skill_berubah() -> void:
	_perbarui_collision()
	queue_redraw()


# ---------------------------------------------------------------------------
# Gambar
# ---------------------------------------------------------------------------

func _draw() -> void:
	if terbuka():
		_gambar_pagar_utuh()
	else:
		_gambar_reruntuhan()


func _gambar_pagar_utuh() -> void:
	var maks := GameState.pagar_hp_maks()
	var rasio := clampf(GameState.hp_pagar / maxf(maks, 0.001), 0.0, 1.0)
	var goyang := sin(_getar * 40.0) * _getar * 1.5

	# Tiga tiang vertikal.
	for i in range(3):
		var x := -14.0 + i * 14.0
		draw_rect(Rect2(x - LEBAR_TIANG * 0.5 + goyang, -TINGGI, LEBAR_TIANG, TINGGI), WARNA_TIANG)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - LEBAR_TIANG * 0.5 + goyang, -TINGGI),
				Vector2(x + LEBAR_TIANG * 0.5 + goyang, -TINGGI),
				Vector2(x + goyang, -TINGGI - 6.0),
			]),
			WARNA_TIANG
		)

	# Palang horizontal.
	draw_rect(Rect2(-22.0 + goyang, -TINGGI + 10.0, 44.0, 4.0), WARNA_KAYU)
	draw_rect(Rect2(-22.0 + goyang, -TINGGI + 26.0, 44.0, 4.0), WARNA_KAYU)
	var palang_y := -TINGGI + 16.0
	while palang_y < -6.0:
		draw_rect(Rect2(-21.0 + goyang, palang_y, 42.0, 2.0), WARNA_KAYU_GELAP)
		palang_y += 5.0

	# Kerusakan.
	var patah := int((1.0 - rasio) * 6.0)
	for i in range(patah):
		var px := -18.0 + float(i) * 7.0
		var py := -TINGGI + 12.0 + float(i % 3) * 8.0
		draw_line(Vector2(px, py), Vector2(px + 5.0, py + 4.0), WARNA_RUSAK, 1.5)

	# Kawat berduri (selalu ada karena ini unlock dari barbed_wire).
	var y := -TINGGI + 5.0
	while y < -6.0:
		draw_line(Vector2(-21.0, y), Vector2(21.0, y + 4.0), WARNA_KAWAT, 0.8)
		draw_line(Vector2(-21.0, y + 4.0), Vector2(21.0, y), WARNA_KAWAT, 0.8)
		y += 9.0

	# Bar HP kecil.
	var lebar := 40.0
	var warna := Color(0.55, 0.85, 0.50)
	if rasio < 0.5:
		warna = Color(0.95, 0.75, 0.30)
	if rasio < 0.25:
		warna = WARNA_RUSAK
	draw_rect(Rect2(-lebar * 0.5, -TINGGI - 12.0, lebar, 3.0), Color(0.0, 0.0, 0.0, 0.7))
	draw_rect(Rect2(-lebar * 0.5, -TINGGI - 12.0, lebar * rasio, 3.0), warna)


func _gambar_reruntuhan() -> void:
	## Pagar belum dibangun — terlihat sebagai reruntuhan, zombie bisa lewat.
	var font := ThemeDB.fallback_font

	# Tiang-tiang miring/patah.
	# Tiang kiri — masih berdiri miring.
	draw_rect(Rect2(-18.0, -28.0, 3.0, 28.0), WARNA_TIANG_RUSAK)
	draw_rect(Rect2(-18.0, -28.0, 14.0, 3.0), WARNA_KAYU_GELAP)

	# Tiang tengah — rebah.
	draw_rect(Rect2(-10.0, -8.0, 3.0, 8.0), WARNA_TIANG_RUSAK)
	draw_rect(Rect2(-14.0, -5.0, 22.0, 2.0), WARNA_KAYU_GELAP)

	# Tiang kanan — puntung pendek.
	draw_rect(Rect2(10.0, -14.0, 3.0, 14.0), WARNA_TIANG_RUSAK)

	# Puing-puing di tanah.
	draw_rect(Rect2(-20.0, -3.0, 8.0, 3.0), WARNA_KAYU_GELAP)
	draw_rect(Rect2(5.0, -2.0, 12.0, 2.0), WARNA_KAYU_GELAP)

	# Label kecil.
	draw_string(
		font, Vector2(-28.0, 14.0), "FENCE RUINED",
		HORIZONTAL_ALIGNMENT_CENTER, 56.0, 7, Color(0.52, 0.46, 0.38)
	)
