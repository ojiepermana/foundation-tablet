# Struktur repo

Struktur nyata repo sesudah implementasi fitur 04, dan setiap penyimpangan dari struktur dasar [README](../../README.md) bagian 5 beserta alasannya. README menyebut struktur itu sebagai baseline, bukan kewajiban membuat semua folder: folder hanya dibuat bila punya tanggung jawab nyata, tanpa file penanda tempat. Sumber keputusannya [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) bagian "Struktur repo fitur 01" dan "Penyimpangan dari README bagian 5".

## Struktur nyata

File sumber yang akan di-commit bersama fitur. Hasil build dan file lokal tidak tercantum (lihat `.gitignore` akar).

```
AGENTS.md                          instruksi untuk agen
README.md                          kebutuhan produk
Cargo.toml                         workspace: members, [workspace.package], [workspace.dependencies]
Cargo.lock                         di-commit
rust-toolchain.toml                channel 1.99.1, profile minimal, rustfmt, clippy, empat target
.xcode-version                     27.1
.gitignore                         aturan commit spec 0001
crates/
  core/                            paket tablet-core (lib): Cargo.toml, src/lib.rs
  tablet-ffi/                      paket tablet-ffi (lib, staticlib, cdylib): Cargo.toml, src/lib.rs, uniffi.toml
tooling/
  uniffi-bindgen/                  paket tablet-uniffi-bindgen (bin uniffi-bindgen): Cargo.toml, src/main.rs
apps/
  ipados/
    Tablet.xcodeproj/              project.pbxproj, xcshareddata/xcschemes/Tablet.xcscheme
    Config/Base.xcconfig           versi dan build setting aplikasi
    Config/UITests.xcconfig        identitas target XCTest UI
    TabletUITests/                 pengujian UI salam melalui FFI
    Tablet/App/TabletApp.swift     @main, WindowGroup, GreetingView dan binding Rust
  android-tablet/
    settings.gradle.kts, build.gradle.kts, gradle.properties
    gradle/libs.versions.toml
    gradle/gradle-daemon-jvm.properties
    gradle/wrapper/gradle-wrapper.jar, gradle-wrapper.properties
    gradlew, gradlew.bat
    app/build.gradle.kts
    app/src/main/AndroidManifest.xml
    app/src/main/kotlin/foundation/tablet/MainActivity.kt
    app/src/main/res/values/strings.xml
    app/src/androidTest/           tes Compose Activity dan FFI
bindings/swift/Package.swift      paket lokal TabletBindings, sumber hasil generasi diabaikan
.github/workflows/                workflow PR kedua platform
scripts/
  build-ipados.sh                  mode 100755
  build-android-tablet.sh          mode 100755
  generate-bindings.sh             mode 100755, binding Swift atau Kotlin dari pustaka tablet-ffi
  test.sh                          mode 100755, menjalankan tes tingkat repo
  test-ipados.sh, test-android-tablet.sh  tes UI dengan target eksplisit
  ci-*.sh                          persiapan runner dan laporan CI
tests/
  lib/harness.sh                   helper tes: asersi, sandbox, alat tiruan
  repo/                            crate-boundary.test.sh, version-locks.test.sh, commit-policy.test.sh,
                                   agent-rules.test.sh (fitur 02)
  build-scripts/                   build-ipados.test.sh, build-android-tablet.test.sh
  artifacts/                       ipados.test.sh, android-tablet.test.sh
test-preferences.json              pilihan alat untuk skill /test, di-commit
docs/
  getting-started.md               panduan mulai singkat
  contributing.md                  panduan kontribusi (fitur 02)
  architecture/                    lima dokumen ini
  contracts/ffi-conventions.md     konvensi kontrak FFI (fitur 03)
  specs/                           spec keputusan (0001 dan seterusnya)
  scope/                           rencana fitur, termasuk coordination/
  reviews/                         bukti build, verify, dan review
  quality/audit-scaffold.md        audit awal
.claude/skills/coordinate/         alur koordinasi sesi agen
```

