# 0004. Navigasi dan jendela iPad

**Date**: 2026-11-17
**Status**: Accepted

## Summary

Anda dapat berpindah antara Salam Rust dan Informasi Fondasi melalui sidebar SwiftUI. Jendela sempit memakai satu panel dengan aksi kembali native. Pilihan dan panel aktif dimiliki setiap scene.

## Context

Scope 05 memperluas layar salam yang sudah memakai binding Rust. Scope 04 menyediakan implementasi salam dan tes lokal. Saat fitur ini berjalan, penutupan scope 04 masuk lewat commit dokumentasi 9d2c72d, tanpa mengubah source dependensi fitur ini. Fitur ini hanya mengubah presentasi iPad. Android, input lanjutan, token, bisnis, serta layar eksternal tetap milik fitur lain.

Architect dijalankan inline dengan kebijakan agent-flow auto bawaan. Kebutuhan berasal dari scope 05, README bagian 7 dan 8, design.md serta matriks pemilik. Tidak ada akun, basis data, endpoint, dependensi, izin native, atau aset baru. Model data hanya keadaan presentasi lokal. Riset dibatasi dokumentasi Apple untuk navigasi dan penyimpanan scene.

## Requirements

- **AC-1** (README 11, 12): dua tujuan native, `Salam Rust` dan `Informasi Fondasi`, dapat dipilih. Salam tetap memanggil binding Rust yang sama; nama dan hasil terakhir bertahan ketika berpindah tujuan dalam scene yang hidup.
- **AC-2** (README 13, 15): pada iPad tegak dan mendatar dengan ruang cukup, sidebar dan konten dapat terlihat bersama. Toolbar sistem dapat menyembunyikan serta menampilkan sidebar. Tidak ada panel ketiga kosong.
- **AC-3** (README 14): jendela nyata yang menyempit menampilkan satu panel, tujuan dapat dibuka dan aksi kembali native membuka daftar tujuan. Isi tetap dapat digulir ketika tinggi berkurang. Melebarkan kembali jendela mempertahankan tujuan.
- **AC-4** (README 16): rotasi, resize, multitasking, dan background ke foreground tidak mengubah tujuan atau nama dan hasil pada scene hidup. Ukuran berasal dari ruang jendela dan adaptasi SwiftUI, bukan model perangkat atau orientasi sebagai pemilih layout.
- **AC-5** (README 16): setiap scene menyimpan tujuan dan panel compact aktif dengan SceneStorage. Saat sistem memulihkan scene, tujuan serta aksi kembali dipulihkan dari snapshot scene itu. Setiap key snapshot yang tidak tersedia atau tidak dikenal memakai fallback sendiri, tujuan Salam Rust dan panel konten. Nilai tujuan sah tetap dipertahankan jika panel tidak sah, demikian juga sebaliknya. Scene baru mulai mandiri dari default. Nama dan hasil salam hanya memori scene hidup, kembali Ayu dan kosong setelah scene dibuat ulang. Menutup scene secara eksplisit atau menghapus app tidak menjanjikan pemulihan. Tes mencakup pemulihan scene setelah aplikasi dibackground, dihentikan, dan dibuka lagi, termasuk panel daftar dan konten; juga scene baru serta isolasi dua scene.
- **AC-6**: gerbang Rust dan repo, build simulator Debug dan perangkat Release tanpa signing, pemeriksaan artefak iPad, tes UI salam lama serta regresi navigasi lulus. Bukti per AC per target mencatat PASS, FAIL, atau NOT_RUN di docs/reviews. Simulator nyata dibedakan dari tes state atau override ukuran. Target perangkat fisik dilaporkan terpisah, tidak menjadi syarat fitur karena tidak tersedia dalam fondasi lokal. Build Android tidak wajib karena kontrak dan sumber bersama tidak berubah.

## Pengecualian penutupan yang diminta pengguna

Pada 2026-11-17 pengguna memperjelas: “Maksud saya skip verifikasi compact dulu, lanjutkan dan selesaikan scope 5.” Verifikasi compact yang belum selesai ditunda dan tidak menjadi gerbang penutupan scope ini. Kebutuhan perilaku serta tes compact tetap dipertahankan. Hasilnya tetap NOT_RUN, bukan PASS. Gerbang build, repo, serta regresi selain compact tetap diselesaikan sebelum status Accepted. Ini menggantikan penafsiran awal bahwa seluruh goal perlu dijeda.

## Options considered

1. Dua kolom NavigationSplitView dengan List serta NavigationLink, direkomendasikan. SwiftUI memiliki transisi, tombol kembali, dan toggle sidebar. SceneStorage cocok untuk snapshot scene. Tidak perlu framework atau aturan layout buatan.
2. NavigationStack dan sidebar manual berdasarkan breakpoint. Memudahkan kontrol penuh tetapi menduplikasi perilaku sistem dan menambah sinkronisasi state.
3. Tiga kolom. Belum ada objek detail terpilih yang membutuhkan panel ketiga.

