# Verify: Kontrak Rust untuk kedua aplikasi · spec 0002 · diperbarui 2026-11-16

_Langkah diturunkan dari acceptance criteria spec 0002. `/check verify` menjalankannya; `/test` mengunci langkah yang tahan lama. Centang hanya diisi oleh checker._

Jalankan dari akar repo. Disarankan pada clone baru (`git clone` ke folder sementara), supaya tidak ada pustaka atau binding lama yang ikut terbaca.

## Commands

### Inti dan ekspor

- [x] `cargo test --workspace --locked` → keluar 0; `tablet-core` menjalankan 4 tes (`greets_ayu`, `greets_bima`, `empty_name_still_greets`, `keeps_non_ascii_name_unchanged`) dan `tablet-ffi` 1 tes (`exported_hello_returns_core_greeting`) → AC-1, AC-2
- [x] `grep -c '^pub fn' crates/core/src/lib.rs` → `1`, dan baris itu `pub fn hello(name: String) -> String {` → AC-1
- [x] `cargo tree -p tablet-core -e normal` → satu baris saja → AC-1
- [x] `grep -n 'uniffi::export' -A3 crates/tablet-ffi/src/lib.rs` → satu ekspor `pub fn hello(name: String) -> String` yang badannya hanya `tablet_core::hello(name)`; `git ls-files '*.udl'` kosong → AC-2

### Generator dan batas

- [x] `grep -c '^name = "uniffi"$' Cargo.lock` → `1`, dan versinya sama dengan pin `uniffi` di `Cargo.toml` → AC-3
- [x] `cargo tree -p tablet-ffi -e normal --target aarch64-apple-ios | grep -c clap` dan sama untuk `--target aarch64-linux-android` → `0` → AC-3
- [x] Di antara `git ls-files '*Cargo.toml'` (ditambah `tooling/uniffi-bindgen/Cargo.toml` bila belum di-commit) selain `Cargo.toml` akar, yang memuat `uniffi` tepat `crates/tablet-ffi/Cargo.toml` dan `tooling/uniffi-bindgen/Cargo.toml` → AC-3

### Swift

- [x] `scripts/build-ipados.sh` → keluar 0 → prasyarat AC-4
- [x] `scripts/generate-bindings.sh swift target/aarch64-apple-ios/release/libtablet_ffi.a target/aarch64-apple-ios-sim/release/libtablet_ffi.a` → keluar 0, mencetak tiga file, baris terakhir `generate-bindings: selesai` → AC-4
- [x] `find bindings/swift target/bindings -type f` → tepat `bindings/swift/Sources/TabletBindings/TabletBindings.swift`, `target/bindings/swift/headers/TabletFFI/TabletFFI.h`, `target/bindings/swift/headers/TabletFFI/module.modulemap` → AC-4
- [x] `cat target/bindings/swift/headers/TabletFFI/module.modulemap` → `module TabletFFI {` dan `header "TabletFFI.h"`; `grep -F 'public func hello(name: String) -> String' bindings/swift/Sources/TabletBindings/TabletBindings.swift` → satu baris → AC-4
- [x] Dengan `DT` dari `IPHONEOS_DEPLOYMENT_TARGET` di `apps/ipados/Config/Base.xcconfig`: `xcrun swiftc -typecheck -swift-version 6 -module-name TabletBindings -target arm64-apple-ios${DT}-simulator -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -I target/bindings/swift/headers bindings/swift/Sources/TabletBindings/TabletBindings.swift` → keluar 0; ulangi dengan `-target arm64-apple-ios${DT}` dan `--sdk iphoneos` → keluar 0 → AC-4

### Kotlin

