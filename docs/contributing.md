# Panduan kontribusi

Panduan ini untuk kamu, baik orang maupun agen, yang mengubah repo ini. [`AGENTS.md`](../AGENTS.md) memuat aturan singkatnya; di sini ada rinciannya. Cara membangun dari clone bersih ada di [panduan mulai singkat](getting-started.md), dan struktur serta batas lapisan ada di [catatan arsitektur](architecture/overview.md). Panduan ini tidak menyalin isi dokumen itu; ia menunjuk ke sana.

## Sebelum mengubah

1. **Cari fiturnya.** Buka [indeks scope](scope/index.md) dan file fitur yang kamu kerjakan. Bila file itu menautkan spec, baca keputusan di spec dulu.
2. **Cari pemilik path.** Setiap path punya satu pemilik di [matriks pemilik](architecture/ownership-matrix.md). Taruh kode di folder pemiliknya. Bila lapisan yang cocok belum punya folder, folder itu dibuat oleh fitur pemiliknya, tidak sebagai penanda tempat.
3. **Periksa arah dependensi.** Arah yang boleh dan tujuh aturannya ada di [aturan dependensi](architecture/dependency-rules.md). Perilaku bersama ditulis sekali di Rust; SwiftUI dan Compose tidak menyalin aturan Rust dan tidak membuat definisi kontrak sendiri.
4. **Tentukan platform yang terdampak.** Pakai tabel di bagian berikut. Perubahan pada kontrak bersama selalu menyentuh kedua aplikasi.
5. **Periksa apakah ada keputusan yang belum dibuat.** Bila perubahan butuh pilihan yang memengaruhi struktur dan belum tercatat di spec, catat dulu lewat `/architect` (lihat [Keputusan arsitektur](#keputusan-arsitektur)).

## Pemeriksaan per perubahan

Jalankan semua perintah dari akar repo. Tandanya: **R** berarti pemeriksaan Rust (`cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked`), **T** berarti `scripts/test.sh`, **I** berarti `scripts/build-ipados.sh` lalu `scripts/test.sh artifacts/ipados`, dan **A** berarti `scripts/build-android-tablet.sh` lalu `scripts/test.sh artifacts/android-tablet`.

| Yang kamu ubah | Platform terdampak | Pemeriksaan yang disarankan |
| --- | --- | --- |
| `crates/**`, `Cargo.toml`, `Cargo.lock`, `rust-toolchain.toml` | kedua aplikasi | R, T, I, A |
| Kontrak yang diekspor `tablet-ffi`, `uniffi.toml`, generator binding (`tooling/uniffi-bindgen`, `scripts/generate-bindings.sh`) | kedua aplikasi | R, T, I, A, lalu `scripts/generate-bindings.sh` untuk `swift` dan `kotlin`, lalu `git status --short` harus kosong |
| `apps/ipados/**`, `.xcode-version` | iPad | T, I |
| `apps/android-tablet/**` | Android | T, A |
| `scripts/build-*.sh` | platform skrip itu | T, lalu build skrip itu |
| `scripts/test.sh`, `tests/**` | tidak ada | T, dan grup `artifacts` bila tesnya di sana |
| Token desain dan sumber daya bersama (mulai fitur 08 dan 09) | kedua aplikasi | T, I, A |
| Hanya dokumen | tidak ada | T (memeriksa tautan di `AGENTS.md` dan panduan ini) |

Fitur yang menyentuh tata letak atau input juga memeriksa orientasi tegak dan mendatar, jendela yang menyempit, keyboard, dan pointer pada kedua aplikasi (README bagian 7, 9, 10). Langkahnya ditambahkan oleh fitur 05 sampai 07.

Bila kamu tidak bisa menjalankan satu pemeriksaan (alatnya tidak ada, perangkat tidak tersedia), jangan menyebutnya lulus. Catat sebagai `NOT_RUN` beserta alasannya. Bedakan validasi konfigurasi, kompilasi, uji di simulator atau emulator, dan uji di perangkat fisik.

## Hasil generasi

- Jangan menyunting hasil generasi dengan tangan dan jangan meng-commit-nya. Daftarnya ada di matriks pemilik (kolom "Hasil generasi") dan di `.gitignore` akar.
- Bangun ulang hasil generasi lewat `scripts/` saja. Proyek Xcode dan Gradle tidak memanggil Cargo.
- Sesudah mengubah API yang diekspor `tablet-ffi`, jalankan generator dan kedua skrip build pada commit yang sama, supaya binding kedua aplikasi berasal dari revisi pustaka yang sama. Generatornya `scripts/generate-bindings.sh`; aturan kontraknya (tipe, galat, nullability, kepemilikan nilai, kompatibilitas) ada di [konvensi kontrak FFI](contracts/ffi-conventions.md).
- Bila build dimulai dari tree bersih, `git status --short` harus tetap kosong sesudahnya. Bila ada file baru di sana, berarti ada hasil generasi yang lolos dari `.gitignore`.
- Bila kamu mengubah token desain kanonis, bangun ulang atau validasi keluaran kedua platform di perubahan yang sama (mulai fitur 08).

## Mencatat bukti

Simpan bukti sewaktu fitur diuji, tidak di akhir.

- **Satu baris per kriteria per target.** Pakai kolom pada [contoh bukti di fitur 02](scope/02-aturan-kontribusi.md): kriteria, commit yang diuji, target dan versi OS, perintah atau langkah manual, hasil aktual dan status, lokasi log atau alasan belum diuji. Bila iPad lulus dan Android belum diuji, tulis dua baris.
- **Status hanya `PASS`, `FAIL`, atau `NOT_RUN`.** `NOT_RUN` selalu disertai alasan dan siapa yang bisa menjalankannya.
- **Log** disimpan di `docs/reviews/<tanggal>-<jenis>-f<NN>.md`, misalnya `2026-11-15-verify-f01-m2.md`. Jenisnya `build`, `verify`, `test`, atau `review`. Langkah yang butuh orang atau perangkat fisik dicatat di file manual koordinasi fitur, seperti [contoh fitur 01](scope/coordination/01-arsitektur-dan-build-awal.manual.md).
- **Kotak fitur tetap terbuka** bila pemeriksaan wajib gagal atau belum dijalankan, dan fitur tetap `in-progress`. Tulis langkah terakhir yang terverifikasi dan langkah berikutnya di file fitur.
- Sebelum meng-commit log, hapus rahasia, token, dan identitas penandatanganan (lihat [Log sensitif](#log-sensitif)).

## Keputusan arsitektur

Repo ini mencatat keputusan sebagai spec di `docs/specs/NNNN-judul/`, bukan sebagai ADR terpisah ([struktur repo](architecture/repository-structure.md)). Spec ditulis dan diperbarui lewat `/architect`.

- **Butuh spec:** crate, modul, atau layanan baru; arah dependensi baru; folder baru di akar; perubahan kunci versi atau target; cara pengemasan binding; dependensi baru; izin native baru; dan apa pun yang mengubah tabel di catatan arsitektur.
- **Tidak butuh spec:** perubahan di dalam satu modul yang mengikuti spec yang sudah `Accepted`.
- Spec `Accepted` tidak diubah diam diam. Bila keputusan berubah, perbarui lewat `/architect` sehingga alasannya tercatat, atau tandai `Superseded` dan tautkan penggantinya.
- Bila struktur nyata berubah, perbarui dokumen di `docs/architecture/` pada perubahan yang sama.

## Dependensi

- **Periksa dulu** apakah modul yang ada bisa memegang fungsinya (README bagian 19). Dependensi baru butuh alasan di spec: kebutuhannya, lisensi, dan siapa pemeliharanya.
- **Rust:** tulis versinya sekali di `[workspace.dependencies]` pada `Cargo.toml` akar dengan versi persis (`"=x.y.z"`, seperti `uniffi`), lalu pakai `<nama>.workspace = true` di crate. `Cargo.lock` di-commit dan perintah Cargo memakai `--locked`. `tablet-core` tidak bergantung pada apa pun, dan hanya `tablet-ffi` yang memuat `uniffi` ([aturan dependensi](architecture/dependency-rules.md) 1 dan 2).
- **Android:** versi hanya di `apps/android-tablet/gradle/libs.versions.toml`. Wrapper Gradle memeriksa checksum distribusi lewat `distributionSha256Sum`; bila kamu menaikkan Gradle, perbarui checksum itu dari situs Gradle, bukan dari unduhan lokal.
- **iPad:** belum ada paket Swift dari luar. Bila nanti ada, kunci versi persisnya dan catat di [matriks dukungan](architecture/support-matrix.md).
- Jangan menyalin angka versi ke dokumen lain. Rujuk sumbernya.

## Rahasia dan penandatanganan

- Jangan pernah meng-commit rahasia, kredensial penandatanganan, kunci privat, token produksi, atau nilai lingkungan rahasia (README bagian 12 dan 20.3).
- Nilai lokal disimpan di file yang diabaikan Git: `apps/ipados/Config/Local.xcconfig` (misalnya `DEVELOPMENT_TEAM` dan bundle ID asli, dimuat oleh `Base.xcconfig` lewat `#include?`) dan `apps/android-tablet/local.properties`. Keystore rilis disimpan di luar repo.
- Build lokal dan CI tidak butuh kredensial produksi: skrip iPad membangun dengan `CODE_SIGNING_ALLOWED=NO`, dan Android membangun APK debug dengan kunci debug bawaan.
- Bila rahasia terlanjur di-commit, anggap rahasia itu bocor: cabut dan ganti di layanannya. Menghapus commit saja tidak cukup.

## Izin native

- Tambahkan izin hanya bila fitur yang tercatat di spec membutuhkannya. Saat ini kedua aplikasi tidak meminta izin apa pun, termasuk jaringan.
- **iPad:** `Info.plist` dibuat dari build setting (`GENERATE_INFOPLIST_FILE = YES`), jadi teks alasan izin ditulis sebagai `INFOPLIST_KEY_NS<Nama>UsageDescription` di `apps/ipados/Config/Base.xcconfig`.
- **Android:** tulis `<uses-permission>` di `apps/android-tablet/app/src/main/AndroidManifest.xml`, dan minta izin berbahaya saat dipakai, bukan saat aplikasi dibuka.
- Bila satu aplikasi menambah izin untuk niat bersama, periksa aplikasi lain di perubahan yang sama, supaya keduanya meminta hal yang setara.

## CI

Belum ada workflow di `.github/`. Ketentuan ini berlaku sejak workflow pertama (fitur 04) dan diperluas oleh fitur 11. Dasarnya [panduan keamanan GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use).

- **Izin token minimum.** Tulis `permissions: contents: read` di tingkat workflow, lalu beri izin tambahan hanya pada job yang memerlukannya.
- **Revisi action dikunci.** Setiap `uses:` dari luar repo memakai SHA commit penuh (40 karakter) dengan komentar versinya, misalnya `uses: actions/checkout@<sha> # v5.0.0`. Tag dan branch tidak dipakai.
- **Pull request tanpa rahasia.** Build pull request memakai pemicu `pull_request`, bukan `pull_request_target`, dan tidak membaca rahasia apa pun.
- **Tanpa kredensial penandatanganan produksi.** Job memanggil skrip yang sama dengan lokal (`scripts/build-ipados.sh`, `scripts/build-android-tablet.sh`, `scripts/test.sh`), yang sudah membangun tanpa tanda tangan produksi. Penandatanganan rilis dan publikasi ke toko aplikasi belum termasuk fondasi ini.
- **Kunci alat.** Versi alat di CI dibaca dari sumber kunci yang sama (`rust-toolchain.toml`, `.xcode-version`, katalog dan wrapper Gradle), tidak ditulis ulang di workflow.
- Jangan menulis bahwa build atau tes lulus bila job itu tidak benar benar berjalan sampai selesai.

## Log sensitif

- Jangan mencatat rahasia, token, kredensial, data pribadi, atau nilai yang diketik pengguna (misalnya nama yang dikirim ke Rust di fitur 04) di log aplikasi, log Rust, atau log build.
- **iPad:** pakai `Logger` dari `os` dan biarkan nilai dinamis `privacy: .private`; tandai `.public` hanya untuk nilai yang aman dilihat siapa pun.
- **Android:** jangan memasukkan nilai pengguna ke `Log`. Log pengembangan tidak boleh ikut ke build rilis.
- **Rust:** `tablet-core` tidak mencetak ke konsol. Error membawa jenis dan kode yang terstruktur, bukan isi data pengguna.
- **Log di `docs/reviews/`:** potong bagian yang memuat token, identitas penandatanganan, atau isi file lokal rahasia sebelum di-commit.

## Rust yang memakai `unsafe`

- `tablet-core` tidak memakai `unsafe`.
- Di `tablet-ffi`, `unsafe` hanya datang dari kode yang dibuat makro UniFFI. Blok `unsafe` yang ditulis tangan butuh alasan di spec lebih dulu.
- Setiap blok `unsafe` yang ditulis tangan diberi komentar `// SAFETY:` yang menyebut invarian yang membuatnya aman: validitas pointer, masa hidup, aliasing, dan alasan `Send` atau `Sync` bila ada.
- Perubahan yang menambah atau mengubah `unsafe` ditinjau lewat `/check review` oleh model yang tidak menulis kodenya, sebelum di-merge. Peninjau memeriksa invarian di komentar `SAFETY`, jalur error lewat batas FFI (pakai `Result` dengan error terstruktur, jangan mengandalkan panic), dan tes yang menjalankan jalur itu.
- Pemeriksaan otomatis untuk aturan ini milik fitur 10.

## Menyerahkan pekerjaan

Sebelum berhenti di tengah fitur, tulis langkah terakhir yang terverifikasi dan langkah berikutnya di file fitur, lalu selaraskan status di indeks scope. Sesi berikutnya mulai dari sana.