## Decision

Gunakan opsi 1. Source dan test implementation dapat dikerjakan sebagai bounded native_task_adaptation oleh Native Subagents; ini bukan delegasi workflow develop atau test. Leader memiliki spec, integrasi, keputusan penerimaan, bukti, scope, dan sync. Cross check spec read only dilakukan sebelum implementasi sesuai tier Beta, melalui fresh context gpt-6.1-terra high. Identitas keluarga author tidak tersedia, maka independensi keluarga unverified. Temuan fallback, transisi nil dan kembali, scene baru, default tes, dan ukuran target telah ditutup di bagian desain. Penerimaan teknis otomatis dilakukan setelah pemeriksaan ini. Tidak diperlukan review GA terpisah.

**Implementation skills**: tidak ada tambahan di luar workflow yang dipilih. Tata letak salam mengikuti design.md, konten informasi memakai tipografi, warna, simbol, dan kontrol sistem yang sama.

## Feature design

### Keadaan dan kepemilikan

Root setiap WindowGroup adalah shell. WindowGroup memiliki id `foundation`; toolbar sidebar menyediakan tombol `Jendela Baru` melalui openWindow(id:). Info.plist hasil build wajib memiliki UIApplicationSupportsMultipleScenes true (sudah terlihat pada baseline hasil build). Tidak ada manager window khusus. Enum tujuan Swift memiliki raw string stabil `greeting` dan `foundation`. SceneStorage menyimpan raw tujuan serta panel `sidebar` atau `detail`. Binding pilihan List membaca tujuan valid sebagai optional. Setter nilai nonnil menyimpan tujuan dan memilih panel detail. Nilai nil dari List tidak menghapus tujuan terakhir. Binding preferredCompactColumn membaca panel tersimpan dan menulis perubahan sistem melalui kembali. Memilih lagi baris tujuan yang sama tetap membuka konten melalui NavigationLink native. Tujuan tetap terpilih saat panel sidebar aktif; aksi kembali hanya mengganti panel. Kedua key dinormalisasi secara mandiri ketika dibaca. Visibilitas sidebar regular adalah state lokal dengan default automatic atau all, boleh mengikuti keputusan sistem dan tidak dijanjikan pulih setelah scene dibuat ulang. Mode layout serta geometri adalah keluaran SwiftUI, tidak disimpan.

Nama `Ayu` dan hasil kosong dipindahkan ke state di root shell dan dibinding ke GreetingView, supaya keluar masuk tujuan tidak membuangnya. Tidak menyimpan nama atau hasil ke disk. Tidak menulis isi input ke log. SceneStorage tidak berbagi state antarscene dan tidak memakai UserDefaults global sebagai pengganti.

### Komposisi

Sidebar berjudul `Fondasi`, berisi Label native dengan simbol sistem `hand.wave` dan `info.circle`. Detail salam mempertahankan urutan dan kontrol yang sudah ada. Informasi memiliki judul `Informasi Fondasi`, teks `Satu inti Rust, dua antarmuka native.`, lalu label dan uraian `Perilaku bersama` / `Rust melalui UniFFI.`, `Tampilan iPad` / `SwiftUI mengatur navigasi dan jendela.`, dan `Batas fondasi` / `Tanpa modul bisnis, jaringan, atau basis data.`. Informasi memakai ScrollView, lebar isi maksimum 560 point dan padding 24 sesuai layar salam. Tidak ada versi alat yang disalin, token atau aset baru.

NavigationSplitView dua kolom memakai gaya balanced, lebar sidebar pilihan sekitar 240 sampai 320 point, lebar akhir tetap sistem. Lebar, tinggi, safe area, dan skala teks dipenuhi oleh layout native dan ScrollView; tidak mengunci orientasi atau ukuran minimum perangkat. Content title native memberi konteks tombol kembali. Tidak ada nested stack, inspector kosong, tombol kembali buatan, atau navigasi di Rust.

### Value sourcing

| Nilai | Sumber |
| --- | --- |
| Tujuan terpilih | SceneStorage scene ini, fallback greeting untuk nilai tak dikenal |
| Panel compact aktif | SceneStorage sidebar/detail melalui binding preferredCompactColumn, fallback detail |
| Visibilitas sidebar regular | State lokal NavigationSplitView dan toggle sistem |
| Mode dan ruang tersedia | Adaptasi NavigationSplitView dari window, safe area, size class sistem |
| Nama dan hasil | State root scene, nilai awal spec 0003; hasil hanya binding hello |
| Judul, simbol, informasi | Literal komposisi di atas, konten fondasi dari README |

### Critical test scenarios

