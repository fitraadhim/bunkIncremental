extends Resource
## Data satu level — daftar konfigurasi wave-nya.

@export var id: int = 1
@export var nama: String = "Level 1"
@export var deskripsi: String = ""
## Jumlah wave di level ini.
@export var jumlah_wave: int = 5
## Pengali HP zombie di level ini (1.0 = normal).
@export var pengali_hp: float = 1.0
## Pengali kecepatan zombie.
@export var pengali_kecepatan: float = 1.0
## Pesan yang muncul saat level dimulai.
@export var pesan_mulai: String = ""
## Pesan saat level selesai.
@export var pesan_selesai: String = ""
