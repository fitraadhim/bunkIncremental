extends Control
## Terminal bunker — satu panel dengan tiga tab: MARKET, GENERATOR, FACTORY.
##
## Selama terminal terbuka, game di-pause. Tapi GameState punya
## process_mode ALWAYS, jadi harga pasar, pembakaran minyak, dan produksi
## peluru tetap berjalan. Ini konvensi umum game incremental.

signal ditutup

const WARNA_TEKS := Color(0.87, 0.89, 0.92)
const WARNA_REDUP := Color(0.52, 0.56, 0.62)
const WARNA_AKSEN := Color(0.95, 0.76, 0.32)
const WARNA_BAIK := Color(0.55, 0.88, 0.55)
const WARNA_BURUK := Color(1.0, 0.45, 0.32)
const WARNA_MINYAK := Color(0.91, 0.51, 0.23)
const WARNA_LISTRIK := Color(0.95, 0.85, 0.35)
const WARNA_BUNKER := Color(0.36, 0.62, 0.86)

const DAFTAR_TAB := ["market", "repair", "generator", "factory"]
const LABEL_TAB := {
	"market": "MARKET",
	"repair": "REPAIR",
	"generator": "POWER",
	"factory": "FACTORY",
}

var _tab_aktif: String = "market"
var _wadah_konten: VBoxContainer
var _tombol_tab: Dictionary = {}
var _label: Dictionary = {}
var _tombol: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_bangun_kerangka()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("buka_panel") or event.is_action_pressed("jeda"):
		tutup()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	_perbarui_dinamis()


# ---------------------------------------------------------------------------
# Buka / tutup
# ---------------------------------------------------------------------------

func buka() -> void:
	visible = true
	get_tree().paused = true
	_bangun_konten()
	_perbarui_dinamis()


func tutup() -> void:
	visible = false
	get_tree().paused = false
	ditutup.emit()


# ---------------------------------------------------------------------------
# Kerangka
# ---------------------------------------------------------------------------

func _bangun_kerangka() -> void:
	var tema := Theme.new()
	tema.default_font_size = 9
	theme = tema

	var peredup := ColorRect.new()
	peredup.color = Color(0.0, 0.0, 0.0, 0.62)
	peredup.set_anchors_preset(Control.PRESET_FULL_RECT)
	peredup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(peredup)

	var panel := PanelContainer.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.07, 0.08, 0.10, 0.97)
	gaya.border_color = Color(0.35, 0.40, 0.46, 0.9)
	gaya.set_border_width_all(1)
	gaya.set_corner_radius_all(3)
	gaya.content_margin_left = 10
	gaya.content_margin_right = 10
	gaya.content_margin_top = 8
	gaya.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", gaya)
	panel.position = Vector2(112, 46)
	panel.custom_minimum_size = Vector2(416, 262)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Baris judul
	var baris_judul := HBoxContainer.new()
	baris_judul.add_theme_constant_override("separation", 8)
	vbox.add_child(baris_judul)

	var judul := Label.new()
	judul.text = "BUNKER TERMINAL"
	judul.add_theme_font_size_override("font_size", 13)
	judul.add_theme_color_override("font_color", WARNA_AKSEN)
	baris_judul.add_child(judul)

	var pengisi := Control.new()
	pengisi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baris_judul.add_child(pengisi)

	var tombol_simpan := Button.new()
	tombol_simpan.text = "SAVE"
	tombol_simpan.pressed.connect(_on_simpan)
	baris_judul.add_child(tombol_simpan)

	var tombol_tutup := Button.new()
	tombol_tutup.text = "CLOSE  [TAB]"
	tombol_tutup.pressed.connect(tutup)
	baris_judul.add_child(tombol_tutup)

	# Baris tab
	var baris_tab := HBoxContainer.new()
	baris_tab.add_theme_constant_override("separation", 4)
	vbox.add_child(baris_tab)

	for kunci in DAFTAR_TAB:
		var tombol := Button.new()
		tombol.text = LABEL_TAB[kunci]
		tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tombol.focus_mode = Control.FOCUS_NONE
		tombol.pressed.connect(_ganti_tab.bind(kunci))
		baris_tab.add_child(tombol)
		_tombol_tab[kunci] = tombol

	var pemisah := HSeparator.new()
	vbox.add_child(pemisah)

	_wadah_konten = VBoxContainer.new()
	_wadah_konten.add_theme_constant_override("separation", 5)
	_wadah_konten.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_wadah_konten)


