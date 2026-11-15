---
name: coordinate
description: Menyelesaikan satu scope dengan sub sesi paralel (architect, developer, checker, tester, debugger); sesi ini lead, dan keputusan diambil dari opsi rekomendasi kecuali argumen memuat `tanya`.
argument-hint: "<nomor atau judul scope | path | F<fitur>> [tanya | tanya berat] [ketentuan tambahan]"
disable-model-invocation: true
---

# /coordinate

Sesi ini adalah **lead**. Setiap pekerjaan dari alur berjalan di **sub sesi** aplikasi (linked session) dengan worktree dan branch sendiri; lead tetap di checkout utama (`main`), memilih SCOPE, membagi item, menjaga gerbang centang, merge branch yang hijau, dan menulis log. Lead tidak menulis kode produksi: file yang lead edit hanya file scope (SCOPE, file scope lain yang item prasyaratnya ditarik, dan `docs/scope/index.md`), log koordinasi, `CHANGELOG.md`, dan hasil `/document` serta `/sync`.

Sub sesi paralel memerlukan `mcp__ccd_session__start_session` di aplikasi Claude. Untuk membaca inventaris atau mencari fitur dari checkout, cukup jalankan pembaca Python di bagian Konteks saat ini.

## Pemakaian

```text
/coordinate <scope> [tanya | tanya berat] [ketentuan tambahan]
```

- Satu file bernomor adalah satu fitur. Contoh pemilih: `04`, `F04`, `fitur 4`, `Salam Rust pada dua tablet`, atau path fitur yang ditautkan indeks. Argumen kosong menampilkan usulan untuk dikonfirmasi.
- `tanya` atau `tanya berat`: memilih Mode keputusan (bagian "Mode keputusan"). Tanpa kata itu modenya `auto`.
- Ketentuan tambahan: teks bebas sesudahnya, yang menimpa bawaan di bawah untuk run ini saja (misalnya model lain untuk satu peran). Lead menyalinnya apa adanya ke baris pertama log Keputusan dan ke file aturan umum brief.

Bawaan setiap run, tanpa perlu disebut user:

- Sub sesi paralel untuk setiap item yang ownership-nya tidak beririsan, dengan model per peran yang dipilih untuk langkah 3.
- Rencana wave ditampilkan lalu langsung dijalankan.
- Debugger dimulai begitu gerbang merah karena test atau langkah verify.
- Keputusan mengikuti Mode keputusan, bawaannya `auto`: opsi rekomendasi diambil dan dicatat.
- Catat pemeriksaan yang memerlukan seseorang atau perangkat tambahan di file manual. Kotak dengan kriteria wajib yang belum terbukti tetap terbuka.
- Fitur menjadi `done` setelah **Done when**, semua kriteria wajib, dan pemeriksaan tier terpenuhi pada setiap target yang dijanjikan.

Jika semua pekerjaan yang dapat dilakukan telah selesai dan bukti wajib masih tertunda, laporkan koordinasi terblokir, simpan langkah lanjut, dan pertahankan status fitur `in-progress` bila pekerjaan sudah dimulai.

## Konteks saat ini

Argumen: `$ARGUMENTS`

Inventaris mengikuti tautan pada tabel “Urutan pengerjaan” di `docs/scope/index.md`. Angka pada tiap file menghitung langkah terbuka termasuk milestone. Judul dan status harus cocok antara heading fitur dan indeks.

!`cd "${CLAUDE_PROJECT_DIR:-.}" && python3 .claude/skills/coordinate/scripts/scope.py`

Log koordinasi yang ada:
!`cd "${CLAUDE_PROJECT_DIR:-.}" && { find docs/scope/coordination -name '*.log.md' 2>/dev/null | sort | grep . || echo "(belum ada)"; }`

Worktree lain, branch yang belum di-merge ke `main`, dan commit terakhir `main`:
!`cd "${CLAUDE_PROJECT_DIR:-.}" && { git worktree list | grep -v ' \[main\]$' || echo "(tidak ada worktree lain)"; }; echo ---; { git branch --no-merged main | grep . || echo "(semua branch sudah di-merge)"; }; echo ---; git log --oneline -15`

## Alur lead

### 1. Tentukan SCOPE

