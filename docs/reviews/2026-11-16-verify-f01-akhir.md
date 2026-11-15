# Bukti verify: fitur 01, verify ulang akhir (Arsitektur dan build awal)

**Verdict: PASS.** AC-1 sampai AC-11 terpenuhi pada setiap target yang dijanjikan di SHA akhir `main`, dan setiap kalimat **Done when** terbukti. Tidak ada AC yang gagal. Suite tes yang baru masuk lulus sebelum dan sesudah build pada clone yang sama.

Dua daftar di bawah bukan kegagalan AC dan tidak menahan `done`, tetapi perlu dijadwalkan: empat langkah `verify.md` yang teksnya kini usang (bagian "Langkah verify.md yang teksnya usang"), dan tiga kalimat dokumen yang tidak lagi cocok dengan repo sesudah suite tes masuk (bagian "Klaim dokumen yang tidak lagi cocok").

- **Spec:** [0001 Arsitektur dan build awal](../specs/0001-arsitektur-dan-build-awal/index.md), Build plan 1 sampai 16
- **Tanggal jalan:** 2026-11-15 (clone 11:56 UTC; suite cepat 11:56:30 sampai 11:57:45 UTC; build iPad 11:58:34 sampai 11:59:10 UTC; build Android 11:59:10 sampai 11:59:46 UTC; suite penuh 12:00:32 sampai 12:00:52 UTC). Nama file memakai tanggal dari brief lead.
- **Commit yang diuji:** `ba1d3c966dbbdbd412c56dbe60e4f0ebd2f9a6da` (`main`). Selisihnya terhadap `d057965` hanya `docs/scope/coordination/01-arsitektur-dan-build-awal.log.md`.
- **Range perubahan sejak verify penuh:** `f3992db..d057965`. `git diff --stat f3992db..d057965 -- crates apps Cargo.toml Cargo.lock rust-toolchain.toml .xcode-version .gitignore scripts/build-ipados.sh scripts/build-android-tablet.sh` kosong, jadi tidak ada kode produksi, konfigurasi build, atau skrip build yang berubah. Yang berubah: `scripts/test.sh`, `tests/**` (delapan file), `test-preferences.json`, `docs/getting-started.md`, `docs/architecture/ownership-matrix.md`, `docs/architecture/repository-structure.md`, tiga file spec, dan file scope serta bukti.
- **Target:** host `aarch64-apple-darwin`; simulator iPad generik (Debug, `aarch64-apple-ios-sim`); iPad generik (Release tanpa tanda tangan, `aarch64-apple-ios`); APK debug ABI `arm64-v8a` dan `x86_64` (`minSdk` 29, `targetSdk` 36, `compileSdk` 37)
- **OS dan alat:** macOS 27.0.1 (26A434), Darwin 27.0.0, arm64 (M1 Max); Xcode 27.1 (27A9275) terpilih di `/Applications/Xcode.app/Contents/Developer`; `rustc 1.99.1 (58cf8f9c3 2026-10-13)`, rustup 1.29.3, cargo-ndk 4.1.2; Android SDK di `~/Library/Android/sdk` (platform `android-36` dan `android-37.0`, build-tools 36.0.0, NDK 28.2.13676358); JBR `openjdk version "25.0.2"` dari Android Studio; Gradle 9.5.1 lewat wrapper; `/bin/bash` 3.2.57
- **Cara:** `git clone` worktree checker ke folder `mktemp -d` di luar repo. `scripts/test.sh` dijalankan lebih dulu pada clone yang belum pernah dibangun. Sesudah itu enam perintah `docs/getting-started.md` bagian "Perintah repo" dijalankan apa adanya dari akar clone, berurutan, lalu `scripts/test.sh repo build-scripts artifacts`. Di antaranya hanya pemeriksaan yang membaca. `ANDROID_HOME`, `ANDROID_NDK_HOME`, `JAVA_HOME`, dan `DEVELOPER_DIR` tidak diset. `target/`, `apps/ipados/build/`, `apps/android-tablet/app/build/`, dan `apps/android-tablet/.gradle/` belum ada sebelum build.
- **Build lain di mesin:** saat clone dibuat ada satu `xcodebuild` milik repo lain. Skrip pembungkus menunggu `pgrep -x xcodebuild` kosong sebelum build iPad dan sebelum build Android; waktu tunggunya 0 detik pada keduanya. Disk bebas 26 GiB saat mulai, 24 GiB sebelum build iPad, 23 GiB sebelum build Android, 24 GiB sesudah pembersihan (batas berhenti 10 GiB).
- **Pemeriksa:** sub sesi `chk-f1-verify` (checker, mode verify), `claude-fable-5-2 · high`
- **Pembanding:** [verify penuh pada `f3992db`](2026-11-15-verify-f01.md) dan [bukti tes pada `6e1fb8a`](2026-11-15-test-f01.md). Hasil di sini sama pada setiap baris yang bisa dibandingkan: ukuran kedua `.a` iPad (18.737.288 dan 18.728.560 byte), kedua `.so` (557.920 dan 526.480 byte), delapan baris `LOAD`, ukuran APK (29.356.319 byte), dan 52 kasus tes.

## Satu hasil per AC dan target pada `ba1d3c9`