func _ganti_tab(kunci: String) -> void:
	_tab_aktif = kunci
	_bangun_konten()
	_perbarui_dinamis()


# ---------------------------------------------------------------------------
# Konten per tab
# ---------------------------------------------------------------------------

func _bangun_konten() -> void:
	_label.clear()
	_tombol.clear()

	for anak in _wadah_konten.get_children():
		_wadah_konten.remove_child(anak)
		anak.queue_free()

	match _tab_aktif:
		"market":
			_bangun_market()
		"repair":
			_bangun_repair()
		"generator":
			_bangun_generator()
		"factory":
			_bangun_factory()

	for kunci in _tombol_tab.keys():
		var tombol: Button = _tombol_tab[kunci]
		var aktif: bool = (kunci == _tab_aktif)
		tombol.add_theme_stylebox_override("normal", _gaya_tab(aktif))
		tombol.add_theme_stylebox_override("hover", _gaya_tab(true))
		tombol.add_theme_stylebox_override("pressed", _gaya_tab(true))
		tombol.add_theme_color_override(
			"font_color",
			WARNA_AKSEN if aktif else WARNA_REDUP
		)


func _gaya_tab(aktif: bool) -> StyleBoxFlat:
	var gaya := StyleBoxFlat.new()
	if aktif:
		gaya.bg_color = Color(0.18, 0.16, 0.10, 1.0)
		gaya.border_color = WARNA_AKSEN
	else:
		gaya.bg_color = Color(0.12, 0.13, 0.16, 1.0)
		gaya.border_color = Color(0.24, 0.27, 0.32, 1.0)
	gaya.set_border_width_all(1)
	gaya.set_corner_radius_all(2)
	gaya.content_margin_top = 3
	gaya.content_margin_bottom = 3
	return gaya


func _bangun_market() -> void:
	_wadah_konten.add_child(_buat_label("CRUDE OIL — BLACK MARKET", 10, WARNA_TEKS))

	_label["harga"] = _buat_label("", 15, WARNA_MINYAK)
	_wadah_konten.add_child(_label["harga"])

	_label["refresh"] = _buat_label("", 8, WARNA_REDUP)
	_wadah_konten.add_child(_label["refresh"])

	_label["stok"] = _buat_label("", 9, WARNA_TEKS)
	_wadah_konten.add_child(_label["stok"])

	_wadah_konten.add_child(_buat_pemisah())

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 5)
	_wadah_konten.add_child(baris)

	_tombol["jual_1"] = _buat_tombol(baris, "SELL 1", _on_jual.bind(1))
	_tombol["jual_10"] = _buat_tombol(baris, "SELL 10", _on_jual.bind(10))
	_tombol["jual_semua"] = _buat_tombol(baris, "SELL ALL", _on_jual_semua)

	var catatan := _buat_label(
		"Oil is the only thing worth money out here. But the generator burns it too.",
		8,
		WARNA_REDUP
	)
	catatan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catatan.custom_minimum_size = Vector2(0, 24)
	_wadah_konten.add_child(catatan)


