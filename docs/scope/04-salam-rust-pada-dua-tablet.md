# 4. Salam Rust pada dua tablet · done

Dari satu layar SwiftUI dan satu layar Compose, Anda dapat memasukkan nama dan membaca hasil yang dikembalikan oleh implementasi Rust yang sama.

Lengkapi panduan mulai singkat dengan versi alat, perintah untuk membangun dan menjalankan tiap aplikasi, serta cara mencoba salam. Workflow pull request pertama memakai [aturan CI dan format bukti per target](02-aturan-kontribusi.md).

**Done when:** dari clone bersih pada runner CI baru, perintah repo yang sama dengan panduan lokal menghasilkan binding, membangun, lalu meluncurkan aplikasi pada simulator iPad dan emulator tablet Android. Pada kedua layar, mengganti nama dari `Ayu` menjadi `Bima` lalu memicu aksi mengubah hasil dari `Hello, Ayu!` menjadi `Hello, Bima!` melalui satu implementasi Rust. Hasil dari commit yang diuji tercatat tersendiri untuk tiap platform. AC 5, 6, 7, 8, 9, 10.

**Spec:** [0003](../specs/0003-salam-rust-dua-tablet.md), mengikuti [kontrak 0002](../specs/0002-kontrak-rust-kedua-aplikasi/index.md).

* [x] Rancang alur dan CI (spec), keputusan teknis diterima lewat kebijakan `auto` agent-flow.
* [x] Bangun alur pada kedua tablet: `/develop salam Rust pada dua tablet`
  * [x] Tautkan binding dan layar input kedua platform (AC-1, AC-2, AC-3, AC-5).
  * [x] Buktikan interaksi dan regresi kemasan (AC-4, AC-8).
  * [x] Siapkan CI, panduan, dan bukti clone bersih (AC-6, AC-7, AC-8).
* [x] Verifikasi perilaku nyata: `/check verify salam Rust pada dua tablet`
* [x] Tes regresi: `/test salam Rust pada dua tablet`

**Kode:** `apps/ipados/Tablet/App/TabletApp.swift`, `apps/android-tablet/app/src/main/kotlin/foundation/tablet/MainActivity.kt`, `bindings/swift/Package.swift`, `scripts/`, dan `.github/workflows/pull-request.yml`.

## Langkah terakhir yang terverifikasi

2026-11-17: [hosted run 44120618653](https://github.com/ojiepermana/foundation-tablet/actions/runs/44120618653) lulus pada kedua target untuk head sumber `6f1ce92c6b57df4bc9f3f9f7173ac6fb06bad70e`, checkout merge `b5ef18beeb9388a6f7361efd2ffd9b08e13aa43a`. Runner baru membangun binding dan aplikasi, menjalankan 2 XCTest iPad (A16) iPadOS 27.0 serta 3 tes Compose tablet API 36 x86_64, lalu membuktikan source bersih. Gerbang Rust/repo dan kedua grup artefak lulus. [Bukti per kriteria dan target](../reviews/2026-11-17-verify-f04.md). Bukti lokal mode satu slice dan tampilan sebelumnya tetap berlaku karena source yang diuji identik, selain perbaikan lokasi AVD CI.

## Langkah berikutnya

Tidak ada langkah terbuka untuk scope 04. Spec 0003 Accepted dan [PR #1](https://github.com/ojiepermana/foundation-tablet/pull/1) memuat implementasi beserta bukti hosted. Perubahan scope 05 yang sedang berjalan di checkout bersama dipertahankan dan tidak masuk penutupan ini.

Koordinasi Native Subagents, model yang diminta, batas bukti model, dan worktree ada di [state run](coordination/04-salam-rust-pada-dua-tablet/state.json).

[Kembali ke indeks scope](index.md)
