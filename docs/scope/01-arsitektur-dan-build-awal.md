# 1. Arsitektur dan build awal · in-progress

Tetapkan batas antara inti Rust, lapisan ekspor UniFFI, dua aplikasi native, serta sumber desain dan penunjangnya. Keputusan yang masih terbuka adalah versi stabil yang kompatibel, target build, dan cara mengemas pustaka untuk tiap platform.

Dokumentasikan versi alat, OS minimum iPadOS dan Android, target simulator dan perangkat iPad, serta arsitektur biner (ABI) emulator dan tablet Android. Matriks dukungan menyebut alasan tiap target dan apakah perangkat Android dengan halaman memori 16 KB termasuk di dalamnya.

**Done when:** kontributor dapat mengompilasi workspace Rust dan kedua proyek native minimal dari clone bersih dengan perintah repo pada panduan mulai singkat. Versi yang dipilih cocok dengan dokumentasi resmi. Catatan arsitektur memuat matriks dukungan, pemilik tiap bagian, arah dependensi, dan alasan penyimpangan dari struktur README bila ada. AC 1, 2.

**Pointer:** spec [0001](../specs/0001-arsitektur-dan-build-awal/index.md)

* [x] Putuskan arsitektur awal (spec): `/architect arsitektur dan build awal`
* [x] Build it: `/develop arsitektur dan build awal`
  * [x] Milestone 1: Workspace Rust dan batas crate. Build plan 1 sampai 3. AC-1, AC-2, AC-8, AC-11. Tanpa build native. Kode di [`crates/`](../../crates), [`Cargo.toml`](../../Cargo.toml), dan [`rust-toolchain.toml`](../../rust-toolchain.toml). Bukti: [verify milestone 1](../reviews/2026-11-15-verify-f01-m1.md), PASS pada `578e3b7`, host `aarch64-apple-darwin`, macOS 27.0.1.
  * [x] Milestone 2: Proyek iPad minimal dan skrip build. Build plan 4, 5. AC-3, AC-5, AC-6, AC-8, AC-11. Needs milestone 1. Build Xcode. Kode di [`apps/ipados/`](../../apps/ipados) dan [`scripts/build-ipados.sh`](../../scripts/build-ipados.sh). Bukti: [verify milestone 2](../reviews/2026-11-15-verify-f01-m2.md), PASS pada `0868e45`, simulator iPad generik (Debug) dan iPad generik (Release tanpa tanda tangan), Xcode 27.1, macOS 27.0.1. iPad fisik: `NOT_RUN` (F01-1 di [langkah manual](coordination/01-arsitektur-dan-build-awal.manual.md)), bukan syarat AC-6.
  * [x] Milestone 3: Proyek Android minimal dan skrip build. Build plan 6 sampai 8. AC-3, AC-4, AC-7, AC-8, AC-11. Needs milestone 1, after milestone 2 (satu build native pada satu waktu). Build Gradle. Kode di [`apps/android-tablet/`](../../apps/android-tablet) dan [`scripts/build-android-tablet.sh`](../../scripts/build-android-tablet.sh). Bukti: [verify milestone 3](../reviews/2026-11-15-verify-f01-m3.md), PASS pada `610cefb`, APK debug ABI `arm64-v8a` dan `x86_64` (API 29, 36, 37), NDK 28.2.13676358, JDK 25.0.2, host macOS 27.0.1. Tablet fisik dan perangkat 16 KB: `NOT_RUN` (F01-2, F01-3 di [langkah manual](coordination/01-arsitektur-dan-build-awal.manual.md)), bukan syarat AC-4 dan AC-7.
  * [x] Milestone 4: Panduan mulai singkat dan catatan arsitektur. Build plan 9, 10, 11. AC-9, AC-10, dan AC-5, AC-6, AC-8 untuk satu baris `Base.xcconfig` (tugas 11). Needs milestone 1, 2, 3. Build Xcode lalu Gradle dari clone bersih. Dokumen di [`docs/getting-started.md`](../getting-started.md) dan [`docs/architecture/`](../architecture). Bukti: [verify milestone 4 dan verify penuh](../reviews/2026-11-15-verify-f01.md), PASS pada `f3992db`, 27 langkah dari clone baru.
* [x] Verify it: `/check verify arsitektur dan build awal`. Bukti: [verify penuh](../reviews/2026-11-15-verify-f01.md), AC-1 sampai AC-11 PASS pada `f3992db`: host `aarch64-apple-darwin`, simulator iPad generik (Debug) dan iPad generik (Release tanpa tanda tangan) dengan Xcode 27.1, APK debug ABI `arm64-v8a` dan `x86_64`, macOS 27.0.1. Belum teramati: pemasangan prasyarat di mesin kosong dan peluncuran aplikasi (bukan janji fitur 01). Perangkat fisik `NOT_RUN` (F01-1 sampai F01-3), bukan syarat AC.
* [ ] Test it: `/test arsitektur dan build awal`

[Kembali ke indeks scope](index.md)
