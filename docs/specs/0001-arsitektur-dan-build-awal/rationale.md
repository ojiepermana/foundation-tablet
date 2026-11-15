# 0001. Arsitektur dan build awal: alasan

Catatan keputusan untuk [index.md](index.md). `/develop` tidak perlu membaca file ini.

## Context

Repo fondasi tablet baru berisi dokumen kebutuhan (`README.md`), scope, dan audit. Belum ada kode. Fitur 01 harus menghasilkan kerangka yang bisa dikompilasi dari clone bersih, dan tiga hal masih terbuka: versi alat yang saling cocok, target build, dan cara mengemas pustaka Rust untuk tiap platform.

Kekuatan yang membentuk keputusan:

- **README meminta versi stabil yang terbukti cocok**, bukan yang terbaru, dan melarang folder penanda tempat serta biner hasil generasi yang tidak perlu di-commit.
- **Pendekatan Tracer Bullet** (indeks scope): bukti pertama adalah satu benang tipis dari Rust ke kedua layar. Fitur 01 menyiapkan benang itu sampai tahap kompilasi; `hello`, binding, dan penautan milik fitur 03 dan 04.
- **Fitur 04 tidak punya langkah spec.** Semua keputusan pengemasan harus selesai di sini supaya fitur 04 bisa langsung dibangun.
- **Fitur 03 dan 11 membaca matriks dukungan** untuk target binding, isi APK, build Release iPad, dan pemeriksaan 16 KB. Audit scaffold (baris "Pertama") meminta OS minimum, target, ABI, dan sikap terhadap 16 KB ditetapkan sekarang.
- **Mesin lead** (M1 Max, macOS 27.0.1, disk bebas sekitar 35 GiB) menjalankan build repo lain bersamaan. Yang sudah terpasang: Xcode 27.1 dengan runtime iOS 26.5, 27.0, 27.1; Rust 1.99.1 (dan 1.100.0) dengan target host saja; Android SDK dengan `android-36`, `android-37.0`, Build Tools 36.0.0, NDK 28.2.13676358, satu image emulator `android-36` `arm64-v8a`; JBR 25.0.2 di Android Studio 2026.1; rustup 1.29.3. Tidak ada `gradle`, `cargo-ndk`, `xcodegen`, atau `java` di PATH.
- **Pengembang berikutnya adalah agen.** Agen tidak bisa mengklik antarmuka Xcode, dan sunting tangan `project.pbxproj` rawan salah.
- **Perangkat fisik tidak tersedia** untuk sub sesi, jadi janji matriks harus dipisah antara yang bisa dibuktikan di sini dan yang manual.

Bila tidak diputuskan sekarang, tiap fitur berikutnya akan memilih versi dan lokasi artefak sendiri, dan kegagalan kompatibilitas baru muncul di CI fitur 11.

## Options considered

### Opsi 1: Kombinasi terdokumentasi cocok, skrip sebagai pintu build, XCFramework statis dan `jniLibs`

Pilih versi dari irisan rentang yang disebut dokumentasi resmi tiap alat, utamakan yang sudah terpasang. Skrip repo menjalankan Cargo lalu `xcodebuild` atau Gradle. Hasil generasi tidak di-commit. Proyek Xcode di-commit dengan grup tersinkron.

**Pros**:
- Setiap pasangan versi punya rujukan resmi; hampir tidak ada yang perlu diunduh di mesin lead.
- Jalur build lokal dan CI identik; binding selalu dari revisi yang sama dengan pustaka.

**Cons**:
- Bukan versi terbaru (AGP 9.3.3, Rust 1.99.1, NDK r28c); perlu jadwal naik versi.
- Membangun dari IDE butuh skrip dijalankan dulu sesudah fitur 04.

### Opsi 2: Semua versi terbaru

Rust 1.100.0, AGP 9.5.1, Gradle 9.9.1, NDK r30 (LTS 2026), `targetSdk` 37, Xcode 27.2.

**Pros**:
- Umur dukungan terpanjang; tidak ada peringatan "versi lama".
- NDK r30 adalah LTS yang disebut halaman dukungan Android milik Rust.

**Cons**:
- Tabel Kotlin 2.4.21 berhenti di AGP 9.3.1 dan Gradle 9.7.0, jadi AGP 9.5.1 dengan Gradle 9.9.1 berada di luar rentang yang terdokumentasi.
- Rust 1.100.0 baru berumur tiga hari. NDK r30, Xcode 27.2, dan image API 37 harus diunduh ke disk yang sudah 92% terpakai.

### Opsi 3: Build Rust dipanggil dari sistem build native

Gradle memanggil Cargo lewat task `Exec` atau plugin, Xcode lewat fase skrip, proyek Xcode dihasilkan XcodeGen.

**Pros**:
- Tombol Run di IDE selalu membangun Rust terbaru.
- `project.yml` lebih mudah ditinjau daripada `project.pbxproj`.

**Cons**:
- Paket Swift dengan target biner harus sudah ada saat resolusi paket, sebelum fase skrip berjalan, jadi iPad tetap butuh skrip pendahulu dan kedua platform menjadi tidak simetris.
- IDE yang dibuka dari Dock tidak mewarisi PATH Cargo; sandbox skrip Xcode harus dimatikan; XcodeGen menambah alat yang harus dipasang dan dikunci.

### Opsi 4: Binding hasil generasi di-commit

Sumber Swift dan Kotlin hasil generasi masuk Git; CI membandingkannya dengan hasil generasi ulang.

**Pros**:
- Perubahan kontrak terlihat sebagai diff binding di pull request.
- IDE bisa membuka proyek tanpa menjalankan generator.

**Cons**:
- Binding bisa basi terhadap pustaka (audit menyebut "binding lama" sebagai risiko utama) dan UniFFI baru menolaknya saat aplikasi berjalan.
- Tetap butuh skrip untuk membangun pustaka, jadi tidak menghapus langkah apa pun.

## Rationale

