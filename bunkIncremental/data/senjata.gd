class_name Senjata
extends Resource
## Definisi satu senjata. Dipakai oleh player dan (nanti) skill tree.
## Dibuat sebagai Resource supaya nanti tinggal bikin file .tres baru
## tanpa menyentuh kode sama sekali.

@export var id: String = ""
@export var nama: String = ""
## "tembak" memakai peluru, "tebas" tidak.
@export var jenis: String = "tembak"
@export var kaliber: String = ""

@export_group("Tempur")
@export var damage: float = 10.0
@export var cooldown: float = 0.4
@export var jangkauan_tebas: float = 26.0

@export_group("Amunisi")
@export var kapasitas_magasin: int = 12
@export var waktu_reload: float = 1.2

@export_group("Progresi")
@export var harga_buka: int = 0
@export_multiline var deskripsi: String = ""
