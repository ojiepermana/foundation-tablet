# Arah tampilan fitur salam

Sumber: keputusan spec 0003. Ini demonstrasi fondasi native, dengan tipografi dan warna sistem, tanpa aset atau identitas merek tambahan. SwiftUI memakai semantic styles bawaan; Android memakai MaterialTheme. Dukungan token bersama tetap fitur 08.

Urutan layar: judul `Salam Rust`, petunjuk singkat dari spec, kolom dengan label tetap `Nama`, tombol utama `Sapa`, lalu hasil terakhir dari Rust. Hasil awal kosong, petunjuk tetap menerangkan aksi yang tersedia. Konten satu kolom dapat digulir, memakai inset sistem, dan lebar dibatasi sesuai spec agar terbaca pada tablet. Tetap gunakan tinggi kontrol dan jarak native yang nyaman untuk sentuhan, keyboard dan pembaca layar.

Keadaan tampilan berasal dari spec 0003. Tidak ada loading karena kontrak sinkron cepat. Hasil tidak dirakit atau divalidasi dalam UI. Warna, bentuk kontrol, ukuran teks, dan perilaku fokus mengikuti platform. Tema gelap mengikuti sistem. Tidak ada navigasi, gambar, font luar, token kanonis baru, atau animasi khusus dalam fitur ini.
