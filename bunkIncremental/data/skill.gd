class_name Skill
extends Resource
## Satu node di skill tree.
##
## Efek TIDAK PERNAH ditulis ke angka dasar GameState. Semua efek adalah
## turunan yang dijumlahkan oleh SkillTree.efek_total(kunci). Jadi kalau
## skill di-reset, cukup kosongkan daftar yang dimiliki — tidak ada angka
## yang perlu dikembalikan secara manual.
##
## Kunci efek yang dikenal (lihat GameState untuk pemakaiannya):
##   damage_persen          +N%  damage senjata pemain
##   reload_persen          -N%  waktu reload (nilai negatif = lebih cepat)
##   hp_bunker_tambah       +N   HP maksimum bunker
##   hp_pagar_persen        +N%  ketahanan pagar
##   regen_bunker           +N   HP bunker per detik
##   slot_pabrik_tambah     +N   slot antrean pabrik
##   scrap_persen           -N%  kebutuhan scrap per peluru
##   kecepatan_produksi_persen  +N% kecepatan pabrik
##   harga_jual_persen      +N%  harga jual minyak
##   refresh_harga_persen   -N%  jeda refresh pasar
##   power_per_oil_tambah   +N   power per crude oil
##   listrik_maks_tambah    +N   kapasitas baterai
##   buka_lantai_2          +1   membuka tangga ke lantai 2

@export var id: String = ""
@export var nama: String = ""
## combat | fortify | industry | economy | engineering
@export var cabang: String = "combat"
## 1..3, dipakai untuk tata letak kolom di panel skill.
@export var tier: int = 1
@export var deskripsi: String = ""
## Biaya dalam dolar. Diisi di sub-fase 4.4 setelah balance pass.
@export var biaya: int = 0
## ID skill lain yang wajib dimiliki lebih dulu.
@export var prasyarat: Array = []
## kunci efek -> nilai (float). Dijumlahkan antar skill.
@export var efek: Dictionary = {}


func punya_efek(kunci: String) -> bool:
	return efek.has(kunci)
