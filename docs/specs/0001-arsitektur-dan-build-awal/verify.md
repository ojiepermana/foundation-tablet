# Verify: Arsitektur dan build awal · spec 0001 · diperbarui 2026-11-15

_Langkah diturunkan dari acceptance criteria spec 0001. `/check verify` menjalankannya; `/test` mengunci langkah yang tahan lama. Tiap milestone punya bagiannya sendiri; centang hanya diisi oleh checker._

## Milestone 1: Workspace Rust dan batas crate

Build plan 1 sampai 3. Target host `aarch64-apple-darwin`. Tanpa build native. Kompilasi silang ke empat target matriks (AC-3) diperiksa di milestone 2 dan 3.

Siapkan clone bersih lebih dulu (disarankan), lalu jalankan semua perintah dari akar clone itu:

```bash
CLONE="$(mktemp -d)/tablet"
git clone <path worktree atau repo> "$CLONE"
cd "$CLONE"
```

### Commands

- [x] `rustup toolchain install` → keluar 0; toolchain `1.99.1` beserta `rustfmt`, `clippy`, dan target `aarch64-apple-ios`, `aarch64-apple-ios-sim`, `aarch64-linux-android`, `x86_64-linux-android` terpasang (`rustup target list --installed` memuat keempatnya) → AC-1, AC-8
- [x] `rustc --version` → diawali `rustc 1.99.1` → AC-1, AC-8
- [x] `cargo build --workspace --locked` → keluar 0 → AC-1
- [x] `cargo test --workspace --locked` → keluar 0 (nol tes, `test result: ok`) → AC-1
- [x] `git ls-files Cargo.lock` → menampilkan `Cargo.lock` → AC-1
- [x] `cargo metadata --no-deps --format-version 1 | grep -o '"name":"tablet-[a-z]*"' | sort -u` → tepat `"name":"tablet-core"` dan `"name":"tablet-ffi"` (workspace berisi tepat dua crate) → AC-2
- [x] `cargo tree -p tablet-core -e normal` → satu baris saja: `tablet-core v0.1.0 (...crates/core)` → AC-2
- [x] `cargo tree -p tablet-ffi -e normal --depth 1` → `tablet-ffi v0.1.0`, lalu tepat dua anak: `tablet-core v0.1.0` dan `uniffi v0.32.2` → AC-2
- [x] `ls target/debug/libtablet_ffi.a target/debug/libtablet_ffi.dylib` (sesudah `cargo build`) → kedua file ada → AC-2
- [x] `grep -n 'crate-type' crates/tablet-ffi/Cargo.toml` → `crate-type = ["lib", "staticlib", "cdylib"]` → AC-2
- [x] Periksa kunci versi terhadap tabel "Proposed stack": `rust-toolchain.toml` memuat `channel = "1.99.1"` dan keempat target; `Cargo.toml` akar memuat `resolver = "3"`, `edition = "2024"`, `rust-version = "1.99"`, `uniffi = "=0.32.2"`; `grep -A1 'name = "uniffi"' Cargo.lock` → `version = "0.32.2"` → AC-8 (bagian Rust, Target Rust, UniFFI)
- [x] `git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'` → kosong (keluar 1) → AC-11
- [x] `git status --short` sesudah build dan test → kosong → AC-11
- [x] `.gitignore` akar memuat setiap entri "Aturan commit" spec: `git check-ignore -v target/x apps/ipados/build/x a/xcuserdata/x apps/ipados/Tablet.xcodeproj/project.xcworkspace/x apps/ipados/Config/Local.xcconfig .build/x .swiftpm/x apps/android-tablet/app/build/x apps/android-tablet/build/x apps/android-tablet/.gradle/x apps/android-tablet/.kotlin/x apps/android-tablet/local.properties apps/android-tablet/app/.cxx/x apps/android-tablet/captures/x apps/android-tablet/app/src/main/jniLibs/x bindings/swift/TabletFFI.xcframework/x bindings/swift/Sources/x bindings/kotlin/x .DS_Store .idea/x a.iml` → setiap path tercetak dengan aturan `.gitignore` yang cocok (21 baris) → AC-11
- [x] Sesudah selesai: `cd / && rm -rf "$(dirname "$CLONE")"` → folder sementara terhapus

