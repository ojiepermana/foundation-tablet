# 0001. Arsitektur dan build awal

**Date**: 2026-11-15
**Status**: In Progress

## Summary

Spec ini menetapkan kerangka repo: satu workspace Rust berisi dua crate (inti dan lapisan ekspor UniFFI), satu proyek iPad, dan satu proyek Android tablet, semuanya dengan versi alat yang dikunci. Kombinasi versi dipilih dari yang tercatat saling cocok di dokumentasi resmi pada 15 November 2026, bukan yang paling baru. Hasil fitur 01 adalah repo yang bisa dikompilasi dari clone bersih dengan perintah repo yang sama untuk lokal dan CI, ditambah catatan arsitektur dan panduan mulai singkat. Salam `hello`, binding, dan penautan pustaka Rust ke aplikasi dibangun di fitur 03 dan 04 dengan mengikuti keputusan pengemasan yang dicatat di sini. Tes fitur 01 adalah satu suite bash kecil di `tests/` yang dijalankan `scripts/test.sh`. Suite itu mengunci batas crate, kunci versi, aturan commit, dan kontrak kedua skrip build, tanpa menambah tes Rust atau target tes native.

## Requirements

**User stories**:

- Sebagai kontributor, saya ingin mengompilasi workspace Rust dan kedua proyek native dari clone bersih dengan perintah repo, supaya saya tahu lingkungan saya benar sebelum menulis fitur.
- Sebagai perancang fitur 03 dan 11, saya ingin satu matriks dukungan yang menyebut target, OS minimum, dan alasan, supaya binding dan CI dibangun untuk target yang sama.
- Sebagai agen yang melanjutkan pekerjaan, saya ingin tahu pemilik tiap folder dan arah dependensi yang diizinkan, supaya saya tidak menaruh kode di lapisan yang salah.

**Acceptance criteria** (kontrak; tiap butir bisa diperiksa sendiri):

- **AC-1** (README AC 1): dari clone bersih, `cargo build --workspace --locked` dan `cargo test --workspace --locked` selesai dengan kode keluar 0. `rustc --version` di akar repo menampilkan `1.99.1`. `Cargo.lock` ter-commit.
- **AC-2** (README AC 2): di fitur 01 workspace berisi tepat dua crate. `tablet-core` di `crates/core` tidak bergantung pada `uniffi` atau crate UI apa pun (saat ini tanpa dependensi sama sekali). `tablet-ffi` di `crates/tablet-ffi` bergantung pada `tablet-core` dan `uniffi` versi `=0.32.2`, dan menghasilkan `staticlib` serta `cdylib`. Bukti: `cargo tree -p tablet-core -e normal` hanya menampilkan `tablet-core`; `cargo tree -p tablet-ffi -e normal --depth 1` menampilkan `tablet-core` dan `uniffi v0.32.2`; sesudah `cargo build`, `target/debug/libtablet_ffi.a` dan `target/debug/libtablet_ffi.dylib` ada.
- **AC-3**: `tablet-ffi` terkompilasi dalam mode release untuk keempat target Rust pada matriks dukungan. Sesudah kedua skrip build dijalankan tanpa argumen, file berikut ada: `target/aarch64-apple-ios/release/libtablet_ffi.a`, `target/aarch64-apple-ios-sim/release/libtablet_ffi.a`, `target/aarch64-linux-android/release/libtablet_ffi.so`, `target/x86_64-linux-android/release/libtablet_ffi.so`.
- **AC-4**: kedua file `.so` Android selaras untuk halaman memori 16 KB. Bukti, untuk tiap file: `"$ANDROID_HOME/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump" -p <file.so> | grep LOAD` menampilkan `align 2**14` di akhir setiap baris (di Linux folder alatnya `linux-x86_64`).
- **AC-5**: `scripts/build-ipados.sh --simulator` selesai dengan kode keluar 0 dan menghasilkan `apps/ipados/build/DerivedData/Build/Products/Debug-iphonesimulator/Tablet.app`. Bukti pada app itu: `lipo -archs Tablet.app/Tablet` menampilkan `arm64` saja; `plutil -extract MinimumOSVersion raw Tablet.app/Info.plist` menampilkan `26.0`; `plutil -extract UIDeviceFamily json -o - Tablet.app/Info.plist` menampilkan `[2]`.
- **AC-6**: `scripts/build-ipados.sh --device` selesai dengan kode keluar 0 dan menghasilkan `apps/ipados/build/DerivedData/Build/Products/Release-iphoneos/Tablet.app` tanpa tanda tangan kode, dengan tiga bukti yang sama seperti AC-5. AC ini hanya menjanjikan build. Menjalankan aplikasi di iPad fisik bukan bagian AC ini (lihat "Bukti perangkat fisik").
- **AC-7**: `scripts/build-android-tablet.sh` selesai dengan kode keluar 0 dan menghasilkan `apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk`. Bukti: `"$ANDROID_HOME/build-tools/36.0.0/aapt2" dump badging <apk>` memuat `minSdkVersion:'29'`, `targetSdkVersion:'36'`, dan `compileSdkVersion='37'`; `unzip -l <apk> | grep 'lib/'` hanya menampilkan folder `lib/arm64-v8a/` dan `lib/x86_64/` (atau tidak ada sama sekali). Menjalankan APK di emulator adalah milik fitur 04, di tablet fisik adalah langkah manual.
- **AC-8**: setiap versi pada tabel "Proposed stack" dikunci di file repo yang disebut tabel itu, dan nilainya sama dengan tabel. `./gradlew buildEnvironment` dari `apps/android-tablet` menampilkan `kotlin-gradle-plugin:2.4.21`. Kedua skrip build berhenti lebih awal dengan kode keluar bukan 0 dan pesan yang menyebut prasyarat yang hilang serta cara memasangnya. Bukti minimal: `ANDROID_HOME=<folder kosong>`, `JAVA_HOME=/tidak/ada`, dan `DEVELOPER_DIR=/tidak/ada`, masing masing dijalankan pada skrip yang relevan.
- **AC-9**: `docs/getting-started.md` memuat prasyarat beserta versinya, cara memasang tiap prasyarat, dan perintah persis pada bagian "Perintah repo". Mengikuti panduan itu pada clone baru (`git clone` ke folder sementara) di mesin yang memenuhi prasyarat mengulang AC-1, AC-3, AC-5, AC-6, dan AC-7 tanpa langkah lain. `git ls-files -s scripts apps/android-tablet/gradlew` menampilkan mode `100755` untuk kedua skrip dan `gradlew`.
- **AC-10**: catatan arsitektur di `docs/architecture/` memuat matriks dukungan (versi alat, target, OS minimum, alasan tiap target, status 16 KB), pemilik tiap bagian, arah dependensi yang diizinkan, dan setiap penyimpangan dari struktur README bagian 5 beserta alasannya. Keputusan yang sudah ditetapkan tetapi belum dibangun (pengemasan pustaka, lokasi binding) ditandai jelas sebagai belum dibangun.
- **AC-11**: kedua aplikasi tetap minimal. Masing masing menampilkan satu layar native statis (SwiftUI `WindowGroup`, Compose `setContent`), belum menautkan pustaka Rust (`unzip -l <apk> | grep libtablet_ffi` kosong), dan belum punya navigasi, token, atau lokalisasi. Tidak ada folder atau file kosong sebagai penanda tempat. `git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'` kosong; satu satunya biner yang di-commit adalah `gradle-wrapper.jar`. Sesudah kedua skrip dijalankan, `git status --short` kosong.

**Bukti perangkat fisik** (bukan syarat AC fitur 01; dicatat `NOT_RUN` di file manual supaya fitur 04, 11, dan 12 mewarisinya):

| ID | Langkah | Prasyarat dari user | Membuktikan |
|---|---|---|---|
| MAN-1 | Jalankan `Tablet` di iPad fisik (iPadOS 26.0 atau lebih baru) dari Xcode | Team ID Apple dan bundle ID asli di `apps/ipados/Config/Local.xcconfig` (`com.example` tidak bisa diprovisikan), iPad terhubung | Baris "iPad perangkat" pada matriks |
| MAN-2 | `adb install` lalu buka `app-debug.apk` di tablet Android fisik (Android 10 atau lebih baru, arm64) | Tablet dengan mode pengembang | Baris "Tablet Android" pada matriks |
| MAN-3 | Ulangi MAN-2 di perangkat yang `adb shell getconf PAGE_SIZE` mengembalikan `16384` | Perangkat 16 KB | Baris "16 KB" pada matriks |

## Decision

**Chosen option**: Opsi 1, kombinasi versi yang terdokumentasi saling cocok, skrip repo sebagai pintu build, pustaka Rust dikemas sebagai XCFramework statis dan `jniLibs`.

Repo memakai Rust 1.99.1, UniFFI 0.32.2, Xcode 27.1, AGP 9.3.3, Gradle 9.5.1, Kotlin 2.4.21, dan NDK 28.2.13676358; dua crate memisahkan inti dari ekspor UniFFI; `scripts/` adalah satu satunya tempat yang menyeberang dari Rust ke proyek native; hasil generasi dan biner tidak pernah di-commit. Tes tingkat repo ditulis dengan bash polos di `tests/` dan dijalankan `scripts/test.sh`; suite itu tidak pernah membangun apa pun sendiri (lihat "Rancangan tes fitur 01").

Tanda `biasa` atau `berat` tiap keputusan ada di tabel "Keputusan diambil" pada [rationale.md](rationale.md). Satu keputusan bertanda `berat`: K32 (alat tes), karena dua opsinya hampir setara dan fitur berikutnya akan mengikuti konvensi ini.

## Rationale

Alasan, opsi yang ditimbang, runner up tiap keputusan, catatan cross check, dan sumber tiap versi ada di [rationale.md](rationale.md).

## Proposed stack

Semua versi diperiksa pada 2026-11-15. Sumber tiap baris ada di `rationale.md` bagian References.

| Lapisan | Pilihan | Dikunci di | Alasan singkat |
|---|---|---|---|
| Rust | 1.99.1, edisi 2024, resolver 3 | `rust-toolchain.toml`, `Cargo.toml` (`edition`, `rust-version = "1.99"`) | Rilis titik berumur satu bulan; 1.100.0 baru berumur tiga hari |
| Target Rust | `aarch64-apple-ios`, `aarch64-apple-ios-sim`, `aarch64-linux-android`, `x86_64-linux-android` | `rust-toolchain.toml` (`targets`) | Sama dengan matriks dukungan |
| UniFFI | 0.32.2 | `Cargo.toml` (`[workspace.dependencies] uniffi = "=0.32.2"`), `Cargo.lock` | Stabil terbaru, rilis 2026-09-22; versi generator dan runtime harus sama persis |
| cargo-ndk | 4.1.2 | `docs/getting-started.md` (`cargo install cargo-ndk --version 4.1.2 --locked`), dicek skrip | Stabil terbaru; menyiapkan linker NDK untuk Cargo |
| Xcode dan Swift | Xcode 27.1 (Swift 6.4, SDK iOS 27.1), mode bahasa Swift 6 | `.xcode-version` berisi `27.1`, `SWIFT_VERSION = 6.0` di `Base.xcconfig` | Terpasang di mesin; butuh macOS 26.6 atau lebih baru di Mac Apple silicon |
| iPadOS minimum | 26.0 | `IPHONEOS_DEPLOYMENT_TARGET = 26.0` di `Base.xcconfig` | Lihat matriks dukungan |
| Android Gradle Plugin | 9.3.3 | `apps/android-tablet/gradle/libs.versions.toml` | Lini AGP terbaru yang masuk rentang uji Kotlin 2.4.21; mendukung API 37 |
| Gradle | 9.5.1 | `gradle/wrapper/gradle-wrapper.properties` (`distributionUrl`, `distributionSha256Sum`) | Versi bawaan AGP 9.3 (minimum 9.5.0) dan di dalam rentang Kotlin (sampai 9.7.0) |
| Kotlin | 2.4.21 (Kotlin bawaan AGP, plugin `org.jetbrains.kotlin.android` tidak dipakai) | `libs.versions.toml`, lewat `classpath` `kotlin-gradle-plugin` di build file akar | Stabil terbaru, rilis 2026-10-08 |
| Compose compiler | plugin `org.jetbrains.kotlin.plugin.compose` 2.4.21 | `libs.versions.toml` (`version.ref = "kotlin"`) | Versinya selalu sama dengan Kotlin |
| Compose | BOM 2026.09.00 (`material3` dari BOM), `activity-compose` 1.13.0 | `libs.versions.toml` | BOM stabil terbaru; Compose 1.12 mewajibkan `compileSdk` 37 dan AGP 9 |
| Material 3 adaptive | belum ditambahkan | tidak ada | Proyek minimal belum memerlukannya. Kandidat untuk fitur 06: 1.3.0 (stabil 2026-08-12) |
| Android SDK | `compileSdk` 37, `targetSdk` 36, `minSdk` 29 | `libs.versions.toml` | Lihat matriks dukungan |
| Build Tools | 36.0.0, bawaan AGP 9.3 | tidak diset (mengikuti AGP) | Sudah terpasang; menyetelnya sendiri menambah satu angka yang bisa basi |
| NDK | 28.2.13676358 (r28c) | `libs.versions.toml`, `android.ndkVersion`, dipakai skrip sebagai `ANDROID_NDK_HOME` | NDK bawaan AGP 9.3, sudah terpasang, selaras 16 KB secara bawaan |
| JDK | 25 untuk menjalankan Gradle; bytecode Java 17 | `gradle/gradle-daemon-jvm.properties` (`toolchainVersion=25`), `compileOptions` dan `jvmTarget` 17 | JBR 25.0.2 sudah ada di Android Studio; Gradle 9.5 berjalan di JVM 17 sampai 26; AGP minimal JDK 17 |

