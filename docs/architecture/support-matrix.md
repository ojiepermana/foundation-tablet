# Matriks dukungan

Versi alat, target, dan OS minimum yang dijanjikan repo, beserta alasannya. Semua versi diperiksa pada **2026-11-15** dari halaman resmi yang tercantum di bagian "Sumber". Keputusan dan opsi yang ditimbang ada di [spec 0001](../specs/0001-arsitektur-dan-build-awal/index.md) dan [rationale.md](../specs/0001-arsitektur-dan-build-awal/rationale.md). Fitur 03 (target binding) dan fitur 11 (ABI di APK, Release iPad fisik, 16 KB) merujuk dokumen ini.

Bila kamu menaikkan versi, ubah dulu file di kolom "Dikunci di", lalu dokumen ini. File itu adalah sumber kebenaran; dokumen ini hanya mencerminkannya.

## Versi alat

| Lapisan | Pilihan | Dikunci di | Alasan singkat |
| --- | --- | --- | --- |
| Rust | 1.99.1, edisi 2024, resolver 3 | `rust-toolchain.toml`, `Cargo.toml` (`edition`, `rust-version = "1.99"`) | Rilis titik berumur satu bulan; 1.100.0 baru berumur tiga hari saat diperiksa |
| Target Rust | `aarch64-apple-ios`, `aarch64-apple-ios-sim`, `aarch64-linux-android`, `x86_64-linux-android` | `rust-toolchain.toml` (`targets`) | Sama dengan matriks target di bawah |
| UniFFI | 0.32.2 | `Cargo.toml` (`[workspace.dependencies] uniffi = "=0.32.2"`), `Cargo.lock` | Stabil terbaru, rilis 2026-09-22; versi generator dan runtime harus sama persis |
| cargo-ndk | 4.1.2 | [`docs/getting-started.md`](../getting-started.md) (`cargo install cargo-ndk --version 4.1.2 --locked`), dicek `scripts/build-android-tablet.sh` | Stabil terbaru; menyiapkan linker NDK untuk Cargo |
| Xcode dan Swift | Xcode 27.1 (Swift 6.4, SDK iOS 27.1), mode bahasa Swift 6 | `.xcode-version` berisi `27.1`, `SWIFT_VERSION = 6.0` di `apps/ipados/Config/Base.xcconfig` | Terpasang di mesin; butuh macOS 26.6 atau lebih baru di Mac Apple silicon |
| iPadOS minimum | 26.0 | `IPHONEOS_DEPLOYMENT_TARGET = 26.0` di `Base.xcconfig` | Lihat "Alasan OS minimum" |
| Android Gradle Plugin | 9.3.3 | `apps/android-tablet/gradle/libs.versions.toml` | Lini AGP terbaru yang masuk rentang uji Kotlin 2.4.21; mendukung API 37 |
| Gradle | 9.5.1 | `apps/android-tablet/gradle/wrapper/gradle-wrapper.properties` (`distributionUrl`, `distributionSha256Sum`) | Versi bawaan AGP 9.3 (minimum 9.5.0) dan di dalam rentang Kotlin (sampai 9.7.0) |
| Kotlin | 2.4.21, Kotlin bawaan AGP (plugin `org.jetbrains.kotlin.android` tidak dipakai) | `libs.versions.toml`, lewat `classpath` `kotlin-gradle-plugin` di `apps/android-tablet/build.gradle.kts` | Stabil terbaru, rilis 2026-10-08 |
| Compose compiler | plugin `org.jetbrains.kotlin.plugin.compose` 2.4.21 | `libs.versions.toml` (`version.ref = "kotlin"`) | Versinya selalu sama dengan Kotlin |
| Compose | BOM 2026.09.00 (`material3` dari BOM), `activity-compose` 1.13.0 | `libs.versions.toml` | BOM stabil terbaru; Compose 1.12 mewajibkan `compileSdk` 37 dan AGP 9 |
| Material 3 adaptive | belum ditambahkan | tidak ada | Proyek minimal belum memerlukannya. Kandidat untuk fitur 06: 1.3.0 (stabil 2026-08-12) |
| Android SDK | `compileSdk` 37, `targetSdk` 36, `minSdk` 29 | `libs.versions.toml` | Lihat "Alasan OS minimum" |
| Build Tools | 36.0.0, bawaan AGP 9.3 | tidak diset (mengikuti AGP) | Sudah terpasang; menyetelnya sendiri menambah satu angka yang bisa basi |
| NDK | 28.2.13676358 (r28c) | `libs.versions.toml`, `android.ndkVersion`, dipakai skrip sebagai `ANDROID_NDK_HOME` | NDK bawaan AGP 9.3, selaras 16 KB secara bawaan |
| JDK | 25 untuk menjalankan Gradle; bytecode Java 17 | `apps/android-tablet/gradle/gradle-daemon-jvm.properties` (`toolchainVersion=25`), `compileOptions` dan `jvmTarget` 17 di `app/build.gradle.kts` | JBR 25.0.2 sudah ada di Android Studio; Gradle 9.5 berjalan di JVM 17 sampai 26; AGP minimal JDK 17 |

