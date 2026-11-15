# Langkah manual: `<nama-SCOPE>`

Catat pemeriksaan yang memerlukan akses atau perangkat tambahan beserta kode yang diuji, target dan hasil pengamatan. Setelah bukti diterima, checker memvalidasi setiap AC pada target yang sama. Kriteria wajib tetap terbuka sampai hasilnya `PASS`.

Keputusan yang diambil atas namamu ada di `<nama-SCOPE>.log.md` bagian "Keputusan delegasi"; baris bertanda `berat` paling perlu kamu baca. Untuk membatalkan satu baris, sebut barisnya ke lead.

Untuk lead: ID langkah `F<fitur>-<n>` tetap seumur file dan tidak dinomori ulang; langkah baru mendapat nomor berikutnya. Hapus paragraf ini di file hasil.

## Ringkasan

| ID | Langkah | AC dan kotak yang menunggu | Commit | Target dan OS | Hasil | Bukti |
| --- | --- | --- | --- | --- | --- | --- |
| `F<fitur>-<n>` | `<judul>` | `<AC dan kotak>` | `<SHA>` | `<target, versi OS>` | `NOT_RUN` / `BLOCKED` / `PASS` / `FAIL` | `<hasil aktual dan lokasi bukti>` |

## Nilai dari user

Nilai yang hanya kamu tahu. AC di kolom ketiga `BLOCKED` sampai nilainya ada.

| ID | Nilai yang dibutuhkan | AC yang menunggu | File yang menunggu |
| --- | --- | --- | --- |
| `N<n>` | `<mis. alamat email untuk laporan Code of Conduct>` | `spec <NNNN> AC-<n>` | `<path>` |

## Fitur `<nomor>`: `<nama>` (spec `<NNNN>`)

### `F<fitur>-<n>` · `<judul>`

Dari laporan `<nama sub sesi>` (`<YYYY-MM-DD>`). Membuktikan AC fitur atau spec yang tercantum di brief.

- **Prasyarat:** `<perangkat atau simulator, versi OS, izin atau akses yang dibutuhkan>`.
- **Jalankan:** `<perintah persis, satu per baris, atau urutan klik di app>`
- **Lulus bila:** `<hasil yang diharapkan, dengan teks atau angka yang bisa dicocokkan>`
- **Hanya langkah ini yang bisa membuktikan:** `<apa yang tidak tercakup test fixture>`
