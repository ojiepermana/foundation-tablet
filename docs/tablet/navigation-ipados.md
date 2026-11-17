# Navigasi dan jendela iPad

Keputusan ada di [spec 0004](../specs/0004-navigasi-jendela-ipad.md), batas presentasi ada di [matriks pemilik](../architecture/ownership-matrix.md). Shell hanya milik iPad. Android menyusul melalui fitur 06.

## Memakai shell

Sidebar `Fondasi` memiliki tujuan `Salam Rust` dan `Informasi Fondasi`. Tombol sidebar sistem menampilkan atau menyembunyikan daftar saat ruang cukup. Ketika window menyempit, SwiftUI memilih satu panel. Pilih tujuan untuk membukanya; tombol kembali native membuka daftar lagi. Konten dapat digulir ketika tinggi berkurang. Tidak ada panel ketiga karena belum ada objek detail.

Gunakan `Jendela Baru` di toolbar sidebar untuk membuka scene lain. Setiap scene mulai dengan Salam Rust. Pilihan tujuan, nama, serta hasil pada window pertama tidak mengikuti perubahan pada window kedua.

## Kepemilikan keadaan

`FoundationShell` di `apps/ipados/Tablet/App/TabletApp.swift` menyimpan tujuan (`navigation.destination`) dan panel compact (`navigation.compactColumn`) melalui SceneStorage. Tombol kembali mengubah panel, bukan menghapus tujuan terakhir. Key yang tidak dikenal memakai fallback masing masing: greeting dan detail. Visibilitas sidebar regular serta ukuran window mengikuti sistem, tidak dijanjikan pulih dari snapshot.

Nama dan hasil salam hanya berada dalam memori shell scene. Berpindah halaman, rotasi, resize, serta background pada scene hidup mempertahankan keduanya. Setelah proses dan scene dibuat ulang, nama kembali Ayu dan hasil kosong. Navigasi dipulihkan ketika sistem menyediakan snapshot scene itu. Scene baru, scene yang ditutup eksplisit, atau pemasangan ulang memakai default. Data scene tidak menggantikan penyimpanan bisnis dan tidak dipindah ke Rust.

## Menjalankan pemeriksaan

Ikuti [panduan mulai singkat](../getting-started.md) untuk build, install, launch, dan memilih UDID iPad. Jalankan `scripts/build-ipados.sh`, kemudian `scripts/test-ipados.sh <UDID>`. Tes salam dan navigasi berada di `apps/ipados/TabletUITests/GreetingUITests.swift`. Debug mengenali `--fresh-navigation` untuk memulai tes dari default navigasi; Release mengabaikannya. Tes pemulihan tidak memakai argumen ini.

Pemeriksaan manual meliputi sidebar plus konten pada portrait dan landscape, window sempit dan pendek, kembali native, melebarkan window lagi, serta dua scene. Untuk proses: pilih informasi, tekan Home agar snapshot disimpan, jalankan `xcrun simctl terminate <UDID> com.example.tablet`, lalu `xcrun simctl launch <UDID> com.example.tablet`. Catat tujuan yang benar benar tampil dan apakah kembali membuka daftar. Ulangi ketika panel daftar aktif. Dalam Windowed Apps, Home dapat meninggalkan window lain tetap aktif. Untuk checkpoint background yang pasti, tutup scene tambahan lalu aktifkan Settings layar penuh sebelum menghentikan aplikasi. Jangan menghitung override size class sebagai bukti resize window nyata.

`Info.plist` hasil build harus memiliki `UIApplicationSceneManifest.UIApplicationSupportsMultipleScenes = true`. Build tidak membutuhkan signing produksi. `scripts/test.sh artifacts/ipados` juga mensyaratkan tree Git bersih, jadi jalankan pemeriksaan itu pada snapshot kerja bersih, bukan menyimpulkan hasil generasi bocor hanya karena ada edit sumber yang belum di-commit.

Bukti aktual per target ada di [laporan scope 05](../reviews/2026-11-17-verify-f05.md). Perangkat fisik dan Android tidak boleh disebut lulus dari hasil simulator iPad.

Tes `testCompactBackAndBothRestoredPanels` memerlukan window nyata sempit (misalnya menu sistem Window, Move & Resize, Left atau Top Left). Suite pada layar penuh melewati tes ini dengan alasan eksplisit; itu bukan bukti compact lulus. Pada lingkungan yang dicatat dalam laporan, proses compositor simulator berhenti saat pemulihan compact. Tidak ada flag atau workaround percobaan yang ditinggalkan dalam aplikasi.

## Penutupan scope 05

Pengguna meminta scope 05 diselesaikan dengan verifikasi compact ditunda. Status done dan spec Accepted mencatat pengecualian itu. Bukti compact yang belum selesai tetap NOT_RUN, dan tesnya tetap tersedia untuk target yang operasional. Untuk menjalankan regresi selain compact secara eksplisit, tambahkan `-skip-testing:TabletUITests/GreetingUITests/testCompactBackAndBothRestoredPanels` pada perintah `xcodebuild test` milik runner. Tes pemulihan layar penuh menggunakan satu scene dan Home; lingkungan Windowed Apps dengan banyak scene perlu checkpoint background terpisah.
