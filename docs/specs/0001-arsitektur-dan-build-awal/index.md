# 0001. Arsitektur dan build awal

**Date**: 2026-11-15
**Status**: Proposed

## Summary

Spec ini menetapkan kerangka repo: satu workspace Rust berisi dua crate (inti dan lapisan ekspor UniFFI), satu proyek iPad, dan satu proyek Android tablet, semuanya dengan versi alat yang dikunci. Kombinasi versi dipilih dari yang tercatat saling cocok di dokumentasi resmi pada 15 November 2026, bukan yang paling baru. Hasil fitur 01 adalah repo yang bisa dikompilasi dari clone bersih dengan perintah repo yang sama untuk lokal dan CI, ditambah catatan arsitektur dan panduan mulai singkat. Salam `hello`, binding, dan penautan pustaka Rust ke aplikasi dibangun di fitur 03 dan 04 dengan mengikuti keputusan pengemasan yang dicatat di sini.

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
- **AC-7**: `scripts/build-android-tablet.sh` selesai dengan kode keluar 0 dan menghasilkan `apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk`. Bukti: `"$ANDROID_HOME/build-tools/36.0.0/aapt2" dump badging <apk>` memuat `sdkVersion:'29'`, `targetSdkVersion:'36'`, dan `compileSdkVersion='37'`; `unzip -l <apk> | grep 'lib/'` hanya menampilkan folder `lib/arm64-v8a/` dan `lib/x86_64/` (atau tidak ada sama sekali). Menjalankan APK di emulator adalah milik fitur 04, di tablet fisik adalah langkah manual.
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

Repo memakai Rust 1.99.1, UniFFI 0.32.2, Xcode 27.1, AGP 9.3.3, Gradle 9.5.1, Kotlin 2.4.21, dan NDK 28.2.13676358; dua crate memisahkan inti dari ekspor UniFFI; `scripts/` adalah satu satunya tempat yang menyeberang dari Rust ke proyek native; hasil generasi dan biner tidak pernah di-commit.

Tanda `biasa` atau `berat` tiap keputusan ada di tabel "Keputusan diambil" pada [rationale.md](rationale.md). Tidak ada keputusan `berat` di spec ini.

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

Hanya path berikut yang dibuat. Folder lain pada README bagian 5 dibuat oleh fitur pemiliknya.

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

- `SWIFT_DEFAULT_ACTOR_ISOLATION` dan `SWIFT_APPROACHABLE_CONCURRENCY` mengikuti bawaan templat Xcode untuk aplikasi; nilainya hanya berlaku untuk target aplikasi, bukan untuk modul binding.
- `Config/Local.xcconfig` tidak di-commit. Isinya nilai milik user (`DEVELOPMENT_TEAM`, dan `PRODUCT_BUNDLE_IDENTIFIER` asli bila sudah ada). File itu tidak boleh menimpa `IPHONEOS_DEPLOYMENT_TARGET`.
- Tidak ada asset catalog, target tes, atau paket Swift di fitur 01.

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
- Tidak ada modul lain, `jniLibs`, dependensi JNA, tes, atau lint khusus di fitur 01.

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

Aturan untuk kedua skrip: `set -euo pipefail`; pindah ke akar repo lebih dulu sehingga bisa dipanggil dari folder mana pun; di dalam repo hanya menulis ke `target/`, `apps/ipados/build/`, dan folder `build/`, `.gradle/`, serta `.kotlin/` milik Gradle; di-commit dengan mode `100755`. Di fitur 01 skrip belum menyalin pustaka Rust ke proyek native.

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

## Catatan arsitektur yang ditulis developer

Semua dokumen ditulis dalam bahasa Indonesia, mengikuti `AGENTS.md` dan `docs/scope/`. Isinya menggambarkan keadaan repo yang nyata; hal yang baru ditetapkan diberi tanda "ditetapkan, belum dibangun".

| Dokumen | Isi wajib |
|---|---|
| `docs/getting-started.md` | Prasyarat dan versi, cara memasang, perintah pada "Perintah repo", lokasi hasil build, masalah umum (JDK, `ANDROID_HOME`, target Rust) |
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
| `scripts/` | Tooling (E) | Pintu build yang sama untuk lokal dan CI | Tidak |
| `rust-toolchain.toml`, `Cargo.toml`, `.xcode-version`, `libs.versions.toml`, wrapper Gradle | Tooling (E) | Kunci versi | Tidak |
| `docs/architecture` | Tata kelola | Catatan arsitektur | Tidak |
| `docs/specs`, `docs/scope` | Tata kelola | Catatan keputusan dan rencana | Tidak |
| `design-system/`, `shared/`, `tooling/`, `tests/`, `.github/` | Pemilik fitur 03, 08, 09, 10, 11 | Belum ada | Belum ada |

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
| `design-system/`, `shared/`, `tooling/`, `tests/`, `.github/`, skrip lain | Belum dibuat | README melarang folder penanda tempat; dibuat oleh fitur pemiliknya |

## Build plan

Pendekatan Tracer Bullet: milestone 1 sampai 3 menarik satu benang tipis dari Cargo ke kedua build native, milestone 4 mengulang semuanya dari clone bersih dan mendokumentasikannya. File tiap milestone tidak beririsan. Hanya satu build native penuh yang boleh berjalan pada satu waktu, jadi milestone 2 dan 3 dijalankan berurutan.

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