Opsi 1 dipilih karena README menuntut kecocokan yang terverifikasi, dan satu satunya irisan yang disebut ketiga sumber (AGP, Kotlin, Gradle) adalah AGP 9.3.x dengan Gradle 9.5 sampai 9.7 dan Kotlin 2.4.21. Compose BOM 2026.09.00 mewajibkan `compileSdk` 37 dan AGP 9, yang dipenuhi AGP 9.3 dan platform `android-37.0` yang sudah terpasang. NDK 28.2.13676358 adalah NDK bawaan AGP 9.3 dan AGP 9.5, sudah terpasang, dan selaras 16 KB secara bawaan, sehingga matriks bisa menjanjikan 16 KB tanpa konfigurasi tambahan.

Skrip sebagai pintu build menjawab audit ("perintah repo yang sama" untuk lokal dan CI) dan menghindari ketidaksimetrisan Opsi 3. Karena fitur 03 mensyaratkan binding berasal dari revisi yang sama dengan pustaka yang ditautkan, tidak meng-commit hasil generasi memenuhi syarat itu dengan sendirinya. Proyek Xcode yang di-commit dengan grup tersinkron dipilih karena agen cukup menulis `project.pbxproj` sekali; sesudah itu file baru tidak mengubahnya.

Mode arsitektur skill `/architect` biasanya tidak menulis Build plan. Spec ini menulisnya karena fitur 01 terhubung ke scope dan alur koordinasi meminta AC ber-ID serta milestone.

## Keputusan diambil

Mode keputusan `auto`: opsi rekomendasi diambil. Semua bertanda `biasa` karena tidak ada format data, kontrak yang sudah dipakai, model keamanan, atau data user yang tersentuh, dan repo belum punya pengguna.

| # | Pertanyaan | Diambil | Runner up | Tanda | Yang berubah bila runner up dipilih |
|---|---|---|---|---|---|
| K1 | Versi Rust | 1.99.1, edisi 2024 | 1.100.0 | biasa | `rust-toolchain.toml`, `rust-version`; AC-8 |
| K2 | Versi UniFFI | 0.32.2, kunci persis | 0.31.x | biasa | `Cargo.toml`; AC-2 |
| K3 | Batas crate | `tablet-core` tanpa `uniffi`, `tablet-ffi` satu satunya pemegang `uniffi`, tanpa fungsi di fitur 01 | `hello` sudah ada di inti sejak fitur 01 | biasa | AC-2, tugas 2; tumpang tindih dengan fitur 03 |
| K4 | Target iPad | `aarch64-apple-ios`, `aarch64-apple-ios-sim` | Tambah `x86_64-apple-ios` | biasa | Matriks, AC-3, `ARCHS` simulator |
| K5 | ABI Android | `arm64-v8a`, `x86_64` | Tambah `armeabi-v7a` | biasa | Matriks, AC-3, AC-4, tugas 8 |
| K6 | Halaman 16 KB | Termasuk | Ditunda sampai fitur 11 | biasa | AC-4 hilang |
| K7 | iPadOS minimum | 26.0 | 18.0 | biasa | `Base.xcconfig`, AC-5; perlu runtime iOS 18 |
| K8 | `minSdk` Android | 29 | 31 | biasa | Katalog versi, AC-7 |
| K9 | `targetSdk` dan `compileSdk` | 36 dan 37 | 37 dan 37 | biasa | Katalog versi, AC-7; perlu image API 37 |
| K10 | Lini AGP, Gradle, Kotlin | 9.3.3, 9.5.1, 2.4.21 | AGP 9.5.1 dengan Gradle 9.6 atau lebih baru | biasa | Katalog versi, wrapper; AC-8 |
| K11 | NDK | 28.2.13676358 (r28c) | 30.0.16248370 (r30 LTS) | biasa | Katalog versi; unduhan NDK |
| K12 | JDK | 25, dikunci lewat kriteria JVM daemon Gradle | 21 | biasa | `gradle-daemon-jvm.properties`; cadangan sudah disetujui |
| K13 | Xcode | 27.1, Swift 6, mode bahasa 6 | 27.2 | biasa | `.xcode-version`; unduhan Xcode |
| K14 | Proyek Xcode | `.xcodeproj` di-commit dengan grup tersinkron | XcodeGen dari `project.yml` | biasa | Tugas 4, prasyarat panduan |
| K15 | Proyek Android | Satu modul `:app`, Kotlin bawaan AGP, katalog versi | Modul pustaka terpisah untuk binding | biasa | Struktur, tugas 6 |
| K16 | Pengemasan iPad | XCFramework statis lewat paket Swift lokal `bindings/swift` | Framework dinamis | biasa | Bagian pengemasan; fitur 04 |
| K17 | Pengemasan Android | `jniLibs` lewat `cargo-ndk`, binding Kotlin sebagai folder sumber | AAR dari modul pustaka | biasa | Bagian pengemasan; fitur 04 |
| K18 | Hasil generasi di Git | Tidak di-commit | Sumber binding di-commit, biner tidak | biasa | Aturan commit, AC-11; pemeriksaan selisih di fitur 10 |
| K19 | Pemanggil Cargo | Hanya `scripts/` | Task Gradle dan fase skrip Xcode | biasa | Kontrak skrip, aturan dependensi 6 |
| K20 | Identitas aplikasi | Sementara `com.example.tablet`, satu sumber per platform, `namespace` Kotlin `foundation.tablet` | Menunggu nilai dari user | biasa | `Base.xcconfig`, `gradle.properties` |
| K21 | Lokasi dan bahasa dokumen | `docs/getting-started.md` dan lima file `docs/architecture/`, bahasa Indonesia | Satu file `docs/architecture/overview.md` | biasa | AC-9, AC-10, tugas 9 dan 10 |

Catatan tambahan per keputusan:

