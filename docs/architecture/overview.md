# Gambaran arsitektur

Dokumen ini menggambarkan repo seperti yang sudah dibangun sampai fitur 01, memakai lapisan A sampai E dari [README](../../README.md) bagian 3. Keputusannya dicatat di [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md). Cara membangun ada di [panduan mulai singkat](../getting-started.md).

## Lapisan dan keadaannya

| Lapisan README | Isi yang dijanjikan README | Yang sudah ada di repo |
| --- | --- | --- |
| A. Presentasi tablet native | SwiftUI di iPad, Compose di Android | `apps/ipados`: satu `WindowGroup` dengan satu `Text` statis. `apps/android-tablet`: satu `ComponentActivity` dengan `setContent` dan satu `Text` statis. Belum ada navigasi, token, atau lokalisasi |
| B. Integrasi platform native | API Apple di Swift, API Android di Kotlin | Belum ada isi. Konfigurasi platform saja: `apps/ipados/Config/Base.xcconfig` (iPadOS 26.0, hanya iPad) dan katalog versi Android (`minSdk` 29, `targetSdk` 36, `compileSdk` 37) |
| C. Inti Rust bersama | Perilaku dan aturan bersama, ekspor lewat UniFFI | `crates/core` (paket `tablet-core`, tanpa dependensi, tanpa fungsi) dan `crates/tablet-ffi` (memuat `uniffi` 0.32.2 dan `uniffi::setup_scaffolding!()`, tanpa ekspor). Pustaka dibangun untuk keempat target matriks, belum ditautkan ke aplikasi |
| D. Sistem desain bersama | Token kanonis dan pemetaan tema native | Belum ada. Dibuat fitur 08 |
| E. Sumber daya dan tooling bersama | Generasi, validasi, kunci versi | Kunci versi (`rust-toolchain.toml`, `Cargo.toml`, `Cargo.lock`, `.xcode-version`, katalog dan wrapper Gradle), dua skrip build dan `scripts/test.sh` di `scripts/`, serta tes tingkat repo di `tests/`. Generator binding dan validasi arsitektur (fitur 10) belum ada |

Tata kelola (`AGENTS.md`, `docs/`) ada di luar kelima lapisan. Fitur 01 menambah dokumen ini, panduan mulai singkat, dan empat dokumen arsitektur lain.

## Alur build saat ini

```
scripts/build-ipados.sh ──> cargo build (aarch64-apple-ios-sim, aarch64-apple-ios)
                        └─> xcodebuild (Debug simulator, Release perangkat tanpa tanda tangan)

scripts/build-android-tablet.sh ──> cargo ndk (arm64-v8a, x86_64)
                                └─> ./gradlew :app:assembleDebug
```

Hanya `scripts/` yang memanggil Cargo. Proyek Xcode dan Gradle tidak tahu apa pun tentang Rust. Pada fitur 01 skrip belum menyalin pustaka ke proyek native.

## Dokumen lain

- [Matriks dukungan](support-matrix.md): versi alat, target, OS minimum, alasan, status 16 KB.
- [Pemilik tiap bagian](ownership-matrix.md): siapa memegang tiap folder dan mana yang hasil generasi.
- [Aturan dependensi](dependency-rules.md): arah dependensi yang diizinkan dan tujuh aturannya.
- [Struktur repo](repository-structure.md): struktur nyata dan penyimpangan dari README bagian 5.

`boundaries.md` dari README bagian 5 belum ditulis. Fitur pertama yang menambah isi batas lapisan menulisnya (kandidat: fitur 10).

## Ditetapkan, belum dibangun

Hal di bawah sudah diputuskan di spec 0001 tetapi belum ada di repo. Fitur yang disebut membangunnya dengan mengikuti keputusan itu.

| Hal | Keputusan | Dibangun oleh |
| --- | --- | --- |
| Fungsi `hello` dan kontrak pertama | Ditambahkan ke `tablet-core`, diekspor `tablet-ffi` | Fitur 03 |
| Generator binding | `scripts/generate-bindings.sh` dan `uniffi.toml`; generator berjalan dari workspace dengan versi UniFFI yang sama dengan runtime (kandidat crate tooling `tooling/uniffi-bindgen`) | Fitur 03 |
| Nama modul binding | FFI C `TabletFFI` (header `TabletFFI.h`), modul Swift dan produk paket `TabletBindings`, paket Kotlin `foundation.tablet.bindings` | Fitur 03 menulisnya ke `uniffi.toml` |
| Pengemasan iPad | XCFramework statis `bindings/swift/TabletFFI.xcframework` di dalam paket Swift lokal `bindings/swift` (`Package.swift` di-commit, `platforms: [.iOS("26.0")]`), ditautkan ke target `Tablet` | Fitur 04 |
| Pengemasan Android | `libtablet_ffi.so` per ABI ke `apps/android-tablet/app/src/main/jniLibs/` lewat `cargo ndk -o`; sumber Kotlin di `bindings/kotlin/` sebagai folder sumber modul `:app`; JNA bentuk `@aar` | Fitur 04 (versi JNA ditetapkan fitur 03) |
| Lokasi binding | `bindings/swift/Sources/TabletBindings/` dan `bindings/kotlin/`, keduanya hasil generasi dan tidak di-commit | Fitur 03 dan 04 |
| Urutan pengemasan di skrip | Hapus keluaran lama, bangun pustaka, panggil generator, kemas, lalu `xcodebuild` atau Gradle | Fitur 04 |
| Menjalankan di emulator Android | AVD tablet dari image `google_apis` `android-36` `arm64-v8a` yang sudah terpasang; di CI emulator `x86_64` di runner Linux | Fitur 04 |
| Salinan kedua iPadOS minimum | `platforms` di `bindings/swift/Package.swift` harus sama dengan `IPHONEOS_DEPLOYMENT_TARGET` di `Base.xcconfig` | Fitur 04 menulisnya, fitur 10 memeriksanya |

Belum ditetapkan, dan bukan bagian spec 0001: bentuk pemeriksaan batas arsitektur (fitur 10), workflow CI beserta `zipalign -P 16` dan emulator 16 KB (fitur 11), serta sistem desain dan sumber daya bersama (fitur 08 dan 09).
