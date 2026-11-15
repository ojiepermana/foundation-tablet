# 0002. Kontrak Rust untuk kedua aplikasi

**Date**: 2026-11-16
**Status**: Accepted

## Summary

Spec ini menetapkan kontrak pertama antara Rust dan kedua aplikasi: satu fungsi `hello(name: String) -> String` yang perilakunya ada di `tablet-core` dan diekspor `tablet-ffi` lewat makro UniFFI. Binding Swift dan Kotlin dihasilkan oleh satu skrip, `scripts/generate-bindings.sh`, dari pustaka yang baru dibangun untuk tiap target, dengan generator UniFFI versi yang sama dari crate tooling di workspace. Konvensi kontrak (kompatibilitas, kepemilikan nilai, galat, thread, cara menambah fungsi) ditulis di `docs/contracts/ffi-conventions.md`. Menautkan pustaka dan binding ke aplikasi tetap milik fitur 04, dengan rincian serah terima di bagian akhir spec ini.

## Requirements

**User stories**:

- Sebagai kontributor, saya ingin menambah perilaku bersama sekali di Rust lalu mendapat binding Swift dan Kotlin dengan satu perintah, supaya kedua aplikasi tidak menyalin aturan.
- Sebagai pembangun fitur 04, saya ingin binding yang selalu cocok dengan pustaka yang saya tautkan untuk tiap target, supaya aplikasi tidak gagal karena checksum atau simbol yang berbeda.
- Sebagai agen yang menambah kontrak berikutnya, saya ingin konvensi tertulis untuk tipe, galat, nullability, kepemilikan nilai, thread, dan kompatibilitas, supaya saya tidak menebak atau mengekspos tipe privat.

**Acceptance criteria** (kontrak; tiap butir bisa diperiksa sendiri):

- **AC-1** (README AC 2): `tablet-core` memuat tepat satu fungsi publik, `pub fn hello(name: String) -> String`, yang mengembalikan `format!("Hello, {name}!")`. Tes unit di `crates/core` membuktikan: `Ayu` menjadi `Hello, Ayu!`, `Bima` menjadi `Hello, Bima!`, string kosong menjadi `Hello, !`, dan nama dengan huruf non ASCII (misalnya `Zoë 東京`) kembali tanpa diubah di antara `Hello, ` dan `!`. `cargo tree -p tablet-core -e normal` tetap satu baris saja (inti tanpa dependensi).
- **AC-2** (README AC 2): `tablet-ffi` mengekspor tepat satu fungsi UniFFI, `hello(name: String) -> String`, dengan `#[uniffi::export]`, dan badannya hanya memanggil `tablet_core::hello`. Tidak ada file UDL. Satu tes asap di `crates/tablet-ffi` memanggil `tablet_ffi::hello` langsung dari Rust dan mendapat `Hello, Ayu!` untuk `Ayu`. Perjalanan penuh lewat simbol C dan binding dibuktikan fitur 04.
- **AC-3**: generator binding adalah crate tooling `tooling/uniffi-bindgen` (paket `tablet-uniffi-bindgen`, biner `uniffi-bindgen`) yang memakai `uniffi` dari `[workspace.dependencies]` dengan fitur `cli`. Bukti: `Cargo.lock` tetap memuat tepat satu paket bernama `uniffi` dengan versi pin `Cargo.toml`; `cargo tree -p tablet-ffi -e normal --target aarch64-apple-ios` dan `--target aarch64-linux-android` tidak memuat `clap`; di antara `git ls-files '*Cargo.toml'` selain `Cargo.toml` akar, yang memuat `uniffi` tepat `crates/tablet-ffi/Cargo.toml` dan `tooling/uniffi-bindgen/Cargo.toml`.
- **AC-4** (README AC 3): sesudah `scripts/build-ipados.sh` tanpa argumen (yang membangun `tablet-ffi` release untuk `aarch64-apple-ios` dan `aarch64-apple-ios-sim`, AC-3 spec 0001), `scripts/generate-bindings.sh swift target/aarch64-apple-ios/release/libtablet_ffi.a target/aarch64-apple-ios-sim/release/libtablet_ffi.a` keluar `0` dan menghasilkan tepat tiga file: `bindings/swift/Sources/TabletBindings/TabletBindings.swift`, `target/bindings/swift/headers/TabletFFI/TabletFFI.h`, dan `target/bindings/swift/headers/TabletFFI/module.modulemap` yang mendeklarasikan `module TabletFFI` dengan `header "TabletFFI.h"`. File Swift memuat `public func hello(name: String) -> String`. File Swift itu lulus pemeriksaan tipe Swift 6 untuk simulator dan perangkat, dengan `DT` = nilai `IPHONEOS_DEPLOYMENT_TARGET` di `apps/ipados/Config/Base.xcconfig`:
  `xcrun swiftc -typecheck -swift-version 6 -module-name TabletBindings -target arm64-apple-ios${DT}-simulator -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -I target/bindings/swift/headers bindings/swift/Sources/TabletBindings/TabletBindings.swift`, lalu sama dengan `-target arm64-apple-ios${DT}` dan `--sdk iphoneos`. Keduanya keluar `0`.