- **K3**: `hello` adalah langkah 4 README bagian 26, sedangkan fitur 01 mencakup langkah 1 sampai 3. Crate tanpa fungsi tetap membuktikan batas lewat manifest dan membuktikan UniFFI terkompilasi untuk keempat target.
- **K9**: perilaku "target API" hanya aktif di perangkat dengan OS setinggi target. Dengan target 36, semua perilaku yang dijanjikan bisa diuji di image API 36 yang terpasang. Untuk aplikasi yang menargetkan 37, Android 17 menghapus pilihan keluar dari aturan orientasi dan ukuran jendela di layar besar; repo ini memang tidak memakai pilihan keluar itu, jadi kenaikan kelak tidak mengubah perilaku.
- **K12**: Android Studio memakai kriteria JVM daemon Gradle secara bawaan untuk proyek baru. Angka 25 dipilih karena itu JDK yang sudah ada di mesin; Gradle 9.5 mendukung JVM 17 sampai 26.
- **K4**: SDK simulator Xcode 27.1 masih mendaftarkan `x86_64` (dibaca dari `SDKSettings.json` di mesin lead), jadi `ARCHS[sdk=iphonesimulator*] = arm64` diperlukan supaya build generik hanya meminta irisan yang ada di matriks.
- **K20**: `com.example` adalah ruang nama contoh, bukan tebakan identitas user. `namespace` Kotlin dipisah dari `applicationId` supaya mengganti identitas kelak hanya mengubah satu baris.

Keputusan tambahan yang ditutup sesudah cross check (semua `biasa`, opsi rekomendasi diambil):

| # | Pertanyaan | Diambil | Runner up | Yang berubah bila runner up dipilih |
|---|---|---|---|---|
| K22 | Nama modul binding | FFI `TabletFFI`, Swift `TabletBindings`, paket Kotlin `foundation.tablet.bindings` | Nama bawaan UniFFI (`tablet_ffiFFI`, `uniffi.tablet_ffi`) | Bagian pengemasan; `uniffi.toml` fitur 03 |
| K23 | ABI di dalam APK | `abiFilters` dari `tablet.abis` sejak fitur 01 | Tanpa filter sampai fitur 04 | AC-7, `gradle.properties`, kontrak skrip Android |
| K24 | Tempat generator binding | Fitur 03 boleh menambah crate tooling ke workspace | Binary di dalam `tablet-ffi` dengan fitur opsional | Aturan dependensi 2; AC-2 berlaku untuk fitur 01 saja |
| K25 | Isolasi aktor Swift di target aplikasi | `MainActor` bawaan templat Xcode | Tanpa isolasi bawaan | `Base.xcconfig` |
| K26 | Build Tools | Mengikuti bawaan AGP, tidak diset | Dikunci di katalog | Tabel stack, AC-8 |
| K27 | iPadOS minimum di `Package.swift` | Salinan kedua yang dinyatakan, diperiksa fitur 10 | Tanpa `platforms` di paket | Tabel sumber nilai; kode `async` hasil generasi gagal dikompilasi tanpa `platforms` |
| K28 | Unduhan SDK otomatis oleh AGP | Dimatikan (`android.builder.sdkDownload=false`) | Dibiarkan | `gradle.properties` |

Keputusan tambahan dari hasil build milestone 2 (pembaruan spec 2026-11-15, saat spec berstatus `In Progress`; opsi rekomendasi developer diambil lead dalam mode `auto`):

| # | Pertanyaan | Diambil | Runner up | Tanda | Yang berubah bila runner up dipilih |
|---|---|---|---|---|---|
| K29 | Peringatan headermap Xcode 27.1 pada target `Tablet` | Tambah `ALWAYS_SEARCH_USER_PATHS = NO` ke `Base.xcconfig` | Biarkan peringatan | biasa | Blok `Base.xcconfig` tetap tanpa baris itu dan tugas 11 Build plan hilang; peringatan tetap tercetak sekali per konfigurasi pada tiap build |

- **Sumber K29**: laporan `dev-f1-m1` untuk milestone 2 ([bukti build](../../reviews/2026-11-15-build-f01-m2.md)) dan build lead pada merge `0868e45`. Xcode 27.1 mencetak dua kali (sekali untuk simulator, sekali untuk perangkat): `warning: Traditional headermap style is no longer supported; please migrate to using separate headermaps and set 'ALWAYS_SEARCH_USER_PATHS' to NO. (in target 'Tablet' from project 'Tablet')`. Spec menetapkan isi `Base.xcconfig` "tepat nilai ini", jadi developer tidak menambah baris itu sendiri.
- **Penyebab**: blok `buildSettings` di `project.pbxproj` sengaja kosong, jadi nilai bawaan Xcode yang berlaku, yaitu `YES`. Templat proyek Xcode menulis `NO` di tingkat proyek; spec ini memindahkan semua nilai ke xcconfig dan baris itu terlewat.
- **Uji K29** (2026-11-15, `git clone` worktree spec pada `0868e45` ke folder sementara di luar repo, Xcode 27.1, sesudah `pgrep -x xcodebuild` kosong; clone dihapus sesudahnya):
  - Tanpa baris itu, `scripts/build-ipados.sh --simulator` keluar 0 dan mencetak peringatan headermap 1 kali.
  - Dengan baris itu sesudah `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD`, `scripts/build-ipados.sh` tanpa argumen keluar 0, `BUILD SUCCEEDED` 2 kali, peringatan headermap 0 kali, tanpa baris `error:`. Satu satunya peringatan yang tersisa adalah `Metadata extraction skipped, no AppIntents.framework dependency found` (informasi bawaan untuk aplikasi tanpa App Intents, sudah ada sebelumnya).
  - Bukti AC-5 dan AC-6 tidak berubah: `lipo -archs` menampilkan `arm64`, `MinimumOSVersion` `26.0`, `UIDeviceFamily` `[2]` untuk kedua app; app Release tetap tanpa tanda tangan.
  - `diff` keluaran `xcodebuild -showBuildSettings` (Debug, simulator generik, 554 baris) sebelum dan sesudah hanya berbeda satu baris: `ALWAYS_SEARCH_USER_PATHS = YES` menjadi `NO`. `Info.plist` app simulator sama persis.
- **Kenapa aman**: setting itu hanya mengatur cara kompilator C mencari header dari jalur pencarian milik user. Target `Tablet` hanya berisi Swift, dan modul binding fitur 04 adalah paket Swift lokal yang tidak membaca xcconfig proyek.