| AC | Target dan OS | Jenis | Perintah | Hasil aktual | Status |
|---|---|---|---|---|---|
| AC-1 (README AC 1) | Host `aarch64-apple-darwin`, macOS 27.0.1 | build | `rustup toolchain install`, `rustc --version`, `cargo build --workspace --locked`, `cargo test --workspace --locked`, `git ls-files Cargo.lock`; kasus B1, V2 | Semua keluar `0`; `rustc 1.99.1`; empat baris `test result: ok. 0 passed`; `Cargo.lock` terlacak | PASS |
| AC-2 (README AC 2) | Host `aarch64-apple-darwin` | konfigurasi dan build | `cargo metadata --no-deps`, dua `cargo tree`, `ls target/debug/libtablet_ffi.{a,dylib}`, `grep crate-type`; kasus B2 sampai B6, V3 | Tepat dua anggota workspace. Pohon inti satu baris. `tablet-ffi` punya tepat dua anak: `tablet-core v0.1.0` dan `uniffi v0.32.2`. Kedua pustaka host ada. `crate-type = ["lib", "staticlib", "cdylib"]` | PASS |
| AC-3 | `aarch64-apple-ios-sim` | build | `scripts/build-ipados.sh`, `ls`; kasus HI1 | `target/aarch64-apple-ios-sim/release/libtablet_ffi.a` ada (18.728.560 byte) | PASS |
| AC-3 | `aarch64-apple-ios` | build | sama | `target/aarch64-apple-ios/release/libtablet_ffi.a` ada (18.737.288 byte) | PASS |
| AC-3 | `aarch64-linux-android` | build | `scripts/build-android-tablet.sh`, `ls`; kasus HA1 | `libtablet_ffi.so` ada (557.920 byte), `elf64-littleaarch64` | PASS |
| AC-3 | `x86_64-linux-android` | build | sama | `libtablet_ffi.so` ada (526.480 byte), `elf64-x86-64` | PASS |
| AC-4 | `aarch64-linux-android`, NDK 28.2.13676358 | konfigurasi biner | `llvm-objdump -p <file.so> \| grep LOAD`; kasus HA2 | Empat baris `LOAD`, semuanya berakhir `align 2**14` | PASS |
| AC-4 | `x86_64-linux-android`, NDK 28.2.13676358 | konfigurasi biner | sama | Empat baris `LOAD`, semuanya berakhir `align 2**14` | PASS |
| AC-5 | Simulator iPad generik, Debug, Xcode 27.1 | build | `scripts/build-ipados.sh` (dari panduan), `lipo`, dua `plutil`; kasus HI2, I7, I9, V9 | Keluar `0`, `BUILD SUCCEEDED`; app ada; `arm64`, `26.0`, `[2]`; nol peringatan headermap | PASS |
| AC-6 | iPad generik, Release tanpa tanda tangan, Xcode 27.1 | build | sama, lalu `codesign -dv`; kasus HI3 | Keluar `0`, `BUILD SUCCEEDED`; app ada; `arm64`, `26.0`, `[2]`; `code object is not signed at all` (keluar 1); tanpa folder `_CodeSignature` | PASS |
| AC-7 | APK debug, ABI `arm64-v8a` dan `x86_64`; AGP 9.3.3, Gradle 9.5.1, JDK 25.0.2 | build | `scripts/build-android-tablet.sh`, `aapt2 dump badging`, `unzip -l`; kasus HA3, HA4, A8, A9 | Keluar `0`, `BUILD SUCCESSFUL in 21s`, `36 actionable tasks: 36 executed`; `minSdkVersion:'29'`, `targetSdkVersion:'36'`, `compileSdkVersion='37'`; `lib/` hanya `arm64-v8a/` dan `x86_64/`; `native-code: 'arm64-v8a' 'x86_64'` | PASS |
| AC-8 | Kunci versi di file repo | konfigurasi | Baca file kolom "Dikunci di"; `diff` blok `Base.xcconfig` terhadap spec; `grep buildToolsVersion`; kasus V1 sampai V7 | Semua nilai sama dengan tabel "Proposed stack" (tabel itu tidak berubah di range). `Base.xcconfig` sama persis dengan blok spec. `buildToolsVersion` tidak diset. SHA-256 `gradle-wrapper.jar` = `497c8c2a…a9c7` | PASS |
| AC-8 | Kotlin bawaan AGP | build | `JAVA_HOME=<JBR> ./gradlew -q buildEnvironment` | `kotlin-gradle-plugin:2.4.21`; satu baris `2.2.10 -> 2.4.21`; AGP `9.3.3`; `compose-compiler-gradle-plugin:2.4.21` | PASS |
| AC-8 | Prasyarat hilang, skrip Android | konfigurasi | `ANDROID_HOME=<folder kosong> scripts/build-android-tablet.sh`; kasus A1 sampai A8 | Keluar `1`; menyebut platform Android 37 dan perintah `sdkmanager "platforms;android-37.0"` | PASS |
| AC-8 | Prasyarat hilang, skrip Android | konfigurasi | `JAVA_HOME=/tidak/ada scripts/build-android-tablet.sh` | Keluar `1`; menyebut `JAVA_HOME` dan cara menyetelnya ke JDK 25 | PASS |
| AC-8 | Prasyarat hilang, skrip iPad | konfigurasi | `DEVELOPER_DIR=/tidak/ada scripts/build-ipados.sh`; kasus I1 sampai I6 | Keluar `1`; menyebut `DEVELOPER_DIR` dan `unset DEVELOPER_DIR` | PASS |
| AC-9 | Clone baru, macOS 27.0.1, semua target build | build | Enam perintah panduan apa adanya; `git ls-files -s scripts apps/android-tablet/gradlew`; kasus C4, V8 | Keenamnya keluar `0` tanpa langkah lain; AC-1, AC-3, AC-5, AC-6, AC-7 terulang; mode `100755` untuk kedua skrip build, `gradlew`, dan `scripts/test.sh`; panduan memuat prasyarat, versi, cara memasang, dan perintah persis | PASS |
| AC-10 | `docs/architecture/` (lima dokumen) | konfigurasi (isi dokumen) | `diff` tabel dokumen terhadap tabel spec yang kini lebih panjang; pemeriksaan tautan; kasus V8 | Pemilik: 13 baris, empat kolom pertama sama persis dengan spec. Penyimpangan: 14 baris sama persis. Diagram dan tujuh aturan sama persis. Matriks dukungan tidak berubah di range dan tabel spec-nya tidak berubah. Hal yang belum dibangun tetap bertanda jelas | PASS |
| AC-11 | Repo dan kedua aplikasi | konfigurasi dan build | `cat` tiga file sumber aplikasi; `nm ... \| grep -ci uniffi`; `unzip -l "$APK" \| grep libtablet_ffi`; `git ls-files \| grep -E ...`; `file --mime-encoding`; pemeriksaan file kosong; `git status --short`; kasus C1, C2, C3, C5, I11, HI4, HA5 | `WindowGroup { Text("Tablet") }` dan `setContent { MaterialTheme { Text("Tablet") } }`; `uniffi` nol simbol di kedua app iPad; `libtablet_ffi` tidak ada di APK; satu satunya biner terlacak `gradle-wrapper.jar`; tidak ada file kosong atau penanda tempat di antara 87 file terlacak; `git status --short` kosong sesudah kedua skrip, sesudah suite tes, dan sesudah semua pemeriksaan | PASS |
| AC-6, iPad fisik | iPadOS 26.0 atau lebih baru | perangkat fisik | MAN-1 (F01-1) | Tidak dijalankan. Bukan syarat AC-6 menurut teks AC. Penanggung jawab user | NOT_RUN |
| AC-7, tablet Android fisik | Android 10 atau lebih baru, arm64 | perangkat fisik | MAN-2 (F01-2) | Tidak dijalankan. Bukan syarat AC-7 menurut teks AC. Penanggung jawab user | NOT_RUN |
| AC-4, perangkat 16 KB | `getconf PAGE_SIZE` = `16384` | perangkat fisik | MAN-3 (F01-3) | Tidak dijalankan. Bukan syarat AC-4 menurut teks AC. Penanggung jawab user | NOT_RUN |