func _bangun_repair() -> void:
	_wadah_konten.add_child(_buat_label("BUNKER INTEGRITY", 10, WARNA_TEKS))

	_label["hp_bunker"] = _buat_label("", 15, WARNA_BUNKER)
	_wadah_konten.add_child(_label["hp_bunker"])

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.max_value = GameState.HP_BUNKER_MAKS
	bar.value = GameState.hp_bunker
	var latar := StyleBoxFlat.new()
	latar.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	var isi := StyleBoxFlat.new()
	isi.bg_color = WARNA_BUNKER
	bar.add_theme_stylebox_override("background", latar)
	bar.add_theme_stylebox_override("fill", isi)
	_wadah_konten.add_child(bar)
	_label["bar_bunker"] = bar

	_wadah_konten.add_child(_buat_pemisah())

	_label["biaya_repair"] = _buat_label("", 9, WARNA_TEKS)
	_wadah_konten.add_child(_label["biaya_repair"])

	_label["peringatan_repair"] = _buat_label("", 8, WARNA_BURUK)
	_label["peringatan_repair"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label["peringatan_repair"].custom_minimum_size = Vector2(0, 22)
	_wadah_konten.add_child(_label["peringatan_repair"])

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 5)
	_wadah_konten.add_child(baris)

	_tombol["repair_25"] = _buat_tombol(baris, "PATCH +25 HP", _on_repair.bind(25.0))
	_tombol["repair_penuh"] = _buat_tombol(baris, "FULL REBUILD", _on_repair.bind(999.0))

	var catatan := _buat_label(
		"Concrete and steel cost money. If the bunker falls, you lose oil and the night starts over.",
		8,
		WARNA_REDUP
	)
	catatan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catatan.custom_minimum_size = Vector2(0, 24)
	_wadah_konten.add_child(catatan)


func _bangun_generator() -> void:
	_wadah_konten.add_child(_buat_label("DIESEL GENERATOR", 10, WARNA_TEKS))

	_label["status_gen"] = _buat_label("", 15, WARNA_LISTRIK)
	_wadah_konten.add_child(_label["status_gen"])

	_label["daya"] = _buat_label("", 9, WARNA_TEKS)
	_wadah_konten.add_child(_label["daya"])

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.max_value = GameState.LISTRIK_MAKS
	bar.value = GameState.listrik
	var latar := StyleBoxFlat.new()
	latar.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	var isi := StyleBoxFlat.new()
	isi.bg_color = WARNA_LISTRIK
	bar.add_theme_stylebox_override("background", latar)
	bar.add_theme_stylebox_override("fill", isi)
	_wadah_konten.add_child(bar)
	_label["bar_daya"] = bar

	_wadah_konten.add_child(_buat_pemisah())

	_label["bahan_bakar"] = _buat_label("", 9, WARNA_TEKS)
	_wadah_konten.add_child(_label["bahan_bakar"])

	var catatan := _buat_label(
		"Burns 1 crude oil every 2s and stores 10 power. Stops when the tank is full.",
		8,
		WARNA_REDUP
	)
	catatan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catatan.custom_minimum_size = Vector2(0, 24)
	_wadah_konten.add_child(catatan)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 5)
	_wadah_konten.add_child(baris)

	_tombol["toggle_gen"] = _buat_tombol(baris, "TOGGLE", _on_toggle_generator)


func _bangun_factory() -> void:
	_wadah_konten.add_child(_buat_label("AMMUNITION FACTORY", 10, WARNA_TEKS))

	var resep: ResepPeluru = Data.resep_peluru.get("9mm")
	_label["resep"] = _buat_label(
		"9mm Round  ·  %d scrap + %ss  →  %d rounds" % [resep.logam, String.num(resep.waktu, 1), resep.hasil],
		9,
		WARNA_TEKS
	)
	_wadah_konten.add_child(_label["resep"])

	_label["antrean"] = _buat_label("", 9, WARNA_TEKS)
	_wadah_konten.add_child(_label["antrean"])

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.max_value = 1.0
	bar.value = 0.0
	var latar := StyleBoxFlat.new()
	latar.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	var isi := StyleBoxFlat.new()
	isi.bg_color = Color(0.55, 0.78, 0.95)
	bar.add_theme_stylebox_override("background", latar)
	bar.add_theme_stylebox_override("fill", isi)
	_wadah_konten.add_child(bar)
	_label["bar_produksi"] = bar

	_wadah_konten.add_child(_buat_pemisah())

	_label["daya_pabrik"] = _buat_label("", 9, WARNA_TEKS)
	_wadah_konten.add_child(_label["daya_pabrik"])

	_label["peringatan"] = _buat_label("", 8, WARNA_BURUK)
	_label["peringatan"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label["peringatan"].custom_minimum_size = Vector2(0, 22)
	_wadah_konten.add_child(_label["peringatan"])

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 5)
	_wadah_konten.add_child(baris)

	_tombol["buat_1"] = _buat_tombol(baris, "CRAFT x1", _on_buat.bind(1))
	_tombol["buat_5"] = _buat_tombol(baris, "CRAFT x5", _on_buat.bind(5))