- Prasyarat: lead berada di checkout utama pada `main` (`git rev-parse --abbrev-ref HEAD` = `main`, `git rev-parse --show-toplevel` bukan di bawah `.claude/worktrees/`) dan folder skill ini sudah ter-commit di `main` (`git ls-files .claude/skills/coordinate | grep -q .`), karena worktree sub sesi hanya memuat commit `main`. Bila belum ter-commit, minta user commit dulu dan sementara itu andalkan butir "Checkout utama" di file aturan umum brief; bila bukan di `main`, berhenti dan minta user menjalankan `/coordinate` dari checkout utama.
- Untuk orkestrasi Claude, periksa model lead melalui `mcp__ccd_session_mgmt__get_session` dengan `"self"`. Pilihan bawaan alat adalah `claude-fable-5-2`. Bila host mengabaikan model sub sesi yang lebih tinggi dari model lead, minta pengguna mengganti model lead melalui pemilih model sebelum membuka sub sesi. Pembacaan inventaris dan resolusi file sendiri tidak membutuhkan sesi Claude.
- Pisahkan argumen menjadi tiga bagian (bagian "Pemakaian"): scope, kata mode, dan ketentuan tambahan. Catat mode dan ketentuan tambahan di header dan baris pertama Keputusan log.
- Dari root repo, jalankan pembaca inventaris tadi dengan pemilih sebagai **satu argumen literal**. Contoh: `python3 .claude/skills/coordinate/scripts/scope.py F04`. Gunakan path yang diterbitkan program. Pisahkan mode dan ketentuan tambahan sebelum memanggilnya. Bila pemilih tidak ditemukan atau ambigu, tampilkan kesalahan dan minta pengguna memilih dari inventaris. Jangan mengeksekusi teks permintaan sebagai shell.
- Tanpa pemilih, usulkan fitur aktif pertama pada urutan indeks yang masih mempunyai langkah terbuka, lalu tunggu konfirmasi. Fitur berstatus `existing`, `done`, atau `dropped` dilewati saat memilih pekerjaan berikut. Nomor atau judul fitur di sumber lain selalu diselesaikan lewat pembaca yang sama.
- Baca file hasil pilihan, README bagian yang dirujuk dan spesifikasi yang tertaut, bila ada. Hasil pembaca memetakan fitur dan langkah, bukan menetapkan bahwa kriteria sudah lulus.

- Buat `docs/scope/coordination/<nama-SCOPE>.brief-umum.md` dari `templates/brief-umum.md` dan `<nama-SCOPE>.manual.md` dari `templates/manual.md` bila belum ada, dan commit keduanya bersama log sebelum sub sesi pertama dimulai.
- Baca bagian Keputusan semua log di `docs/scope/coordination/` dan terapkan yang berlaku lintas scope (penomoran spec, pilihan cross check); catat ulang di log SCOPE ini dengan rujukan log asalnya.
- Bila `docs/scope/coordination/<nama-SCOPE>.log.md` ada, baca dulu, lalu cocokkan tiap baris tabel sub sesinya: (a) masih tampil di `list_sessions {"linked": true}` atau `ListAgents` → jangan mulai ulang; kirim `SendMessage` berisi alamat lead baru dan minta laporan ke sana; (b) sesi hilang tetapi branch-nya punya commit di depan `main` (`git log --oneline main..<branch>`) → perlakukan sebagai laporan `done` yang belum diperiksa lewat gerbang langkah 6, atau bila belum selesai mulai sub sesi pengganti dengan `source_branch: <branch lama>` dan brief yang menyebut commit terakhirnya; worktree kotor (`git -C <worktree> status --short`) → biarkan apa adanya, catat di "Blocker terbuka", dan item itu menunggu sampai user memilih commit `wip(...)` atau buang; (c) tidak keduanya → item kembali ke antrian. Catat hasilnya di log; bila heading atau kolom log lama berbeda dari `templates/log.md`, sesuaikan dulu.

### 2. Analisis dan rencana wave

Baca SCOPE beserta prasyaratnya, `docs/scope/index.md` (Urutan pengerjaan, Workflow, Cara memakai scope), instruksi `AGENTS.md` yang berlaku untuk lokasi kerja, dan spec yang ditautkan bila sudah ada. Periksa bagian Requirements, Build plan, keputusan, bukti, serta follow up yang relevan. Bila dokumen berisi konflik Git, selesaikan konflik bersama pemilik sebelum bergantung padanya.

Baca **perintah di dalam kotak**, terlepas dari bahasa label dan penanda daftar (`*` atau `-`). `/architect` memulai desain; hasilnya memperluas file fitur dengan tautan spec, kotak build beserta milestone, serta pemeriksaan tier. `/audit` masuk ke developer sebagai penugasan dokumentasi/aturan dengan skill audit. `/develop` langsung masuk ke developer memakai **Done when** dan AC fitur sebagai brief bila belum ada spec. Tambahkan kotak build lanjutan setelah audit bila hasil kerjanya membutuhkannya, dan kotak penutup yang belum ada sebelum menutup langkah awal. Pada tier Beta, siapkan `/check verify <fitur>` kemudian `/test <fitur>` pada file fitur tersebut. Saat entri langsung mulai dikerjakan, ubah status heading dan baris indeks ke `in-progress` dalam satu commit. Tag tier di heading menggantikan default dari indeks. Ketiadaan spec sendiri bukan blocker untuk entri langsung.

Rekonsiliasi dulu dengan keadaan nyata, selalu, bukan hanya bila log ada:

- Sesi dan branch lain: jalankan `ListAgents`, `list_sessions` tanpa filter, dan `git branch --no-merged main`; petakan tiap sesi peer dan branch ke fitur dan milestone lewat judul, nama branch, subject `git log --oneline main..<branch>`, dan path `git diff --stat main...<branch>` dibandingkan `code in`. Item yang cocok ditandai **DIKERJAKAN DI LUAR KOORDINASI**, bukan SIAP. Bawaannya tunggu: lead tidak menyentuh sesi atau branch itu, dan saat branch-nya selesai lead memeriksanya lewat langkah 6. Ambil alih (lead mengirim brief lewat `SendMessage` dan memperlakukan laporannya seperti sub sesi) atau abaikan hanya atas kata user. Branch tanpa sesi hidup dicatat di log "Blocker terbuka" dengan tawaran merge atau hapus. Sesi lain yang menyentuh `docs/scope/` dilaporkan ke user sebelum lead mengedit scope. Batas 4 sesi menghitung peer yang masih `busy`.
- Kode yang sudah masuk `main`: untuk tiap kotak `[ ]`, cek path `code in`, artefak yang disebut teks kotak (modul, trait, file test), dan `git log --oneline -15 -- <path dari Build plan>`. Kotak yang artefaknya sudah lengkap di `main` bukan item developer: ia langsung masuk checker verify langkah 6 dan dicatat di log Keputusan dengan hash commit-nya; kotak yang sebagian sudah ada menjadi item developer yang brief-nya menyebut langkah Build plan yang sudah masuk di "Prasyarat yang sudah selesai".

Bangun antrian dari urutan indeks, prasyarat yang tertulis di kotak dan spec, Follow-up lintas fitur, serta **Done when**. Resolusi `spec NNNN` mengikuti tautan spec. Resolusi nomor fitur mengikuti pembaca inventaris. Prasyarat per langkah dapat terbuka setelah perubahan terkait masuk `main` dan lolos pemeriksaan. Catat bukti untuk tiap prasyarat. Penutupan mengikuti tier dan urutan dalam file fitur, dengan verifikasi sebelum tes pada Beta. Arahkan keputusan baru yang memengaruhi kontrak ke architect, dokumentasi konvensi ke audit, dan implementasi yang sudah ditentukan ke developer. Follow-up tentang fitur baru menjadi usulan ke pengguna.

Tandai tiap kotak terbuka **SIAP** atau **TERBLOKIR** beserta penyebabnya: prasyarat yang belum masuk `main` (kotak `[x]`, atau branch developer-nya sudah di-merge dan pemeriksaan `main` langkah 6 hijau walau checker verify-nya masih berjalan), keputusan yang belum ada di spec, atau hardware dan akun yang tidak tersedia. Prasyarat SIAP di file scope lain yang ownership-nya bebas masuk antrian yang sama sebagai item (brief menyebut file scope-nya; lead mencentangnya di file scope itu dan mencatatnya di log dengan kolom Scope). Dengan argumen nomor fitur, prasyarat lintas fitur dan lintas scope boleh ikut, item lain tidak.

Satu item adalah satu kotak atau sebagian tugas Build plan ketika file milik masing masing sub sesi tidak beririsan. Catat path pemilik di brief. Beri kontrak publik, definisi desain sumber dan hasil generasi terkait satu pemilik per perubahan. Jadwalkan serial bila dua item perlu mengubah file bersama. Untuk spec baru pilih nomor yang bebas di repo, branch dan log aktif; tetapkan sebelum architect mulai. Kotak `(spec)` bersarang di bawah build memperbarui spec tertaut.

Rencana adalah antrian terurut yang disetujui sekali, bukan himpunan. Urutan: (1) item pada rantai sisa terpanjang menuju kotak terakhir SCOPE; (2) item yang merge-nya membuka paling banyak item lain, termasuk di file scope lain, dan untuk file satu pemilik urutkan pemiliknya menurut jumlah dependen; (3) kotak penutup fitur yang `Build it`-nya `[x]`; (4) architect tanpa dependen build sebagai pengisi slot. Item yang ownership-nya tumpang tindih dengan item yang sedang berjalan menunggu. Tampilkan tabel: item, peran, file scope, rantai sisa, yang dibuka, ownership, nama sub sesi, model dan effort yang dipilih untuk langkah 3, serta item TERBLOKIR yang akan terbuka oleh merge wave ini dalam urutan mulainya. Lead menampilkan tabel itu lalu langsung ke langkah 3 tanpa menunggu; antrian yang berubah (blocker baru, item tambahan) ditampilkan lagi dengan cara yang sama. Item TERBLOKIR karena keputusan dibuka menurut "Mode keputusan" (lewat item architect, atau satu `AskUserQuestion` untuk semua pertanyaan ronde itu); item TERBLOKIR karena hardware, akun, atau izin user mengikuti "Langkah manual". Bila tidak ada item SIAP sama sekali sesudah itu, jangan mulai sub sesi: tulis tiap blocker satu baris `<fitur> · <kotak> ← <file>:<prasyarat>` | `keputusan: <pertanyaan, OQ/AC terkait>` | `hardware/akun: <apa, pemiliknya>`, dan tawarkan prasyarat lintas scope dari lead ini.

### 3. Mulai sub sesi

