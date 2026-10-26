class_name Produksi
extends RefCounted
## Logika antrean pabrik peluru. Murni, tidak menyentuh node.
##
## Satu item antrean berbentuk Dictionary:
##     {"kaliber": "9mm", "sisa": 2.0}
##
## Pabrik hanya jalan kalau listrik cukup. Ini yang membuat minyak punya
## dua pilihan: dijual, atau dibakar untuk menyalakan produksi.


## Buat item antrean baru dari sebuah ResepPeluru.
static func buat_item(resep: ResepPeluru) -> Dictionary:
	return {"kaliber": resep.id, "sisa": resep.waktu}


## Proses antrean selama `delta` detik.
## Mengembalikan {"selesai": Array[String], "daya_terpakai": float}.
static func proses(antrean: Array, delta: float, daya: float, resep_map: Dictionary) -> Dictionary:
	var hasil := {"selesai": [], "daya_terpakai": 0.0}
	if antrean.is_empty():
		return hasil

	var item: Dictionary = antrean[0]
	var resep: ResepPeluru = resep_map.get(item.get("kaliber", ""))
	if resep == null:
		antrean.pop_front()
		return hasil

	var konsumsi := resep.listrik * delta
	if daya < konsumsi:
		return hasil

	item["sisa"] = float(item["sisa"]) - delta
	hasil["daya_terpakai"] = konsumsi

	if float(item["sisa"]) <= 0.0:
		hasil["selesai"].append(item["kaliber"])
		antrean.pop_front()

	return hasil


## Berapa banyak item yang masih bisa masuk antrean.
static func sisa_slot(antrean: Array, batas: int) -> int:
	return maxi(0, batas - antrean.size())


## Persentase progres item terdepan (0.0 - 1.0), untuk progress bar UI.
static func progres(antrean: Array, resep_map: Dictionary) -> float:
	if antrean.is_empty():
		return 0.0
	var item: Dictionary = antrean[0]
	var resep: ResepPeluru = resep_map.get(item.get("kaliber", ""))
	if resep == null or resep.waktu <= 0.0:
		return 0.0
	return clampf(1.0 - float(item["sisa"]) / resep.waktu, 0.0, 1.0)
