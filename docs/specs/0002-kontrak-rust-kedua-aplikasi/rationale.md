# 0002. Kontrak Rust untuk kedua aplikasi: alasan

Catatan keputusan untuk [index.md](index.md). `/develop` tidak perlu membaca file ini.

## Context

Fitur 01 meninggalkan dua crate kosong: `tablet-core` tanpa dependensi dan `tablet-ffi` yang hanya memanggil `uniffi::setup_scaffolding!()`. Spec 0001 sudah menetapkan nama modul (`TabletFFI`, `TabletBindings`, `foundation.tablet.bindings`), lokasi binding, dan urutan build lalu generasi lalu pengemasan. Spec itu menyerahkan ke fitur 03 bentuk generator, `uniffi.toml`, `scripts/generate-bindings.sh`, versi JNA, mode bahasa Swift untuk `TabletBindings`, tes Rust pertama, dan apakah `scripts/test.sh` mendapat grup Cargo.

Kekuatan yang membentuk keputusan:

- **README bagian 2.3, 6, 15, dan 16**: kontrak UniFFI eksplisit, tanpa tipe privat, binding tidak pernah disunting tangan, generasi bisa diulang dan versinya dikunci, dan konvensi jangka panjang untuk sebelas topik kontrak tanpa DTO bisnis spekulatif.
- **Done when fitur 03**: binding kedua bahasa harus dari revisi sumber yang sama dengan pustaka yang akan ditautkan untuk tiap target matriks dukungan (dua target Apple, dua ABI Android).
- **Fitur 04 tidak punya langkah spec** dan langsung memakai skrip ini dari kedua skrip build, jadi antarmuka skrip dan lokasi keluarannya harus tuntas di sini.
- **Aplikasi iPad memakai Swift 6** dengan isolasi bawaan `MainActor` (`Base.xcconfig`), sedangkan catatan spec 0001 menyebut dukungan Swift 6 UniFFI 0.32 baru sebagian.
- **Mesin lead**: Xcode 27.1, NDK 28.2.13676358, `cargo-ndk` 4.1.2, keempat target Rust terpasang; tidak ada `kotlinc`, `ktlint`, `swiftformat`, atau `swift-format` di `PATH`. Paket `uniffi 0.32.2` dengan fitur `cli` dan dependensinya sudah ada di cache Cargo; JNA 5.18.1 (`.aar`) sudah ada di cache Gradle.
- **Tes fitur 01** mengunci batas crate (B1 sampai B6), satu pin `uniffi` di `Cargo.lock` (V3), dan aturan commit (C1 sampai C5). Spec 0001 meminta crate tooling ditaruh di luar `crates/` supaya B6 tetap lulus tanpa diubah.

Bila tidak diputuskan, fitur 04 harus memilih generator dan lokasi keluaran sambil membangun aplikasi, dan binding yang basi atau berbeda antar target baru ketahuan saat aplikasi gagal memuat checksum.

## Options considered

### Opsi 1: Makro UniFFI, generator crate tooling di workspace, generasi per platform dari pustaka tiap target

`hello` di inti, ekspor `#[uniffi::export]` di `tablet-ffi`. Crate `tooling/uniffi-bindgen` membungkus `uniffi::uniffi_bindgen_main()`. Skrip menerima bahasa dan satu atau lebih pustaka, menghasilkan binding dari tiap pustaka dalam mode pustaka, dan hanya menulis bila semuanya identik.

**Pros**:
- Versi generator sama persis dengan runtime lewat satu pin workspace; tanpa alat global.
- Tidak ada file UDL yang bisa berbeda dari kode Rust.
- Bukti "sama untuk tiap target" diperiksa mesin setiap kali, bukan diasumsikan.

**Cons**:
- Menambah crate ketiga dan dependensi `clap` (hanya di host).
- Satu generasi per pustaka; untuk dua target sedikit lebih lama daripada sekali.

### Opsi 2: File UDL dan generasi dari UDL

Kontrak ditulis di `tablet.udl`; `tablet-ffi` memakai `uniffi::include_scaffolding!` dan `build.rs`; binding dihasilkan dari UDL tanpa membangun pustaka.

**Pros**:
- Kontrak terbaca sebagai satu file bahasa netral.
- Generasi tidak butuh pustaka yang sudah dibangun.

**Cons**:
- Dua sumber kebenaran (UDL dan Rust) yang harus selalu sama; README meminta Rust dan UniFFI sebagai otoritas.
- Butuh `build.rs` dan dependensi build `uniffi` di `tablet-ffi`; binding tidak terikat ke pustaka yang ditautkan, sehingga janji "revisi yang sama" tidak terbukti.