### Acceptance-criteria coverage

- AC-1: toolchain, `rustc --version`, `cargo build`, `cargo test`, `Cargo.lock` ter-commit
- AC-2: `cargo metadata`, dua `cargo tree`, pustaka `.a` dan `.dylib`, `crate-type`
- AC-8 (bagian Rust): `rustup toolchain install`, `rustc --version`, pemeriksaan kunci versi
- AC-11 (bagian `.gitignore` dan biner): `git ls-files`, `git status --short`, `git check-ignore`

## Milestone 2: Proyek iPad minimal dan skrip build

Build plan 4 dan 5. Target simulator iPad generik (Debug, `aarch64-apple-ios-sim`) dan iPad generik (Release tanpa tanda tangan, `aarch64-apple-ios`), Xcode 27.1, macOS 27.0.1. Butuh milestone 1. Menjalankan aplikasi di iPad fisik bukan bagian milestone ini (MAN-1 di file manual).

Periksa disk lebih dulu (`df -h .`, berhenti bila bebas di bawah 10 GiB), lalu siapkan clone bersih dan jalankan semua perintah dari akarnya:

```bash
CLONE="$(mktemp -d)/tablet"
git clone <path worktree atau repo> "$CLONE"
cd "$CLONE"
P=apps/ipados/build/DerivedData/Build/Products
```

### Commands

- [x] `cat .xcode-version` → `27.1`; `xcodebuild -version` → `Xcode 27.1` → AC-8 (baris Xcode)
- [x] `grep -nE '^(IPHONEOS_DEPLOYMENT_TARGET|SWIFT_VERSION|TARGETED_DEVICE_FAMILY|ARCHS\[sdk=iphonesimulator\*\])' apps/ipados/Config/Base.xcconfig` → `26.0`, `6.0`, `2`, `arm64`; isi file sama persis dengan blok `Base.xcconfig` di spec bagian "Proyek iPad" → AC-8 (baris Xcode dan Swift, iPadOS minimum)
- [x] `plutil -lint apps/ipados/Tablet.xcodeproj/project.pbxproj` → `OK` → AC-5
- [x] `xcodebuild -list -project apps/ipados/Tablet.xcodeproj` → target `Tablet`, konfigurasi `Debug` dan `Release`, skema `Tablet` → AC-5
- [x] `grep -c 'buildSettings = {' apps/ipados/Tablet.xcodeproj/project.pbxproj` → `4`, dan `grep -A1 'buildSettings = {' apps/ipados/Tablet.xcodeproj/project.pbxproj | grep -vE 'buildSettings|^\s*};|^--'` → kosong (semua blok kosong, nilai hanya di xcconfig) → AC-8
- [x] `DEVELOPER_DIR=/tidak/ada scripts/build-ipados.sh; echo $?` → pesan menyebut `DEVELOPER_DIR` dan cara memperbaikinya, kode keluar `1`, tanpa build → AC-8
- [x] `scripts/build-ipados.sh; echo $?` (tanpa argumen) → `** BUILD SUCCEEDED **` dua kali, baris terakhir `build-ipados: selesai`, kode keluar `0` → AC-3, AC-5, AC-6
- [x] `ls target/aarch64-apple-ios/release/libtablet_ffi.a target/aarch64-apple-ios-sim/release/libtablet_ffi.a` → kedua file ada → AC-3 (dua target Apple)
- [x] Simulator: `lipo -archs $P/Debug-iphonesimulator/Tablet.app/Tablet` → `arm64`; `plutil -extract MinimumOSVersion raw $P/Debug-iphonesimulator/Tablet.app/Info.plist` → `26.0`; `plutil -extract UIDeviceFamily json -o - $P/Debug-iphonesimulator/Tablet.app/Info.plist` → `[2]` → AC-5
- [x] Perangkat: tiga perintah yang sama pada `$P/Release-iphoneos/Tablet.app` → `arm64`, `26.0`, `[2]`; `codesign -dv $P/Release-iphoneos/Tablet.app` → `code object is not signed at all` → AC-6
- [x] `nm $P/Release-iphoneos/Tablet.app/Tablet | grep -ci uniffi` → `0` (pustaka Rust belum ditautkan) → AC-11
- [x] `cat apps/ipados/Tablet/App/TabletApp.swift` → satu `@main` `App` dengan `WindowGroup` berisi satu `Text` statis, tanpa navigasi, token, atau lokalisasi → AC-11
- [x] `git ls-files apps/ipados scripts .xcode-version` → tepat enam file: `.xcode-version`, `apps/ipados/Config/Base.xcconfig`, `apps/ipados/Tablet.xcodeproj/project.pbxproj`, `apps/ipados/Tablet.xcodeproj/xcshareddata/xcschemes/Tablet.xcscheme`, `apps/ipados/Tablet/App/TabletApp.swift`, `scripts/build-ipados.sh` (tanpa folder atau file penanda) → AC-11
- [x] `git ls-files -s scripts/build-ipados.sh` → mode `100755` → AC-9 (bagian skrip iPad)
- [x] `git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'` → kosong → AC-11
- [x] `git status --short` sesudah skrip → kosong → AC-11
- [x] Sesudah selesai: `cd / && rm -rf "$(dirname "$CLONE")"` → clone, `target/`, dan `apps/ipados/build/` di dalamnya terhapus

