#!/usr/bin/env bash
# Menjalankan XCUITest pada simulator iPad yang dipilih, tanpa memanggil Cargo.
# Pemakaian: scripts/test-ipados.sh <UDID>
# Alternatif: IPADOS_SIMULATOR_UDID=<UDID> scripts/test-ipados.sh
# Bangun binding lebih dulu: scripts/build-ipados.sh --simulator
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

usage() {
  printf 'Pemakaian: %s <UDID simulator iPad>\n' "$0"
  printf 'Alternatif: IPADOS_SIMULATOR_UDID=<UDID> %s\n' "$0"
}

fail() {
  printf 'test-ipados: %s\n' "$1" >&2
  exit 1
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
[[ $# -le 1 ]] || { usage >&2; fail 'terlalu banyak argumen.'; }
simulator_udid="${1:-${IPADOS_SIMULATOR_UDID:-}}"
[[ -n "$simulator_udid" ]] || { usage >&2; fail 'UDID simulator wajib disebut.'; }
[[ "$simulator_udid" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]] \
  || fail "UDID simulator tidak sah: $simulator_udid"
[[ -f bindings/swift/Sources/TabletBindings/TabletBindings.swift && -d bindings/swift/TabletFFI.xcframework ]] \
  || fail 'binding belum tersedia; jalankan scripts/build-ipados.sh --simulator.'

result_bundle="apps/ipados/build/TestResults/Tablet-$(date -u +%Y%m%dT%H%M%SZ)-$$.xcresult"
mkdir -p apps/ipados/build/TestResults
printf 'test-ipados: simulator %s\n' "$simulator_udid"
printf 'test-ipados: hasil %s\n' "$result_bundle"
xcodebuild -project apps/ipados/Tablet.xcodeproj -scheme Tablet -configuration Debug \
  -destination "platform=iOS Simulator,id=$simulator_udid" \
  -derivedDataPath apps/ipados/build/DerivedData \
  -resultBundlePath "$result_bundle" \
  -parallel-testing-enabled NO ARCHS=arm64 test
printf 'test-ipados: selesai\n'
