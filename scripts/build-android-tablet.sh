#!/usr/bin/env bash
# Membangun pustaka Rust untuk ABI Android lalu APK debug aplikasi tablet.
#
# Pemakaian: scripts/build-android-tablet.sh
#
# Variabel lingkungan:
#   ANDROID_HOME  folder Android SDK; bila tidak diset, skrip mencoba ~/Library/Android/sdk
#   JAVA_HOME     JDK 25; bila tidak diset, skrip mencoba JBR Android Studio
#
# Di dalam repo skrip ini hanya menulis ke target/ dan folder build/, .gradle/, serta .kotlin/ milik Gradle.
# Kontraknya ada di docs/specs/0001-arsitektur-dan-build-awal/index.md bagian "Perintah repo".
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

GRADLE_ROOT="apps/android-tablet"
CATALOG="$GRADLE_ROOT/gradle/libs.versions.toml"
GRADLE_PROPERTIES="$GRADLE_ROOT/gradle.properties"
EXPECTED_JAVA_MAJOR="25"
EXPECTED_CARGO_NDK="4.1.2"
DEFAULT_ANDROID_HOME="$HOME/Library/Android/sdk"
DEFAULT_JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

fail() {
  printf 'build-android-tablet: %s\n' "$1" >&2
  shift
  for line in "$@"; do
    printf '  %s\n' "$line" >&2
  done
  exit 1
}

usage() {
  printf 'Pemakaian: %s\n' "$0"
  printf 'Membangun libtablet_ffi.so untuk setiap ABI di tablet.abis, lalu app-debug.apk.\n'
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
    *) usage >&2; fail "argumen tidak dikenal: $arg" ;;
  esac
done

# Membaca nilai berkutip dari katalog versi, misalnya: minSdk = "29".
catalog_value() {
  local value
  value="$(sed -n "s/^$1 *= *\"\([^\"]*\)\".*/\1/p" "$CATALOG" | head -n 1)"
  [[ -n "$value" ]] || fail "nilai $1 tidak ditemukan di $CATALOG."
  printf '%s' "$value"
}

min_sdk="$(catalog_value minSdk)"
compile_sdk="$(catalog_value compileSdk)"
ndk_version="$(catalog_value ndk)"
abis_line="$(sed -n 's/^tablet\.abis=//p' "$GRADLE_PROPERTIES" | head -n 1)"
[[ -n "$abis_line" ]] || fail "tablet.abis tidak ditemukan di $GRADLE_PROPERTIES."
IFS=',' read -r -a abis <<<"$abis_line"

# 1. Prasyarat.
command -v cargo >/dev/null 2>&1 \
  || fail "cargo tidak ditemukan di PATH." \
    "Pasang rustup dari https://rustup.rs, buka terminal baru, lalu jalankan 'rustup toolchain install' dari akar repo."
command -v rustup >/dev/null 2>&1 \
  || fail "rustup tidak ditemukan di PATH." \
    "Pasang rustup dari https://rustup.rs supaya toolchain dan target dibaca dari rust-toolchain.toml."

# Android SDK.
if [[ -z "${ANDROID_HOME:-}" ]]; then
  ANDROID_HOME="$DEFAULT_ANDROID_HOME"
fi
sdk_fix="Pasang Android SDK (misalnya lewat Android Studio, Settings > Languages & Frameworks > Android SDK), lalu set ANDROID_HOME ke foldernya, misalnya: export ANDROID_HOME=\"\$HOME/Library/Android/sdk\""
[[ -d "$ANDROID_HOME" ]] \
  || fail "folder Android SDK tidak ada: $ANDROID_HOME" "$sdk_fix"
if [[ ! -d "$ANDROID_HOME/platforms/android-$compile_sdk.0" && ! -d "$ANDROID_HOME/platforms/android-$compile_sdk" ]]; then
  fail "platform Android $compile_sdk tidak ada di $ANDROID_HOME/platforms (dicari android-$compile_sdk.0 dan android-$compile_sdk)." \
    "Pasang dengan: \"\$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager\" \"platforms;android-$compile_sdk.0\"" \
    "atau lewat SDK Manager di Android Studio. Bila SDK ada di folder lain, set ANDROID_HOME ke folder itu."