**Cadangan yang sudah disetujui**: bila build Gradle gagal karena JDK 25, pakai JDK 21 (`brew install openjdk@21`, `JAVA_HOME` menunjuk JDK itu). Yang ikut berubah: `toolchainVersion=21`, pemeriksaan versi di `build-android-tablet.sh`, `docs/getting-started.md`, dan baris JDK pada `support-matrix.md`. Catat di laporan. Untuk kegagalan kompatibilitas lain, berhenti dan lapor `needs-decision` dengan log; jangan mengganti versi sendiri.

## Matriks dukungan

| Target | Triple Rust atau ABI | OS | Alasan | Bukti di fitur 01 | Bukti lanjutan |
|---|---|---|---|---|---|
| iPad simulator | `aarch64-apple-ios-sim` | iPadOS 26.0 ke atas (runtime 26.5, 27.0, 27.1 terpasang) | Xcode 27 hanya berjalan di Mac Apple silicon, jadi simulator selalu arm64 | Build (AC-3, AC-5) | Peluncuran lokal dan di CI: fitur 04 |
| iPad perangkat | `aarch64-apple-ios` | iPadOS 26.0 ke atas | Semua iPad yang menjalankan iPadOS 26 adalah arm64 | Build Release tanpa tanda tangan (AC-3, AC-6) | Tautan Release: fitur 11. Perangkat fisik: MAN-1 |
| Emulator Android di host arm64 | `arm64-v8a` (`aarch64-linux-android`) | API 29 sampai 37; image `google_apis` API 36 terpasang | Emulator di Mac Apple silicon memakai image arm64 | Build pustaka dan APK (AC-3, AC-7) | Peluncuran lokal: fitur 04 |
| Emulator Android di host x86_64 | `x86_64` (`x86_64-linux-android`) | API 29 sampai 37 | Emulator Android di CI berjalan di runner Linux x86_64, bukan di runner macOS Apple silicon | Build pustaka (AC-3) | Peluncuran di CI: fitur 04 |
| Tablet Android | `arm64-v8a` | Android 10 (API 29) ke atas | Tablet yang masih dijual memakai arm64 | Build (AC-3, AC-7) | Perangkat fisik: MAN-2 |
| Halaman memori 16 KB | `arm64-v8a`, `x86_64` | Android 15 ke atas | **Termasuk.** Google Play menolak pembaruan yang tidak mendukung 16 KB mulai 1 Februari 2027 | Keselarasan ELF (AC-4) | `zipalign` dan emulator 16 KB: fitur 11. Perangkat fisik: MAN-3 |

**Tidak didukung, dengan alasan**:

- `x86_64-apple-ios` (simulator di Mac Intel): Xcode 27 tidak berjalan di Mac Intel, tetapi SDK simulatornya masih mendaftarkan `x86_64`. `Base.xcconfig` memuat `ARCHS[sdk=iphonesimulator*] = arm64` supaya build simulator generik tidak meminta irisan yang tidak ada di matriks.
- `armeabi-v7a` dan `x86` (Android 32 bit): menambah dua build dan dua jalur uji untuk perangkat lama yang bukan sasaran produk produktivitas ini. `abiFilters` membatasi APK ke dua ABI matriks, sehingga APK tidak terpasang di perangkat 32 bit. Bisa ditambahkan kelak tanpa mengubah kontrak.
- Mac Catalyst, "Designed for iPad" di Mac, visionOS, ponsel: di luar lingkup README bagian 24. Proyek iPad memuat `TARGETED_DEVICE_FAMILY = 2`.

**Alasan OS minimum**:

- **iPadOS 26.0**: Xcode 27.1 hanya menyediakan simulator dan debug perangkat untuk iOS 17 ke atas, jadi pilihan nyata adalah 17, 18, 26, atau 27. iPadOS 26 membawa sistem jendela yang bisa diubah ukurannya, yang menjadi dasar fitur 05 dan 07. Runtime terdekat yang terpasang adalah 26.5, jadi OS minimum bisa diuji mendekati batasnya di mesin ini. Per 7 Juni 2026, 68% semua iPad sudah memakai iPadOS 26 (data Apple).
- **Android `minSdk` 29**: Android 10 adalah versi pertama dengan tema gelap sistem dan navigasi gestur, dua hal yang diminta README (AC 21 dan bagian 10.2) tanpa jalur kompatibilitas tambahan. Pustaka AndroidX kini memakai `minSdk` bawaan 24, dan versi UniFFI berikutnya meminta minimal API 28 untuk binding Kotlin bawaan. API 29 ke atas mencakup 96,6% perangkat (apilevels.com, data Oktober 2026).
- **`targetSdk` 36 dengan `compileSdk` 37**: Compose 1.12 mewajibkan `compileSdk` 37. Google Play mewajibkan target API 36 sejak 31 Agustus 2026. Target 36 dipilih karena satu satunya image emulator yang terpasang adalah API 36, sehingga perilaku yang dijanjikan bisa diuji di sini. Menaikkan ke 37 tercatat di Follow-up.

Belum ada fitur yang meluncurkan aplikasi pada OS minimum (runtime iOS 26.5, emulator API 29). Itu tercatat di Follow-up untuk fitur 11.

## Struktur repo fitur 01

Hanya path berikut yang dibuat. Folder lain pada README bagian 5 dibuat oleh fitur pemiliknya. Path tes (`scripts/test.sh`, `tests/`, `test-preferences.json`) dibuat tester pada milestone 5; isinya ditetapkan di "Rancangan tes fitur 01".

```
Cargo.toml                         workspace: members, [workspace.package], [workspace.dependencies]
Cargo.lock                         di-commit
rust-toolchain.toml                channel 1.99.1, profile minimal, rustfmt, clippy, empat target
.xcode-version                     27.1
.gitignore                         lihat "Aturan commit"
crates/core/                       paket tablet-core (lib): Cargo.toml, src/lib.rs
crates/tablet-ffi/                 paket tablet-ffi (lib, staticlib, cdylib): Cargo.toml, src/lib.rs
apps/ipados/
  Tablet.xcodeproj/                project.pbxproj, xcshareddata/xcschemes/Tablet.xcscheme
  Config/Base.xcconfig             semua build setting
  Tablet/App/TabletApp.swift       @main, WindowGroup, satu Text statis
apps/android-tablet/
  settings.gradle.kts, build.gradle.kts, gradle.properties
  gradle/libs.versions.toml
  gradle/gradle-daemon-jvm.properties
  gradle/wrapper/gradle-wrapper.jar, gradle-wrapper.properties
  gradlew, gradlew.bat
  app/build.gradle.kts
  app/src/main/AndroidManifest.xml
  app/src/main/kotlin/foundation/tablet/MainActivity.kt
  app/src/main/res/values/strings.xml
scripts/build-ipados.sh            mode 100755
scripts/build-android-tablet.sh    mode 100755
scripts/test.sh                    mode 100755, menjalankan tes tingkat repo
tests/lib/harness.sh               helper tes: asersi, sandbox, alat tiruan
tests/repo/                        crate-boundary.test.sh, version-locks.test.sh, commit-policy.test.sh
tests/build-scripts/               build-ipados.test.sh, build-android-tablet.test.sh
tests/artifacts/                   ipados.test.sh, android-tablet.test.sh
test-preferences.json              pilihan alat untuk skill /test, di-commit
docs/getting-started.md
docs/architecture/overview.md
docs/architecture/support-matrix.md
docs/architecture/ownership-matrix.md
docs/architecture/dependency-rules.md
docs/architecture/repository-structure.md
```

### Workspace Rust

- `Cargo.toml` akar: `resolver = "3"`, `members = ["crates/core", "crates/tablet-ffi"]`. `[workspace.package]`: `version = "0.1.0"`, `edition = "2024"`, `rust-version = "1.99"`, `publish = false`. Tanpa field `license` (nilai dari user). `[workspace.dependencies]`: `tablet-core = { path = "crates/core" }`, `uniffi = "=0.32.2"`.
- `crates/core`: nama paket `tablet-core` (nama `core` bentrok dengan crate `core` bawaan Rust). Tanpa dependensi. `src/lib.rs` hanya berisi komentar dokumentasi crate yang menyebut tanggung jawabnya. Fungsi `hello` ditambahkan fitur 03.
- `crates/tablet-ffi`: `[lib] crate-type = ["lib", "staticlib", "cdylib"]`, dependensi `tablet-core.workspace = true` dan `uniffi.workspace = true`. `src/lib.rs` berisi komentar dokumentasi dan `uniffi::setup_scaffolding!();` tanpa ekspor. Bentuk ini sudah dicoba terkompilasi di host dengan Rust 1.99.1 dan UniFFI 0.32.2 pada 2026-11-15. Ekspor ditambahkan fitur 03.
- Tidak ada pengaturan `[profile.*]`, lint workspace, atau binary `uniffi-bindgen` di fitur 01.
- Tidak ada tes Rust (`#[test]`, folder `tests/` di dalam crate, atau dev-dependency) di fitur 01. Tes Rust pertama milik fitur 03. Tes fitur 01 ada di `tests/` akar repo dan tidak menjadi bagian workspace Cargo.

### Proyek iPad

- `Tablet.xcodeproj` di-commit, ditulis langsung (tanpa XcodeGen): `objectVersion = 77`, satu target aplikasi `Tablet`, satu grup tersinkron dengan sistem file (`PBXFileSystemSynchronizedRootGroup`) yang menunjuk folder `Tablet/`, sehingga menambah file Swift kelak tidak mengubah `project.pbxproj`.
- Objek yang harus ada di `project.pbxproj`: satu `PBXProject`, satu `PBXNativeTarget`, dua `XCConfigurationList` (proyek dan target), empat `XCBuildConfiguration` (Debug dan Release untuk masing masing), satu `PBXFileReference` untuk `Config/Base.xcconfig` di grup utama, tiga fase build (Sources, Frameworks, Resources), dan referensi produk `Tablet.app`.
- Kedua konfigurasi tingkat proyek memakai `Config/Base.xcconfig` lewat `baseConfigurationReference`. Blok `buildSettings` di `project.pbxproj` kosong di tingkat proyek dan target; semua nilai ada di xcconfig.
- Skema bersama `Tablet` di-commit (`BuildableName = "Tablet.app"`, `BlueprintIdentifier` sama dengan ID target) supaya `xcodebuild -scheme Tablet` bekerja pada clone bersih.
- Periksa sendiri sebelum build pertama: `plutil -lint apps/ipados/Tablet.xcodeproj/project.pbxproj` dan `xcodebuild -list -project apps/ipados/Tablet.xcodeproj` menampilkan target dan skema `Tablet`.
- `Config/Base.xcconfig` memuat tepat nilai ini:

```
SDKROOT = iphoneos
IPHONEOS_DEPLOYMENT_TARGET = 26.0
TARGETED_DEVICE_FAMILY = 2
SUPPORTED_PLATFORMS = iphoneos iphonesimulator
SUPPORTS_MACCATALYST = NO
SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO
SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO
ALWAYS_SEARCH_USER_PATHS = NO
ARCHS[sdk=iphonesimulator*] = arm64
SWIFT_VERSION = 6.0
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
SWIFT_APPROACHABLE_CONCURRENCY = YES
CODE_SIGN_STYLE = Automatic
PRODUCT_NAME = Tablet
PRODUCT_BUNDLE_IDENTIFIER = com.example.tablet
MARKETING_VERSION = 0.1.0
CURRENT_PROJECT_VERSION = 1
GENERATE_INFOPLIST_FILE = YES
INFOPLIST_KEY_CFBundleDisplayName = Tablet
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES
INFOPLIST_KEY_UILaunchScreen_Generation = YES
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
#include? "Local.xcconfig"
```

