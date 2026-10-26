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