Keputusan tambahan dari hasil build milestone 3 (pembaruan spec 2026-11-15, saat spec berstatus `In Progress`; diambil lead dalam mode `auto`):

| # | Pertanyaan | Diambil | Runner up | Tanda | Yang berubah bila runner up dipilih |
|---|---|---|---|---|---|
| K30 | Nama field `aapt2` pada bukti AC-7 | Ikuti keluaran `aapt2` 36.0.0: `minSdkVersion:'29'` | Biarkan teks `sdkVersion:'29'` dan catat tafsiran di tiap laporan | biasa | Teks AC-7 tetap tidak cocok dengan keluaran alat, dan tiap laporan build, verify, dan test harus mengulang tafsiran yang sama. Tidak ada tugas Build plan yang berubah pada kedua opsi |

- **Sumber K30**: laporan `dev-f1-m1` untuk milestone 3 ([bukti build](../../reviews/2026-11-15-build-f01-m3.md), butir "Tafsiran AC-7") dan build lead pada merge `610cefb`. `"$ANDROID_HOME/build-tools/36.0.0/aapt2" dump badging <apk>` mencetak `minSdkVersion:'29'`, `targetSdkVersion:'36'`, dan `compileSdkVersion='37'`. Draf AC-7 menulis nama field lama `sdkVersion`, yang tidak dicetak `aapt2` 36.0.0.
- **Yang berubah**: hanya nama field pada teks bukti AC-7. ID AC, nilai `minSdk` 29 (K8), `targetSdk` 36 dan `compileSdk` 37 (K9), katalog versi, dan tugas Build plan tetap.
- **Ikut dirapikan**: kalimat pembuka "Build plan" kini menyebut satu irisan file yang sudah tertulis di baris File milestone 4 sejak K29 (`apps/ipados/Config/Base.xcconfig`, tugas 11). Isi milestone dan tugas tidak berubah.

Keputusan tambahan untuk rancangan tes (pembaruan spec 2026-11-15, saat spec berstatus `In Progress` dan kotak `Test it` masih terbuka; mode `auto`, opsi rekomendasi diambil):

| # | Pertanyaan | Diambil | Runner up | Tanda | Yang berubah bila runner up dipilih |
|---|---|---|---|---|---|
| K31 | Apa yang dikunci tes fitur 01 | Hal yang tahan lama: batas crate, kunci versi dan satu sumber, aturan commit, kontrak skrip, hasil build. Bukan potret fitur 01 | Tidak ada tes otomatis di fitur 01; `Test it` diganti gerbang verify (`"tool": null`, `"gate": "verify"` di `test-preferences.json`) | biasa | Bagian "Rancangan tes" dan milestone 5 hilang; kotak `Test it` berubah arti; fitur 10 dan 11 mulai dari nol |
| K32 | Alat tes tingkat repo | bash polos tanpa framework, berjalan di bash 3.2 | Python `unittest` dengan `python3` bawaan Xcode (3.9) | **berat** | File tes menjadi `tests/**/test_*.py`, runner memanggil `python3 -m unittest`, alat tiruan tetap skrip shell; `python3` masuk daftar prasyarat tes; `additionalTools` menjadi `["unittest"]` |
| K33 | Lokasi tes | `tests/<grup>/*.test.sh` di akar repo dan runner `scripts/test.sh` | Tes integrasi Rust di `crates/*/tests/` yang dijalankan `cargo test` | biasa | Struktur repo, tabel pemilik, tabel penyimpangan; `tablet-core` atau `tablet-ffi` mendapat tes yang bukan tentang perilakunya; Consequences "nol tes Rust" hilang |
| K34 | Apakah suite boleh butuh build native | Dua tingkat: bawaan cepat tanpa build dan tanpa jaringan; grup `artifacts` hanya membaca hasil build dan harus disebut | Cepat saja; pemeriksaan hasil build ditunda ke fitur 11 | biasa | Grup `artifacts`, tugas 14, dan kasus HI serta HA hilang; AC-3 sampai AC-7 hanya dikunci pada sisi perintah |
| K35 | Cara menguji kedua skrip build | Salinan skrip di sandbox dengan alat tiruan di `PATH` | Tiga percobaan AC-8 terhadap lingkungan nyata (`ANDROID_HOME`, `JAVA_HOME`, `DEVELOPER_DIR`) | biasa | Kasus I dan A menyusut menjadi tiga; tes butuh Xcode dan Android SDK asli; bentuk perintah dan cabang lain tidak dikunci |
| K36 | Cara mengunci versi | Tes membaca nilai dari sumbernya lalu memeriksa bentuk kunci, pemakai, dan dokumen | Tabel nilai harapan di dalam tes (salinan tabel "Proposed stack") | biasa | Kasus V menjadi perbandingan literal; tiap kenaikan versi wajib mengubah tes juga; tes menjadi salinan keempat tiap angka |
| K37 | Isi `test-preferences.json` | `"tool": "cargo test"`, `"additionalTools": ["bash"]`, di-commit di akar | `"tool": "bash"`, `"testDir": "tests"`, `"filePattern": "*.test.sh"`, `"additionalTools": ["cargo test"]` | biasa | Tiga nilai JSON; fitur 03 harus membalik `tool` saat menulis tes Rust pertama |
| K38 | Biner yang di-commit | Daftar izin di `tests/repo/commit-policy.test.sh`; kini berisi `gradle-wrapper.jar` saja | Tes menegaskan "hanya `gradle-wrapper.jar`" tanpa daftar | biasa | Kasus C2; fitur yang meng-commit aset biner harus menulis ulang kasus itu, bukan menambah satu baris |
| K39 | Pemilik tugas dokumen (tugas 15) | Tester, di branch yang sama dengan suite, hanya tambahan yang disebut | Developer di branch terpisah | biasa | Ownership brief; kasus V8 baru hijau sesudah dua branch digabung |
| K40 | Apakah `scripts/test.sh` membungkus `cargo test` | Tidak, sampai ada tes Rust (fitur 03) | Ya, sebagai grup bawaan | biasa | Runner butuh kompilasi dan jaringan pada clone baru; jalur cepat tidak lagi tanpa build |

