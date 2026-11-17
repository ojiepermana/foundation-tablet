#!/usr/bin/env bash
# Membangun pustaka Rust untuk target Apple dan aplikasi iPad.
#
# Pemakaian: scripts/build-ipados.sh [--simulator] [--device]
#   --simulator  aarch64-apple-ios-sim, lalu Tablet.app Debug untuk simulator iPad generik
#   --device     aarch64-apple-ios, lalu Tablet.app Release untuk iPad generik tanpa tanda tangan
#   tanpa argumen: keduanya
#
# Di dalam repo skrip ini hanya menulis ke target/, hasil generasi bindings/swift/,
# dan apps/ipados/build/.
# Kontraknya ada di docs/specs/0001-arsitektur-dan-build-awal/index.md bagian "Perintah repo".
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

PROJECT="apps/ipados/Tablet.xcodeproj"
XCCONFIG="apps/ipados/Config/Base.xcconfig"
DERIVED_DATA="apps/ipados/build/DerivedData"

fail() {
  printf 'build-ipados: %s\n' "$1" >&2
  shift
  for line in "$@"; do
    printf '  %s\n' "$line" >&2
  done
  exit 1
}

warn() {
  printf 'build-ipados: peringatan: %s\n' "$1" >&2
}

usage() {
  printf 'Pemakaian: %s [--simulator] [--device]\n' "$0"
  printf 'Tanpa argumen: simulator dan perangkat.\n'
}

build_simulator=0
build_device=0
for arg in "$@"; do
  case "$arg" in
    --simulator) build_simulator=1 ;;
    --device) build_device=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; fail "argumen tidak dikenal: $arg" ;;
  esac
done
if [[ $build_simulator -eq 0 && $build_device -eq 0 ]]; then
  build_simulator=1
  build_device=1
fi

triples=()
[[ $build_simulator -eq 1 ]] && triples+=("aarch64-apple-ios-sim")
[[ $build_device -eq 1 ]] && triples+=("aarch64-apple-ios")

# 1. Prasyarat.
command -v cargo >/dev/null 2>&1 \
  || fail "cargo tidak ditemukan di PATH." \
    "Pasang rustup dari https://rustup.rs, buka terminal baru, lalu jalankan 'rustup toolchain install' dari akar repo."
command -v rustup >/dev/null 2>&1 \
  || fail "rustup tidak ditemukan di PATH." \
    "Pasang rustup dari https://rustup.rs supaya toolchain dan target dibaca dari rust-toolchain.toml."

developer_dir="$(xcode-select -p 2>/dev/null)" \
  || fail "xcode-select tidak menemukan folder developer." \
    "Pasang Xcode 27.1, lalu jalankan: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
if [[ -n "${DEVELOPER_DIR:-}" && ! -d "$DEVELOPER_DIR" ]]; then
  fail "DEVELOPER_DIR menunjuk folder yang tidak ada: $DEVELOPER_DIR" \
    "Hapus variabel itu (unset DEVELOPER_DIR) atau arahkan ke folder Developer di dalam Xcode 27.1, misalnya /Applications/Xcode.app/Contents/Developer."
fi
if [[ ! -d "$developer_dir" ]]; then
  fail "folder developer tidak ada: $developer_dir" \
    "Pasang Xcode 27.1, lalu jalankan: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi
case "$developer_dir" in
  */CommandLineTools*)
    fail "folder developer aktif adalah Command Line Tools ($developer_dir), bukan Xcode." \
      "Pasang Xcode 27.1, lalu jalankan: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    ;;
esac

xcode_version_output="$(xcodebuild -version 2>/dev/null)" \
  || fail "xcodebuild -version gagal dengan folder developer $developer_dir." \
    "Buka Xcode sekali untuk menyelesaikan pemasangan dan menerima lisensi (sudo xcodebuild -license accept), lalu ulangi."
xcode_version="$(printf '%s\n' "$xcode_version_output" | sed -n 's/^Xcode \([0-9][0-9.]*\).*/\1/p' | head -n 1)"
[[ -n "$xcode_version" ]] \
  || fail "versi Xcode tidak terbaca dari 'xcodebuild -version'." \
    "Pastikan Xcode 27.1 terpasang dan terpilih lewat xcode-select."
if [[ "${xcode_version%%.*}" != "27" ]]; then
  fail "repo ini butuh Xcode 27, yang aktif Xcode $xcode_version." \
    "Pasang Xcode 27.1, lalu jalankan: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi
expected_xcode="$(tr -d '[:space:]' < .xcode-version)"
if [[ "$xcode_version" != "$expected_xcode" ]]; then
  warn "repo diverifikasi dengan Xcode $expected_xcode (.xcode-version), yang aktif Xcode $xcode_version."
fi

installed_targets="$(rustup target list --installed)" \
  || fail "rustup target list --installed gagal." \
    "Jalankan 'rustup toolchain install' dari akar repo untuk memasang toolchain di rust-toolchain.toml."
for triple in "${triples[@]}"; do
  grep -qx "$triple" <<<"$installed_targets" \
    || fail "target Rust $triple belum terpasang." \
      "Jalankan dari akar repo: rustup target add $triple" \
      "atau: rustup toolchain install (memasang semua target di rust-toolchain.toml)."
done

# 2. iPadOS minimum dari satu sumber.
deployment_target="$(sed -n 's/^IPHONEOS_DEPLOYMENT_TARGET *= *\([0-9.]*\).*/\1/p' "$XCCONFIG" | head -n 1)"
[[ -n "$deployment_target" ]] \
  || fail "IPHONEOS_DEPLOYMENT_TARGET tidak ditemukan di $XCCONFIG."
export IPHONEOS_DEPLOYMENT_TARGET="$deployment_target"
printf 'build-ipados: Xcode %s, iPadOS minimum %s\n' "$xcode_version" "$IPHONEOS_DEPLOYMENT_TARGET"

# 3. Pustaka Rust.
for triple in "${triples[@]}"; do
  printf 'build-ipados: cargo build tablet-ffi untuk %s\n' "$triple"
  cargo build -p tablet-ffi --release --locked --target "$triple"
done

# 4. Binding dan XCFramework hanya dari slice yang dibangun pada run ini.
libraries=()
xcframework_args=()
for triple in "${triples[@]}"; do
  library="target/$triple/release/libtablet_ffi.a"
  libraries+=("$library")
  xcframework_args+=( -library "$library" -headers target/bindings/swift/headers )
done
scripts/generate-bindings.sh swift "${libraries[@]}"
rm -rf bindings/swift/TabletFFI.xcframework
xcodebuild -create-xcframework "${xcframework_args[@]}" \
  -output bindings/swift/TabletFFI.xcframework

# 5. Simulator.
if [[ $build_simulator -eq 1 ]]; then
  printf 'build-ipados: xcodebuild Debug untuk simulator iPad generik\n'
  xcodebuild -project "$PROJECT" -scheme Tablet -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA" ARCHS=arm64 build
fi

# 6. Perangkat, tanpa tanda tangan kode.
if [[ $build_device -eq 1 ]]; then
  printf 'build-ipados: xcodebuild Release untuk iPad generik tanpa tanda tangan\n'
  xcodebuild -project "$PROJECT" -scheme Tablet -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA" CODE_SIGNING_ALLOWED=NO build
fi

printf 'build-ipados: selesai\n'
