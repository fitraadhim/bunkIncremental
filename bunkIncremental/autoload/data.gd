extends Node
## Data — registry konten game.
##
## Semua definisi senjata, musuh, dan resep dimuat di sini lewat preload
## eksplisit (bukan DirAccess) supaya tetap aman saat game di-export ke .exe.
## Untuk menambah konten baru: bikin file .tres lalu tambahkan ke daftar.

const DAFTAR_SENJATA: Array = [
	preload("res://data/senjata/pistol.tres"),
	preload("res://data/senjata/parang.tres"),
]

const DAFTAR_MUSUH: Array = [
	preload("res://data/musuh/zombie_biasa.tres"),
]

const DAFTAR_RESEP: Array = [
	preload("res://data/peluru/9mm.tres"),
]

var senjata: Dictionary = {}
var musuh: Dictionary = {}
var resep_peluru: Dictionary = {}


func _ready() -> void:
	_daftarkan(DAFTAR_SENJATA, senjata, "senjata")
	_daftarkan(DAFTAR_MUSUH, musuh, "musuh")
	_daftarkan(DAFTAR_RESEP, resep_peluru, "resep")


func _daftarkan(daftar: Array, target: Dictionary, label: String) -> void:
	for item in daftar:
		if item == null:
			push_warning("Data: entri %s kosong" % label)
			continue
		target[item.id] = item


## Ambil senjata berdasarkan id, dengan fallback ke pistol agar game tidak crash.
func ambil_senjata(id: String) -> Senjata:
	if senjata.has(id):
		return senjata[id]
	return senjata.get("pistol", null)


func ambil_musuh(id: String) -> Musuh:
	if musuh.has(id):
		return musuh[id]
	return musuh.values()[0] if not musuh.is_empty() else null