fi
ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$ndk_version"
[[ -d "$ANDROID_NDK_HOME" ]] \
  || fail "NDK $ndk_version tidak ada: $ANDROID_NDK_HOME" \
    "Pasang dengan: \"\$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager\" \"ndk;$ndk_version\"" \
    "atau lewat SDK Manager di Android Studio (tab SDK Tools, centang Show Package Details)."
export ANDROID_HOME ANDROID_NDK_HOME

# JDK. Jangan memanggil java dari PATH: di macOS itu bisa berupa stub.
if [[ -z "${JAVA_HOME:-}" ]]; then
  JAVA_HOME="$DEFAULT_JAVA_HOME"
fi
jdk_fix="Pasang JDK $EXPECTED_JAVA_MAJOR (JBR bawaan Android Studio sudah cukup), lalu set JAVA_HOME ke foldernya, misalnya: export JAVA_HOME=\"$DEFAULT_JAVA_HOME\""
[[ -x "$JAVA_HOME/bin/java" ]] \
  || fail "java tidak ditemukan di JAVA_HOME: $JAVA_HOME/bin/java" "$jdk_fix"
java_version_output="$("$JAVA_HOME/bin/java" -version 2>&1)" \
  || fail "\"$JAVA_HOME/bin/java\" -version gagal." "$jdk_fix"
grep -q "version \"$EXPECTED_JAVA_MAJOR\." <<<"$java_version_output" \
  || fail "repo ini butuh JDK $EXPECTED_JAVA_MAJOR, JAVA_HOME menunjuk: $(head -n 1 <<<"$java_version_output")" "$jdk_fix"
export JAVA_HOME

# cargo-ndk.
cargo_ndk_fix="Pasang dengan: cargo install cargo-ndk --version $EXPECTED_CARGO_NDK --locked"
cargo_ndk_output="$(cargo ndk --version 2>/dev/null)" \
  || fail "cargo-ndk tidak ditemukan." "$cargo_ndk_fix"
cargo_ndk_version="$(sed -n 's/^cargo-ndk \([0-9][0-9.]*\).*/\1/p' <<<"$cargo_ndk_output" | head -n 1)"
[[ "$cargo_ndk_version" == "$EXPECTED_CARGO_NDK" ]] \
  || fail "repo ini butuh cargo-ndk $EXPECTED_CARGO_NDK, yang terpasang: ${cargo_ndk_output:-tidak terbaca}" "$cargo_ndk_fix"

# Target Rust untuk tiap ABI.
installed_targets="$(rustup target list --installed)" \
  || fail "rustup target list --installed gagal." \
    "Jalankan 'rustup toolchain install' dari akar repo untuk memasang toolchain di rust-toolchain.toml."
ndk_targets=()
for abi in "${abis[@]}"; do
  case "$abi" in
    arm64-v8a) triple="aarch64-linux-android" ;;
    x86_64) triple="x86_64-linux-android" ;;
    *) fail "ABI $abi di $GRADLE_PROPERTIES tidak ada di matriks dukungan (arm64-v8a, x86_64)." ;;
  esac
  grep -qx "$triple" <<<"$installed_targets" \
    || fail "target Rust $triple (ABI $abi) belum terpasang." \
      "Jalankan dari akar repo: rustup target add $triple" \
      "atau: rustup toolchain install (memasang semua target di rust-toolchain.toml)."
  ndk_targets+=(-t "$abi")
done

printf 'build-android-tablet: SDK %s, NDK %s, minSdk %s, ABI %s\n' "$ANDROID_HOME" "$ndk_version" "$min_sdk" "$abis_line"
printf 'build-android-tablet: %s\n' "$(head -n 1 <<<"$java_version_output")"

# 2. Pustaka Rust.
printf 'build-android-tablet: cargo ndk build tablet-ffi untuk %s\n' "$abis_line"
CARGO_NDK_PLATFORM="$min_sdk" cargo ndk "${ndk_targets[@]}" build -p tablet-ffi --release --locked

# 3. APK debug.
printf 'build-android-tablet: gradlew :app:assembleDebug\n'
(cd "$GRADLE_ROOT" && ./gradlew :app:assembleDebug)

printf 'build-android-tablet: selesai\n'