Mulai sub sesi dari kepala antrian, maksimal 4 berjalan bersamaan (peer yang `busy` ikut dihitung); begitu satu selesai, ambil item antrian berikutnya yang ownership-nya bebas (termasuk yang baru terbuka oleh merge) tanpa menunggu wave berakhir dan tanpa persetujuan ulang. Untuk tiap item panggil `mcp__ccd_session__start_session` dengan `initiation: "user_asked"`, `context: "fresh"`, `use_worktree: true`, `wake_when_done: true`, `name` berbentuk `<peran>-f<fitur>-<item>` dengan peran disingkat `arc`, `dev`, `chk`, `tst`, `dbg` dan `<item>` = `m<k>` untuk milestone, `m<k>-s<langkah>` untuk pecahan, atau `spec`, `update`, `verify`, `test`, `review`, `fix` (contoh `dev-f10-m1-s3`, `chk-f6-review`, `arc-f67-spec`; maksimal 24 karakter; nama yang sudah dipakai wave lama diberi akhiran `-2`), `branch_name` yang sama, `title` yang diawali `name` itu (`<name> · <fitur dan item>`, di bawah 60 karakter) karena `ListAgents` menampilkan judul dan `[ref]`, bukan `name`, `prompt` berisi brief dari `templates/brief.md` yang sudah terisi penuh, dan `background` berisi tujuan wave. Sub sesi hanya menerima brief itu, bukan riwayat lead, jadi brief harus lengkap; aturan yang sama untuk semua item scope ini tinggal di `<nama-SCOPE>.brief-umum.md` dan brief menunjuknya. Jangan set `permission_mode`, supaya pesan antarsesi tidak tertahan menunggu persetujuan. `source_branch`: checker verify milestone dan debugger pada branch yang belum di-merge mendapat `source_branch: claude/<branch developer>`, sub sesi pengganti mendapat branch lama, yang lain dipotong dari `main`. Pilih model dan effort dari tabel peran di bawah, lalu catat model aktual di kolom Model log.

`start_session` bisa ditolak pada giliran yang dipicu pesan sesi lain, jadi pada giliran user (giliran `/coordinate` itu sendiri) lead memulai sekaligus semua sesi yang antrian butuhkan: satu sesi per fitur yang punya item SIAP atau akan terbuka di wave ini, ditambah satu sesi cadangan `chk-f<n>-review` untuk tiap fitur `· GA` yang `Review it`-nya masih terbuka, karena review wajib sesi yang belum melihat implementasi. Sesi cadangan dan sesi yang itemnya belum SIAP mengakhiri giliran pertama dengan `STATUS: standby`. Sesudah itu item berikutnya berjalan di sesi yang dipakai ulang ("Pakai ulang sub sesi" di Hemat token); item yang tidak mendapat sesi menunggu sesi yang selesai atau giliran user berikutnya. Sesi architect tidak membangun, jadi boleh melebihi batas 4 sampai 6 sesi; jumlah build penuh yang berjalan bersamaan disesuaikan dengan kapasitas runner.

Jika aplikasi membatasi effort giliran pertama di bawah kebutuhan peran, giliran pertama sesi itu hanya membaca brief, file aturan umum, dan role, lalu berakhir `STATUS: standby`; lead lalu memanggil `set_session_effort` dan mengirim "mulai".

Model bawaan alat koordinasi Claude mengikuti tabel. Ketentuan tambahan dari pengguna mengubah baris yang disebut untuk run itu.

| Peran | Nama | Model | Effort |
| --- | --- | --- | --- |
| Architect dan pembaruan spec | `arc-…` | `claude-fable-5-2` | `high` |
| Developer, termasuk entri audit dan perbaikan | `dev-…` | `claude-opus-5-5` | `medium` |
| Tester | `tst-…` | `claude-opus-5-5` | `high` |
| Checker verify dan checker review | `chk-…` | `claude-fable-5-2` | `high` |
| Debugger | `dbg-…` | `claude-fable-5-2` | `medium` |

Review GA menggunakan sesi baru yang belum melihat implementasi. Jika seluruh penulis memakai Opus, pakai Fable. Jika seluruh penulis memakai Fable, pakai Opus dengan effort `high`. Jika kedua keluarga model ikut menulis, pakai Fable dan cross check dari subagent di dalam `/check review`. Catat model penulis dan reviewer yang benar benar dipakai di brief serta laporan.

Sub sesi memakai skill sesuai brief (`audit`, `architect`, `develop`, `check`, `test`, atau `debug`) lewat tool `Skill` atau file instruksi skill yang tersedia di host. Jika skill yang diperlukan tidak tersedia, beri tahu lead agar ia dapat menjadwalkan tugas setara dari kriteria repo atau melaporkan keterbatasannya.

Alamat lead untuk `SendMessage` diambil dari baris pertama hasil `ListAgents` dan ditulis di file aturan umum brief; nama dan judul sub sesi terkait ditulis di brief karena `name` ditentukan lead sebelum mulai.

### 4. Komunikasi

