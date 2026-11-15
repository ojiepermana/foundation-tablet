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

- [ ] `rustup toolchain install` → keluar 0; toolchain `1.99.1` beserta `rustfmt`, `clippy`, dan target `aarch64-apple-ios`, `aarch64-apple-ios-sim`, `aarch64-linux-android`, `x86_64-linux-android` terpasang (`rustup target list --installed` memuat keempatnya) → AC-1, AC-8
- [ ] `rustc --version` → diawali `rustc 1.99.1` → AC-1, AC-8
- [ ] `cargo build --workspace --locked` → keluar 0 → AC-1
- [ ] `cargo test --workspace --locked` → keluar 0 (nol tes, `test result: ok`) → AC-1
- [ ] `git ls-files Cargo.lock` → menampilkan `Cargo.lock` → AC-1
- [ ] `cargo metadata --no-deps --format-version 1 | grep -o '"name":"tablet-[a-z]*"' | sort -u` → tepat `"name":"tablet-core"` dan `"name":"tablet-ffi"` (workspace berisi tepat dua crate) → AC-2
- [ ] `cargo tree -p tablet-core -e normal` → satu baris saja: `tablet-core v0.1.0 (...crates/core)` → AC-2
- [ ] `cargo tree -p tablet-ffi -e normal --depth 1` → `tablet-ffi v0.1.0`, lalu tepat dua anak: `tablet-core v0.1.0` dan `uniffi v0.32.2` → AC-2
- [ ] `ls target/debug/libtablet_ffi.a target/debug/libtablet_ffi.dylib` (sesudah `cargo build`) → kedua file ada → AC-2
- [ ] `grep -n 'crate-type' crates/tablet-ffi/Cargo.toml` → `crate-type = ["lib", "staticlib", "cdylib"]` → AC-2
- [ ] Periksa kunci versi terhadap tabel "Proposed stack": `rust-toolchain.toml` memuat `channel = "1.99.1"` dan keempat target; `Cargo.toml` akar memuat `resolver = "3"`, `edition = "2024"`, `rust-version = "1.99"`, `uniffi = "=0.32.2"`; `grep -A1 'name = "uniffi"' Cargo.lock` → `version = "0.32.2"` → AC-8 (bagian Rust, Target Rust, UniFFI)
- [ ] `git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'` → kosong (keluar 1) → AC-11
- [ ] `git status --short` sesudah build dan test → kosong → AC-11
- [ ] `.gitignore` akar memuat setiap entri "Aturan commit" spec: `git check-ignore -v target/x apps/ipados/build/x a/xcuserdata/x apps/ipados/Tablet.xcodeproj/project.xcworkspace/x apps/ipados/Config/Local.xcconfig .build/x .swiftpm/x apps/android-tablet/app/build/x apps/android-tablet/build/x apps/android-tablet/.gradle/x apps/android-tablet/.kotlin/x apps/android-tablet/local.properties apps/android-tablet/app/.cxx/x apps/android-tablet/captures/x apps/android-tablet/app/src/main/jniLibs/x bindings/swift/TabletFFI.xcframework/x bindings/swift/Sources/x bindings/kotlin/x .DS_Store .idea/x a.iml` → setiap path tercetak dengan aturan `.gitignore` yang cocok (21 baris) → AC-11
- [ ] Sesudah selesai: `cd / && rm -rf "$(dirname "$CLONE")"` → folder sementara terhapus

### Acceptance-criteria coverage

- AC-1: toolchain, `rustc --version`, `cargo build`, `cargo test`, `Cargo.lock` ter-commit
- AC-2: `cargo metadata`, dua `cargo tree`, pustaka `.a` dan `.dylib`, `crate-type`
- AC-8 (bagian Rust): `rustup toolchain install`, `rustc --version`, pemeriksaan kunci versi
- AC-11 (bagian `.gitignore` dan biner): `git ls-files`, `git status --short`, `git check-ignore`