- `ALWAYS_SEARCH_USER_PATHS = NO` ada karena blok `buildSettings` di `project.pbxproj` kosong, sehingga nilai bawaan Xcode (`YES`) berlaku dan Xcode 27.1 mencetak peringatan "Traditional headermap style is no longer supported" pada tiap build. Nilai `NO` sama dengan yang ditulis templat proyek Xcode, dan target ini tidak punya header C, jadi hasil build tidak berubah (K29 di `rationale.md`).
- `SWIFT_DEFAULT_ACTOR_ISOLATION` dan `SWIFT_APPROACHABLE_CONCURRENCY` mengikuti bawaan templat Xcode untuk aplikasi; nilainya hanya berlaku untuk target aplikasi, bukan untuk modul binding.
- `Config/Local.xcconfig` tidak di-commit. Isinya nilai milik user (`DEVELOPMENT_TEAM`, dan `PRODUCT_BUNDLE_IDENTIFIER` asli bila sudah ada). File itu tidak boleh menimpa `IPHONEOS_DEPLOYMENT_TARGET`.
- Tidak ada asset catalog, target tes, atau paket Swift di fitur 01. Tes fitur 01 ada di `tests/` akar repo, di luar proyek Xcode; target tes native milik fitur 04.

### Proyek Android

- Akar Gradle adalah `apps/android-tablet/`, satu modul `:app`, semua build file memakai Kotlin DSL.
- `settings.gradle.kts`:

```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode = RepositoriesMode.FAIL_ON_PROJECT_REPOS
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "android-tablet"
include(":app")
```

- `build.gradle.kts` akar:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Mengunci Kotlin bawaan AGP ke versi katalog.
        classpath(libs.kotlin.gradle.plugin)
    }
}
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.compose.compiler) apply false
}
```

  Bila aksesor `libs` tidak tersedia di blok `buildscript`, tulis koordinatnya dengan versi literal `2.4.21` dan komentar "harus sama dengan `kotlin` di katalog", lalu catat di laporan.
- `gradle/libs.versions.toml`, bagian `[versions]`: `agp = "9.3.3"`, `kotlin = "2.4.21"`, `composeBom = "2026.09.00"`, `activityCompose = "1.13.0"`, `compileSdk = "37"`, `minSdk = "29"`, `targetSdk = "36"`, `ndk = "28.2.13676358"`. `[libraries]`: `kotlin-gradle-plugin`, `androidx-compose-bom`, `androidx-compose-material3` (tanpa versi, dari BOM), `androidx-activity-compose`. `[plugins]`: `android-application`, `compose-compiler`. Build file membaca semua angka dari katalog ini.
- `gradle.properties` memuat tepat ini:

```properties
tablet.applicationId=com.example.tablet
tablet.abis=arm64-v8a,x86_64
android.useAndroidX=true
android.builder.sdkDownload=false
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
```

  `android.builder.sdkDownload=false` membuat build gagal dengan jelas bila komponen SDK tidak ada, bukan mengunduh diam diam. Bila AGP 9.3.3 menolak properti itu, hapus dan catat di laporan.
- `app/build.gradle.kts`: plugin `android-application` dan `compose-compiler`; `namespace = "foundation.tablet"`; `compileSdk = 37` dibaca dari katalog (bila AGP tidak menemukan platform `android-37.0` dengan bentuk itu, pakai `compileSdk { version = release(37) }` dan catat); `minSdk`, `targetSdk`, `ndkVersion` dari katalog; `applicationId` dari `tablet.applicationId`; `versionCode = 1`; `versionName = "0.1.0"`; `ndk { abiFilters += <isi tablet.abis> }`; `buildFeatures { compose = true }`; `compileOptions` Java 17 dan `kotlin { compilerOptions { jvmTarget = JVM_17 } }`. Dependensi hanya BOM Compose, `material3`, dan `activity-compose`.
- `MainActivity` turunan `ComponentActivity`: `enableEdgeToEdge()`, lalu `setContent` dengan `MaterialTheme` dan satu `Text` statis. Manifest: satu activity `exported` dengan filter LAUNCHER, tema `@android:style/Theme.Material.Light.NoActionBar`, tanpa `screenOrientation`, tanpa `resizeableActivity`. `strings.xml` hanya berisi `app_name` bernilai `Tablet`.
- Wrapper: `distributionUrl` menunjuk `gradle-9.5.1-bin.zip`, `distributionSha256Sum=bafc141b619ad6350fd975fc903156dd5c151998cc8b058e8c1044ab5f7b031f`. Cara membuatnya tanpa memasang Gradle: unduh `gradle-9.5.1-bin.zip` ke folder sementara, cocokkan SHA-256 dengan halaman checksum Gradle (bila berbeda dari nilai di atas, berhenti dan lapor), ekstrak, lalu di folder kosong jalankan `JAVA_HOME=<JBR> <dist>/bin/gradle wrapper --gradle-version 9.5.1 --distribution-type bin --gradle-distribution-sha256-sum <nilai>` dan salin `gradlew`, `gradlew.bat`, dan `gradle/wrapper/` ke `apps/android-tablet/`. Cocokkan juga SHA-256 `gradle-wrapper.jar` dengan checksum wrapper yang diterbitkan Gradle. `gradlew` di-commit dengan mode `100755`.
- `gradle/gradle-daemon-jvm.properties` berisi `toolchainVersion=25`. Tidak ada plugin unduh JDK otomatis. Kriteria ini hanya terpenuhi bila `JAVA_HOME` menunjuk JDK 25, karena JBR di dalam Android Studio bukan lokasi yang dicari Gradle sendiri; skrip mengekspor `JAVA_HOME`, dan CI serta IDE harus menyetelnya juga.
- Tidak ada modul lain, `jniLibs`, dependensi JNA, tes di dalam proyek Gradle (`app/src/test`, `app/src/androidTest`), atau lint khusus di fitur 01. Tes fitur 01 ada di `tests/` akar repo; tes aplikasi milik fitur 04.

### Sumber nilai

Setiap nilai punya satu sumber. Pemakai lain membacanya, tidak menyalinnya.

| Nilai | Sumber tunggal | Dibaca oleh |
|---|---|---|
| iPadOS minimum | `apps/ipados/Config/Base.xcconfig` | Xcode; `build-ipados.sh` mengekspornya sebagai `IPHONEOS_DEPLOYMENT_TARGET` untuk Cargo. Salinan kedua yang dinyatakan: `platforms` di `bindings/swift/Package.swift` (fitur 04), harus sama |
| Bundle ID iPad | `Base.xcconfig`, ditimpa `Local.xcconfig` | Xcode |
| `minSdk`, `targetSdk`, `compileSdk`, NDK | `apps/android-tablet/gradle/libs.versions.toml` | Gradle; `build-android-tablet.sh` membaca `minSdk` untuk `CARGO_NDK_PLATFORM` dan `ndk` untuk `ANDROID_NDK_HOME` |
| ABI Android | `apps/android-tablet/gradle.properties` (`tablet.abis`) | Gradle (`abiFilters`); `build-android-tablet.sh` (argumen `-t` cargo-ndk) |
| `applicationId` Android | `apps/android-tablet/gradle.properties` (`tablet.applicationId`) | Gradle |
| Versi Rust dan target | `rust-toolchain.toml` | rustup, Cargo, kedua skrip |
| Versi UniFFI | `Cargo.toml` akar | `tablet-ffi`; generator binding fitur 03 |
| Versi Xcode yang diverifikasi | `.xcode-version` | `build-ipados.sh` |
| Nama pustaka | `tablet_ffi` (dari nama paket `tablet-ffi`) | Skrip, XCFramework dan `jniLibs` fitur 04 |
| Nama modul binding | Bagian "Pengemasan pustaka Rust" spec ini; ditulis ke `uniffi.toml` oleh fitur 03 | Generator binding, `Package.swift`, kode aplikasi |
| Daftar biner yang boleh di-commit | `tests/repo/commit-policy.test.sh` (satu daftar izin) | Kasus C2 pada suite tes |
| Pilihan alat tes | `test-preferences.json` di akar repo | Skill `/test` di setiap fitur |

Skrip membaca nilai dengan pola baris: `^IPHONEOS_DEPLOYMENT_TARGET *= *` di xcconfig, `^minSdk *= *"` dan `^ndk *= *"` di katalog, `^tablet.abis=` di `gradle.properties`.

## Perintah repo

Prasyarat yang harus disebut `docs/getting-started.md`:

- Mac Apple silicon dengan macOS 26.6 atau lebih baru, dan Xcode 27.1 terpilih lewat `xcode-select` (27.x yang lebih baru boleh, skrip memberi peringatan).
- `rustup` (toolchain dan target dipasang dari `rust-toolchain.toml`).
- Android SDK dengan `platforms;android-37.0`, `build-tools;36.0.0`, `platform-tools`, dan `ndk;28.2.13676358`. `ANDROID_HOME` menunjuk SDK itu; bila tidak diset, skrip mencoba `~/Library/Android/sdk`.
- JDK 25. Bila `JAVA_HOME` tidak diset, skrip mencoba JBR di `/Applications/Android Studio.app/Contents/jbr/Contents/Home`.
- `cargo-ndk` 4.1.2.

Perintah dari akar clone bersih, dalam urutan ini:

```bash
rustup toolchain install
cargo install cargo-ndk --version 4.1.2 --locked
cargo build --workspace --locked
cargo test --workspace --locked
scripts/build-ipados.sh
scripts/build-android-tablet.sh
```

Perintah tes tingkat repo (`scripts/test.sh`) bukan bagian dari enam perintah ini; kontraknya ada di "Rancangan tes fitur 01".

Aturan untuk kedua skrip build: `set -euo pipefail`; pindah ke akar repo lebih dulu sehingga bisa dipanggil dari folder mana pun; di dalam repo hanya menulis ke `target/`, `apps/ipados/build/`, dan folder `build/`, `.gradle/`, serta `.kotlin/` milik Gradle; di-commit dengan mode `100755`. Di fitur 01 skrip belum menyalin pustaka Rust ke proyek native.

**Kontrak `scripts/build-ipados.sh [--simulator] [--device]`** (tanpa argumen: keduanya):

1. Periksa prasyarat dan berhenti dengan pesan perbaikan bila gagal: `cargo` ada; `xcode-select -p` bukan Command Line Tools; `xcodebuild -version` adalah Xcode 27 (peringatan saja bila bukan versi di `.xcode-version`); target Rust yang diminta ada di `rustup target list --installed` (pesan menyebut `rustup target add <triple>`).
2. Baca `IPHONEOS_DEPLOYMENT_TARGET` dari `Base.xcconfig` lalu ekspor.
3. `cargo build -p tablet-ffi --release --locked --target <triple>` untuk `aarch64-apple-ios-sim` (simulator) dan `aarch64-apple-ios` (perangkat).
4. Simulator: `xcodebuild -project apps/ipados/Tablet.xcodeproj -scheme Tablet -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath apps/ipados/build/DerivedData build`.
5. Perangkat: perintah yang sama dengan `-configuration Release -destination 'generic/platform=iOS'` dan `CODE_SIGNING_ALLOWED=NO`.

**Kontrak `scripts/build-android-tablet.sh`**:

1. Tetapkan dan ekspor `ANDROID_HOME`, `ANDROID_NDK_HOME` (`$ANDROID_HOME/ndk/<ndk katalog>`), dan `JAVA_HOME`. Berhenti dengan pesan perbaikan bila: folder SDK, `platforms/android-37.0`, atau folder NDK tidak ada; `"$JAVA_HOME/bin/java" -version` tidak memuat `version "25.` (jangan memanggil `java` dari PATH, di macOS itu bisa berupa stub); `cargo ndk --version` bukan 4.1.2; target Rust Android tidak terpasang.
2. `CARGO_NDK_PLATFORM=<minSdk katalog> cargo ndk -t <tiap ABI di tablet.abis> build -p tablet-ffi --release --locked`.
3. `./gradlew :app:assembleDebug` dari `apps/android-tablet`.

## Pengemasan pustaka Rust (ditetapkan di sini, dibangun fitur 03 dan 04)

**Nama yang dipakai semua pihak** (fitur 03 menuliskannya ke `uniffi.toml`):

| Hal | Nama |
|---|---|
| Pustaka | `libtablet_ffi.a`, `libtablet_ffi.so` |
| Modul FFI C untuk Swift | `TabletFFI` (header `TabletFFI.h`) |
| Modul Swift dan produk paket | `TabletBindings` |
| Paket Kotlin hasil generasi | `foundation.tablet.bindings` |
| XCFramework | `bindings/swift/TabletFFI.xcframework` |

**Urutan di kedua skrip build** (fitur 04 menambahkannya ke skrip fitur 01):

1. Hapus keluaran lama: `bindings/swift/TabletFFI.xcframework`, `bindings/swift/Sources/`, `bindings/kotlin/`, `apps/android-tablet/app/src/main/jniLibs/`.
2. Bangun `tablet-ffi` untuk target platform itu.
3. Panggil `scripts/generate-bindings.sh` (milik fitur 03), yang menghasilkan binding dari pustaka yang baru dibangun.
4. Kemas, lalu jalankan `xcodebuild` atau Gradle.

**iPad**:

- Header dan modulemap hasil generasi disusun di folder sementara sebagai `<tmp>/TabletFFI/TabletFFI.h` dan `<tmp>/TabletFFI/module.modulemap`.
- `xcodebuild -create-xcframework -library target/aarch64-apple-ios/release/libtablet_ffi.a -headers <tmp> -library target/aarch64-apple-ios-sim/release/libtablet_ffi.a -headers <tmp> -output bindings/swift/TabletFFI.xcframework`.
- `bindings/swift/Package.swift` (di-commit): `platforms: [.iOS("26.0")]`; `binaryTarget(name: "TabletFFI", path: "TabletFFI.xcframework")`; target `TabletBindings` di `Sources/TabletBindings` yang bergantung pada `TabletFFI`; produk pustaka `TabletBindings`. Sumber Swift hasil generasi ditaruh di `bindings/swift/Sources/TabletBindings/`.
- Proyek Xcode menambahkan `../../bindings/swift` sebagai paket lokal dan target `Tablet` menautkan produk `TabletBindings`.

**Android**:

- `cargo ndk -o apps/android-tablet/app/src/main/jniLibs ...` menaruh `libtablet_ffi.so` per ABI di lokasi bawaan AGP.
- Sumber Kotlin hasil generasi ada di `bindings/kotlin/` dan ditambahkan ke modul `:app` sebagai folder sumber Kotlin (`rootDir.resolve("../../bindings/kotlin")`). Tetap satu modul `:app`, tanpa AAR.
- JNA (`net.java.dev.jna:jna`, bentuk `@aar`, minimal 5.12.0; versi persis ditetapkan fitur 03) ditambahkan saat binding pertama dipakai. `abiFilters` dari fitur 01 mencegah pustaka JNA 32 bit ikut terkemas.

**Aturan umum**:

- Proyek Xcode dan Gradle tidak pernah memanggil Cargo. Sesudah mengubah Rust, kontributor menjalankan skrip lagi sebelum membangun dari IDE.
- Generator binding berjalan dari workspace dengan versi UniFFI yang sama dengan runtime (bukan `cargo install uniffi-bindgen`). Fitur 03 boleh menambah satu crate tooling ke workspace untuk itu (kandidat lokasi: `tooling/uniffi-bindgen`), supaya dependensi baris perintah tidak ikut ke build mobile.
- Bila `IPHONEOS_DEPLOYMENT_TARGET` berubah, jalankan `cargo clean` untuk kedua target Apple sebelum membangun lagi.

### Aturan commit

- Tidak pernah di-commit: `target/`, `apps/ipados/build/`, `xcuserdata/`, `apps/ipados/Tablet.xcodeproj/project.xcworkspace/`, `apps/ipados/Config/Local.xcconfig`, `.build/`, `.swiftpm/`, `apps/android-tablet/**/build/`, `apps/android-tablet/.gradle/`, `apps/android-tablet/.kotlin/`, `apps/android-tablet/local.properties`, `apps/android-tablet/app/.cxx/`, `apps/android-tablet/captures/`, `apps/android-tablet/app/src/main/jniLibs/`, `bindings/swift/TabletFFI.xcframework/`, `bindings/swift/Sources/`, `bindings/kotlin/`, `.DS_Store`, `.idea/`, `*.iml`. `.gitignore` akar memuat semuanya sejak milestone 1 supaya milestone lain tidak perlu menyentuhnya.
- Di-commit: `Cargo.lock`, `Tablet.xcodeproj` beserta skema bersama, wrapper Gradle termasuk `gradle-wrapper.jar`, dan kelak `bindings/swift/Package.swift`.

## Rancangan tes fitur 01

Kotak `Test it` fitur 01 ditutup oleh satu suite bash kecil di `tests/`, dijalankan lewat `scripts/test.sh`. Suite ini mengunci hal yang tetap benar sesudah fitur berikutnya masuk, bukan potret fitur 01. Tester yang membangunnya pada milestone 5, dan kode produksi tidak berubah. ID dan teks AC-1 sampai AC-11 tidak berubah.

### Yang dikunci dan yang tidak

| Hal | Dikunci suite fitur 01 | Catatan |
|---|---|---|
| Batas crate (AC-2) | Ya, dalam bentuk yang tahan lama | `tablet-core` tidak pernah menarik `uniffi`, hanya `tablet-ffi` di `crates/` yang memuat `uniffi`, dan `tablet-ffi` tetap `staticlib` serta `cdylib` |
| Kunci versi dan satu sumber nilai (AC-8) | Ya, tanpa menyalin angka versi ke tes | Tes membaca nilai dari sumbernya, lalu memeriksa bentuk kunci, pemakai, dan dokumen |
| Aturan commit (AC-9 bagian mode, AC-11) | Ya | Tanpa hasil build, biner hanya dari daftar izin, `.gitignore` lengkap, mode `100755`, tanpa file penanda |
| Prasyarat hilang dan bentuk perintah kedua skrip (AC-8; AC-3, AC-5, AC-6, AC-7 pada sisi perintah) | Ya, di sandbox dengan alat tiruan | Satu satunya logika bercabang di fitur 01 |
| Hasil build (AC-3 sampai AC-7, AC-11 bagian pohon kerja bersih) | Ya, pada grup `artifacts` yang hanya membaca | Butuh kedua skrip build dijalankan lebih dulu |
| "Tepat dua crate" dan "`tablet-core` tanpa dependensi sama sekali" (AC-2) | Tidak | Potret fitur 01. K24 dan fitur 03 mengubahnya dengan sengaja. Tetap bukti verify |
| Aplikasi minimal dan belum menautkan Rust (AC-11) | Tidak | Potret fitur 01. Fitur 04 membaliknya dengan sengaja |
| Tes Rust (`#[test]`) | Tidak | Milik fitur 03. `cargo test` tetap lulus dengan nol tes |
| Target tes native dan peluncuran aplikasi | Tidak | Milik fitur 04 |
| Aturan arah dependensi umum, contoh pelanggaran, hasil generasi yang menyimpang, keberadaan dokumen wajib | Tidak | Milik fitur 10 (`scripts/validate-architecture.sh`) |
| CI, `zipalign`, emulator 16 KB, pustaka Rust di APK akhir, tautan Release iPad | Tidak | Milik fitur 11, yang memanggil suite ini |
| Pengulangan clone bersih (AC-9), isi dokumen (AC-10), isi log build | Tidak | Tetap bukti verify; pengulangan otomatis milik fitur 11 |

### Alat dan aturan suite

- **Alat**: bash polos, tanpa framework dan tanpa alat baru. File tes dan helper harus berjalan di bash 3.2 (bash bawaan macOS di `/bin/bash`), jadi tanpa array asosiatif, `mapfile`, `readarray`, `${var,,}`, `${var^^}`, dan `&>>`.
- **Alat yang boleh dipanggil tes**: `git` dan alat dasar sistem (`sed`, `awk`, `grep`, `sort`, `head`, `tr`, `cp`, `mkdir`, `mktemp`, `chmod`, `find`, `wc`). Hanya kasus V2 yang memanggil `rustc`. Grup `artifacts` juga memakai `lipo`, `plutil`, `codesign`, `unzip`, serta `llvm-objdump` dan `aapt2` dari Android SDK. Tidak boleh memakai `jq`, Python, atau jaringan.
- **Hanya bentuk perintah yang sama di macOS dan Linux**: tanpa `sed -i`, `stat`, dan `find -printf`. Berkas sandbox diubah dengan `sed` ke berkas sementara lalu `mv`. Ukuran berkas diperiksa dengan `test -s`. Path sementara dibandingkan sesudah dinormalkan dengan `pwd -P`, karena `mktemp` di macOS berada di balik tautan `/var` ke `/private/var`.
- **Tidak pernah membangun**: suite tidak memanggil `cargo build`, `cargo test`, `cargo ndk`, `xcodebuild`, atau `gradlew` yang asli. Pintu build tetap kedua skrip build.
- **Tidak menulis ke dalam repo**: semua file sementara dibuat di folder `mktemp -d` di luar repo dan dihapus lewat `trap` saat file tes selesai. Karena itu `.gitignore` tidak berubah.
- **Nilai dibaca dari sumbernya**: tes tidak menyalin angka versi. Nilai harapan dibaca dari file pada tabel "Sumber nilai" dengan pola baris yang sama seperti skrip. Pengecualian yang dinyatakan: janji matriks pada kasus V9 dan daftar path pada kasus C2 dan C3.
- **Pesan diperiksa lewat token**: kasus prasyarat memeriksa kode keluar dan kata kunci (nama variabel, nama alat, perintah perbaikan), bukan kalimat utuh, supaya kata kata pesan boleh dirapikan.
- **Tanpa SKIP**: tidak ada kasus yang dilewati. Bila alat atau hasil build yang dibutuhkan tidak ada, kasus itu gagal dengan pesan yang menyebut cara memperbaikinya.
- **Format keluaran**: tiap baris tabel kasus menjadi tepat satu baris `ok <n> - <ID> <AC> <nama>` atau `not ok <n> - <ID> <AC> <nama>`, contoh `ok 3 - B3 AC-2 tablet-core tidak menarik uniffi`. Kasus dengan beberapa percobaan (misalnya I9, I10, A6, A10) tetap satu baris, dan baris `# ` menyebut percobaan yang gagal. Beberapa AC ditulis dengan koma tanpa spasi, contoh `AC-1,AC-8`. Kasus yang gagal disusul baris `# ` yang memuat nilai harapan dan nilai nyata. Baris terakhir file adalah `1..<jumlah kasus>`. File tes keluar `0` bila semua kasus `ok`, selain itu `1`.
- **Jejak ke AC**: ID kasus dan AC di nama kasus adalah jejak ke kontrak. Satu kasus boleh menyebut lebih dari satu AC.

### Perintah tes dan kontrak `scripts/test.sh`

```bash
scripts/test.sh                              # grup repo dan build-scripts: cepat, tanpa build, tanpa jaringan
scripts/test.sh artifacts                    # hasil build kedua platform; jalankan sesudah kedua skrip build
scripts/test.sh artifacts/ipados             # satu file tes
scripts/test.sh repo build-scripts artifacts # semuanya
```

1. `set -uo pipefail`; pindah ke akar repo lebih dulu sehingga bisa dipanggil dari folder mana pun; di-commit dengan mode `100755`.
2. Tanpa argumen: grup `repo` lalu `build-scripts`. Grup `artifacts` hanya berjalan bila disebut.
3. Tiap argumen adalah nama grup (folder di `tests/` selain `lib`) atau `<grup>/<nama>` untuk file `tests/<grup>/<nama>.test.sh`. Semua argumen diperiksa lebih dulu: bila ada satu saja yang tidak cocok, runner mencetak pemakaian ke stderr dan keluar `2` tanpa menjalankan tes apa pun. `-h` atau `--help`: cetak pemakaian dan keluar `0`.
4. Grup dijalankan menurut urutan argumen, file di dalam grup menurut urutan nama. File yang terpilih lebih dari sekali hanya dijalankan sekali, pada kemunculan pertamanya.
5. Tiap file tes dijalankan sebagai proses terpisah dengan `/bin/bash <file>` bila `/bin/bash` ada, selain itu dengan `bash <file>`. Di macOS `/bin/bash` adalah bash 3.2, jadi aturan bash 3.2 ikut terbukti tiap kali suite berjalan, juga di mesin yang punya bash lebih baru di `PATH`. Runner sendiri juga harus berjalan di bash 3.2. Stdout dan stderr file tes diteruskan apa adanya di bawah satu baris judul `# tests/<grup>/<nama>.test.sh`.
6. Baris terakhir: `test: <jumlah file> file, <lulus> lulus, <gagal> gagal`. Kode keluar `0` bila semua file lulus, `1` bila ada yang gagal.
7. Runner tidak menjalankan `cargo test`. Perintah tes Rust tetap `cargo test --workspace --locked` pada "Perintah repo" (AC-1). Fitur 03 memutuskan apakah runner mendapat grup untuk tes Rust.
8. Enam perintah pada "Perintah repo" tidak berubah. `docs/getting-started.md` mendapat bagian baru "Menjalankan tes" yang memuat empat perintah di atas (tugas 15).

Cara fitur 11 memanggilnya di CI: job pemeriksaan cepat menjalankan `scripts/test.sh`; job iPad (runner macOS) menjalankan `scripts/build-ipados.sh` lalu `scripts/test.sh artifacts/ipados`; job Android menjalankan `scripts/build-android-tablet.sh` lalu `scripts/test.sh artifacts/android-tablet`. Grup `repo` dan `build-scripts` dirancang berjalan di macOS dan Linux, tetapi di fitur 01 hanya dibuktikan di macOS.

### Helper `tests/lib/harness.sh`

Satu file yang di-`source` tiap file tes. Nama fungsinya bebas; yang wajib ada:

- Pencatat kasus yang mencetak baris `ok` atau `not ok` beserta baris `# `, menghitung nomor, mencetak `1..<n>`, dan menentukan kode keluar.
- Pembaca nilai dari sumber tunggal dengan pola baris pada bagian "Sumber nilai": `channel` dan `targets` di `rust-toolchain.toml`, pin `uniffi` di `Cargo.toml`, isi `.xcode-version`, `IPHONEOS_DEPLOYMENT_TARGET` di `Base.xcconfig`, tiap kunci `[versions]` di katalog, `tablet.abis` di `gradle.properties`, versi Gradle dari `distributionUrl`, `toolchainVersion`, dan versi cargo-ndk dari baris `cargo install cargo-ndk --version <v> --locked` di `docs/getting-started.md`.
- Pemetaan ABI ke triple Rust: `arm64-v8a` ke `aarch64-linux-android`, `x86_64` ke `x86_64-linux-android`.
- Pembuat sandbox dan alat tiruan (lihat "Grup `build-scripts`").

### Grup `repo`: keadaan repo yang di-commit

Membaca file terlacak dan indeks Git. Tanpa build, tanpa jaringan. Waktu yang diharapkan di mesin lead: beberapa detik.

**`tests/repo/crate-boundary.test.sh`**

| ID | AC | Yang ditegaskan |
|---|---|---|
| B1 | AC-1 | `git ls-files --error-unmatch Cargo.lock` keluar `0` |
| B2 | AC-2 | `members` di `Cargo.toml` akar memuat `crates/core` dan `crates/tablet-ffi`; nama paket di manifest masing masing adalah `tablet-core` dan `tablet-ffi` |
| B3 | AC-2 | Di `Cargo.lock`, tutup transitif dependensi paket `tablet-core` tidak memuat paket yang namanya diawali `uniffi`. Tes menelusuri blok `[[package]]` dan daftar `dependencies` tanpa memanggil Cargo. Entri berbentuk `"nama"`, `"nama versi"`, atau `"nama versi (sumber)"`; kata pertama adalah nama paket, dan bila satu nama punya beberapa versi, semua bloknya ikut ditelusuri. Kasus gagal bila blok `tablet-core` tidak ditemukan, supaya tidak lulus hanya karena pembacaan kosong. Ini lebih ketat daripada `cargo tree -e normal` karena lockfile juga memuat dependensi build dan dev |
| B4 | AC-2 | Di `Cargo.lock`, daftar `dependencies` paket `tablet-ffi` memuat `tablet-core` dan `uniffi` |
| B5 | AC-2 | Baris `crate-type` di `crates/tablet-ffi/Cargo.toml` memuat `"staticlib"` dan `"cdylib"` |
| B6 | AC-2 | Di antara `crates/*/Cargo.toml`, hanya `crates/tablet-ffi/Cargo.toml` yang memuat kata `uniffi` (aturan arah dependensi 2) |

**`tests/repo/version-locks.test.sh`**

| ID | AC | Yang ditegaskan |
|---|---|---|
| V1 | AC-8 | `channel` di `rust-toolchain.toml` berbentuk `X.Y.Z`. Daftar `targets` memuat `aarch64-apple-ios`, `aarch64-apple-ios-sim`, dan triple untuk tiap ABI di `tablet.abis` |
| V2 | AC-1, AC-8 | `rustc --version` dari akar repo diawali `rustc <channel>`. `rust-version` di `Cargo.toml` sama dengan `X.Y` dari `channel`. `rustc` dipanggil dengan `RUSTUP_AUTO_INSTALL=0` supaya rustup tidak mengunduh toolchain. Bila `rustc` atau toolchain itu tidak ada, kasus gagal dengan pesan `rustup toolchain install` |
| V3 | AC-2, AC-8 | Nilai `uniffi` di `[workspace.dependencies]` diawali `=`. `Cargo.lock` memuat tepat satu paket bernama `uniffi`, dan versinya sama dengan pin itu tanpa `=` |
| V4 | AC-8 | Di `gradle-wrapper.properties`, `distributionUrl` berakhir `gradle-<X.Y.Z>-bin.zip` dan `distributionSha256Sum` berisi tepat 64 karakter heksadesimal |
| V5 | AC-8 | Katalog `[versions]` memuat kunci `agp`, `kotlin`, `composeBom`, `activityCompose`, `compileSdk`, `minSdk`, `targetSdk`, `ndk`, dan nilai kedelapan kunci itu hanya berisi angka dan titik (kunci lain yang kelak ditambahkan tidak diperiksa). Baris `kotlin-gradle-plugin` dan `compose-compiler` memuat `version.ref = "kotlin"`. Baris `androidx-compose-material3` tidak memuat `version` |
| V6 | AC-8 | Di `app/build.gradle.kts`, tiap baris yang memuat `compileSdk`, `minSdk`, `targetSdk`, atau `ndkVersion` juga memuat `libs.versions.`; baris `applicationId` dan `abiFilters` memuat `gradleProperty("tablet.` |
| V7 | AC-8 | Di `project.pbxproj` ada minimal satu blok `buildSettings = {`, dan tiap blok langsung ditutup `};` pada baris berikutnya (semua nilai hanya di xcconfig) |
| V8 | AC-9, AC-10 | Dokumen mengikuti sumber. Nilai dicari sebagai token berlabel, bukan angka lepas, supaya angka pendek tidak cocok secara kebetulan. Di tabel "Versi alat" `docs/architecture/support-matrix.md`, baris yang sel pertamanya sama persis dengan label berikut memuat token ini: `Rust` memuat channel; `UniFFI` memuat pin tanpa `=`; `cargo-ndk` memuat `--version <versi cargo-ndk>`; `Xcode dan Swift` memuat `Xcode <isi .xcode-version>`; `iPadOS minimum` memuat `IPHONEOS_DEPLOYMENT_TARGET = <nilai>`; `Android Gradle Plugin` memuat `agp`; `Gradle` memuat versi wrapper; `Kotlin` memuat `kotlin`; `Compose` memuat `BOM <composeBom>` dan `` `activity-compose` <activityCompose> ``; `Android SDK` memuat `` `compileSdk` <nilai> ``, `` `targetSdk` <nilai> ``, dan `` `minSdk` <nilai> ``; `NDK` memuat `ndk`; `JDK` memuat `toolchainVersion=<nilai>`. Di tabel "Prasyarat" `docs/getting-started.md`: sel kedua baris `Xcode` diawali isi `.xcode-version`; baris `` `rustup` `` memuat `toolchain <channel>`; baris `Android SDK` memuat `platforms;android-<compileSdk>.0` dan `ndk;<ndk>`; sel kedua baris `JDK` sama persis dengan `toolchainVersion`; sel kedua baris `` `cargo-ndk` `` sama persis dengan versi cargo-ndk. Tiap label harus cocok dengan tepat satu baris; nol atau lebih dari satu baris berarti gagal |
| V9 | AC-5, AC-6, AC-7 | Janji matriks ada di konfigurasi: `Base.xcconfig` memuat baris `TARGETED_DEVICE_FAMILY = 2` dan `ARCHS[sdk=iphonesimulator*] = arm64`; tiap ABI di `tablet.abis` adalah `arm64-v8a` atau `x86_64` |

**`tests/repo/commit-policy.test.sh`**

| ID | AC | Yang ditegaskan |
|---|---|---|
| C1 | AC-11 | `git ls-files \| grep -E '\.(a\|so\|apk)$\|xcframework\|/build/\|^target/'` kosong |
| C2 | AC-11 | Himpunan file biner terlacak (baris yang diawali `i/-text` pada `git ls-files --eol`) sama persis dengan daftar izin di file tes ini. Daftar izin fitur 01 berisi satu path: `apps/android-tablet/gradle/wrapper/gradle-wrapper.jar`. Fitur yang kelak meng-commit biner yang sah (misalnya aset gambar) menambah path itu ke daftar izin di commit yang sama |
| C3 | AC-11 | `git check-ignore -v` mencetak aturan yang sumbernya `.gitignore` akar repo (keluaran diawali `.gitignore:`) untuk tiap path berikut. Aturan dari berkas abaikan global milik user atau dari `.git/info/exclude` tidak dihitung: `target/x`, `apps/ipados/build/x`, `a/xcuserdata/x`, `apps/ipados/Tablet.xcodeproj/project.xcworkspace/x`, `apps/ipados/Config/Local.xcconfig`, `.build/x`, `.swiftpm/x`, `apps/android-tablet/app/build/x`, `apps/android-tablet/build/x`, `apps/android-tablet/.gradle/x`, `apps/android-tablet/.kotlin/x`, `apps/android-tablet/local.properties`, `apps/android-tablet/app/.cxx/x`, `apps/android-tablet/captures/x`, `apps/android-tablet/app/src/main/jniLibs/x`, `bindings/swift/TabletFFI.xcframework/x`, `bindings/swift/Sources/x`, `bindings/kotlin/x`, `.DS_Store`, `.idea/x`, `a.iml` |
| C4 | AC-9 | Pada `git ls-files -s scripts apps/android-tablet/gradlew`, setiap baris bermode `100755` |
| C5 | AC-11 | Tidak ada file terlacak berukuran 0 byte (diperiksa dengan `test -s`), dan tidak ada file terlacak bernama `.gitkeep` atau `.keep` |

### Grup `build-scripts`: kontrak kedua skrip build di sandbox

Kedua skrip pindah ke `$(dirname "${BASH_SOURCE[0]}")/..`, jadi salinan skrip di folder lain memperlakukan folder itu sebagai akar repo. Tes memanfaatkannya: skrip dijalankan dari salinan di sandbox dengan alat tiruan, sehingga tidak ada build nyata, tidak butuh Xcode atau Android SDK, dan file sumber nilai bisa diubah di sandbox tanpa menyentuh repo.

**Sandbox** (folder `mktemp -d` baru untuk tiap kasus) berisi:

- `repo/scripts/build-ipados.sh` dan `repo/scripts/build-android-tablet.sh`, disalin dari repo dengan mode yang sama.
- `repo/.xcode-version`, `repo/apps/ipados/Config/Base.xcconfig`, `repo/apps/android-tablet/gradle/libs.versions.toml`, `repo/apps/android-tablet/gradle.properties`, disalin dari repo.
- `repo/apps/android-tablet/gradlew` tiruan (mode `755`).
- `bin/` berisi alat tiruan `cargo`, `rustup`, `xcode-select`, dan `xcodebuild`.
- `sdk/platforms/android-<compileSdk>.0/` dan `sdk/ndk/<ndk>/` (folder kosong, nama dari katalog) sebagai Android SDK tiruan.
- `jdk/bin/java` dan `jdk21/bin/java` tiruan, `xcode/Contents/Developer/` dan `CommandLineTools/` (folder kosong), `home/`, dan `calls.log`.

**Cara menjalankan**: `env -i PATH="<sandbox>/bin:/usr/bin:/bin" HOME="<sandbox>/home" STUB_LOG="<sandbox>/calls.log" <variabel STUB lain> <variabel kasus> <sandbox>/repo/scripts/<skrip> <argumen>`, dari folder kerja selain akar sandbox. Lingkungan dikosongkan supaya `ANDROID_HOME`, `JAVA_HOME`, dan `DEVELOPER_DIR` milik mesin tidak ikut. Skrip dijalankan lewat shebang-nya, jadi di macOS ia berjalan di bash 3.2 bawaan. Bila skrip gagal di sana karena hal lain selain yang diuji, itu temuan untuk developer, bukan alasan mengubah tes.

**Alat tiruan**. Tiap alat tiruan menambah satu baris ke berkas pada `STUB_LOG`: nama alat, folder kerja mutlak dari `pwd -P`, semua argumen, dan nilai `IPHONEOS_DEPLOYMENT_TARGET`, `CARGO_NDK_PLATFORM`, `ANDROID_HOME`, `ANDROID_NDK_HOME`, serta `JAVA_HOME` saat dipanggil. Alat tiruan tidak membaca berkas repo. Semua perilakunya diatur variabel `STUB_*` yang selalu diisi harness dan ikut diwariskan ke proses anak skrip. Perilaku bawaannya (jalur lulus) dan sakelarnya:

| Alat tiruan | Perilaku bawaan | Sakelar untuk kasus gagal |
|---|---|---|
| `cargo` | `cargo ndk --version` mencetak `cargo-ndk $STUB_CARGO_NDK_VERSION` (bawaan: versi cargo-ndk dari getting-started); panggilan lain hanya dicatat; keluar `0` | `STUB_CARGO_NDK_VERSION` berisi versi lain; nilai `none` membuat `cargo ndk --version` keluar `1`; untuk I6 berkas `bin/cargo` dihapus dari sandbox kasus itu |
| `rustup` | `rustup target list --installed` mencetak isi `STUB_RUST_TARGETS` (dipisah spasi), satu per baris (bawaan: keempat target dari `rust-toolchain.toml`) | Satu target dihilangkan dari `STUB_RUST_TARGETS` |
| `xcode-select` | `xcode-select -p` mencetak `STUB_DEVELOPER_DIR` (bawaan: `<sandbox>/xcode/Contents/Developer`) | `STUB_DEVELOPER_DIR=<sandbox>/CommandLineTools`, folder yang ada |
| `xcodebuild` | `xcodebuild -version` mencetak `Xcode $STUB_XCODE_VERSION` (bawaan: isi `.xcode-version`) lalu satu baris `Build version`; panggilan lain hanya dicatat; keluar `0` | `STUB_XCODE_VERSION=26.4`; `STUB_XCODE_VERSION=27.2` |
| `jdk/bin/java` | `-version` mencetak `openjdk version "$STUB_JAVA_VERSION"` ke stderr (bawaan: `<toolchainVersion>.0.2`) | `JAVA_HOME=<sandbox>/jdk21`, yang `java` tiruannya mencetak `openjdk version "21.0.5"` |
| `gradlew` | Hanya dicatat; keluar `0` | Tidak ada |

