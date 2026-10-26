extends Node2D
## Interior bunker — dua lantai, digambar penuh lewat _draw().
##
## Bukan scene terpisah: node ini menempati ruang layar yang sama dengan
## World, lalu World/Entities disembunyikan saat pemain masuk. Dengan begitu
## tidak perlu change_scene (yang akan menghancurkan state wave) dan tidak
## perlu kamera, karena kamera game ini statis.
##
## Waktu TETAP berjalan selama pemain di dalam: zombie terus menggerus pagar
## dan pintu. Karena itu interior bukan tempat aman gratis.
##
## Tata letak dijaga di dalam pita y = 96..270 supaya tidak tertutup panel
## HUD (resource di kiri atas, wave di kanan atas, kondisi & amunisi di bawah).

## Batas gerak pemain di dalam.
const BATAS_KIRI := 56.0
const BATAS_KANAN := 588.0
const Y_LANTAI_1 := 264.0
const Y_LANTAI_2 := 170.0
const Y_ATAP := 96.0

## Zona tangga: hanya di sini pemain bisa naik/turun.
const TANGGA_X_MIN := 500.0
const TANGGA_X_MAX := 576.0

## Zona kasur: regenerasi HP selama berdiri di sini.
const KASUR_X_MIN := 160.0
const KASUR_X_MAX := 236.0
const KASUR_REGEN := 3.0

## Zona pintu keluar.
const PINTU_X_MIN := 56.0
const PINTU_X_MAX := 100.0

const WARNA_DINDING := Color(0.16, 0.17, 0.18)
const WARNA_DINDING_GELAP := Color(0.11, 0.12, 0.13)
const WARNA_LANTAI := Color(0.26, 0.25, 0.23)
const WARNA_LANTAI_TEBAL := Color(0.34, 0.32, 0.28)
const WARNA_TANGGA := Color(0.40, 0.36, 0.30)
const WARNA_AKSEN := Color(0.95, 0.76, 0.32)
const WARNA_REDUP := Color(0.52, 0.56, 0.62)
const WARNA_BAIK := Color(0.55, 0.88, 0.55)

var _aktif: bool = false
var _regen_akumulasi: float = 0.0
var _font: Font


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	GameState.hp_pemain_berubah.connect(_on_hp_pemain)
	SkillTree.skill_berubah.connect(_on_skill_berubah)


func _process(delta: float) -> void:
	if not _aktif:
		return
	_tick_kasur(delta)


func apakah_aktif() -> bool:
	return _aktif


func lantai_2_terbuka() -> bool:
	return SkillTree.efek_total("buka_lantai_2") > 0.0


func masuk() -> void:
	_aktif = true
	visible = true
	_regen_akumulasi = 0.0
	queue_redraw()


func keluar() -> void:
	_aktif = false
	visible = false


# ---------------------------------------------------------------------------
# Posisi pemain
# ---------------------------------------------------------------------------

func y_lantai(lantai: int) -> float:
	return Y_LANTAI_2 if lantai >= 2 else Y_LANTAI_1


## Posisi muncul saat pertama masuk — tepat di dalam pintu, bukan di atas kasur.
func posisi_masuk() -> Vector2:
	return Vector2(130.0, Y_LANTAI_1)


func posisi_turun() -> Vector2:
	return Vector2((TANGGA_X_MIN + TANGGA_X_MAX) * 0.5, Y_LANTAI_1)


func posisi_naik() -> Vector2:
	return Vector2((TANGGA_X_MIN + TANGGA_X_MAX) * 0.5, Y_LANTAI_2)


func di_zona_tangga(x: float) -> bool:
	return x >= TANGGA_X_MIN and x <= TANGGA_X_MAX


func di_zona_kasur(x: float) -> bool:
	return x >= KASUR_X_MIN and x <= KASUR_X_MAX


func di_zona_pintu(x: float) -> bool:
	return x >= PINTU_X_MIN and x <= PINTU_X_MAX


func _tick_kasur(delta: float) -> void:
	var pemain = get_tree().get_first_node_in_group("pemain")
	if pemain == null or not is_instance_valid(pemain):
		return
	if pemain.lantai != 1 or not di_zona_kasur(pemain.global_position.x):
		_regen_akumulasi = 0.0
		return
	if GameState.hp_pemain >= GameState.HP_PEMAIN_MAKS - 0.5:
		return

	_regen_akumulasi += KASUR_REGEN * delta
	if _regen_akumulasi >= 1.0:
		var sembuh := int(_regen_akumulasi)
		_regen_akumulasi -= float(sembuh)
		GameState.pulihkan_pemain(float(sembuh))