Setiap path pada spec bagian "Struktur repo fitur 01" ada di `git ls-files` (44 path diperiksa satu per satu dengan `git ls-files --error-unmatch`, nol yang hilang). Tidak ada surface yang ditetapkan tetapi belum dibangun.

## Done when pada file fitur

| Kalimat | Bukti | Status |
|---|---|---|
| Kontributor dapat mengompilasi workspace Rust dan kedua proyek native minimal dari clone bersih dengan perintah repo pada panduan mulai singkat | Enam perintah panduan pada clone baru, semuanya keluar `0`; AC-9 | PASS |
| Versi yang dipilih cocok dengan dokumentasi resmi | Tabel "Proposed stack" dan `rationale.md` bagian "Bukti pemeriksaan" serta References tidak berubah di range (44 URL, himpunannya masih sama persis dengan `support-matrix.md`). Kombinasi itu terkompilasi lagi di sini. Saya tidak memeriksa ulang tiap versi ke web | PASS, dengan batas yang sama seperti verify penuh |
| Catatan arsitektur memuat matriks dukungan, pemilik tiap bagian, arah dependensi, dan alasan penyimpangan | AC-10 | PASS |
| AC 1 README | AC-1 | PASS |
| AC 2 README | AC-2 | PASS |

## Perintah baru: suite tes

| No | Perintah (dari akar clone) | Hasil aktual | Status |
|---|---|---|---|
| 1 | `scripts/test.sh` sebelum build apa pun | Keluar `0` dalam 75 detik. `test: 5 file, 5 lulus, 0 gagal`; 43 baris `ok`, nol `not ok` (grup `repo` 20, `build-scripts` 23). Sesudahnya `git status --short --ignored` kosong | PASS |
| 2 | `scripts/test.sh tidak-ada` | Keluar `2`; stderr `test: argumen tidak dikenal: tidak-ada` lalu pemakaian | PASS |
| 3 | `scripts/test.sh --help` | Keluar `0`, mencetak pemakaian | PASS |
| 4 | `scripts/test.sh artifacts` pada clone yang belum dibangun | Keluar `1`. Tujuh kasus merah (HA1 sampai HA4, HI1 sampai HI3), tiap pesan menyebut skrip build yang harus dijalankan. HA5 dan HI4 tetap `ok`. `test: 2 file, 0 lulus, 2 gagal` | PASS (sesuai rancangan) |
| 5 | `scripts/test.sh repo build-scripts artifacts` sesudah kedua skrip build pada clone yang sama | Keluar `0` dalam 20 detik. `test: 7 file, 7 lulus, 0 gagal`; 52 baris `ok`, nol `not ok` (`1..5`, `1..6`, `1..9`, `1..12`, `1..11`, `1..5`, `1..4`) | PASS |
| 6 | `git status --short --ignored` sesudah langkah 5 | Hanya `apps/android-tablet/.gradle/`, `apps/android-tablet/app/build/`, `apps/ipados/build/`, `target/` | PASS |

## Langkah `verify.md` yang dijalankan ulang

Semua langkah bagian `## Milestone 4` (27 langkah) dijalankan lagi pada clone baru dan lulus. Dari milestone 1 sampai 3 dijalankan ulang langkah yang hasilnya bergantung pada daftar file terlacak, ditambah pemeriksaan build yang ikut terulang lewat panduan.