Nilai bawaan alat tiruan dibaca dari file sumber, bukan ditulis tetap. Dengan begitu jalur lulus sekaligus membuktikan bahwa angka di dalam skrip (`JDK 25`, `cargo-ndk 4.1.2`) sama dengan `gradle-daemon-jvm.properties` dan `docs/getting-started.md`.

Folder kerja pada log dibandingkan dengan path `repo/` sandbox sesudah `pwd -P`. Pada kasus gagal, "tanpa build" berarti `calls.log` tidak memuat baris `cargo build`, `cargo ndk` yang diikuti `build`, `xcodebuild` selain `-version`, atau `gradlew`.

**`tests/build-scripts/build-ipados.test.sh`**

| ID | AC | Keadaan | Yang ditegaskan |
|---|---|---|---|
| I1 | AC-8 | `DEVELOPER_DIR=/tidak/ada` | Keluar bukan `0`; stderr memuat `DEVELOPER_DIR` dan `unset DEVELOPER_DIR`; tanpa build |
| I2 | AC-8 | `STUB_DEVELOPER_DIR=<sandbox>/CommandLineTools` | Keluar bukan `0`; stderr memuat `Command Line Tools` dan `xcode-select -s`; tanpa build |
| I3 | AC-8 | `xcodebuild -version` melaporkan `Xcode 26.4` | Keluar bukan `0`; stderr memuat `Xcode 27` dan `26.4`; tanpa build |
| I4 | AC-8 | `xcodebuild -version` melaporkan `Xcode 27.2` | Keluar `0`; stderr memuat `peringatan`, isi `.xcode-version`, dan `27.2` |
| I5 | AC-8 | Target `aarch64-apple-ios-sim` tidak terpasang | Keluar bukan `0`; stderr memuat `rustup target add aarch64-apple-ios-sim`; tanpa build |
| I6 | AC-8 | `cargo` tidak ada di `PATH` | Keluar bukan `0`; stderr memuat `cargo` dan `rustup.rs`; tanpa build |
| I7 | AC-3, AC-5, AC-6 | Jalur lulus tanpa argumen | Keluar `0`. `calls.log` memuat, berurutan: `cargo build -p tablet-ffi --release --locked --target aarch64-apple-ios-sim`; perintah yang sama untuk `aarch64-apple-ios`; `xcodebuild` dengan `-project apps/ipados/Tablet.xcodeproj`, `-scheme Tablet`, `-configuration Debug`, `generic/platform=iOS Simulator`, `-derivedDataPath apps/ipados/build/DerivedData`, dan `build`; `xcodebuild` dengan `-configuration Release`, `generic/platform=iOS`, `CODE_SIGNING_ALLOWED=NO`, dan `build`. Semua panggilan memakai folder kerja akar `repo/`. Baris terakhir stdout `build-ipados: selesai` |
| I8 | AC-8 | Jalur lulus | Nilai `IPHONEOS_DEPLOYMENT_TARGET` yang dicatat pada kedua panggilan `cargo build` sama dengan nilai di `Base.xcconfig` sandbox. Sesudah baris itu di sandbox diubah menjadi `27.0`, nilai yang dicatat `27.0` |
| I9 | AC-5, AC-6 | `--simulator` saja, lalu `--device` saja | `--simulator`: hanya triple `aarch64-apple-ios-sim` dan `xcodebuild` Debug. `--device`: hanya triple `aarch64-apple-ios` dan `xcodebuild` Release dengan `CODE_SIGNING_ALLOWED=NO` |
| I10 | AC-8 | Argumen `--salah`, lalu `--help` | `--salah`: keluar bukan `0`, stderr memuat `--salah`, tanpa build. `--help`: keluar `0`, stdout memuat `--simulator` dan `--device`, `calls.log` kosong |
| I11 | AC-11 | Jalur lulus | Sesudah skrip selesai, daftar file di `repo/` sama dengan sebelum dijalankan (skrip sendiri tidak membuat file di dalam repo) |

**`tests/build-scripts/build-android-tablet.test.sh`**

Kecuali disebut lain, tiap kasus menyetel `ANDROID_HOME=<sandbox>/sdk` dan `JAVA_HOME=<sandbox>/jdk`.

| ID | AC | Keadaan | Yang ditegaskan |
|---|---|---|---|
| A1 | AC-8 | `ANDROID_HOME` menunjuk folder kosong | Keluar bukan `0`; stderr memuat `sdkmanager` dan `platforms;android-<compileSdk>.0`; tanpa build |
| A2 | AC-8 | `ANDROID_HOME=/tidak/ada` | Keluar bukan `0`; stderr memuat `ANDROID_HOME` dan `/tidak/ada`; tanpa build |
| A3 | AC-8 | Folder `ndk/<ndk>` dihapus dari SDK tiruan | Keluar bukan `0`; stderr memuat `ndk;<ndk>`; tanpa build |
| A4 | AC-8 | `JAVA_HOME=/tidak/ada` | Keluar bukan `0`; stderr memuat `JAVA_HOME` dan `JDK <toolchainVersion>`; tanpa build |
| A5 | AC-8 | `JAVA_HOME=<sandbox>/jdk21` | Keluar bukan `0`; stderr memuat `JDK <toolchainVersion>` dan `21`; tanpa build |
| A6 | AC-8 | cargo-ndk versi lain, lalu cargo-ndk tidak ada | Keduanya keluar bukan `0`; stderr memuat `cargo install cargo-ndk --version <versi cargo-ndk> --locked`; tanpa build |
| A7 | AC-8 | Target `x86_64-linux-android` tidak terpasang | Keluar bukan `0`; stderr memuat `rustup target add x86_64-linux-android`; tanpa build |
| A8 | AC-7, AC-8 | `tablet.abis=arm64-v8a,armeabi-v7a` di sandbox | Keluar bukan `0`; stderr memuat `armeabi-v7a` dan `matriks`; tanpa build |
| A9 | AC-3, AC-7 | Jalur lulus | Keluar `0`. `calls.log` memuat, berurutan: `cargo ndk` dengan `-t <ABI>` untuk tiap ABI di `tablet.abis` menurut urutannya, lalu `build -p tablet-ffi --release --locked`, dari folder kerja akar `repo/`; lalu `gradlew :app:assembleDebug` dari folder kerja `apps/android-tablet`. Baris terakhir stdout `build-android-tablet: selesai` |
| A10 | AC-8 | Jalur lulus | Pada panggilan `cargo ndk`: `CARGO_NDK_PLATFORM` sama dengan `minSdk` katalog sandbox dan `ANDROID_NDK_HOME` sama dengan `<ANDROID_HOME>/ndk/<ndk>`. Pada panggilan `gradlew`: `JAVA_HOME` dan `ANDROID_HOME` terisi dengan nilai sandbox. Sesudah `minSdk` di sandbox diubah menjadi `31`, `CARGO_NDK_PLATFORM` yang dicatat `31`. Sesudah `tablet.abis` diubah menjadi `arm64-v8a`, hanya ada satu `-t` |
| A11 | AC-8 | `ANDROID_HOME` tidak diset, SDK tiruan ada di `<sandbox>/home/Library/Android/sdk` | Keluar `0`; `ANDROID_HOME` yang dicatat sama dengan path itu |
| A12 | AC-8 | Argumen `--salah` | Keluar bukan `0`; stderr memuat `--salah`; tanpa build |

Yang tidak bisa diuji di sandbox dan tetap menjadi bukti verify: lokasi bawaan `JAVA_HOME` (path mutlak ke Android Studio).

### Grup `artifacts`: hasil build yang nyata

Hanya membaca hasil di `target/`, `apps/ipados/build/`, dan `apps/android-tablet/app/build/`. Jalankan sesudah skrip build yang bersangkutan. Hasil yang tidak ada membuat kasusnya gagal dengan pesan yang menyebut skrip yang harus dijalankan. `ANDROID_HOME` dipakai bila diset; bila tidak, `~/Library/Android/sdk`, sama dengan aturan skrip.

**`tests/artifacts/ipados.test.sh`** (butuh macOS dan `scripts/build-ipados.sh` tanpa argumen)

| ID | AC | Yang ditegaskan |
|---|---|---|
| HI1 | AC-3 | `target/aarch64-apple-ios/release/libtablet_ffi.a` dan `target/aarch64-apple-ios-sim/release/libtablet_ffi.a` ada dan tidak kosong |
| HI2 | AC-5 | Pada `apps/ipados/build/DerivedData/Build/Products/Debug-iphonesimulator/Tablet.app`: `lipo -archs Tablet.app/Tablet` mencetak `arm64` saja; `plutil -extract MinimumOSVersion raw Tablet.app/Info.plist` sama dengan `IPHONEOS_DEPLOYMENT_TARGET` di `Base.xcconfig`; `plutil -extract UIDeviceFamily json -o - Tablet.app/Info.plist` mencetak `[2]` |
| HI3 | AC-6 | Tiga pemeriksaan yang sama pada `.../Release-iphoneos/Tablet.app`, dan `codesign -dv` pada app itu keluar bukan `0` dengan keluaran yang memuat `not signed` |
| HI4 | AC-11 | `git status --short` kosong |

**`tests/artifacts/android-tablet.test.sh`** (butuh `scripts/build-android-tablet.sh`)

| ID | AC | Yang ditegaskan |
|---|---|---|
| HA1 | AC-3 | Untuk tiap ABI di `tablet.abis`, `target/<triple>/release/libtablet_ffi.so` ada dan tidak kosong |
| HA2 | AC-4 | Untuk tiap file itu, `llvm-objdump -p <file> \| grep LOAD` mencetak minimal satu baris dan setiap barisnya berakhir `align 2**14`. Alat diambil dari `<ANDROID_HOME>/ndk/<ndk>/toolchains/llvm/prebuilt/*/bin/llvm-objdump` |
| HA3 | AC-7 | `aapt2 dump badging apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk` memuat `minSdkVersion:'<minSdk>'`, `targetSdkVersion:'<targetSdk>'`, dan `compileSdkVersion='<compileSdk>'`, dengan nilai dari katalog. `aapt2` diambil dari folder `<ANDROID_HOME>/build-tools/*/` yang urutannya terakhir |
| HA4 | AC-7 | Pada `unzip -l <apk>`, setiap path yang diawali `lib/` berada di bawah `lib/<ABI>/` untuk ABI yang ada di `tablet.abis` |
| HA5 | AC-11 | `git status --short` kosong. Sengaja sama dengan HI4, karena di CI tiap platform dibangun di job yang berbeda |

### `test-preferences.json`

File ini di-commit di akar repo dengan isi persis berikut. Tester menulisnya sebelum memanggil skill `/test`, supaya skill menemukan `tool` yang sudah terisi dan melewati panel pemilihan framework serta panel pemasangan, di fitur ini dan fitur berikutnya.

```json
{
  "tool": "cargo test",
  "gate": null,
  "additionalTools": ["bash"],
  "e2eTool": "none",
  "testDir": "Rust: di dalam crate (#[cfg(test)] atau crates/<crate>/tests/). Tes tingkat repo: tests/<grup>/",
  "filePattern": "Rust: *.rs. Tes tingkat repo: *.test.sh",
  "packageManager": "cargo"
}
```

| Kunci | Nilai | Alasan |
|---|---|---|
| `tool` | `cargo test` | Sama dengan yang dipilih skill `/test` sendiri untuk repo ber-`Cargo.toml`, tanpa bertanya. Dipakai mulai fitur 03 |
| `gate` | `null` | Repo ini memakai tes, bukan hanya typecheck |
| `additionalTools` | `["bash"]` | Tes tingkat repo di `tests/`. Tidak ada yang perlu dipasang |
| `e2eTool` | `none` | Belum ada alur layar. Fitur 04 menetapkan alat tes native dan menambahkannya di sini |
| `testDir`, `filePattern` | Dua area dalam satu kalimat | Format file hanya punya satu tempat untuk tiap kunci, sedangkan repo punya dua area tes |
| `packageManager` | `cargo` | Satu satunya pengelola paket yang dipakai tes |