Catatan tambahan untuk rancangan tes:

- **K31, kenapa bukan "tidak ada tes"**: fitur 01 memang tidak punya perilaku aplikasi, tetapi punya dua hal yang bisa rusak diam diam. Pertama, kedua skrip build berisi lebih dari dua puluh cabang prasyarat, dan verify hanya menjalankan tiga di antaranya. Kedua, tiap angka versi tertulis di file sumber dan di dua dokumen, dan fitur 03 sampai 11 akan menyentuh semuanya. Suite ini murah (beberapa detik, tanpa build) dan langsung dipakai fitur 10 dan 11.
- **K31, kenapa bukan potret**: AC-2 menyebut "tepat dua crate" dan "tanpa dependensi sama sekali" untuk fitur 01 saja (K24 mengizinkan crate tooling di fitur 03). AC-11 menyebut aplikasi belum menautkan Rust, yang dibalik fitur 04. Tes yang mengunci potret itu akan merah karena pekerjaan yang benar, lalu dilunakkan. Potret tetap dibuktikan verify pada `f3992db`.
- **K31, batas dengan fitur 10**: fitur 10 menjanjikan satu perintah yang mendeteksi contoh pelanggaran aturan umum, lengkap dengan contoh negatif, selisih hasil generasi, skema, dan keberadaan dokumen. Suite fitur 01 hanya mengunci bukti AC-2 dan AC-11 untuk dua crate dan aturan commit yang sudah ada. Follow-up meminta fitur 10 memutuskan apakah kasus itu dipanggil atau dipindahkan.
- **K31, batas dengan fitur 11**: fitur 11 memegang CI, `zipalign`, emulator 16 KB, pustaka Rust di APK akhir, dan tautan Release. Grup `artifacts` hanya memeriksa bukti AC fitur 01 pada hasil yang sudah ada dan tidak membangun, jadi fitur 11 cukup memanggilnya sesudah skrip build.
- **K32, kenapa bertanda `berat`**: kedua opsi hampir setara dan sama murahnya dibalik hari ini (sekitar lima puluh kasus). Tanda `berat` dipasang karena fitur 10 dan 11 akan mengikuti konvensi ini, sehingga harga membaliknya naik tiap fitur. bash dipilih karena skrip yang diuji adalah bash, langkah `verify.md` sudah berupa perintah shell sehingga tes adalah salinan langsungnya, README bagian 5 menamai semua alat repo sebagai skrip `.sh`, dan tidak ada bahasa atau prasyarat baru. Python lebih kuat untuk isolasi, pesan gagal, dan membaca JSON, dan `python3` 3.9 sudah ikut Xcode; harganya adalah bahasa kelima di repo produk. bats-core ditolak karena menambah prasyarat yang harus dipasang dan dikunci untuk kebutuhan sekecil ini.
- **K32, bash 3.2**: `env bash` pada macOS tanpa Homebrew adalah `/bin/bash` 3.2.57. Mesin lead punya bash 5.3 di `/opt/homebrew/bin`, jadi tanpa aturan ini tes bisa lulus di sini dan gagal di mesin kontributor.
- **K33**: akar workspace adalah manifest virtual, jadi folder `tests/` di akar tidak dibaca Cargo dan tidak menambah crate. Tes repo di dalam `crates/core/tests/` akan membuat `cargo test` bergantung pada `git` dan `bash`, dan menaruh pemeriksaan Gradle serta Xcode di lapisan inti Rust. README bagian 5 sudah punya `tests/` di akar dan `scripts/test.sh`; dua subfolder README (`fixtures`, `contracts`) dibiarkan untuk fitur pemiliknya.
- **K35**: kedua skrip pindah ke `$(dirname "${BASH_SOURCE[0]}")/..`, jadi salinan di folder lain bekerja tanpa perubahan kode produksi. Dibaca dari skrip pada `main` (`610cefb` dan sesudahnya): urutan pemeriksaan, kata kunci pesan, dan argumen `cargo`, `xcodebuild`, serta `gradlew` pada tabel kasus diambil dari sana. `PATH` sandbox adalah `<sandbox>/bin:/usr/bin:/bin`, sehingga `xcode-select` dan `xcodebuild` asli di `/usr/bin` tertutup alat tiruan.
- **K36**: tabel "Proposed stack" spec, `support-matrix.md`, dan `getting-started.md` sudah tiga tempat. Tes yang menyalin angka menjadi tempat keempat dan hanya mendeteksi "ada yang berubah". Tes yang membandingkan sumber dengan dokumen mendeteksi "berubah setengah jalan", dan kenaikan versi yang benar lulus tanpa menyentuh tes. Kesamaan nilai dengan tabel spec tetap bukti verify (AC-8).
- **K37**: format `test-preferences.json` dibaca dari `~/.claude/skills/test/SKILL.md` langkah 2 dan `modes/setup.md` langkah 6. Skill bercabang pada `tool`: bila terisi, ia melewati pertanyaan framework. Untuk repo ber-`Cargo.toml`, setup skill itu sendiri memilih `cargo test` tanpa bertanya, jadi nilai ini sama dengan yang akan ditulis skill. Format hanya punya satu `tool`, satu `testDir`, dan satu `filePattern`, sedangkan repo punya dua area tes, sehingga dua kunci terakhir berisi satu kalimat untuk tiap area. Panel yang tersisa pada skill (`No changes`, `Run tests?`) dijawab dari file aturan umum brief.
- **K38**: pemeriksaan biner memakai `git ls-files --eol`; baris `i/-text` adalah file yang isi indeksnya dinilai biner oleh Git. Pada `main` saat ini hanya `gradle-wrapper.jar` yang demikian (`gradlew.bat` tercatat `i/crlf`).