| Baris `verify.md` | Langkah | Hasil aktual | Status |
|---|---|---|---|
| 23 | `git ls-files Cargo.lock` | `Cargo.lock` | PASS |
| 30, 71, 121 | `git ls-files \| grep -E '\.(a\|so\|apk)$\|xcframework\|/build/\|^target/'` | Kosong, keluar `1` | PASS |
| 121 | `git ls-files -z \| xargs -0 file --mime-encoding \| grep -w binary` | Hanya `gradle-wrapper.jar` (87 file terlacak) | PASS |
| 31, 72, 122, 174 | `git status --short` sesudah build | Kosong | PASS |
| 32 | `git check-ignore -v` untuk 21 path | 21 baris | PASS |
| 69 | `git ls-files apps/ipados scripts .xcode-version` | Delapan file, bukan enam. Lihat daftar teks usang nomor 1 | Teks usang, AC-11 tetap PASS |
| 70 | `git ls-files -s scripts/build-ipados.sh` | `100755` | PASS |
| 119 | `git ls-files apps/android-tablet scripts/build-android-tablet.sh` | Tepat 14 file, sama dengan spec | PASS |
| 120, 173 | `git ls-files -s scripts apps/android-tablet/gradlew` | Empat baris, semuanya `100755`. Lihat daftar teks usang nomor 2 dan 3 | Teks usang, AC-9 tetap PASS |
| 156 | `awk ... \| diff - apps/ipados/Config/Base.xcconfig; echo $?` | Tanpa selisih, `0` | PASS |
| 157 | `git diff 610cefb -- apps/ipados/Config/Base.xcconfig` | Satu baris `+ALWAYS_SEARCH_USER_PATHS = NO` | PASS |
| 161 | `grep -A11 '^## Perintah repo' docs/getting-started.md` | Blok enam baris, `diff` terhadap blok spec kosong | PASS |
| 162 sampai 165 | `rustup toolchain install`, `rustc --version`, `cargo install cargo-ndk`, `cargo build`, `cargo test` | Semua keluar `0`; `rustc 1.99.1`; `cargo build` 17 detik; `test result: ok` empat kali | PASS |
| 166, 167 | `scripts/build-ipados.sh > "$LOG_IPAD" 2>&1` | Keluar `0` dalam 36 detik; `BUILD SUCCEEDED` = `2`; baris terakhir `build-ipados: selesai`; `Traditional headermap` = `0`; nol `error:`; dua `warning:` App Intents yang sudah dikenal | PASS |
| 168, 169 | Bukti pada kedua app iPad | `arm64`, `26.0`, `[2]` pada keduanya; app Release `not signed at all` | PASS |
| 170 | `scripts/build-android-tablet.sh` | Keluar `0` dalam 36 detik; `BUILD SUCCESSFUL in 21s`; baris terakhir `build-android-tablet: selesai` | PASS |
| 171 | `ls` empat pustaka | Keempatnya ada | PASS |
| 172 | `aapt2 dump badging`, `unzip -l` | `29`, `36`, `37`; `lib/` hanya dua ABI matriks | PASS |
| 175 | Tidak ada langkah di luar panduan yang diperlukan | Keenam perintah keluar `0` tanpa perintah lain dan tanpa variabel lingkungan tambahan | PASS |
| 179 | Isi `docs/getting-started.md` | Semua isi yang disebut langkah ada. Bagian baru "Menjalankan tes" memuat empat perintah yang sama persis dengan spec (`diff` kosong). Lihat teks usang nomor 4 | PASS |
| 180 | Isi `docs/architecture/overview.md` | Lima baris lapisan, tautan ke empat dokumen lain, sembilan baris "Ditetapkan, belum dibangun". Baris lapisan E belum menyebut suite tes; lihat klaim dokumen nomor 2 | PASS |
| 181 | Isi `docs/architecture/support-matrix.md` | File dan tabel spec-nya tidak berubah di range; kasus V8 lulus; 44 URL sama persis dengan `rationale.md` | PASS |
| 182 | Isi `docs/architecture/ownership-matrix.md` | 13 baris, sama persis dengan tabel spec yang baru (termasuk baris `tests/...` dan `test-preferences.json`) | PASS |
| 183 | Isi `docs/architecture/dependency-rules.md` | Diagram dan tujuh aturan sama persis dengan spec | PASS |
| 184 | Isi `docs/architecture/repository-structure.md` | 14 baris penyimpangan sama persis dengan spec. Blok "Struktur nyata" memuat ke 40 file terlacak di luar `docs/` dan `.claude/`, termasuk `scripts/test.sh`, delapan file `tests/`, dan `test-preferences.json` | PASS |
| 185 | Angka versi dokumen terhadap file repo | Sama (dibaca langsung dan lewat kasus V8) | PASS |
| 186 | Tautan relatif keenam dokumen | Tanpa keluaran `HILANG`; 19 tujuan diperiksa (3, 1, 7, 1, 2, 5) | PASS |
| 187 | `ls docs/architecture` | Tepat lima file, tanpa `boundaries.md`, tanpa file kosong | PASS |
| 188 | Pembersihan | Lihat "Pembersihan" | PASS |

## Langkah `verify.md` yang teksnya usang

Ini bukan kegagalan AC. Centang tidak saya cabut dan teks tidak saya sunting. Pemilik teks: developer (`dev-f1-m1`).

| No | Baris | Teks yang usang | Keluaran nyata pada `ba1d3c9` | Teks pengganti yang saya sarankan |
|---|---|---|---|---|
| 1 | 69 | `git ls-files apps/ipados scripts .xcode-version` → "tepat enam file: `.xcode-version`, ..., `scripts/build-ipados.sh`" | Delapan file: enam file itu ditambah `scripts/build-android-tablet.sh` (sejak milestone 3) dan `scripts/test.sh` (sejak milestone 5). Keduanya sah menurut spec bagian "Struktur repo fitur 01" | `git ls-files apps/ipados .xcode-version scripts/build-ipados.sh` → tepat enam file (daftar yang sama), tanpa folder atau file penanda |
| 2 | 120 | `git ls-files -s scripts apps/android-tablet/gradlew` → "mode `100755` untuk `scripts/build-android-tablet.sh`, `scripts/build-ipados.sh`, dan `apps/android-tablet/gradlew`" | Empat baris, semuanya `100755`: tiga file itu ditambah `scripts/test.sh` | "setiap baris bermode `100755`: `apps/android-tablet/gradlew`, `scripts/build-android-tablet.sh`, `scripts/build-ipados.sh`, dan `scripts/test.sh`" |
| 3 | 173 | Sama dengan nomor 2, pada bagian milestone 4 | Sama dengan nomor 2 | Sama dengan nomor 2 |
| 4 | 179 | Daftar isi wajib `docs/getting-started.md` berhenti di "masalah umum (JDK, `ANDROID_HOME`, target Rust)" | Tabel spec "Catatan arsitektur yang ditulis developer" kini juga mewajibkan bagian "Menjalankan tes" dengan empat perintah `scripts/test.sh`. Bagian itu ada dan sama persis dengan spec | Tambahkan di akhir daftar: "dan bagian 'Menjalankan tes' dengan empat perintah `scripts/test.sh` yang sama dengan spec bagian 'Perintah tes dan kontrak `scripts/test.sh`'" |

Saran tambahan, bukan teks usang: `verify.md` belum punya langkah untuk suite tes. Tiga langkah yang saya jalankan di sini bisa dipakai apa adanya: `scripts/test.sh` pada clone yang belum dibangun → keluar `0`, `test: 5 file, 5 lulus, 0 gagal`, lalu `git status --short --ignored` kosong; `scripts/test.sh artifacts` pada clone itu → keluar `1` dengan pesan yang menyebut skrip build; `scripts/test.sh repo build-scripts artifacts` sesudah kedua skrip build → keluar `0`, `test: 7 file, 7 lulus, 0 gagal`.

