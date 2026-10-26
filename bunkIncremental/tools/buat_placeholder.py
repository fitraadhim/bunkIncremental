"""
Generator sprite placeholder untuk Bunker Incremental.

Script ini menulis file PNG langsung (tanpa dependency eksternal, hanya zlib
dan struct dari standard library). Tujuannya supaya fase 1-5 bisa dimainkan
tanpa menunggu aset pixel art jadi.

Cara pakai:
    python tools/buat_placeholder.py

Semua hasil masuk ke art/placeholder/ dengan ukuran tetap. Nanti saat aset
asli sudah jadi, cukup timpa file PNG-nya dengan nama & ukuran yang sama.
"""

import os
import struct
import zlib

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "art", "placeholder")
os.makedirs(OUT, exist_ok=True)

TRANSPARAN = (0, 0, 0, 0)


# ---------------------------------------------------------------------------
# Helper gambar
# ---------------------------------------------------------------------------

def kanvas(lebar, tinggi):
    return [[TRANSPARAN for _ in range(lebar)] for _ in range(tinggi)]


def titik(k, x, y, warna):
    if 0 <= y < len(k) and 0 <= x < len(k[0]):
        k[y][x] = warna


def kotak(k, x0, y0, x1, y1, warna):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            titik(k, x, y, warna)


def bingkai(k, x0, y0, x1, y1, warna):
    kotak(k, x0, y0, x1, y0, warna)
    kotak(k, x0, y1, x1, y1, warna)
    kotak(k, x0, y0, x0, y1, warna)
    kotak(k, x1, y0, x1, y1, warna)


