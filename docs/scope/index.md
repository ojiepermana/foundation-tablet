# Indeks scope fondasi tablet native

Repo ini ditujukan untuk tim yang akan membangun aplikasi produktivitas di iPad dan tablet Android. Tim dapat menambah perilaku bersama di Rust sekali saja. Setiap aplikasi mengatur tampilan, navigasi, input, dan jendelanya sendiri.

**Build approach:** Tracer Bullet. Bukti pertama adalah satu nama yang dikirim dari masing masing aplikasi ke Rust dan satu salam yang kembali ke layar. Tahap berikutnya memperluas alur yang sama.

**Workflow:** Beta. Setelah `/develop`, urutan yang disarankan adalah `/check verify` untuk mencoba perilaku nyata, lalu `/test` untuk menguji agar perilaku itu tetap bekerja.

Saat scope ini dibuat, repo hanya berisi [README produk](../../README.md). Nomor **AC** di setiap file fitur menunjuk ke 34 kriteria penerimaan pada bagian 25 README. Nomor itu menunjukkan tempat pembuktiannya, bukan hasil pengujian.

## Urutan pengerjaan

Pilih nama fitur untuk melihat tujuan, kriteria selesai, dan langkah pertamanya. Nomor file mengikuti urutan pengerjaan.

| No. | Fitur | Fase | Status |
|---|---------|-------|--------|
| 01 | [Arsitektur dan build awal](01-arsitektur-dan-build-awal.md) | Fondasi | done |
| 02 | [Aturan kontribusi](02-aturan-kontribusi.md) | Fondasi | done |
| 03 | [Kontrak Rust untuk kedua aplikasi](03-kontrak-rust-untuk-kedua-aplikasi.md) | Fondasi | done |
| 04 | [Salam Rust pada dua tablet](04-salam-rust-pada-dua-tablet.md) | Alur pertama | planned |
| 05 | [Navigasi dan jendela iPad](05-navigasi-dan-jendela-ipad.md) | Ruang kerja tablet | planned |
| 06 | [Navigasi dan jendela Android](06-navigasi-dan-jendela-android.md) | Ruang kerja tablet | planned |
| 07 | [Input dan aksesibilitas](07-input-dan-aksesibilitas.md) | Ruang kerja tablet | planned |
| 08 | [Tema dari token bersama](08-tema-dari-token-bersama.md) | Identitas bersama | planned |
| 09 | [Teks dan sumber daya bersama](09-teks-dan-sumber-daya-bersama.md) | Identitas bersama | planned |
| 10 | [Pemeriksaan batas arsitektur](10-pemeriksaan-batas-arsitektur.md) | Penerimaan | planned |
| 11 | [Build dan pengujian otomatis](11-build-dan-pengujian-otomatis.md) | Penerimaan | planned |
| 12 | [Bukti penerimaan fondasi](12-bukti-penerimaan-fondasi.md) | Penerimaan | planned |

## Ditunda

Empat kelompok berikut memerlukan kebutuhan dan rencana tersendiri. Tidak ada layanan, dependensi, atau direktori kosong yang perlu disiapkan untuknya.

* **Modul bisnis dan identitas:** autentikasi, peran, pelanggan, ERP, dan metrik bisnis.
* **Layanan data:** klien jaringan, basis data, sinkronisasi, unggahan latar, dan konfigurasi jarak jauh.
* **Ruang kerja lanjutan:** penyuntingan dokumen, pemrosesan gambar, gambar dengan stylus, seret antarjendela, jendela bisnis independen, dan layar eksternal.
* **Perluasan produk dan distribusi:** varian ponsel atau desktop, pustaka komponen besar, serta publikasi ke toko aplikasi.

## Cara memakai scope

Untuk melihat antrean dari root repo, jalankan `python3 .claude/skills/coordinate/scripts/scope.py`. Tambahkan `04` atau `F04` untuk mendapatkan path fitur salam. Urutan pada tabel di atas menjadi acuan bagi [alat koordinasi](../../.claude/skills/coordinate/SKILL.md).

Kotak kosong pertama menunjukkan langkah yang disarankan. Tanda `needs a decision` berarti ada keputusan yang layak dicatat sebelum implementasi. Setelah spesifikasi tersedia, bagian fitur dapat memuat tautan spesifikasi, tonggak build, pemeriksaan, dan tes. Pekerjaan rinci tetap berada di spesifikasi.

Status `planned` berarti direncanakan, `in-progress` berarti sedang dirancang atau dibangun, dan `done` berarti pekerjaan telah diselesaikan dengan bukti. Status `existing` menandai pekerjaan yang sudah ada sebelum alur ini, sedangkan `dropped` menyimpan riwayat pekerjaan yang dikeluarkan. Anda dapat menjalankan `/scope` lagi untuk menyelaraskan rencana dengan keadaan repo.

Saat setiap fitur diuji, simpan satu hasil per kriteria dan target memakai [contoh bukti di fitur 02](02-aturan-kontribusi.md). Jika pemeriksaan wajib gagal atau belum dijalankan, kotaknya tetap terbuka dan fitur tetap `in-progress`. Sertakan alasan dan langkah berikutnya agar sesi lain dapat melanjutkan. Fitur 12 merujuk bukti yang dikumpulkan sejak awal.

[Laporan audit kesiapan scaffold](../quality/audit-scaffold.md) mencatat alasan di balik tambahan kriteria build, pemulihan navigasi, dan pengujian pada kedua platform.
