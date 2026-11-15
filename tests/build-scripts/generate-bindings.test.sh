# Grup build-scripts: kontrak scripts/generate-bindings.sh di sandbox dengan cargo dan
# generator tiruan (spec 0002, AC-4, AC-5, AC-6, AC-7). Tidak ada build atau generasi nyata.
#
# cargo tiruan: "build -p tablet-uniffi-bindgen" menanam target/debug/uniffi-bindgen tiruan
# (gagal bila STUB_CARGO_BUILD_FAIL=1). Generator tiruan menulis file yang diharapkan per
# bahasa ke --out-dir. Sakelar: STUB_GEN_DIFFER=1 (isi bergantung pada path pustaka),
# STUB_GEN_FAIL=1 (keluar 1), STUB_GEN_MISSING=1 (satu file tidak ditulis).
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

IOS=aarch64-apple-ios
SIM=aarch64-apple-ios-sim
ARM=aarch64-linux-android
X86=x86_64-linux-android
OLD=202601010000
NEW=202601020000
NEWER=202601030000

SWIFT_SRC=bindings/swift/Sources/TabletBindings/TabletBindings.swift
SWIFT_H=target/bindings/swift/headers/TabletFFI/TabletFFI.h
SWIFT_MAP=target/bindings/swift/headers/TabletFFI/module.modulemap
KOTLIN_SRC=bindings/kotlin/foundation/tablet/bindings/tablet_ffi.kt

# gb_sandbox: sandbox fitur 01 ditambah skrip generasi, rust-toolchain.toml, sumber
# Rust tiruan, cargo tiruan yang menanam generator, dan empat pustaka tiruan yang baru.
gb_sandbox() {
  local t ext
  sandbox_new || return 1
  cp -p "$REPO_ROOT/scripts/generate-bindings.sh" "$SB/repo/scripts/"
  cp "$REPO_ROOT/rust-toolchain.toml" "$SB/repo/rust-toolchain.toml"
  mkdir -p "$SB/repo/crates/core/src" "$SB/repo/crates/tablet-ffi/src"
  echo '// tiruan' > "$SB/repo/crates/core/src/lib.rs"
  echo '// tiruan' > "$SB/repo/crates/tablet-ffi/src/lib.rs"
  echo '# tiruan' > "$SB/repo/crates/tablet-ffi/uniffi.toml"
  touch -t "$OLD" "$SB/repo/crates/core/src/lib.rs" "$SB/repo/crates/tablet-ffi/src/lib.rs" \
    "$SB/repo/crates/tablet-ffi/uniffi.toml"

  _write_stub "$SB/bin/cargo" cargo '
if [ "$1" = build ] && [ "$2" = -p ] && [ "$3" = tablet-uniffi-bindgen ]; then
  if [ "${STUB_CARGO_BUILD_FAIL-}" = 1 ]; then echo "error: tiruan" >&2; exit 1; fi
  mkdir -p target/debug
  cp "$STUB_GEN_SRC" target/debug/uniffi-bindgen
  chmod 755 target/debug/uniffi-bindgen
fi'
  cat > "$SB/generator" <<'EOF'
#!/bin/sh
printf 'uniffi-bindgen\t%s\t%s\n' "$(pwd -P)" "$*" >> "$STUB_LOG"
[ "${STUB_GEN_FAIL-}" = 1 ] && { echo "galat generator tiruan" >&2; exit 1; }
lang=""; out=""; lib=""
while [ $# -gt 0 ]; do
  case "$1" in
    --language) lang="$2"; shift 2 ;;
    --out-dir) out="$2"; shift 2 ;;
    --*) shift ;;
    generate) shift ;;
    *) lib="$1"; shift ;;
  esac
done
body="isi tiruan"
[ "${STUB_GEN_DIFFER-}" = 1 ] && body="isi dari $lib"
mkdir -p "$out"
case "$lang" in
  swift)
    echo "$body" > "$out/TabletBindings.swift"
    echo "$body" > "$out/TabletFFI.h"
    [ "${STUB_GEN_MISSING-}" = 1 ] || echo "module TabletFFI { header \"TabletFFI.h\" }" > "$out/TabletFFI.modulemap"
    ;;
  kotlin)
    mkdir -p "$out/foundation/tablet/bindings"
    [ "${STUB_GEN_MISSING-}" = 1 ] || echo "$body" > "$out/foundation/tablet/bindings/tablet_ffi.kt"
    ;;