Sub sesi boleh saling kirim pesan langsung lewat `SendMessage` (alamat persis seperti baris `ListAgents`: judul plus `[ref]`) untuk pertanyaan kontrak atau API, kegagalan test, dan temuan review, lalu mengirim ringkasan satu kalimat ke lead. Perubahan di luar ownership diminta lewat pesan ke pemilik file, bukan diedit sendiri. Penyimpangan dari spec dan keputusan yang belum tercatat diteruskan ke lead, yang menyelesaikannya menurut "Mode keputusan"; langkah yang butuh izin user mengikuti "Langkah manual". Panel skill asli dijawab sub sesi dari butir "Panel skill" di file aturan umum dan field "Jawaban panel khusus item ini" di brief, atau diteruskan ke lead dengan `STATUS: needs-decision`; lead tidak pernah menjawab panel di jendela sub sesi, dan keputusan yang berlaku untuk semua item (mis. pilihan cross check) dicatat sekali di log Keputusan dan di file aturan umum brief. Aplikasi menahan pesan antarsesi lead sesudah sekitar 20 pesan sejak user terakhir mengetik: brief meminta satu laporan akhir per item tanpa pesan sementara, lead menggabungkan tindak lanjut untuk satu sesi ke satu pesan, dan saat pesan mulai tertahan lead menutup giliran dengan ringkasan satu baris dan meminta user mengetik `lanjut`. Pesan ke sesi yang sedang bekerja masuk antrian sampai gilirannya berakhir; laporan yang tidak tiba dibaca lewat `mcp__ccd_session_mgmt__list_events`. Lead mengirim tindak lanjut ke sub sesi yang sama lewat `SendMessage`, bukan memulai sesi baru; tindak lanjut sesudah laporan `done` atau sesudah merge lain selalu dimulai dengan `git merge main` di worktree sesi itu.

### 5. Laporan

Saat sub sesi mengakhiri giliran, lead menerima catatan berisi awal recap-nya; karena itu baris pertama recap wajib `STATUS: ...`. Laporan lengkap sesuai `templates/report.md` dikirim sub sesi ke lead lewat `SendMessage`. Setiap branch atau worktree yang selesai wajib sudah ter-commit: laporan `done` hanya sah bila pekerjaannya ter-commit di branch sub sesi itu dan working tree-nya bersih; laporan `done` dengan perubahan yang belum di-commit dikembalikan dengan permintaan commit. Laporan tanpa STATUS, daftar file, branch, atau perintah plus hasil dikembalikan untuk dilengkapi. File di luar BOLEH yang muncul di laporan adalah pelanggaran: minta dikembalikan, lalu catat di log. Catatan sebuah sesi adalah laporannya, bukan bukti: lead memeriksa diff branch-nya sebelum mempercayainya.

### 6. Gerbang centang dan merge

Hanya lead yang menulis file scope dan indeks. Sebelum merge, periksa diff, kepemilikan file dan hasil uji branch. Periksa hasil gabungan sebelum commit merge, termasuk konflik Git dan perintah proyek yang relevan dengan perubahan. Ambil perintah dari repo tablet, spec dan brief. Untuk perubahan dokumen, periksa target tautan dan konsistensi indeks. Untuk perubahan native, jalankan build atau alur pada target yang dijanjikan. Jika pemeriksaan gagal, batalkan merge yang masih tertunda, teruskan bukti ke pemilik dan debugger, lalu ulangi setelah perbaikan. Hasil lama perlu diperiksa kembali jika jalur yang dibuktikan berubah.

- Kotak dengan `/architect`: setelah spec dengan AC, keputusan, dan Build plan didukung oleh gerbang desain, pertahankan H1 `# <n>. <nama> · in-progress`, lepaskan tag keputusan yang sudah selesai, dan pertahankan tag tier lain. Tautkan path spec yang benar, centang langkah desain, lalu tambahkan build dengan milestone dan langkah penutup sesuai tier. Untuk kotak audit atau develop langsung, ikuti gerbang dan kotak lanjutan langkah 2 tanpa mengarang spec.
- Setiap perubahan status dipasang pada heading file fitur dan sel Status di baris nomor yang sama pada tabel “Urutan pengerjaan” di `docs/scope/index.md` dalam satu commit. Jalankan pembaca inventaris lagi setelah mengedit. Pertahankan penanda daftar, level heading, dan tautan fitur asli.

- Milestone: centang setelah kode masuk dan checker menguji AC yang terkait pada target yang dijanjikan. Tambahkan tautan kode dan bukti ke file fitur. Jika ada spec, perbarui status spec sesuai alurnya.
- Build dan verifikasi: periksa terpisah pekerjaan implementasi dan hasil verifikasi. Untuk setiap kotak, seluruh kriteria wajib yang menjadi tanggung jawabnya harus berstatus `PASS`. Catat AC, SHA yang diuji, target, versi OS, perintah atau langkah manual, hasil aktual dan lokasi bukti pada baris terpisah per platform. Langkah wajib `NOT_RUN` atau `BLOCKED` membuat kotak terkait tetap terbuka dan fiturnya belum terverifikasi.
- Tes: laporan tester mencantumkan tes yang dijalankan terhadap commit integrasi dan bukti per target terkait. Setelah tes lulus, lead mencentang kotaknya.
- `Review it` (fitur `· GA`): review dari sub sesi checker BARU yang belum melihat implementasinya (brief memuat Range perubahan dan Model penulis kode), file di `docs/reviews/` ada. Temuan Blocker atau Major: lead memulai developer `dev-f<fitur>-fix` dengan ownership file temuan, merge lewat pemeriksaan di atas, checker verify yang sama mengulang langkah `verify.md` yang menyentuh file itu lewat `SendMessage`, lalu reviewer yang sama mengonfirmasi lewat diff baru; `Review it` dicentang setelah tidak ada Blocker atau Major terbuka. Minor dicatat di log.
- `Document it`: lead menjalankan skill `document` lewat tool `Skill` dengan argumen `changelog` dan rentang `<hash main sebelum merge pertama fitur>..<hash merge terakhirnya>` dari log sebagai pengganti `BASE..HEAD` (di `main` rentang bawaan kosong; `pr` tidak dipakai karena tidak ada PR), lalu membaca ulang SCOPE karena skill itu mencentang kotaknya sendiri; `CHANGELOG.md` di-commit lead `docs(changelog): <fitur>`.
- Hanya setelah semua AC wajib dan pemeriksaan tier terkait lulus, lead menandai `done` di heading dan indeks, lalu `Accepted` pada spec jika memakai status itu. Satu kotak entri yang telah dicentang, laporan `done` sub sesi, atau pencatatan langkah manual belum cukup. Hasil `FAIL` membuka kembali langkah terkait dan diteruskan ke debugger.

