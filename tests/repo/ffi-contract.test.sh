# Grup repo: kontrak FFI dan generator binding yang tahan lama (spec 0002, AC-1 sampai
# AC-4, AC-8). Membaca file repo tanpa memanggil Cargo atau membangun apa pun.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

CONVENTIONS="docs/contracts/ffi-conventions.md"
UNIFFI_TOML="crates/tablet-ffi/uniffi.toml"
TOOLING="tooling/uniffi-bindgen"

# File repo yang terlacak atau belum terlacak tetapi tidak diabaikan, sesuai pola.
repo_files() {
  git ls-files --cached --others --exclude-standard -- "$@" | LC_ALL=C sort -u
}

case_f1() {
  local f found=""
  while IFS= read -r f; do
    [ -n "$f" ] && [ "$f" != Cargo.toml ] || continue
    if grep -q 'uniffi' "$f"; then
      found="$found $f"
    fi
  done <<EOF
$(repo_files '*Cargo.toml')
EOF
  expect_eq " crates/tablet-ffi/Cargo.toml $TOOLING/Cargo.toml" "$found" \
    "manifest selain Cargo.toml akar yang memuat uniffi"
}

case_f2() {
  local ok=0 members manifest
  members="$(awk '/^members *= *\[/ { f = 1 } f { print } f && /\]/ { exit }' Cargo.toml)"
  expect_contains "$members" "\"$TOOLING\"" "members di Cargo.toml" || ok=1
  manifest="$TOOLING/Cargo.toml"
  [ -f "$manifest" ] || { diag "$manifest tidak ada"; return 1; }
  expect_eq "tablet-uniffi-bindgen" "$(sed -n 's/^name *= *"\([^"]*\)".*/\1/p' "$manifest" | head -n 1)" \
    "nama paket $TOOLING" || ok=1
  expect_contains "$(grep '^uniffi' "$manifest")" 'workspace = true' "dependensi uniffi $manifest" || ok=1
  expect_contains "$(grep '^uniffi' "$manifest")" '"cli"' "fitur uniffi $manifest" || ok=1
  expect_eq 1 "$(grep -c '^\[dependencies\]' "$manifest")" "jumlah bagian [dependencies] $manifest" || ok=1
  expect_eq "" "$(repo_files 'crates/*' | grep -i 'bindgen')" "file generator di bawah crates/" || ok=1
  return $ok
}

case_f3() {
  local ok=0 swift kotlin
  [ -f "$UNIFFI_TOML" ] || { diag "$UNIFFI_TOML tidak ada"; return 1; }
  swift="$(_toml_section "$UNIFFI_TOML" bindings.swift)"
  kotlin="$(_toml_section "$UNIFFI_TOML" bindings.kotlin)"
  expect_contains "$swift" 'module_name = "TabletBindings"' "[bindings.swift]" || ok=1
  expect_contains "$swift" 'ffi_module_name = "TabletFFI"' "[bindings.swift]" || ok=1
  expect_contains "$swift" 'ffi_module_filename = "TabletFFI"' "[bindings.swift]" || ok=1
  expect_contains "$kotlin" 'package_name = "foundation.tablet.bindings"' "[bindings.kotlin]" || ok=1
  expect_contains "$kotlin" 'cdylib_name = "tablet_ffi"' "[bindings.kotlin]" || ok=1
  expect_eq "" "$(grep -n 'omit_checksums' "$UNIFFI_TOML")" "omit_checksums di $UNIFFI_TOML (checksum harus aktif)" || ok=1
  return $ok
}

case_f4() {
  local f line bad=""
  for f in scripts/*.sh; do
    while IFS= read -r line; do
      case "$line" in
        *'cargo build'* | *'cargo ndk'*' build'*) ;;
        *) continue ;;
      esac
      case "$line" in
        *printf* | '#'*) continue ;;
      esac
      case "$line" in
        *'-p tablet-ffi '* | *'-p tablet-uniffi-bindgen '*) ;;
        *) bad="$bad [$f: $line]" ;;
      esac
    done < "$f"
  done
  expect_eq "" "$bad" "pemanggilan cargo build atau cargo ndk build tanpa -p tablet-ffi atau -p tablet-uniffi-bindgen"
}

case_f5() {
  local ok=0 heading
  [ -f "$CONVENTIONS" ] || { diag "$CONVENTIONS tidak ada"; return 1; }
  while IFS= read -r heading; do
    [ -n "$heading" ] || continue
    grep -Fxq "## $heading" "$CONVENTIONS" || { diag "$CONVENTIONS tanpa judul '## $heading'"; ok=1; }
  done <<'EOF'
Antarmuka UniFFI
DTO Rust
Galat bertipe
Kode galat yang terbaca mesin
Nullability
Kepemilikan sumber daya
Thread pemanggil
Kompatibilitas
Versi
Operasi async
Pembatalan
Antarmuka kemampuan native
Kontrak transport
Hasil generasi
Menambah fungsi kontrak
EOF
  return $ok
}

case_f6() {
  local ok=0
  expect_eq 1 "$(grep -c '^pub fn ' crates/core/src/lib.rs)" "jumlah pub fn di crates/core/src/lib.rs" || ok=1
  expect_eq "pub fn hello(name: String) -> String {" "$(grep '^pub fn ' crates/core/src/lib.rs)" \
    "fungsi publik tablet-core" || ok=1
  expect_eq "" "$(grep -rnE 'uniffi::|^[[:space:]]*uniffi[[:space:]]*=' crates/core 2>/dev/null)" \
    "pemakaian uniffi di kode atau manifest crates/core" || ok=1
  expect_eq 1 "$(grep -c '#\[uniffi::export\]' crates/tablet-ffi/src/lib.rs)" \
    "jumlah #[uniffi::export] di crates/tablet-ffi/src/lib.rs" || ok=1
  expect_eq "" "$(repo_files '*.udl')" "file UDL di repo" || ok=1
  return $ok
}

check F1 AC-3 "hanya tablet-ffi dan tooling/uniffi-bindgen yang memuat uniffi" case_f1
check F2 AC-3 "crate generator di tooling/, memakai pin uniffi workspace dengan fitur cli" case_f2
check F3 AC-4,AC-5 "uniffi.toml memuat nama modul spec 0001 dan checksum tetap aktif" case_f3
check F4 AC-3 "build cargo di scripts/ selalu memilih paket dengan -p" case_f4
check F5 AC-8 "konvensi kontrak punya bagian untuk tiap topik" case_f5
check F6 AC-1,AC-2 "inti satu fungsi publik tanpa uniffi, ekspor lewat makro tanpa UDL" case_f6
finish