- **AC-5** (README AC 4): sesudah `scripts/build-android-tablet.sh` (yang membangun `tablet-ffi` release untuk `aarch64-linux-android` dan `x86_64-linux-android`), `scripts/generate-bindings.sh kotlin target/aarch64-linux-android/release/libtablet_ffi.so target/x86_64-linux-android/release/libtablet_ffi.so` keluar `0` dan menghasilkan tepat satu file, `bindings/kotlin/foundation/tablet/bindings/tablet_ffi.kt`. Bukti dengan `grep -F`: memuat `package foundation.tablet.bindings`, `import com.sun.jna.Native`, `findLibraryName(componentName = "tablet_ffi")`, dan ``fun `hello`(`name`: kotlin.String): kotlin.String``. Kompilasi Kotlin dicatat `NOT_RUN` di bukti fitur ini (tidak ada `kotlinc` dan modul `:app` belum memuat JNA) dan dibuktikan fitur 04.
- **AC-6** (README AC 3, 4): generasi bisa diulang. Menjalankan perintah AC-4 atau AC-5 dua kali menghasilkan file yang identik byte demi byte. Skrip menghasilkan binding dari tiap pustaka yang diberikan, membandingkan hasil tiap pustaka dengan hasil pustaka pertama, dan hanya menulis keluaran bila semuanya identik; bila tidak, skrip keluar `1` dan menyebut pustaka pertama serta pustaka pertama yang berbeda. Generator selalu dipanggil dengan `--no-format` dan `--metadata-no-deps`. Skrip menghapus keluaran lama bahasa itu (dan hanya itu, lihat langkah 6 kontrak skrip) sebelum memindahkan yang baru, jadi file asing di folder keluaran hilang. Sesudahnya `git status --short` sama dengan sebelum skrip dijalankan.
- **AC-7**: skrip gagal lebih awal dengan kode keluar `1`, pesan berawalan `generate-bindings: ` yang menyebut masalahnya, baris perbaikan bertakuk di bawahnya, dan tanpa mengubah keluaran yang sudah ada, pada setiap kasus di tabel "Pesan galat skrip". `-h` atau `--help` mencetak cara pakai dan keluar `0`.
- **AC-8** (README AC 25): `docs/contracts/ffi-conventions.md` ada dan memuat satu bagian untuk tiap topik pada tabel "Isi konvensi kontrak" (sebelas topik README bagian 15, ditambah thread pemanggil, kontrak transport, hasil generasi, dan langkah menambah fungsi kontrak). Topik yang belum dipakai kontrak apa pun ditandai "ditetapkan, belum dipakai" beserta aturannya, dan yang masih butuh keputusan diarahkan ke `/architect`. Dokumen tidak mendefinisikan entitas bisnis.
- **AC-9**: catatan arsitektur dan panduan mengikuti keadaan nyata. Setiap kalimat pada tabel "Kalimat dokumen yang diperbarui" sudah diperbarui, dan `docs/architecture/ownership-matrix.md` memuat baris `tooling/uniffi-bindgen`, `crates/tablet-ffi/uniffi.toml`, `scripts/generate-bindings.sh`, `docs/contracts`, dan `target/bindings/` (hasil generasi). `docs/getting-started.md` memuat bagian "Menghasilkan binding" untuk kedua bahasa, dan `docs/contributing.md` menunjuk ke `docs/contracts/ffi-conventions.md`.
- **AC-10**: gerbang repo tetap hijau pada commit fitur ini: `cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked`, dan `scripts/test.sh` keluar `0`. Kasus B1 sampai B6, V1 sampai V9, C1 sampai C5, G1 sampai G4, I1 sampai I11, dan A1 sampai A12 lulus tanpa diubah. `git ls-files -s scripts/generate-bindings.sh` menampilkan mode `100755`.

## Decision

**Chosen option**: Opsi 1, kontrak lewat makro UniFFI, generator dari crate tooling di workspace, binding dihasilkan per platform dari pustaka tiap target dan harus identik.

`hello` hidup di `tablet-core` dan diekspor tipis oleh `tablet-ffi` dengan `#[uniffi::export]`; `scripts/generate-bindings.sh <swift|kotlin> <pustaka>...` menjalankan biner `uniffi-bindgen` dari crate `tooling/uniffi-bindgen` dalam mode pustaka (membaca metadata yang tertanam di pustaka yang sudah dibangun), dan konvensi kontrak tertulis di `docs/contracts/ffi-conventions.md`.

**Implementation skills**: `rust-best-practices` (penulis `apollographql`, `.claude/skills/rust-best-practices/`)

## Rationale

Alasan, opsi yang ditimbang, keputusan kecil (K1 sampai K17), bukti probe, dan catatan cross check ada di [rationale.md](rationale.md).

## Feature design

**Data model sketch**:

Tidak ada penyimpanan. Satu satunya "data" adalah nilai yang menyeberang batas FFI:

| Nilai | Tipe Rust | Swift | Kotlin | Wajib | Catatan |
|---|---|---|---|---|---|
| `name` (masuk) | `String` | `String` | `kotlin.String` | ya, boleh kosong | Disalin ke Rust sebagai UTF 8; tanpa batas panjang, tanpa trim |
| hasil (keluar) | `String` | `String` | `kotlin.String` | ya | Disalin ke native; Rust tidak menyimpan apa pun |

Tidak ada entitas, relasi, atau keadaan. Keadaan tampilan (isi kolom nama, hasil terakhir) milik aplikasi (fitur 04).

**State transitions**: tidak ada. `hello` murni (tanpa efek samping, tanpa keadaan).

**API surface** (kontrak FFI dan antarmuka skrip):

| Antarmuka | Bentuk | Masukan utama | Keluaran utama | Siapa memanggil | Galat utama |
|---|---|---|---|---|---|
| `tablet_core::hello` | `pub fn hello(name: String) -> String` | `name` (wajib) | `Hello, {name}!` | `tablet-ffi` saja | Tidak ada; total untuk semua string |
| `tablet_ffi::hello` | `#[uniffi::export] pub fn hello(name: String) -> String` | `name` | sama dengan inti | Binding Swift dan Kotlin | Tidak ada galat kontrak. Panic Rust (secara praktis hanya kehabisan memori) ditangkap UniFFI: Swift berhenti (`try!` di binding), Kotlin melempar `InternalException` |
| Swift | `public func hello(name: String) -> String` di modul `TabletBindings` | `name:` | `String` | Aplikasi iPad (fitur 04), boleh dari main thread | Checksum tidak cocok membuat binding berhenti saat pertama dipakai |
| Kotlin | ``fun `hello`(`name`: kotlin.String): kotlin.String`` di paket `foundation.tablet.bindings` | `name` | `kotlin.String` | Aplikasi Android (fitur 04), boleh dari main thread | `UnsatisfiedLinkError` bila `libtablet_ffi.so` tidak terkemas; checksum tidak cocok melempar saat pustaka dimuat |
| `scripts/generate-bindings.sh` | `generate-bindings.sh <swift\|kotlin> <pustaka> [<pustaka>...]` | bahasa, satu atau lebih path pustaka | file pada AC-4 atau AC-5 | Kontributor, skrip build (fitur 04), CI (fitur 11) | Tabel "Pesan galat skrip", keluaran berbeda antar target (AC-6) |