esac
exit 0
EOF
  chmod 755 "$SB/generator"

  for t in $IOS $SIM $ARM $X86; do
    case "$t" in *apple*) ext=a ;; *) ext=so ;; esac
    gb_library "$t" "$ext"
  done
  SB_ENV=("STUB_GEN_SRC=$SB/generator")
}

# gb_library <triple> <ekstensi>: pustaka tiruan dan libtablet_ffi.d yang mencantumkan
# kedua sumber Rust tiruan; pustaka lebih baru dari sumbernya.
gb_library() {
  local dir="$SB/repo/target/$1/release"
  mkdir -p "$dir"
  echo "pustaka $1" > "$dir/libtablet_ffi.$2"
  printf '%s: %s %s\n' "$dir/libtablet_ffi.$2" \
    "$SB/repo/crates/core/src/lib.rs" "$SB/repo/crates/tablet-ffi/src/lib.rs" > "$dir/libtablet_ffi.d"
  touch -t "$NEW" "$dir/libtablet_ffi.$2"
}

lib() { printf '%s/repo/target/%s/release/libtablet_ffi.%s' "$SB" "$1" "$2"; }

# gb_calls <alat>: baris calls.log untuk alat itu.
gb_calls() {
  awk -F'\t' -v t="$1" '$1 == t' "$SB/calls.log"
}

# expect_gen_not_called <label>: generator tidak dipanggil dan cargo tidak membangun.
expect_nothing_run() {
  local calls
  calls="$(gb_calls uniffi-bindgen; sb_build_calls)"
  if [ -z "$calls" ]; then
    return 0
  fi
  diag "$1: harapan tanpa build dan tanpa generator, nyata: $(printf '%s' "$calls" | cut -f1,3 | tr '\t\n' ' ;')"
  return 1
}

# expect_fail_with <kata kunci> <label>: keluar 1, baris stderr pertama berawalan
# generate-bindings: dan memuat kata kunci.
expect_fail_with() {
  local ok=0
  expect_eq 1 "$SB_RC" "$2: kode keluar" || ok=1
  expect_contains "$(grep -v -e '^galat generator tiruan$' -e '^error: tiruan$' "$SB/err" | head -n 1)" \
    "generate-bindings: $1" "$2: baris stderr pertama" || ok=1
  return $ok
}

# expect_files <label> <path>...: tepat file ini di bawah bindings/ dan target/bindings/.
expect_files() {
  local label="$1" want got
  shift
  want="$(printf '%s\n' "$@" | LC_ALL=C sort)"
  got="$(cd "$SB/repo" && find bindings target/bindings -type f 2>/dev/null | LC_ALL=C sort)"
  expect_eq "$(printf '%s' "$want" | tr '\n' ' ')" "$(printf '%s' "$got" | tr '\n' ' ')" "$label: file keluaran"
}

case_gb1() {
  local ok=0 gens
  gb_sandbox || return 1
  sb_run generate-bindings.sh swift "$(lib $IOS a)" "$(lib $SIM a)"
  expect_exit_zero "swift dua pustaka" || ok=1
  expect_files "swift dua pustaka" "$SWIFT_SRC" "$SWIFT_H" "$SWIFT_MAP" || ok=1
  expect_contains "$(cat "$SB/repo/$SWIFT_MAP" 2>/dev/null)" 'module TabletFFI' "module.modulemap" || ok=1
  gens="$(gb_calls uniffi-bindgen)"
  expect_eq 2 "$(printf '%s\n' "$gens" | grep -c .)" "jumlah pemanggilan generator" || ok=1
  expect_eq 2 "$(printf '%s\n' "$gens" | grep -c -- 'generate --no-format --metadata-no-deps --language swift --out-dir ')" \
    "pemanggilan generator dengan --no-format --metadata-no-deps" || ok=1
  expect_eq "$SB/repo" "$(printf '%s\n' "$gens" | head -n 1 | cut -f2)" "folder kerja generator" || ok=1
  expect_eq "build -p tablet-uniffi-bindgen --locked --quiet" "$(sb_build_calls | cut -f3 | tr '\n' ';' | sed 's/;$//')" \
    "build cargo yang dipanggil (sekali, hanya generator)" || ok=1
  expect_eq "generate-bindings: selesai" "$(tail -n 1 "$SB/out")" "baris terakhir stdout" || ok=1
  return $ok
}