- [x] `scripts/build-android-tablet.sh` → keluar 0 → prasyarat AC-5
- [x] `scripts/generate-bindings.sh kotlin target/aarch64-linux-android/release/libtablet_ffi.so target/x86_64-linux-android/release/libtablet_ffi.so` → keluar 0; `find bindings/kotlin -type f` → tepat `bindings/kotlin/foundation/tablet/bindings/tablet_ffi.kt` → AC-5
- [x] `grep -F` pada file itu menemukan keempat string: `package foundation.tablet.bindings`, `import com.sun.jna.Native`, `findLibraryName(componentName = "tablet_ffi")`, ``fun `hello`(`name`: kotlin.String): kotlin.String`` → AC-5
- [ ] Kompilasi Kotlin: catat `NOT_RUN` (dibuktikan fitur 04) → AC-5

### Bisa diulang

- [x] Simpan `shasum -a 256` keempat file hasil, jalankan kedua perintah generasi lagi, bandingkan → identik → AC-6
- [x] `git status --short` sebelum dan sesudah generasi → sama → AC-6
- [x] Taruh `bindings/swift/Package.swift` tiruan dan `bindings/swift/Sources/TabletBindings/asing.txt`, jalankan generasi `swift` → `asing.txt` hilang, `Package.swift` tetap; hapus tiruannya → AC-6
- [x] `grep -n -- '--no-format --metadata-no-deps' scripts/generate-bindings.sh` → satu pemanggilan generator → AC-6

### Galat skrip

- [x] `scripts/generate-bindings.sh --help` → keluar 0 → AC-7
- [x] Masing masing keluar 1 dengan kata kunci tabel "Pesan galat skrip": tanpa argumen (`bahasa tidak disebut`), `python` (`bahasa tidak dikenal`), `swift` saja (`pustaka tidak disebut`), path tidak ada (`pustaka tidak ada`), `.so` untuk `swift` dan `.a` untuk `kotlin` (`pustaka tidak sah`), path di luar `target/` (`pustaka tidak sah`), pustaka disebut dua kali (`pustaka ganda`), `CARGO_TARGET_DIR=/tmp/x` (`target-dir`), `PATH=/usr/bin:/bin` (`cargo tidak ditemukan`) → AC-7
- [x] `touch crates/core/src/lib.rs`, lalu generasi `swift` → keluar 1 dengan `pustaka basi` dan path `crates/core/src/lib.rs`, binding lama tidak berubah; `touch crates/tablet-ffi/uniffi.toml` saja tidak membuat skrip gagal → AC-7

### Dokumen dan gerbang

- [x] `docs/contracts/ffi-conventions.md` punya bagian untuk tiap topik "Isi konvensi kontrak" spec 0002; topik yang belum dipakai ditandai "ditetapkan, belum dipakai"; tanpa entitas bisnis → AC-8
- [x] Tiap baris "Kalimat dokumen yang diperbarui" spec 0002 sudah diperbarui; matriks pemilik memuat kelima baris AC-9; `docs/getting-started.md` punya bagian "Menghasilkan binding"; `docs/contributing.md` menautkan konvensi → AC-9
- [x] `cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked`, `scripts/test.sh` → semuanya keluar 0 → AC-10
- [ ] Sesudah commit: `git ls-files -s scripts/generate-bindings.sh` → mode `100755` → AC-10

## Acceptance-criteria coverage

- AC-1: inti dan ekspor 1 sampai 3 · AC-2: inti dan ekspor 1, 4 · AC-3: generator dan batas 1 sampai 3 · AC-4: Swift 1 sampai 5 · AC-5: Kotlin 1 sampai 4 · AC-6: bisa diulang 1 sampai 4 · AC-7: galat skrip 1 sampai 3 · AC-8: dokumen 1 · AC-9: dokumen 2 · AC-10: dokumen 3, 4

Baris Value sourcing: nama modul dan paket (Swift 4, Kotlin 2), metadata pustaka dan target (bisa diulang 1), dep info Cargo (galat skrip 3), triple sah (galat skrip 2), `DT` dari `Base.xcconfig` (Swift 5), lokasi keluaran (Swift 3, Kotlin 1).
