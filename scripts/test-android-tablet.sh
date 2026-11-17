#!/usr/bin/env bash
# Menjalankan tes Compose pada satu tablet Android yang sudah menyala.
# Pemakaian: scripts/test-android-tablet.sh <adb-serial>
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() {
  printf 'test-android-tablet: %s\n' "$1" >&2
  exit 1
}

usage() {
  printf 'Pemakaian: %s <adb-serial>\n' "$0"
  printf 'Bangun dahulu dengan scripts/build-android-tablet.sh; nyalakan tablet/emulator secara terpisah.\n'
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
esac
[[ $# -eq 1 && -n "$1" ]] || { usage >&2; fail "sebut tepat satu serial tablet dari adb devices."; }
export ANDROID_SERIAL="$1"

ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME JAVA_HOME
adb="$ANDROID_HOME/platform-tools/adb"
[[ -x "$adb" ]] || fail "adb tidak ditemukan: $adb; set ANDROID_HOME ke Android SDK."
[[ -x "$JAVA_HOME/bin/java" ]] || fail "java tidak ditemukan di JAVA_HOME: $JAVA_HOME."
[[ "$("$adb" -s "$ANDROID_SERIAL" get-state 2>/dev/null)" == "device" ]] \
  || fail "tablet $ANDROID_SERIAL tidak tersambung atau belum diotorisasi."

# Gunakan konfigurasi aktual (termasuk density override), bukan nama profil emulator.
configuration="$("$adb" -s "$ANDROID_SERIAL" shell am get-config)"
smallest_width="$(printf '%s\n' "$configuration" | sed -n 's/.*-sw\([0-9][0-9]*\)dp.*/\1/p' | head -n 1)"
[[ -n "$smallest_width" ]] || fail "smallest width tablet $ANDROID_SERIAL tidak dapat dibaca dari am get-config."
[[ "$smallest_width" -ge 600 ]] || fail "target $ANDROID_SERIAL bukan tablet: smallest width ${smallest_width}dp (perlu >=600dp)."

printf 'test-android-tablet: target %s, smallest width %sdp\n' "$ANDROID_SERIAL" "$smallest_width"
printf 'test-android-tablet: revision %s\n' "$(git rev-parse HEAD)"
(cd apps/android-tablet && ./gradlew :app:connectedDebugAndroidTest)
printf 'test-android-tablet: selesai; laporan apps/android-tablet/app/build/reports/androidTests/connected/debug/\n'