case_gb2() {
  local ok=0
  gb_sandbox || return 1
  sb_run generate-bindings.sh kotlin "$(lib $ARM so)" "$(lib $X86 so)"
  expect_exit_zero "kotlin dua pustaka" || ok=1
  expect_files "kotlin dua pustaka" "$KOTLIN_SRC" || ok=1
  expect_eq 2 "$(gb_calls uniffi-bindgen | grep -c -- '--no-format --metadata-no-deps --language kotlin')" \
    "pemanggilan generator kotlin" || ok=1
  return $ok
}

case_gb3() {
  local ok=0
  gb_sandbox || return 1
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_exit_zero "keluaran awal" || return 1
  SB_ENV=("STUB_GEN_SRC=$SB/generator" "STUB_GEN_DIFFER=1")
  sb_run generate-bindings.sh swift "$(lib $IOS a)" "$(lib $SIM a)"
  expect_fail_with "binding berbeda" "pustaka berbeda" || ok=1
  expect_err_has "$IOS/release/libtablet_ffi.a" "pustaka pertama disebut" || ok=1
  expect_err_has "$SIM/release/libtablet_ffi.a" "pustaka berbeda disebut" || ok=1
  expect_eq "isi tiruan" "$(cat "$SB/repo/$SWIFT_SRC" 2>/dev/null)" "keluaran lama tetap" || ok=1
  return $ok
}

case_gb4() {
  local ok=0
  gb_sandbox || return 1
  mkdir -p "$SB/repo/bindings/swift/Sources/TabletBindings" "$SB/repo/target/bindings/swift/headers" \
    "$SB/repo/bindings/kotlin"
  echo '// tiruan' > "$SB/repo/bindings/swift/Package.swift"
  echo x > "$SB/repo/bindings/swift/Sources/TabletBindings/asing.txt"
  echo x > "$SB/repo/target/bindings/swift/headers/asing.h"
  echo x > "$SB/repo/bindings/kotlin/asing.kt"
  sb_run generate-bindings.sh swift "$(lib $SIM a)"
  expect_exit_zero "swift dengan file asing" || ok=1
  [ ! -e "$SB/repo/bindings/swift/Sources/TabletBindings/asing.txt" ] \
    || { diag "bindings/swift/Sources/TabletBindings/asing.txt harapan dihapus"; ok=1; }
  [ ! -e "$SB/repo/target/bindings/swift/headers/asing.h" ] \
    || { diag "target/bindings/swift/headers/asing.h harapan dihapus"; ok=1; }
  [ -f "$SB/repo/bindings/swift/Package.swift" ] \
    || { diag "bindings/swift/Package.swift harapan tetap ada"; ok=1; }
  [ -f "$SB/repo/bindings/kotlin/asing.kt" ] \
    || { diag "bindings/kotlin/asing.kt harapan tidak disentuh run swift"; ok=1; }
  sb_run generate-bindings.sh kotlin "$(lib $ARM so)"
  expect_exit_zero "kotlin dengan file asing" || ok=1
  [ ! -e "$SB/repo/bindings/kotlin/asing.kt" ] \
    || { diag "bindings/kotlin/asing.kt harapan dihapus run kotlin"; ok=1; }
  [ -f "$SB/repo/$SWIFT_SRC" ] || { diag "$SWIFT_SRC harapan tidak disentuh run kotlin"; ok=1; }
  return $ok
}

case_gb5() {
  local ok=0
  gb_sandbox || return 1
  sb_run generate-bindings.sh
  expect_fail_with "bahasa tidak disebut" "tanpa argumen" || ok=1
  expect_nothing_run "tanpa argumen" || ok=1
  sb_run generate-bindings.sh python "$(lib $IOS a)"
  expect_fail_with "bahasa tidak dikenal" "bahasa python" || ok=1
  expect_err_has "python" "bahasa python" || ok=1
  expect_nothing_run "bahasa python" || ok=1
  sb_run generate-bindings.sh swift
  expect_fail_with "pustaka tidak disebut" "swift tanpa pustaka" || ok=1
  expect_err_has "aarch64-apple-ios" "contoh perintah swift" || ok=1
  expect_nothing_run "swift tanpa pustaka" || ok=1
  return $ok
}

