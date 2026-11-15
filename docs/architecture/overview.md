# Gambaran arsitektur

Dokumen ini menggambarkan repo seperti yang sudah dibangun sampai fitur 03, memakai lapisan A sampai E dari [README](../../README.md) bagian 3. Keputusannya dicatat di [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) dan [spec 0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md); aturan kontrak ada di [konvensi kontrak FFI](../contracts/ffi-conventions.md). Cara membangun ada di [panduan mulai singkat](../getting-started.md).

## Lapisan dan keadaannya

| Lapisan README | Isi yang dijanjikan README | Yang sudah ada di repo |
| --- | --- | --- |
| A. Presentasi tablet native | SwiftUI di iPad, Compose di Android | `apps/ipados`: satu `WindowGroup` dengan satu `Text` statis. `apps/android-tablet`: satu `ComponentActivity` dengan `setContent` dan satu `Text` statis. Belum ada navigasi, token, atau lokalisasi |
| B. Integrasi platform native | API Apple di Swift, API Android di Kotlin | Belum ada isi. Konfigurasi platform saja: `apps/ipados/Config/Base.xcconfig` (iPadOS 26.0, hanya iPad) dan katalog versi Android (`minSdk` 29, `targetSdk` 36, `compileSdk` 37) |
| C. Inti Rust bersama | Perilaku dan aturan bersama, ekspor lewat UniFFI | `crates/core` (paket `tablet-core`, tanpa dependensi, dengan `hello`) dan `crates/tablet-ffi` (memuat `uniffi` dan mengekspor `hello` dengan `#[uniffi::export]`). Pustaka dibangun untuk keempat target matriks dan binding dihasilkan darinya, tetapi belum ditautkan ke aplikasi |
| D. Sistem desain bersama | Token kanonis dan pemetaan tema native | Belum ada. Dibuat fitur 08 |
| E. Sumber daya dan tooling bersama | Generasi, validasi, kunci versi | Kunci versi (`rust-toolchain.toml`, `Cargo.toml`, `Cargo.lock`, `.xcode-version`, katalog dan wrapper Gradle), dua skrip build, `scripts/generate-bindings.sh`, dan `scripts/test.sh` di `scripts/`, crate generator `tooling/uniffi-bindgen`, serta tes tingkat repo di `tests/`. Validasi arsitektur (fitur 10) belum ada |

Tata kelola (`AGENTS.md`, `docs/`) ada di luar kelima lapisan. Fitur 01 menambah dokumen ini, panduan mulai singkat, dan empat dokumen arsitektur lain. Fitur 03 menambah `docs/contracts/ffi-conventions.md`.

## Alur build saat ini

```
scripts/build-ipados.sh ──> cargo build (aarch64-apple-ios-sim, aarch64-apple-ios)
                        └─> xcodebuild (Debug simulator, Release perangkat tanpa tanda tangan)

scripts/build-android-tablet.sh ──> cargo ndk (arm64-v8a, x86_64)
                                └─> ./gradlew :app:assembleDebug

scripts/generate-bindings.sh <swift|kotlin> <pustaka>... ──> cargo build -p tablet-uniffi-bindgen (host)
                                                        └─> uniffi-bindgen generate per pustaka, harus identik
```

Hanya `scripts/` yang memanggil Cargo. Proyek Xcode dan Gradle tidak tahu apa pun tentang Rust. Skrip build belum memanggil skrip generasi dan belum menyalin pustaka ke proyek native (fitur 04). Skrip generasi dijalankan sendiri sesudah skrip build.

## Dokumen lain

- [Matriks dukungan](support-matrix.md): versi alat, target, OS minimum, alasan, status 16 KB.
- [Pemilik tiap bagian](ownership-matrix.md): siapa memegang tiap folder dan mana yang hasil generasi.
- [Aturan dependensi](dependency-rules.md): arah dependensi yang diizinkan dan tujuh aturannya.
- [Struktur repo](repository-structure.md): struktur nyata dan penyimpangan dari README bagian 5.

`boundaries.md` dari README bagian 5 belum ditulis. Fitur pertama yang menambah isi batas lapisan menulisnya (kandidat: fitur 10).

## Ditetapkan, belum dibangun

Hal di bawah sudah diputuskan di spec 0001 atau 0002 tetapi belum ada di repo. Fitur yang disebut membangunnya dengan mengikuti keputusan itu.

| Hal | Keputusan | Dibangun oleh |
| --- | --- | --- |
| Pengemasan iPad | XCFramework statis `bindings/swift/TabletFFI.xcframework` dari pustaka dan `target/bindings/swift/headers` di dalam paket Swift lokal `bindings/swift` (`Package.swift` di-commit, `platforms: [.iOS("26.0")]`, mode bahasa Swift 6), ditautkan ke target `Tablet` | Fitur 04 (rincian di spec 0002, "Serah terima ke fitur 04") |
| Pengemasan Android | `libtablet_ffi.so` per ABI ke `apps/android-tablet/app/src/main/jniLibs/` lewat `cargo ndk -o`; sumber Kotlin di `bindings/kotlin/` sebagai folder sumber modul `:app`; JNA bentuk `@aar` | Fitur 04 (versi JNA di spec 0002, "Serah terima ke fitur 04") |
| Urutan pengemasan di skrip | Hapus keluaran lama, bangun pustaka, panggil `scripts/generate-bindings.sh` dengan pustaka yang dibangun pada run itu, kemas, lalu `xcodebuild` atau Gradle | Fitur 04 |
| Menjalankan di emulator Android | AVD tablet dari image `google_apis` `android-36` `arm64-v8a` yang sudah terpasang; di CI emulator `x86_64` di runner Linux | Fitur 04 |
| Salinan kedua iPadOS minimum | `platforms` di `bindings/swift/Package.swift` harus sama dengan `IPHONEOS_DEPLOYMENT_TARGET` di `Base.xcconfig` | Fitur 04 menulisnya, fitur 10 memeriksanya |

Belum ditetapkan, dan bukan bagian spec 0001 atau 0002: bentuk pemeriksaan batas arsitektur (fitur 10), workflow CI beserta `zipalign -P 16` dan emulator 16 KB (fitur 11), serta sistem desain dan sumber daya bersama (fitur 08 dan 09).
