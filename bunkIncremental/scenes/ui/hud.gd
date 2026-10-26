extends Control
## HUD — seluruh UI dibangun dari kode supaya gampang diubah tanpa
## menyentuh file .tscn. Teks in-game berbahasa Inggris.

const WARNA_TEKS := Color(0.87, 0.89, 0.92)
const WARNA_REDUP := Color(0.52, 0.56, 0.62)
const WARNA_MINYAK := Color(0.91, 0.51, 0.23)
const WARNA_LOGAM := Color(0.62, 0.67, 0.72)
const WARNA_OBAT := Color(0.86, 0.32, 0.36)
const WARNA_UANG := Color(0.95, 0.76, 0.32)
const WARNA_HP := Color(0.80, 0.26, 0.22)
const WARNA_BUNKER := Color(0.36, 0.62, 0.86)
const WARNA_BAIK := Color(0.55, 0.88, 0.55)
const WARNA_BURUK := Color(1.0, 0.45, 0.32)

const LEBAR_LAYAR := 640.0

var _label: Dictionary = {}
var _bar: Dictionary = {}
var _pemain: Node = null

var _label_pesan: Label
var _wadah_pesan: PanelContainer
var _sisa_pesan: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bangun()

	GameState.resource_berubah.connect(_perbarui_resource)
	GameState.hp_pemain_berubah.connect(_on_hp_pemain)
	GameState.hp_bunker_berubah.connect(_on_hp_bunker)
	GameState.listrik_berubah.connect(_on_listrik)
	GameState.wave_berubah.connect(_on_wave)
	GameState.peluru_berubah.connect(_on_peluru)

	_perbarui_resource()
	_on_hp_pemain(GameState.hp_pemain, GameState.HP_PEMAIN_MAKS)
	_on_hp_bunker(GameState.hp_bunker, GameState.HP_BUNKER_MAKS)
	_on_listrik(GameState.listrik, GameState.LISTRIK_MAKS)
	_on_wave(GameState.wave, GameState.zombie_hidup)


func _process(delta: float) -> void:
	# Harga pasar dan jumlah peluru berubah cepat, jadi cukup di-poll.
	if _label.has("pasar"):
		var panah := ""
		if GameState.tren_harga == "up":
			panah = " ^"
		elif GameState.tren_harga == "down":
			panah = " v"
		_label["pasar"].text = "OIL $%s%s  (%s)" % [
			Formatter.harga(GameState.harga_minyak),
			panah,
			Formatter.waktu(GameState.sisa_refresh_harga),
		]

	if _sisa_pesan > 0.0:
		_sisa_pesan -= delta
		if _sisa_pesan <= 0.6:
			_wadah_pesan.modulate.a = clampf(_sisa_pesan / 0.6, 0.0, 1.0)


func hubungkan_pemain(pemain: Node) -> void:
	_pemain = pemain
	if _pemain != null and _pemain.has_signal("magasin_berubah"):
		_pemain.magasin_berubah.connect(_on_magasin)
		_on_magasin(_pemain.isi_magasin, _pemain.senjata_tembak.kapasitas_magasin,
			GameState.jumlah_peluru(_pemain.senjata_tembak.kaliber))


func tampilkan_pesan(teks: String, warna: Color) -> void:
	if _label_pesan == null:
		return
	_label_pesan.text = teks
	_label_pesan.add_theme_color_override("font_color", warna)
	_wadah_pesan.modulate.a = 1.0
	_sisa_pesan = 2.8


# ---------------------------------------------------------------------------
# Pembangunan UI
# ---------------------------------------------------------------------------

func _bangun() -> void:
	_bangun_panel_resource()
	_bangun_panel_wave()
	_bangun_panel_kondisi()
	_bangun_panel_amunisi()
	_bangun_pesan()
	_bangun_petunjuk()


func _bangun_panel_resource() -> void:
	var panel := _buat_panel(Vector2(112, 0))
	panel.position = Vector2(6, 6)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	_label["minyak"] = _baris_resource(vbox, "OIL", WARNA_MINYAK)
	_label["logam"] = _baris_resource(vbox, "SCRAP", WARNA_LOGAM)
	_label["obat"] = _baris_resource(vbox, "MEDS", WARNA_OBAT)
	_label["uang"] = _baris_resource(vbox, "MONEY", WARNA_UANG)


func _bangun_panel_wave() -> void:
	var panel := _buat_panel(Vector2(142, 0))
	panel.position = Vector2(LEBAR_LAYAR - 148.0, 6)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	_label["wave"] = _buat_label("NIGHT 1", 12, WARNA_TEKS)
	vbox.add_child(_label["wave"])

	_label["sisa"] = _buat_label("0 walkers left", 8, WARNA_REDUP)
	vbox.add_child(_label["sisa"])

	_label["pasar"] = _buat_label("OIL $2.00", 8, WARNA_UANG)
	vbox.add_child(_label["pasar"])


func _bangun_panel_kondisi() -> void:
	var panel := _buat_panel(Vector2(168, 0))
	panel.position = Vector2(6, 306)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	_baris_bar(vbox, "YOU", WARNA_HP, "hp_pemain")
	_baris_bar(vbox, "BUNKER", WARNA_BUNKER, "hp_bunker")
	_baris_bar(vbox, "POWER", WARNA_UANG, "listrik")