case_gb6() {
  local ok=0 outside
  gb_sandbox || return 1
  sb_run generate-bindings.sh swift "$SB/repo/target/$IOS/release/tidak-ada.a"
  expect_fail_with "pustaka tidak ada" "path tidak ada" || ok=1
  expect_err_has "scripts/build-ipados.sh" "path tidak ada" || ok=1
  sb_run generate-bindings.sh swift "$(lib $ARM so)"
  expect_fail_with "pustaka tidak sah" ".so untuk swift" || ok=1
  sb_run generate-bindings.sh kotlin "$(lib $IOS a)"
  expect_fail_with "pustaka tidak sah" ".a untuk kotlin" || ok=1
  mkdir -p "$SB/repo/target/$ARM/release"
  echo x > "$SB/repo/target/$ARM/release/libtablet_ffi.a"
  sb_run generate-bindings.sh swift "$SB/repo/target/$ARM/release/libtablet_ffi.a"
  expect_fail_with "pustaka tidak sah" "triple Android untuk swift" || ok=1
  expect_err_has "$ARM" "triple Android untuk swift" || ok=1
  mkdir -p "$SB/repo/target/$IOS/debug"
  cp "$(lib $IOS a)" "$SB/repo/target/$IOS/debug/libtablet_ffi.a"
  sb_run generate-bindings.sh swift "$SB/repo/target/$IOS/debug/libtablet_ffi.a"
  expect_fail_with "pustaka tidak sah" "folder debug" || ok=1
  outside="$SB/home/target/$IOS/release"
  mkdir -p "$outside"
  cp "$(lib $IOS a)" "$outside/libtablet_ffi.a"
  sb_run generate-bindings.sh swift "$outside/libtablet_ffi.a"
  expect_fail_with "pustaka tidak sah" "di luar target/ repo" || ok=1
  sb_run generate-bindings.sh swift "$(lib $IOS a)" "$(lib $IOS a)"
  expect_fail_with "pustaka ganda" "pustaka disebut dua kali" || ok=1
  expect_nothing_run "argumen pustaka salah" || ok=1
  expect_files "argumen pustaka salah" || ok=1
  return $ok
}

case_gb7() {
  local ok=0 spaced
  gb_sandbox || return 1
  touch -t "$NEWER" "$SB/repo/crates/core/src/lib.rs"
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_fail_with "pustaka basi" "sumber lebih baru" || ok=1
  expect_err_has "crates/core/src/lib.rs" "sumber lebih baru disebut" || ok=1
  expect_err_has "scripts/build-ipados.sh" "skrip build disebut" || ok=1
  expect_nothing_run "sumber lebih baru" || ok=1

  gb_sandbox || return 1
  rm "$SB/repo/target/$ARM/release/libtablet_ffi.d"
  sb_run generate-bindings.sh kotlin "$(lib $ARM so)"
  expect_fail_with "pustaka basi" ".d tidak ada" || ok=1
  expect_err_has "scripts/build-android-tablet.sh" ".d tidak ada" || ok=1

  gb_sandbox || return 1
  touch -t "$NEWER" "$SB/repo/crates/tablet-ffi/uniffi.toml"
  echo x > "$SB/repo/crates/.DS_Store"
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_exit_zero "uniffi.toml dan file non sumber lebih baru tidak membuat basi" || ok=1

  gb_sandbox || return 1
  spaced="$SB/repo/crates/core/src/dengan spasi.rs"
  echo '// tiruan' > "$spaced"
  printf '%s: %s %s\n' "$(lib $SIM a)" "$SB/repo/crates/core/src/lib.rs" \
    "$(printf '%s' "$spaced" | sed 's/ /\\ /g')" > "$SB/repo/target/$SIM/release/libtablet_ffi.d"
  touch -t "$OLD" "$spaced"
  sb_run generate-bindings.sh swift "$(lib $SIM a)"
  expect_exit_zero "path berspasi di .d, sumber lebih tua" || ok=1
  touch -t "$NEWER" "$spaced"
  sb_run generate-bindings.sh swift "$(lib $SIM a)"
  expect_fail_with "pustaka basi" "path berspasi di .d, sumber lebih baru" || ok=1
  expect_err_has "dengan spasi.rs" "path berspasi disebut utuh" || ok=1
  return $ok
}