AC-1: pilih informasi, kembali ke salam, hasil dan nama sama; panggilan salam berikutnya bekerja.
AC-2/4: target utama iPad Pro 11 inch runtime 27.0 yang tersedia, layar penuh, pilih informasi, rotasi dua arah, background lalu activate, pilihan tetap benar; expanded sidebar dan konten terlihat.
AC-3/4: ubah window nyata lebar ke sempit dan tinggi pendek, pilih informasi, kembali, pilih salam, lebarkan lagi; kontrol tetap dapat dipakai. Override size class atau unit test hanya bukti tambahan.
AC-5: pulihkan snapshot tujuan informasi di panel konten, ulang di panel daftar; kembali dan buka salam; buat scene kedua dan pastikan pilihan scene pertama tidak ikut berubah. Gunakan lifecycle sistem nyata: Home atau aplikasi sistem layar penuh untuk menyimpan snapshot, pastikan aplikasi benar benar background, hentikan proses dengan simctl terminate setelah background, lalu launch tanpa argumen reset. Catat apakah sistem memakai scene yang sama dan apa yang terlihat. Jangan menamai seed atau recreation SwiftUI view sebagai bukti process restore. Jika sistem tidak memulihkan snapshot, hasilnya FAIL untuk kontrak ini dan investigasi diperlukan. Tes salam dan tes navigasi yang memerlukan default menggunakan argumen DEBUG `--fresh-navigation` yang mereset hanya key navigasi saat shell baru tampil; tes pemulihan tidak mengirimnya.
Semua baris tujuan memakai identifier `navigation.greeting` dan `navigation.foundation`, tombol window memakai `navigation.newWindow`, konten informasi memakai `foundation.content`. Identifier membedakan judul dan baris.

AC-6: jalankan scripts/build-ipados.sh lalu scripts/test-ipados.sh pada simulator iPad, gerbang Rust/repo dan scripts/test.sh artifacts/ipados. Jalankan regresi pada runtime utama yang dapat diluncurkan. Runtime minimum yang terpasang dicoba terpisah; instalasi runtime saja bukan bukti bahwa simulator dapat menyelesaikan boot. Bila runtime tambahan tidak operasional, laporkan NOT_RUN tanpa menganggapnya lulus atau menyatakan kompatibilitas runtime itu terbukti; sumber pin tetap matriks dukungan.

## Build plan

- [x] Shell dan dua tujuan beserta binding scene, mempertahankan salam (AC-1, AC-2, AC-4, AC-5).
- [x] Build kedua konfigurasi dan coba navigasi serta lifecycle di simulator nyata, termasuk resize, dengan pengecualian verifikasi compact yang diminta pengguna (AC-1 sampai AC-6).
- [x] Tes regresi navigasi, pemulihan layar penuh, isolasi scene dan salam; bukti target serta catatan cara menjalankan, compact tetap ditunda (AC-1 sampai AC-6).

## Consequences

SwiftUI menentukan kapan sidebar menjadi stack. Snapshot scene mengikuti lifecycle sistem, bukan penyimpanan bisnis yang dijamin setiap saat. Nama dan hasil tidak dipersistenkan. Dua kolom cukup untuk isi fondasi saat ini. Multiwindow hanya mendemonstrasikan state scene lokal, tanpa bisnis independen atau seret antarjendela.

## Follow-up

Fitur 06 menangani Android, 07 input dan aksesibilitas lanjutan, 08 token. Hosted CI scope 04 telah ditutup oleh pekerjaan terpisah dan tidak diubah oleh fitur ini. Tidak perlu mengubah spec Accepted sebelumnya.

## Rationale

Dua tujuan fondasi memberi alur nyata terkecil untuk menguji sidebar, kembali, resize, dan pemulihan. Keadaan native tetap dimiliki SwiftUI. Penyimpanan scene menghindari satu pilihan global yang bocor ke window lain. Pilihan diterima secara teknis melalui kebijakan auto, bukan jawaban pengguna yang dibuat buat.

## References

- [NavigationSplitView, Apple](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [NavigationSplitViewColumn, Apple](https://developer.apple.com/documentation/swiftui/navigationsplitviewcolumn)
- [Restoring your app state, Apple](https://developer.apple.com/documentation/SwiftUI/restoring-your-app-s-state-with-swiftui)
- Scope 05, README bagian 7, 8 dan 25, design.md, matriks pemilik.

## Checkpoint penutupan

Scope 05 selesai atas instruksi pengguna, dengan verifikasi compact ditunda. Empat regresi UI selain compact lulus pada source akhir, termasuk pemulihan tujuan setelah proses dimulai kembali dalam scene layar penuh. Build Debug dan Release unsigned, Rust, repo, serta artefak bersih lulus. Tes compact tetap tersedia, bukti yang belum diperoleh tetap NOT_RUN. Acceptance ini tidak menyatakan bahwa crash compositor simulator telah diperbaiki atau bahwa pemulihan compact telah terverifikasi. Laporan docs/reviews/2026-11-17-verify-f05.md menyimpan bukti dan pengecualian penutupan.
