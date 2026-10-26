# Bunker Incremental

Survive the night. Scavenge the dead. Build the bunker.

Game incremental bertema bunker zombie, 2D side-view, dibuat dengan **Godot 4.6.3**.
Semua kode berbahasa Indonesia (variabel & fungsi), seluruh teks in-game berbahasa Inggris.

---

## Cara Menjalankan

```powershell
# Editor
& "C:\ListPc\download\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe" --path .

# Langsung main tanpa editor
& "C:\ListPc\download\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe" --path .
```

## Kontrol

| Tombol | Aksi |
|---|---|
| `A` / `D` | Jalan kiri / kanan |
| `Mouse` | Bidik |
| `Klik kiri` | Tembak |
| `Spasi` | Tebas parang |
| `Q` | Pakai medkit |
| `Tab` / `E` (dekat pintu) | Buka terminal |
| `Esc` / `Tab` | Tutup terminal |

## Alur Ekonomi

```
ZOMBIE MATI
   ├─→ OIL ────┬─→ MARKET ─→ MONEY ─→ REPAIR
   │           └─→ GENERATOR ─→ POWER ─┐
   ├─→ SCRAP ──────────────────────────┴─→ FACTORY ─→ 9MM
   └─→ MEDS ─→ heal pemain
```

Inti keputusannya: **oil dijual untuk uang, atau dibakar untuk listrik?**
Tanpa listrik, pabrik peluru berhenti. Tanpa uang, bunker tidak bisa diperbaiki.

---

## Struktur Proyek

```
bunkIncremental/
├── project.godot
├── autoload/
│   ├── data.gd            # registry konten (senjata, musuh, resep)
│   ├── game_state.gd      # pusat data runtime + sinyal
│   └── save_manager.gd    # save/load JSON + autosave 10s
├── core/                  # LOGIKA MURNI, tanpa node, bisa dites
│   ├── ekonomi.gd
│   ├── formatter.gd
│   └── produksi.gd
├── data/                  # konten data-driven (.tres)
│   ├── senjata.gd / senjata/{pistol,parang}.tres
│   ├── musuh.gd / musuh/zombie_biasa.tres
│   └── resep_peluru.gd / peluru/9mm.tres
├── scenes/
│   ├── main.tscn/.gd          # orkestrasi wave & spawn
│   ├── world/world.tscn/.gd   # latar, reruntuhan, tanah
│   ├── entities/              # player, zombie, peluru, pickup
│   └── ui/                    # hud, terminal
├── art/placeholder/       # sprite sementara (generated)
├── tools/
│   ├── buat_placeholder.py    # generator sprite
│   ├── uji.tscn/.gd           # 53 tes otomatis
│   ├── simulasi.tscn/.gd      # simulator balance
│   └── tangkap.tscn/.gd       # screenshot otomatis
└── CHANGELOG.md
```

**Prinsip arsitektur:**

1. **Logika di `core/` tidak menyentuh node.** Ekonomi dan produksi bisa dites dan
   disimulasikan tanpa membuka jendela game.
2. **UI reaktif lewat sinyal**, bukan polling `_process` tiap frame.
3. **Konten di `.tres`**, bukan hardcode. Menambah senjata = bikin file baru.
4. **`GameState` satu-satunya pemilik angka.** Script lain tidak boleh menulis
   resource secara langsung.

---

## Alat Developer

### Tes otomatis (53 tes)

```powershell
& "C:\ListPc\download\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe" --headless --path . tools/uji.tscn
```

Menguji ekonomi, produksi, formatter, GameState, save round-trip, dan combat.
Exit code 0 kalau semua lolos.

### Simulator balance

```powershell
# 20 menit gameplay dalam ~10 detik
& "...console.exe" --headless --path . tools/simulasi.tscn -- --menit=20

# Strategi tempur saja (baseline tanpa ekonomi)
& "...console.exe" --headless --path . tools/simulasi.tscn -- --menit=20 --strategi=tempur
```

Bot sederhana menjalankan game dengan `Engine.time_scale`, mencetak tabel progres
per menit. Ini cara utama men-tuning angka tanpa main manual berjam-jam.

### Screenshot otomatis

```powershell
& "...console.exe" --path . tools/tangkap.tscn -- --nama=layar
& "...console.exe" --path . tools/tangkap.tscn -- --terminal --tab=factory --nama=pabrik
```

Hasil tersimpan di `%APPDATA%\Godot\app_userdata\Bunker Incremental\`.

### Regenerate placeholder art

```powershell
python tools/buat_placeholder.py
```

---

## Angka Balance (v0.3.0)

| Parameter | Nilai |
|---|---|
| HP zombie | 20, ×1.12 per wave |
| Kecepatan zombie | 34 px/s |
| Damage zombie | 4 per 1.1s |
| Pistol | 10 dmg, 0.4s cooldown, mag 12, reload 1.2s |
| Parang | 15 dmg, 0.6s, jangkauan 26px |
| Drop zombie | Oil 2–4, Scrap 1–2, +1 per 3/4 wave |
| Harga minyak | $2.00 dasar, fluktuasi ±15%, refresh 60s |
| Generator | 1 oil / 2s → 10 power (cap 30) |
| Pabrik 9mm | 1 scrap + 2s → 5 peluru, 1 power/s |
| HP bunker | 100, repair $10+3×wave |
| Bounty wave | $10 + 5×wave |
| Save | autosave 10s + saat close |

---

## Peta Jalan

| Fase | Isi | Status |
|---|---|---|
| 1 | Fondasi: scaffold, pixel pipeline, GameState, save/load | ✅ |
| 2 | Combat manual: gerak, bidik, tembak, tebas, zombie AI | ✅ |
| 3 | Ekonomi: pickup, pasar, generator, pabrik peluru | ✅ |
| 4 | Skill tree v1 (15 node, 5 cabang) | ⬜ |
| 5 | Otomasi: turret, penjaga, offline progress | ⬜ |
| 6 | Wave & prestige: boss, evakuasi, blueprint | ⬜ |
| 7 | Polish: SFX, partikel, settings, build .exe | ⬜ |
