# Brief sub sesi

Lead mengisi semua field dan mengirimnya sebagai `prompt` saat memulai sub sesi, atau lewat `SendMessage` untuk sesi yang dipakai ulang. Teks di dalam `<...>` diganti. Brief hanya memuat yang khusus item ini; aturan yang sama untuk semua item scope ini ada di file "Aturan umum", dan brief memperinci tugas dalam batas kriteria fitur. Sub sesi membaca brief ini, file aturan umum, lalu `.claude/skills/coordinate/roles/<peran>.md` (bila file itu tidak ada di worktree kamu, baca dari checkout utama yang disebut file aturan umum), lalu memanggil skill yang disebut di sana, baru mulai bekerja.

- **Nama sub sesi:** `<peran singkat>-f<fitur>-<item>` (pola di SKILL.md langkah 3) · **Judul:** `<name> · <fitur dan item>`
- **Wave:** `<n>`
- **Peran:** `architect` | `architect (update)` | `developer` | `checker (verify)` | `checker (review)` | `tester` | `debugger`
- **Aturan umum:** `<path absolut checkout utama>/docs/scope/coordination/<nama-SCOPE>.brief-umum.md`
- **Mode keputusan:** `auto` | `tanya berat` | `tanya` (dipakai role architect; peran lain mencatat tafsiran AC di laporan)
- **Model sesi:** `<model · effort dari tabel SKILL.md langkah 3>` · **Giliran pertama:** `langsung` | `standby` (hanya baca brief, aturan umum, dan role, lalu akhiri giliran dengan `STATUS: standby` tanpa mengirim pesan; mulai bekerja saat lead mengirim "mulai")
- **Sesi dipakai ulang:** `ya` | `tidak`; bila `ya`, konteks sudah dibersihkan lead, worktree dan branch lanjut dari item sebelumnya: jalankan `git merge main` dulu, lalu kerjakan item ini seperti brief baru
- **Lokasi sumber:** `<file repo, keputusan, tautan spec dan hasil graph bila tersedia>`.
- **Fitur:** `<nomor>. <nama>` di `docs/scope/<file>.md` (file scope selalu disebut, karena item bisa berasal dari file scope lain)
- **Milestone:** `<teks kotak persis seperti di SCOPE>` · **Langkah Build plan:** `<a> sampai <b>` atau `semua`
- **ID AC:** `<AC spec bila ada dan AC README pada Done when, target serta versi OS yang dicakup>`.
- **Path spec:** `<spec yang ditautkan, atau file fitur dan Done when untuk entri langsung>`. Untuk architect tulis lokasi spec yang disepakati.
- **Spec target dan Follow-up sumber** (hanya `architect (update)`): `docs/specs/<NNNN-slug>/` dan baris Follow-up yang diterapkan, atau baris "Keputusan delegasi" yang dibatalkan beserta opsi yang user pilih
- **Follow-up dari spec lain:** `<path spec: baris Follow-up yang menyebut fitur ini, atau "tidak ada">`
- **File yang BOLEH diubah:** `<path atau folder, satu per baris>`
- **File yang DILARANG:** aturan Ownership di brief umum, ditambah `<path atau folder milik sub sesi lain>`
- **Skill dan argumen:** perintah pada kotak fitur, misalnya `/audit`, `/develop salam Rust pada dua tablet`, atau `/check verify salam Rust pada dua tablet`.
- **Range perubahan:** `<hash sebelum merge pertama>..<hash merge terakhir>` (`git log --oneline <range>`, `git diff --name-only <range>`); checker review memakainya sebagai cakupan diff, tester sebagai daftar file yang diuji; verify milestone dari `source_branch` tidak memerlukannya
- **Langkah verify.md yang sudah [x]** (checker): `<nomor atau kutipan, atau "tidak ada">`; jalankan sisanya plus langkah yang AC-nya disentuh Range perubahan
- **Laporan gagal** (debugger): `<laporan lengkap sub sesi yang gagal, apa adanya, termasuk perintah dan output>`
- **Sub sesi terkait:** `<name>` · judul `<title persis>` → `<peran>` → `<untuk apa menghubunginya>`; di `ListAgents` cari baris yang judulnya diawali `<name>` dan kirim ke alamat persis seperti baris itu tercetak (judul plus `[ref]`); bila tidak ada baris yang cocok, kirim ke lead
- **Prasyarat yang sudah selesai:** `<kotak atau milestone [x] yang item ini andalkan, nomor langkah Build plan yang sudah di-merge ke main, dan di mana hasilnya>`
- **Langkah manual item ini:** `<AC dan target yang memerlukan akses khusus, bila ada>`. Catat apa yang dapat dijalankan dan apa yang menunggu beserta alasannya.
- **Jawaban panel khusus item ini:** `<jawaban yang berbeda dari "Panel skill" di aturan umum, atau "tidak ada">`
- **Model penulis kode** dan **Model reviewer:** `<family>` (hanya `checker (review)`; penulis dari kolom Model log dan trailer commit di Range perubahan)
