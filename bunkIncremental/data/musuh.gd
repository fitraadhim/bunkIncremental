class_name Musuh
extends Resource
## Definisi satu tipe zombie. Angka drop memakai Vector2i(min, maks).

@export var id: String = ""
@export var nama: String = ""
@export var hp: float = 20.0
@export var kecepatan: float = 20.0
@export var damage: float = 5.0
@export var jeda_serang: float = 1.0

@export_group("Hadiah")
@export var drop_minyak: Vector2i = Vector2i(2, 4)
@export var drop_logam: Vector2i = Vector2i(1, 2)
@export var peluang_obat: float = 0.03

@export_group("Tampilan")
@export var warna: Color = Color(0.42, 0.56, 0.31, 1)
@export var skala: float = 1.0
