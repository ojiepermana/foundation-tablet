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
