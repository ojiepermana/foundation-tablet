# Melanjutkan pekerjaan di repo tablet

Untuk memulai atau melanjutkan fitur, buka [indeks scope](docs/scope/index.md), lalu file bernomor untuk fitur yang diminta. Gunakan fase, status, kriteria selesai, dan langkah terbuka di sana. Jika file fitur menautkan spesifikasi, baca keputusan yang sudah dicatat sebelum melanjutkan.

[README produk](README.md) menetapkan kebutuhan dan batas fondasi. Baca bagian yang relevan dengan fitur. Gunakan keputusan yang sudah tercatat dan periksa keadaan repo sebelum bertanya. Minta masukan pengguna bila keputusan yang memengaruhi hasil masih terbuka dan membutuhkan preferensinya.

Saat menyerahkan pekerjaan yang berlanjut ke sesi lain, catat langkah terakhir yang terverifikasi dan langkah berikutnya di file fitur. Jika status berubah, selaraskan status di indeks.

Untuk perubahan UI salam, ikuti [arah tampilan](design.md); token bersama tetap mengikuti fitur 08.

## Build approach

Tracer Bullet, sesuai [indeks scope](docs/scope/index.md).

## Stack

Inti Rust dalam workspace Cargo dengan UniFFI; iPad memakai Swift dan SwiftUI di Xcode; Android tablet memakai Kotlin dan Jetpack Compose dengan Gradle. Versi yang dikunci dan alasannya ada di [matriks dukungan](docs/architecture/support-matrix.md) dan [spec 0001](docs/specs/0001-arsitektur-dan-build-awal/index.md); jangan menyalin angka versi ke tempat lain.

## Perintah

- Build dari clone bersih: enam perintah pada bagian "Perintah repo" di [panduan mulai singkat](docs/getting-started.md).
- Tes tingkat repo: `scripts/test.sh` (cepat, tanpa build). Sesudah kedua skrip build, `scripts/test.sh artifacts` memeriksa hasil build.
- Hanya `scripts/` yang memanggil Cargo untuk proyek native. Pemilik tiap folder dan arah dependensi ada di [catatan arsitektur](docs/architecture/overview.md).

## Aturan kontribusi

Rinciannya ada di [panduan kontribusi](docs/contributing.md); daftar di bawah adalah ringkasannya.

- **Pemilik dulu.** Sebelum menaruh kode, cari pemilik path di [matriks pemilik](docs/architecture/ownership-matrix.md) dan ikuti [aturan dependensi](docs/architecture/dependency-rules.md). Perilaku bersama hanya di Rust; SwiftUI dan Compose tidak menyalin aturan Rust atau membuat kontrak sendiri.
- **Kedua platform.** Perubahan di `crates/`, kontrak, binding, token, atau sumber daya bersama diperiksa di iPad dan Android. Tabel pemeriksaan per path ada di panduan.
- **Hasil generasi.** Jangan disunting tangan dan jangan di-commit; bangun ulang lewat `scripts/`. Build dari tree bersih harus meninggalkan `git status --short` kosong.
- **Pemeriksaan.** Sebelum menyerahkan: `cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked`, `scripts/test.sh`, dan skrip build platform yang terdampak.
- **Bukti per target.** Satu baris per kriteria per target dengan status `PASS`, `FAIL`, atau `NOT_RUN` beserta alasannya; log di `docs/reviews/`. Jangan menyebut lulus tanpa bukti.
- **Keputusan arsitektur** dicatat sebagai spec di `docs/specs/` lewat `/architect`, bukan ADR. Spec `Accepted` tidak diubah diam diam.
- **Keamanan.** Dependensi baru butuh alasan di spec dan versi persis di sumber kuncinya. Rahasia dan kredensial penandatanganan tidak pernah di-commit. Izin native hanya untuk fitur yang tercatat. Log tidak memuat rahasia atau data pengguna. Workflow CI memakai `permissions: contents: read`, action dikunci ke SHA commit penuh, dan build tanpa kredensial penandatanganan produksi. `unsafe` yang ditulis tangan butuh komentar `// SAFETY:` dan `/check review` oleh model lain.
