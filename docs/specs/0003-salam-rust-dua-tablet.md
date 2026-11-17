# 0003. Salam Rust pada dua tablet

**Date**: 2026-11-16
**Status**: Accepted

## Summary

Kedua aplikasi menampilkan satu kolom nama dan tombol untuk meminta salam dari Rust. Skrip build menghasilkan binding dan mengemas pustaka sebelum proyek native dibangun. Tes pada simulator iPad dan emulator tablet Android membuktikan bahwa perubahan nama menyeberangi batas bahasa.

## Context

Fitur 03 sudah menetapkan kontrak dan generator, tetapi aplikasi masih menampilkan teks statis. Fitur 04 harus membuktikan perjalanan dari input native ke Rust dan kembali ke layar, termasuk build dari clone bersih dan workflow pull request pertama. Batas fitur ini satu layar, tanpa navigasi, token, layanan, atau persistensi bisnis.

Desain dijalankan oleh Leader melalui architect dengan kebijakan agent-flow `auto` bawaan. Kebutuhan, nilai, keadaan, integrasi, galat, keamanan, dan pengujian dievaluasi dari scope 04, README bagian 6 dan 25, serta serah terima spec 0002. Tidak ada preferensi pengguna baru yang diperlukan.

## Requirements

**User stories**:

- Sebagai kontributor, saya dapat mengetik nama pada setiap tablet dan melihat salam Rust agar satu implementasi bersama terbukti dipakai.
- Sebagai reviewer, saya dapat membangun dan menguji revisi yang sama pada kedua platform dari perintah yang terdokumentasi.

**Acceptance criteria**:

- **AC-1** (README AC 5, 7, 9): skrip iPad menghasilkan binding dari tepat slice yang dibangunnya, mengemas XCFramework dengan header, dan membangun aplikasi Debug simulator serta Release perangkat tanpa tanda tangan produksi. Aplikasi memakai produk lokal `TabletBindings`. Mode satu slice tetap bekerja.
- **AC-2** (README AC 6, 8, 10): skrip Android menghasilkan binding dari kedua pustaka Rust, mengemas hanya ABI terdaftar ke `jniLibs`, dan membangun APK debug yang memuat `libtablet_ffi.so` serta runtime JNA untuk kedua ABI. Kode Kotlin hasil generasi ikut dikompilasi.
- **AC-3** (kedua platform): layar berjudul `Salam Rust` memiliki kolom berlabel `Nama`, nilai awal `Ayu`, tombol `Sapa`, petunjuk `Masukkan nama, lalu tekan Sapa.`, dan hasil awal kosong. Aksi tombol atau submit keyboard memanggil binding `hello` dengan isi kolom saat itu, menampilkan nilai kembalian persis. Menyunting nama saja mempertahankan hasil terakhir. Tidak ada trim, validasi, atau format salam di native.
- **AC-4** (kedua platform): tes UI nyata mengirim `Ayu`, mengganti ke `Bima`, lalu menguji string kosong dan `Zoë 東京`. Hasil masing masing persis `Hello, Ayu!`, `Hello, Bima!`, `Hello, !`, dan `Hello, Zoë 東京!`. Pemeriksaan hasil dilakukan pada layar, bukan hanya fungsi Rust. Tes juga membuktikan hasil tidak berubah sebelum aksi berikutnya.
- **AC-5** (kedua platform): konten satu kolom dapat digulir, berada dalam safe area atau inset sistem, lebar isi dibatasi sekitar 560 point/dp dan diletakkan di tengah ruang tablet. Kontrol memakai komponen sistem, label dapat diakses, hasil dapat dibaca dalam beberapa baris. Nama dan hasil adalah keadaan tampilan per scene atau Activity, Android memakai `rememberSaveable`. Navigasi dan pemulihan proses iPad di luar fitur ini.
- **AC-6** (kedua platform): panduan menjelaskan perintah build, install, launch, dan tes UI, lokasi hasil, serta langkah Ayu menjadi Bima. Arsitektur dan pemilik mencerminkan dependensi nyata. Hasil generasi tetap diabaikan Git; build tidak mengubah sumber terlacak.
- **AC-7** (kedua platform): workflow `pull_request` pertama pada runner baru menginstal alat dari sumber kunci, menjalankan gerbang Rust/repo, skrip build yang sama dengan lokal, dan tes UI pada simulator iPad atau emulator tablet Android. Tiap job mencatat SHA revisi dan hasil target. Semua action memakai SHA penuh, `permissions: contents: read`, tanpa rahasia atau penandatanganan produksi. Bukti eksekusi hosted CI wajib dicatat terpisah dari uji lokal; konfigurasi saja bukan PASS.
- **AC-8**: `cargo fmt --all --check`, `cargo clippy --workspace --locked --all-targets -- -D warnings`, `cargo test --workspace --locked`, `scripts/test.sh`, kedua skrip build dan `scripts/test.sh artifacts` lulus. Bukti per kriteria dan target berada di `docs/reviews/`, menyebut SHA dasar beserta identitas patch bila belum di-commit. Fitur tetap in-progress selama bukti wajib belum lengkap.

