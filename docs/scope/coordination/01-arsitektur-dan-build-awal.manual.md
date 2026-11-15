# Langkah manual: `01-arsitektur-dan-build-awal`

Catat pemeriksaan yang memerlukan akses atau perangkat tambahan beserta kode yang diuji, target dan hasil pengamatan. Setelah bukti diterima, checker memvalidasi setiap AC pada target yang sama. Kriteria wajib tetap terbuka sampai hasilnya `PASS`.

Keputusan yang diambil atas namamu ada di `01-arsitektur-dan-build-awal.log.md` bagian "Keputusan delegasi"; baris bertanda `berat` paling perlu kamu baca. Untuk membatalkan satu baris, sebut barisnya ke lead.

## Ringkasan

| ID | Langkah | AC dan kotak yang menunggu | Commit | Target dan OS | Hasil | Bukti |
| --- | --- | --- | --- | --- | --- | --- |
| `F01-1` | Jalankan `Tablet` di iPad fisik (MAN-1 spec 0001) | Baris "iPad perangkat" matriks dukungan; melengkapi AC-6. Bukan syarat kotak fitur 01; diwarisi fitur 04, 11, 12 | belum ada (menunggu milestone 2) | iPad fisik, iPadOS 26.0 atau lebih baru | `NOT_RUN` | belum ada |
| `F01-2` | Pasang dan buka APK di tablet Android fisik (MAN-2) | Baris "Tablet Android" matriks; melengkapi AC-7. Bukan syarat kotak fitur 01; diwarisi fitur 04, 11, 12 | belum ada (menunggu milestone 3) | tablet arm64, Android 10 atau lebih baru | `NOT_RUN` | belum ada |
| `F01-3` | Ulangi F01-2 di perangkat halaman memori 16 KB (MAN-3) | Baris "Halaman memori 16 KB" matriks; melengkapi AC-4. Bukan syarat kotak fitur 01; diwarisi fitur 11, 12 | belum ada (menunggu milestone 3) | perangkat dengan `getconf PAGE_SIZE` = `16384` | `NOT_RUN` | belum ada |

## Nilai dari user

Nilai yang hanya kamu tahu. AC di kolom ketiga `BLOCKED` sampai nilainya ada.

| ID | Nilai yang dibutuhkan | AC yang menunggu | File yang menunggu |
| --- | --- | --- | --- |
| `N1` | Bundle ID iPad asli (sementara `com.example.tablet`) | F01-1; tidak menahan AC fitur 01 | `apps/ipados/Config/Local.xcconfig` (tidak di-commit) atau `apps/ipados/Config/Base.xcconfig` |
| `N2` | `applicationId` Android asli (sementara `com.example.tablet`) | tidak menahan AC fitur 01 | `apps/android-tablet/gradle.properties` kunci `tablet.applicationId` |
| `N3` | Team ID Apple (`DEVELOPMENT_TEAM`) | F01-1 | `apps/ipados/Config/Local.xcconfig` |
| `N4` | Lisensi repo | tidak menahan AC fitur 01 | `Cargo.toml` field `license` (sengaja belum diisi) |

## Fitur 01: Arsitektur dan build awal (spec 0001)

Ketiga langkah berasal dari laporan `arc-f1-spec` (2026-11-15), bagian "Bukti perangkat fisik" spec 0001. Tidak satu pun menjadi syarat penutupan AC fitur 01: AC-4, AC-6, dan AC-7 hanya menjanjikan build. Hasilnya diwarisi fitur 04, 11, dan 12.

### `F01-1` · iPad fisik (MAN-1)

- **Prasyarat:** milestone 2 sudah di `main`; Mac dengan Xcode 27.1; iPad dengan iPadOS 26.0 atau lebih baru, terhubung, Mode Pengembang aktif; `apps/ipados/Config/Local.xcconfig` berisi `DEVELOPMENT_TEAM = <Team ID>` dan `PRODUCT_BUNDLE_IDENTIFIER = <bundle ID asli>` (nilai N1 dan N3).
- **Jalankan:** buka `apps/ipados/Tablet.xcodeproj`, pilih skema `Tablet` dan iPad itu sebagai tujuan, tekan Run.
- **Lulus bila:** aplikasi terpasang dan terbuka, menampilkan satu teks statis, tidak crash. Catat model iPad dan versi iPadOS.
- **Hanya langkah ini yang bisa membuktikan:** tanda tangan kode, pemasangan, dan peluncuran di perangkat; AC-6 membangun tanpa tanda tangan.

### `F01-2` · Tablet Android fisik (MAN-2)

- **Prasyarat:** milestone 3 sudah di `main`; tablet Android 10 atau lebih baru dengan `adb shell getprop ro.product.cpu.abi` bernilai `arm64-v8a`, opsi pengembang dan debugging USB aktif.
- **Jalankan:**
  - `scripts/build-android-tablet.sh`
  - `adb devices`
  - `adb install -r apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk`
  - `adb shell am start -n com.example.tablet/foundation.tablet.MainActivity`
- **Lulus bila:** `adb install` mencetak `Success`, layar menampilkan satu teks statis, tidak crash. Catat model dan `adb shell getprop ro.build.version.release`.
- **Hanya langkah ini yang bisa membuktikan:** pemasangan dan peluncuran di perangkat keras tablet; AC-7 hanya memeriksa isi APK.

### `F01-3` · Perangkat halaman memori 16 KB (MAN-3)

- **Prasyarat:** seperti F01-2, pada perangkat yang `adb shell getconf PAGE_SIZE` mengembalikan `16384`.
- **Jalankan:** sama dengan F01-2.
- **Lulus bila:** aplikasi terpasang dan terbuka tanpa dialog kompatibilitas ukuran halaman.
- **Hanya langkah ini yang bisa membuktikan:** pemuatan pustaka pada kernel 16 KB nyata; AC-4 hanya memeriksa keselarasan ELF.