Yang diperiksa di mesin lead untuk rancangan tes (2026-11-15): `/bin/bash` 3.2.57 dan `/opt/homebrew/bin/bash` 5.3.15; `python3` 3.9.6 dari Xcode; `shellcheck` dan `bats` tidak terpasang; tidak ada file terlacak berukuran 0 byte; `Cargo.lock` memuat blok `tablet-core` tanpa `dependencies` dan blok `tablet-ffi` dengan `tablet-core` serta `uniffi`; label sel pertama tabel "Versi alat" di `support-matrix.md` dan tabel "Prasyarat" di `getting-started.md` sama dengan yang dipakai kasus V8.

## Catatan cross check

Dijalankan 2026-11-15 oleh model lain (`claude-opus-5-5`, hanya membaca) terhadap draf pertama. Vonisnya: arah desain kokoh, tetapi draf belum bisa dibangun tanpa bertanya. Semua perbaikan yang direkomendasikan diterapkan (mode `auto`).

Empat celah pemblokir yang ditutup:

1. `SDKROOT = iphoneos` tidak ada di `Base.xcconfig`, padahal spec melarang nilai lain di `project.pbxproj`. Ditambahkan, bersama daftar objek wajib `project.pbxproj`.
2. Urutan "generasi binding lalu build Rust" salah untuk mode pustaka UniFFI, yang membaca metadata dari pustaka yang sudah dibangun. Urutan dibalik.
3. Nama modul FFI, tata letak header XCFramework, dan isi `Package.swift` belum ditetapkan, sedangkan fitur 04 tidak punya spec. Ditetapkan (K22).
4. `settings.gradle.kts` dan build file akar belum ditulis (repositori untuk `buildscript`, cara plugin dideklarasikan). Keduanya kini tertulis lengkap.

Perbaikan lain yang diterapkan: baris Build Tools yang tidak cocok dengan katalog (K26); bentuk `compileSdk` dan larangan unduh SDK (K28); isi `gradle.properties`; pemeriksaan JDK lewat `$JAVA_HOME/bin/java`; langkah prasyarat di kedua skrip dan bukti AC-8; path alat dan keluaran yang diharapkan untuk AC-4 sampai AC-7; cara membuat wrapper tanpa memasang Gradle; mode berkas `100755`; pembersihan keluaran lama; `abiFilters` (K23); salinan kedua iPadOS minimum (K27); tambahan `.gitignore`; `scripts/generate-bindings.sh` milik fitur 03; pembagian bukti peluncuran (emulator `x86_64` di CI, `arm64` lokal); kata "bisa diuji" untuk OS minimum diperlunak menjadi runtime terdekat.

Dua saran yang tidak diambil, dengan alasan:

- `cargo rustc --crate-type` per platform untuk memangkas waktu tautan: menambah cabang di skrip demi penghematan kecil; dicatat di Consequences sebagai sifat netral.
- `cargo ndk --platform` sebagai pengganti `CARGO_NDK_PLATFORM`: hanya variabel lingkungan yang tertulis di README cargo-ndk yang terbaca saat pemeriksaan.

### Cross check rancangan tes

Dijalankan 2026-11-15 oleh model lain (`claude-opus-5-5`, hanya membaca) terhadap draf "Rancangan tes fitur 01". Vonisnya: rancangan bisa dibangun, dan setiap kasus I dan A lulus terhadap skrip yang tidak diubah di bash 3.2 (urutan cabang, kode keluar, dan kata kunci stderr ditelusuri satu per satu). Sebelas celah ditemukan, sebagian besar risiko lulus kosong. Semua perbaikan yang direkomendasikan diterapkan (mode `auto`).

1. Runner memanggil `bash`, yang di mesin lead adalah bash 5, jadi aturan bash 3.2 tidak pernah terbukti. Runner kini memakai `/bin/bash` bila ada.
2. C3 bisa lulus karena berkas abaikan global milik user (`~/.config/git/ignore` ada di mesin lead). Kasus kini menuntut aturan yang sumbernya `.gitignore` repo. Kedua puluh satu path sudah diperiksa cocok dengan `.gitignore` saat ini.
3. V8 mencocokkan angka pendek (`25`, `37`) yang bisa cocok secara kebetulan, dan baris `cargo-ndk` pada tabel "Prasyarat" tidak diperiksa. Kasus kini memakai token berlabel dan tiap label harus cocok dengan tepat satu baris.
4. B3 lulus kosong bila blok `tablet-core` tidak terbaca. Kasus kini gagal bila blok itu tidak ditemukan, dan bentuk entri ketiga (`"nama versi (sumber)"`) ditetapkan.
5. Tabel "tes menggigit": mengubah `EXPECTED_JAVA_MAJOR` memerahkan lebih banyak kasus Android daripada yang tertulis. Diubah menjadi "minimal".
6. Urutan commit tidak tertulis, padahal clone tugas 14 hanya berisi file ter-commit. Ditambahkan ke "Pemilik dan batas tester" dan tugas 14.
7. Skill `/test` tanpa `package.json` akan menampilkan panel "No changes", memilih `cargo test` sebagai perintah, bisa menulis `#[test]`, dan ingin mencentang scope. Empat ketetapan untuk brief tester ditambahkan di bawah `test-preferences.json`.
8. Rincian alat tiruan yang harus dikarang tester: cara menyalakan sakelar di bawah `env -i`, lokasi log, folder Command Line Tools, bentuk folder kerja di log, dan perintah yang berbeda antara BSD dan GNU. Ditetapkan lewat variabel `STUB_*`, `STUB_LOG`, folder sandbox, `pwd -P`, dan larangan `sed -i`, `stat`, serta `find -printf`.
9. Kontrak runner yang belum tertulis: argumen campuran, argumen ganda, urutan, stderr, penulisan beberapa AC, dan satu baris per baris tabel. Semuanya ditetapkan.
10. V2 bisa memicu rustup mengunduh toolchain. Kasus kini menyetel `RUSTUP_AUTO_INSTALL=0` (nama variabel itu ada di biner rustup 1.29.3 di mesin lead).
11. V5 tidak jelas mencakup kunci mana. Dibatasi pada delapan kunci yang disebut.