## Options considered

### Opsi 1: State lokal dan kontrol native, direkomendasikan

Setiap layar menyimpan nama serta hasil terakhir, lalu memanggil fungsi sinkron yang sudah ditetapkan. Kelebihannya jalur FFI terlihat langsung dan tidak memerlukan lapisan tambahan. Kekurangannya pengujian harus meluncurkan aplikasi dan tidak menyediakan contoh ViewModel untuk fitur berikutnya.

### Opsi 2: ViewModel dan adapter kontrak tambahan

Membuat objek keadaan dan antarmuka pembungkus di setiap aplikasi memberi seam tes unit. Kelebihannya mudah diperluas untuk alur panjang. Kekurangannya menambah abstraksi yang tidak diperlukan untuk dua string lokal dan dapat mengaburkan bukti FFI yang diminta.

## Decision

**Chosen option**: Opsi 1. Gunakan state presentasi lokal dan kontrol SwiftUI atau Material 3 bawaan, tanpa dependensi UI produksi baru. Pengemasan mengikuti serah terima spec 0002 tanpa mengubah kontrak Accepted itu.

JNA memakai pin yang telah disetujui spec 0002, ditambahkan sekali ke katalog Android sebagai AAR. Pengujian Android memakai Compose UI test dari BOM yang sudah dikunci dan AndroidX test runner (pin `androidxTestRunner` di katalog) dan ext.junit (pin `androidxTestJunit` di katalog), masing masing versi stabil yang diverifikasi pada desain, dengan pin persis di katalog. Dependensi tes dipelihara Android Open Source Project dengan lisensi Apache 2.0; runtime JNA dipelihara Java Native Access dengan lisensi LGPL 2.1 atau Apache 2.0. Tidak ada dependensi Rust baru.

## Rationale

Dua string dan satu fungsi cepat tidak membutuhkan model bisnis, layanan, atau thread baru. State SwiftUI dan Compose membuat pembagian kepemilikan jelas, sedangkan tes UI memeriksa binding, linker, checksum dan kemasan native sekaligus. XCTest UI bawaan Xcode dan Compose UI test dipilih agar alur yang sama dapat berjalan di CI tanpa mengotomasi koordinat layar.

Runner Apple memakai label `xcode-27` yang tersedia pada inventaris resmi GitHub saat desain ini dibuat. Pilihan Xcode tetap dibaca dari `.xcode-version`. Android memakai runner Linux dengan emulator x86_64 berprofil tablet. Image emulator memakai API dari sumber katalog yang telah ada, bukan minimum platform yang disalin ke workflow. Bila runner atau image tidak tersedia, job gagal dengan sebabnya, tidak mengubah target untuk mengklaim lulus.

## Feature design

**Data model sketch**: `name: String` wajib, awal `Ayu`; `greeting: String` wajib, awal kosong. Tidak ada basis data, relasi, identitas, atau keadaan bersama Rust.

**State transitions**: edit mengubah `name` saja. Tombol dan submit mengisi `greeting = hello(name)`. Panggilan sinkron pada main thread diperbolehkan oleh konvensi kontrak. Setiap scene iPad mempunyai state sendiri.

**API surface**:

| Aksi | Masukan | Keluaran | Akses | Galat |
| --- | --- | --- | --- | --- |
| `Sapa` atau submit | isi kolom `name` | string dari binding `hello` | lokal, tanpa autentikasi | Kesalahan kemasan atau checksum menggagalkan build/tes; tidak disamarkan dengan salam buatan |
| build iPad | mode yang sudah ada | binding, XCFramework, aplikasi | lokal/CI | generasi gagal menghentikan build sebelum Xcode |
| build Android | ABI dari properti | binding, jniLibs, APK | lokal/CI | generasi gagal menghentikan build sebelum Gradle |

**Value sourcing**:

| Aksi | Nilai | Sumber |
| --- | --- | --- |
| tampil awal | judul, label, tombol, petunjuk | literal presentasi pada AC-3 |
| tampil awal | `name`, `greeting` | nilai awal AC-3 |
| edit | `name` | input native pengguna, disimpan tanpa perubahan |
| submit | `greeting` | nilai kembalian binding dari fungsi Rust spec 0002 |
| kemas | nama modul, pustaka, path | serah terima spec 0002 dan skrip build spec 0001 |
| tes/CI | target OS, alat, ABI | katalog, xcconfig, toolchain dan properti yang sudah dikunci |
| bukti | SHA, hasil | checkout yang benar benar diuji dan exit code/pernyataan tes |