case_gb8() {
  local ok=0
  gb_sandbox || return 1
  rm "$SB/bin/cargo"
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_fail_with "cargo tidak ditemukan" "tanpa cargo" || ok=1
  expect_err_has "https://rustup.rs" "tanpa cargo" || ok=1

  gb_sandbox || return 1
  SB_ENV=("STUB_GEN_SRC=$SB/generator" "CARGO_TARGET_DIR=$SB/lain")
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_fail_with "folder target-dir" "CARGO_TARGET_DIR" || ok=1
  expect_err_has "unset CARGO_TARGET_DIR" "CARGO_TARGET_DIR" || ok=1
  expect_nothing_run "CARGO_TARGET_DIR" || ok=1
  return $ok
}

case_gb9() {
  local ok=0
  gb_sandbox || return 1
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_exit_zero "keluaran awal" || return 1

  SB_ENV=("STUB_GEN_SRC=$SB/generator" "STUB_CARGO_BUILD_FAIL=1")
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_fail_with "generator gagal dibangun" "cargo build gagal" || ok=1

  SB_ENV=("STUB_GEN_SRC=$SB/generator" "STUB_GEN_FAIL=1")
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_fail_with "generasi gagal" "generator keluar 1" || ok=1
  expect_err_has "$IOS/release/libtablet_ffi.a" "generator keluar 1" || ok=1

  SB_ENV=("STUB_GEN_SRC=$SB/generator" "STUB_GEN_MISSING=1")
  sb_run generate-bindings.sh swift "$(lib $IOS a)"
  expect_fail_with "keluaran generator tidak sesuai" "satu file tidak ditulis" || ok=1
  expect_err_has "uniffi.toml" "satu file tidak ditulis" || ok=1

  expect_files "keluaran lama sesudah tiga kegagalan" "$SWIFT_SRC" "$SWIFT_H" "$SWIFT_MAP" || ok=1
  return $ok
}

case_gb10() {
  local ok=0
  gb_sandbox || return 1
  sb_run generate-bindings.sh --help
  expect_exit_zero "--help" || ok=1
  expect_contains "$(sb_out)" "Pemakaian:" "--help stdout" || ok=1
  expect_nothing_run "--help" || ok=1
  return $ok
}

case_gb11() {
  local ok=0
  gb_sandbox || return 1
  sb_run generate-bindings.sh swift "../repo/target/$SIM/release/libtablet_ffi.a"
  expect_exit_zero "path relatif terhadap folder pemanggil" || ok=1
  expect_files "path relatif" "$SWIFT_SRC" "$SWIFT_H" "$SWIFT_MAP" || ok=1
  return $ok
}

check GB1 AC-4,AC-6 "swift dari dua pustaka menulis tiga file lewat generator workspace" case_gb1
check GB2 AC-5,AC-6 "kotlin dari dua pustaka menulis satu file" case_gb2
check GB3 AC-6 "hasil berbeda antar pustaka gagal tanpa mengubah keluaran lama" case_gb3
check GB4 AC-6 "keluaran lama bahasa itu saja yang diganti" case_gb4
check GB5 AC-7 "bahasa dan pustaka yang tidak disebut ditolak sebelum build" case_gb5
check GB6 AC-7 "pustaka yang tidak ada, tidak sah, atau ganda ditolak" case_gb6
check GB7 AC-7 "pustaka basi menurut libtablet_ffi.d ditolak" case_gb7
check GB8 AC-7 "cargo hilang dan CARGO_TARGET_DIR ditolak" case_gb8
check GB9 AC-7 "kegagalan build generator dan generasi tidak mengubah keluaran" case_gb9
check GB10 AC-7 "--help keluar 0 tanpa build" case_gb10
check GB11 AC-7 "path relatif diartikan terhadap folder pemanggil" case_gb11
finish
