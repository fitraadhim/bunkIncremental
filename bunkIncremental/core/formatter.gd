class_name Formatter
extends RefCounted
## Pemformat angka untuk HUD.
## Game ini berbahasa Inggris, jadi sufiksnya juga Inggris: 1.2K, 3.4M, 1.1B.

const SUFIX: Array = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx"]


## 1234 -> "1.23K", 42 -> "42", 3.5 -> "3.5"
static func angka(nilai: float) -> String:
	var n := absf(nilai)
	var tanda := "-" if nilai < 0.0 else ""

	if n < 1000.0:
		if is_equal_approx(n, roundf(n)):
			return tanda + str(int(roundf(n)))
		return tanda + "%.1f" % n

	var i := 0
	while n >= 1000.0 and i < SUFIX.size() - 1:
		n /= 1000.0
		i += 1

	var desimal := 2 if n < 10.0 else 1
	return tanda + ("%." + str(desimal) + "f") % n + SUFIX[i]


## Harga pasar selalu 2 desimal: "2.13"
static func harga(nilai: float) -> String:
	return "%.2f" % nilai


## Detik -> "1:05"
static func waktu(detik: float) -> String:
	var total := maxi(0, int(ceil(detik)))
	return "%d:%02d" % [total / 60, total % 60]
