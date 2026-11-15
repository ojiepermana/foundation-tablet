# 3. Kontrak Rust untuk kedua aplikasi · planned · needs a decision

Batasi model data awal pada satu nama masuk dan satu teks salam keluar. Rust memiliki perilakunya, UniFFI menyediakan antarmuka publik, dan aplikasi memiliki keadaan tampilan.

**Done when:** inti bebas dari dependensi UI. Binding Swift dan Kotlin untuk `hello(name: String) -> String` dapat dihasilkan ulang tanpa suntingan manual dari revisi sumber yang sama dengan pustaka Rust yang akan ditautkan untuk tiap target dalam [matriks dukungan](01-arsitektur-dan-build-awal.md). Konvensi menjelaskan kompatibilitas, kepemilikan nilai, galat, dan perluasan kontrak tanpa mengekspos tipe privat atau membuat entitas bisnis. AC 3, 4, 25.

* [ ] Rancang batas kontrak (spec): `/architect kontrak Rust untuk kedua aplikasi`

[Kembali ke indeks scope](index.md)
