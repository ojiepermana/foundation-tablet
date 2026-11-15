# 11. Build dan pengujian otomatis · planned

Beri kontributor dan GitHub Actions jalur build yang sama. Pustaka Rust untuk simulator, emulator, dan perangkat dikemas sesuai targetnya.

Perluas CI [alur salam](04-salam-rust-pada-dua-tablet.md) ke target yang ditetapkan pada [matriks dukungan](01-arsitektur-dan-build-awal.md). Pada iPad, tautkan pustaka Rust dalam build Release untuk target perangkat fisik selain menjalankan salam di simulator. Pada Android, periksa pustaka Rust di APK akhir untuk tiap ABI yang dijanjikan. Bila matriks mencakup halaman memori 16 KB, periksa alignment segmen ELF dan alignment ZIP untuk pustaka yang disimpan tanpa kompresi, lalu jalankan salam di emulator yang mengembalikan `16384` untuk `adb shell getconf PAGE_SIZE`.

**Done when:** satu pull request berhasil menjalankan build kedua platform dari clone bersih dengan perintah repo yang sama seperti di lokal, termasuk runner macOS untuk iPad. Bukti mencakup generasi binding, token, sumber daya, pemeriksaan arsitektur, format, lint, tes, dan hasil pemeriksaan paket per target. Workflow memakai izin token minimum, revisi action eksternal yang dikunci, dan berjalan tanpa kredensial penandatanganan produksi. AC 29, 30.

* [ ] Hubungkan build lokal dan otomatis: `/develop build dan pengujian otomatis`

[Kembali ke indeks scope](index.md)
