class_name Ekonomi
extends RefCounted
## Logika ekonomi murni — tidak menyentuh node, jadi bisa dites terpisah.
## Harga minyak bergerak acak tapi selalu tertarik balik ke harga dasar,
## supaya tidak pernah nyangkut di 0 atau meledak tak terbatas.

const HARGA_DASAR := 2.0
const HARGA_MIN := 1.0
const HARGA_MAKS := 4.0
const TARIK_BALIK := 0.3
const GUNCANGAN := 0.3


## Hitung harga baru setelah satu siklus refresh pasar.
static func harga_berikutnya(harga_lama: float) -> float:
	var tarik := (HARGA_DASAR - harga_lama) * TARIK_BALIK
	var acak := randf_range(-GUNCANGAN, GUNCANGAN)
	var baru := clampf(harga_lama + tarik + acak, HARGA_MIN, HARGA_MAKS)
	return snappedf(baru, 0.01)


## Total uang dari menjual sejumlah minyak.
static func nilai_jual(jumlah: int, harga: float) -> int:
	if jumlah <= 0:
		return 0
	return int(floor(jumlah * harga))


## Tren pasar untuk indikator panah di UI.
static func tren(harga_lama: float, harga_baru: float) -> String:
	if harga_baru > harga_lama + 0.005:
		return "up"
	if harga_baru < harga_lama - 0.005:
		return "down"
	return "flat"