# ---------------------------------------------------------------------------
# Aksi
# ---------------------------------------------------------------------------

func _on_jual(jumlah: int) -> void:
	var dapat := GameState.jual_minyak(jumlah)
	if dapat <= 0:
		GameState.pesan.emit("You have no oil to sell", WARNA_BURUK)
	else:
		GameState.pesan.emit("Sold oil for $%d" % dapat, WARNA_BAIK)


func _on_jual_semua() -> void:
	_on_jual(GameState.minyak)


func _on_toggle_generator() -> void:
	GameState.set_generator(not GameState.generator_aktif)


func _on_repair(jumlah: float) -> void:
	GameState.beli_perbaikan(jumlah)


func _on_buat(jumlah: int) -> void:
	var berhasil := 0
	for i in range(jumlah):
		if GameState.antre_peluru("9mm"):
			berhasil += 1
		else:
			break
	if berhasil > 0:
		GameState.pesan.emit("Queued %d batch(es) of 9mm" % berhasil, WARNA_BAIK)


func _on_simpan() -> void:
	SaveManager.simpan()
	GameState.pesan.emit("Game saved", WARNA_BAIK)


# ---------------------------------------------------------------------------
# Update dinamis
# ---------------------------------------------------------------------------

func _perbarui_dinamis() -> void:
	match _tab_aktif:
		"market":
			_perbarui_market()
		"repair":
			_perbarui_repair()
		"generator":
			_perbarui_generator()
		"factory":
			_perbarui_factory()


func _perbarui_market() -> void:
	if not _label.has("harga"):
		return

	_label["harga"].text = "$%s / unit" % Formatter.harga(GameState.harga_minyak)

	var tren := "stable"
	var warna := WARNA_REDUP
	if GameState.tren_harga == "up":
		tren = "rising"
		warna = WARNA_BAIK
	elif GameState.tren_harga == "down":
		tren = "falling"
		warna = WARNA_BURUK
	_label["refresh"].text = "Market %s · price shifts in %s" % [
		tren, Formatter.waktu(GameState.sisa_refresh_harga)
	]
	_label["refresh"].add_theme_color_override("font_color", warna)

	_label["stok"].text = "You hold %d oil  →  $%d" % [
		GameState.minyak, Ekonomi.nilai_jual(GameState.minyak, GameState.harga_minyak)
	]

	if _tombol.has("jual_1"):
		_tombol["jual_1"].disabled = GameState.minyak < 1
		_tombol["jual_10"].disabled = GameState.minyak < 1
		_tombol["jual_semua"].disabled = GameState.minyak < 1