**Cadangan yang sudah disetujui:** bila build Gradle gagal karena JDK 25, pakai JDK 21. Build milestone 3 menerima JDK 25, jadi cadangan ini belum dipakai.

## Target

| Target | Triple Rust atau ABI | OS | Alasan | Bukti di fitur 01 | Bukti lanjutan |
| --- | --- | --- | --- | --- | --- |
| iPad simulator | `aarch64-apple-ios-sim` | iPadOS 26.0 ke atas (runtime 26.5, 27.0, 27.1 terpasang di mesin lead) | Xcode 27 hanya berjalan di Mac Apple silicon, jadi simulator selalu arm64 | Build (AC-3, AC-5) | Peluncuran lokal dan di CI: fitur 04 |
| iPad perangkat | `aarch64-apple-ios` | iPadOS 26.0 ke atas | Semua iPad yang menjalankan iPadOS 26 adalah arm64 | Build Release tanpa tanda tangan (AC-3, AC-6) | Tautan Release: fitur 11. Perangkat fisik: MAN-1 |
| Emulator Android di host arm64 | `arm64-v8a` (`aarch64-linux-android`) | API 29 sampai 37; image `google_apis` API 36 terpasang | Emulator di Mac Apple silicon memakai image arm64 | Build pustaka dan APK (AC-3, AC-7) | Peluncuran lokal: fitur 04 |
| Emulator Android di host x86_64 | `x86_64` (`x86_64-linux-android`) | API 29 sampai 37 | Emulator Android di CI berjalan di runner Linux x86_64, bukan di runner macOS Apple silicon | Build pustaka (AC-3) | Peluncuran di CI: fitur 04 |
| Tablet Android | `arm64-v8a` | Android 10 (API 29) ke atas | Tablet yang masih dijual memakai arm64 | Build (AC-3, AC-7) | Perangkat fisik: MAN-2 |
| Halaman memori 16 KB | `arm64-v8a`, `x86_64` | Android 15 ke atas | **Termasuk.** Google Play menolak pembaruan yang tidak mendukung 16 KB mulai 1 Februari 2027 | Keselarasan ELF (AC-4) | `zipalign` dan emulator 16 KB: fitur 11. Perangkat fisik: MAN-3 |

**Status 16 KB:** kedua `libtablet_ffi.so` Android selaras 16 KB. Setiap baris `LOAD` dari `llvm-objdump -p` berakhir `align 2**14` (bukti build milestone 3: [2026-11-15-build-f01-m3.md](../reviews/2026-11-15-build-f01-m3.md)). Keselarasan ZIP di APK dan peluncuran di emulator 16 KB belum diperiksa (fitur 11). Perangkat fisik 16 KB belum diuji (MAN-3).

MAN-1 sampai MAN-3 adalah langkah perangkat fisik di spec bagian "Bukti perangkat fisik", dicatat `NOT_RUN` sebagai `F01-1` sampai `F01-3` di [file manual koordinasi](../scope/coordination/01-arsitektur-dan-build-awal.manual.md).

## Tidak didukung, dengan alasan

- **`x86_64-apple-ios`** (simulator di Mac Intel): Xcode 27 tidak berjalan di Mac Intel, tetapi SDK simulatornya masih mendaftarkan `x86_64`. `Base.xcconfig` memuat `ARCHS[sdk=iphonesimulator*] = arm64` supaya build simulator generik tidak meminta irisan yang tidak ada di matriks.
- **`armeabi-v7a` dan `x86`** (Android 32 bit): menambah dua build dan dua jalur uji untuk perangkat lama yang bukan sasaran produk ini. `abiFilters` (dari `tablet.abis` di `gradle.properties`) membatasi APK ke dua ABI matriks, sehingga APK tidak terpasang di perangkat 32 bit. Bisa ditambahkan kelak tanpa mengubah kontrak.
- **Mac Catalyst, "Designed for iPad" di Mac, visionOS, ponsel:** di luar lingkup README bagian 24. `Base.xcconfig` memuat `TARGETED_DEVICE_FAMILY = 2` dan mematikan Mac Catalyst serta "Designed for iPad" di Mac dan Vision Pro.

## Alasan OS minimum