**Kontrak skrip `scripts/generate-bindings.sh`**, langkah demi langkah (bash, harus jalan di bash 3.2 macOS dan bash Linux; tanpa `realpath`, `stat`, `mapfile`, `readarray`, atau `${x,,}`):

1. Simpan folder pemanggil, lalu `cd` ke akar repo (`"$(dirname "${BASH_SOURCE[0]}")/.."`, pola skrip build fitur 01). Path pustaka relatif diartikan terhadap folder pemanggil, lalu dinormalkan dengan `cd "$(dirname "$p")" && pwd -P`.
2. Periksa lingkungan dan argumen sesuai tabel "Pesan galat skrip", berurutan, dan berhenti pada galat pertama. Aturan pustaka: nama file tepat `libtablet_ffi.a` untuk `swift` atau `libtablet_ffi.so` untuk `kotlin`; folder induknya tepat `<akar>/target/<triple>/release`; `<triple>` termasuk daftar `targets` di `rust-toolchain.toml` dan cocok dengan bahasa (`swift`: `aarch64-apple-ios`, `aarch64-apple-ios-sim`; `kotlin`: `aarch64-linux-android`, `x86_64-linux-android`); tidak ada pustaka yang disebut dua kali.
3. Pemeriksaan basi untuk tiap pustaka: baca `libtablet_ffi.d` di folder yang sama (berkas dep info yang ditulis Cargo; daftar file sumber yang benar benar dipakai membangun pustaka itu, dengan spasi di path ditulis `\ `). Pustaka basi bila `.d` tidak ada, atau ada file `.rs` di daftar itu yang lebih baru dari pustaka (`[ file -nt pustaka ]`). File lain (`uniffi.toml`, `Cargo.toml`, file non sumber, folder) tidak dihitung, karena mengubahnya tidak membuat Cargo membangun ulang pustaka.
4. Bangun generator sekali: `cargo build -p tablet-uniffi-bindgen --locked --quiet` (profil debug, target host), lalu pakai `target/debug/uniffi-bindgen`.
5. Untuk tiap pustaka ke n, jalankan `target/debug/uniffi-bindgen generate --no-format --metadata-no-deps --language <bahasa> --out-dir <tmp>/<n> <pustaka>` ke folder sementara (`mktemp -d`, dihapus lewat `trap ... EXIT`). Bandingkan tiap `<tmp>/<n>` dengan `<tmp>/1` memakai `diff -r`; berbeda berarti gagal (AC-6). Lalu pastikan `<tmp>/1` berisi tepat file yang diharapkan dan tidak kosong (Swift: `TabletBindings.swift`, `TabletFFI.h`, `TabletFFI.modulemap`; Kotlin: `foundation/tablet/bindings/tablet_ffi.kt`); selain itu gagal. Sampai langkah ini keluaran lama belum disentuh.
6. Hapus keluaran lama bahasa itu, hanya path berikut: Swift `bindings/swift/Sources/TabletBindings/` dan `target/bindings/swift/`; Kotlin `bindings/kotlin/`. `bindings/swift/Package.swift`, `bindings/swift/TabletFFI.xcframework`, dan keluaran bahasa lain tidak pernah disentuh.
7. Pindahkan hasil. Swift: `TabletBindings.swift` ke `bindings/swift/Sources/TabletBindings/`; `TabletFFI.h` ke `target/bindings/swift/headers/TabletFFI/`; `TabletFFI.modulemap` ke folder yang sama dengan nama `module.modulemap`. Kotlin: pohon `foundation/` ke `bindings/kotlin/`.
8. Cetak `generate-bindings: <bahasa> dari <jumlah> pustaka`, satu baris per file yang ditulis (path relatif dari akar), lalu `generate-bindings: selesai`, dan keluar `0`.

Skrip tidak membangun `tablet-ffi`, tidak memanggil `xcodebuild`, Gradle, atau `cargo ndk`, dan tidak menyentuh proyek native. Satu pustaka saja juga sah (misalnya `scripts/build-ipados.sh --simulator`); pemeriksaan identik baru bermakna mulai dua pustaka.

**Pesan galat skrip** (kode keluar `1`; baris pertama `generate-bindings: <pesan>` ke stderr, baris perbaikan bertakuk dua spasi; tes mencocokkan kata kunci yang dicetak tebal):

