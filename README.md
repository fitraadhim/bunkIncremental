# Bunker Incremental

**Survive the night. Scavenge the dead. Build the bunker.**

Game incremental bertema bunker zombie — 2D side-view, dibuat dengan **Godot 4.6.3**.

Kamu satu-satunya orang di bunker. Zombie datang tiap malam. Setiap yang mati
meninggalkan **crude oil**, **scrap metal**, dan kadang **medkit**. Minyak bisa
dijual untuk uang, atau dibakar untuk menyalakan pabrik peluru. Uang memperbaiki
pagar dan bunker. Setiap malam lebih berat dari sebelumnya.

> **Status:** `v0.4.0-demo` — vertical slice. Combat manual, ekonomi, pasar,
> generator, pabrik peluru, pohon skill bercabang, pagar, dan interior bunker
> dua lantai sudah berjalan. Otomasi turret dan prestige belum ada.

---

## Mulai Cepat

```bash
git clone https://github.com/fitraadhim/bunkIncremental.git
cd bunkIncremental/bunkIncremental
```

Lalu buka folder itu di **Godot 4.6+** dan tekan `F5`. Atau jalankan langsung:

```bash
godot --path .
```

## Kontrol

| Tombol | Aksi |
|---|---|
| `A` / `D` | Jalan kiri / kanan |
| `Mouse` | Bidik |
| `Klik kiri` | Tembak |
| `Spasi` | Tebas parang |
| `Q` | Pakai medkit |
| `E` | Masuk / keluar bunker |
| `W` / `S` | Naik / turun lantai |
| `Tab` | Buka terminal bunker |
| `K` | Buka pohon skill |

## Inti Permainannya

```
ZOMBIE MATI
   ├─→ OIL ────┬─→ MARKET ─→ MONEY ─→ REPAIR (pagar + bunker)
   │           └─→ GENERATOR ─→ POWER ─┐
   ├─→ SCRAP ──────────────────────────┴─→ FACTORY ─→ 9MM
   └─→ MEDS ─→ heal pemain
```

Satu keputusan yang harus kamu ambil terus-menerus:
**oil dijual untuk uang, atau dibakar untuk listrik?**
Tanpa listrik pabrik berhenti. Tanpa uang pagar dan bunker tidak bisa diperbaiki.

Pertahanan berlapis: **pagar** menahan zombie di garis depan, **bunker** jadi
lapis kedua kalau pagar jebol, dan **lantai 2** menampung auto-weapon pertama
nanti. Kamu bisa masuk bunker untuk sembuh di kasur — tapi waktu tetap berjalan
dan zombie terus menggerus, jadi itu bukan jeda gratis.

**Pohon skill** berisi 15 node di 5 cabang (COMBAT, FORTIFY, ENGINEERING,
INDUSTRY, ECONOMY) dengan prasyarat lintas cabang. Semua efeknya modifier
turunan — angka dasar tidak pernah ditulis ulang.

---

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [bunkIncremental/README.md](bunkIncremental/README.md) | Arsitektur, alat developer, tabel balance |
| [bunkIncremental/CHANGELOG.md](bunkIncremental/CHANGELOG.md) | Riwayat versi & detail perubahan |

## Alat Developer

```bash
# 174 tes otomatis (ekonomi, produksi, save, combat, skill, pagar, interior)
godot --headless --path . tools/uji.tscn

# Simulator balance: 20 menit gameplay dalam hitungan detik
godot --headless --path . tools/simulasi.tscn -- --menit=20

# Screenshot otomatis
godot --path . tools/tangkap.tscn -- --nama=layar
```

## Peta Jalan

| Fase | Isi | Status |
|---|---|---|
| 1 | Fondasi: scaffold, pixel pipeline, GameState, save/load | ✅ |
| 2 | Combat manual: gerak, bidik, tembak, tebas, zombie AI | ✅ |
| 3 | Ekonomi: pickup, pasar, generator, pabrik peluru | ✅ |
| 4 | Skill tree v1, pagar, interior bunker, lantai 2 | ✅ |
| 5 | Otomasi: turret menembak, penjaga, offline progress | ⬜ |
| 6 | Wave & prestige: boss, evakuasi, blueprint | ⬜ |
| 7 | Polish: SFX, partikel, settings, build `.exe` | ⬜ |