### Acceptance-criteria coverage

- AC-3 (dua target Apple): dua file `libtablet_ffi.a` sesudah skrip tanpa argumen
- AC-5: `plutil -lint`, `xcodebuild -list`, build simulator, tiga bukti pada app Debug simulator
- AC-6: build perangkat, tiga bukti pada app Release, `codesign` tanpa tanda tangan
- AC-8 (bagian iPad): `.xcode-version`, isi `Base.xcconfig`, blok `buildSettings` kosong, percobaan `DEVELOPER_DIR=/tidak/ada`
- AC-11 (sisi iPad): satu layar SwiftUI statis, tidak menautkan pustaka Rust, tanpa penanda tempat, tanpa biner ter-commit, `git status --short` kosong

Bukti build dari clone bersih oleh developer: [docs/reviews/2026-11-15-build-f01-m2.md](../../reviews/2026-11-15-build-f01-m2.md).

## Milestone 3: Proyek Android minimal dan skrip build

Build plan 6 sampai 8. Target APK debug untuk ABI `arm64-v8a` dan `x86_64` (`minSdk` 29, `targetSdk` 36, `compileSdk` 37), pustaka Rust `aarch64-linux-android` dan `x86_64-linux-android`, host macOS 27.0.1. Butuh milestone 1 dan `cargo-ndk` 4.1.2 (`cargo install cargo-ndk --version 4.1.2 --locked`). Menjalankan APK di emulator milik fitur 04; di tablet fisik dan perangkat 16 KB adalah MAN-2 dan MAN-3 di file manual.

Periksa disk lebih dulu (`df -h .`, berhenti bila bebas di bawah 10 GiB) dan pastikan tidak ada build Xcode lain (`pgrep -x xcodebuild` kosong). Biarkan `ANDROID_HOME` dan `JAVA_HOME` tidak diset supaya jalur bawaan skrip ikut teruji. Siapkan clone bersih dan jalankan semua perintah dari akarnya:

```bash
CLONE="$(mktemp -d)/tablet"
git clone <path worktree atau repo> "$CLONE"
cd "$CLONE"
SDK="$HOME/Library/Android/sdk"
OBJDUMP="$SDK/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump"
APK=apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk
JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

### Commands

- [ ] `cat apps/android-tablet/gradle/libs.versions.toml` → `agp = "9.3.3"`, `kotlin = "2.4.21"`, `composeBom = "2026.09.00"`, `activityCompose = "1.13.0"`, `compileSdk = "37"`, `minSdk = "29"`, `targetSdk = "36"`, `ndk = "28.2.13676358"`; `material3` tanpa versi; plugin `compose-compiler` memakai `version.ref = "kotlin"` → AC-8 (baris AGP, Kotlin, Compose compiler, Compose, Android SDK, NDK)
- [ ] `cat apps/android-tablet/gradle/wrapper/gradle-wrapper.properties` → `distributionUrl` menunjuk `gradle-9.5.1-bin.zip` dan `distributionSha256Sum=bafc141b619ad6350fd975fc903156dd5c151998cc8b058e8c1044ab5f7b031f` → AC-8 (baris Gradle)
- [ ] `shasum -a 256 apps/android-tablet/gradle/wrapper/gradle-wrapper.jar` → sama dengan isi https://services.gradle.org/distributions/gradle-9.5.1-wrapper.jar.sha256 (`497c8c2a7e5031f6aa847f88104aa80a93532ec32ee17bdb8d1d2f67a194a9c7` pada 2026-11-15) → AC-8
- [ ] `cat apps/android-tablet/gradle/gradle-daemon-jvm.properties` → tepat `toolchainVersion=25` → AC-8 (baris JDK)
- [ ] `cat apps/android-tablet/gradle.properties` → sama persis dengan blok `gradle.properties` di spec bagian "Proyek Android" → AC-8
- [ ] `grep -nE 'compileSdk|minSdk|targetSdk|ndkVersion|abiFilters|applicationId|JVM_17|VERSION_17' apps/android-tablet/app/build.gradle.kts` → semua angka dibaca dari `libs.versions.*` atau `providers.gradleProperty(...)`, tanpa angka SDK literal; Java dan `jvmTarget` 17 → AC-8 (sumber nilai)
- [ ] `E="$(mktemp -d)"; ANDROID_HOME="$E" scripts/build-android-tablet.sh; echo $?` → pesan menyebut platform Android 37 yang hilang dan perintah `sdkmanager` untuk memasangnya, kode keluar `1`, tanpa build → AC-8
- [ ] `JAVA_HOME=/tidak/ada scripts/build-android-tablet.sh; echo $?` → pesan menyebut `JAVA_HOME` dan cara menyetelnya ke JDK 25, kode keluar `1`, tanpa build → AC-8
- [ ] `scripts/build-android-tablet.sh; echo $?` → baris awal menyebut SDK `~/Library/Android/sdk`, NDK `28.2.13676358`, `minSdk 29`, ABI `arm64-v8a,x86_64`, dan `openjdk version "25.`; lalu `BUILD SUCCESSFUL`, baris terakhir `build-android-tablet: selesai`, kode keluar `0` → AC-7, AC-8
- [ ] `ls target/aarch64-linux-android/release/libtablet_ffi.so target/x86_64-linux-android/release/libtablet_ffi.so` → kedua file ada → AC-3 (dua target Android)
- [ ] `"$OBJDUMP" -p target/aarch64-linux-android/release/libtablet_ffi.so | grep LOAD` dan perintah yang sama untuk `x86_64-linux-android` → setiap baris berakhir `align 2**14` → AC-4
- [ ] `"$SDK/build-tools/36.0.0/aapt2" dump badging "$APK" | grep -E 'SdkVersion|compileSdkVersion='` → `minSdkVersion:'29'`, `targetSdkVersion:'36'`, `compileSdkVersion='37'` (aapt2 36.0.0 menulis `minSdkVersion`, teks AC menyebut `sdkVersion`) → AC-7
- [ ] `unzip -l "$APK" | grep 'lib/'` → hanya path di bawah `lib/arm64-v8a/` dan `lib/x86_64/` (saat ini `libandroidx.graphics.path.so` dari Compose) → AC-7
- [ ] `unzip -l "$APK" | grep libtablet_ffi` → kosong (keluar 1) → AC-11
- [ ] `(cd apps/android-tablet && JAVA_HOME="$JBR" ./gradlew -q buildEnvironment | grep 'kotlin-gradle-plugin:2.4.21')` → minimal satu baris `org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21`; tidak ada versi Kotlin lain yang menang (baris `2.2.10 -> 2.4.21` berarti dinaikkan ke versi katalog) → AC-8 (baris Kotlin)
- [ ] `cat apps/android-tablet/app/src/main/kotlin/foundation/tablet/MainActivity.kt apps/android-tablet/app/src/main/AndroidManifest.xml apps/android-tablet/app/src/main/res/values/strings.xml` → `ComponentActivity` dengan `enableEdgeToEdge()` lalu `setContent { MaterialTheme { Text(...) } }`; satu activity `exported` dengan filter LAUNCHER, tema `@android:style/Theme.Material.Light.NoActionBar`, tanpa `screenOrientation` atau `resizeableActivity`; `strings.xml` hanya `app_name` = `Tablet`; tanpa navigasi, token, atau lokalisasi → AC-11
- [ ] `git ls-files apps/android-tablet scripts/build-android-tablet.sh` → tepat 14 file yang tercantum di spec bagian "Struktur repo fitur 01" untuk Android dan skripnya, tanpa folder atau file penanda → AC-11
- [ ] `git ls-files -s scripts apps/android-tablet/gradlew` → mode `100755` untuk `scripts/build-android-tablet.sh`, `scripts/build-ipados.sh`, dan `apps/android-tablet/gradlew` → AC-9 (bagian mode berkas)
- [ ] `git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'` → kosong; `git ls-files -z | xargs -0 file --mime-encoding | grep -w binary` → hanya `gradle-wrapper.jar` → AC-11
- [ ] `git status --short` sesudah skrip → kosong → AC-11
- [ ] Sesudah selesai: `(cd apps/android-tablet && JAVA_HOME="$JBR" ./gradlew --stop)`, lalu `cd / && rm -rf "$(dirname "$CLONE")"` → daemon mati, clone beserta `target/` dan folder `build/` di dalamnya terhapus