### Opsi 3: Generator terpasang global (`cargo install uniffi-bindgen-cli` atau sejenis)

Kontributor dan CI memasang biner generator dengan versi yang dicatat di panduan.

**Pros**:
- Workspace tetap dua crate; tidak ada `clap` di `Cargo.lock`.

**Cons**:
- Versi generator bisa berbeda dari runtime di mesin mana pun; spec 0001 sudah menolaknya.
- Satu langkah pemasangan tambahan di panduan dan CI.

### Opsi 4: Generasi sekali dari pustaka host

Bangun `tablet-ffi` untuk host lalu hasilkan kedua bahasa dari `target/debug/libtablet_ffi.dylib`.

**Pros**:
- Cepat dan tidak butuh NDK atau SDK Apple untuk generasi.

**Cons**:
- Pustaka host bukan yang ditautkan; perbedaan `cfg` per target tidak akan ketahuan.
- Tidak memenuhi kalimat Done when tentang pustaka untuk tiap target.

## Rationale

Opsi 1 dipilih karena hanya opsi ini yang membuktikan kalimat Done when secara mekanis: binding dihasilkan dari pustaka yang memang akan ditautkan, untuk tiap target, dan skrip gagal bila hasilnya berbeda atau pustakanya lebih tua dari sumber. Probe di bawah menunjukkan mode pustaka membaca `.a` Apple dan `.so` Android sama baiknya, dan keluaran kedua target satu platform identik byte demi byte, jadi pemeriksaan identik tidak menimbulkan gagal palsu hari ini.

Opsi 2 menarik untuk kontrak yang dibaca manusia, tetapi menambah sumber kebenaran kedua dan tidak terikat ke pustaka yang ditautkan. Opsi 3 sudah ditolak spec 0001 karena versi generator bisa menyimpang. Opsi 4 adalah jalan pintas yang benar untuk saat ini (kontrak tidak punya `cfg` per target) tetapi tidak membuktikan janji scope, dan biaya tambahannya kecil.

Biaya Opsi 1 (crate ketiga, `clap` di `Cargo.lock`) dibatasi: crate tooling di luar `crates/` (B6 tetap lulus), memakai pin `uniffi` yang sama (V3 tetap lulus), dan pustaka mobile dibangun dengan `-p tablet-ffi` sehingga fitur `cli` tidak ikut.

## Keputusan diambil

Mode keputusan `auto` (bawaan `claude-agent-flow`, user tidak memberi tanda): opsi rekomendasi diambil. Tanda `berat` berarti keputusan menyentuh kontrak yang akan dipakai fitur berikutnya.