| # | Kasus | Pesan memuat | Perbaikan memuat |
|---|---|---|---|
| E1 | `cargo` tidak ada di `PATH` | **`cargo tidak ditemukan`** | `https://rustup.rs` |
| E2 | `CARGO_TARGET_DIR` atau `CARGO_BUILD_TARGET_DIR` diset (diperiksa sebelum argumen), atau sesudah langkah 4 `target/debug/uniffi-bindgen` tidak ada karena konfigurasi Cargo memakai `build.target-dir` lain | **`target-dir`** | `unset CARGO_TARGET_DIR CARGO_BUILD_TARGET_DIR`, atau hapus `build.target-dir` dari konfigurasi Cargo |
| E3 | tanpa argumen | **`bahasa tidak disebut`** | baris cara pakai |
| E4 | bahasa selain `swift` atau `kotlin` | **`bahasa tidak dikenal`** dan nilai yang diberikan | `swift` atau `kotlin` |
| E5 | tanpa path pustaka | **`pustaka tidak disebut`** | contoh perintah untuk bahasa itu |
| E6 | path tidak ada | **`pustaka tidak ada`** dan path itu | nama skrip build platform itu |
| E7 | nama file atau folder tidak sesuai aturan langkah 2 (termasuk `.so` untuk `swift`, `.a` untuk `kotlin`, path di luar `target/<triple>/release/`, triple yang tidak cocok bahasa) | **`pustaka tidak sah`** dan path itu | aturan yang dilanggar dan path yang diharapkan |
| E8 | pustaka disebut dua kali | **`pustaka ganda`** dan path itu | sebut tiap pustaka sekali |
| E9 | pustaka basi (langkah 3) | **`pustaka basi`**, path pustaka, dan file sumber pertama yang lebih baru (atau `.d` tidak ada) | nama skrip build platform itu (`scripts/build-ipados.sh` atau `scripts/build-android-tablet.sh`) |
| E10 | `cargo build -p tablet-uniffi-bindgen` gagal | **`generator gagal dibangun`** | jalankan perintah itu sendiri untuk melihat galatnya |
| E11 | generator keluar bukan `0` | **`generasi gagal`** dan path pustaka | keluaran generator diteruskan di atasnya |
| E12 | hasil berbeda antar pustaka (AC-6) | **`binding berbeda`**, pustaka pertama, dan pustaka yang berbeda | kontrak tidak boleh bergantung pada target; periksa `cfg` per target |
| E13 | isi folder sementara tidak sesuai (langkah 5) | **`keluaran generator tidak sesuai`** dan daftar file yang ada | periksa `crates/tablet-ffi/uniffi.toml` |

**`crates/tablet-ffi/uniffi.toml`** (di-commit, dibaca generator dalam mode pustaka):

```toml
[bindings.swift]
module_name = "TabletBindings"
ffi_module_name = "TabletFFI"
ffi_module_filename = "TabletFFI"

[bindings.kotlin]
package_name = "foundation.tablet.bindings"
cdylib_name = "tablet_ffi"
```

Opsi lain dibiarkan bawaan: checksum tetap aktif (`omit_checksums` tidak diset), `android` dan `android_cleaner` tidak diset (K9).

**`tooling/uniffi-bindgen`**:

- `Cargo.toml`: paket `tablet-uniffi-bindgen`, `version`, `edition`, `rust-version`, `publish` dari workspace; `[[bin]] name = "uniffi-bindgen", path = "src/main.rs"`; dependensi tunggal `uniffi = { workspace = true, features = ["cli"] }`.
- `src/main.rs`: `fn main() { uniffi::uniffi_bindgen_main() }` dengan komentar kepala yang menyebut pemiliknya (Tooling, lapisan E), bahwa hanya `scripts/generate-bindings.sh` yang memanggilnya, dan bahwa build mobile tidak memakainya.
- Ditambahkan ke `members` di `Cargo.toml` akar. Skrip build mobile tetap memakai `cargo build -p tablet-ffi` (dan `cargo ndk ... build -p tablet-ffi`), jadi fitur `cli` tidak ikut ke pustaka mobile (AC-3).

**Value sourcing**:

| Aksi | Nilai yang dihasilkan | Sumber |
|---|---|---|
| `hello` | teks salam | Diturunkan dari masukan `name` dengan `format!("Hello, {name}!")` (README bagian 6) |
| `hello` di Swift atau Kotlin | `name` | Parameter fungsi dari aplikasi; isinya keadaan tampilan fitur 04 |
| Generasi Swift | nama modul `TabletBindings`, modul FFI `TabletFFI`, nama file `TabletFFI.h` | `crates/tablet-ffi/uniffi.toml`, nilainya dari tabel nama spec 0001 |
| Generasi Swift | nama file `module.modulemap` | Diganti nama oleh skrip (langkah 7), mengikuti bentuk folder header spec 0001 |
| Generasi Kotlin | paket `foundation.tablet.bindings`, nama pustaka `tablet_ffi` | `crates/tablet-ffi/uniffi.toml` |
| Generasi | isi antarmuka (fungsi, tipe, checksum) | Metadata UniFFI yang tertanam di pustaka yang diberikan (mode pustaka) |
| Generasi | lokasi `uniffi.toml` | `cargo metadata --no-deps` yang dijalankan generator dari akar repo (langkah 1 dan `--metadata-no-deps`) |
| Generasi | versi generator | Pin `uniffi` di `[workspace.dependencies]` lewat crate tooling; sama dengan runtime |
| Pemeriksaan basi | file sumber pustaka | `target/<triple>/release/libtablet_ffi.d` milik Cargo |
| Pemeriksaan triple | daftar target sah | `targets` di `rust-toolchain.toml`, dipetakan ke bahasa di langkah 2 |
| Pemeriksaan tipe Swift | OS minimum `DT` | `IPHONEOS_DEPLOYMENT_TARGET` di `apps/ipados/Config/Base.xcconfig` |
| Folder keluaran | path | Tetap di skrip (langkah 6 dan 7), sama dengan `.gitignore` dan spec 0001 |

**Key invariants**:

- `tablet-core` tidak bergantung pada `uniffi`, kerangka UI, atau API platform, dan tipe publiknya tidak memakai derive UniFFI.
- `tablet-ffi` tidak punya perilaku sendiri: setiap fungsi yang diekspor hanya memetakan tipe dan memanggil inti.
- Hanya `tablet-ffi` dan `tooling/uniffi-bindgen` yang memuat `uniffi`; keduanya memakai satu pin workspace.
- Setiap pemanggilan `cargo build` atau `cargo ndk ... build` di `scripts/` untuk pustaka mobile memakai `-p tablet-ffi`.
- Binding untuk satu platform selalu identik untuk semua target platform itu, dan selalu dihasilkan dari pustaka yang tidak lebih tua dari file sumbernya.
- Hasil generasi tidak disunting tangan dan tidak di-commit (`bindings/swift/Sources/`, `bindings/kotlin/`, `target/`).
- Generator selalu berjalan dengan `--no-format` dan `--metadata-no-deps`, jadi keluaran tidak bergantung pada alat format yang terpasang dan tidak butuh jaringan selain build generator.
- Keluaran lama tidak disentuh sebelum keluaran baru lengkap dan terperiksa.

