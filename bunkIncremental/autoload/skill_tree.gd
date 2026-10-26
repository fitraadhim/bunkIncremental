extends Node
## SkillTree — pemilik skill yang sudah dibeli, dan satu-satunya tempat
## menghitung efek turunan.
##
## Prinsip: efek TIDAK PERNAH ditulis ke angka dasar GameState. Semua sistem
## lain memanggil efek_total(kunci) dan memakai hasilnya sebagai pengali atau
## penambah. Konsekuensinya:
##   - reset skill cukup mengosongkan daftar, tidak ada angka yang bocor;
##   - save/load tidak perlu menyimpan angka turunan, cukup daftar id;
##   - menambah skill baru tidak menyentuh kode mana pun.
##
## Hasil penjumlahan di-cache dan hanya dihitung ulang saat daftar berubah.

signal skill_berubah

const POHON: PohonSkill = preload("res://data/skill/pohon_skill.tres")

## id -> true. Hanya skill yang sudah dibeli.
var _dimiliki: Dictionary = {}
## id -> Skill, dibangun sekali saat _ready.
var _indeks: Dictionary = {}
## kunci efek -> total. Cache, dihitung ulang saat _cache_valid false.
var _cache: Dictionary = {}
var _cache_valid: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for item in POHON.daftar:
		if item is Skill:
			_indeks[item.id] = item


# ---------------------------------------------------------------------------
# Katalog
# ---------------------------------------------------------------------------

func semua() -> Array:
	return POHON.daftar


func ambil(id: String) -> Skill:
	return _indeks.get(id)


## Daftar id per cabang, urut tier. Dipakai panel skill untuk menyusun kolom.
func per_cabang(cabang: String) -> Array:
	var hasil: Array = []
	for item in POHON.daftar:
		if item is Skill and item.cabang == cabang:
			hasil.append(item)
	hasil.sort_custom(func(a, b): return a.tier < b.tier)
	return hasil


const DAFTAR_CABANG := ["combat", "fortify", "industry", "economy", "engineering"]


# ---------------------------------------------------------------------------
# Kepemilikan
# ---------------------------------------------------------------------------

func sudah_dimiliki(id: String) -> bool:
	return _dimiliki.has(id)


func jumlah_dimiliki() -> int:
	return _dimiliki.size()


## String kosong kalau boleh dibeli. Selain itu alasan penolakan, dipakai UI.
func alasan_tidak_bisa(id: String) -> String:
	var skill: Skill = ambil(id)
	if skill == null:
		return "tidak_ada"
	if sudah_dimiliki(id):
		return "dimiliki"
	for syarat in skill.prasyarat:
		if not sudah_dimiliki(str(syarat)):
			return "prasyarat"
	if GameState.uang < skill.biaya:
		return "uang"
	return ""


func bisa_beli(id: String) -> bool:
	return alasan_tidak_bisa(id) == ""


## Beli skill. Mengembalikan true kalau berhasil.
func beli(id: String) -> bool:
	var skill: Skill = ambil(id)
	if skill == null:
		return false
	var alasan := alasan_tidak_bisa(id)
	if alasan == "dimiliki":
		return false
	if alasan == "prasyarat":
		GameState.pesan.emit("Locked — a prerequisite is missing", Color(1.0, 0.6, 0.3))
		return false
	if alasan == "uang":
		GameState.pesan.emit("Not enough money for %s" % skill.nama, Color(1.0, 0.6, 0.3))
		return false
	if alasan != "":
		return false

	if not GameState.kurangi_resource("uang", skill.biaya):
		return false

	_dimiliki[id] = true
	_invalidasi()
	GameState.pesan.emit("Acquired %s" % skill.nama, Color(0.6, 0.9, 0.6))
	skill_berubah.emit()
	return true


# ---------------------------------------------------------------------------
# Efek turunan
# ---------------------------------------------------------------------------

## Total nilai satu kunci efek dari semua skill yang dimiliki.
## Mengembalikan 0.0 kalau kunci tidak dipakai skill mana pun.
func efek_total(kunci: String) -> float:
	if not _cache_valid:
		_hitung_cache()
	return float(_cache.get(kunci, 0.0))


func punya_efek(kunci: String) -> bool:
	return efek_total(kunci) > 0.0


func _hitung_cache() -> void:
	_cache.clear()
	for id in _dimiliki.keys():
		var skill: Skill = _indeks.get(id)
		if skill == null:
			continue
		for kunci in skill.efek.keys():
			_cache[kunci] = float(_cache.get(kunci, 0.0)) + float(skill.efek[kunci])
	_cache_valid = true


func _invalidasi() -> void:
	_cache_valid = false


# ---------------------------------------------------------------------------
# Simpan / muat
# ---------------------------------------------------------------------------

func ke_array() -> Array:
	return _dimiliki.keys()


func dari_array(daftar: Array) -> void:
	_dimiliki.clear()
	for id in daftar:
		var skill: Skill = _indeks.get(str(id))
		if skill != null:
			_dimiliki[skill.id] = true
	_invalidasi()
	skill_berubah.emit()


func reset() -> void:
	_dimiliki.clear()
	_invalidasi()
	skill_berubah.emit()