Catatan kelayakan yang diterapkan sebagai Follow-up: I11, daftar file sandbox, dan V7 berubah saat fitur 04 menambah pengemasan dan target tes; crate tooling fitur 03 harus di luar `crates/` supaya B6 tetap lulus; fitur 11 memakai ulang HA2. Dua catatan yang tidak mengubah rancangan: HI4 dan HA5 sengaja kembar karena tiap platform dibangun di job CI yang berbeda, dan V6 serta V7 dekat dengan pendeteksi perubahan tetapi dipertahankan karena mengunci aturan "nilai hanya di satu sumber". Pemeriksa menilai tanda `berat` pada K32 wajar dan pilihan bash bisa dipertahankan.

## Bukti pemeriksaan

Diperiksa 2026-11-15 dari halaman resmi (lihat References) dan dari mesin lead.

| Fakta | Nilai | Sumber |
|---|---|---|
| Rust stabil terbaru | 1.100.0 (2026-11-12); sebelumnya 1.99.1 (2026-10-15) | Catatan rilis Rust |
| Tier target Rust | Keempat target matriks Tier 2 dengan `std` | Halaman dukungan platform rustc |
| iOS minimum Rust | 10.0, dinaikkan lewat `IPHONEOS_DEPLOYMENT_TARGET` | Halaman `apple-ios` rustc |
| UniFFI | 0.32.2 (2026-09-22), 0.32.1, 0.32.0 (2026-06-30) | crates.io, CHANGELOG |
| JNA untuk UniFFI Kotlin | 5.12.0 atau lebih baru, bentuk `@aar` | Dokumentasi UniFFI |
| cargo-ndk | 4.1.2, `rust-version` 1.86 | crates.io |
| Xcode 27.1 | Swift 6.4, SDK iOS 27.1, butuh macOS 26.6+, simulator dan debug perangkat iOS 17+ | Halaman dukungan Xcode, catatan rilis |
| Xcode 27 di Mac Intel | Tidak berjalan | Catatan rilis Xcode 27 |
| Pangsa iPadOS 26 | 68% semua iPad (2026-06-07) | Apple, halaman App Store |
| AGP 9.3 | Patch 9.3.3; Gradle minimal 9.5.0; API maksimal 37; NDK bawaan 28.2.13676358; JDK minimal 17; Build Tools 36.0.0 | Catatan rilis AGP 9.3.0 |
| AGP 9.5 | Patch 9.5.1; Gradle minimal 9.6.0 | Catatan rilis AGP |
| Kotlin | 2.4.21 (2026-10-08); rentang Gradle 7.6.3 sampai 9.7.0, AGP 8.5.2 sampai 9.3.1 | Dokumentasi Kotlin |
| Gradle | 9.5.1 (2026-05-12); JVM 17 sampai 26; terbaru 9.9.1 | gradle.org, tabel kompatibilitas 9.5 |
| Compose BOM | 2026.09.00; Compose 1.12 butuh `compileSdk` 37 dan AGP 9 | Halaman BOM dan compiler Compose |
| `activity-compose` | 1.13.0 (2026-03-11) | Halaman rilis AndroidX |
| `minSdk` bawaan AndroidX | 24 | Halaman versi AndroidX |
| 16 KB | NDK r28+ selaras bawaan; AGP 8.5.1+; Play menolak pembaruan tanpa dukungan mulai 2027-02-01 | Panduan ukuran halaman Android |
| NDK LTS | r30 (30.0.16248370) | Halaman unduhan NDK |
| Target API Play | 36 sejak 2026-08-31 | Halaman syarat target SDK |
| Pangsa API 29+ | 96,6% (data Oktober 2026) | apilevels.com (pihak ketiga) |
| Platform `android-37.0` final | `Pkg.Revision=2`, `PreviewSdkInt=0` | `source.properties` di SDK mesin lead |
| Arsitektur SDK simulator | `arm64` dan `x86_64`; target minimum 15.0 | `SDKSettings.json` Xcode 27.1 di mesin lead |
| Crate UniFFI tanpa ekspor | `cargo build` dan `cargo test` lulus di host; `cargo tree` sesuai AC-2 | Uji coba di folder sementara, Rust 1.99.1, UniFFI 0.32.2 |
| Alat NDK untuk AC-4 | `toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump` ada | NDK 28.2.13676358 di mesin lead |

**Yang tidak bisa dipastikan dari dokumentasi, dan cara spec menanganinya**:

- Versi Kotlin Gradle Plugin bawaan AGP 9.3 tidak tercantum. Spec mengunci 2.4.21 lewat `classpath`, cara yang didokumentasikan catatan rilis AGP 9.0.
- Tabel Kotlin berhenti di AGP 9.3.1, spec memakai patch 9.3.3 di lini yang sama.
- Tabel uji Gradle 9.5 ditulis sebelum AGP 9.3 dan Kotlin 2.4 rilis. Kecocokan diambil dari sisi AGP (minimal 9.5.0) dan Kotlin (sampai 9.7.0).
- MSRV UniFFI 0.32 tidak tertulis (0.31 menyebut 1.87). Rust 1.99.1 jauh di atasnya.
- AGP dengan JDK 25 tidak disebut eksplisit. Build milestone 3 membuktikannya; cadangan JDK 21 sudah disetujui.
- Isi TN3117 dan halaman XCFramework Apple tidak terbaca otomatis (hanya judul). Isinya dirujuk dari pengetahuan umum: simulator di Apple silicon butuh irisan arm64, dan XCFramework menggabungkan irisan perangkat dan simulator.
- Pemetaan Material 3 adaptive di dalam BOM tidak terverifikasi; karena itu hanya dicatat sebagai kandidat untuk fitur 06.
- Checksum Gradle 9.5.1 dibaca dari halaman checksum lewat alat ambil web; developer mencocokkannya lagi saat membuat wrapper.

Penawaran pencarian Agent Skill dan server MCP untuk alat baru (langkah wajib tanya pada skill `/architect`) tidak dijalankan karena sesi koordinasi tidak boleh membuka panel pertanyaan. Tidak ada skill komunitas yang membentuk spec ini.