## Klaim dokumen yang tidak lagi cocok

Ketiganya ada di file yang tidak termasuk tugas 15 spec (tugas itu hanya menyebut `getting-started.md` bagian baru, `ownership-matrix.md`, dan `repository-structure.md`), jadi tester memang tidak boleh menyentuhnya. Teks AC-9 dan AC-10 tetap terpenuhi, jadi ini bukan FAIL. Pemilik: developer.

| No | File dan baris | Kalimat | Keadaan repo sekarang | Saran |
|---|---|---|---|---|
| 1 | `docs/architecture/dependency-rules.md:26` | "Belum ada pemeriksaan otomatis (fitur 10). Sampai ada, kamu bisa memeriksa aturan 1 dan 2 dengan:" | `scripts/test.sh` sudah memeriksa sebagian aturan itu tanpa build: B3 dan B6 (aturan 1 dan 2, sisi `uniffi`), B4 (aturan 2), C1 (aturan 7), serta HI4 dan HA5 (pohon kerja bersih sesudah build) | "`scripts/test.sh` memeriksa aturan 1, 2, dan 7 pada sisi yang bisa dibaca dari file terlacak (kasus B3, B4, B6, C1). Pemeriksaan arah dependensi yang lengkap milik fitur 10. Kamu juga bisa memeriksa aturan 1 dan 2 dengan:" |
| 2 | `docs/architecture/overview.md:13` | Baris lapisan E: "Kunci versi (...) dan dua skrip build di `scripts/`. Generator binding dan validasi belum ada" | Lapisan E kini juga memuat `scripts/test.sh`, delapan file di `tests/`, dan `test-preferences.json` (ketiganya berlabel Tooling (E) di `ownership-matrix.md`) | "Kunci versi (...), dua skrip build dan `scripts/test.sh` di `scripts/`, serta tes tingkat repo di `tests/`. Generator binding dan validasi arsitektur (fitur 10) belum ada" |
| 3 | `docs/getting-started.md:64` | "Pada fitur 01 belum ada tes, jadi hasilnya `test result: ok` dengan nol tes." | Fitur 01 punya 52 kasus tes tingkat repo. Yang belum ada hanya tes Rust | "Pada fitur 01 belum ada tes Rust, jadi hasilnya `test result: ok` dengan nol tes. Tes tingkat repo ada di bagian 'Menjalankan tes'." |

Di luar itu saya tidak menemukan klaim "belum ada" yang salah: `tests/fixtures`, `tests/contracts`, `bindings/`, `design-system/`, `shared/`, `tooling/`, `.github/`, `scripts/generate-bindings.sh`, `uniffi.toml`, dan `boundaries.md` memang belum ada. Baris `**Status**: In Progress` di spec dan baris `Verify it` di file scope (masih menunjuk `f3992db`) adalah milik lead saat fitur ditandai `done`.

## Tafsiran AC

- **Perangkat fisik bukan syarat AC fitur 01.** Sama dengan verify penuh. AC-6 menulis "AC ini hanya menjanjikan build", AC-7 menulis "di tablet fisik adalah langkah manual", dan bukti AC-4 hanya keselarasan ELF. F01-1 sampai F01-3 dicatat `NOT_RUN` tanpa menahan verdict.
- **AC-9, mode berkas:** teks AC menyebut "mode `100755` untuk kedua skrip dan `gradlew`". Perintahnya kini mencetak empat baris karena `scripts/test.sh` ikut. Keempatnya `100755`, jadi AC terpenuhi; kasus C4 menegaskan hal yang sama untuk setiap baris.
- **AC-10 dan klaim dokumen yang usang:** teks AC-10 meminta matriks dukungan, pemilik, arah dependensi, penyimpangan, dan tanda "belum dibangun". Semuanya ada dan sama dengan spec. Tiga kalimat pada daftar di atas berada di luar isi yang diminta AC, jadi saya mencatatnya sebagai perbaikan teks, bukan FAIL.
- **`scripts/test.sh` sebelum enam perintah panduan:** brief meminta suite cepat dijalankan sebelum build. Suite itu hanya membaca dan tidak menulis ke repo (`git status --short --ignored` kosong sesudahnya), jadi pengulangan panduan sesudahnya tetap sah sebagai clone yang belum dibangun.

## Batas bukti

- **Mesin ini bukan mesin kosong.** Toolchain Rust 1.99.1 dengan keempat target, `cargo-ndk` 4.1.2, distribusi Gradle 9.5.1, dan cache Maven sudah terpasang. `rustup toolchain install` dan `cargo install` hanya memastikan versi. Pemasangan prasyarat dari nol tidak teramati, jadi bagian "Cara memasang prasyarat" hanya diperiksa isinya.
- **Yang dibangun dari nol di clone:** semua keluaran Cargo, kedua app iPad, dan APK (`36 actionable tasks: 36 executed`).
- **Aplikasi tidak diluncurkan** di simulator, emulator, atau perangkat. Fitur 01 hanya menjanjikan build.
- **Linux tidak diuji.** Suite tes dan kedua skrip hanya dibuktikan di macOS; pembuktian di runner Linux milik fitur 11.
- Kasus V2 lulus karena toolchain 1.99.1 sudah terpasang sebelum `rustup toolchain install` dijalankan. Di mesin kosong, suite cepat yang dijalankan sebelum perintah pertama panduan akan merah di V2 dengan pesan `rustup toolchain install`; itu sesuai rancangan tetapi tidak teramati di sini.
- `/bin/bash scripts/test.sh` sebagai pemanggilan terpisah tidak saya ulang (tester sudah membuktikannya); runner sendiri menjalankan tiap file tes dengan `/bin/bash` 3.2.57.
- Tiga percobaan prasyarat hilang dijalankan pada clone yang sudah dibangun, jadi "tanpa build" di sini terbukti dari kode keluar `1` dalam waktu kurang dari satu detik dan dari kasus sandbox I1, A1, A4, bukan dari ketiadaan `target/`.