Perintah menjalankan tes tidak disimpan di file ini. Perintahnya ada di "Perintah tes dan kontrak `scripts/test.sh`" dan di `docs/getting-started.md`.

Skill `/test` tidak mengenal repo tanpa `package.json`, jadi empat hal berikut ditetapkan di sini dan disalin lead ke brief tester:

- **Lingkup**: skill menyaring `tests/`, `*.json`, dan dokumen, dan kode fitur 01 sudah ter-commit, jadi panel "No changes" muncul. Jawabannya `Specific files`: `scripts/build-ipados.sh` dan `scripts/build-android-tablet.sh` (kelas `cli`), ditambah file konfigurasi pada tabel "Sumber nilai" sebagai bahan bacaan.
- **Perintah menjalankan**: `scripts/test.sh` untuk suite cepat dan `scripts/test.sh artifacts` sesudah kedua skrip build. Bukan `cargo test`, yang akan lulus dengan nol tes dan tidak membuktikan apa pun.
- **Tanpa tes Rust**: nilai `tool` adalah `cargo test`, tetapi di fitur 01 tester tidak menulis `#[test]` atau file `.rs`. Semua kasus ada di tabel bagian ini.
- **Langkah penutup skill dilewati**: skill ingin mencentang `Test it` di `docs/scope/` dan mengubah status spec menjadi `Accepted`. Keduanya dikerjakan lead, bukan tester.

### Pemilik dan batas tester

