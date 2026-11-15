# Audit kesiapan scaffold tablet

15 November 2026 · `main` pada commit `6f0a7ef`

Keputusan pertama yang saya sarankan adalah menjadikan **clone bersih yang bisa menjalankan salam Rust di kedua tablet** sebagai hasil fitur 04. Ini memberi tim cara tercepat untuk menemukan dependensi lokal, binding lama, atau kesalahan pengemasan sebelum fitur tablet bertambah.

## Yang dapat dibuktikan saat ini

Commit yang diperiksa berisi 15 file Markdown. Semua tautan lokal dari panduan agen, indeks, dan file fitur memiliki tujuan yang valid. Nomor dan status 12 fitur cocok dengan indeks, dan seluruh 34 kriteria penerimaan README memiliki tempat pembuktian. Seluruh fitur berstatus `planned`. Belum ada proyek native, manifest Rust, atau workflow CI pada commit ini. Build dan perilaku aplikasi belum bisa diuji. [Indeks](../scope/index.md) · [Kriteria produk](../../README.md#25-foundation-acceptance-criteria)

## Sebelum menjalankan koordinasi otomatis

Ada temuan khusus pada salinan kerja lokal. Penghitung di `.claude/skills/coordinate/SKILL.md` baris 43 mencari kotak `- [ ]`. Dua belas file fitur memakai `* [ ]`. Saat kedua pola diperiksa, pola milik alat menemukan **0** langkah terbuka dan pola yang menerima keduanya menemukan **12**. Pemilihan fitur melalui bentuk `F04` juga mencari judul tingkat tiga, sedangkan setiap file fitur memakai judul tingkat satu. Folder alat tersebut belum tercatat di Git pada saat audit.

Jika alat itu akan dipakai bersama, sesuaikan pembacanya dengan format scope dan uji dua contoh: daftar awal menampilkan 12 langkah dan pilihan `04` serta `F04` membuka fitur salam yang sama. Periksa juga aturan untuk uji manual pada baris 120 dan 124. Alat mengizinkan fitur ditutup ketika uji manual masih berstatus `NOT_RUN`. Untuk kriteria wajib, simpan hasil itu sebagai **belum terverifikasi** sampai ada bukti. [Contoh file fitur](../scope/04-salam-rust-pada-dua-tablet.md) · [Aturan bukti dalam README](../../README.md#25-foundation-acceptance-criteria)

## Tambahan yang disarankan pada fitur yang sudah ada

| Prioritas | Fitur | Celah dan usulan bukti selesai |
|---|---|---|
| Pertama | [01](../scope/01-arsitektur-dan-build-awal.md), [04](../scope/04-salam-rust-pada-dua-tablet.md), [11](../scope/11-build-dan-pengujian-otomatis.md) | Build dari salinan bersih dan alur salam sudah diminta, tetapi baru dipertemukan di CI pada fitur 11. Sejak fitur 04, sediakan petunjuk mulai singkat dengan versi alat, perintah build per platform, dan cara menjalankan salam. Buktikan runner baru bisa menghasilkan binding, membuka masing masing aplikasi, dan membaca salam sesuai nama yang dimasukkan. Gunakan perintah repo yang sama agar kontributor dapat mengulang kegagalan secara lokal. |
| Pertama | [01](../scope/01-arsitektur-dan-build-awal.md), [03](../scope/03-kontrak-rust-untuk-kedua-aplikasi.md), [11](../scope/11-build-dan-pengujian-otomatis.md) | Tetapkan OS minimum yang didukung, target simulator dan perangkat, serta arsitektur biner Android. Buat build Release yang benar benar menautkan pustaka Rust untuk iPad fisik, di samping uji simulator. Pada Android, periksa pustaka di APK akhir untuk arsitektur yang dijanjikan. Jika mendukung perangkat dengan halaman memori 16 KB, periksa alignment dan jalankan salam di emulator dengan ukuran halaman terverifikasi. Catat tersendiri hasil pada perangkat fisik. [Panduan Apple](https://developer.apple.com/documentation/technotes/tn3117-resolving-build-errors-for-apple-silicon) · [Panduan Android](https://developer.android.com/guide/practices/page-sizes) |
| Pertama | [02](../scope/02-aturan-kontribusi.md), [04](../scope/04-salam-rust-pada-dua-tablet.md), [12](../scope/12-bukti-penerimaan-fondasi.md) | Panduan agen mencatat langkah terakhir dan berikutnya. Tambahkan satu contoh bukti yang bisa diulang oleh sesi lain: kriteria, commit yang diuji, target dan versi OS, perintah atau langkah manual, hasil aktual, serta lokasi log. Simpan sewaktu fitur dikerjakan. Bila iPad lulus dan Android belum diuji, tampilkan kedua hasil itu pada baris terpisah. Laporan akhir cukup merujuk bukti tersebut. [Panduan agen](../../AGENTS.md) |
| Saat navigasi dibuat | [05](../scope/05-navigasi-dan-jendela-ipad.md), [06](../scope/06-navigasi-dan-jendela-android.md) | Fitur Android sudah mencakup pembuatan ulang Activity, sedangkan README juga meminta pemulihan setelah proses dihentikan sistem. Pilih tujuan, pindah ke latar, simulasikan penghentian proses oleh sistem, lalu buka kembali dari daftar aplikasi terakhir. Periksa tujuan, panel aktif, dan aksi kembali. Di iPad, tetapkan keadaan milik scene yang perlu dipulihkan dan uji saat scene tersebut dibuat kembali. [Kebutuhan jendela](../../README.md#9-tablet-window-management-and-multitasking) · [Panduan pemulihan Android](https://developer.android.com/topic/libraries/architecture/saving-states) |
| Saat tema dan teks digabung | [07](../scope/07-input-dan-aksesibilitas.md), [08](../scope/08-tema-dari-token-bersama.md), [09](../scope/09-teks-dan-sumber-daya-bersama.md) | Pemeriksaan aksesibilitas dijadwalkan sebelum perubahan tema dan terjemahan. Ulangi alur salam setelah keduanya masuk, memakai jendela sempit, ukuran teks besar, label yang panjang, dan tema gelap. Pastikan tombol tetap terjangkau, fokus mengikuti urutan tindakan, dan hasil baru dapat dibaca dengan VoiceOver dan TalkBack. |
| Saat CI pertama dibuat | [02](../scope/02-aturan-kontribusi.md), [11](../scope/11-build-dan-pengujian-otomatis.md) | Aturan rahasia sudah direncanakan. Tambahkan pengaturan konkret pada workflow pemeriksaan pull request: izin minimum untuk token, build yang dapat berjalan tanpa kredensial penandatanganan produksi, dan revisi action eksternal yang terkunci. Buktikan satu pull request bisa menjalankan kedua build dengan pengaturan itu. [Panduan GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use) |

Untuk urutan pengerjaan, tiga tambahan pertama bisa masuk ketika fitur 01 sampai 04 dirancang. Pemeriksaan pemulihan, aksesibilitas, dan izin CI bisa mengikuti fitur pemiliknya. Seluruh usulan di atas mempertahankan lingkup produk awal berupa satu alur Rust dan dua aplikasi tablet native.

## Tindak lanjut audit

Seluruh usulan pada tabel telah masuk ke kriteria fitur yang ditautkan. Build pertama dari clone bersih dan bukti terpisah per platform kini menjadi bagian dari fitur 04. Pelaksanaan dan pengujian aplikasi tetap dijadwalkan dalam [indeks scope](../scope/index.md).

[Pembaca scope](../../.claude/skills/coordinate/scripts/scope.py) memakai urutan indeks. Saat dijalankan terhadap repo ini, hasilnya 12 fitur dengan 12 langkah terbuka. Untuk setiap fitur, nomor dua digit dan awalan `F` mengembalikan file yang sama, termasuk `04` dan `F04`. Pilihan ambigu atau nomor yang tidak ditemukan menghasilkan pesan kesalahan.

[Aturan koordinasi](../../.claude/skills/coordinate/SKILL.md) kini mempertahankan kotak verifikasi wajib yang belum lulus sebagai pekerjaan terbuka. Pengujian perubahan ini mencakup pembaca scope. Orkestrasi sesi di Claude Desktop dan pengujian aplikasi native belum dijalankan.
