#!/usr/bin/env bash
# Menghasilkan binding Swift atau Kotlin dari pustaka tablet-ffi yang sudah dibangun.
#
# Pemakaian: scripts/generate-bindings.sh <swift|kotlin> <pustaka> [<pustaka>...]
#   swift   pustaka target/<aarch64-apple-ios|aarch64-apple-ios-sim>/release/libtablet_ffi.a
#   kotlin  pustaka target/<aarch64-linux-android|x86_64-linux-android>/release/libtablet_ffi.so
#
# Bangun pustakanya lebih dulu dengan scripts/build-ipados.sh atau
# scripts/build-android-tablet.sh. Skrip ini tidak membangun tablet-ffi.
# Binding dihasilkan dari tiap pustaka dan hanya ditulis bila semuanya identik.
#
# Di dalam repo skrip ini hanya menulis ke bindings/swift/Sources/TabletBindings/,
# target/bindings/swift/ (swift), bindings/kotlin/ (kotlin), dan target/debug/.
# Kontraknya ada di docs/specs/0002-kontrak-rust-kedua-aplikasi/index.md bagian
# "Kontrak skrip scripts/generate-bindings.sh".
set -euo pipefail

caller_dir="$(pwd -P)"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
root="$(pwd -P)"

GENERATOR="target/debug/uniffi-bindgen"

fail() {
  printf 'generate-bindings: %s\n' "$1" >&2
  shift
  for line in "$@"; do
    printf '  %s\n' "$line" >&2
  done
  exit 1
}

usage() {
  printf 'Pemakaian: %s <swift|kotlin> <pustaka> [<pustaka>...]\n' "$0"
  printf '  swift   target/<aarch64-apple-ios|aarch64-apple-ios-sim>/release/libtablet_ffi.a\n'
  printf '  kotlin  target/<aarch64-linux-android|x86_64-linux-android>/release/libtablet_ffi.so\n'
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
  esac
done

# 1. Lingkungan.
command -v cargo >/dev/null 2>&1 \
  || fail "cargo tidak ditemukan di PATH." \
    "Pasang rustup dari https://rustup.rs, buka terminal baru, lalu jalankan 'rustup toolchain install' dari akar repo."

if [[ -n "${CARGO_TARGET_DIR:-}" || -n "${CARGO_BUILD_TARGET_DIR:-}" ]]; then
  fail "folder target-dir Cargo diubah lewat CARGO_TARGET_DIR atau CARGO_BUILD_TARGET_DIR; skrip ini hanya memakai target/ di akar repo." \
    "Jalankan: unset CARGO_TARGET_DIR CARGO_BUILD_TARGET_DIR"
fi

# 2. Argumen.
if [[ $# -eq 0 ]]; then
  fail "bahasa tidak disebut." "Sebut swift atau kotlin sebagai argumen pertama." \
    "Pemakaian: $0 <swift|kotlin> <pustaka> [<pustaka>...]"
fi

language="$1"
shift
case "$language" in
  swift)
    extension="a"
    build_script="scripts/build-ipados.sh"
    example="$0 swift target/aarch64-apple-ios/release/libtablet_ffi.a target/aarch64-apple-ios-sim/release/libtablet_ffi.a"
    ;;
  kotlin)
    extension="so"
    build_script="scripts/build-android-tablet.sh"
    example="$0 kotlin target/aarch64-linux-android/release/libtablet_ffi.so target/x86_64-linux-android/release/libtablet_ffi.so"
    ;;
  *)
    fail "bahasa tidak dikenal: $language" "Pakai swift atau kotlin." \
      "Pemakaian: $0 <swift|kotlin> <pustaka> [<pustaka>...]"
    ;;
esac

if [[ $# -eq 0 ]]; then
  fail "pustaka tidak disebut untuk $language." "Contoh: $example"
fi

# Target yang sah: daftar targets di rust-toolchain.toml yang cocok dengan bahasa.
toolchain_targets="$(awk '/^targets *= *\[/ { f = 1 } f { print } f && /\]/ { exit }' rust-toolchain.toml \
  | grep -o '"[^"]*"' | tr -d '"')"
target_allowed() {
  local triple="$1"
  case "$language:$triple" in
    swift:aarch64-apple-ios | swift:aarch64-apple-ios-sim) ;;
    kotlin:aarch64-linux-android | kotlin:x86_64-linux-android) ;;
    *) return 1 ;;
  esac
  printf '%s\n' "$toolchain_targets" | grep -qx "$triple"
}

