# Panduan mulai singkat

Panduan ini membawa kamu dari clone baru sampai workspace Rust, aplikasi iPad, dan aplikasi Android tablet selesai dikompilasi. Semua perintah dijalankan dari akar repo. Keputusan di baliknya ada di [spec 0001](specs/0001-arsitektur-dan-build-awal/index.md); versi tiap alat dan alasannya ada di [matriks dukungan](architecture/support-matrix.md).

Pada fitur 01 kedua aplikasi baru menampilkan satu layar statis. Pustaka Rust sudah dibangun untuk tiap target, tetapi belum ditautkan ke aplikasi (itu milik fitur 03 dan 04).

## Prasyarat

| Prasyarat | Versi | Dikunci di |
| --- | --- | --- |
| Mac Apple silicon | macOS 26.6 atau lebih baru | syarat Xcode 27.1 |
| Xcode | 27.1, terpilih lewat `xcode-select` (27.x yang lebih baru boleh, skrip memberi peringatan) | `.xcode-version` |
| `rustup` | versi apa saja yang membaca `rust-toolchain.toml` | toolchain 1.99.1 dan empat target di `rust-toolchain.toml` |
| Android SDK | `platforms;android-37.0`, `build-tools;36.0.0`, `platform-tools`, `ndk;28.2.13676358` | `apps/android-tablet/gradle/libs.versions.toml` |
| JDK | 25 | `apps/android-tablet/gradle/gradle-daemon-jvm.properties` |
| `cargo-ndk` | 4.1.2 | dicek `scripts/build-android-tablet.sh` |

Gradle tidak perlu dipasang. Wrapper di `apps/android-tablet/gradlew` mengunduh Gradle 9.5.1 sendiri dan mencocokkan checksumnya.

## Cara memasang prasyarat

Kamu cukup memasang yang belum ada.

1. **Xcode 27.1.** Pasang dari App Store atau dari halaman unduhan Apple Developer, buka sekali untuk menyelesaikan pemasangan komponen, lalu pilih:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

   Periksa dengan `xcodebuild -version`; baris pertama harus `Xcode 27.1`.

2. **rustup.** Pasang dari <https://rustup.rs>, lalu buka terminal baru supaya `cargo` dan `rustup` masuk ke `PATH`. Toolchain 1.99.1 beserta `rustfmt`, `clippy`, dan keempat target (`aarch64-apple-ios`, `aarch64-apple-ios-sim`, `aarch64-linux-android`, `x86_64-linux-android`) dipasang oleh perintah pertama di bagian "Perintah repo", karena rustup membaca `rust-toolchain.toml`.

3. **Android SDK.** Cara termudah adalah Android Studio: buka Settings, lalu Languages & Frameworks, lalu Android SDK. Di tab SDK Platforms centang Android 37.0. Di tab SDK Tools nyalakan Show Package Details, lalu centang Android SDK Build Tools 36.0.0, Android SDK Platform Tools, dan NDK 28.2.13676358. Lokasi bawaan SDK adalah `~/Library/Android/sdk`. Bila kamu memakai `sdkmanager`:

   ```bash
   "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platforms;android-37.0" "build-tools;36.0.0" "platform-tools" "ndk;28.2.13676358"
   ```

   Skrip memakai `ANDROID_HOME` bila diset, dan mencoba `~/Library/Android/sdk` bila tidak. Kamu hanya perlu menyetel `ANDROID_HOME` bila SDK ada di folder lain.

4. **JDK 25.** JBR bawaan Android Studio (`/Applications/Android Studio.app/Contents/jbr/Contents/Home`) sudah JDK 25. Skrip memakai `JAVA_HOME` bila diset, dan mencoba folder JBR itu bila tidak. Kamu hanya perlu menyetel `JAVA_HOME` bila JDK 25 ada di tempat lain.

5. **cargo-ndk 4.1.2.** Dipasang oleh perintah kedua di bagian "Perintah repo" (sekitar setengah menit).

## Perintah repo

Dari akar clone, dalam urutan ini:

```bash
rustup toolchain install
cargo install cargo-ndk --version 4.1.2 --locked
cargo build --workspace --locked
cargo test --workspace --locked
scripts/build-ipados.sh
scripts/build-android-tablet.sh
```

Yang terjadi pada tiap baris:

1. `rustup toolchain install` memasang toolchain 1.99.1, komponen, dan keempat target dari `rust-toolchain.toml`. Sesudahnya `rustc --version` di akar repo menampilkan `rustc 1.99.1`.
2. `cargo install cargo-ndk --version 4.1.2 --locked` memasang `cargo-ndk`, yang menyiapkan linker NDK untuk Cargo.
3. `cargo build --workspace --locked` mengompilasi `tablet-core` dan `tablet-ffi` untuk Mac.
4. `cargo test --workspace --locked` menjalankan tes workspace. Pada fitur 01 belum ada tes, jadi hasilnya `test result: ok` dengan nol tes.
5. `scripts/build-ipados.sh` membangun `tablet-ffi` untuk `aarch64-apple-ios-sim` dan `aarch64-apple-ios`, lalu `Tablet.app` Debug untuk simulator iPad generik dan `Tablet.app` Release untuk iPad generik tanpa tanda tangan kode. Kamu bisa membangun salah satunya saja dengan `--simulator` atau `--device`.
6. `scripts/build-android-tablet.sh` membangun `tablet-ffi` untuk `arm64-v8a` dan `x86_64` lewat `cargo-ndk`, lalu `app-debug.apk` lewat `./gradlew :app:assembleDebug`. Build pertama mengunduh Gradle 9.5.1 (sekitar 151 MB) ke `~/.gradle/wrapper/dists` dan dependensi Maven ke `~/.gradle/caches`.

