# Struktur repo

Struktur nyata repo sesudah fitur 01, dan setiap penyimpangan dari struktur dasar [README](../../README.md) bagian 5 beserta alasannya. README menyebut struktur itu sebagai baseline, bukan kewajiban membuat semua folder: folder hanya dibuat bila punya tanggung jawab nyata, tanpa file penanda tempat. Sumber keputusannya [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) bagian "Struktur repo fitur 01" dan "Penyimpangan dari README bagian 5".

## Struktur nyata

Hanya file yang di-commit. Hasil build dan file lokal tidak tercantum (lihat `.gitignore` akar).

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
  tablet-ffi/                      paket tablet-ffi (lib, staticlib, cdylib): Cargo.toml, src/lib.rs
apps/
  ipados/
    Tablet.xcodeproj/              project.pbxproj, xcshareddata/xcschemes/Tablet.xcscheme
    Config/Base.xcconfig           semua build setting
    Tablet/App/TabletApp.swift     @main, WindowGroup, satu Text statis
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
scripts/
  build-ipados.sh                  mode 100755
  build-android-tablet.sh          mode 100755
  test.sh                          mode 100755, menjalankan tes tingkat repo
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
  specs/                           spec keputusan (0001 dan seterusnya)
  scope/                           rencana fitur, termasuk coordination/
  reviews/                         bukti build, verify, dan review
  quality/audit-scaffold.md        audit awal
.claude/skills/coordinate/         alur koordinasi sesi agen
```

Folder yang dibuat build dan tidak di-commit: `target/`, `apps/ipados/build/`, `apps/android-tablet/app/build/`, `apps/android-tablet/.gradle/`, `apps/android-tablet/.kotlin/`.

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
| `scripts/test.sh` | Ada sejak fitur 01, menjalankan tes tingkat repo saja | `cargo test` tetap perintah tes Rust; fitur 03 memutuskan apakah runner mendapat grup Rust |
| Tidak ada | `test-preferences.json` di akar | Skill `/test` membaca pilihan alat dari file ini, jadi tidak bertanya di tiap fitur |
| `design-system/`, `shared/`, `tooling/`, `.github/`, skrip lain | Belum dibuat | README melarang folder penanda tempat; dibuat oleh fitur pemiliknya |

Baris `apps/ipados/Tablet/` berlaku untuk folder di dalam target: saat ini hanya `Tablet/App/` yang ada. Folder `Presentation/`, `Platform/`, dan seterusnya dibuat di dalam `Tablet/` oleh fitur yang pertama mengisinya. Paket Kotlin `foundation.tablet.presentation` dan folder tes Android juga belum ada; saat ini hanya paket `foundation.tablet`.

Baris `bindings/` adalah keputusan yang ditetapkan, belum dibangun: folder itu belum ada sampai fitur 03 dan 04.