def outline(k, warna):
    """Tambah garis tepi gelap di sekeliling piksel yang tidak transparan."""
    tinggi = len(k)
    lebar = len(k[0])
    hasil = [baris[:] for baris in k]
    for y in range(tinggi):
        for x in range(lebar):
            if k[y][x][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < lebar and 0 <= ny < tinggi and k[ny][nx][3] != 0:
                    hasil[y][x] = warna
                    break
    return hasil


def tulis_png(nama, k):
    tinggi = len(k)
    lebar = len(k[0])
    mentah = b""
    for baris in k:
        mentah += b"\x00"
        for px in baris:
            mentah += bytes(px)

    def chunk(tipe, data):
        isi = struct.pack(">I", len(data)) + tipe + data
        return isi + struct.pack(">I", zlib.crc32(tipe + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", lebar, tinggi, 8, 6, 0, 0, 0)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(mentah, 9))
        + chunk(b"IEND", b"")
    )
    with open(os.path.join(OUT, nama), "wb") as berkas:
        berkas.write(png)
    print("  %-22s %dx%d" % (nama, lebar, tinggi))


# ---------------------------------------------------------------------------
# Sprite
# ---------------------------------------------------------------------------

def buat_pemain():
    k = kanvas(16, 24)
    K = (18, 20, 24, 255)
    RAMBUT = (46, 46, 54, 255)
    KULIT = (214, 158, 100, 255)
    JAKET = (61, 69, 80, 255)
    JAKET_GELAP = (42, 46, 53, 255)
    CELANA = (38, 42, 50, 255)
    SEPATU = (24, 26, 30, 255)
    LOGAM = (140, 146, 156, 255)

    # kepala
    kotak(k, 5, 2, 10, 8, KULIT)
    kotak(k, 5, 2, 10, 4, RAMBUT)
    titik(k, 9, 6, K)
    titik(k, 10, 6, K)
    # leher
    kotak(k, 7, 9, 8, 9, KULIT)
    # badan
    kotak(k, 4, 10, 11, 16, JAKET)
    kotak(k, 4, 10, 5, 16, JAKET_GELAP)
    # lengan + pistol
    kotak(k, 11, 11, 13, 13, JAKET)
    kotak(k, 13, 11, 15, 12, LOGAM)
    # sabuk
    kotak(k, 4, 16, 11, 16, SEPATU)
    # kaki
    kotak(k, 5, 17, 7, 21, CELANA)
    kotak(k, 8, 17, 10, 21, CELANA)
    kotak(k, 4, 22, 7, 23, SEPATU)
    kotak(k, 8, 22, 11, 23, SEPATU)

    k = outline(k, K)
    tulis_png("player.png", k)


def buat_zombie():
    k = kanvas(16, 24)
    K = (16, 20, 16, 255)
    KULIT = (107, 142, 78, 255)
    KULIT_GELAP = (74, 107, 51, 255)
    KAIN = (52, 62, 44, 255)
    MATA = (200, 45, 45, 255)

    # kepala bungkuk
    kotak(k, 5, 3, 10, 9, KULIT)
    kotak(k, 6, 9, 9, 9, KULIT_GELAP)
    titik(k, 8, 6, MATA)
    titik(k, 9, 6, MATA)
    # badan
    kotak(k, 4, 10, 11, 16, KAIN)
    kotak(k, 5, 11, 6, 15, KULIT_GELAP)
    # tangan menjulur ke depan
    kotak(k, 11, 11, 14, 12, KULIT)
    kotak(k, 13, 11, 15, 12, KULIT_GELAP)
    # kaki
    kotak(k, 5, 17, 7, 22, KAIN)
    kotak(k, 8, 17, 10, 22, KAIN)
    kotak(k, 4, 23, 7, 23, K)
    kotak(k, 8, 23, 11, 23, K)

    k = outline(k, K)
    tulis_png("zombie.png", k)


def buat_bunker():
    k = kanvas(96, 96)
    DINDING = (74, 80, 90, 255)
    DINDING_GELAP = (58, 64, 73, 255)
    SIAR = (44, 49, 57, 255)
    GELAP = (24, 27, 32, 255)
    LAMPU = (242, 193, 78, 255)
    KARUNG = (96, 88, 66, 255)

    kotak(k, 0, 6, 95, 95, DINDING)

    # pola bata
    baris = 0
    y = 6
    while y < 96:
        kotak(k, 0, y, 95, y, SIAR)
        geser = 0 if baris % 2 == 0 else 16
        x = geser
        while x < 96:
            kotak(k, x, y + 1, x, min(y + 11, 95), DINDING_GELAP)
            x += 32
        baris += 1
        y += 12

    # pintu
    kotak(k, 58, 50, 82, 95, GELAP)
    bingkai(k, 56, 48, 84, 95, DINDING_GELAP)
    kotak(k, 58, 50, 82, 95, GELAP)
    titik(k, 79, 72, LAMPU)

    # jendela bidik
    kotak(k, 16, 28, 40, 38, GELAP)
    bingkai(k, 14, 26, 42, 40, DINDING_GELAP)
    kotak(k, 16, 28, 40, 38, GELAP)
    kotak(k, 20, 31, 36, 35, (60, 44, 30, 255))

    # karung pasir di dasar
    kotak(k, 0, 88, 95, 95, KARUNG)
    for x in range(0, 96, 12):
        bingkai(k, x, 88, x + 11, 95, (72, 66, 48, 255))

    # atap
    kotak(k, 0, 0, 95, 6, DINDING_GELAP)
    kotak(k, 0, 0, 95, 1, SIAR)

    tulis_png("bunker.png", k)


def buat_tanah():
    k = kanvas(16, 16)
    dasar = (58, 46, 36, 255)
    terang = (72, 58, 45, 255)
    gelap = (44, 34, 26, 255)
    kotak(k, 0, 0, 15, 15, dasar)
    for (x, y) in ((2, 3), (7, 1), (12, 5), (4, 9), (10, 11), (14, 14), (1, 13)):
        titik(k, x, y, terang)
    for (x, y) in ((5, 6), (13, 2), (8, 13), (2, 8)):
        titik(k, x, y, gelap)
    kotak(k, 0, 0, 15, 1, (86, 70, 54, 255))
    tulis_png("ground_tile.png", k)


def buat_pickup():
    # Minyak
    k = kanvas(10, 10)
    kotak(k, 2, 3, 7, 9, (176, 74, 38, 255))
    kotak(k, 2, 3, 7, 4, (208, 96, 48, 255))
    kotak(k, 4, 1, 5, 2, (120, 110, 100, 255))
    titik(k, 3, 6, (230, 150, 80, 255))
    tulis_png("pickup_minyak.png", outline(k, (20, 18, 16, 255)))

    # Logam
    k = kanvas(10, 10)
    kotak(k, 1, 3, 8, 8, (128, 136, 146, 255))
    kotak(k, 1, 3, 8, 4, (168, 176, 186, 255))
    kotak(k, 3, 6, 6, 7, (96, 102, 112, 255))
    tulis_png("pickup_logam.png", outline(k, (20, 20, 24, 255)))

    # Obat
    k = kanvas(10, 10)
    kotak(k, 1, 2, 8, 8, (232, 232, 228, 255))
    kotak(k, 4, 3, 5, 7, (198, 52, 58, 255))
    kotak(k, 2, 4, 7, 5, (198, 52, 58, 255))
    tulis_png("pickup_obat.png", outline(k, (24, 24, 26, 255)))


def buat_peluru():
    k = kanvas(5, 2)
    kotak(k, 0, 0, 4, 1, (240, 206, 96, 255))
    titik(k, 4, 0, (255, 250, 210, 255))
    titik(k, 4, 1, (255, 250, 210, 255))
    tulis_png("peluru.png", k)


def buat_kilatan():
    k = kanvas(8, 8)
    kuning = (255, 216, 110, 255)
    putih = (255, 250, 230, 255)
    kotak(k, 3, 0, 4, 7, kuning)
    kotak(k, 0, 3, 7, 4, kuning)
    kotak(k, 2, 2, 5, 5, kuning)
    kotak(k, 3, 3, 4, 4, putih)
    tulis_png("kilatan.png", k)


def buat_tebasan():
    k = kanvas(24, 24)
    for i in range(10):
        tebal = 1 if i > 5 else 2
        for d in range(tebal):
            titik(k, 12 + i, 12 - i + d, (230, 240, 255, 220 - i * 18))
            titik(k, 12 + i, 12 + i - d, (230, 240, 255, 220 - i * 18))
    tulis_png("tebasan.png", k)


def main():
    print("Membuat placeholder sprite ke:", OUT)
    buat_pemain()
    buat_zombie()
    buat_bunker()
    buat_tanah()
    buat_pickup()
    buat_peluru()
    buat_kilatan()
    buat_tebasan()
    print("Selesai.")


if __name__ == "__main__":
    main()
