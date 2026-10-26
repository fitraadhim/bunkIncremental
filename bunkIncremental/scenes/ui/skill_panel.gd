extends Control
## Panel skill tree — terpisah dari terminal, dibuka dengan K.
##
## Tema militer: latar hijau zaitun gelap, grid halus, sudut bracket, node
## heksagon. Semua digambar lewat _draw(), jadi belum butuh aset apa pun.
##
## Selama panel terbuka game di-pause, tapi GameState punya process_mode
## ALWAYS sehingga ekonomi tetap berjalan — sama seperti terminal.

signal ditutup

const WARNA_TEKS := Color(0.88, 0.89, 0.84)
const WARNA_REDUP := Color(0.52, 0.55, 0.48)
const WARNA_AKSEN := Color(0.80, 0.84, 0.46)
const WARNA_BAIK := Color(0.55, 0.85, 0.50)
const WARNA_BURUK := Color(1.0, 0.45, 0.32)
const WARNA_UANG := Color(0.95, 0.76, 0.32)

const WARNA_PANEL := Color(0.075, 0.090, 0.075, 0.97)
const WARNA_BINGKAI := Color(0.40, 0.45, 0.32, 0.95)
const WARNA_GRID := Color(0.16, 0.18, 0.14, 0.75)
const WARNA_GARIS_MATI := Color(0.24, 0.27, 0.22)

## Engineering sengaja di tengah supaya garis prasyaratnya dari FORTIFY
## tidak menyeberangi dua kolom lain.
const URUTAN_CABANG := ["combat", "fortify", "engineering", "industry", "economy"]
const LABEL_CABANG := {
	"combat": "COMBAT",
	"fortify": "FORTIFY",
	"engineering": "ENGINEERING",
	"industry": "INDUSTRY",
	"economy": "ECONOMY",
}

const X_AWAL := 84.0
const JARAK_KOLOM := 118.0
const Y_TIER := [80.0, 140.0, 200.0]
const RADIUS_NODE := 17.0
const LEBAR_LABEL := 104.0
## Tinggi pita latar di belakang nama skill, supaya garis prasyarat terlihat
## "terpotong" oleh label dan teksnya tetap terbaca.
const TINGGI_PITA := 15.0

const BINGKAI := Rect2(24.0, 18.0, 592.0, 324.0)
const KOTAK_DETAIL := Rect2(34.0, 250.0, 572.0, 84.0)

var _terpilih: String = ""
var _hover: String = ""
## id skill -> Vector2 posisi pusat heksagon.
var _posisi: Dictionary = {}

var _label: Dictionary = {}
var _tombol_beli: Button
var _font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_font = ThemeDB.fallback_font
	_siapkan_posisi()
	_bangun_ui()
	SkillTree.skill_berubah.connect(_on_skill_berubah)


# ---------------------------------------------------------------------------
# Buka / tutup
# ---------------------------------------------------------------------------

func buka() -> void:
	visible = true
	get_tree().paused = true
	_hover = ""
	if _terpilih == "" or SkillTree.sudah_dimiliki(_terpilih):
		_terpilih = _pilih_awal()
	_perbarui_semua()


func tutup() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	ditutup.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("buka_skill") or event.is_action_pressed("jeda"):
		tutup()
		get_viewport().set_input_as_handled()


func _pilih_awal() -> String:
	for item in SkillTree.semua():
		if item is Skill and SkillTree.bisa_beli(item.id):
			return item.id
	for item in SkillTree.semua():
		if item is Skill:
			return item.id
	return ""


# ---------------------------------------------------------------------------
# Tata letak
# ---------------------------------------------------------------------------

func _siapkan_posisi() -> void:
	_posisi.clear()
	for i in range(URUTAN_CABANG.size()):
		var cabang: String = URUTAN_CABANG[i]
		for skill in SkillTree.per_cabang(cabang):
			var tier := clampi(skill.tier - 1, 0, Y_TIER.size() - 1)
			_posisi[skill.id] = Vector2(X_AWAL + i * JARAK_KOLOM, Y_TIER[tier])


func _node_di(titik: Vector2) -> String:
	for id in _posisi.keys():
		if titik.distance_to(_posisi[id]) <= RADIUS_NODE + 8.0:
			return id
	return ""


# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

func _bangun_ui() -> void:
	var tema := Theme.new()
	tema.default_font_size = 9
	theme = tema

	mouse_filter = Control.MOUSE_FILTER_STOP

	var judul := _buat_label("FIELD MANUAL  //  SKILL MATRIX", 11, WARNA_AKSEN)
	judul.position = Vector2(38, 24)
	add_child(judul)

	_label["uang"] = _buat_label("", 10, WARNA_UANG)
	_label["uang"].position = Vector2(470, 25)
	_label["uang"].size = Vector2(130, 14)
	_label["uang"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_label["uang"])

	var petunjuk := _buat_label("CLICK NODE  ·  K/ESC CLOSE", 7, WARNA_REDUP)
	petunjuk.position = Vector2(300, 27)
	petunjuk.size = Vector2(162, 12)
	petunjuk.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(petunjuk)

	# --- Kotak detail ---
	var kotak := PanelContainer.new()
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color(0.055, 0.065, 0.055, 0.95)
	gaya.border_color = Color(0.30, 0.34, 0.26, 0.9)
	gaya.set_border_width_all(1)
	gaya.content_margin_left = 10
	gaya.content_margin_right = 10
	gaya.content_margin_top = 6
	gaya.content_margin_bottom = 6
	kotak.add_theme_stylebox_override("panel", gaya)
	kotak.position = KOTAK_DETAIL.position
	kotak.custom_minimum_size = KOTAK_DETAIL.size
	add_child(kotak)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kotak.add_child(baris)

	var kiri := VBoxContainer.new()
	kiri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kiri.add_theme_constant_override("separation", 2)
	baris.add_child(kiri)

	_label["nama"] = _buat_label("", 11, WARNA_TEKS)
	kiri.add_child(_label["nama"])

	_label["desk"] = _buat_label("", 8, WARNA_REDUP)
	_label["desk"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label["desk"].custom_minimum_size = Vector2(380, 26)
	kiri.add_child(_label["desk"])

	_label["syarat"] = _buat_label("", 7, WARNA_REDUP)
	kiri.add_child(_label["syarat"])

	var kanan := VBoxContainer.new()
	kanan.add_theme_constant_override("separation", 4)
	kanan.custom_minimum_size = Vector2(132, 0)
	baris.add_child(kanan)

	_label["biaya"] = _buat_label("", 12, WARNA_UANG)
	_label["biaya"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kanan.add_child(_label["biaya"])

	_tombol_beli = Button.new()
	_tombol_beli.text = "ACQUIRE"
	_tombol_beli.focus_mode = Control.FOCUS_NONE
	_tombol_beli.custom_minimum_size = Vector2(0, 22)
	_tombol_beli.pressed.connect(_on_beli)
	kanan.add_child(_tombol_beli)


func _buat_label(teks: String, ukuran: int, warna: Color) -> Label:
	var label := Label.new()
	label.text = teks
	label.add_theme_font_size_override("font_size", ukuran)
	label.add_theme_color_override("font_color", warna)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# ---------------------------------------------------------------------------
# Interaksi
# ---------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var baru := _node_di(event.position)
		if baru != _hover:
			_hover = baru
			queue_redraw()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var node := _node_di(event.position)
		if node != "":
			_terpilih = node
			_perbarui_detail()
			queue_redraw()
		accept_event()


func _on_beli() -> void:
	if _terpilih == "":
		return
	if SkillTree.beli(_terpilih):
		_perbarui_detail()
		queue_redraw()


func _on_skill_berubah() -> void:
	if visible:
		_perbarui_detail()
		queue_redraw()


func _process(_delta: float) -> void:
	if not visible:
		return
	_label["uang"].text = "$%d" % GameState.uang


func _perbarui_semua() -> void:
	_label["uang"].text = "$%d" % GameState.uang
	_perbarui_detail()
	queue_redraw()


func _perbarui_detail() -> void:
	var skill: Skill = SkillTree.ambil(_terpilih)
	if skill == null:
		_label["nama"].text = "SELECT A NODE"
		_label["desk"].text = "Click a hexagon to read its field notes."
		_label["syarat"].text = ""
		_label["biaya"].text = ""
		_tombol_beli.text = "—"
		_tombol_beli.disabled = true
		return

	_label["nama"].text = "%s   ·   %s TIER %d" % [
		skill.nama.to_upper(), LABEL_CABANG.get(skill.cabang, ""), skill.tier
	]
	_label["desk"].text = skill.deskripsi
	_label["biaya"].text = "$%d" % skill.biaya

	match SkillTree.alasan_tidak_bisa(skill.id):
		"":
			_label["syarat"].text = "READY TO ACQUIRE"
			_label["syarat"].add_theme_color_override("font_color", WARNA_BAIK)
			_tombol_beli.text = "ACQUIRE"
			_tombol_beli.disabled = false
		"dimiliki":
			_label["syarat"].text = "ALREADY ACQUIRED"
			_label["syarat"].add_theme_color_override("font_color", WARNA_BAIK)
			_tombol_beli.text = "OWNED"
			_tombol_beli.disabled = true
		"prasyarat":
			_label["syarat"].text = "REQUIRES:  %s" % _nama_prasyarat(skill)
			_label["syarat"].add_theme_color_override("font_color", WARNA_BURUK)
			_tombol_beli.text = "LOCKED"
			_tombol_beli.disabled = true
		"uang":
			_label["syarat"].text = "NOT ENOUGH FUNDS"
			_label["syarat"].add_theme_color_override("font_color", WARNA_BURUK)
			_tombol_beli.text = "ACQUIRE"
			_tombol_beli.disabled = true
		_:
			_label["syarat"].text = "UNAVAILABLE"
			_tombol_beli.text = "—"
			_tombol_beli.disabled = true


func _nama_prasyarat(skill: Skill) -> String:
	var nama: Array = []
	for id in skill.prasyarat:
		var lain: Skill = SkillTree.ambil(str(id))
		if lain != null:
			nama.append(lain.nama.to_upper())
	return ", ".join(nama)


# ---------------------------------------------------------------------------
# Gambar
# ---------------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.02, 1.0))
	draw_rect(BINGKAI, WARNA_PANEL)
	draw_rect(BINGKAI, WARNA_BINGKAI, false, 1.0)
	_kurung(BINGKAI.grow(-4.0), 14.0, WARNA_AKSEN, 1.0)

	_gambar_grid()
	_gambar_kepala_cabang()
	_gambar_garis()
	_gambar_node()


func _kurung(rect: Rect2, panjang: float, warna: Color, tebal: float) -> void:
	var kiri := rect.position.x
	var atas := rect.position.y
	var kanan := rect.end.x
	var bawah := rect.end.y
	draw_line(Vector2(kiri, atas), Vector2(kiri + panjang, atas), warna, tebal)
	draw_line(Vector2(kiri, atas), Vector2(kiri, atas + panjang), warna, tebal)
	draw_line(Vector2(kanan, atas), Vector2(kanan - panjang, atas), warna, tebal)
	draw_line(Vector2(kanan, atas), Vector2(kanan, atas + panjang), warna, tebal)
	draw_line(Vector2(kiri, bawah), Vector2(kiri + panjang, bawah), warna, tebal)
	draw_line(Vector2(kiri, bawah), Vector2(kiri, bawah - panjang), warna, tebal)
	draw_line(Vector2(kanan, bawah), Vector2(kanan - panjang, bawah), warna, tebal)
	draw_line(Vector2(kanan, bawah), Vector2(kanan, bawah - panjang), warna, tebal)


func _gambar_grid() -> void:
	var y := 60.0
	while y < 232.0:
		draw_line(Vector2(34.0, y), Vector2(606.0, y), WARNA_GRID, 0.5)
		y += 12.0
	for i in range(URUTAN_CABANG.size()):
		var x := X_AWAL + i * JARAK_KOLOM
		draw_line(Vector2(x, 62.0), Vector2(x, 228.0), WARNA_GRID, 0.5)


func _gambar_kepala_cabang() -> void:
	for i in range(URUTAN_CABANG.size()):
		var cabang: String = URUTAN_CABANG[i]
		var x := X_AWAL + i * JARAK_KOLOM
		draw_string(
			_font, Vector2(x - 60.0, 56.0), LABEL_CABANG.get(cabang, cabang),
			HORIZONTAL_ALIGNMENT_CENTER, 120.0, 8, WARNA_REDUP
		)


func _gambar_garis() -> void:
	for skill in SkillTree.semua():
		if not (skill is Skill):
			continue
		if not _posisi.has(skill.id):
			continue
		var ke: Vector2 = _posisi[skill.id]
		for id_syarat in skill.prasyarat:
			var dari_id := str(id_syarat)
			if not _posisi.has(dari_id):
				continue
			var dari: Vector2 = _posisi[dari_id]
			var dimiliki := SkillTree.sudah_dimiliki(skill.id)
			var siap := SkillTree.bisa_beli(skill.id)
			var warna := WARNA_GARIS_MATI
			if dimiliki:
				warna = WARNA_BAIK
			elif siap:
				warna = WARNA_AKSEN
			# Mulai dari tepi heksagon, berhenti di pita label, supaya garis
			# tidak menembus tulisan nama skill.
			var arah := (ke - dari).normalized()
			var awal := dari + arah * (RADIUS_NODE + 2.0)
			var akhir := ke - arah * (RADIUS_NODE + 2.0)
			if dimiliki or siap:
				draw_line(awal, akhir, warna, 1.0)
			else:
				draw_dashed_line(awal, akhir, warna, 1.0, 4.0)


func _gambar_node() -> void:
	for skill in SkillTree.semua():
		if not (skill is Skill) or not _posisi.has(skill.id):
			continue
		var pusat: Vector2 = _posisi[skill.id]
		var dimiliki := SkillTree.sudah_dimiliki(skill.id)
		var siap := SkillTree.bisa_beli(skill.id)
		var disorot: bool = skill.id == _hover or skill.id == _terpilih

		var isi := Color(0.11, 0.12, 0.10)
		var garis := WARNA_GARIS_MATI
		var teks := WARNA_REDUP
		if dimiliki:
			isi = Color(0.16, 0.28, 0.15)
			garis = WARNA_BAIK
			teks = WARNA_BAIK
		elif siap:
			isi = Color(0.20, 0.20, 0.10)
			garis = WARNA_AKSEN
			teks = WARNA_AKSEN

		var heks := _heksagon(pusat, RADIUS_NODE)
		draw_colored_polygon(heks, isi)
		draw_polyline(_tutup_poli(heks), garis, 1.5 if disorot else 1.0, true)

		if disorot:
			var luar := _heksagon(pusat, RADIUS_NODE + 5.0)
			draw_polyline(_tutup_poli(luar), Color(garis, 0.45), 1.0, true)

		# Angka tier di dalam heksagon.
		draw_string(
			_font, pusat + Vector2(-10.0, 4.0), str(skill.tier),
			HORIZONTAL_ALIGNMENT_CENTER, 20.0, 10, teks
		)

		# Nama skill di bawah heksagon, dengan pita latar supaya garis
		# prasyarat yang lewat di belakangnya tidak mengganggu bacaan.
		var pita := Rect2(
			pusat.x - LEBAR_LABEL * 0.5,
			pusat.y + RADIUS_NODE + 2.0,
			LEBAR_LABEL,
			TINGGI_PITA
		)
		draw_rect(pita, Color(0.075, 0.090, 0.075, 1.0))
		var warna_nama := WARNA_TEKS if (dimiliki or siap) else WARNA_REDUP
		draw_multiline_string(
			_font, pusat + Vector2(-LEBAR_LABEL * 0.5, RADIUS_NODE + 13.0),
			skill.nama, HORIZONTAL_ALIGNMENT_CENTER, LEBAR_LABEL, 7, 2, warna_nama
		)


func _heksagon(pusat: Vector2, r: float) -> PackedVector2Array:
	var titik := PackedVector2Array()
	for i in range(6):
		var sudut := deg_to_rad(60.0 * i - 30.0)
		titik.append(pusat + Vector2(cos(sudut), sin(sudut)) * r)
	return titik


func _tutup_poli(titik: PackedVector2Array) -> PackedVector2Array:
	var hasil := titik.duplicate()
	if hasil.size() > 0:
		hasil.append(hasil[0])
	return hasil
