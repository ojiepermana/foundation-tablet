# Log koordinasi: `02-aturan-kontribusi`

- **Scope:** `docs/scope/02-aturan-kontribusi.md`
- **Hash awal:** `3b15469`
- **Mode keputusan:** `auto` (bawaan, user tidak memberi tanda) · **Ketentuan tambahan:** tidak ada
- **Tier:** Beta (indeks scope): `/audit` lalu verify lalu test
- **Diperbarui:** 2026-11-16

## Tahap

| Tahap | Workflow | Penempatan | Model sesi | Status |
| --- | --- | --- | --- | --- |
| Catat aturan dari repo | `/audit` gap fill (root `AGENTS.md` sudah ada) | inline, main thread (syarat skill audit) | `claude-opus-5-5` | selesai |
| Panduan terperinci | menulis dokumen yang dirujuk `AGENTS.md` | inline | `claude-opus-5-5` | selesai (`docs/contributing.md`) |
| Tes | `/test` untuk tautan dan rujukan `AGENTS.md` | inline, main thread (syarat skill test) | `claude-opus-5-5` | selesai (G1 sampai G4) |
| Verify | peta **Done when** ke baris dokumen, cek tautan dan perintah | subagent baru, hanya baca, konteks segar | `sonnet` (diminta; model nyata tidak dilaporkan runtime) | PASS, tiga temuan kecil |
| Review independen | `/check review` | dilewati | | tier Beta tidak memintanya |

## Keputusan

| Tanggal | Keputusan | Oleh |
| --- | --- | --- |
| 2026-11-16 | Argumen run: scope `2. Aturan kontribusi`, mode `auto`. | user |
| 2026-11-16 | Panduan terperinci ditulis di `docs/contributing.md` (bahasa Indonesia), bukan `CONTRIBUTING.md` di akar: `README.md` adalah dokumen produk dan panduan lain sudah ada di `docs/`. `AGENTS.md` hanya memuat aturan singkat dan tautan (README bagian 18). | lead (auto) |
| 2026-11-16 | Keputusan arsitektur tetap dicatat sebagai spec lewat `/architect` di `docs/specs/`, sesuai `docs/architecture/repository-structure.md` (tanpa folder ADR). | lead (auto) |
| 2026-11-16 | Tidak ada `AGENTS.md` bersarang baru: area `apps/`, `crates/`, `tests/` masih scaffold dan aturannya sudah ada di spec 0001 serta kepala file. Ditimbang ulang saat fitur 03 sampai 05 mengisi area itu. | lead (auto) |
| 2026-11-16 | Panel izin audit (`Add them now` / `Show me the diff` / `Skip`) dijawab `Add them now` atas dasar mode `auto`. Root `AGENTS.md` tanpa baris drafted by, jadi hanya menambah, tanpa mengubah baris yang ada. | lead (auto) |
| 2026-11-16 | Aturan CI ditulis sebagai ketentuan untuk workflow pertama (fitur 04 menurut scope 02, fitur 11 menurut audit scaffold); belum ada `.github/`. | lead (auto) |
| 2026-11-16 | `cargo fmt --all --check` dan `cargo clippy --workspace --locked --all-targets -- -D warnings` lulus pada `3b15469`, jadi keduanya masuk daftar pemeriksaan panduan. | lead |
| 2026-11-16 | Temuan verify: kalimat `git status --short` diperjelas menjadi "dari tree bersih", dan kasus G4 ditambah. Saran mengganti rujukan README bagian 12 ditolak karena bagian 12 memang memuat daftar "Never commit"; rujukan menjadi "12 dan 20.3". | lead |
| 2026-11-16 | Fitur 02 `done`: setiap kalimat Done when PASS ([bukti](../../reviews/2026-11-16-verify-f02.md)), tier Beta terpenuhi (verify lalu tes), `scripts/test.sh` lulus. Workflow CI nyata tetap `NOT_RUN` sampai fitur 04. | lead |

## Blocker terbuka

Tidak ada.