## References

**Project sources** (bisa diperiksa di repo ini):

- `README.md` bagian 1 sampai 6, 16, 22, 24, 25 (AC 1 dan 2), 26 langkah 1 sampai 3
- `docs/scope/index.md` (Tracer Bullet, tier Beta, "Ditunda") dan `docs/scope/01-arsitektur-dan-build-awal.md`
- `docs/scope/03-kontrak-rust-untuk-kedua-aplikasi.md`, `04-salam-rust-pada-dua-tablet.md`, `11-build-dan-pengujian-otomatis.md` (pemakai matriks)
- `docs/quality/audit-scaffold.md`, baris "Pertama"
- `docs/scope/coordination/01-arsitektur-dan-build-awal.brief-umum.md` (keadaan mesin lead)
- `README.md` bagian 5 (`tests/`, `scripts/test.sh`), 17, 21, dan 22 (strategi tes dan perintah yang bisa diulang)
- `docs/scope/10-pemeriksaan-batas-arsitektur.md` dan `docs/scope/11-build-dan-pengujian-otomatis.md` (batas lingkup suite fitur 01)
- `docs/specs/0001-arsitektur-dan-build-awal/verify.md` dan `docs/reviews/2026-11-15-verify-f01.md` (langkah yang dikunci)
- `scripts/build-ipados.sh` dan `scripts/build-android-tablet.sh` pada `main` (sumber tabel kasus I dan A)

**Practices & standards**:

- Kunci versi di file repo, bukan di dokumentasi saja (toolchain file, wrapper dengan checksum, katalog versi, lockfile)
- Hasil generasi selalu dari revisi sumber yang sama dengan pustaka yang ditautkan
- XCFramework untuk menggabungkan irisan perangkat dan simulator arm64 (TN3117)
- Satu sumber untuk tiap nilai konfigurasi

**Links** (diverifikasi lewat web pada 2026-11-15):

- Rust, catatan rilis: https://doc.rust-lang.org/stable/releases.html
- Rust 1.100.0: https://blog.rust-lang.org/2026/11/12/Rust-1.100.0/
- Rust, dukungan platform: https://doc.rust-lang.org/stable/rustc/platform-support.html
- Rust, target iOS: https://doc.rust-lang.org/stable/rustc/platform-support/apple-ios.html
- Rust, target Android: https://doc.rust-lang.org/stable/rustc/platform-support/android.html
- rustup, file toolchain: https://rust-lang.github.io/rustup/overrides.html
- UniFFI di crates.io: https://crates.io/api/v1/crates/uniffi
- UniFFI CHANGELOG: https://raw.githubusercontent.com/mozilla/uniffi-rs/main/CHANGELOG.md
- UniFFI, binding bahasa lain: https://mozilla.github.io/uniffi-rs/latest/tutorial/foreign_language_bindings.html
- UniFFI, Kotlin dan Gradle: https://mozilla.github.io/uniffi-rs/latest/kotlin/gradle.html
- UniFFI, Swift: https://mozilla.github.io/uniffi-rs/latest/swift/overview.html
- cargo-ndk di crates.io: https://crates.io/api/v1/crates/cargo-ndk
- cargo-ndk README: https://raw.githubusercontent.com/bbqsrc/cargo-ndk/main/README.md
- Xcode, dukungan: https://developer.apple.com/support/xcode/
- Xcode 27.1, catatan rilis: https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes.md
- Xcode 27, catatan rilis: https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes.md
- Apple, syarat unggah: https://developer.apple.com/news/upcoming-requirements/
- Apple, pangsa versi OS: https://developer.apple.com/support/app-store/
- TN3117 (hanya judul yang terbaca): https://developer.apple.com/documentation/technotes/tn3117-resolving-build-errors-for-apple-silicon
- AGP, catatan rilis: https://developer.android.com/build/releases/gradle-plugin
- AGP, tabel kompatibilitas: https://developer.android.com/build/releases/about-agp
- AGP 9.3.0: https://developer.android.com/build/releases/agp-9-3-0-release-notes
- AGP 9.0.0 (Kotlin bawaan): https://developer.android.com/build/releases/agp-9-0-0-release-notes
- Android, Kotlin bawaan: https://developer.android.com/build/migrate-to-built-in-kotlin
- Android, JDK untuk build: https://developer.android.com/build/jdks
- Gradle, rilis: https://gradle.org/releases/
- Gradle, checksum: https://gradle.org/release-checksums/
- Gradle 9.5, kompatibilitas: https://docs.gradle.org/9.5.0/userguide/compatibility.html
- Gradle, daemon dan kriteria JVM: https://docs.gradle.org/current/userguide/gradle_daemon.html
- Kotlin, rilis: https://kotlinlang.org/docs/releases.html
- Kotlin, kompatibilitas Gradle dan AGP: https://kotlinlang.org/docs/gradle-configure-project.html
- Compose BOM: https://developer.android.com/develop/ui/compose/bom
- Compose compiler: https://developer.android.com/develop/ui/compose/compiler
- AndroidX, versi: https://developer.android.com/jetpack/androidx/versions
- AndroidX activity: https://developer.android.com/jetpack/androidx/releases/activity
- Material 3 adaptive: https://developer.android.com/jetpack/androidx/releases/compose-material3-adaptive
- Android, ukuran halaman 16 KB: https://developer.android.com/guide/practices/page-sizes
- Android NDK, unduhan: https://developer.android.com/ndk/downloads
- Android, ABI: https://developer.android.com/ndk/guides/abis
- Google Play, target SDK: https://developer.android.com/google/play/requirements/target-sdk
- Android 16, perubahan perilaku: https://developer.android.com/about/versions/16/behavior-changes-16
- Android 17, perubahan perilaku: https://developer.android.com/about/versions/17/behavior-changes-17
- Android 17, penyiapan SDK: https://developer.android.com/about/versions/17/setup-sdk
- Pangsa API level (pihak ketiga): https://apilevels.com/