Folder yang dibuat build atau generasi dan tidak di-commit: `bindings/swift/Sources/`, `bindings/kotlin/`, `target/` (termasuk `target/bindings/swift/headers/`), `apps/ipados/build/`, `apps/android-tablet/app/build/`, `apps/android-tablet/.gradle/`, `apps/android-tablet/.kotlin/`.

## Penyimpangan dari README bagian 5

| README | Di repo | Alasan |
| --- | --- | --- |
| Paket di `crates/core` | Folder sama, nama paket `tablet-core` | Nama `core` bentrok dengan crate bawaan Rust |
| `apps/ipados/App/`, `Presentation/`, dan seterusnya | Di dalam `apps/ipados/Tablet/` | Satu folder target yang tersinkron membuat `project.pbxproj` tidak berubah saat file bertambah |
| Tidak ada | `apps/ipados/Config/` | Build setting di xcconfig supaya terbaca dan punya satu sumber |
| `apps/android-tablet/presentation/`, `designsystem/`, `platform/`, `tests/` | Paket Kotlin di dalam modul `app` (`foundation.tablet.presentation` dan seterusnya), tes di `app/src/test` dan `app/src/androidTest` | Mengikuti konvensi Gradle; satu modul cukup untuk fondasi |
| `bindings/swift`, `bindings/kotlin` berisi binding | Sama, tetapi `bindings/swift` adalah paket Swift lokal dan isinya tidak di-commit | Kode generasi terisolasi di modulnya sendiri dan selalu berasal dari revisi yang sama dengan pustaka |
| `docs/decisions/ADR-*`, `docs/plans/` | `docs/specs/` dan `docs/scope/` | Alur kerja repo ini mencatat keputusan sebagai spec dan rencana sebagai scope |
| Lima file `docs/architecture/` | Empat dari lima, ditambah `support-matrix.md`; `boundaries.md` belum ditulis | Matriks dirujuk fitur 03 dan 11 sehingga perlu alamat sendiri; batas lapisan di luar yang sudah dibangun belum punya isi |
| Panduan di `README.md` | `docs/getting-started.md` | `README.md` adalah dokumen kebutuhan produk |
| Tidak ada | `.xcode-version`, `Cargo.lock` di akar | Kunci versi |
| `tests/fixtures`, `tests/contracts` | `tests/lib`, `tests/repo`, `tests/build-scripts`, `tests/artifacts`; dua folder README belum dibuat | Fitur 01 hanya punya tes tingkat repo; fixture dan tes kontrak dibuat oleh fitur pemiliknya |
| `scripts/test.sh` | Ada sejak fitur 01, menjalankan tes tingkat repo saja | `cargo test` tetap perintah tes Rust; spec 0002 (K12) memutuskan runner tidak mendapat grup Cargo |
| Tidak ada | `test-preferences.json` di akar | Skill `/test` membaca pilihan alat dari file ini, jadi tidak bertanya di tiap fitur |
| `tooling/codegen/`, `tooling/validation/` | `tooling/uniffi-bindgen/` | Satu crate generator binding; folder validasi dibuat fitur 10 bila perlu |
| `docs/contracts/ffi-conventions.md` | Sama | Ditulis fitur 03 |
| `design-system/`, `shared/`, skrip fitur lanjutan | Belum dibuat | README melarang folder penanda tempat; dibuat oleh fitur pemiliknya |

Baris `apps/ipados/Tablet/` berlaku untuk folder di dalam target: saat ini hanya `Tablet/App/` yang ada. Folder `Presentation/`, `Platform/`, dan seterusnya dibuat di dalam `Tablet/` oleh fitur yang pertama mengisinya. Paket Kotlin `foundation.tablet.presentation` belum ada; paket utama tetap `foundation.tablet`, dengan tes UI di `app/src/androidTest`.

Folder `bindings/` dibuat sejak fitur 03. `bindings/swift/Package.swift` adalah sumber yang di-commit; Swift, Kotlin dan XCFramework hasil generasi tetap diabaikan. Fitur 04 menambahkan tes UI native dan workflow PR, tanpa membentuk lapisan layanan tambahan.
