# Konvensi kontrak FFI

Dokumen ini berisi aturan untuk kontrak antara inti Rust dan kedua aplikasi native: apa yang boleh menyeberang batas UniFFI, bentuknya, siapa pemilik nilainya, dan cara menambah fungsi tanpa merusak kedua aplikasi. Keputusannya dicatat di [spec 0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md); arah dependensi ada di [aturan dependensi](../architecture/dependency-rules.md).

Kontrak yang ada sekarang hanya satu fungsi:

```rust
// crates/tablet-ffi/src/lib.rs
#[uniffi::export]
pub fn hello(name: String) -> String {
    tablet_core::hello(name)
}
```

Swift melihatnya sebagai `hello(name:)` di modul `TabletBindings`, Kotlin sebagai `hello(name)` di paket `foundation.tablet.bindings`. Topik yang belum dipakai kontrak apa pun ditandai **ditetapkan, belum dipakai**: aturannya sudah berlaku, tetapi belum ada kode yang memakainya.

## Antarmuka UniFFI

Kontrak hanya ditulis dengan makro UniFFI di `crates/tablet-ffi`: `#[uniffi::export]` untuk fungsi dan metode, serta derive `uniffi::Record`, `uniffi::Enum`, `uniffi::Object`, dan `uniffi::Error` untuk tipe. Tidak ada file UDL. `tablet-ffi` memanggil `uniffi::setup_scaffolding!()` sekali.

Nama di Rust memakai `snake_case`. Generator memetakannya ke `camelCase` di Swift dan Kotlin, jadi tidak perlu nama ganda.

`tablet-ffi` tidak punya perilaku sendiri. Setiap fungsi yang diekspor hanya mengubah tipe dan memanggil `tablet-core`. Aturan, validasi, dan perhitungan selalu ada di `tablet-core`.

## DTO Rust

Tipe yang menyeberang batas (DTO, objek pembawa data) didefinisikan di `tablet-ffi`. Tipe inti tidak memakai derive UniFFI dan tidak diekspos langsung, supaya struktur internal inti bisa berubah tanpa memutus kontrak. Konversi antara keduanya memakai `From` (atau `TryFrom` bila bisa gagal) di `tablet-ffi`.

Jangan membuat DTO sebelum ada fitur yang memakainya. Entitas bisnis (pelanggan, pesanan, dan sejenisnya) baru boleh masuk kontrak sesudah fiturnya punya scope dan spec.

## Galat bertipe

Fungsi yang bisa gagal mengembalikan `Result<T, E>`. `E` adalah enum per area di `tablet-ffi` dengan `#[derive(Debug, uniffi::Error)]`, dipetakan dari galat inti. Swift menerimanya sebagai `throws`, Kotlin sebagai exception bertipe.

Fungsi yang tidak bisa gagal, seperti `hello`, tidak memakai `Result`.

Panic bukan cara melapor galat. UniFFI menangkap panic di batas dan mengubahnya menjadi galat internal: di Swift aplikasi berhenti (binding memakai `try!` untuk fungsi tanpa `Result`), di Kotlin muncul `InternalException`. Karena penangkapan ini butuh unwinding, profil build tidak memakai `panic = "abort"`.

## Kode galat yang terbaca mesin