| # | Pertanyaan | Diambil | Runner up | Tanda | Yang berubah bila runner up dipilih |
|---|---|---|---|---|---|
| K1 | Cara mendefinisikan kontrak | Makro `#[uniffi::export]`, tanpa UDL | File UDL | berat | `tablet-ffi` butuh `build.rs`; Opsi 2 |
| K2 | Bentuk generator | Crate `tooling/uniffi-bindgen`, paket `tablet-uniffi-bindgen`, biner `uniffi-bindgen` | Biner global | berat | Panduan dan CI memasang alat; AC-3 |
| K3 | Nama paket tooling | `tablet-uniffi-bindgen` | `uniffi-bindgen` | biasa | Nama paket mirip `uniffi_bindgen` milik UniFFI di `Cargo.lock`; membingungkan pembaca |
| K4 | Sumber generasi | Mode pustaka dari pustaka release tiap target, semua harus identik | Sekali dari pustaka host | berat | Opsi 4; AC-6 melemah |
| K5 | Antarmuka skrip | `generate-bindings.sh <swift\|kotlin> <pustaka>...`; skrip tidak membangun `tablet-ffi` | Skrip membangun sendiri | biasa | Skrip build fitur 04 membangun dua kali |
| K6 | Format keluaran | Selalu `--no-format` | Format bila alat ada | berat | Keluaran bergantung pada alat yang terpasang; AC-6 gagal antar mesin |
| K7 | Lokasi header dan modulemap Swift | `target/bindings/swift/headers/TabletFFI/` dengan `module.modulemap` | Folder baru di `bindings/swift/` | biasa | `.gitignore`, kasus C3, dan daftar commit spec 0001 berubah |
| K8 | Isi `uniffi.toml` | Nama dari spec 0001, opsi lain bawaan, checksum aktif | `omit_checksums = true` | biasa | Binding tidak cocok tidak lagi gagal saat dimuat |
| K9 | Cleaner Kotlin Android | Bawaan (`android` tidak diset) sampai ada objek pertama | `android = true` | biasa | Menambah `androidx.annotation` ke binding sekarang, padahal belum ada objek |
| K10 | Mode bahasa Swift `TabletBindings` | Swift 6 (`swiftLanguageModes: [.v6]`, ditulis fitur 04) | Swift 5 | biasa | Probe lulus di kedua mode; Swift 5 menunda pemeriksaan konkurensi ke aplikasi |
| K11 | Versi JNA | `5.18.1` (`@aar`), ditambahkan fitur 04 | `5.12.0` (minimum UniFFI) | biasa | Versi lebih lama tanpa alasan; sudah ada di cache Gradle |
| K12 | Grup Cargo di `scripts/test.sh` | Tidak; tes Rust tetap `cargo test --workspace --locked` | Grup `rust` yang memanggil Cargo | biasa | `scripts/test.sh` tidak lagi bebas build; kontrak runner spec 0001 berubah |
| K13 | Tanda tangan `hello` di inti | `pub fn hello(name: String) -> String`, sama dengan README | `name: &str` | biasa | Satu baris penyimpangan dari README bagian 6 |
| K14 | Pemeriksaan basi | File `.rs` yang tercantum di `libtablet_ffi.d` milik Cargo tidak boleh lebih baru dari pustaka; `.d` wajib ada | Semua file di `crates/`, `Cargo.toml`, `Cargo.lock` | berat | Runner up macet: mengubah `uniffi.toml` atau `Cargo.toml` tidak membuat Cargo membangun ulang, jadi skrip menuntut build yang tidak mengubah apa pun (temuan cross check) |
| K15 | Pencarian konfigurasi generator | `--metadata-no-deps` | `cargo metadata` lengkap (bawaan) | biasa | Generator butuh graf dependensi penuh dan mungkin jaringan di runner baru; probe menunjukkan keluaran identik |
| K16 | Jumlah pustaka per run | Satu atau lebih; skrip build memberi tepat yang dibangunnya; duplikat ditolak | Wajib semua target platform | biasa | `--simulator` atau `--device` saja tidak bisa menghasilkan binding |
| K17 | Folder target Cargo | Hanya `target/` di akar; `CARGO_TARGET_DIR` ditolak | Ikut `CARGO_TARGET_DIR` | biasa | Path keluaran dan aturan pustaka harus dibaca dari variabel, dan `.gitignore` tidak lagi menjamin hasil tidak ter-commit |

## Bukti probe (2026-11-16)

Dijalankan di folder sementara di luar repo, pada salinan `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml`, dan `crates/` dari `962b9c9`, ditambah `hello`, `uniffi.toml`, dan crate tooling seperti `index.md`, kecuali nama paket tooling (probe memakai `uniffi-bindgen`, spec memilih `tablet-uniffi-bindgen`, K3). Repo tidak berubah.