Kedua skrip bisa dipanggil dari folder mana pun karena pindah ke akar repo lebih dulu. Bila prasyarat kurang, skrip berhenti sebelum build dengan pesan yang menyebut apa yang hilang dan cara memasangnya.

## Lokasi hasil build

Semua hasil ada di folder yang diabaikan Git, jadi `git status --short` tetap kosong sesudah kedua skrip.

| Hasil | Path |
| --- | --- |
| Pustaka Rust untuk Mac | `target/debug/libtablet_ffi.a`, `target/debug/libtablet_ffi.dylib` |
| Pustaka Rust iPad perangkat | `target/aarch64-apple-ios/release/libtablet_ffi.a` |
| Pustaka Rust iPad simulator | `target/aarch64-apple-ios-sim/release/libtablet_ffi.a` |
| Pustaka Rust Android arm64 | `target/aarch64-linux-android/release/libtablet_ffi.so` |
| Pustaka Rust Android x86_64 | `target/x86_64-linux-android/release/libtablet_ffi.so` |
| Aplikasi iPad simulator | `apps/ipados/build/DerivedData/Build/Products/Debug-iphonesimulator/Tablet.app` |
| Aplikasi iPad perangkat, tanpa tanda tangan | `apps/ipados/build/DerivedData/Build/Products/Release-iphoneos/Tablet.app` |
| APK Android debug | `apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk` |

Untuk mengosongkan lagi, kamu bisa menghapus `target/`, `apps/ipados/build/`, dan `apps/android-tablet/app/build/`, lalu mematikan daemon Gradle dengan `(cd apps/android-tablet && ./gradlew --stop)`.

## Masalah umum

- **`java` di `PATH` tidak dipakai.** Di macOS, `/usr/bin/java` bisa berupa stub yang hanya meminta kamu memasang Java. Skrip Android tidak memanggilnya; skrip memakai `"$JAVA_HOME/bin/java"`. Bila skrip berhenti dengan `java tidak ditemukan di JAVA_HOME` atau `repo ini butuh JDK 25`, set `JAVA_HOME` ke JDK 25, misalnya `export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`. Bila kamu menjalankan `./gradlew` langsung (bukan lewat skrip), set `JAVA_HOME` dulu dengan cara yang sama, karena Gradle tidak mencari JBR di dalam Android Studio.
- **Jangan set `JAVA_HOME=/usr`.** `JAVA_HOME` harus menunjuk JDK 25 yang nyata (misalnya JBR Android Studio di atas) atau tidak diset sama sekali. Dengan `/usr`, skrip memanggil stub `/usr/bin/java -version` milik macOS. Stub itu bisa diam lebih dari dua menit sebelum skrip akhirnya mencetak pesan perbaikan dan keluar dengan kode 1. Bila skrip Android tampak macet di awal, periksa `echo "$JAVA_HOME"` dulu.
- **`ANDROID_HOME` salah atau komponen SDK hilang.** Pesan `folder Android SDK tidak ada`, `platform Android 37 tidak ada`, atau `NDK 28.2.13676358 tidak ada` menyebut perintah `sdkmanager` untuk memasangnya. `gradle.properties` memuat `android.builder.sdkDownload=false`, jadi Gradle tidak mengunduh komponen SDK diam diam; komponen yang kurang membuat build gagal dengan jelas.
- **Target Rust belum terpasang.** Pesan `target Rust <triple> belum terpasang` muncul bila `rustup toolchain install` belum dijalankan di akar repo. Jalankan perintah itu, atau `rustup target add <triple>` untuk satu target saja.
- **`cargo-ndk` tidak ditemukan atau versinya lain.** Jalankan `cargo install cargo-ndk --version 4.1.2 --locked`.
- **Xcode yang aktif adalah Command Line Tools atau versi lain.** Jalankan `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. Bila `DEVELOPER_DIR` diset ke folder yang tidak ada, hapus dengan `unset DEVELOPER_DIR`. Bila `xcodebuild -version` gagal, buka Xcode sekali dan terima lisensinya (`sudo xcodebuild -license accept`).
- **Sesudah mengubah `IPHONEOS_DEPLOYMENT_TARGET`.** Jalankan `cargo clean` sebelum membangun lagi supaya pustaka Apple dikompilasi ulang dengan OS minimum yang baru.
- **Membuka proyek di IDE.** Proyek Xcode dan Gradle tidak pernah memanggil Cargo. Mulai fitur 04, jalankan skrip dulu sesudah mengubah Rust, baru bangun dari Xcode atau Android Studio.

## Yang belum dicakup panduan ini

- Menjalankan aplikasi di simulator atau emulator ditambahkan fitur 04.
- Uji di iPad dan tablet Android fisik belum dijalankan. Langkahnya ada di [file manual koordinasi](scope/coordination/01-arsitektur-dan-build-awal.manual.md) sebagai `F01-1` sampai `F01-3`. iPad fisik butuh Team ID Apple dan bundle ID asli di `apps/ipados/Config/Local.xcconfig` (file itu tidak di-commit).
