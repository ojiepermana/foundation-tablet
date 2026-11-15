# Grup artifacts: hasil build iPad yang nyata (AC-3, AC-5, AC-6, AC-11).
# Butuh macOS dan scripts/build-ipados.sh tanpa argumen lebih dulu. Hanya membaca.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

PRODUCTS="apps/ipados/build/DerivedData/Build/Products"
FIX="jalankan scripts/build-ipados.sh (tanpa argumen) lebih dulu"

# need_tool <alat>: gagal dengan pesan bila alat tidak ada.
need_tool() {
  if command -v "$1" > /dev/null 2>&1; then
    return 0
  fi
  diag "$1 tidak ditemukan; grup artifacts/ipados butuh macOS dengan Xcode"
  return 1
}

# app_checks <path Tablet.app> <label>: tiga pemeriksaan AC-5/AC-6.
app_checks() {
  local app="$1" label="$2" ok=0 archs min family expected
  if [ ! -d "$app" ]; then
    diag "$label: $app tidak ada; $FIX"
    return 1
  fi
  need_tool lipo || return 1
  need_tool plutil || return 1
  archs="$(lipo -archs "$app/Tablet" 2>&1)"
  expect_eq "arm64" "$archs" "$label: lipo -archs Tablet.app/Tablet" || ok=1
  expected="$(src_deployment_target)"
  expect_nonempty "$expected" "IPHONEOS_DEPLOYMENT_TARGET di Base.xcconfig" || ok=1
  min="$(plutil -extract MinimumOSVersion raw "$app/Info.plist" 2>&1)"
  expect_eq "$expected" "$min" "$label: MinimumOSVersion" || ok=1
  family="$(plutil -extract UIDeviceFamily json -o - "$app/Info.plist" 2>&1)"
  expect_eq "[2]" "$family" "$label: UIDeviceFamily" || ok=1
  return $ok
}

case_hi1() {
  local ok=0 triple lib
  for triple in aarch64-apple-ios aarch64-apple-ios-sim; do
    lib="target/$triple/release/libtablet_ffi.a"
    if [ ! -s "$lib" ]; then
      diag "$lib tidak ada atau kosong; $FIX"
      ok=1
    fi
  done
  return $ok
}

case_hi2() {
  app_checks "$PRODUCTS/Debug-iphonesimulator/Tablet.app" "simulator Debug"
}

case_hi3() {
  local ok=0 app="$PRODUCTS/Release-iphoneos/Tablet.app" out rc
  app_checks "$app" "perangkat Release" || ok=1
  [ -d "$app" ] || return 1
  need_tool codesign || return 1
  out="$(codesign -dv "$app" 2>&1)"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    diag "codesign -dv harapan keluar bukan 0 (app tanpa tanda tangan), nyata 0: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-300)"
    ok=1
  fi
  expect_contains "$out" "not signed" "codesign -dv" || ok=1
  return $ok
}

case_hi4() {
  local status
  status="$(git status --short)"
  if [ -z "$status" ]; then
    return 0
  fi
  diag "git status --short harapan kosong, nyata: $(printf '%s' "$status" | tr '\n' ';')"
  return 1
}

check HI1 AC-3 "pustaka Rust iPad perangkat dan simulator ada" case_hi1
check HI2 AC-5 "Tablet.app simulator arm64, OS minimum, khusus iPad" case_hi2
check HI3 AC-6 "Tablet.app perangkat Release tanpa tanda tangan" case_hi3
check HI4 AC-11 "pohon kerja bersih sesudah build" case_hi4
finish
