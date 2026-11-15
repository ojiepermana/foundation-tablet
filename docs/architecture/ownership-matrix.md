# Pemilik tiap bagian

Tabel ini menyebut lapisan README (bagian 3) yang memegang tiap path, tanggung jawabnya, dan apakah isinya hasil generasi. Sumbernya [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) bagian "Pemilik tiap bagian", ditambah baris kontrak dan generator binding dari [spec 0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md). Sebelum menaruh kode baru, cari path tujuannya di sini; bila lapisan yang cocok belum punya folder, folder itu dibuat oleh fitur pemiliknya, bukan sebagai penanda tempat.

| Path | Pemilik (lapisan README) | Tanggung jawab | Hasil generasi | Ada di repo |
| --- | --- | --- | --- | --- |
| `crates/core` | Inti Rust (C) | Perilaku dan aturan bersama | Tidak | Ya, paket `tablet-core` dengan `hello` |
| `crates/tablet-ffi` | Batas UniFFI (C) | Hanya memetakan API inti ke kontrak UniFFI; tanpa perilaku sendiri | Tidak | Ya, mengekspor `hello` |
| `crates/tablet-ffi/uniffi.toml` | Batas UniFFI (C) | Nama modul binding Swift dan Kotlin untuk generator | Tidak | Ya |
| `tooling/uniffi-bindgen` | Tooling (E) | Biner generator binding `uniffi-bindgen` dengan pin `uniffi` workspace; hanya dipanggil `scripts/generate-bindings.sh` | Tidak | Ya, paket `tablet-uniffi-bindgen` |
| `bindings/swift`, `bindings/kotlin` | Tooling (E) | Binding hasil generasi dan pustaka terkemas | Ya, kecuali `Package.swift` | Dibuat `scripts/generate-bindings.sh` sejak fitur 03 dan tidak di-commit; `Package.swift` dan pengemasan dari fitur 04 |
| `target/bindings/swift/headers` | Tooling (E) | Header `TabletFFI.h` dan `module.modulemap` untuk XCFramework | Ya | Dibuat `scripts/generate-bindings.sh`, tidak di-commit |
| `apps/ipados` | Presentasi dan integrasi iPad (A, B) | SwiftUI, scene, API Apple | Tidak | Ya |
| `apps/android-tablet` | Presentasi dan integrasi Android (A, B) | Compose, Activity, API Android | Tidak, kecuali `jniLibs` | Ya (`jniLibs` belum ada) |
| `scripts/generate-bindings.sh` | Tooling (E) | Satu satunya pintu generasi binding Swift dan Kotlin dari pustaka `tablet-ffi` yang sudah dibangun | Tidak | Ya |
| `scripts/` | Tooling (E) | Pintu build, generasi, dan tes yang sama untuk lokal dan CI | Tidak | Ya, `build-ipados.sh`, `build-android-tablet.sh`, `generate-bindings.sh`, dan `test.sh` |
| `tests/lib`, `tests/repo`, `tests/build-scripts`, `tests/artifacts` | Tooling (E) | Tes tingkat repo: hal yang tidak dimiliki satu crate atau satu aplikasi | Tidak | Ya |
| `test-preferences.json` | Tooling (E) | Pilihan alat tes untuk skill `/test` | Tidak | Ya |
| `rust-toolchain.toml`, `Cargo.toml`, `.xcode-version`, `libs.versions.toml`, wrapper Gradle | Tooling (E) | Kunci versi | Tidak | Ya |
| `docs/architecture` | Tata kelola | Catatan arsitektur | Tidak | Ya |
| `docs/specs`, `docs/scope` | Tata kelola | Catatan keputusan dan rencana | Tidak | Ya |
| `docs/contracts` | Tata kelola | Konvensi kontrak FFI | Tidak | Ya, `ffi-conventions.md` |
| `design-system/`, `shared/`, `tests/fixtures`, `tests/contracts`, `.github/` | Pemilik fitur 08, 09, 10, 11 | Belum ada | Belum ada | Belum |

`Cargo.lock` ikut kunci versi (lapisan E) dan di-commit. `docs/getting-started.md` dan `docs/contributing.md` ikut tata kelola. Hasil build (`target/`, `apps/ipados/build/`, folder `build/` Gradle) tidak punya pemilik karena tidak pernah di-commit; daftar lengkapnya ada di spec bagian "Aturan commit" dan di `.gitignore` akar.