### 7. Log

Setelah setiap laporan, perbarui `docs/scope/coordination/<nama-SCOPE>.log.md` sesuai `templates/log.md` (`<nama-SCOPE>` adalah nama file scope tanpa `.md`, misalnya `01-arsitektur-dan-build-awal`). Buat foldernya bila belum ada. Salin field "Langkah Build plan selesai" dan "Pointer code in" laporan ke kolom Item, supaya developer milestone berikutnya menerimanya di "Prasyarat yang sudah selesai". Commit edit scope dan log segera setelah tiap centang dan tiap pembaruan log (`docs(scope): tick <fitur> <kotak>`), sebelum merge berikutnya dan sebelum memulai sub sesi baru, karena worktree baru hanya melihat `main` yang sudah di-commit dan `git merge` menolak checkout yang kotor pada file yang sama.

### 8. Akhir wave

Tutup wave dengan ringkasan, dalam urutan ini: keputusan delegasi bertanda `berat` (opsi yang diambil, runner-up, cara membatalkan), keputusan delegasi lain, pemeriksaan wajib yang masih terbuka serta bukti yang ditunggu, lalu selesai (kotak yang dicentang dan branch yang di-merge), terbuka, blocker, kotak di file scope lain yang terbuka karena merge wave ini, dan wave berikutnya. Jalankan `sync` seperti langkah 9 butir 2 dengan rentang wave ini (`<hash awal wave>..HEAD`) supaya `AGENTS.md` yang dibaca sub sesi wave berikutnya sudah mencerminkan kode yang di-merge, commit hasilnya, lalu pastikan `git status --short docs/ AGENTS.md` kosong (edit scope dan log sudah di-commit per langkah 7). Bila masih ada item terbuka, catat `git rev-parse main` sebagai hash awal wave berikutnya di log dan lanjut dari langkah 2; bila semua item SCOPE (atau fitur yang diminta) sudah `[x]`, lanjut ke langkah 9.

### 9. Penutupan: merge semua, `/sync`, commit, push, bersihkan

Saat semua gerbang pekerjaan yang dipilih lulus, lead menyelesaikan langkah berikut sesuai kewenangan run ini. Push dan pembersihan worktree mengikuti izin pengguna untuk repo dan sesi ini.

