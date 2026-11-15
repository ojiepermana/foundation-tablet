# Pemilik tiap bagian

Tabel ini menyebut lapisan README (bagian 3) yang memegang tiap path, tanggung jawabnya, dan apakah isinya hasil generasi. Sumbernya [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) bagian "Pemilik tiap bagian". Sebelum menaruh kode baru, cari path tujuannya di sini; bila lapisan yang cocok belum punya folder, folder itu dibuat oleh fitur pemiliknya, bukan sebagai penanda tempat.

| Path | Pemilik (lapisan README) | Tanggung jawab | Hasil generasi | Ada di repo |
| --- | --- | --- | --- | --- |
| `crates/core` | Inti Rust (C) | Perilaku dan aturan bersama | Tidak | Ya, paket `tablet-core` tanpa fungsi |
| `crates/tablet-ffi` | Batas UniFFI (C) | Hanya memetakan API inti ke kontrak UniFFI; tanpa perilaku sendiri | Tidak | Ya, tanpa ekspor |
| `bindings/swift`, `bindings/kotlin` | Tooling (E) | Binding hasil generasi dan pustaka terkemas | Ya, kecuali `Package.swift` | Belum, ditetapkan untuk fitur 03 dan 04 |
| `apps/ipados` | Presentasi dan integrasi iPad (A, B) | SwiftUI, scene, API Apple | Tidak | Ya |
| `apps/android-tablet` | Presentasi dan integrasi Android (A, B) | Compose, Activity, API Android | Tidak, kecuali `jniLibs` | Ya (`jniLibs` belum ada) |
| `scripts/` | Tooling (E) | Pintu build yang sama untuk lokal dan CI | Tidak | Ya, `build-ipados.sh` dan `build-android-tablet.sh` |
| `rust-toolchain.toml`, `Cargo.toml`, `.xcode-version`, `libs.versions.toml`, wrapper Gradle | Tooling (E) | Kunci versi | Tidak | Ya |
| `docs/architecture` | Tata kelola | Catatan arsitektur | Tidak | Ya |
| `docs/specs`, `docs/scope` | Tata kelola | Catatan keputusan dan rencana | Tidak | Ya |
| `design-system/`, `shared/`, `tooling/`, `tests/`, `.github/` | Pemilik fitur 03, 08, 09, 10, 11 | Belum ada | Belum ada | Belum |

`Cargo.lock` ikut kunci versi (lapisan E) dan di-commit. `docs/getting-started.md` ikut tata kelola. Hasil build (`target/`, `apps/ipados/build/`, folder `build/` Gradle) tidak punya pemilik karena tidak pernah di-commit; daftar lengkapnya ada di spec bagian "Aturan commit" dan di `.gitignore` akar.