| Pemeriksaan | Hasil |
|---|---|
| `cargo build -p uniffi-bindgen` (crate tooling, fitur `cli`) tanpa jaringan | Berhasil, sekitar 20 detik; `Cargo.lock` mendapat `anstyle`, `clap`, `clap_builder`, `clap_derive`, `clap_lex`, `strsim`, dan paket tooling; tetap satu paket `uniffi` |
| Build release `tablet-ffi` untuk keempat target (`IPHONEOS_DEPLOYMENT_TARGET=26.0`, `cargo ndk --platform 29`) | Keempat pustaka ada |
| `uniffi-bindgen generate --no-format -l swift` dari `.a` `aarch64-apple-ios` dan `aarch64-apple-ios-sim` | `TabletBindings.swift`, `TabletFFI.h`, `TabletFFI.modulemap`; keduanya identik (`diff -r` kosong) |
| `uniffi-bindgen generate --no-format -l kotlin` dari `.so` kedua ABI | `foundation/tablet/bindings/tablet_ffi.kt`; keduanya identik |
| Generasi Swift diulang | Identik dengan hasil pertama |
| `swiftc -typecheck` untuk `arm64-apple-ios26.0-simulator`, `-swift-version 5` dan `6` | Nol galat di kedua mode |
| Isi modulemap | `module TabletFFI { header "TabletFFI.h" export * use "Darwin" use "_Builtin_stdbool" use "_Builtin_stdint" }` |
| Kotlin | Mengimpor `com.sun.jna.*`; tanpa coroutine dan tanpa cleaner (belum ada objek) |
| Opsi generator | `--library` usang, deteksi otomatis; `--no-format` tersedia; konfigurasi Kotlin punya `android`, `android_cleaner`, `omit_checksums`; konfigurasi Swift punya `ffi_module_filename`, `generate_module_map` |
| Cleaner Android UniFFI 0.32.2 | Memakai `SystemCleaner` hanya di API 34 ke atas dan mengimpor `androidx.annotation.RequiresApi`; di bawahnya `UniffiJnaCleaner` |
| `--metadata-no-deps` untuk Swift dan Kotlin | Keluaran identik dengan tanpa flag |
| `cargo fmt --all`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked` dengan `hello(name: String)`, ekspor, tes unit, dan crate tooling | Clippy bersih, satu tes lulus |
| `target/<triple>/release/libtablet_ffi.d` | Ada untuk target Apple dan Android; isinya hanya `crates/core/src/lib.rs` dan `crates/tablet-ffi/src/lib.rs` |
| Kotlin memuat pustaka | `Native.register(..., findLibraryName(componentName = "tablet_ffi"))`, lalu pemeriksaan versi kontrak dan checksum |

## Cross check (2026-11-16)

Mode keputusan `auto`; untuk tier Beta upstream merekomendasikan `Another model`, jadi itu yang dijalankan: subagent baru bertipe `Plan` (hanya baca, tanpa alat sunting), konteks segar tanpa riwayat percakapan, model diminta `fable` (spec ditulis sesi `claude-opus-5-5`). Runtime tidak melaporkan model nyata yang dipakai subagent, jadi kemandiriannya tercatat `unverified` untuk keluarga model, `clean` untuk konteks.

Temuan dan penyelesaian (semua rekomendasi diambil karena didukung bukti; tidak ada fakta yang hanya diketahui user):

| Temuan | Tingkat | Penyelesaian di `index.md` |
|---|---|---|
| Pemeriksaan basi macet bila `uniffi.toml`, `Cargo.toml`, atau file non sumber berubah | tinggi | K14: hanya file `.rs` dari `libtablet_ffi.d` |
| Skrip build `--simulator` atau `--device` hanya membangun satu target | tinggi | K16 dan "Serah terima ke fitur 04": skrip build memberi pustaka yang dibangunnya; XCFramework satu slice sah |
| Arti path, triple, dan nama file pustaka belum tuntas | tinggi | Langkah 1 dan 2 kontrak skrip |
| Path yang dihapus sebelum menulis belum disebut | tinggi | Langkah 6 |
| Keluaran lama terhapus sebelum keluaran baru terperiksa | sedang | Langkah 5 memeriksa isi folder sementara dulu (E13) |
| Generator menjalankan `cargo metadata` lengkap | sedang | K15, `--metadata-no-deps` |
| Pesan, kode keluar, `--help`, `cargo` hilang, `CARGO_TARGET_DIR` | sedang | Tabel E1 sampai E13, K17 |
| Lebih dari dua pustaka dan pustaka ganda | sedang | AC-6 (banding dengan pustaka pertama), E8 |
| Perintah pemeriksaan tipe Swift dan prasyarat build | sedang | AC-4, AC-5 memakai skrip build dan perintah persis |
| AC-3 salah karena `Cargo.toml` akar juga memuat `uniffi` | sedang | AC-3 memakai `git ls-files '*Cargo.toml'` tanpa akar |
| Arti tes asap | sedang | AC-2: panggil `tablet_ffi::hello` dari Rust |
| Bukti Kotlin tanpa string pemeriksaan | sedang | AC-5: empat string `grep -F`, kompilasi `NOT_RUN` |
| Rincian JNA dan SwiftPM untuk fitur 04 | sedang | "Serah terima ke fitur 04" |
| Aturan thread dan kontrak transport belum ada | sedang | Dua baris baru di "Isi konvensi kontrak" |
| Gerbang Rust belum dicoba pada ekspansi makro | sedang | Probe tambahan di atas; gerbang dipindah ke milestone 1 tugas 3 |
| Kalimat dokumen basi belum didaftar | rendah | Tabel "Kalimat dokumen yang diperbarui" |
| Mode `100755`, cara memperbarui `Cargo.lock`, rincian sandbox, portabilitas bash 3.2, kunci `-p tablet-ffi` | rendah | Milestone 1, tugas 3, tugas 11, tugas 12, kontrak skrip |
| `git status --short` kosong tidak berlaku bila tree sudah kotor | rendah | AC-6: sama dengan sebelum skrip dijalankan |

Satu koreksi dari lead sesudah cross check: `cargo config get` belum stabil, jadi E2 memeriksa variabel lingkungan dan keberadaan `target/debug/uniffi-bindgen`, bukan konfigurasi Cargo.
