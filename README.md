# Bunker Incremental

**Survive the night. Scavenge the dead. Build the bunker.**

Game incremental bertema bunker zombie — 2D side-view, dibuat dengan **Godot 4.6.3**.

Kamu satu-satunya orang di bunker. Zombie datang tiap malam. Setiap yang mati
meninggalkan **crude oil**, **scrap metal**, dan kadang **medkit**. Minyak bisa
dijual untuk uang, atau dibakar untuk menyalakan pabrik peluru. Uang memperbaiki
bunker. Setiap malam lebih berat dari sebelumnya.

> **Status:** `v0.3.1-demo` — vertical slice. Combat manual, ekonomi, pasar,
> generator, dan pabrik peluru sudah berjalan. Skill tree, otomasi, dan prestige
> belum ada.

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
| `Tab` | Buka terminal bunker |

## Inti Permainannya

```
ZOMBIE MATI
   ├─→ OIL ────┬─→ MARKET ─→ MONEY ─→ REPAIR
   │           └─→ GENERATOR ─→ POWER ─┐
   ├─→ SCRAP ──────────────────────────┴─→ FACTORY ─→ 9MM
   └─→ MEDS ─→ heal pemain
```

Satu keputusan yang harus kamu ambil terus-menerus:
**oil dijual untuk uang, atau dibakar untuk listrik?**
Tanpa listrik pabrik berhenti. Tanpa uang bunker tidak bisa diperbaiki.

---

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [bunkIncremental/README.md](bunkIncremental/README.md) | Arsitektur, alat developer, tabel balance |
| [bunkIncremental/CHANGELOG.md](bunkIncremental/CHANGELOG.md) | Riwayat versi & detail perubahan |

## Alat Developer

```bash
# 64 tes otomatis (ekonomi, produksi, save, combat)
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
| 4 | Skill tree v1 (15 node, 5 cabang) | ⬜ |
| 5 | Otomasi: turret, penjaga, offline progress | ⬜ |
| 6 | Wave & prestige: boss, evakuasi, blueprint | ⬜ |
| 7 | Polish: SFX, partikel, settings, build `.exe` | ⬜ |
