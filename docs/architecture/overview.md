# Gambaran arsitektur

Dokumen ini menggambarkan repo seperti yang sudah dibangun sampai implementasi fitur 04, memakai lapisan A sampai E dari [README](../../README.md) bagian 3. Keputusannya dicatat di [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) dan [spec 0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md); aturan kontrak ada di [konvensi kontrak FFI](../contracts/ffi-conventions.md). Cara membangun ada di [panduan mulai singkat](../getting-started.md).

## Lapisan dan keadaannya

| Lapisan README | Isi yang dijanjikan README | Yang sudah ada di repo |
| --- | --- | --- |
| A. Presentasi tablet native | SwiftUI di iPad, Compose di Android | Kedua aplikasi memiliki layar nama dan salam, state presentasi lokal, serta aksi tombol/submit ke binding Rust. Belum ada navigasi, token, atau lokalisasi |
| B. Integrasi platform native | API Apple di Swift, API Android di Kotlin | Tidak ada izin platform baru. Konfigurasi platform: `apps/ipados/Config/Base.xcconfig` (iPadOS 26.0, hanya iPad) dan katalog versi Android (`minSdk` 29, `targetSdk` 36, `compileSdk` 37) |
| C. Inti Rust bersama | Perilaku dan aturan bersama, ekspor lewat UniFFI | `crates/core` (paket `tablet-core`, tanpa dependensi, dengan `hello`) dan `crates/tablet-ffi` (memuat `uniffi` dan mengekspor `hello` dengan `#[uniffi::export]`). Pustaka dibangun untuk keempat target matriks dan binding dihasilkan darinya, ditautkan ke kedua aplikasi |
| D. Sistem desain bersama | Token kanonis dan pemetaan tema native | Belum ada. Dibuat fitur 08 |
| E. Sumber daya dan tooling bersama | Generasi, validasi, kunci versi | Kunci versi (`rust-toolchain.toml`, `Cargo.toml`, `Cargo.lock`, `.xcode-version`, katalog dan wrapper Gradle), dua skrip build, `scripts/generate-bindings.sh`, dan `scripts/test.sh` di `scripts/`, crate generator `tooling/uniffi-bindgen`, serta tes tingkat repo di `tests/`. Validasi arsitektur (fitur 10) belum ada |

Tata kelola (`AGENTS.md`, `docs/`) ada di luar kelima lapisan. Fitur 01 menambah dokumen ini, panduan mulai singkat, dan empat dokumen arsitektur lain. Fitur 03 menambah `docs/contracts/ffi-conventions.md`.

## Alur build saat ini

```text
build-ipados.sh -> Rust staticlibs -> generate-bindings.sh swift
                -> XCFramework + paket TabletBindings -> Xcode Debug/Release
build-android-tablet.sh -> Rust cdylibs -> generate-bindings.sh kotlin
                       -> jniLibs + sumber Kotlin + JNA -> Gradle APK
```

Hanya `scripts/` yang memanggil Cargo. Kedua skrip build menghasilkan binding dari pustaka yang baru dibangunnya sebelum mengemas dan membangun aplikasi. Proyek Xcode dan Gradle hanya membaca binding serta pustaka terkemas. `scripts/test-ipados.sh` dan `scripts/test-android-tablet.sh` menguji alur pada target eksplisit, tanpa memanggil Cargo. Workflow PR di `.github/workflows/` memanggil jalur lokal yang sama; hasil hosted CI harus dibuktikan dari run yang benar benar selesai.

## Dokumen lain

- [Matriks dukungan](support-matrix.md): versi alat, target, OS minimum, alasan, status 16 KB.
- [Pemilik tiap bagian](ownership-matrix.md): siapa memegang tiap folder dan mana yang hasil generasi.
- [Aturan dependensi](dependency-rules.md): arah dependensi yang diizinkan dan tujuh aturannya.
- [Struktur repo](repository-structure.md): struktur nyata dan penyimpangan dari README bagian 5.

`boundaries.md` dari README bagian 5 belum ditulis. Fitur pertama yang menambah isi batas lapisan menulisnya (kandidat: fitur 10).

## Kemasan yang tersedia

Paket Swift lokal `bindings/swift/Package.swift` mengekspos `TabletBindings` melalui XCFramework statis. Binding dan XCFramework tidak di-commit. Android memakai sumber Kotlin hasil generasi di modul `:app`, menyalin `libtablet_ffi.so` ke `jniLibs` untuk setiap ABI terdaftar, dan memakai runtime JNA AAR. Rincian kontrak tetap di spec 0002, implementasi dan bukti fitur 04 di [spec 0003](../specs/0003-salam-rust-dua-tablet.md) serta [scope 04](../scope/04-salam-rust-pada-dua-tablet.md).

Pemeriksaan batas arsitektur lengkap tetap fitur 10. Perluasan CI termasuk emulator 16 KB dan `zipalign -P 16` tetap fitur 11. Sistem desain dan sumber daya bersama tetap fitur 08 dan 09.