func _on_hp_pemain(_sekarang: float, _maks: float) -> void:
	if _aktif:
		queue_redraw()


func _on_skill_berubah() -> void:
	if _aktif:
		queue_redraw()


# ---------------------------------------------------------------------------
# Gambar
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.055, 0.06, 0.065))
	_gambar_dinding()
	_gambar_lantai()
	_gambar_tangga()
	_gambar_kasur()
	_gambar_pintu()
	_gambar_label()


func _gambar_dinding() -> void:
	# Panel beton vertikal supaya dinding tidak terasa rata.
	var x := 24.0
	while x < 616.0:
		draw_line(Vector2(x, Y_ATAP), Vector2(x, Y_LANTAI_1), WARNA_DINDING_GELAP, 1.0)
		x += 28.0

	# Garis sambungan horizontal.
	draw_line(Vector2(24.0, Y_ATAP), Vector2(616.0, Y_ATAP), WARNA_DINDING, 1.0)
	draw_line(Vector2(24.0, Y_LANTAI_2 + 6.0), Vector2(616.0, Y_LANTAI_2 + 6.0),
		WARNA_DINDING_GELAP, 1.0)

	# Lampu darurat.
	_lampu(Vector2(452.0, Y_ATAP + 20.0))
	_lampu(Vector2(452.0, Y_LANTAI_2 - 22.0))


func _lampu(pos: Vector2) -> void:
	draw_circle(pos, 14.0, Color(0.95, 0.76, 0.32, 0.06))
	draw_circle(pos, 6.0, Color(0.95, 0.76, 0.32, 0.12))
	draw_rect(Rect2(pos.x - 4.0, pos.y - 3.0, 8.0, 5.0), Color(0.95, 0.82, 0.45))


func _gambar_lantai() -> void:
	if lantai_2_terbuka():
		draw_rect(Rect2(24.0, Y_LANTAI_2, 592.0, 7.0), WARNA_LANTAI)
		draw_line(Vector2(24.0, Y_LANTAI_2), Vector2(616.0, Y_LANTAI_2),
			WARNA_LANTAI_TEBAL, 1.0)
	else:
		# Langit-langit gelap: petunjuk visual bahwa ada ruang di atas.
		draw_rect(Rect2(24.0, Y_LANTAI_2, 592.0, 7.0), Color(0.10, 0.10, 0.11))
		draw_string(
			_font, Vector2(24.0, Y_LANTAI_2 - 7.0), "SEALED — TOWER ACCESS REQUIRED",
			HORIZONTAL_ALIGNMENT_CENTER, 592.0, 8, Color(0.34, 0.34, 0.36)
		)

	draw_rect(Rect2(24.0, Y_LANTAI_1, 592.0, 9.0), WARNA_LANTAI)
	draw_line(Vector2(24.0, Y_LANTAI_1), Vector2(616.0, Y_LANTAI_1),
		WARNA_LANTAI_TEBAL, 1.0)

	_gambar_perabot()


## Perabot lantai 1 — pengisi ruang supaya bunker tidak terasa kosong.
func _gambar_perabot() -> void:
	var y := Y_LANTAI_1

	# Meja kerja di tengah.
	draw_rect(Rect2(306.0, y - 18.0, 76.0, 4.0), Color(0.34, 0.31, 0.26))
	draw_rect(Rect2(310.0, y - 14.0, 4.0, 14.0), Color(0.26, 0.24, 0.20))
	draw_rect(Rect2(374.0, y - 14.0, 4.0, 14.0), Color(0.26, 0.24, 0.20))
	# Perkakas di atas meja.
	draw_rect(Rect2(318.0, y - 24.0, 12.0, 6.0), Color(0.46, 0.44, 0.38))
	draw_rect(Rect2(342.0, y - 22.0, 6.0, 4.0), Color(0.52, 0.46, 0.30))

	# Peti logam di kiri.
	draw_rect(Rect2(252.0, y - 20.0, 30.0, 20.0), Color(0.28, 0.30, 0.26))
	draw_rect(Rect2(252.0, y - 20.0, 30.0, 3.0), Color(0.36, 0.38, 0.32))
	draw_line(Vector2(267.0, y - 20.0), Vector2(267.0, y), Color(0.22, 0.24, 0.20), 1.0)

	# Rak amunisi di kanan, sebelum tangga.
	draw_rect(Rect2(420.0, y - 34.0, 46.0, 3.0), Color(0.32, 0.30, 0.26))
	draw_rect(Rect2(420.0, y - 20.0, 46.0, 3.0), Color(0.32, 0.30, 0.26))
	draw_rect(Rect2(422.0, y - 31.0, 8.0, 7.0), Color(0.44, 0.40, 0.28))
	draw_rect(Rect2(434.0, y - 31.0, 8.0, 7.0), Color(0.44, 0.40, 0.28))
	draw_rect(Rect2(446.0, y - 17.0, 12.0, 5.0), Color(0.38, 0.36, 0.30))


