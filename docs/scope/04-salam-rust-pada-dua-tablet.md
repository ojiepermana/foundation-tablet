# 4. Salam Rust pada dua tablet · in-progress

Dari satu layar SwiftUI dan satu layar Compose, Anda dapat memasukkan nama dan membaca hasil yang dikembalikan oleh implementasi Rust yang sama.

Lengkapi panduan mulai singkat dengan versi alat, perintah untuk membangun dan menjalankan tiap aplikasi, serta cara mencoba salam. Workflow pull request pertama memakai [aturan CI dan format bukti per target](02-aturan-kontribusi.md).

**Done when:** dari clone bersih pada runner CI baru, perintah repo yang sama dengan panduan lokal menghasilkan binding, membangun, lalu meluncurkan aplikasi pada simulator iPad dan emulator tablet Android. Pada kedua layar, mengganti nama dari `Ayu` menjadi `Bima` lalu memicu aksi mengubah hasil dari `Hello, Ayu!` menjadi `Hello, Bima!` melalui satu implementasi Rust. Hasil dari commit yang diuji tercatat tersendiri untuk tiap platform. AC 5, 6, 7, 8, 9, 10.

**Spec:** [0003](../specs/0003-salam-rust-dua-tablet.md), mengikuti [kontrak 0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md).

* [x] Rancang alur dan CI (spec), keputusan teknis diterima lewat kebijakan `auto` agent-flow.
* [x] Bangun alur pada kedua tablet: `/develop salam Rust pada dua tablet`
  * [x] Tautkan binding dan layar input kedua platform (AC-1, AC-2, AC-3, AC-5).
  * [x] Buktikan interaksi dan regresi kemasan (AC-4, AC-8).
  * [x] Siapkan CI, panduan, dan bukti clone bersih (AC-6, AC-7, AC-8).
* [ ] Verifikasi perilaku nyata: `/check verify salam Rust pada dua tablet`
* [x] Tes regresi: `/test salam Rust pada dua tablet`

**Kode:** `apps/ipados/Tablet/App/TabletApp.swift`, `apps/android-tablet/app/src/main/kotlin/foundation/tablet/MainActivity.kt`, `bindings/swift/Package.swift`, `scripts/`, dan `.github/workflows/pull-request.yml`.

## Langkah terakhir yang terverifikasi

2026-11-16: source snapshot bersih `677eb0eea64cf52cd9130216b43dcde2ecaba9ad` (dasar pengguna `be511aa` + patch fitur 04) membangun kedua aplikasi dan mode iPad satu slice. Sebanyak 81 kasus skrip/artefak pada 11 file, 2 XCTest iPad mini iPadOS 27.0, serta 3 tes Compose emulator tablet API 36 arm64 lulus. Lima tes Rust dan gerbang fmt/clippy lulus. Runtime/tooling/tes pada snapshot identik dengan checkout pengguna menurut manifest SHA256. [Bukti per target](../reviews/2026-11-16-verify-f04.md) dan [laporan tes](../reviews/2026-11-16-test-f04.md).

## Langkah berikutnya

Publikasikan branch fitur dan PR setelah pengguna mengizinkan publikasi, lalu tunggu kedua job hosted pada revisi yang sama. Simpan URL/run ID dan SHA serta hasil per target di laporan. AC-7 spec 0003 dan Done when runner CI baru masih `NOT_RUN`; jangan tandai fitur done atau spec Accepted sebelum bukti itu ada. Source pengguna belum di-commit atau di-push.

Koordinasi Native Subagents, model yang diminta, batas bukti model, dan worktree ada di [state run](coordination/04-salam-rust-pada-dua-tablet/state.json).

[Kembali ke indeks scope](index.md)