func _bangun_panel_amunisi() -> void:
	var panel := _buat_panel(Vector2(150, 0))
	panel.position = Vector2(LEBAR_LAYAR - 156.0, 306)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	_label["amunisi_judul"] = _buat_label("9MM  ·  MAG / RESERVE", 8, WARNA_REDUP)
	vbox.add_child(_label["amunisi_judul"])

	_label["amunisi"] = _buat_label("0 / 0", 12, WARNA_TEKS)
	vbox.add_child(_label["amunisi"])


func _bangun_pesan() -> void:
	var wadah := PanelContainer.new()
	wadah.position = Vector2(0, 92)
	wadah.size = Vector2(LEBAR_LAYAR, 20)
	wadah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.03, 0.035, 0.05, 0.78)
	gaya.border_color = Color(0.30, 0.34, 0.40, 0.5)
	gaya.border_width_top = 1
	gaya.border_width_bottom = 1
	wadah.add_theme_stylebox_override("panel", gaya)
	wadah.modulate.a = 0.0
	add_child(wadah)

	_label_pesan = _buat_label("", 10, WARNA_TEKS)
	_label_pesan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_pesan.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_pesan.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_label_pesan.add_theme_constant_override("shadow_offset_x", 1)
	_label_pesan.add_theme_constant_override("shadow_offset_y", 1)
	wadah.add_child(_label_pesan)

	_wadah_pesan = wadah


func _bangun_petunjuk() -> void:
	var petunjuk := _buat_label(
		"A/D move   ·   LMB shoot   ·   SPACE machete   ·   Q medkit   ·   TAB terminal",
		8,
		Color(0.45, 0.48, 0.54)
	)
	petunjuk.position = Vector2(0, 344)
	petunjuk.size = Vector2(LEBAR_LAYAR, 12)
	petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(petunjuk)


# ---------------------------------------------------------------------------
# Helper widget
# ---------------------------------------------------------------------------

func _buat_panel(ukuran: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.06, 0.07, 0.09, 0.82)
	gaya.border_color = Color(0.30, 0.34, 0.40, 0.55)
	gaya.set_border_width_all(1)
	gaya.set_corner_radius_all(2)
	gaya.content_margin_left = 6
	gaya.content_margin_right = 6
	gaya.content_margin_top = 4
	gaya.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", gaya)
	panel.custom_minimum_size = ukuran
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _buat_label(teks: String, ukuran: int, warna: Color) -> Label:
	var label := Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", ukuran)
	label.add_theme_color_override("font_color", warna)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _baris_resource(induk: Node, judul: String, warna: Color) -> Label:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 5)
	induk.add_child(baris)

	var kotak := ColorRect.new()
	kotak.color = warna
	kotak.custom_minimum_size = Vector2(4, 4)
	kotak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(kotak)

	var label_judul := _buat_label(judul, 8, WARNA_REDUP)
	label_judul.custom_minimum_size = Vector2(42, 0)
	baris.add_child(label_judul)

	var label_nilai := _buat_label("0", 10, WARNA_TEKS)
	label_nilai.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_nilai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris.add_child(label_nilai)
	return label_nilai


func _baris_bar(induk: Node, judul: String, warna: Color, kunci: String) -> void:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 6)
	induk.add_child(baris)

	var label := _buat_label(judul, 8, WARNA_REDUP)
	label.custom_minimum_size = Vector2(48, 0)
	baris.add_child(label)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 100.0
	bar.custom_minimum_size = Vector2(0, 5)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var latar := StyleBoxFlat.new()
	latar.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	latar.set_corner_radius_all(1)

	var isi := StyleBoxFlat.new()
	isi.bg_color = warna
	isi.set_corner_radius_all(1)

	bar.add_theme_stylebox_override("background", latar)
	bar.add_theme_stylebox_override("fill", isi)

	baris.add_child(bar)
	_bar[kunci] = bar


# ---------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------

func _perbarui_resource() -> void:
	_label["minyak"].text = Formatter.angka(GameState.minyak)
	_label["logam"].text = Formatter.angka(GameState.logam)
	_label["obat"].text = Formatter.angka(GameState.obat)
	_label["uang"].text = "$" + Formatter.angka(GameState.uang)


func _on_hp_pemain(sekarang: float, maks: float) -> void:
	if not _bar.has("hp_pemain"):
		return
	_bar["hp_pemain"].max_value = maks
	_bar["hp_pemain"].value = sekarang


func _on_hp_bunker(sekarang: float, maks: float) -> void:
	if not _bar.has("hp_bunker"):
		return
	_bar["hp_bunker"].max_value = maks
	_bar["hp_bunker"].value = sekarang


func _on_listrik(sekarang: float, maks: float) -> void:
	if not _bar.has("listrik"):
		return
	_bar["listrik"].max_value = maks
	_bar["listrik"].value = sekarang


func _on_wave(nomor: int, sisa: int) -> void:
	if _label.has("wave"):
		_label["wave"].text = "NIGHT %d" % nomor
	if _label.has("sisa"):
		_label["sisa"].text = "%d walkers left" % sisa


func _on_peluru(_kaliber: String, _jumlah: int) -> void:
	if _pemain != null and is_instance_valid(_pemain):
		_on_magasin(_pemain.isi_magasin, _pemain.senjata_tembak.kapasitas_magasin, _jumlah)


func _on_magasin(isi: int, kapasitas: int, cadangan: int) -> void:
	if not _label.has("amunisi"):
		return
	_label["amunisi"].text = "%d / %d" % [isi, cadangan]
	var warna := WARNA_TEKS
	if isi <= 0:
		warna = WARNA_BURUK
	elif isi <= kapasitas / 3:
		warna = WARNA_UANG
	_label["amunisi"].add_theme_color_override("font_color", warna)