**Security model**: Tidak ada data pengguna, rahasia, izin native, atau jaringan. `name` tidak dicatat ke log oleh Rust maupun skrip. Skrip hanya menulis ke `bindings/swift/Sources/TabletBindings/`, `bindings/kotlin/`, `target/bindings/swift/`, dan folder sementara; menolak pustaka di luar `target/<triple>/release/`; dan memakai `--locked` sehingga dependensi tidak berubah diam diam. Dependensi baru (`clap` dan kawan kawan, lewat fitur `cli`) hanya masuk ke biner tooling host, tidak ke pustaka mobile; versinya dikunci `Cargo.lock`.

**Configuration required**: tidak ada variabel lingkungan baru. Skrip memakai `cargo` dari `PATH` dan toolchain dari `rust-toolchain.toml`, dan menolak folder target selain `target/` di akar repo (E2).

**Critical test scenarios** (tiap butir menunjuk acceptance criterion):

- Jalur bahagia: jalankan kedua skrip build, lalu skrip generasi untuk `swift` dan `kotlin`; file AC-4 dan AC-5 ada, Swift lulus pemeriksaan tipe Swift 6 untuk simulator dan perangkat, verifies **AC-4**, **AC-5**
- Bisa diulang: jalankan skrip dua kali dan bandingkan hash; tambahkan file asing ke folder keluaran lalu jalankan lagi, file itu hilang, `Package.swift` tiruan tetap ada, verifies **AC-6**
- Target berbeda: di sandbox, generator tiruan menulis isi berbeda untuk pustaka kedua; skrip gagal (E12) dan keluaran lama tetap utuh, verifies **AC-6**
- Pustaka basi: sentuh `crates/core/src/lib.rs` sesudah build, skrip gagal (E9); sentuh `crates/tablet-ffi/uniffi.toml` atau buat `crates/.DS_Store`, skrip tetap lulus, verifies **AC-7**
- Argumen salah: setiap baris E1 sampai E8 dan E13 keluar `1` dengan kata kuncinya, verifies **AC-7**
- Perilaku inti: tes unit `Ayu`, `Bima`, kosong, non ASCII; tes asap ekspor, verifies **AC-1**, **AC-2**
- Batas: `cargo tree` untuk target mobile tanpa `clap`, inti tanpa dependensi, kasus fitur 01 tetap lulus, verifies **AC-1**, **AC-3**, **AC-10**
- Izin: tidak berlaku (tidak ada pengguna atau peran); yang ditolak adalah masukan skrip pada AC-7

## Build plan

Pendekatan Tracer Bullet: milestone 1 menarik satu benang tipis dari `hello` di inti sampai satu file Swift hasil generasi dari satu target, milestone 2 menebalkannya ke empat target dan dua bahasa dengan semua pemeriksaan, milestone 3 menulis konvensi dan dokumen, milestone 4 mengunci hasilnya dengan tes. File milestone 1 sampai 3 tidak beririsan kecuali `scripts/generate-bindings.sh` (milestone 1 menulis jalur bahagia, milestone 2 melengkapinya). Hanya satu build native penuh pada satu waktu.

**Milestone 1: Benang tipis Rust ke Swift** (target host dan `aarch64-apple-ios-sim`)

File: `crates/core/src/lib.rs`, `crates/tablet-ffi/src/lib.rs`, `crates/tablet-ffi/uniffi.toml`, `tooling/uniffi-bindgen/**`, `Cargo.toml`, `Cargo.lock`, `scripts/generate-bindings.sh` (mode `100755`, `git add --chmod=+x` bila perlu).