1. Cocokkan tabel sub sesi di log dengan `git branch --no-merged main`. Merge hanya branch yang laporan terakhirnya `done` dan lulus gerbang langkah 6 (termasuk pemeriksaan di `main` sesudah merge); branch `failed`, `blocked`, dan debugger dicatat `tidak di-merge` di log beserta alasannya. Selesai bila setiap branch milik koordinasi ini sudah di-merge atau tercatat beserta alasan disimpan.
2. Jalankan skill `sync` lewat tool `Skill`. Di `main` tanpa perubahan uncommitted skill itu berhenti "nothing to sync", jadi saat mengikutinya lead mengisi inputnya sendiri: `MODE=branch`, `MERGE_BASE=<hash awal dari log>`, `DIFF_COMMAND=git diff --name-status <hash awal>..HEAD`, `CHANGED_FILES` dari perintah itu, scope yang direkonsiliasi `<SCOPE>`, plus baris Follow-up `/sync ...` dari spec yang dibaca langkah 2 untuk diterapkan lalu dicentang. Sesudahnya baca `git diff docs/scope/ docs/specs/`: centang atau status yang tidak didukung gerbang langkah 6 (mis. `Test it` hanya karena ada file test) dikembalikan per hunk dan dicatat `ditolak dari /sync` di log.
3. Commit hasil `/sync` bersama log terakhir di `main`, lalu tulis ringkasan akhir di log: semua branch yang di-merge dengan hash merge-nya, kotak yang dicentang, dan blocker yang tersisa.
4. Bila push diizinkan, push `main`. `git fetch origin`, lalu periksa file yang masuk commit dan `git rev-list --count main..origin/main` = `0`. Bila remote lebih maju, berhenti dan laporkan ke user; jangan rebase, merge, atau force. Lalu `git push origin main` (tanpa `--force`, tanpa branch atau tag lain), dan pastikan `git rev-parse main` = `git rev-parse origin/main`. Push yang gagal (auth, jaringan, hook remote) menghentikan langkah ini sebelum pembersihan; laporkan error-nya ke user.
5. Bila pembersihan diizinkan, bersihkan worktree dan branch yang dipakai koordinasi ini, yaitu setiap branch di tabel sub sesi semua wave log SCOPE ini, beserta worktree-nya di `.claude/worktrees/`. Branch dan sesi di luar log tidak disentuh. Sebelum menghapus apa pun, pastikan semua isinya sudah di `main`. Tiap branch harus lulus ketiga cek ini:
   - sesinya tidak sedang bekerja (`list_sessions {"linked": true}`);
   - `git -C <worktree> status --short` kosong, termasuk file untracked;
   - `git merge-base --is-ancestor <branch> origin/main` berhasil, artinya semua commit branch itu sudah ada di `main` dan sudah ter-push.

   Bila lulus: panggil `mcp__ccd_session_mgmt__archive_session` untuk sesinya dengan `reason: "<branch> sudah di origin/main"`, yang juga menghapus worktree-nya. Bila sesinya sudah tidak ada atau worktree masih tersisa sesudah arsip, jalankan `git worktree remove <path>` tanpa `--force`. Lalu `git branch -d <branch>`, bukan `-D`. Terakhir `git worktree prune`. Sub sesi tidak pernah push, jadi tidak ada branch remote yang perlu dihapus.

   Bila satu cek gagal, atau arsip ditolak karena sesi di-pin atau sedang terbuka: jangan hapus apa pun dari branch itu. Catat `disimpan: <alasan>` di log dan sebutkan ke user. Branch yang tercatat `tidak di-merge` (`failed`, `blocked`, debugger) tidak pernah dihapus otomatis; tunjukkan `git log --oneline main..<branch>`-nya dan biarkan user memutuskan. Jangan pernah memakai `git branch -D`, `git worktree remove --force`, `clean_up_worktrees` dengan `include_uncommitted`, atau `discard_kept_worktree`.

   Selesai bila `git worktree list` dan `git branch --list 'claude/*'` tidak lagi memuat branch log ini, kecuali yang tercatat `disimpan` atau `tidak di-merge`.
6. Catat hasil penutupan. Bila laporan penutupan ikut dikirim ke remote, verifikasi kembali hash branch setelah push.

## Mode keputusan

**Keputusan** adalah pilihan yang mengubah isi spec: jawaban atas gap architect, "Accept this spec?", dan perubahan teks AC, OQ, atau keputusan yang sudah tercatat. Tafsiran AC yang ambigu oleh developer, checker, atau tester bukan keputusan: sesi itu mengambil tafsiran yang paling sesuai teks AC dan `rationale.md`, menulisnya di laporan, dan checker yang menilainya.

Keputusan **berat** adalah yang mahal dibalik sesudah dibangun: format data di disk atau migrasi, break kontrak (kenaikan major protokol), model keamanan, trust, atau secret, lisensi dan hal hukum, perilaku yang menyentuh data user yang sudah ada, dan perubahan teks AC atau keputusan pada spec `Accepted`. Architect yang menandainya; lead boleh menaikkan tanda itu, tidak menurunkannya.

| Mode | Kata di argumen | Keputusan biasa | Keputusan berat |
| --- | --- | --- | --- |
| `auto` (bawaan) | tidak ada | opsi rekomendasi | opsi rekomendasi, bertanda `berat` |
| `tanya berat` | `tanya berat` | opsi rekomendasi | user |
| `tanya` | `tanya` | user | user |

Mode hanya mengatur keputusan. Rencana wave, debugger, langkah manual, dan tanda `done` berjalan sama di ketiga mode.

**Opsi rekomendasi.** Architect memilih opsi yang direkomendasikannya sendiri, menulis alasannya dan runner-up di `rationale.md`, dan melaporkannya di field "Keputusan diambil". Bila dua opsi setara, ia mengambil yang paling murah dibalik dan menandainya `berat`. Lead membalas `accept` pada ringkasan spec sesudah memeriksa tiga hal: temuan cross check sudah diterapkan, setiap AC yang dirujuk **Done when** fitur tercakup, dan tidak ada keputusan yang bertentangan dengan spec `Accepted` lain (baca spec terkait). Ringkasan yang gagal salah satunya dikembalikan ke architect dengan daftar perbaikan. Setiap keputusan masuk tabel "Keputusan delegasi" log: opsi yang diambil, runner-up, tanda `berat`, dan cara membatalkannya.

**User.** Lead mengumpulkan pertanyaan semua architect ronde itu ke satu `AskUserQuestion` (opsi rekomendasi pertama, runner-up kedua, masing masing dengan akibatnya dalam satu kalimat), dan item yang tidak bergantung pada jawabannya tetap berjalan. Jawaban dicatat di log Keputusan dengan `user`.