func _perbarui_repair() -> void:
	if not _label.has("hp_bunker"):
		return

	_label["hp_bunker"].text = "%d / %d HP" % [int(GameState.hp_bunker), int(GameState.HP_BUNKER_MAKS)]
	_label["bar_bunker"].value = GameState.hp_bunker

	var biaya := GameState.biaya_perbaikan()
	_label["biaya_repair"].text = "Repair cost: $%d   ·   You have: $%d" % [biaya, GameState.uang]

	var kurang := GameState.HP_BUNKER_MAKS - GameState.hp_bunker
	if kurang <= 0.5:
		_label["peringatan_repair"].text = "Structure intact. Nothing to fix."
		_label["peringatan_repair"].add_theme_color_override("font_color", WARNA_BAIK)
	elif GameState.uang < biaya:
		_label["peringatan_repair"].text = "Not enough money. Sell oil at the Market."
		_label["peringatan_repair"].add_theme_color_override("font_color", WARNA_BURUK)
	else:
		_label["peringatan_repair"].text = "Missing %d HP." % int(kurang)
		_label["peringatan_repair"].add_theme_color_override("font_color", WARNA_REDUP)

	var bisa := GameState.uang >= biaya and kurang > 0.5
	if _tombol.has("repair_25"):
		_tombol["repair_25"].disabled = not bisa
		_tombol["repair_penuh"].disabled = not bisa


func _perbarui_generator() -> void:
	if not _label.has("status_gen"):
		return

	if GameState.generator_aktif:
		_label["status_gen"].text = "RUNNING"
		_label["status_gen"].add_theme_color_override("font_color", WARNA_BAIK)
	else:
		_label["status_gen"].text = "STOPPED"
		_label["status_gen"].add_theme_color_override("font_color", WARNA_BURUK)

	_label["daya"].text = "Stored power: %s / %s" % [
		Formatter.angka(GameState.listrik), Formatter.angka(GameState.LISTRIK_MAKS)
	]
	_label["bar_daya"].value = GameState.listrik
	_label["bahan_bakar"].text = "Fuel tank: %d crude oil" % GameState.minyak

	if _tombol.has("toggle_gen"):
		_tombol["toggle_gen"].text = "SHUT DOWN" if GameState.generator_aktif else "START ENGINE"
		_tombol["toggle_gen"].disabled = (not GameState.generator_aktif) and GameState.minyak <= 0


func _perbarui_factory() -> void:
	if not _label.has("antrean"):
		return

	var resep: ResepPeluru = Data.resep_peluru.get("9mm")
	var jumlah_antre := GameState.antrean_pabrik.size()

	_label["antrean"].text = "Queue: %d / %d    ·    Scrap: %d    ·    9mm in stock: %d" % [
		jumlah_antre, GameState.KAPASITAS_ANTREAN, GameState.logam,
		GameState.jumlah_peluru("9mm")
	]

	_label["bar_produksi"].value = Produksi.progres(GameState.antrean_pabrik, Data.resep_peluru)
	_label["daya_pabrik"].text = "Power draw: %s /s   ·   Available: %s" % [
		String.num(resep.listrik, 1), Formatter.angka(GameState.listrik)
	]

	if jumlah_antre > 0 and GameState.listrik <= 0.0:
		_label["peringatan"].text = "No power — start the generator to keep the line moving."
	elif not GameState.generator_aktif and jumlah_antre > 0:
		_label["peringatan"].text = "Generator is off. The line will stall once stored power runs out."
	elif GameState.logam < resep.logam:
		_label["peringatan"].text = "Not enough scrap. Kill walkers to collect more."
	else:
		_label["peringatan"].text = ""

	var bisa := GameState.logam >= resep.logam and jumlah_antre < GameState.KAPASITAS_ANTREAN
	if _tombol.has("buat_1"):
		_tombol["buat_1"].disabled = not bisa
		_tombol["buat_5"].disabled = not bisa


# ---------------------------------------------------------------------------
# Helper widget
# ---------------------------------------------------------------------------

func _buat_label(teks: String, ukuran: int, warna: Color) -> Label:
	var label := Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", ukuran)
	label.add_theme_color_override("font_color", warna)
	return label


func _buat_tombol(induk: Node, teks: String, aksi: Callable) -> Button:
	var tombol := Button.new()
	tombol.text = teks
	tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tombol.pressed.connect(aksi)
	induk.add_child(tombol)
	return tombol


func _buat_pemisah() -> HSeparator:
	return HSeparator.new()