### Acceptance-criteria coverage

- AC-3 (dua target Android): dua file `libtablet_ffi.so` sesudah skrip
- AC-4: `llvm-objdump -p ... | grep LOAD` untuk kedua `.so`
- AC-7: skrip keluar 0, `aapt2 dump badging`, `unzip -l ... | grep 'lib/'`
- AC-8 (bagian Android): katalog versi, wrapper dan checksum, `gradle-daemon-jvm.properties`, `gradle.properties`, sumber nilai di `app/build.gradle.kts`, `buildEnvironment`, percobaan `ANDROID_HOME=<folder kosong>` dan `JAVA_HOME=/tidak/ada`
- AC-9 (bagian mode berkas): `git ls-files -s`
- AC-11 (sisi Android): satu layar Compose statis, `libtablet_ffi` tidak ada di APK, tanpa penanda tempat, satu satunya biner `gradle-wrapper.jar`, `git status --short` kosong

Bukti build dari clone bersih oleh developer: [docs/reviews/2026-11-15-build-f01-m3.md](../../reviews/2026-11-15-build-f01-m3.md).

## Milestone 4: Panduan mulai singkat dan catatan arsitektur

Build plan 9, 10, dan 11. Target sama dengan milestone 1 sampai 3: host macOS 27.0.1 (Mac Apple silicon), Xcode 27.1, simulator iPad generik dan iPad generik tanpa tanda tangan, APK debug `arm64-v8a` dan `x86_64`. Butuh milestone 1, 2, dan 3. Langkah ini mengikuti `docs/getting-started.md` apa adanya pada clone baru: jangan menjalankan perintah lain di antara perintah panduan selain pemeriksaan bukti di bawah.

Periksa disk lebih dulu (`df -h .`, berhenti bila bebas di bawah 10 GiB) dan pastikan tidak ada build native lain (`pgrep -x xcodebuild` dan `pgrep -f build-android-tablet.sh` kosong). Biarkan `ANDROID_HOME` dan `JAVA_HOME` tidak diset, seperti mesin yang memasang SDK dan Android Studio di lokasi bawaannya. Siapkan clone bersih dan jalankan semua perintah dari akarnya:

```bash
CLONE="$(mktemp -d)/tablet"
git clone <path worktree atau repo> "$CLONE"
cd "$CLONE"
P=apps/ipados/build/DerivedData/Build/Products
SDK="$HOME/Library/Android/sdk"
APK=apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk
LOG_IPAD="$(dirname "$CLONE")/build-ipados.log"
```

### Commands

Tugas 11, satu baris `Base.xcconfig`:

- [ ] `awk '/^SDKROOT = iphoneos/{f=1} f{print} /^#include\? "Local.xcconfig"/{if(f)exit}' docs/specs/0001-arsitektur-dan-build-awal/index.md | diff - apps/ipados/Config/Base.xcconfig; echo $?` → tanpa selisih, kode keluar `0` (isi file sama persis dengan blok spec bagian "Proyek iPad", termasuk `ALWAYS_SEARCH_USER_PATHS = NO` sesudah `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO`) → AC-8
- [ ] `git diff 610cefb -- apps/ipados/Config/Base.xcconfig` (`610cefb` adalah `main` sesudah milestone 3) → selisih hanya satu baris tambahan `+ALWAYS_SEARCH_USER_PATHS = NO`, tanpa baris lain yang berubah → AC-8

Tugas 9, perintah panduan pada clone baru (perintah persis dari `docs/getting-started.md` bagian "Perintah repo", berurutan):

- [ ] `grep -A8 '^## Perintah repo' docs/getting-started.md` → blok `bash` berisi tepat enam baris yang sama dengan spec bagian "Perintah repo": `rustup toolchain install`, `cargo install cargo-ndk --version 4.1.2 --locked`, `cargo build --workspace --locked`, `cargo test --workspace --locked`, `scripts/build-ipados.sh`, `scripts/build-android-tablet.sh` → AC-9
- [ ] `rustup toolchain install; echo $?` → kode keluar `0`; lalu `rustc --version` → diawali `rustc 1.99.1` → AC-1, AC-9
- [ ] `cargo install cargo-ndk --version 4.1.2 --locked; echo $?` → kode keluar `0` (bila sudah terpasang, Cargo mencetak bahwa paket sudah terpasang dan tetap keluar `0`) → AC-9
- [ ] `cargo build --workspace --locked; echo $?` → kode keluar `0` → AC-1, AC-9
- [ ] `cargo test --workspace --locked; echo $?` → `test result: ok`, kode keluar `0` → AC-1, AC-9
- [ ] `scripts/build-ipados.sh > "$LOG_IPAD" 2>&1; echo $?` → kode keluar `0`; `grep -c 'BUILD SUCCEEDED' "$LOG_IPAD"` → `2`; `tail -1 "$LOG_IPAD"` → `build-ipados: selesai` → AC-3, AC-5, AC-6, AC-9
- [ ] `grep -c 'Traditional headermap' "$LOG_IPAD"` → `0` → AC-5, AC-6 (tugas 11)
- [ ] Simulator: `lipo -archs $P/Debug-iphonesimulator/Tablet.app/Tablet` → `arm64`; `plutil -extract MinimumOSVersion raw $P/Debug-iphonesimulator/Tablet.app/Info.plist` → `26.0`; `plutil -extract UIDeviceFamily json -o - $P/Debug-iphonesimulator/Tablet.app/Info.plist` → `[2]` → AC-5
- [ ] Perangkat: tiga perintah yang sama pada `$P/Release-iphoneos/Tablet.app` → `arm64`, `26.0`, `[2]`; `codesign -dv $P/Release-iphoneos/Tablet.app` → `code object is not signed at all` → AC-6
- [ ] `scripts/build-android-tablet.sh; echo $?` (sesudah build iPad selesai, tidak bersamaan) → `BUILD SUCCESSFUL`, baris terakhir `build-android-tablet: selesai`, kode keluar `0` → AC-7, AC-9
- [ ] `ls target/aarch64-apple-ios/release/libtablet_ffi.a target/aarch64-apple-ios-sim/release/libtablet_ffi.a target/aarch64-linux-android/release/libtablet_ffi.so target/x86_64-linux-android/release/libtablet_ffi.so` → keempat file ada → AC-3
- [ ] `"$SDK/build-tools/36.0.0/aapt2" dump badging "$APK" | grep -E 'SdkVersion|compileSdkVersion='` → `minSdkVersion:'29'`, `targetSdkVersion:'36'`, `compileSdkVersion='37'`; `unzip -l "$APK" | grep 'lib/'` → hanya `lib/arm64-v8a/` dan `lib/x86_64/` → AC-7
- [ ] `git ls-files -s scripts apps/android-tablet/gradlew` → mode `100755` untuk `apps/android-tablet/gradlew`, `scripts/build-android-tablet.sh`, dan `scripts/build-ipados.sh` → AC-9
- [ ] `git status --short` sesudah kedua skrip → kosong → AC-9, AC-11
- [ ] Tidak ada langkah di luar panduan yang ternyata diperlukan (catat di bukti bila ada; itu berarti panduan harus diperbaiki) → AC-9

