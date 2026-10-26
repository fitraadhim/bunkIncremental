extends Node
## SaveManager — simpan/muat progres ke user://simpanan.json
##
## Field "versi" wajib ada sejak awal. Kalau nanti format save berubah,
## kita bisa migrasi save lama alih-alih menghapusnya.

const VERSI_SAVE := 1
const JALUR_SIMPAN := "user://simpanan.json"
const INTERVAL_AUTOSAVE := 10.0

var _timer_autosave: float = 0.0
var _sudah_dimuat: bool = false
## True kalau saat start ada file save yang berhasil dibaca.
var berhasil_muat: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_auto_accept_quit(false)
	muat()


func _process(delta: float) -> void:
	if not _sudah_dimuat:
		return
	_timer_autosave += delta
	if _timer_autosave >= INTERVAL_AUTOSAVE:
		_timer_autosave = 0.0
		simpan()


func _notification(apa: int) -> void:
	if apa == NOTIFICATION_WM_CLOSE_REQUEST:
		simpan()
		get_tree().quit()


func simpan() -> void:
	var data := {
		"versi": VERSI_SAVE,
		"waktu_simpan": Time.get_unix_time_from_system(),
		"game": GameState.ke_dict(),
	}
	var berkas := FileAccess.open(JALUR_SIMPAN, FileAccess.WRITE)
	if berkas == null:
		push_warning("SaveManager: gagal menulis %s" % JALUR_SIMPAN)
		return
	berkas.store_string(JSON.stringify(data, "\t"))
	berkas.close()


func muat() -> bool:
	if not FileAccess.file_exists(JALUR_SIMPAN):
		_sudah_dimuat = true
		return false

	var berkas := FileAccess.open(JALUR_SIMPAN, FileAccess.READ)
	if berkas == null:
		_sudah_dimuat = true
		return false

	var teks := berkas.get_as_text()
	berkas.close()

	var hasil = JSON.parse_string(teks)
	if not (hasil is Dictionary):
		push_warning("SaveManager: isi save rusak, mulai dari awal")
		_sudah_dimuat = true
		return false

	var versi := int(hasil.get("versi", 0))
	if versi > VERSI_SAVE:
		push_warning("SaveManager: save dari versi lebih baru (%d), dilewati" % versi)
		_sudah_dimuat = true
		return false

	var isi: Dictionary = hasil.get("game", {})
	GameState.dari_dict(isi)
	_sudah_dimuat = true
	berhasil_muat = true
	return true


func hapus_save() -> void:
	if FileAccess.file_exists(JALUR_SIMPAN):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(JALUR_SIMPAN))


func ada_save() -> bool:
	return FileAccess.file_exists(JALUR_SIMPAN)
