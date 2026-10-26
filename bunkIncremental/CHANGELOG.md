# Changelog — Bunker Incremental

Semua perubahan penting dicatat di sini. Format mengikuti
[Keep a Changelog](https://keepachangelog.com/), versi mengikuti
[Semantic Versioning](https://semver.org/).

Tahap rilis yang dipakai:

| Tahap | Arti |
|---|---|
| **demo** | Vertical slice. Bisa dimainkan, tapi masih ada sistem inti yang belum ada. |
| **beta** | Semua sistem inti sudah ada. Yang tersisa adalah polish dan balancing. |
| **1.0** | Rilis resmi. Fitur lengkap, sudah di-balance, siap dibagikan. |

---

## [0.4.0-demo] — 2026-10-26

**Judul: "Hold the Line"**

Fase 4: progresi pemain akhirnya punya bentuk. Ada pohon skill bercabang,
pagar sebagai garis depan yang benar-benar menahan zombie, dan bunker yang bisa
dimasuki — lengkap dengan lantai dua untuk auto-weapon pertama nanti.

### Ditambahkan

**Pohon skill (15 node, 5 cabang × 3 tier)**

Panel terpisah, bukan tab terminal. Tema militer: heksagon olive, garis
prasyarat putus-putus, bracket sudut. Buka dengan `K`, tutup dengan `K`/`Esc`.
Selama panel terbuka, waktu game berhenti.

| Cabang | Tier 1 | Tier 2 | Tier 3 |
|---|---|---|---|
| COMBAT | Steady Aim | Quick Hands | Hollow Point |
| FORTIFY | Reinforced Door | Barbed Wire | Auto Patch |
| ENGINEERING | Tower Access | Fuel Injector | Backup Generator |
| INDUSTRY | Second Line | Salvage Press | Overclock |
| ECONOMY | Haggler | Bulk Contract | Night Market |

Prasyarat tidak selalu satu cabang: `Tower Access` butuh `Reinforced Door`
(lintas cabang FORTIFY → ENGINEERING). Garis prasyarat digambar sebagai
polyline sehingga cabang yang tidak sejajar tetap terbaca.

**Pagar sebagai garis depan**

`Pagar` adalah `StaticBody2D` di physics layer baru "Fence". Zombie
menabraknya secara fisik, jadi pagar menahan mereka — bukan sekadar angka HP
yang dikurangi dari jauh. Punya bar HP sendiri di HUD, retakan saat rusak,
kawat berduri saat `Barbed Wire` dibeli, dan goyang saat kena pukul.

**Interior bunker dua lantai**

Tekan `E` dekat pintu untuk masuk. Lantai 1 punya kasur (regenerasi 3 HP/s)
dan pintu keluar. Lantai 2 terkunci sampai `Tower Access` dibeli. Naik/turun
lewat tangga dengan `W`/`S`.

Waktu **tetap berjalan** selama di dalam. Zombie terus menggerus pagar dan
pintu, jadi masuk bunker bukan jeda gratis — justru kehilangan tembakan.

Interior bukan scene terpisah, melainkan `Node2D` di dalam `main.tscn`.
`World`/`Entities` disembunyikan, bukan di-`change_scene`. Dengan begitu state
wave, zombie, dan drop tidak hancur, dan tidak perlu kamera kedua.

**Mount point turret (belum menembak)**

Dua slot kosong: satu di depan bunker, satu di lantai 2. Keduanya hanya
menampilkan alas dan heksagon "MOUNT — EMPTY". Logika menembak masuk fase 5.

### Diperbaiki

- **Minyak bisa menjadi −1.** Ditemukan lewat simulasi 20 menit: kolom minyak
  sempat menampilkan `-1`. Penyebabnya akuntansi `_sisa_bara`.

  `_sisa_bara` adalah bahan bakar yang **sudah terbakar tapi belum dipotong**
  dari stok. Jadi ketersediaan yang benar adalah `minyak - _sisa_bara`, bukan
  `minyak + _sisa_bara`. Dengan penjumlahan, saat `minyak = 1` dan pecahan
  `0.8`, satu tick masih boleh membakar `0.8` lagi lalu memotong 1 unit →
  `minyak = -1`.

  Sekarang ada `tersedia = maxf(0.0, minyak - _sisa_bara)` plus jaring pengaman
  yang memaksa `minyak >= 0`. Konservasi 1 oil = 10 power tetap utuh
  (efisiensi simulasi 9.78 power/oil).

- **Pemain tidak bergerak saat di dalam bunker.** `_gerak()` memotong posisi
  tapi tidak pernah menambahkan `velocity * delta`, karena `move_and_slide()`
  dilewati. Sekarang gerak interior dihitung langsung.

### Diubah

- **Posisi pagar: `x = 165` → `x = 470`.** Di 165 pagar berada **di belakang**
  titik spawn pemain (`x = 200`), sehingga zombie selalu menjangkau pemain
  lebih dulu dan pagar tidak pernah menyerap apa pun. Di 470 pagar jadi garis
  depan yang sebenarnya. **Ini menyimpang dari rencana awal — perlu konfirmasi.**

- **Target zombie jadi berlapis:** pemain (hanya kalau terjangkau dan dalam
  90 px) → pagar (kalau hidup) → bunker. Pemain yang sedang di dalam bunker
  dianggap tidak terjangkau.

- **Batas angka pindah ke fungsi turunan.** Semua `*_DASAR` tetap jadi sumber
  tunggal; skill hanya menambah modifier lewat `hp_bunker_maks()`,
  `pagar_hp_maks()`, `pengali_damage()`, `pengali_reload()`,
  `pengali_kecepatan_produksi()`, `pengali_hasil_produksi()`,
  `pengali_harga_jual()`, `harga_jual_efektif()`, `nilai_jual()`. Tidak ada
  angka base `GameState` yang ditulis ulang oleh skill.

- **Save format v3** menambah `skill_dimiliki` dan `hp_pagar`. Field opsional
  baru setelah ini tidak akan menaikkan versi lagi — pembaca memakai default
  aman.

- **Kontrol:** `E` sekarang untuk masuk/keluar bunker. Terminal tetap global
  di `Tab`.

### Catatan balancing

Biaya skill masih **placeholder** (120–900) dan belum di-balance. Sesuai
kesepakatan, penyeimbangan angka ditunda. Simulasi 20 menit saat ini: wave 20,
267 kill, 10/15 skill, bunker 125/125, pemain 100/100.

Observasi: dengan pagar di 470, bunker nyaris tidak pernah kena damage sampai
wave ~20 karena pagar menyerap semuanya dan biaya perbaikan masih terjangkau.
Tekanan baru muncul saat biaya perbaikan (`30 + wave × 4`) tumbuh lebih cepat
daripada pendapatan. Kalau terasa terlalu aman, tuas paling murah adalah
menaikkan koefisien biaya perbaikan pagar, bukan menurunkan HP pagar.

### Pengujian

174 test otomatis, semua lolos (`tools/uji.tscn`). Termasuk test baru untuk:
masuk/keluar bunker, lantai 2 terkunci tanpa `Tower Access`, regenerasi kasur
(hanya lantai 1), zombie mengabaikan pemain di dalam, dan regresi minyak
negatif.

---

**Judul: "Fuel Efficiency"**

Perbaikan bug yang dilaporkan pemain: generator terus menyedot crude oil walau
baterai hampir penuh, sehingga minyak terbuang sia-sia.

### Diagnosis

Generator lama membakar **1 oil utuh** lalu menambahkan 10 power sekaligus,
tanpa melihat berapa yang benar-benar muat di baterai:

```gdscript
minyak -= 1                                                  # 1 oil utuh
listrik = minf(listrik + LISTRIK_PER_BARA, LISTRIK_MAKS)      # +10, dipotong cap
```

Dengan baterai 30 dan pabrik yang makan 1 power/detik, siklusnya:

| Waktu | Power | Kejadian |
|---|---|---|
| 0s | 30 | penuh, generator diam |
| 2s | 28 | pabrik makan 2 |
| 2s | **30** | generator bakar 1 oil (+10, hanya muat 2 → **8 power hilang**) |

Hasilnya pabrik butuh 1 power/detik tapi generator membakar 0.5 oil/detik.
Satu oil seharusnya cukup untuk 10 detik, bukan 2. **Efisiensi hanya 20% —
80% minyak menguap.** Bug kedua: `_akumulator_bara` di-reset ke 0 saat baterai
penuh, membuang progres pembakaran yang sudah setengah jalan.

### Diperbaiki

- **Pembakaran minyak sekarang proporsional.** Bahan bakar dihitung *dari daya
  yang benar-benar tersimpan*, bukan dari waktu:

  ```gdscript
  var daya := minf(LAJU_DAYA * delta, ruang)      # dibatasi ruang baterai
  var bakar := minf(daya / LISTRIK_PER_BARA, stok) # minyak sebanding
  ```

  Hasilnya **1 crude oil selalu menghasilkan tepat 10 power**. Konsumsi turun
  dari 0.5 → 0.1 oil/detik pada beban pabrik penuh (**5× lebih hemat**).

- **Pecahan minyak disimpan** di `_sisa_bara` (float), dan `minyak` hanya
  dipotong saat sudah genap 1 unit. Tidak ada lagi minyak "setengah terbakar"
  yang hilang saat generator dimatikan.

- **Baterai penuh = nol konsumsi.** Generator tetap menyala tapi berhenti
  membakar sepenuhnya, bukan membuang progres akumulator.

- **Status generator jadi tiga:** `STOPPED`, `IDLE — BATTERY FULL`, `RUNNING`.
  Sebelumnya hanya dua, sehingga pemain tidak bisa membedakan "sedang membakar"
  dan "menyala tapi diam".

### Ditambahkan

- **Indikator konsumsi live** di tab POWER (`Consumption: 0.10 oil/s`),
  dihitung dari laju pengisian daya pada tick terakhir.
- **Statistik `minyak_terbakar` dan `daya_terpakai`** untuk audit efisiensi.
- **11 tes regresi baru** di `tools/uji.tscn` (total 53 → 64), termasuk:
  - `tidak membakar 1 oil utuh saat hampir penuh`
  - `generator tidak membakar saat baterai penuh`
  - `1 oil menghasilkan tepat 10 power`
  - `tidak ada minyak terbuang (efisiensi 100%)`
  - `daya terkonservasi (tersimpan + terpakai = dihasilkan)`
- **Argumen `--siapkan=` pada `tools/tangkap.gd`** untuk memaksa state tertentu
  sebelum screenshot (`generator`, `idle`).
- **`.gitignore`** di root repo — mencegah folder `.godot/` (cache impor,
  bisa ratusan MB) ikut ter-commit.

### Diubah

- **`VERSI_SAVE` 1 → 2** — menambah field `sisa_bara`. Save v1 tetap bisa
  dimuat (field baru default `0.0`), dan proses migrasi dicatat di log.
- **Teks tab POWER** — dari *"Burns 1 crude oil every 2s"* menjadi
  *"Burns fuel only as needed — 1 crude oil per 10 power."*

### Hasil Simulasi (20 menit, strategi ekonomi)

| Metrik | v0.3.0 | v0.3.1 |
|---|---|---|
| Minyak terkumpul | 1.452 | 1.477 |
| Minyak terbakar | — (tidak tercatat) | **122** |
| Daya terpakai | — | 1.192,4 |
| **Efisiensi** | ~20% | **9,77 power per oil (ideal 10)** |
| Wave tercapai | 18 | 18 |

Efisiensi 9,77 dari ideal 10 karena sebagian daya masih tersimpan di baterai
saat simulasi berakhir. Kurva progres tidak berubah signifikan, jadi konsumsi
daya pabrik tetap **1 power/detik** — tidak perlu kompensasi.

---

## [0.3.0-demo] — 2026-10-26

**Judul: "Balance & Recovery"**

Versi ini tidak menambah fitur baru. Isinya memperbaiki masalah desain yang
ditemukan lewat simulator: pemain bisa masuk *death spiral* tanpa jalan keluar.

### Ditambahkan

- **Tab REPAIR di terminal** — memperbaiki bunker dengan uang. Biaya naik
  seiring wave (`$10 + 3×wave`), jadi ini *money sink* yang skalanya ikut
  kesulitan game.
- **Medkit (Q)** — memakai 1 MEDS untuk memulihkan 35 HP. Sebelumnya resource
  MEDS menumpuk tanpa kegunaan sama sekali.
- **Drop scaling per wave** — minyak dapat bonus `+wave/3`, scrap `+wave/4`.
  Ini perbaikan paling penting: sebelumnya pendapatan tetap datar sementara HP
  zombie naik eksponensial, sehingga wave 7 ke atas jadi mustahil.
- **`tools/simulasi.gd`** — simulator balance berbasis bot dengan
  `Engine.time_scale`. Mencetak tabel progres per menit.
- **`tools/tangkap.gd`** — screenshot otomatis, bisa membuka tab terminal
  tertentu lewat argumen.
- **Statistik runtime** — hitungan tembakan di player, untuk menghitung
  efisiensi amunisi (peluru per kill).
- **`target_bidik` / `target_titik` di player** — hook untuk auto-aim. Dipakai
  simulator sekarang, dan nanti oleh turret di fase otomasi.

### Diperbaiki

- **Death spiral di wave 7+** — bunker jebol berulang, uang habis, tidak ada
  cara pulih. Sekarang ada repair + drop scaling.
- **Bulan tertutup panel HUD** — dipindah ke tengah layar.
- **Jendela gedung terlalu redup** — opacity dinaikkan, ditambah variasi
  jendela redup supaya kota terlihat hidup.
- **Tab aktif di terminal tidak ter-highlight** — sebelumnya memakai state
  `disabled`, sekarang style box khusus dengan border emas.
- **Pesan tengah HUD tidak terbaca** — ditambah panel latar gelap + text shadow.
- **Bar POWER selalu penuh** — sinyal `listrik_berubah` tidak pernah tersambung
  ke HUD, jadi bar-nya menampilkan nilai default 100%.
- **Zombie saling menembus** — collision mask zombie diubah agar mereka
  berbaris, bukan menumpuk di satu titik.
- **Simulator hang** — parse error di script membuat proses tidak pernah
  selesai. Ditambah guard batas waktu nyata (`--batas=`).

### Diubah

- **HP zombie per wave: ×1.18 → ×1.12.** Dengan drop scaling, 1.18 membuat
  kurva terlalu curam.
- **Kecepatan zombie: 20 → 34 px/s.** 20 px/s membuat satu wave butuh 30+ detik
  hanya untuk zombie sampai ke bunker.
- **Damage zombie: 5 → 4, jeda serang 1.0 → 1.1s.** Memberi ruang bernapas di
  awal game.
- **Label tab: GENERATOR → POWER** (muat 4 tab).

### Hasil Simulasi (20 menit, strategi ekonomi)

| Metrik | Sebelum (0.2.0) | Sesudah (0.3.0) |
|---|---|---|
| Wave tercapai | 7 (mentok) | 18 |
| Zombie dibunuh | 194 | 235 |
| Uang total | $485 | $2.646 |
| Peluru per kill | 6.3 | 7.8 |

---

## [0.2.0-demo] — 2026-10-26

**Judul: "Terminal & Economy Loop"**

### Ditambahkan

- **Terminal bunker** — satu panel dengan tiga tab (MARKET, GENERATOR,
  FACTORY). Game di-pause saat terminal terbuka, tapi produksi, pembakaran
  minyak, dan harga pasar tetap berjalan karena `GameState` memakai
  `PROCESS_MODE_ALWAYS`.
- **Pasar minyak** — harga fluktuatif dengan mean reversion ke $2.00, batas
  $1.00–$4.00, refresh tiap 60 detik. Indikator tren naik/turun/datar.
- **Generator diesel** — bakar 1 oil / 2 detik → 10 power (cap 30).
  Otomatis mati kalau minyak habis.
- **Pabrik peluru** — antrean 5 slot, 1 scrap + 2 detik → 5 butir 9mm.
  Berhenti kalau listrik habis. Ini yang membuat minyak punya dua kegunaan.
- **HUD lengkap** — oil/scrap/meds/money, HP pemain, HP bunker, power,
  indikator magasin/reserve, wave counter, harga pasar, baris pesan.
- **HUD reaktif lewat sinyal** — `resource_berubah`, `hp_pemain_berubah`,
  `peluru_berubah`, dan seterusnya. Tidak ada polling state di `_process`.
- **Tes otomatis `tools/uji.tscn`** — 53 tes untuk ekonomi, produksi,
  formatter, GameState, save round-trip, dan combat.
- **Paket awal** — 24 butir 9mm untuk pemain baru, supaya tidak deadlock di
  malam pertama.

### Diperbaiki

- **Formatter angka** — `String.num()` membuang trailing zero, jadi `1000`
  tampil `1K` bukan `1.00K`. Diganti format string eksplisit.

---

## [0.1.0-demo] — 2026-10-26

**Judul: "First Night"** — Vertical slice pertama.

### Ditambahkan

- **Scaffold proyek Godot 4.6.3** — viewport 640×360, window 1280×720,
  stretch `canvas_items`, texture filter nearest (pixel art tajam).
- **Pixel pipeline** — `tools/buat_placeholder.py`, generator sprite PNG murni
  Python tanpa dependency. Menghasilkan player, zombie, bunker, tile tanah,
  3 pickup, peluru, kilatan, dan efek tebasan.
- **Combat manual**
  - Player: gerak A/D, bidik mouse, tembak klik kiri, tebas Spasi.
  - Pistol: 10 dmg, magasin 12, reload 1.2s, konsumsi peluru nyata.
  - Parang: 15 dmg, tanpa amunisi, jangkauan terbatas + cek arah hadap.
  - Peluru memakai **raycast per frame**, bukan Area2D — tidak bisa menembus
    zombie saat framerate turun.
- **Zombie AI** — jalan ke kiri, menyerang pemain kalau dekat, kalau tidak
  menyerang bunker. Health bar di atas kepala, hanya muncul saat terluka.
- **Drop & pickup** — minyak, scrap, meds. Pickup punya efek magnet: ditarik
  ke pemain kalau jarak < 54 px. Ada animasi terapung dan umur 60 detik.
- **Wave system** — `4 + wave` zombie, jeda 5 detik antar malam, bounty uang.
  Kalau bunker jebol: kehilangan 50% minyak, mundur ke wave yang sama.
- **Save/load** — JSON ke `user://simpanan.json`, autosave 10 detik + saat
  window ditutup, field `versi` untuk migrasi ke depan.
- **Dunia 2D** — langit gradien, bulan, 12 siluet gedung dengan jendela
  menyala acak, tile tanah, puing di garis tanah. Semua `_draw()`, belum pakai
  aset parallax.
- **Arsitektur berlapis** — `core/` (logika murni), `data/` (konten .tres),
  `scenes/` (node), `autoload/` (state global).

### Catatan Teknis

- Renderer `gl_compatibility` untuk kompatibilitas maksimal.
- Input map memakai nama Indonesia (`gerak_kiri`, `tembak`, `tebas`).
- Konten 100% data-driven: `data/senjata/pistol.tres` bisa diubah tanpa
  menyentuh satu baris kode.
