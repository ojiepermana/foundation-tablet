# 2. Aturan kontribusi · planned

Beri kontributor dan agen panduan singkat berdasarkan struktur yang sudah dapat dibangun. Tempatkan penjelasan terperinci di dokumentasi yang dirujuk oleh panduan.

Untuk serah terima, simpan satu baris bukti per target sewaktu fitur diuji. Contoh format berikut dapat diisi dengan hasil pengujian nyata.

| Kriteria | Commit yang diuji | Target dan versi OS | Perintah atau langkah manual | Hasil aktual dan status | Lokasi log atau alasan belum diuji |
|---|---|---|---|---|---|
| AC 5 | … | Simulator iPad · … | … | … | … |
| AC 5 | … | Emulator tablet Android · … | … | … | … |

Untuk CI pull request, panduan menetapkan izin token minimum, revisi action eksternal yang dikunci, dan cara membangun tanpa kredensial penandatanganan produksi. Ketentuan ini berlaku sejak workflow pertama pada fitur 04.

**Done when:** `AGENTS.md` mengarahkan kontributor ke pemilik perubahan dan panduan untuk memeriksa kedua platform, memperbarui hasil generasi, menjalankan pemeriksaan, mencatat bukti per target dan keputusan arsitektur. Panduan mencakup dependensi, rahasia, izin native dan CI, log sensitif serta peninjauan Rust yang memakai `unsafe`. AC 27.

* [ ] Catat aturan dari repo yang sudah terbentuk: `/audit`

[Kembali ke indeks scope](index.md)