**Key invariants**: Rust satu satunya pembentuk salam. Binding tidak disunting. Proyek native tidak memanggil Cargo atau merujuk `target/`. Skrip build memakai target mobile `tablet-ffi` saja. Tidak ada navigasi atau sumber kanonis token/teks baru.

**Security model**: semua operasi lokal; tidak ada izin native atau rahasia baru. Nama pengguna tidak dicatat ke log aplikasi. Tes memakai nama fixture, tidak mengambil data pengguna. CI pull request tidak membaca secret dan checkout mematikan persistensi kredensial.

**Critical test scenarios**:

- Ayu, edit Bima tanpa submit, submit Bima, kosong, Unicode melalui layar, AC-3 dan AC-4.
- Build default dan mode iPad satu slice, isi APK kedua ABI, AC-1 dan AC-2.
- Kegagalan generator menghentikan build dan mempertahankan galat, AC-8.
- Clone bersih dengan generated output tidak ada, build dan jalankan tes UI, AC-6 sampai AC-8.
- Kontrol dapat dijangkau dan hasil tampil setelah keyboard/rotasi, AC-5; pengujian aksesibilitas lengkap tetap fitur 07.

### Sumber alat tes dan CI

- `androidx-test-runner`: `androidx.test:runner`, pin `androidxTestRunner` di katalog. `androidx-test-junit`: `androidx.test.ext:junit`, pin `androidxTestJunit`. Nilai stabil diperiksa dari halaman rilis AndroidX Test resmi pada tanggal spec. `androidx-compose-ui-test-junit4` dan `androidx-compose-ui-test-manifest` memakai versi BOM Compose yang sudah dikunci. Dependensi ini hanya untuk tes/debug.
- CI Android membaca `targetSdk` untuk API emulator, tag `google_apis`, ABI `x86_64`, profil `pixel_tablet`, nama AVD khusus `Foundation_Tablet_CI`. Pengujian lokal di Apple silicon memakai image yang sama dengan ABI `arm64-v8a`. Bila profil itu tidak ditemukan, perintah gagal dengan petunjuk SDK Manager.
- CI membaca JDK dari `gradle-daemon-jvm.properties`, cargo-ndk dari nilai `EXPECTED_CARGO_NDK` skrip Android yang sudah menjadi pemeriksaan repo, NDK dan compileSdk dari katalog, Xcode dari `.xcode-version`, Rust dari `rust-toolchain.toml`. Action dan SHA dipilih dari tag rilis resmi yang diperiksa saat implementasi, lalu dikunci penuh dalam workflow.

## Build plan

Pendekatan Tracer Bullet, pertama dua jalur tipis dari layar sampai Rust lalu penguatan serta otomasi.

1. Tautkan binding dan pustaka, bangun layar input masing masing platform, AC-1, AC-2, AC-3, AC-5. Implementasi native boleh paralel karena path berbeda.
2. Jalankan alur Ayu lalu Bima pada kedua target, tambahkan tes UI kasus kosong/Unicode dan regresi skrip/kemasan, AC-4 dan AC-8.
3. Tambahkan workflow PR yang memanggil jalur lokal yang sama, perbarui panduan serta arsitektur, buktikan clone bersih, AC-6, AC-7 dan AC-8.

## Consequences

Pengujian menangkap kesalahan linker, checksum dan pustaka yang hilang di aplikasi nyata. State lokal sederhana dan mudah dibaca. Biayanya dua target UI test native dan waktu boot simulator/emulator dalam CI. CI hosted baru terbukti setelah revisi dipublikasikan dan job selesai, sehingga uji lokal saja tidak menutup fitur.

## Follow-up

- Fitur 05 sampai 09 memperluas navigasi, pemulihan state, input, aksesibilitas, token dan sumber daya bersama. Fitur 11 memperluas CI tanpa mengambil alih kebutuhan PR pertama di fitur 04.

## Catatan pelaksanaan desain

Cross-check spec segar pada Native Subagents (`gpt-6.1-sol`, effort high diminta) menemukan tiga celah sumber: koordinat/pin alat tes, profil/image emulator, dan sumber pemilihan Xcode/JDK. Rekomendasi diperiksa serta diterapkan lewat mode auto. Tidak ada perubahan kontrak Rust. Independensi keluarga model terhadap penulis tidak terverifikasi karena metadata exact Leader tidak tersedia; ini bukan klaim review GA independen. Keputusan teknis diterima oleh Leader berdasarkan kebijakan agent-flow auto, status tetap In Progress sampai bukti wajib lengkap.
