#!/usr/bin/env bash
# settings: keluaran JDK untuk setup-java; prepare: SDK/AVD; boot: emulator CI.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { printf 'ci-android-tablet: %s\n' "$*" >&2; exit 1; }
catalog="apps/android-tablet/gradle/libs.versions.toml"
catalog_value() {
  local value
  value="$(sed -n "s/^$1 *= *\"\([^\"]*\)\".*/\1/p" "$catalog")"
  [[ -n "$value" ]] || fail "nilai $1 tidak ditemukan di $catalog."
  printf '%s' "$value"
}
java_version="$(sed -n 's/^toolchainVersion=//p' apps/android-tablet/gradle/gradle-daemon-jvm.properties)"
[[ "$java_version" =~ ^[0-9]+$ ]] || fail 'toolchainVersion JDK tidak terbaca.'

case "${1:-}" in
  settings)
    : "${GITHUB_OUTPUT:?settings memerlukan GITHUB_OUTPUT.}"
    printf 'java-version=%s\n' "$java_version" >> "$GITHUB_OUTPUT"
    exit 0
    ;;
  prepare | boot) ;;
  *) fail 'Pemakaian: scripts/ci-prepare-android-tablet.sh settings|prepare|boot' ;;
esac
: "${GITHUB_ENV:?Skrip persiapan ini memerlukan GITHUB_ENV dari runner CI.}"
: "${GITHUB_PATH:?Skrip persiapan ini memerlukan GITHUB_PATH dari runner CI.}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[[ -d "$ANDROID_HOME" ]] || fail 'ANDROID_HOME tidak menunjuk Android SDK runner.'
export ANDROID_SDK_ROOT="$ANDROID_HOME"
sdk_bin="$ANDROID_HOME/cmdline-tools/latest/bin"
[[ -x "$sdk_bin/sdkmanager" ]] || fail "sdkmanager tidak ada di $sdk_bin."
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$sdk_bin:$PATH"
mkdir -p target/ci/android-tablet

if [[ "$1" == prepare ]]; then
  compile_sdk="$(catalog_value compileSdk)"
  target_sdk="$(catalog_value targetSdk)"
  ndk_version="$(catalog_value ndk)"
  cargo_ndk="$(sed -n 's/^EXPECTED_CARGO_NDK="\([^"]*\)"/\1/p' scripts/build-android-tablet.sh)"
  [[ -n "$cargo_ndk" ]] || fail 'EXPECTED_CARGO_NDK tidak ditemukan di skrip build Android.'
  printf 'ci-android-tablet: JDK %s, compileSdk %s, targetSdk %s, NDK %s, cargo-ndk %s\n' \
    "$java_version" "$compile_sdk" "$target_sdk" "$ndk_version" "$cargo_ndk"
  java -version
  cargo install cargo-ndk --version "$cargo_ndk" --locked

  sudo apt-get update
  sudo apt-get install -y libpulse0 libnss3 libx11-6 libxcb1 libxcomposite1 \
    libxcursor1 libxdamage1 libxi6 libxtst6 libgl1 libasound2t64
  [[ -e /dev/kvm ]] || fail '/dev/kvm tidak tersedia pada runner Linux ini.'
  printf '%s\n' 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' \
    | sudo tee /etc/udev/rules.d/99-kvm4all.rules
  sudo udevadm control --reload-rules
  sudo udevadm trigger --name-match=kvm
  sudo udevadm settle
  [[ -r /dev/kvm && -w /dev/kvm ]] || fail 'runner tidak dapat memakai /dev/kvm.'

  # yes boleh mendapat SIGPIPE; hanya exit code sdkmanager menentukan hasil lisensi.
  set +e
  yes | sdkmanager --licenses
  license_status="${PIPESTATUS[1]}"
  set -e
  [[ "$license_status" -eq 0 ]] || fail 'penerimaan lisensi SDK gagal.'
  sdkmanager --list > target/ci/android-tablet/sdk-packages.txt
  platform="platforms;android-$compile_sdk"
  if ! awk -F '|' -v package="$platform" '$1 ~ "^[[:space:]]*" package "[[:space:]]*$" { found=1 } END { exit !found }' target/ci/android-tablet/sdk-packages.txt; then
    platform="platforms;android-$compile_sdk.0"
  fi
  image="system-images;android-$target_sdk;google_apis;x86_64"
  sdkmanager --install 'platform-tools' 'emulator' "$platform" "ndk;$ndk_version" "$image"
  avdmanager list device > target/ci/android-tablet/device-profiles.txt
  grep -Fq '"pixel_tablet"' target/ci/android-tablet/device-profiles.txt \
    || fail 'profil pixel_tablet tidak tersedia; perbarui Android SDK Command-line Tools lewat SDK Manager.'
  printf 'no\n' | avdmanager create avd --force --name Foundation_Tablet_CI \
    --package "$image" --device pixel_tablet
  printf 'ANDROID_HOME=%s\nANDROID_SDK_ROOT=%s\n' "$ANDROID_HOME" "$ANDROID_HOME" >> "$GITHUB_ENV"
  printf '%s\n' "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/emulator" "$sdk_bin" >> "$GITHUB_PATH"
  exit 0
fi

emulator -accel-check
serial=emulator-5554
[[ -z "$(adb devices | awk -v serial="$serial" '$1 == serial { print $1 }')" ]] \
  || fail "$serial sudah terpakai sebelum boot AVD CI."
nohup emulator -avd Foundation_Tablet_CI -port 5554 -no-window -no-audio \
  -no-boot-anim -no-snapshot -wipe-data -gpu swiftshader_indirect \
  > target/ci/android-tablet/emulator.log 2>&1 < /dev/null &
emulator_pid=$!
deadline=$((SECONDS + 600))
while [[ "$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != 1 ]]; do
  kill -0 "$emulator_pid" 2>/dev/null || fail 'proses emulator berhenti; lihat emulator.log.'
  [[ "$SECONDS" -lt "$deadline" ]] || fail 'emulator belum selesai boot setelah 600 detik; lihat emulator.log.'
  sleep 5
done
adb -s "$serial" shell input keyevent 82
adb -s "$serial" shell getprop ro.build.version.release
adb -s "$serial" shell getprop ro.product.cpu.abi
printf 'ANDROID_SERIAL=%s\n' "$serial" >> "$GITHUB_ENV"
