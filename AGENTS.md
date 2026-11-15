# Melanjutkan pekerjaan di repo tablet

Untuk memulai atau melanjutkan fitur, buka [indeks scope](docs/scope/index.md), lalu file bernomor untuk fitur yang diminta. Gunakan fase, status, kriteria selesai, dan langkah terbuka di sana. Jika file fitur menautkan spesifikasi, baca keputusan yang sudah dicatat sebelum melanjutkan.

[README produk](README.md) menetapkan kebutuhan dan batas fondasi. Baca bagian yang relevan dengan fitur. Gunakan keputusan yang sudah tercatat dan periksa keadaan repo sebelum bertanya. Minta masukan pengguna bila keputusan yang memengaruhi hasil masih terbuka dan membutuhkan preferensinya.

Saat menyerahkan pekerjaan yang berlanjut ke sesi lain, catat langkah terakhir yang terverifikasi dan langkah berikutnya di file fitur. Jika status berubah, selaraskan status di indeks.

## Build approach

Tracer Bullet, sesuai [indeks scope](docs/scope/index.md).

## Stack

Inti Rust dalam workspace Cargo dengan UniFFI; iPad memakai Swift dan SwiftUI di Xcode; Android tablet memakai Kotlin dan Jetpack Compose dengan Gradle. Versi yang dikunci dan alasannya ada di [matriks dukungan](docs/architecture/support-matrix.md) dan [spec 0001](docs/specs/0001-arsitektur-dan-build-awal/index.md); jangan menyalin angka versi ke tempat lain.

## Perintah

- Build dari clone bersih: enam perintah pada bagian "Perintah repo" di [panduan mulai singkat](docs/getting-started.md).
- Tes tingkat repo: `scripts/test.sh` (cepat, tanpa build). Sesudah kedua skrip build, `scripts/test.sh artifacts` memeriksa hasil build.
- Hanya `scripts/` yang memanggil Cargo untuk proyek native. Pemilik tiap folder dan arah dependensi ada di [catatan arsitektur](docs/architecture/overview.md).