**Nilai yang hanya user tahu** (alamat email, akun, handle, nama badan hukum, harga) bukan keputusan di mode apa pun: nilainya masuk file manual di bawah "Nilai dari user", AC yang bergantung padanya `BLOCKED` dengan `owner: user`, dan sisanya dibangun.

**Membatalkan.** User menyebut baris "Keputusan delegasi"; lead memulai item `architect (update)` pada spec itu dengan opsi yang user pilih, lalu item developer untuk langkah Build plan yang berubah.

## Langkah manual

Jalankan pemeriksaan native yang dapat dilakukan di lingkungan dan izin yang tersedia. Bila suatu pemeriksaan memerlukan tindakan pengguna, perangkat, atau akun yang tidak tersedia, sub sesi mencatat `NOT_RUN` atau `BLOCKED`, alasan, penanggung jawab, serta cara mengulangnya di [templat manual](templates/manual.md). Gunakan status `FAIL` untuk kegagalan yang diamati. Simpan hasil aktual, commit dan bukti per target melalui [templat laporan](templates/report.md).

Lead mencatat pemeriksaan yang tertunda di log dan membiarkan kotak yang bergantung pada AC wajib itu terbuka. Ketika pengguna atau sesi lain menguji ulang, checker memeriksa commit, target, versi OS, langkah, hasil aktual dan lokasi bukti. Hanya hasil `PASS` yang sesuai kriteria dan target itu yang membuka penutupan. Jika perangkat fisik belum diuji, hasil build untuk target perangkat tetap dicatat sebagai build.

## Batasan

- `prd.md` tidak pernah diubah. ID AC dan OQ tetap stabil; teks AC, OQ, dan keputusan spec berubah hanya lewat item architect, diputuskan menurut "Mode keputusan".
- Yang selalu menunggu user, di mode apa pun: konfirmasi scope saat argumen kosong, membuang apa pun (worktree kotor, branch yang tidak di-merge), mengambil alih sesi di luar koordinasi, `/scope` untuk fitur baru, dan remote yang lebih maju saat push.
- Lead tidak menulis kode produksi dan tidak membuat branch kerja. Lead hanya push `main` ke `origin`, hanya di langkah 9, dan tidak pernah dengan `--force`. Sub sesi commit hanya di branch-nya sendiri, tidak push, tidak membuat PR.
- Hanya lead yang mengedit file scope (SCOPE, file scope lain yang item prasyaratnya ditarik, `docs/scope/index.md`) dan log koordinasi, dan hanya lead yang merge ke `main`; konflik kode diselesaikan pemilik branch di worktree-nya, bukan lead.
- Fixture pass bukan bukti native; hardware, binary, atau signing yang hilang dicatat `BLOCKED`, bukan dilewati.

## Hemat token

- Temukan kode, keputusan dan bukti melalui indeks scope, tautan spec, serta pencarian file repo. Jika graph pengetahuan tersedia, pakai sebagai tambahan dan periksa hasilnya pada file sumber.

- **Pakai ulang sub sesi, bersihkan konteksnya dulu.** Untuk item berikutnya dari fitur yang sama (milestone berikutnya, verify milestone berikutnya, `architect (update)` lanjutan, fix hasil review), lead memakai ulang sub sesi yang sudah `done` dan di-merge, bukan memulai yang baru: 1) pastikan sesi idle dan laporannya sudah lewat gerbang; 2) panggil `mcp__ccd_session_mgmt__clear_session` dengan id sesi itu, supaya konteks `/develop` atau `/check` sebelumnya tidak terbawa; 3) bila kebutuhan model untuk item baru berbeda dari item lama (mis. verify milestone → verify penuh), panggil `set_session_model` dan `set_session_effort` lebih dulu; 4) perbarui judul lewat `set_session_title` ke `<name> · <item baru>` dan kirim brief baru yang lengkap lewat `SendMessage`, diawali perintah `git merge main` di worktree-nya; 5) catat di log sebagai baris baru dengan status `dipakai ulang`. Worktree dan branch tetap sama, jadi pemeriksaan langkah 6 memakai `git diff --stat main...<branch>` yang hanya memuat perubahan baru. Tidak untuk `Review it` (wajib sesi baru) dan tidak untuk sesi yang sedang dibuka di layar atau di-pin (clear ditolak aplikasi; mulai sesi baru).
- **Brief ringkas, bukan salinan.** Brief menunjuk bagian spec dan `verify.md` yang dibutuhkan item itu, bukan menyalin isinya; `AGENTS.md` sudah dimuat otomatis di tiap sesi, jadi tidak diulang; laporan sub sesi memuat nomor langkah dan path, bukan isi file.

## File skill

- `roles/architect.md`, `roles/developer.md`, `roles/checker.md`, `roles/tester.md`, `roles/debugger.md`: tujuan, command, ownership, jalur pesan, definisi selesai, dan verifikasi tiap peran.
- `templates/brief.md`, `templates/report.md`, `templates/log.md`: format brief, laporan, dan log.
- `templates/brief-umum.md`: aturan yang sama untuk semua brief satu scope (mode keputusan, model per peran, larangan, disk, panel skill); lead mengisinya sekali di langkah 1.
- `templates/manual.md`: format file langkah manual untuk user.