File: `docs/getting-started.md`, `docs/architecture/**`.

9. Tulis `docs/getting-started.md`, lalu ikuti panduan itu pada `git clone` baru di folder sementara dan catat hasil tiap perintah, satisfies **AC-9**
10. Tulis lima dokumen `docs/architecture/` sesuai "Catatan arsitektur yang ditulis developer", satisfies **AC-10**

**Skenario uji penting**:

- Clone bersih: `git clone` ke folder sementara lalu enam perintah pada "Perintah repo", verifies **AC-1**, **AC-3**, **AC-5**, **AC-6**, **AC-7**, **AC-9**
- Batas crate: dua perintah `cargo tree` pada AC-2, verifies **AC-2**
- Prasyarat hilang: tiga percobaan pada AC-8 (`ANDROID_HOME`, `JAVA_HOME`, `DEVELOPER_DIR`), masing masing harus keluar bukan 0 dan menyebut cara memperbaikinya, verifies **AC-8**
- Tidak ada biner ter-commit dan pohon kerja tetap bersih sesudah build: perintah pada AC-11, verifies **AC-11**

## Consequences

**Positive**:

- Satu pintu build (`scripts/`) untuk lokal dan CI sejak hari pertama, sesuai permintaan audit.
- Binding tidak mungkin basi: selalu dihasilkan dari revisi yang sama dengan pustaka.
- Tidak ada yang perlu diunduh ke SDK Android dan Xcode di mesin lead; yang dipasang hanya target Rust, `cargo-ndk`, dan distribusi Gradle.
- Matriks kecil (dua target per platform) membuat tiap janji bisa diuji.

**Negative / tradeoffs**:

- Membuka proyek di Xcode atau Android Studio sesudah fitur 04 butuh skrip dijalankan dulu, dan dijalankan lagi tiap kali Rust berubah.
- AGP 9.3.3 dan Rust 1.99.1 bukan versi terbaru; naik versi adalah pekerjaan tersendiri.
- `project.pbxproj` ditulis tangan; perubahan target (bukan file) tetap menyentuh file itu.
- Tablet Android 32 bit dan iPad yang berhenti di iPadOS 18 tidak didukung.
- `targetSdk` 36 memicu peringatan lint "bukan target terbaru" sampai dinaikkan.
- Identitas aplikasi masih `com.example.tablet`; tidak bisa dipakai untuk distribusi atau perangkat fisik iPad.
- iPadOS minimum tertulis di dua tempat sesudah fitur 04 (`Base.xcconfig` dan `Package.swift`).

**Neutral**:

- `tablet-core` dan `tablet-ffi` belum punya fungsi; `cargo test` lulus dengan nol tes sampai fitur 03.
- Fitur 01 membangun pustaka Rust untuk tiap target tetapi belum menautkannya ke aplikasi.
- Tiap build Rust menghasilkan `staticlib` dan `cdylib` untuk semua target, walau tiap platform hanya memakai satu.
- JDK 25 dipakai untuk menjalankan Gradle, sedangkan AGP menyebut JDK 17 sebagai minimum; cadangan JDK 21 sudah disetujui.

## Follow-up

- [ ] Nilai dari user: bundle ID dan `applicationId` asli, Team ID Apple, dan lisensi repo. Sampai ada, pakai `com.example.tablet` dan jangan isi field `license`.
- [ ] Fitur 03: tulis `scripts/generate-bindings.sh` dan `uniffi.toml` dengan nama pada bagian pengemasan, tetapkan bentuk generator binding (mode pustaka, crate tooling), versi JNA, mode bahasa Swift untuk modul `TabletBindings` (UniFFI 0.32 baru mendukung Swift 6 sebagian), dan tambahkan `hello`.
- [ ] Fitur 04: buat AVD tablet dari image `google_apis` `android-36` `arm64-v8a` yang terpasang, tambahkan urutan pengemasan ke kedua skrip, tulis `bindings/swift/Package.swift`, dan lengkapi panduan dengan cara menjalankan. Peluncuran Android di CI memakai emulator `x86_64` di runner Linux.
- [ ] Fitur 06: konfirmasi versi Material 3 adaptive (kandidat 1.3.0) terhadap BOM saat itu.
- [ ] Fitur 11: periksa `zipalign -P 16` pada APK, jalankan salam di emulator 16 KB (image `google_apis_ps16k`, belum terpasang), tautkan pustaka di build Release iPad, dan luncurkan pada OS minimum (runtime iOS 26.5 dan emulator API 29). File scope fitur 11 belum menyebut uji OS minimum.
- [ ] Fitur 10: periksa bahwa `platforms` di `Package.swift` sama dengan `IPHONEOS_DEPLOYMENT_TARGET`.
- [ ] Naikkan `targetSdk` ke 37 saat emulator tablet API 37 masuk matriks uji.
- [ ] Android Studio di mesin lead adalah 2026.1; periksa apakah versi itu bisa menyinkronkan AGP 9.3 sebelum mengandalkan IDE. Build lewat skrip tidak terpengaruh.
- [ ] `docs/architecture/boundaries.md` ditulis oleh fitur pertama yang menambah isi batas lapisan (kandidat: fitur 10).