## Hal yang bekerja tetapi patut diperhatikan

- Suite cepat butuh 75 detik pada jalan pertama, saat mesin juga membangun repo lain. Spec menyebut grup `repo` selesai dalam "beberapa detik". Jalan kedua (tujuh file) selesai dalam 20 detik. Saya tidak mengukur file mana yang lambat.
- Dua peringatan App Intents tetap tercetak pada tiap build iPad (sudah dicatat di `rationale.md` K29).
- Temuan lama nomor 2 dari verify penuh masih berlaku: panduan mengandaikan Android Studio ada dan tidak memberi jalur pasang JDK 25 berdiri sendiri.

## Pembersihan

- Perintah pembersihan panduan dijalankan apa adanya dengan `JAVA_HOME` tidak diset: `(cd apps/android-tablet && JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}" ./gradlew --stop)` → `1 Daemon stopped`, keluar `0`. Ini membuktikan perbaikan `97d9246`; pada verify penuh baris lama gagal. Daemon Gradle 9.5.1 sudah tidak ada. Daemon 9.3.1 milik repo lain tidak disentuh.
- Clone sementara `/var/folders/sx/35k0wvh13dg0cgpr19hnkjb80000gp/T/tmp.7qFmbrO5cE` dihapus dengan path literal, beserta `target/` (690 MB), `apps/ipados/build/` (118 MB), dan `apps/android-tablet/app/build/` (63 MB). Folder kosong untuk percobaan `ANDROID_HOME` juga dihapus.

## Keluaran

Log dipotong ke baris kunci. `<clone>` adalah folder sementara yang sudah dihapus.