- **iPadOS 26.0:** Xcode 27.1 hanya menyediakan simulator dan debug perangkat untuk iOS 17 ke atas, jadi pilihan nyata adalah 17, 18, 26, atau 27. iPadOS 26 membawa sistem jendela yang bisa diubah ukurannya, dasar fitur 05 dan 07. Runtime terdekat yang terpasang adalah 26.5, jadi OS minimum bisa diuji mendekati batasnya. Per 7 Juni 2026, 68% semua iPad sudah memakai iPadOS 26 (data Apple).
- **Android `minSdk` 29:** Android 10 adalah versi pertama dengan tema gelap sistem dan navigasi gestur, dua hal yang diminta README (AC 21 dan bagian 10.2) tanpa jalur kompatibilitas tambahan. Pustaka AndroidX kini memakai `minSdk` bawaan 24, dan versi UniFFI berikutnya meminta minimal API 28 untuk binding Kotlin bawaan. API 29 ke atas mencakup 96,6% perangkat (apilevels.com, data Oktober 2026).
- **`targetSdk` 36 dengan `compileSdk` 37:** Compose 1.12 mewajibkan `compileSdk` 37. Google Play mewajibkan target API 36 sejak 31 Agustus 2026. Target 36 dipilih karena satu satunya image emulator yang terpasang adalah API 36, sehingga perilaku yang dijanjikan bisa diuji di sini. Menaikkan ke 37 tercatat di Follow-up spec.

Belum ada fitur yang meluncurkan aplikasi pada OS minimum (runtime iOS 26.5, emulator API 29). Itu tercatat di Follow-up spec untuk fitur 11.

## Sumber

Diverifikasi lewat web pada 2026-11-15 oleh architect (daftar lengkap di [rationale.md](../specs/0001-arsitektur-dan-build-awal/rationale.md) bagian References).

- Rust: [catatan rilis](https://doc.rust-lang.org/stable/releases.html), [Rust 1.100.0](https://blog.rust-lang.org/2026/11/12/Rust-1.100.0/), [dukungan platform](https://doc.rust-lang.org/stable/rustc/platform-support.html), [target iOS](https://doc.rust-lang.org/stable/rustc/platform-support/apple-ios.html), [target Android](https://doc.rust-lang.org/stable/rustc/platform-support/android.html), [file toolchain rustup](https://rust-lang.github.io/rustup/overrides.html)
- UniFFI: [crates.io](https://crates.io/api/v1/crates/uniffi), [CHANGELOG](https://raw.githubusercontent.com/mozilla/uniffi-rs/main/CHANGELOG.md), [binding bahasa lain](https://mozilla.github.io/uniffi-rs/latest/tutorial/foreign_language_bindings.html), [Kotlin dan Gradle](https://mozilla.github.io/uniffi-rs/latest/kotlin/gradle.html), [Swift](https://mozilla.github.io/uniffi-rs/latest/swift/overview.html)
- cargo-ndk: [crates.io](https://crates.io/api/v1/crates/cargo-ndk), [README](https://raw.githubusercontent.com/bbqsrc/cargo-ndk/main/README.md)
- Apple: [dukungan Xcode](https://developer.apple.com/support/xcode/), [catatan rilis Xcode 27.1](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes.md), [catatan rilis Xcode 27](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes.md), [syarat unggah](https://developer.apple.com/news/upcoming-requirements/), [pangsa versi OS](https://developer.apple.com/support/app-store/), [TN3117](https://developer.apple.com/documentation/technotes/tn3117-resolving-build-errors-for-apple-silicon)
- Android build: [catatan rilis AGP](https://developer.android.com/build/releases/gradle-plugin), [kompatibilitas AGP](https://developer.android.com/build/releases/about-agp), [AGP 9.3.0](https://developer.android.com/build/releases/agp-9-3-0-release-notes), [AGP 9.0.0](https://developer.android.com/build/releases/agp-9-0-0-release-notes), [Kotlin bawaan](https://developer.android.com/build/migrate-to-built-in-kotlin), [JDK untuk build](https://developer.android.com/build/jdks)
- Gradle: [rilis](https://gradle.org/releases/), [checksum](https://gradle.org/release-checksums/), [kompatibilitas 9.5](https://docs.gradle.org/9.5.0/userguide/compatibility.html), [kriteria JVM daemon](https://docs.gradle.org/current/userguide/gradle_daemon.html)
- Kotlin: [rilis](https://kotlinlang.org/docs/releases.html), [kompatibilitas Gradle dan AGP](https://kotlinlang.org/docs/gradle-configure-project.html)
- Compose dan AndroidX: [BOM](https://developer.android.com/develop/ui/compose/bom), [compiler](https://developer.android.com/develop/ui/compose/compiler), [versi AndroidX](https://developer.android.com/jetpack/androidx/versions), [activity](https://developer.android.com/jetpack/androidx/releases/activity), [Material 3 adaptive](https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive)
- Android platform: [ukuran halaman 16 KB](https://developer.android.com/guide/practices/page-sizes), [unduhan NDK](https://developer.android.com/ndk/downloads), [ABI](https://developer.android.com/ndk/guides/abis), [target SDK Google Play](https://developer.android.com/google/play/requirements/target-sdk), [perubahan Android 16](https://developer.android.com/about/versions/16/behavior-changes-16), [perubahan Android 17](https://developer.android.com/about/versions/17/behavior-changes-17), [penyiapan SDK Android 17](https://developer.android.com/about/versions/17/setup-sdk)
- Pangsa API level (pihak ketiga): [apilevels.com](https://apilevels.com/)