Tugas 9 dan 10, isi dokumen terhadap tabel spec bagian "Catatan arsitektur yang ditulis developer":

- [ ] `docs/getting-started.md` memuat: prasyarat dan versinya (macOS 26.6, Xcode 27.1, rustup dengan `rust-toolchain.toml`, Android SDK `platforms;android-37.0` `build-tools;36.0.0` `platform-tools` `ndk;28.2.13676358`, JDK 25, `cargo-ndk` 4.1.2), cara memasang tiap prasyarat, enam perintah "Perintah repo", lokasi hasil build, dan masalah umum (JDK, `ANDROID_HOME`, target Rust) → AC-9
- [ ] `docs/architecture/overview.md` memuat: lapisan A sampai E README bagian 3 dengan keadaan yang sudah dibangun, tautan ke empat dokumen lain, dan daftar "Ditetapkan, belum dibangun" (pengemasan pustaka iPad dan Android, lokasi binding, nama modul) → AC-10
- [ ] `docs/architecture/support-matrix.md` memuat: tabel "Proposed stack" dan "Matriks dukungan" spec dengan nilai yang sama, target yang tidak didukung beserta alasan, alasan OS minimum, status 16 KB, tanggal pemeriksaan `2026-11-15`, dan tautan sumber dari `rationale.md` bagian References → AC-10
- [ ] `docs/architecture/ownership-matrix.md` memuat: setiap baris tabel spec "Pemilik tiap bagian" → AC-10
- [ ] `docs/architecture/dependency-rules.md` memuat: diagram dan tujuh aturan spec "Arah dependensi" dengan teks yang sama → AC-10
- [ ] `docs/architecture/repository-structure.md` memuat: struktur repo yang sama dengan `git ls-files` dan setiap baris tabel spec "Penyimpangan dari README bagian 5" → AC-10
- [ ] Angka versi di dokumen sama dengan file repo: `cat rust-toolchain.toml .xcode-version apps/android-tablet/gradle/libs.versions.toml apps/android-tablet/gradle/wrapper/gradle-wrapper.properties apps/android-tablet/gradle/gradle-daemon-jvm.properties` lalu bandingkan dengan `support-matrix.md` dan `getting-started.md` → AC-9, AC-10
- [ ] Setiap tautan relatif di keenam dokumen menunjuk file yang ada: `for f in docs/getting-started.md docs/architecture/*.md; do d=$(dirname "$f"); grep -o '](\([^)#h][^)]*\))' "$f" | sed 's/](\(.*\))/\1/; s/#.*//' | sort -u | while read -r p; do [ -e "$d/$p" ] || echo "HILANG $f -> $p"; done; done` → tanpa keluaran → AC-9, AC-10
- [ ] `ls docs/architecture` → tepat lima file: `dependency-rules.md`, `overview.md`, `ownership-matrix.md`, `repository-structure.md`, `support-matrix.md` (tanpa `boundaries.md`, tanpa penanda) → AC-10, AC-11
- [ ] Sesudah selesai: `(cd apps/android-tablet && JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew --stop)`, lalu `cd / && rm -rf "$(dirname "$CLONE")"` → daemon mati, clone dan log terhapus

### Acceptance-criteria coverage

- AC-1: `rustup toolchain install`, `rustc --version`, `cargo build`, `cargo test` dari panduan
- AC-3: empat pustaka sesudah kedua skrip dari panduan
- AC-5, AC-6: build iPad dari panduan, bukti pada kedua app, `grep -c 'Traditional headermap'` = `0` (tugas 11)
- AC-7: build Android dari panduan, `aapt2` dan `unzip -l`
- AC-8: `Base.xcconfig` sama persis dengan blok spec, selisih satu baris (tugas 11)
- AC-9: panduan memuat isi wajib, enam perintah persis, clone baru tanpa langkah lain, mode `100755`, `git status --short` kosong
- AC-10: lima dokumen `docs/architecture/` dengan isi wajib tabel spec, tanda "ditetapkan, belum dibangun", tautan valid