- **Boleh dibuat tester**: `test-preferences.json`, `scripts/test.sh`, `tests/lib/harness.sh`, dan tujuh file tes di `tests/repo/`, `tests/build-scripts/`, dan `tests/artifacts/`. Bukti tes disimpan di `docs/reviews/` dengan nama `<tanggal>-test-f01.md`.
- **Boleh diubah tester untuk tugas 15, hanya sebagai tambahan**: bagian baru "Menjalankan tes" di `docs/getting-started.md` (blok enam perintah "Perintah repo" tidak disentuh), serta baris yang berubah pada tabel "Pemilik tiap bagian" dan "Penyimpangan dari README bagian 5" berikut blok struktur di `docs/architecture/ownership-matrix.md` dan `docs/architecture/repository-structure.md`. Lead boleh menyerahkan tugas 15 ke developer; isinya sama.
- **Dilarang**: `crates/**`, `apps/**`, `scripts/build-ipados.sh`, `scripts/build-android-tablet.sh`, `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, `.xcode-version`, `.gitignore`, spec ini, `verify.md`, `docs/scope/**`, dan `AGENTS.md`.
- **Urutan commit**: tester meng-commit di branch-nya sendiri (`test(repo): ...`). Tugas 12, 13, dan 15 di-commit lebih dulu, karena `git clone` pada tugas 14 hanya berisi file yang ter-commit dan kasus HI4 serta HA5 menuntut `git status --short` kosong. Clone tugas 14 dibuat dari commit itu.
- **Bila tes merah karena kode produksi**: tester tidak melunakkan tes dan tidak mengubah kode. Ia mengirim perintah dan keluaran persis ke developer pemilik file dan mencatatnya di laporan.
- **Bila perilaku skrip berbeda dari tabel kasus di atas**: tabel kasus diturunkan dari kontrak skrip di "Perintah repo" dan dari skrip pada `main` saat spec ini diperbarui. Selisih kata kunci pesan boleh disesuaikan tester ke pesan nyata dan dicatat di laporan sebagai tafsiran. Selisih perilaku (kode keluar, urutan, nilai yang diteruskan) adalah temuan untuk developer.

### Cakupan AC

| AC | Kasus yang mengunci | Yang tetap hanya bukti verify |
|---|---|---|
| AC-1 | B1, V2 | `cargo build` dan `cargo test` keluar `0` (perintah repo; dijalankan CI fitur 11) |
| AC-2 | B2 sampai B6, V3 | "Tepat dua crate", `tablet-core` tanpa dependensi sama sekali, pustaka host di `target/debug/` |
| AC-3 | I7, A9, HI1, HA1 | Tidak ada |
| AC-4 | HA2 | Perangkat 16 KB (MAN-3) |
| AC-5 | I7, I9, V9, HI2 | Tidak ada |
| AC-6 | I7, I9, V9, HI3 | iPad fisik (MAN-1) |
| AC-7 | A8, A9, V9, HA3, HA4 | Tablet fisik (MAN-2) |
| AC-8 | V1 sampai V7, I1 sampai I6, I8, I10, A1 sampai A8, A10 sampai A12 | Nilai sama dengan tabel "Proposed stack" spec; `./gradlew buildEnvironment`; lokasi bawaan `JAVA_HOME` |
| AC-9 | C4, V8 | Pengulangan panduan pada clone baru |
| AC-10 | V8 | Kelengkapan isi lima dokumen arsitektur |
| AC-11 | C1, C2, C3, C5, I11, HI4, HA5 | Aplikasi tetap minimal dan belum menautkan pustaka Rust |

### Bukti bahwa tes menggigit

Tes shell mudah lulus tanpa memeriksa apa pun. Karena itu tester menjalankan lima perubahan sengaja berikut, masing masing pada `git clone` sekali pakai di luar repo, dan mencatat kasus yang menjadi merah. Tidak ada perubahan ini yang di-commit.

| Perubahan sengaja | Kasus yang harus merah |
|---|---|
| Tambah `uniffi.workspace = true` di bawah `[dependencies]` pada `crates/core/Cargo.toml` | B6 |
| Ubah `agp` di katalog menjadi `9.3.4` tanpa mengubah dokumen | V8 |
| `git add -f` satu file biner `x.so` (misalnya salinan `gradle-wrapper.jar`) | C1 dan C2 |
| Ubah `EXPECTED_JAVA_MAJOR` menjadi `21` pada `scripts/build-android-tablet.sh` di clone itu | Minimal A4, A5, dan A9 (kasus Android lain yang melewati pemeriksaan JDK ikut merah) |
| Jalankan `scripts/test.sh artifacts` pada clone yang belum pernah dibangun | Semua kasus HI dan HA selain HI4 dan HA5 |

Selain itu `scripts/test.sh tidak-ada` harus keluar `2`.

## Catatan arsitektur yang ditulis developer

Semua dokumen ditulis dalam bahasa Indonesia, mengikuti `AGENTS.md` dan `docs/scope/`. Isinya menggambarkan keadaan repo yang nyata; hal yang baru ditetapkan diberi tanda "ditetapkan, belum dibangun".

| Dokumen | Isi wajib |
|---|---|
| `docs/getting-started.md` | Prasyarat dan versi, cara memasang, perintah pada "Perintah repo", lokasi hasil build, masalah umum (JDK, `ANDROID_HOME`, target Rust), dan bagian "Menjalankan tes" dengan empat perintah `scripts/test.sh` (tugas 15) |
| `docs/architecture/overview.md` | Gambaran lapisan A sampai E pada tingkat yang sudah dibangun, tautan ke dokumen lain, daftar hal yang ditetapkan tetapi belum dibangun |
| `docs/architecture/support-matrix.md` | Tabel "Proposed stack" dan "Matriks dukungan" spec ini beserta alasan, target yang tidak didukung, tanggal pemeriksaan, dan tautan sumber dari `rationale.md` |
| `docs/architecture/ownership-matrix.md` | Tabel "Pemilik tiap bagian" di bawah |
| `docs/architecture/dependency-rules.md` | Diagram dan tujuh aturan "Arah dependensi" di bawah |
| `docs/architecture/repository-structure.md` | Struktur nyata, tabel "Penyimpangan dari README bagian 5" di bawah |

### Pemilik tiap bagian

| Path | Pemilik (lapisan README) | Tanggung jawab | Hasil generasi |
|---|---|---|---|
| `crates/core` | Inti Rust (C) | Perilaku dan aturan bersama | Tidak |
| `crates/tablet-ffi` | Batas UniFFI (C) | Hanya memetakan API inti ke kontrak UniFFI; tanpa perilaku sendiri | Tidak |
| `bindings/swift`, `bindings/kotlin` | Tooling (E) | Binding hasil generasi dan pustaka terkemas | Ya, kecuali `Package.swift` |
| `apps/ipados` | Presentasi dan integrasi iPad (A, B) | SwiftUI, scene, API Apple | Tidak |
| `apps/android-tablet` | Presentasi dan integrasi Android (A, B) | Compose, Activity, API Android | Tidak, kecuali `jniLibs` |
| `scripts/` | Tooling (E) | Pintu build dan tes yang sama untuk lokal dan CI | Tidak |
| `tests/lib`, `tests/repo`, `tests/build-scripts`, `tests/artifacts` | Tooling (E) | Tes tingkat repo: hal yang tidak dimiliki satu crate atau satu aplikasi | Tidak |
| `test-preferences.json` | Tooling (E) | Pilihan alat tes untuk skill `/test` | Tidak |
| `rust-toolchain.toml`, `Cargo.toml`, `.xcode-version`, `libs.versions.toml`, wrapper Gradle | Tooling (E) | Kunci versi | Tidak |
| `docs/architecture` | Tata kelola | Catatan arsitektur | Tidak |
| `docs/specs`, `docs/scope` | Tata kelola | Catatan keputusan dan rencana | Tidak |
| `design-system/`, `shared/`, `tooling/`, `tests/fixtures`, `tests/contracts`, `.github/` | Pemilik fitur 03, 08, 09, 10, 11 | Belum ada | Belum ada |

### Arah dependensi

```
apps/ipados ──────┐
                  ├──> bindings (hasil generasi) ──> crates/tablet-ffi ──> crates/core
apps/android-tablet ┘
scripts ──> cargo, xcodebuild, gradle (hanya saat build)
```

1. `tablet-core` tidak bergantung pada apa pun di repo ini, pada `uniffi`, atau pada kerangka UI dan platform.
2. `tablet-ffi` hanya bergantung pada `tablet-core` dan `uniffi`. Di luar crate tooling generator binding, hanya crate ini yang boleh memuat `uniffi`.
3. Aplikasi hanya memakai Rust lewat binding hasil generasi dan pustaka terkemas. Aplikasi tidak merujuk `crates/` atau `target/`.
4. Kedua aplikasi tidak saling bergantung dan tidak berbagi kode sumber.
5. Rust tidak bergantung pada aplikasi, token desain, atau sumber daya bersama.
6. Proyek Xcode dan Gradle tidak memanggil Cargo. Hanya `scripts/` yang menyeberang dari Rust ke native.
7. Hasil generasi tidak disunting tangan dan tidak di-commit.

### Penyimpangan dari README bagian 5

| README | Di repo | Alasan |
|---|---|---|
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

## Build plan

Pendekatan Tracer Bullet: milestone 1 sampai 3 menarik satu benang tipis dari Cargo ke kedua build native, milestone 4 mengulang semuanya dari clone bersih dan mendokumentasikannya, milestone 5 mengunci hasilnya dengan tes. File tiap milestone tidak beririsan, dengan satu pengecualian: milestone 4 menambah satu baris ke `apps/ipados/Config/Base.xcconfig` milik milestone 2 (tugas 11). Hanya satu build native penuh yang boleh berjalan pada satu waktu, jadi milestone 2 dan 3 dijalankan berurutan.

**Milestone 1: Workspace Rust dan batas crate** (tanpa build native)

File: `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, `.gitignore`, `crates/core/**`, `crates/tablet-ffi/**`.

1. Tulis `rust-toolchain.toml` dan `Cargo.toml` akar sesuai "Workspace Rust", satisfies **AC-1**, **AC-8**
2. Buat `crates/core` dan `crates/tablet-ffi` dengan batas dependensi yang ditetapkan, commit `Cargo.lock`, satisfies **AC-1**, **AC-2**
3. Tulis `.gitignore` akar lengkap sesuai "Aturan commit", satisfies **AC-11**

**Milestone 2: Proyek iPad minimal dan skrip build** (butuh build Xcode; needs milestone 1)

File: `apps/ipados/**`, `scripts/build-ipados.sh`, `.xcode-version`.

4. Tulis `Base.xcconfig`, `TabletApp.swift`, `Tablet.xcodeproj`, dan skema bersama sesuai "Proyek iPad", satisfies **AC-5**, **AC-6**, **AC-8**, **AC-11**
5. Tulis `scripts/build-ipados.sh` sesuai kontraknya dan `.xcode-version`, lalu jalankan untuk simulator dan perangkat, satisfies **AC-3**, **AC-5**, **AC-6**, **AC-8**

**Milestone 3: Proyek Android minimal dan skrip build** (butuh build Gradle; needs milestone 1; after milestone 2 karena satu build native pada satu waktu)

File: `apps/android-tablet/**`, `scripts/build-android-tablet.sh`.

6. Buat wrapper Gradle 9.5.1 dengan checksum, katalog versi, `gradle-daemon-jvm.properties`, `gradle.properties`, dan build file sesuai "Proyek Android", satisfies **AC-7**, **AC-8**
7. Tulis `MainActivity`, manifest, dan `strings.xml`, satisfies **AC-7**, **AC-11**
8. Tulis `scripts/build-android-tablet.sh` sesuai kontraknya, jalankan, lalu periksa keselarasan 16 KB kedua `.so`, satisfies **AC-3**, **AC-4**, **AC-7**, **AC-8**

**Milestone 4: Panduan mulai singkat dan catatan arsitektur** (butuh build Xcode lalu Gradle, berurutan; needs milestone 1, 2, 3)

File: `docs/getting-started.md`, `docs/architecture/**`, dan `apps/ipados/Config/Base.xcconfig` (file milestone 2 yang sudah selesai; hanya baris `ALWAYS_SEARCH_USER_PATHS = NO` yang ditambahkan, baris lain tidak berubah).

9. Tulis `docs/getting-started.md`, lalu ikuti panduan itu pada `git clone` baru di folder sementara dan catat hasil tiap perintah, satisfies **AC-9**
10. Tulis lima dokumen `docs/architecture/` sesuai "Catatan arsitektur yang ditulis developer", satisfies **AC-10**
11. Tambahkan baris `ALWAYS_SEARCH_USER_PATHS = NO` ke `apps/ipados/Config/Base.xcconfig` di posisi yang sama dengan blok pada "Proyek iPad", dan pastikan `scripts/build-ipados.sh` tidak lagi mencetak peringatan headermap (`grep -c 'Traditional headermap'` pada log build menampilkan `0`). Kerjakan sebelum pengulangan clone bersih pada tugas 9 supaya build itu sekaligus menjadi buktinya, satisfies **AC-5**, **AC-6**, **AC-8**

**Milestone 5: Tes tingkat repo** (dikerjakan tester untuk kotak `Test it`; needs milestone 1 sampai 4; tugas 14 butuh build Xcode lalu Gradle, berurutan)

File: `test-preferences.json`, `scripts/test.sh`, `tests/**`, serta tambahan pada `docs/getting-started.md`, `docs/architecture/ownership-matrix.md`, dan `docs/architecture/repository-structure.md` (tugas 15). Tidak ada file produksi yang berubah.

12. Tulis `test-preferences.json` dengan isi pada "Rancangan tes fitur 01", lalu `scripts/test.sh`, `tests/lib/harness.sh`, dan tiga file grup `repo` (kasus B1 sampai B6, V1 sampai V9, C1 sampai C5). `scripts/test.sh repo` keluar `0`, locks **AC-1**, **AC-2**, **AC-8**, **AC-9**, **AC-10**, **AC-11**
13. Tulis dua file grup `build-scripts` dengan sandbox dan alat tiruan (kasus I1 sampai I11, A1 sampai A12). `scripts/test.sh` tanpa argumen keluar `0` tanpa memanggil build apa pun, dan `/bin/bash scripts/test.sh` memberi hasil yang sama, locks **AC-8**, dan sisi perintah **AC-3**, **AC-5**, **AC-6**, **AC-7**
14. Tulis dua file grup `artifacts` (kasus HI1 sampai HI4, HA1 sampai HA5) dan commit bersama tugas 12, 13, dan 15. Pada `git clone` baru dari commit itu, di luar repo, jalankan `scripts/build-ipados.sh`, lalu `scripts/build-android-tablet.sh`, lalu `scripts/test.sh repo build-scripts artifacts`; semuanya keluar `0`, locks **AC-3**, **AC-4**, **AC-5**, **AC-6**, **AC-7**, **AC-11**
15. Tambahkan bagian "Menjalankan tes" ke `docs/getting-started.md`, dan selaraskan `docs/architecture/ownership-matrix.md` serta `docs/architecture/repository-structure.md` dengan tabel "Pemilik tiap bagian", tabel "Penyimpangan dari README bagian 5", dan blok "Struktur repo fitur 01" spec ini. Kerjakan sebelum pengulangan pada tugas 14 supaya kasus V8 berjalan pada dokumen akhir, keeps **AC-9**, **AC-10**
16. Jalankan lima perubahan sengaja pada "Bukti bahwa tes menggigit" dan catat kasus yang merah, lalu simpan bukti tes (perintah, keluaran, SHA, target) di `docs/reviews/`, locks **AC-2**, **AC-8**, **AC-11**

**Skenario uji penting**:

- Clone bersih: `git clone` ke folder sementara lalu enam perintah pada "Perintah repo", verifies **AC-1**, **AC-3**, **AC-5**, **AC-6**, **AC-7**, **AC-9**
- Batas crate: dua perintah `cargo tree` pada AC-2, verifies **AC-2**
- Prasyarat hilang: tiga percobaan pada AC-8 (`ANDROID_HOME`, `JAVA_HOME`, `DEVELOPER_DIR`), masing masing harus keluar bukan 0 dan menyebut cara memperbaikinya, verifies **AC-8**
- Tidak ada biner ter-commit dan pohon kerja tetap bersih sesudah build: perintah pada AC-11, verifies **AC-11**
- Suite cepat: `scripts/test.sh` tanpa argumen pada clone yang belum pernah dibangun keluar `0` dan tidak membuat file di dalam repo (`git status --short --ignored` kosong sesudahnya), verifies **AC-1**, **AC-2**, **AC-8**, **AC-9**, **AC-10**, **AC-11**
- Suite hasil build: `scripts/test.sh artifacts` sesudah kedua skrip build keluar `0`; pada clone yang belum dibangun keluar `1` dengan pesan yang menyebut skrip build, verifies **AC-3**, **AC-4**, **AC-5**, **AC-6**, **AC-7**
- Tes menggigit: lima perubahan sengaja pada "Bukti bahwa tes menggigit" masing masing membuat kasus yang disebut menjadi merah, verifies **AC-2**, **AC-8**, **AC-11**

## Consequences

**Positive**:

- Satu pintu build (`scripts/`) untuk lokal dan CI sejak hari pertama, sesuai permintaan audit.
- Binding tidak mungkin basi: selalu dihasilkan dari revisi yang sama dengan pustaka.
- Tidak ada yang perlu diunduh ke SDK Android dan Xcode di mesin lead; yang dipasang hanya target Rust, `cargo-ndk`, dan distribusi Gradle.
- Matriks kecil (dua target per platform) membuat tiap janji bisa diuji.
- Kenaikan versi yang hanya mengubah satu tempat (file sumber tanpa dokumen, atau sebaliknya) tertangkap `scripts/test.sh` dalam beberapa detik, tanpa build.
- Cabang prasyarat kedua skrip build teruji tanpa Xcode, Android SDK, atau JDK yang asli, jadi bisa dijalankan di runner mana pun.

**Negative / tradeoffs**:

- Membuka proyek di Xcode atau Android Studio sesudah fitur 04 butuh skrip dijalankan dulu, dan dijalankan lagi tiap kali Rust berubah.
- AGP 9.3.3 dan Rust 1.99.1 bukan versi terbaru; naik versi adalah pekerjaan tersendiri.
- `project.pbxproj` ditulis tangan; perubahan target (bukan file) tetap menyentuh file itu.
- Tablet Android 32 bit dan iPad yang berhenti di iPadOS 18 tidak didukung.
- `targetSdk` 36 memicu peringatan lint "bukan target terbaru" sampai dinaikkan.
- Identitas aplikasi masih `com.example.tablet`; tidak bisa dipakai untuk distribusi atau perangkat fisik iPad.
- iPadOS minimum tertulis di dua tempat sesudah fitur 04 (`Base.xcconfig` dan `Package.swift`).
- Tes bash polos memakai helper buatan sendiri (`tests/lib/harness.sh`) yang harus dirawat, dan harus tetap berjalan di bash 3.2.
- Tes sandbox bergantung pada cara skrip menemukan akar repo dan pada kata kunci pesannya. Mengubah salah satunya berarti menyesuaikan tes di commit yang sama.
- Fitur yang meng-commit biner yang sah atau menambah path hasil build harus memperbarui daftar izin (C2) atau daftar path (C3).

**Neutral**:

- `tablet-core` dan `tablet-ffi` belum punya fungsi; `cargo test` lulus dengan nol tes Rust sampai fitur 03. Tes fitur 01 adalah tes tingkat repo di `tests/` dan dijalankan `scripts/test.sh`, bukan `cargo test`.
- Grup `artifacts` tidak membangun; ia gagal bila hasil build belum ada. Urutan build lalu tes adalah tanggung jawab pemanggil (kontributor, tester, atau CI fitur 11).
- Fitur 01 membangun pustaka Rust untuk tiap target tetapi belum menautkannya ke aplikasi.
- Tiap build Rust menghasilkan `staticlib` dan `cdylib` untuk semua target, walau tiap platform hanya memakai satu.
- JDK 25 dipakai untuk menjalankan Gradle, sedangkan AGP menyebut JDK 17 sebagai minimum; cadangan JDK 21 sudah disetujui.

## Follow-up

- [ ] Nilai dari user: bundle ID dan `applicationId` asli, Team ID Apple, dan lisensi repo. Sampai ada, pakai `com.example.tablet` dan jangan isi field `license`.
- [ ] Fitur 03: tulis `scripts/generate-bindings.sh` dan `uniffi.toml` dengan nama pada bagian pengemasan, tetapkan bentuk generator binding (mode pustaka, crate tooling), versi JNA, mode bahasa Swift untuk modul `TabletBindings` (UniFFI 0.32 baru mendukung Swift 6 sebagian), dan tambahkan `hello`.
- [ ] Fitur 04: buat AVD tablet dari image `google_apis` `android-36` `arm64-v8a` yang terpasang, tambahkan urutan pengemasan ke kedua skrip, tulis `bindings/swift/Package.swift`, dan lengkapi panduan dengan cara menjalankan. Peluncuran Android di CI memakai emulator `x86_64` di runner Linux.
- [ ] Fitur 03: tes Rust pertama (`#[test]` di `tablet-core`, uji asap ekspor UniFFI) memakai `cargo test`. Putuskan apakah `scripts/test.sh` mendapat grup yang memanggil `cargo test --workspace --locked`. Bila fitur 03 menambah dependensi ke `tablet-core`, kasus B3 harus tetap lulus tanpa diubah. Crate tooling generator binding ditaruh di luar `crates/` (kandidat `tooling/uniffi-bindgen`) supaya kasus B6 tetap lulus tanpa diubah.
- [ ] Fitur 04: tetapkan alat tes native (kandidat: target tes di proyek Xcode, serta `app/src/test` dan `app/src/androidTest` di modul `:app`) dan tambahkan ke `additionalTools` atau `e2eTool` pada `test-preferences.json`. Saat urutan pengemasan masuk ke kedua skrip, perbarui daftar file sandbox, alat tiruan (`scripts/generate-bindings.sh`, `xcodebuild -create-xcframework`), dan kasus I7, I11, A9, HA4, serta daftar path C3. Kasus I11 berubah dari "tidak membuat file" menjadi "hanya membuat file di path yang diabaikan Git". Bila target tes native menaruh build setting di `project.pbxproj`, sesuaikan kasus V7 atau pindahkan nilainya ke xcconfig.
- [ ] Fitur 06: konfirmasi versi Material 3 adaptive (kandidat 1.3.0) terhadap BOM saat itu.
- [ ] Fitur 11: periksa `zipalign -P 16` pada APK, jalankan salam di emulator 16 KB (image `google_apis_ps16k`, belum terpasang), tautkan pustaka di build Release iPad, dan luncurkan pada OS minimum (runtime iOS 26.5 dan emulator API 29). File scope fitur 11 belum menyebut uji OS minimum.
- [ ] Fitur 10: periksa bahwa `platforms` di `Package.swift` sama dengan `IPHONEOS_DEPLOYMENT_TARGET`. Saat `scripts/validate-architecture.sh` ada, putuskan apakah kasus batas crate (B2 sampai B6) dan aturan commit (C1 sampai C5) dipanggil dari sana atau dipindahkan, supaya tiap aturan punya satu rumah.
- [ ] Fitur 11: panggil `scripts/test.sh` dan `scripts/test.sh artifacts/<platform>` di CI sesudah skrip build, dan buktikan grup `repo` serta `build-scripts` berjalan di runner Linux (di fitur 01 hanya dibuktikan di macOS). Pemeriksaan keselarasan ELF di CI memakai ulang kasus HA2, bukan menulis yang baru; `zipalign` dan pustaka di dalam APK akhir ditambahkan sebagai kasus baru di `tests/artifacts/android-tablet.test.sh`.
- [ ] Naikkan `targetSdk` ke 37 saat emulator tablet API 37 masuk matriks uji.
- [ ] Android Studio di mesin lead adalah 2026.1; periksa apakah versi itu bisa menyinkronkan AGP 9.3 sebelum mengandalkan IDE. Build lewat skrip tidak terpengaruh.
- [ ] `docs/architecture/boundaries.md` ditulis oleh fitur pertama yang menambah isi batas lapisan (kandidat: fitur 10).