```text
$ git merge main; git log --oneline main..HEAD        (worktree checker)
(kosong)
$ git diff --stat f3992db..d057965 -- crates apps Cargo.toml Cargo.lock rust-toolchain.toml .xcode-version .gitignore scripts/build-ipados.sh scripts/build-android-tablet.sh
(kosong)

$ git clone -q /Users/ojiepermana/Worktrees/tablet/chk-f1-verify-4078a9 <clone>; git rev-parse HEAD
ba1d3c966dbbdbd412c56dbe60e4f0ebd2f9a6da
$ ls -d target apps/ipados/build apps/android-tablet/app/build apps/android-tablet/.gradle
ls: ... No such file or directory   (keempatnya)
ANDROID_HOME=<unset> ANDROID_NDK_HOME=<unset> JAVA_HOME=<unset> DEVELOPER_DIR=<unset>

$ scripts/test.sh; echo $?                              (sebelum build, 75 detik)
# tests/repo/commit-policy.test.sh
ok 1 - C1 AC-11 tidak ada hasil build terlacak
ok 2 - C2 AC-11 biner terlacak hanya dari daftar izin
ok 3 - C3 AC-11 .gitignore akar mengabaikan semua hasil build dan file lokal
ok 4 - C4 AC-9 skrip dan gradlew bermode 100755
ok 5 - C5 AC-11 tanpa file kosong atau file penanda tempat
1..5
# tests/repo/crate-boundary.test.sh
ok 1 - B1 AC-1 Cargo.lock ter-commit
ok 2 - B2 AC-2 workspace memuat tablet-core dan tablet-ffi
ok 3 - B3 AC-2 tablet-core tidak menarik uniffi
ok 4 - B4 AC-2 tablet-ffi bergantung pada tablet-core dan uniffi
ok 5 - B5 AC-2 tablet-ffi menghasilkan staticlib dan cdylib
ok 6 - B6 AC-2 hanya tablet-ffi yang memuat uniffi
1..6
# tests/repo/version-locks.test.sh
ok 1 - V1 AC-8 channel dan targets rust-toolchain.toml
ok 2 - V2 AC-1,AC-8 rustc di akar repo sama dengan channel
ok 3 - V3 AC-2,AC-8 uniffi dikunci persis dan sama dengan Cargo.lock
ok 4 - V4 AC-8 wrapper Gradle dikunci dengan checksum
ok 5 - V5 AC-8 katalog versi Gradle lengkap dan berbentuk angka
ok 6 - V6 AC-8 build.gradle.kts membaca nilai dari katalog dan gradle.properties
ok 7 - V7 AC-8 buildSettings project.pbxproj kosong
ok 8 - V8 AC-9,AC-10 dokumen mengikuti sumber nilai
ok 9 - V9 AC-5,AC-6,AC-7 janji matriks ada di konfigurasi
1..9
# tests/build-scripts/build-android-tablet.test.sh
ok 1 - A1 AC-8 SDK tanpa platform dihentikan
ok 2 - A2 AC-8 ANDROID_HOME yang tidak ada dihentikan
ok 3 - A3 AC-8 NDK yang hilang dihentikan
ok 4 - A4 AC-8 JAVA_HOME yang tidak ada dihentikan
ok 5 - A5 AC-8 JDK versi lain dihentikan
ok 6 - A6 AC-8 cargo-ndk versi lain atau hilang dihentikan
ok 7 - A7 AC-8 target Rust Android yang hilang dihentikan
ok 8 - A8 AC-7,AC-8 ABI di luar matriks ditolak
ok 9 - A9 AC-3,AC-7 jalur lulus
ok 10 - A10 AC-8 nilai diteruskan dari sumbernya
ok 11 - A11 AC-8 ANDROID_HOME bawaan di HOME
ok 12 - A12 AC-8 argumen salah dihentikan
1..12
# tests/build-scripts/build-ipados.test.sh
ok 1 - I1 AC-8 DEVELOPER_DIR yang tidak ada dihentikan
ok 2 - I2 AC-8 Command Line Tools ditolak
ok 3 - I3 AC-8 Xcode selain 27 ditolak
ok 4 - I4 AC-8 Xcode 27 lain hanya diberi peringatan
ok 5 - I5 AC-8 target Rust simulator yang hilang dihentikan
ok 6 - I6 AC-8 cargo yang hilang dihentikan
ok 7 - I7 AC-3,AC-5,AC-6 jalur lulus tanpa argumen
ok 8 - I8 AC-8 IPHONEOS_DEPLOYMENT_TARGET dibaca dari Base.xcconfig
ok 9 - I9 AC-5,AC-6 --simulator dan --device masing masing
ok 10 - I10 AC-8 argumen salah dan --help
ok 11 - I11 AC-11 skrip tidak membuat file di repo
1..11
test: 5 file, 5 lulus, 0 gagal
0
$ git status --short --ignored
(kosong)

$ scripts/test.sh tidak-ada; echo $?
test: argumen tidak dikenal: tidak-ada
Pemakaian: scripts/test.sh [<grup> | <grup>/<nama>]...
Tanpa argumen: grup repo lalu build-scripts. Grup artifacts hanya berjalan bila disebut.
Grup yang ada: artifacts build-scripts repo
2

$ scripts/test.sh artifacts; echo $?                    (clone belum dibangun)
not ok 1 - HA1 AC-3 pustaka Rust Android ada untuk tiap ABI
# target/aarch64-linux-android/release/libtablet_ffi.so (ABI arm64-v8a) tidak ada atau kosong; jalankan scripts/build-android-tablet.sh lebih dulu
...
ok 5 - HA5 AC-11 pohon kerja bersih sesudah build
not ok 1 - HI1 AC-3 pustaka Rust iPad perangkat dan simulator ada
# target/aarch64-apple-ios/release/libtablet_ffi.a tidak ada atau kosong; jalankan scripts/build-ipados.sh (tanpa argumen) lebih dulu
...
ok 4 - HI4 AC-11 pohon kerja bersih sesudah build
test: 2 file, 0 lulus, 2 gagal
1

$ rustup toolchain install; echo $?
info: using existing install for 1.99.1-aarch64-apple-darwin
info: the active toolchain `1.99.1-aarch64-apple-darwin` has been installed
0
$ rustc --version
rustc 1.99.1 (58cf8f9c3 2026-10-13)
$ rustup target list --installed
aarch64-apple-darwin
aarch64-apple-ios
aarch64-apple-ios-sim
aarch64-linux-android
aarch64-pc-windows-msvc
x86_64-linux-android

$ cargo install cargo-ndk --version 4.1.2 --locked; echo $?
     Ignored package `cargo-ndk v4.1.2` is already installed, use --force to override
0
$ cargo build --workspace --locked; echo $?
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 17.00s
0
$ cargo test --workspace --locked; echo $?
test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out   (4 kali)
0

$ scripts/build-ipados.sh > "$LOG_IPAD" 2>&1; echo $?      (36 detik)
0
build-ipados: Xcode 27.1, iPadOS minimum 26.0
build-ipados: cargo build tablet-ffi untuk aarch64-apple-ios-sim
build-ipados: cargo build tablet-ffi untuk aarch64-apple-ios
build-ipados: xcodebuild Debug untuk simulator iPad generik
build-ipados: xcodebuild Release untuk iPad generik tanpa tanda tangan
build-ipados: selesai
$ grep -c 'BUILD SUCCEEDED' "$LOG_IPAD"; grep -c 'Traditional headermap' "$LOG_IPAD"; grep -c 'error:' "$LOG_IPAD"
2
0
0

$ lipo -archs $P/Debug-iphonesimulator/Tablet.app/Tablet; plutil -extract MinimumOSVersion raw ...; plutil -extract UIDeviceFamily json -o - ...
arm64
26.0
[2]
$ lipo -archs $P/Release-iphoneos/Tablet.app/Tablet; plutil ...; plutil ...; codesign -dv $P/Release-iphoneos/Tablet.app
arm64
26.0
[2]
apps/ipados/build/DerivedData/Build/Products/Release-iphoneos/Tablet.app: code object is not signed at all
$ nm $P/Release-iphoneos/Tablet.app/Tablet | grep -ci uniffi; nm $P/Debug-iphonesimulator/Tablet.app/Tablet | grep -ci uniffi
0
0

$ scripts/build-android-tablet.sh; echo $?                 (36 detik)
build-android-tablet: SDK /Users/ojiepermana/Library/Android/sdk, NDK 28.2.13676358, minSdk 29, ABI arm64-v8a,x86_64
build-android-tablet: openjdk version "25.0.2" 2026-01-20
build-android-tablet: cargo ndk build tablet-ffi untuk arm64-v8a,x86_64
build-android-tablet: gradlew :app:assembleDebug
BUILD SUCCESSFUL in 21s
36 actionable tasks: 36 executed
build-android-tablet: selesai
0

$ ls -l target/debug/libtablet_ffi.{a,dylib} target/*/release/libtablet_ffi.{a,so}
22132784  target/debug/libtablet_ffi.a
  821904  target/debug/libtablet_ffi.dylib
18728560  target/aarch64-apple-ios-sim/release/libtablet_ffi.a
18737288  target/aarch64-apple-ios/release/libtablet_ffi.a
  557920  target/aarch64-linux-android/release/libtablet_ffi.so
  526480  target/x86_64-linux-android/release/libtablet_ffi.so

$ "$OBJDUMP" -p target/aarch64-linux-android/release/libtablet_ffi.so | grep LOAD
    LOAD off    0x0000000000000000 vaddr 0x0000000000000000 paddr 0x0000000000000000 align 2**14
    LOAD off    0x0000000000017ca8 vaddr 0x000000000001bca8 paddr 0x000000000001bca8 align 2**14
    LOAD off    0x0000000000055700 vaddr 0x000000000005d700 paddr 0x000000000005d700 align 2**14
    LOAD off    0x00000000000574e8 vaddr 0x00000000000634e8 paddr 0x00000000000634e8 align 2**14
$ "$OBJDUMP" -p target/x86_64-linux-android/release/libtablet_ffi.so | grep LOAD
    LOAD off    0x0000000000000000 vaddr 0x0000000000000000 paddr 0x0000000000000000 align 2**14
    LOAD off    0x0000000000018330 vaddr 0x000000000001c330 paddr 0x000000000001c330 align 2**14
    LOAD off    0x000000000005ac80 vaddr 0x0000000000062c80 paddr 0x0000000000062c80 align 2**14
    LOAD off    0x000000000005d200 vaddr 0x0000000000069200 paddr 0x0000000000069200 align 2**14

$ "$SDK/build-tools/36.0.0/aapt2" dump badging "$APK" | grep -E 'SdkVersion|compileSdkVersion=|native-code'
package: name='com.example.tablet' versionCode='1' versionName='0.1.0' platformBuildVersionName='17' platformBuildVersionCode='37' compileSdkVersion='37' compileSdkVersionCodename='17'
minSdkVersion:'29'
targetSdkVersion:'36'
native-code: 'arm64-v8a' 'x86_64'
$ unzip -l "$APK" | grep 'lib/'
    10096  01-01-1981 01:01   lib/arm64-v8a/libandroidx.graphics.path.so
    10760  01-01-1981 01:01   lib/x86_64/libandroidx.graphics.path.so
$ unzip -l "$APK" | grep libtablet_ffi; echo $?
1

$ scripts/test.sh repo build-scripts artifacts; echo $?    (sesudah kedua build, 20 detik)
(43 baris ok yang sama dengan di atas, lalu)
# tests/artifacts/android-tablet.test.sh
ok 1 - HA1 AC-3 pustaka Rust Android ada untuk tiap ABI
ok 2 - HA2 AC-4 pustaka Android selaras 16 KB
ok 3 - HA3 AC-7 APK memakai SDK dari katalog
ok 4 - HA4 AC-7 APK hanya memuat ABI matriks
ok 5 - HA5 AC-11 pohon kerja bersih sesudah build
1..5
# tests/artifacts/ipados.test.sh
ok 1 - HI1 AC-3 pustaka Rust iPad perangkat dan simulator ada
ok 2 - HI2 AC-5 Tablet.app simulator arm64, OS minimum, khusus iPad
ok 3 - HI3 AC-6 Tablet.app perangkat Release tanpa tanda tangan
ok 4 - HI4 AC-11 pohon kerja bersih sesudah build
1..4
test: 7 file, 7 lulus, 0 gagal
0

$ git ls-files -s scripts apps/android-tablet/gradlew
100755 b9bb139f790567973216cd313e69ae65789c3754 0	apps/android-tablet/gradlew
100755 0e34f31bdd1e682a41f32135e21aef3a5387ec05 0	scripts/build-android-tablet.sh
100755 484204811f33aaa088d367b4e506d6f9e3e52a5e 0	scripts/build-ipados.sh
100755 1397189d64436340c96215715dce6ace3028ebec 0	scripts/test.sh
$ git ls-files apps/ipados scripts .xcode-version
.xcode-version
apps/ipados/Config/Base.xcconfig
apps/ipados/Tablet.xcodeproj/project.pbxproj
apps/ipados/Tablet.xcodeproj/xcshareddata/xcschemes/Tablet.xcscheme
apps/ipados/Tablet/App/TabletApp.swift
scripts/build-android-tablet.sh
scripts/build-ipados.sh
scripts/test.sh
$ git ls-files apps/android-tablet scripts/build-android-tablet.sh | wc -l
14
$ git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/'; echo $?
1
$ git ls-files -z | xargs -0 file --mime-encoding | grep -w binary
apps/android-tablet/gradle/wrapper/gradle-wrapper.jar: binary
$ git status --short; git status --short --ignored
!! apps/android-tablet/.gradle/
!! apps/android-tablet/app/build/
!! apps/ipados/build/
!! target/

$ cargo metadata --no-deps --format-version 1 | grep -o '"name":"tablet-[a-z]*"' | sort -u
"name":"tablet-core"
"name":"tablet-ffi"
$ cargo tree -p tablet-core -e normal
tablet-core v0.1.0 (<clone>/crates/core)
$ cargo tree -p tablet-ffi -e normal --depth 1
tablet-ffi v0.1.0 (<clone>/crates/tablet-ffi)
├── tablet-core v0.1.0 (<clone>/crates/core)
└── uniffi v0.32.2

$ (cd apps/android-tablet && JAVA_HOME="$JBR" ./gradlew -q buildEnvironment | grep kotlin-gradle-plugin:)
+--- org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21
|         +--- org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.10 -> 2.4.21 (*)
|         \--- org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21 (*)
|    |    +--- org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21 (c)

$ ANDROID_HOME=<folder kosong> scripts/build-android-tablet.sh; echo $?
build-android-tablet: platform Android 37 tidak ada di <folder kosong>/platforms (dicari android-37.0 dan android-37).
  Pasang dengan: "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platforms;android-37.0"
  atau lewat SDK Manager di Android Studio. Bila SDK ada di folder lain, set ANDROID_HOME ke folder itu.
1
$ JAVA_HOME=/tidak/ada scripts/build-android-tablet.sh; echo $?
build-android-tablet: java tidak ditemukan di JAVA_HOME: /tidak/ada/bin/java
  Pasang JDK 25 (JBR bawaan Android Studio sudah cukup), lalu set JAVA_HOME ke foldernya, misalnya: export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
1
$ DEVELOPER_DIR=/tidak/ada scripts/build-ipados.sh; echo $?
build-ipados: DEVELOPER_DIR menunjuk folder yang tidak ada: /tidak/ada
  Hapus variabel itu (unset DEVELOPER_DIR) atau arahkan ke folder Developer di dalam Xcode 27.1, misalnya /Applications/Xcode.app/Contents/Developer.
1

Isi dokumen terhadap spec (diff tabel yang dinormalkan):
pemilik: diff exit=0, 13 baris     penyimpangan: diff exit=0, 14 baris     diagram dan aturan: diff exit=0, 11 baris
blok "Perintah repo": diff exit=0, 6 baris     blok "Menjalankan tes": diff exit=0, 4 baris
URL rationale.md vs support-matrix.md: 44 dan 44, tanpa selisih

Pembersihan, perintah panduan apa adanya (JAVA_HOME tidak diset):
$ (cd apps/android-tablet && JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}" ./gradlew --stop); echo $?
Stopping Daemon(s)
1 Daemon stopped
0
$ cd / && rm -rf /var/folders/sx/35k0wvh13dg0cgpr19hnkjb80000gp/T/tmp.7qFmbrO5cE
```
