# 4. Salam Rust pada dua tablet · planned

Dari satu layar SwiftUI dan satu layar Compose, Anda dapat memasukkan nama dan membaca hasil yang dikembalikan oleh implementasi Rust yang sama.

Lengkapi panduan mulai singkat dengan versi alat, perintah untuk membangun dan menjalankan tiap aplikasi, serta cara mencoba salam. Workflow pull request pertama memakai [aturan CI dan format bukti per target](02-aturan-kontribusi.md).

**Done when:** dari clone bersih pada runner CI baru, perintah repo yang sama dengan panduan lokal menghasilkan binding, membangun, lalu meluncurkan aplikasi pada simulator iPad dan emulator tablet Android. Pada kedua layar, mengganti nama dari `Ayu` menjadi `Bima` lalu memicu aksi mengubah hasil dari `Hello, Ayu!` menjadi `Hello, Bima!` melalui satu implementasi Rust. Hasil dari commit yang diuji tercatat tersendiri untuk tiap platform. AC 5, 6, 7, 8, 9, 10.

* [ ] Bangun alur pada kedua tablet: `/develop salam Rust pada dua tablet`

[Kembali ke indeks scope](index.md)