libraries=()
for raw in "$@"; do
  case "$raw" in
    /*) candidate="$raw" ;;
    *) candidate="$caller_dir/$raw" ;;
  esac
  [[ -e "$candidate" ]] \
    || fail "pustaka tidak ada: $raw" "Bangun dulu dengan $build_script, lalu jalankan skrip ini lagi."
  [[ -f "$candidate" ]] \
    || fail "pustaka tidak sah: $raw" "Path harus berupa file libtablet_ffi.$extension, bukan folder."
  library="$(cd "$(dirname "$candidate")" && pwd -P)/$(basename "$candidate")"

  name="$(basename "$library")"
  [[ "$name" == "libtablet_ffi.$extension" ]] \
    || fail "pustaka tidak sah: $raw" \
      "Untuk $language nama file harus libtablet_ffi.$extension, nyata $name."
  release_dir="$(dirname "$library")"
  triple_dir="$(dirname "$release_dir")"
  triple="$(basename "$triple_dir")"
  if [[ "$(basename "$release_dir")" != "release" || "$(dirname "$triple_dir")" != "$root/target" ]]; then
    fail "pustaka tidak sah: $raw" \
      "Pustaka harus ada di $root/target/<triple>/release/, nyata di $release_dir."
  fi
  target_allowed "$triple" \
    || fail "pustaka tidak sah: $raw" \
      "Target $triple bukan target $language di rust-toolchain.toml (swift: aarch64-apple-ios, aarch64-apple-ios-sim; kotlin: aarch64-linux-android, x86_64-linux-android)."

  for seen in ${libraries[@]+"${libraries[@]}"}; do
    [[ "$seen" != "$library" ]] \
      || fail "pustaka ganda: $raw" "Sebut tiap pustaka sekali."
  done
  libraries+=("$library")
done

# 3. Pemeriksaan basi: file .rs pada dep info Cargo (libtablet_ffi.d) tidak boleh
# lebih baru dari pustaka. Spasi di path ditulis "\ " oleh Cargo.
SPACE_MARK="$(printf '\001')"
for library in "${libraries[@]}"; do
  depinfo="$(dirname "$library")/libtablet_ffi.d"
  [[ -f "$depinfo" ]] \
    || fail "pustaka basi atau asal usulnya tidak diketahui: $library (libtablet_ffi.d tidak ada)" \
      "Bangun ulang dengan $build_script, lalu jalankan skrip ini lagi."
  newer=""
  while IFS= read -r source; do
    [[ -n "$source" ]] || continue
    source="${source//$SPACE_MARK/ }"
    case "$source" in
      *.rs) ;;
      *) continue ;;
    esac
    if [[ ! -e "$source" || "$source" -nt "$library" ]]; then
      newer="$source"
      break
    fi
  done < <(sed -e 's/^[^:]*: *//' -e "s/\\\\ /$SPACE_MARK/g" "$depinfo" | tr ' ' '\n')
  [[ -z "$newer" ]] \
    || fail "pustaka basi: $library lebih tua dari $newer" \
      "Bangun ulang dengan $build_script, lalu jalankan skrip ini lagi."
done

# 4. Generator dari workspace, versi uniffi sama dengan runtime.
cargo build -p tablet-uniffi-bindgen --locked --quiet \
  || fail "generator gagal dibangun." \
    "Jalankan 'cargo build -p tablet-uniffi-bindgen --locked' dari akar repo untuk melihat galatnya."
[[ -x "$GENERATOR" ]] \
  || fail "generator tidak ada di $GENERATOR; konfigurasi Cargo memakai build.target-dir lain." \
    "Hapus build.target-dir dari konfigurasi Cargo, lalu jalankan skrip ini lagi."

# 5. Generasi per pustaka ke folder sementara, lalu bandingkan dengan pustaka pertama.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/generate-bindings.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

n=0
for library in "${libraries[@]}"; do
  n=$((n + 1))
  "$GENERATOR" generate --no-format --metadata-no-deps --language "$language" \
    --out-dir "$tmp/$n" "$library" \
    || fail "generasi gagal untuk $library." "Keluaran generator ada di atas pesan ini."
done

n=0
for library in "${libraries[@]}"; do
  n=$((n + 1))
  [[ $n -eq 1 ]] && continue
  diff -r "$tmp/1" "$tmp/$n" >/dev/null 2>&1 \
    || fail "binding berbeda: ${libraries[0]} dan $library menghasilkan binding yang tidak sama." \
      "Kontrak tidak boleh bergantung pada target; periksa cfg per target di crates/."
done

case "$language" in
  swift) expected="TabletBindings.swift
TabletFFI.h
TabletFFI.modulemap" ;;
  kotlin) expected="foundation/tablet/bindings/tablet_ffi.kt" ;;
esac
actual="$(cd "$tmp/1" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)"
complete=1
[[ "$actual" == "$expected" ]] || complete=0
while IFS= read -r file; do
  [[ -s "$tmp/1/$file" ]] || complete=0
done <<< "$expected"
[[ $complete -eq 1 ]] \
  || fail "keluaran generator tidak sesuai untuk $language: $(printf '%s' "$actual" | tr '\n' ' ')" \
    "Yang diharapkan: $(printf '%s' "$expected" | tr '\n' ' ')" \
    "Periksa crates/tablet-ffi/uniffi.toml."

# 6 dan 7. Ganti keluaran lama bahasa ini saja.
written=()
case "$language" in
  swift)
    rm -rf bindings/swift/Sources/TabletBindings target/bindings/swift
    mkdir -p bindings/swift/Sources/TabletBindings target/bindings/swift/headers/TabletFFI
    mv "$tmp/1/TabletBindings.swift" bindings/swift/Sources/TabletBindings/TabletBindings.swift
    mv "$tmp/1/TabletFFI.h" target/bindings/swift/headers/TabletFFI/TabletFFI.h
    mv "$tmp/1/TabletFFI.modulemap" target/bindings/swift/headers/TabletFFI/module.modulemap
    written=(
      bindings/swift/Sources/TabletBindings/TabletBindings.swift
      target/bindings/swift/headers/TabletFFI/TabletFFI.h
      target/bindings/swift/headers/TabletFFI/module.modulemap
    )
    ;;
  kotlin)
    rm -rf bindings/kotlin
    mkdir -p bindings/kotlin
    mv "$tmp/1/foundation" bindings/kotlin/foundation
    written=(bindings/kotlin/foundation/tablet/bindings/tablet_ffi.kt)
    ;;
esac

# 8. Laporan.
printf 'generate-bindings: %s dari %d pustaka\n' "$language" "${#libraries[@]}"
for file in "${written[@]}"; do
  printf '  %s\n' "$file"
done
printf 'generate-bindings: selesai\n'
