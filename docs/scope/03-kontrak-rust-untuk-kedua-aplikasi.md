# 3. Kontrak Rust untuk kedua aplikasi · in-progress

Batasi model data awal pada satu nama masuk dan satu teks salam keluar. Rust memiliki perilakunya, UniFFI menyediakan antarmuka publik, dan aplikasi memiliki keadaan tampilan.

**Done when:** inti bebas dari dependensi UI. Binding Swift dan Kotlin untuk `hello(name: String) -> String` dapat dihasilkan ulang tanpa suntingan manual dari revisi sumber yang sama dengan pustaka Rust yang akan ditautkan untuk tiap target dalam [matriks dukungan](01-arsitektur-dan-build-awal.md). Konvensi menjelaskan kompatibilitas, kepemilikan nilai, galat, dan perluasan kontrak tanpa mengekspos tipe privat atau membuat entitas bisnis. AC 3, 4, 25.

**Pointer:** spec [0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md)

* [x] Rancang batas kontrak (spec): `/architect kontrak Rust untuk kedua aplikasi`
* [x] Build it: `/develop kontrak Rust untuk kedua aplikasi`. Kode di [`crates/`](../../crates), [`tooling/uniffi-bindgen/`](../../tooling/uniffi-bindgen), [`scripts/generate-bindings.sh`](../../scripts/generate-bindings.sh), dan [`docs/contracts/`](../contracts). Langkah verify di [verify.md spec 0002](../specs/0002-kontrak-rust-kedua-aplikasi/verify.md).
  * [x] Milestone 1: Benang tipis Rust ke Swift. Build plan 1 sampai 4. AC-1, AC-2, AC-3, AC-4, AC-10. `hello` di inti, ekspor UniFFI, `uniffi.toml`, crate `tooling/uniffi-bindgen`, jalur bahagia `scripts/generate-bindings.sh` untuk simulator iPad.
  * [x] Milestone 2: Empat target, dua bahasa, pemeriksaan lengkap. Build plan 5 sampai 7. AC-4, AC-5, AC-6, AC-7. Needs milestone 1. Build Xcode lalu Gradle (satu build native pada satu waktu).
  * [x] Milestone 3: Konvensi kontrak dan catatan arsitektur. Build plan 8 sampai 10. AC-8, AC-9, AC-10. Needs milestone 2.
* [ ] Verify it: `/check verify kontrak Rust untuk kedua aplikasi`. Terakhir terverifikasi: [verify fitur 03](../reviews/2026-11-16-verify-f03.md), AC-1 sampai AC-9 PASS pada `962b9c9` ditambah perubahan yang belum di-commit (simulator dan perangkat iPad lewat pemeriksaan tipe Swift 6, ABI `arm64-v8a` dan `x86_64`, host macOS 27.0.1); kompilasi Kotlin `NOT_RUN` (fitur 04). Masih terbuka: mode `100755` (AC-10) dan `HI4`, `HA5` butuh commit. Langkah berikutnya: commit, lalu `git ls-files -s scripts/generate-bindings.sh` dan, sesudah kedua skrip build, `scripts/test.sh artifacts` pada SHA itu.
* [x] Test it: `/test kontrak Rust untuk kedua aplikasi`. Bukti: [tes fitur 03](../reviews/2026-11-16-test-f03.md), 5 tes Rust dan 8 file `scripts/test.sh` lulus (bash 3.2 juga); tujuh perubahan sengaja membuat kasusnya merah. Linux `NOT_RUN` (fitur 11).
  * [x] Milestone 4: Tes. Build plan 11 sampai 13. Mengunci AC-3, AC-6, AC-7, AC-8, AC-10. Needs milestone 1 sampai 3.

[Kembali ke indeks scope](index.md)