Nama varian enum galat adalah kodenya. Aplikasi mencocokkan varian, bukan teks pesan. Pesan untuk manusia boleh berubah kapan saja; nama varian tidak diganti atau dihapus tanpa langkah kompatibilitas (lihat [Kompatibilitas](#kompatibilitas)).

Ditetapkan, belum dipakai: belum ada fungsi yang bisa gagal.

## Nullability

Ketiadaan nilai hanya dinyatakan dengan `Option<T>`, yang menjadi `T?` di Swift dan Kotlin. Jangan memakai nilai pengganti seperti string kosong, `0`, atau `-1` untuk arti "tidak ada".

String kosong adalah nilai biasa. `hello("")` mengembalikan `Hello, !`.

## Kepemilikan sumber daya

String, angka, record, dan enum **disalin** saat menyeberang. Setelah fungsi kembali, tidak ada pihak yang memegang memori pihak lain. Rust tidak menyimpan `name` atau hasil `hello`.

String berupa UTF 8 di batas. Swift selalu memberi UTF 8 yang sah. Encoder Kotlin mengganti surrogate tunggal yang tidak sah sebelum mengirim, jadi Rust tidak pernah menerima UTF 8 rusak.

Ditetapkan, belum dipakai: objek (`uniffi::Object`) dibungkus `Arc` di Rust dan hidup selama masih ada referensi. Swift melepasnya saat `deinit`. Kotlin melepasnya lewat `close()` (objek binding mengimplementasi `AutoCloseable`) atau lewat cleaner. Konfigurasi cleaner Android diputuskan saat objek pertama diekspor (spec 0002, K9).

## Thread pemanggil

Fungsi sinkron dalam kontrak harus cepat dan tidak memblokir: tanpa I/O, tanpa menunggu kunci atau jaringan. Dengan begitu aplikasi boleh memanggilnya dari main thread. `hello` memenuhi aturan ini.

Pekerjaan yang bisa lama tidak dibuat sebagai fungsi sinkron; tunggu keputusan [async](#operasi-async). Rust tidak mengasumsikan dipanggil dari thread tertentu.

## Kompatibilitas

Binding dan pustaka selalu berasal dari revisi sumber yang sama. `scripts/generate-bindings.sh` menolak pustaka yang lebih tua dari file sumbernya, dan binding satu platform harus identik untuk semua target platform itu. Karena itu tidak ada janji ABI (antarmuka biner) antar versi.

Checksum UniFFI tetap aktif. Binding yang tidak cocok dengan pustaka gagal dengan jelas, bukan diam diam: Kotlin saat pustaka dimuat, Swift saat fungsi pertama dipanggil.

- **Aditif:** menambah fungsi, tipe, varian enum yang belum dicocokkan aplikasi, atau field record baru.
- **Memutus:** mengganti nama, menghapus, mengubah tipe parameter atau nilai kembali, atau mengganti nama varian galat. Perubahan ini dikerjakan dalam satu commit bersama pembaruan kedua aplikasi.

## Versi

Versi kontrak sama dengan `version` di `[workspace.package]` pada `Cargo.toml` akar. Tidak ada nomor versi kontrak terpisah selama kedua aplikasi ada di repo yang sama.

## Operasi async

Ditetapkan, belum dipakai. Fungsi async pertama butuh spec lewat `/architect` yang memilih runtime (fitur `tokio` UniFFI, atau tanpa runtime) dan dependensi coroutine di Kotlin. Sampai ada, kontrak tidak memuat fungsi `async`.

## Pembatalan

Ditetapkan, belum dipakai. Mengikuti keputusan async. Sampai keputusan itu ada, kontrak tidak menawarkan operasi panjang yang perlu dibatalkan.

## Antarmuka kemampuan native

Ditetapkan, belum dipakai. Kemampuan platform yang dibutuhkan Rust (misalnya penyimpanan aman atau jam sistem) menjadi trait `#[uniffi::export(with_foreign)]` yang diimplementasikan di Swift dan Kotlin. Setiap antarmuka pertama butuh spec karena menyangkut izin native, dan izin native hanya untuk fitur yang tercatat.

## Kontrak transport

Kontrak aplikasi dan FFI di dokumen ini terpisah dari kontrak transport yang mungkin datang nanti (misalnya OpenAPI untuk layanan jaringan). Tipe transport tidak langsung menjadi tipe FFI; `tablet-core` memetakannya ke tipe inti, lalu `tablet-ffi` ke DTO.

## Hasil generasi

| Hasil | Lokasi | Di-commit |
| --- | --- | --- |
| Sumber Swift `TabletBindings.swift` | `bindings/swift/Sources/TabletBindings/` | Tidak |
| Header C `TabletFFI.h` dan `module.modulemap` | `target/bindings/swift/headers/TabletFFI/` | Tidak |
| Sumber Kotlin `tablet_ffi.kt` | `bindings/kotlin/foundation/tablet/bindings/` | Tidak |
| Konfigurasi generator | `crates/tablet-ffi/uniffi.toml` | Ya |
| Paket Swift `Package.swift` (fitur 04) | `bindings/swift/` | Ya |

Semua hasil generasi dibuat `scripts/generate-bindings.sh` dan tidak pernah disunting tangan. Untuk mengubahnya, ubah Rust atau `uniffi.toml`, lalu jalankan skripnya lagi. Generator berasal dari crate `tooling/uniffi-bindgen` yang memakai pin `uniffi` workspace, jadi versinya selalu sama dengan runtime.

## Menambah fungsi kontrak

1. Tulis perilakunya beserta tes unit di `crates/core`.
2. Petakan di `crates/tablet-ffi` dengan `#[uniffi::export]`, tanpa logika tambahan, dan tambahkan tes asap.
3. Jalankan `scripts/build-ipados.sh` dan `scripts/build-android-tablet.sh`, lalu `scripts/generate-bindings.sh swift ...` dan `scripts/generate-bindings.sh kotlin ...` dengan pustaka yang baru dibangun (perintah persis ada di [panduan mulai singkat](../getting-started.md#menghasilkan-binding)).
4. Panggil fungsinya dari kedua aplikasi bila fitur memintanya.
5. Jalankan pemeriksaan pada `AGENTS.md` dan cek kedua platform menurut [panduan kontribusi](../contributing.md).

Bila fungsi baru butuh hal yang di atas masih **ditetapkan, belum dipakai** (async, objek, galat pertama, antarmuka native), catat keputusannya dulu lewat `/architect`.
