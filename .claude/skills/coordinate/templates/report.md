# Laporan sub sesi

Kirim ke lead lewat `SendMessage` saat selesai, terblokir, gagal, atau butuh keputusan, lalu akhiri giliran dengan recap yang baris pertamanya sama dengan baris STATUS di bawah. Semua field wajib; tulis `tidak ada` bila kosong.

- **STATUS:** `done` | `blocked` | `failed` | `needs-decision` (`standby` hanya sebagai recap giliran pertama, tanpa laporan)
- **Sub sesi:** `<nama>` (`<peran>`)
- **Fitur / milestone / AC:** `<nomor>. <nama>` / `<teks kotak>` / `<AC-n, ...>`
- **Branch dan commit terakhir:** `claude/<name>-<hash>` · `<hash pendek>` · working tree `bersih` | `kotor`
- **File diubah:** `<path, satu per baris; harus subset dari "File yang BOLEH diubah" di brief>`
- **Pointer code in** (developer): `<folder atau file rumah kode milestone ini, untuk baris Pointer scope>`
- **Langkah Build plan selesai** (developer): `<nomor langkah, misalnya 13, 14, 15>`
- **Perintah uji** (developer): `<perintah test dan langkah verify milestone ini, satu per baris>`
- **Model:** `<model · effort sesi ini, dari get_session "self">`; bila beda dari "Model sesi" di brief, sebut di Blocker

**Perintah dijalankan dan hasil:**

| AC | Commit yang diuji | Target dan versi OS | Jenis pemeriksaan | Perintah atau langkah manual | Hasil aktual dan status | Lokasi log atau bukti |
| --- | --- | --- | --- | --- | --- | --- |
| `<ID>` | `<SHA>` | `<target, OS>` | `konfigurasi / build / simulator / emulator / perangkat fisik` | `<langkah persis>` | `<pengamatan, PASS / FAIL / NOT_RUN / BLOCKED>` | `<path atau tautan>` |

- **Bukti:** satu baris per AC dan target termasuk OS. Untuk `FAIL`, `NOT_RUN` atau `BLOCKED`, tulis alasan, penanggung jawab dan langkah berikut. Target wajib yang belum lulus tetap terbuka.
- **Keputusan diambil** (architect): satu baris per keputusan: `<pertanyaan>` · diambil `<opsi>` · runner-up `<opsi>` · `biasa` | `berat` · `<AC atau langkah Build plan yang berubah bila runner-up yang dipilih>`
- **Tafsiran AC** (developer, checker, tester): `<AC-n: tafsiran yang diambil dan alasannya dari teks AC atau rationale.md>`
- **Langkah manual:** `<teks lengkap tiap langkah untuk file manual: prasyarat, perintah persis, hasil yang diharapkan, AC yang dibuktikan; nilai yang hanya user tahu di bawah "Nilai dari user">`
- **Blocker atau pertanyaan:** `<apa yang menahan, siapa yang bisa membuka, atau keputusan yang modenya memberi ke user: tiap pertanyaan dengan dua sampai empat opsi, rekomendasi pertama, akibat tiap opsi satu kalimat>`
- **Pesan antarsesi:** `<ringkasan satu kalimat per pertukaran, dengan nama sub sesi>`
- **Rekomendasi langkah berikutnya:** `<kotak yang siap dicentang, item yang terbuka karena ini, atau fix yang diminta>`
- **Blok scope usulan** (hanya architect): `<baris Pointer, Design it dicentang, Build it dengan 2 sampai 5 milestone bersarang beserta AC dan prasyaratnya, kotak penutup sesuai tier; gunakan H1 dan nomor file fitur dari brief>`
