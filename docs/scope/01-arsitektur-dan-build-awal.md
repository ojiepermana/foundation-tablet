# 1. Arsitektur dan build awal · planned · needs a decision

Tetapkan batas antara inti Rust, lapisan ekspor UniFFI, dua aplikasi native, serta sumber desain dan penunjangnya. Keputusan yang masih terbuka adalah versi stabil yang kompatibel, target build, dan cara mengemas pustaka untuk tiap platform.

Dokumentasikan versi alat, OS minimum iPadOS dan Android, target simulator dan perangkat iPad, serta arsitektur biner (ABI) emulator dan tablet Android. Matriks dukungan menyebut alasan tiap target dan apakah perangkat Android dengan halaman memori 16 KB termasuk di dalamnya.

**Done when:** kontributor dapat mengompilasi workspace Rust dan kedua proyek native minimal dari clone bersih dengan perintah repo pada panduan mulai singkat. Versi yang dipilih cocok dengan dokumentasi resmi. Catatan arsitektur memuat matriks dukungan, pemilik tiap bagian, arah dependensi, dan alasan penyimpangan dari struktur README bila ada. AC 1, 2.

* [ ] Putuskan arsitektur awal (spec): `/architect arsitektur dan build awal`

[Kembali ke indeks scope](index.md)
