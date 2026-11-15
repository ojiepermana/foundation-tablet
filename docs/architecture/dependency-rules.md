# Aturan dependensi

Arah dependensi yang diizinkan di repo ini, dari [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) bagian "Arah dependensi". Panah berarti "boleh bergantung pada". Arah yang tidak digambar tidak diizinkan.

```
apps/ipados ──────┐
                  ├──> bindings (hasil generasi) ──> crates/tablet-ffi ──> crates/core
apps/android-tablet ┘
scripts ──> cargo, xcodebuild, gradle (hanya saat build)
```

Pada fitur 01 baru bagian kanan diagram yang ada: `crates/tablet-ffi` bergantung pada `crates/core`. Folder `bindings` dan tautan aplikasi ke binding ditetapkan, belum dibangun (fitur 03 dan 04), jadi kedua aplikasi saat ini belum bergantung pada apa pun di repo.

## Tujuh aturan

1. `tablet-core` tidak bergantung pada apa pun di repo ini, pada `uniffi`, atau pada kerangka UI dan platform.
2. `tablet-ffi` hanya bergantung pada `tablet-core` dan `uniffi`. Di luar crate tooling generator binding, hanya crate ini yang boleh memuat `uniffi`.
3. Aplikasi hanya memakai Rust lewat binding hasil generasi dan pustaka terkemas. Aplikasi tidak merujuk `crates/` atau `target/`.
4. Kedua aplikasi tidak saling bergantung dan tidak berbagi kode sumber.
5. Rust tidak bergantung pada aplikasi, token desain, atau sumber daya bersama.
6. Proyek Xcode dan Gradle tidak memanggil Cargo. Hanya `scripts/` yang menyeberang dari Rust ke native.
7. Hasil generasi tidak disunting tangan dan tidak di-commit.

## Cara memeriksa sekarang

Belum ada pemeriksaan otomatis (fitur 10). Sampai ada, kamu bisa memeriksa aturan 1 dan 2 dengan:

```bash
cargo tree -p tablet-core -e normal
cargo tree -p tablet-ffi -e normal --depth 1
```

Yang pertama hanya menampilkan `tablet-core`. Yang kedua menampilkan `tablet-ffi` dengan tepat dua anak: `tablet-core` dan `uniffi v0.32.2`.

Untuk aturan 7, `git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'` harus kosong, dan `git status --short` harus tetap kosong sesudah kedua skrip build dijalankan.
