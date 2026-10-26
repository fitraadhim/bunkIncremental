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
| `E` | Masuk / keluar bunker |
| `W` / `S` | Naik / turun lantai (di zona tangga) |
| `Tab` | Buka terminal (global, juga saat di dalam bunker) |
| `K` | Buka pohon skill |
| `Esc` / `Tab` | Tutup panel |

## Alur Ekonomi

```
ZOMBIE MATI
   ├─→ OIL ────┬─→ MARKET ─→ MONEY ─→ REPAIR (bunker + pagar)
   │           └─→ GENERATOR ─→ POWER ─┐
   ├─→ SCRAP ──────────────────────────┴─→ FACTORY ─→ 9MM
   └─→ MEDS ─→ heal pemain
```

Inti keputusannya: **oil dijual untuk uang, atau dibakar untuk listrik?**
Tanpa listrik, pabrik peluru berhenti. Tanpa uang, bunker dan pagar tidak bisa
diperbaiki.

## Tiga Lapis Pertahanan

| Lapis | Fungsi | Cara pulih |
|---|---|---|
| **Pagar** (`x = 470`) | Menahan zombie secara fisik. Garis depan. | REPAIR di terminal |
| **Bunker** (`x = 104`) | Kalau pagar jebol, zombie menggerus pintu. | REPAIR di terminal |
| **Lantai 2** | Slot auto-weapon pertama (fase 5). Butuh `Tower Access`. | — |

Masuk bunker dengan `E`. Waktu **tetap berjalan** di dalam: zombie terus
menggerus pagar dan pintu, dan pemain tidak bisa menembak. Jadi masuk bunker
adalah pilihan untuk sembuh di kasur (3 HP/s), bukan jeda gratis.

---

## Struktur Proyek

```
bunkIncremental/
├── project.godot
├── autoload/
│   ├── data.gd            # registry konten (senjata, musuh, resep)
│   ├── game_state.gd      # pusat data runtime + sinyal
│   ├── skill_tree.gd      # kepemilikan skill + cache efek_total
│   └── save_manager.gd    # save/load JSON + autosave 10s
├── core/                  # LOGIKA MURNI, tanpa node, bisa dites
│   ├── ekonomi.gd
│   ├── formatter.gd
│   └── produksi.gd
├── data/                  # konten data-driven (.tres)
│   ├── senjata.gd / senjata/{pistol,parang}.tres
│   ├── musuh.gd / musuh/zombie_biasa.tres
│   ├── resep_peluru.gd / peluru/9mm.tres
│   └── skill.gd, pohon_skill.gd / skill/pohon_skill.tres
├── scenes/
│   ├── main.tscn/.gd          # orkestrasi wave, spawn, masuk/keluar bunker
│   ├── world/
│   │   ├── world.tscn/.gd     # latar, reruntuhan, tanah
│   │   ├── pagar.tscn/.gd     # garis depan, bar HP, retakan
│   │   ├── interior.tscn/.gd  # interior dua lantai (digambar via _draw)
│   │   └── mount_point.tscn/.gd  # slot turret (belum menembak)
│   ├── entities/              # player, zombie, peluru, pickup
│   └── ui/                    # hud, terminal, skill_panel
├── art/placeholder/       # sprite sementara (generated)
├── tools/
│   ├── buat_placeholder.py    # generator sprite
│   ├── uji.tscn/.gd           # 174 tes otomatis
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
5. **Skill hanya menambah modifier turunan.** Angka dasar ada di `*_DASAR`
   (`HP_BUNKER_DASAR`, `PAGAR_HP_DASAR`, `DAMAGE_PISTOL_DASAR`, …). Sistem
   lain wajib memanggil `hp_bunker_maks()`, `pagar_hp_maks()`,
   `pengali_damage()`, dan kawan-kawan — tidak pernah membaca angka dasar
   langsung. Dengan begitu membeli skill tidak pernah merusak angka base.

---

## Alat Developer

### Tes otomatis (174 tes)

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
& "...console.exe" --path . tools/tangkap.tscn -- --terminal --tab=generator --siapkan=idle --nama=power_idle
& "...console.exe" --path . tools/tangkap.tscn -- --skill --nama=skill
& "...console.exe" --path . tools/tangkap.tscn -- --skill --pilih=hollow_point --nama=skill_detail
& "...console.exe" --path . tools/tangkap.tscn -- --siapkan=interior --nama=interior
& "...console.exe" --path . tools/tangkap.tscn -- --siapkan=interior_lantai_2 --nama=interior2
```

`--siapkan=` memaksa state tertentu sebelum capture: `generator`, `idle`,
`pagar`, `skill`, `skill_baru`, `interior`, `interior_lantai_2`.

Hasil tersimpan di `%APPDATA%\Godot\app_userdata\Bunker Incremental\`.

### Regenerate placeholder art

```powershell
python tools/buat_placeholder.py
```

---

## Angka Balance (v0.4.0)

| Parameter | Nilai |
|---|---|
| HP zombie | 20, ×1.12 per wave |
| Kecepatan zombie | 34 px/s |
| Damage zombie | 4 per 1.1s |
| Pistol | 10 dmg, 0.4s cooldown, mag 12, reload 1.2s |
| Parang | 15 dmg, 0.6s, jangkauan 26px |
| Drop zombie | Oil 2–4, Scrap 1–2, +1 per 3/4 wave |
| Harga minyak | $2.00 dasar, fluktuasi ±15%, refresh 60s |
| Generator | 5 power/detik, bakar proporsional: **1 oil = 10 power** |
| Pabrik 9mm | 1 scrap + 2s → 5 peluru, 1 power/s |
| HP bunker | 100, repair $10+3×wave |
| HP pagar | 200 (+60 `Barbed Wire`), repair $30+4×wave |
| Kasur | +3 HP/s, hanya lantai 1 |
| Bounty wave | $10 + 5×wave |
| Skill | 15 node, biaya **placeholder** 120–900 |
| Save | autosave 10s + saat close, format v3 |

**Biaya skill belum di-balance** — sengaja ditunda. Angka di
`data/skill/pohon_skill.tres` masih tebakan kasar.

---

## Peta Jalan

| Fase | Isi | Status |
|---|---|---|
| 1 | Fondasi: scaffold, pixel pipeline, GameState, save/load | ✅ |
| 2 | Combat manual: gerak, bidik, tembak, tebas, zombie AI | ✅ |
| 3 | Ekonomi: pickup, pasar, generator, pabrik peluru | ✅ |
| 4 | Skill tree v1, pagar, interior bunker, lantai 2 | ✅ |
| 5 | Otomasi: turret menembak, penjaga, offline progress | ⬜ |
| 6 | Wave & prestige: boss, evakuasi, blueprint | ⬜ |
| 7 | Polish: SFX, partikel, settings, build .exe | ⬜ |