1. Tambahkan `hello` ke `tablet-core` beserta tes unitnya, satisfies **AC-1**
2. Ekspor `hello` dari `tablet-ffi` dengan `#[uniffi::export]` beserta tes asapnya, lalu tulis `crates/tablet-ffi/uniffi.toml`, satisfies **AC-2**, **AC-4**, **AC-5**
3. Buat `tooling/uniffi-bindgen` dan tambahkan ke `members`. Perbarui `Cargo.lock` dengan satu `cargo build -p tablet-uniffi-bindgen` tanpa `--locked`, lalu pastikan `git diff Cargo.lock` hanya menambah paket tooling dan keluarga `clap` (`anstyle`, `clap`, `clap_builder`, `clap_derive`, `clap_lex`, `strsim`). Periksa `cargo tree` untuk target mobile, lalu jalankan `cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, dan `cargo test --workspace --locked` sekarang juga, satisfies **AC-3**, **AC-10**
4. Tulis jalur bahagia `scripts/generate-bindings.sh` (langkah 1, 4, 5, 6, 7, 8 kontrak skrip) dan jalankan untuk `swift` dengan pustaka simulator saja (`scripts/build-ipados.sh --simulator` lebih dulu); periksa ketiga file dan pemeriksaan tipe simulator, satisfies **AC-4**

**Milestone 2: Empat target, dua bahasa, pemeriksaan lengkap** (needs milestone 1)

File: `scripts/generate-bindings.sh`.

5. Tambahkan pemeriksaan lingkungan, argumen, dan pustaka (langkah 2 dan 3, tabel E1 sampai E9), satisfies **AC-7**
6. Tambahkan perbandingan antar pustaka, pemeriksaan isi folder sementara, dan pesan E10 sampai E13, satisfies **AC-6**, **AC-7**
7. Jalankan `scripts/build-ipados.sh` lalu `scripts/build-android-tablet.sh` (berurutan, tanpa argumen), lalu skrip generasi untuk `swift` dan `kotlin` dengan perintah AC-4 dan AC-5; ulangi sekali untuk bukti identik; jalankan kedua pemeriksaan tipe Swift dan `grep -F` Kotlin; coba E3, E4, E7, E8, dan E9 dengan tangan, satisfies **AC-4**, **AC-5**, **AC-6**, **AC-7**

**Milestone 3: Konvensi kontrak dan catatan arsitektur** (needs milestone 2 supaya dokumen menggambarkan skrip nyata)

File: `docs/contracts/ffi-conventions.md`, `docs/architecture/ownership-matrix.md`, `docs/architecture/overview.md`, `docs/architecture/repository-structure.md`, `docs/architecture/dependency-rules.md`, `docs/getting-started.md`, `docs/contributing.md`.

8. Tulis `docs/contracts/ffi-conventions.md` dengan isi pada "Isi konvensi kontrak" di bawah, satisfies **AC-8**
9. Perbarui setiap kalimat pada "Kalimat dokumen yang diperbarui", tambahkan baris matriks pemilik, bagian "Menghasilkan binding" di `docs/getting-started.md`, dan tautan konvensi di `docs/contributing.md`, satisfies **AC-9**
10. Jalankan `cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked`, dan `scripts/test.sh`; semuanya keluar `0`, satisfies **AC-10**

**Milestone 4: Tes** (dikerjakan `/test`; needs milestone 1 sampai 3; kode produksi tidak berubah)

File: `tests/build-scripts/generate-bindings.test.sh`, `tests/repo/*.test.sh` (tambahan kasus saja), `docs/reviews/`.

11. Tulis kasus grup `build-scripts` untuk `scripts/generate-bindings.sh` di sandbox, mengikuti pola `tests/build-scripts/` (salin skrip dan file yang dibacanya ke folder sementara, `PATH` berisi alat tiruan). `cargo` tiruan mencatat argumennya dan, untuk `build -p tablet-uniffi-bindgen`, menanam `target/debug/uniffi-bindgen` tiruan. Generator tiruan mencatat argumennya dan menulis file yang diharapkan per bahasa ke `--out-dir`; sakelar lingkungan `STUB_GEN_DIFFER` (isi berbeda untuk pustaka kedua), `STUB_GEN_FAIL` (keluar `1`), `STUB_GEN_MISSING` (satu file tidak ditulis), dan `STUB_CARGO_BUILD_FAIL`. Waktu ubah diatur dengan `touch -t`. Kasusnya: E1 sampai E13; keluaran berbeda; pembersihan file asing tanpa menyentuh `Package.swift`; `--no-format` dan `--metadata-no-deps` selalu diteruskan; `cargo build -p tablet-uniffi-bindgen --locked` dipanggil sekali; `--help` keluar `0`. `scripts/test.sh` tetap tanpa build dan tanpa jaringan, locks **AC-6**, **AC-7**
12. Tambahkan kasus grup `repo`: `uniffi.toml` memuat nama dari tabel spec 0001; manifest pemegang `uniffi` (aturan AC-3) tepat dua; `tooling/uniffi-bindgen` tidak di bawah `crates/`; setiap `cargo build` atau `cargo ndk ... build` di `scripts/` memakai `-p tablet-ffi` atau `-p tablet-uniffi-bindgen`; `docs/contracts/ffi-conventions.md` memuat judul bagian untuk tiap topik AC-8; `scripts/generate-bindings.sh` bermode `100755`, locks **AC-3**, **AC-8**, **AC-10**
13. Simpan bukti tes (perintah, keluaran, SHA, target, satu baris per kriteria per target dengan `PASS`, `FAIL`, atau `NOT_RUN`) di `docs/reviews/`, locks **AC-1** sampai **AC-10**

Tes Rust tetap dijalankan dengan `cargo test --workspace --locked`; `scripts/test.sh` tidak mendapat grup yang memanggil Cargo (K12).

### Kalimat dokumen yang diperbarui

| File | Kalimat atau baris sekarang | Menjadi |
|---|---|---|
| `docs/architecture/overview.md` | Baris lapisan E: "Generator binding dan validasi arsitektur (fitur 10) belum ada" | Generator binding ada (`scripts/generate-bindings.sh`, `tooling/uniffi-bindgen`); validasi arsitektur (fitur 10) belum ada |
| `docs/architecture/overview.md` | Bagian "Ditetapkan, belum dibangun": baris "Generator binding" dan "Nama modul binding" | Dipindah ke keadaan nyata; yang tersisa hanya pengemasan dan penautan (fitur 04) |
| `docs/architecture/ownership-matrix.md` | Baris `bindings/swift`, `bindings/kotlin`: "Belum, ditetapkan untuk fitur 03 dan 04" | Dihasilkan skrip sejak fitur 03; pengemasan fitur 04 |
| `docs/architecture/ownership-matrix.md` | Baris terakhir menyebut `tooling/` "Belum ada" | `tooling/` dihapus dari baris itu dan mendapat baris sendiri |
| `docs/architecture/repository-structure.md` | Baris penyimpangan `design-system/`, `shared/`, `tooling/`, ... "Belum dibuat" | `tooling/` dihapus dari baris itu; struktur nyata memuat `tooling/uniffi-bindgen` dan `docs/contracts/` |
| `docs/architecture/repository-structure.md` | "Baris `bindings/` adalah keputusan yang ditetapkan, belum dibangun: folder itu belum ada sampai fitur 03 dan 04." | Folder `bindings/` dibuat skrip generasi sejak fitur 03 dan tidak di-commit; `Package.swift` dari fitur 04 |
| `docs/architecture/dependency-rules.md` | "Folder `bindings` dan tautan aplikasi ke binding ditetapkan, belum dibangun (fitur 03 dan 04)" | Binding dihasilkan sejak fitur 03; tautan aplikasi ke binding masih fitur 04 |
| `docs/getting-started.md` | Setiap kalimat yang menyebut `cargo test` lulus dengan nol tes, atau workspace dua crate | Jumlah crate dan tes yang nyata |
| `docs/contributing.md` | "Generatornya (`scripts/generate-bindings.sh`) ditetapkan untuk fitur 03." | Generatornya `scripts/generate-bindings.sh`; aturan kontrak di `docs/contracts/ffi-conventions.md` |

Developer mencari kalimat lain dengan arti sama (`grep -n -i 'belum\|fitur 03\|dua crate\|nol tes' docs/architecture docs/getting-started.md docs/contributing.md`) dan memperbaruinya juga.

### Isi konvensi kontrak

`docs/contracts/ffi-conventions.md` (bahasa Indonesia, gaya dokumen `docs/architecture/`) memuat satu bagian per baris di bawah. Developer menuliskannya menjadi prosa; aturannya tidak berubah.

| Topik | Aturan |
|---|---|
| Antarmuka UniFFI | Hanya makro (`#[uniffi::export]`, `uniffi::Record`, `uniffi::Enum`, `uniffi::Object`, `uniffi::Error`) di `tablet-ffi`; tanpa UDL. Satu `uniffi::setup_scaffolding!()` di `tablet-ffi`. Nama Rust `snake_case`; generator memetakannya ke `camelCase` Swift dan Kotlin |
| DTO Rust | Tipe yang menyeberang FFI didefinisikan di `tablet-ffi` dan dikonversi dengan `From` dari dan ke tipe inti. Tipe inti tidak memakai derive UniFFI dan tidak diekspos langsung. Tidak ada DTO spekulatif atau entitas bisnis sebelum fiturnya punya scope dan spec |
| Galat bertipe | Fungsi yang bisa gagal mengembalikan `Result<T, E>` dengan `E` enum `#[derive(Debug, uniffi::Error)]` per area di `tablet-ffi`, dipetakan dari galat inti. Fungsi yang tidak bisa gagal (seperti `hello`) tidak memakai `Result`. Panic bukan cara melapor galat; UniFFI menangkapnya sebagai galat internal (Swift berhenti, Kotlin `InternalException`). Profil build tidak memakai `panic = "abort"` |
| Kode galat terbaca mesin | Nama varian enum galat adalah kodenya. Varian tidak diganti nama atau dihapus tanpa langkah kompatibilitas; pesan untuk manusia boleh berubah. Aplikasi mencocokkan varian, bukan teks pesan |
| Nullability | Ketiadaan nilai hanya `Option<T>` (menjadi `T?` di Swift dan Kotlin). Tidak ada nilai pengganti seperti string kosong atau `-1` |
| Kepemilikan sumber daya | String, angka, record, dan enum disalin saat menyeberang; tidak ada pihak yang memegang memori pihak lain. Objek (`uniffi::Object`, dibungkus `Arc`) hidup selama ada referensi: Swift melepasnya saat `deinit`, Kotlin lewat `close()` (`AutoCloseable`) atau cleaner. String berupa UTF 8 di batas; encoder Kotlin mengganti surrogate tunggal yang tidak valid |
| Thread pemanggil | Fungsi sinkron kontrak harus cepat dan tidak memblokir (tanpa I/O, tanpa tunggu), sehingga aplikasi boleh memanggilnya dari main thread. `hello` memenuhi ini. Pekerjaan yang bisa lama tidak dibuat sinkron; tunggu keputusan async. Rust tidak mengasumsikan thread pemanggil tertentu |
| Kompatibilitas | Binding dan pustaka selalu dari revisi yang sama (skrip menolak pustaka basi), jadi tidak ada janji ABI antar versi. Checksum UniFFI tetap aktif sehingga binding yang tidak cocok gagal saat pustaka dimuat (Kotlin) atau saat pertama dipakai (Swift), bukan diam diam. Menambah fungsi atau tipe baru bersifat aditif; mengganti nama, menghapus, atau mengubah tipe parameter adalah perubahan yang memutus, dan dikerjakan dalam satu commit bersama kedua aplikasi |
| Versi | Versi kontrak sama dengan `version` di `[workspace.package]`. Tidak ada nomor versi kontrak terpisah selama kedua aplikasi ada di repo yang sama |
| Operasi async | Ditetapkan, belum dipakai. Fungsi async pertama butuh spec (`/architect`) yang memilih runtime (fitur `tokio` UniFFI atau tanpa runtime) dan dependensi coroutine Kotlin |
| Pembatalan | Ditetapkan, belum dipakai. Ikut keputusan async; sampai ada, kontrak tidak menawarkan operasi panjang |
| Antarmuka kemampuan native | Ditetapkan, belum dipakai. Kemampuan platform yang dibutuhkan Rust (misalnya penyimpanan aman) menjadi trait `#[uniffi::export(with_foreign)]` yang diimplementasi native; tiap antarmuka pertama butuh spec karena menyangkut izin native |
| Kontrak transport | Kontrak aplikasi dan FFI di dokumen ini terpisah dari kontrak transport kelak (misalnya OpenAPI). Tipe transport tidak menjadi tipe FFI secara langsung; `tablet-core` memetakannya |
| Hasil generasi | Dihasilkan `scripts/generate-bindings.sh` ke `bindings/swift/Sources/TabletBindings/`, `bindings/kotlin/`, dan `target/bindings/swift/`; tidak disunting dan tidak di-commit. `crates/tablet-ffi/uniffi.toml` dan (kelak) `bindings/swift/Package.swift` di-commit |
| Menambah fungsi kontrak | 1) tulis perilaku dan tesnya di `tablet-core`; 2) petakan di `tablet-ffi` tanpa logika; 3) jalankan kedua skrip build dan skrip generasi untuk `swift` dan `kotlin`; 4) panggil dari kedua aplikasi bila fitur memintanya; 5) jalankan pemeriksaan pada `AGENTS.md` dan cek kedua platform menurut panduan kontribusi |

### Serah terima ke fitur 04

Fitur 04 tidak punya spec, jadi rincian yang dibutuhkannya dari kontrak ini dicatat di sini.

- Skrip build memanggil `scripts/generate-bindings.sh <bahasa>` dengan tepat pustaka yang dibangunnya pada run itu (satu atau dua), sesudah build Rust dan sebelum pengemasan.
- `xcodebuild -create-xcframework` memakai `-headers target/bindings/swift/headers` untuk tiap `-library` yang dibangun pada run itu. Run `--simulator` atau `--device` saja menghasilkan XCFramework satu slice; itu sah.
- `bindings/swift/Package.swift`: `// swift-tools-version: 6.0`; `platforms: [.iOS("26.0")]` (sama dengan `Base.xcconfig`); `binaryTarget(name: "TabletFFI", path: "TabletFFI.xcframework")`; target `TabletBindings` di `Sources/TabletBindings` yang bergantung pada `TabletFFI`, dengan `swiftLanguageModes: [.v6]` di tingkat paket; produk pustaka `TabletBindings`.
- Android: kunci katalog `jna = "5.18.1"` di `[versions]` dan `jna = { module = "net.java.dev.jna:jna", version.ref = "jna" }` di `[libraries]` pada `libs.versions.toml`; di `:app`, `implementation(libs.jna) { artifact { type = "aar" } }`; folder sumber Kotlin `rootDir.resolve("../../bindings/kotlin")`.
- Bukti fitur 04 menutup yang `NOT_RUN` di sini: binding Kotlin terkompilasi di `:app`, dan `hello` terpanggil dari kedua aplikasi di simulator dan emulator.

## Consequences

**Positive**:

- Satu perintah menghasilkan binding untuk satu platform, dan hasilnya tidak bisa diam diam berbeda antar target atau basi terhadap sumber.
- Generator memakai versi UniFFI yang persis sama dengan runtime tanpa `cargo install` global, jadi clone bersih dan CI mendapat generator yang sama.
- Mode pustaka berarti tidak ada file UDL kedua yang harus diselaraskan dengan kode Rust.
- Konvensi tertulis memberi fitur berikutnya aturan untuk galat, nullability, thread, dan objek sebelum kontrak itu dipakai, tanpa membuat tipe spekulatif.
- Binding Swift sudah terbukti lulus Swift 6 sejak fitur ini, sesuai mode bahasa aplikasi iPad.

**Negative / tradeoffs**:

- Kompilasi binding Kotlin dan pemanggilan dari kedua aplikasi belum terbukti di fitur ini (`NOT_RUN`); risiko itu pindah ke fitur 04. Tidak ada `kotlinc` di mesin lead, dan modul `:app` belum memuat JNA.
- Membangun generator pertama kali butuh sekitar 20 detik (dependensi `clap`), dan `cargo build --workspace` di host juga membangunnya.
- `cargo build --workspace` di host menyatukan fitur `uniffi` (termasuk `cli`) untuk `tablet-ffi` host; pustaka host itu bukan yang dikemas, tetapi skrip build mobile harus tetap memakai `-p tablet-ffi` (dikunci tes repo).
- Pemeriksaan basi bergantung pada waktu ubah file dan berkas `.d` Cargo. Pustaka yang disalin atau dipulihkan dari cache dengan waktu baru bisa lolos walau basi; checksum UniFFI tetap menjadi pengaman terakhir saat aplikasi memuatnya.
- File header dan modulemap ada di `target/`, sehingga `cargo clean` ikut menghapusnya; skrip build fitur 04 selalu menghasilkannya lagi.
- Skrip menolak `CARGO_TARGET_DIR`; kontributor yang memakai folder target bersama harus mematikannya untuk repo ini.
- Konvensi untuk async, pembatalan, dan antarmuka native baru berupa arah; fitur pertama yang memakainya tetap butuh spec.

**Neutral**:

- Workspace sekarang berisi tiga crate. Langkah verify spec 0001 yang menyebut "tepat dua crate" mencatat keadaan fitur 01; kasus B2 hanya memeriksa keberadaan kedua crate inti dan tetap lulus.
- `hello` mengikuti bentuk README (`name: String`), bukan `&str`, supaya fungsi inti dan kontrak sama persis dengan dokumen kebutuhan.
- Generator bawaan UniFFI menulis modulemap dengan `use "Darwin"` dan modul bawaan Clang; tidak ada `link_frameworks` tambahan.

## Follow-up

- [ ] Fitur 04: kerjakan "Serah terima ke fitur 04" di atas, lalu perbarui alat tiruan sandbox skrip build (`scripts/generate-bindings.sh`) dan daftar file sesuai catatan Follow-up spec 0001.
- [ ] Fitur 10: putuskan apakah pemeriksaan "hanya `tablet-ffi` dan `tooling/uniffi-bindgen` memuat `uniffi`", "pustaka mobile selalu `-p tablet-ffi`", dan "inti tanpa derive UniFFI" dipindahkan ke `scripts/validate-architecture.sh`.
- [ ] Fitur 11: jalankan `scripts/generate-bindings.sh` di CI pada runner Linux untuk `kotlin` dan runner macOS untuk `swift`, dan catat hasilnya per platform. Pastikan build generator di runner baru tidak butuh jaringan selain unduhan crate yang dikunci `Cargo.lock`.
- [ ] Objek pertama yang diekspor: putuskan `android = true` (cleaner `SystemCleaner` di API 34 ke atas, menambah `androidx.annotation`) atau tetap bawaan; dicatat di K9.
- [ ] `rust-best-practices` dipakai untuk spec ini tetapi belum disebut di `AGENTS.md`; konvensinya berlaku untuk semua kode Rust, jadi tempatnya di bagian aturan `AGENTS.md` akar (urusan `/sync` atau `/audit`).
