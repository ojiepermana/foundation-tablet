# 5. Navigasi dan jendela iPad · done

Gunakan sidebar dan area konten native untuk berpindah antara salam dan informasi fondasi. Lebar dan tinggi jendela yang tersedia menentukan panel yang terlihat; panel detail hanya muncul bila ada isi dan ruang.

**Done when:** di iPad, Anda dapat memilih tujuan dan kembali dalam satu panel saat sempit, lalu memakai sidebar dan konten saat ruang cukup. Pilihan tetap benar setelah rotasi, perubahan ukuran, multitasking, dan kembali ke aplikasi. Kebijakan pemulihan menyebut keadaan navigasi milik tiap scene. Setelah scene dibuat kembali, uji menunjukkan tujuan, panel aktif, dan aksi kembali sesuai kebijakan tersebut. AC 11 sampai 16 untuk iPadOS.

**Spec:** [0004, navigasi dan jendela iPad](../specs/0004-navigasi-jendela-ipad.md).

* [x] Rancang navigasi iPad (spec): `/architect navigasi dan jendela iPad`
* [x] Bangun shell native: `/develop navigasi dan jendela iPad`
  * [x] Sidebar, salam, dan informasi fondasi.
  * [x] Keadaan per scene, adaptasi, dan pemulihan navigasi (verifikasi compact ditunda).
* [x] Verifikasi perilaku nyata selain compact: `/check verify navigasi dan jendela iPad`
* [x] Tes regresi selain compact: `/test navigasi dan jendela iPad`

Kode berada di [TabletApp.swift](../../apps/ipados/Tablet/App/TabletApp.swift), tes di [GreetingUITests.swift](../../apps/ipados/TabletUITests/GreetingUITests.swift), dan kebijakan pemulihan di [panduan navigasi](../tablet/navigation-ipados.md).

**Langkah terakhir terverifikasi (2026-11-17):** shell dan dua tujuan terintegrasi. Build Debug dan Release unsigned, gerbang Rust/repo, serta artefak pada snapshot bersih lulus. Navigasi, rotasi, window half dan quarter, kembali native, pelebaran kembali, serta isolasi dua scene dibuktikan di simulator. Pemulihan tujuan pada layar penuh lulus. Bukti rinci ada di [laporan scope 05](../reviews/2026-11-17-verify-f05.md).

**Penutupan (2026-11-17):** pengguna memperjelas, “Maksud saya skip verifikasi compact dulu, lanjutkan dan selesaikan scope 5.” Scope ditutup sebagai done dengan pengecualian ini. Empat tes UI selain compact terbukti lulus pada revisi source yang sama (tiga pada run penutupan, keyboard pada retry tersendiri); gerbang Rust/repo dan build iPad lulus. Spec 0004 Accepted.

**Verifikasi compact yang ditunda:** pemulihan visual kedua panel setelah scene dibuat ulang tetap NOT_RUN, bukan PASS. Compositor sistem backboardd pada Pro dan mini iPadOS 27.0 berhenti dengan Metal invalid pixelFormat (0). Runtime 26.5 tertahan saat boot, runtime 27.1 terpasang menolak iPad, perangkat fisik tidak tersedia. Tidak ada workaround percobaan yang ditinggalkan di source. Tes `testCompactBackAndBothRestoredPanels` tetap tersedia untuk target yang operasional, tanpa menahan penutupan yang diminta pengguna.

**Langkah berikutnya:** fitur [06, navigasi dan jendela Android](06-navigasi-dan-jendela-android.md). Bukti compact yang ditunda tetap dicatat untuk penerimaan fondasi, tidak diklaim telah lulus.

Koordinasi dan checkpoint: [state](coordination/05-navigasi-dan-jendela-ipad/state.json). Kebijakan keputusan auto bawaan agent-flow; penundaan ini berasal dari jawaban pengguna.

[Kembali ke indeks scope](index.md)