func _gambar_tangga() -> void:
	var langkah := 8
	var tinggi := (Y_LANTAI_1 - Y_LANTAI_2) / float(langkah)
	var lebar := (TANGGA_X_MAX - TANGGA_X_MIN) / float(langkah)

	var warna := WARNA_TANGGA if lantai_2_terbuka() else Color(0.22, 0.21, 0.19)
	for i in range(langkah):
		var y := Y_LANTAI_1 - tinggi * float(i + 1)
		var x := TANGGA_X_MIN + lebar * float(i)
		draw_rect(Rect2(x, y, TANGGA_X_MAX - x, 4.0), warna)

	if not lantai_2_terbuka():
		var tengah := (TANGGA_X_MIN + TANGGA_X_MAX) * 0.5
		var y_tengah := (Y_LANTAI_1 + Y_LANTAI_2) * 0.5
		draw_line(Vector2(tengah - 14.0, y_tengah - 9.0),
			Vector2(tengah + 14.0, y_tengah + 9.0), Color(0.58, 0.26, 0.22), 2.0)
		draw_line(Vector2(tengah - 14.0, y_tengah + 9.0),
			Vector2(tengah + 14.0, y_tengah - 9.0), Color(0.58, 0.26, 0.22), 2.0)


func _gambar_kasur() -> void:
	var x := KASUR_X_MIN
	var lebar := KASUR_X_MAX - KASUR_X_MIN
	var y := Y_LANTAI_1

	# Rangka.
	draw_rect(Rect2(x, y - 14.0, lebar, 14.0), Color(0.30, 0.28, 0.25))
	# Kasur.
	draw_rect(Rect2(x + 3.0, y - 20.0, lebar - 6.0, 7.0), Color(0.44, 0.42, 0.40))
	# Bantal.
	draw_rect(Rect2(x + 6.0, y - 24.0, 18.0, 5.0), Color(0.58, 0.56, 0.53))
	# Selimut.
	draw_rect(Rect2(x + 26.0, y - 20.0, lebar - 32.0, 6.0), Color(0.34, 0.38, 0.34))

	draw_string(
		_font, Vector2(x, y + 13.0), "REST", HORIZONTAL_ALIGNMENT_CENTER, lebar, 7, WARNA_REDUP
	)


func _gambar_pintu() -> void:
	var x := PINTU_X_MIN
	var y := Y_LANTAI_1
	draw_rect(Rect2(x, y - 48.0, 34.0, 48.0), Color(0.20, 0.21, 0.23))
	draw_rect(Rect2(x + 3.0, y - 44.0, 28.0, 44.0), Color(0.28, 0.29, 0.31))
	draw_circle(Vector2(x + 26.0, y - 24.0), 2.0, WARNA_AKSEN)
	draw_string(
		_font, Vector2(x - 6.0, y + 13.0), "EXIT", HORIZONTAL_ALIGNMENT_CENTER, 46.0, 7, WARNA_REDUP
	)


func _gambar_label() -> void:
	var lantai := 1
	var pemain = get_tree().get_first_node_in_group("pemain")
	if pemain != null and is_instance_valid(pemain):
		lantai = pemain.lantai

	draw_string(
		_font, Vector2(200.0, 26.0), "BUNKER INTERIOR  ·  FLOOR %d" % lantai,
		HORIZONTAL_ALIGNMENT_CENTER, 240.0, 10, WARNA_AKSEN
	)

	var petunjuk := "A/D move"
	if lantai_2_terbuka():
		petunjuk += "  ·  W/S stairs"
	petunjuk += "  ·  E exit"
	draw_string(
		_font, Vector2(180.0, 336.0), petunjuk,
		HORIZONTAL_ALIGNMENT_CENTER, 294.0, 8, WARNA_REDUP
	)

	# Indikator regenerasi saat pemain berdiri di kasur.
	if pemain != null and is_instance_valid(pemain) and lantai == 1 \
			and di_zona_kasur(pemain.global_position.x) \
			and GameState.hp_pemain < GameState.HP_PEMAIN_MAKS - 0.5:
		draw_string(
			_font, Vector2(KASUR_X_MIN - 20.0, Y_LANTAI_1 - 34.0),
			"RESTING  +%d HP/s" % int(KASUR_REGEN),
			HORIZONTAL_ALIGNMENT_CENTER, 116.0, 8, WARNA_BAIK
		)
