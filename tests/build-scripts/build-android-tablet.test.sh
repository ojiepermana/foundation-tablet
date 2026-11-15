# Grup build-scripts: kontrak scripts/build-android-tablet.sh di sandbox dengan alat
# tiruan (AC-3, AC-7, AC-8). Tidak ada build nyata. Kecuali disebut lain, tiap kasus
# menyetel ANDROID_HOME=<sandbox>/sdk dan JAVA_HOME=<sandbox>/jdk.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

SCRIPT=build-android-tablet.sh
CARGO_TAIL="build -p tablet-ffi --release --locked"

# Baris pertama calls.log untuk cargo ndk ... build, dan untuk gradlew.
ndk_build_line() {
  sb_build_calls | awk -F'\t' '$1 == "cargo" && $3 ~ /^ndk( |$)/ { print; exit }'
}
gradlew_line() {
  sb_build_calls | awk -F'\t' '$1 == "gradlew" { print; exit }'
}

# expected_t_flags [akar]: "-t <ABI>" untuk tiap ABI di tablet.abis, berurutan.
expected_t_flags() {
  local abi out=""
  for abi in $(src_abi_list "$1"); do
    out="$out -t $abi"
  done
  printf '%s' "${out# }"
}

# count_t <args>: jumlah kata -t.
count_t() {
  printf '%s\n' "$1" | tr ' ' '\n' | grep -cx -- '-t'
}

case_a1() {
  local ok=0
  sandbox_new || return 1
  mkdir -p "$SB/empty-sdk"
  SB_ENV=("ANDROID_HOME=$SB/empty-sdk" "JAVA_HOME=$SB/jdk")
  sb_run "$SCRIPT"
  expect_exit_nonzero "SDK kosong" || ok=1
  expect_err_has "sdkmanager" "SDK kosong" || ok=1
  expect_err_has "platforms;android-$(src_catalog compileSdk "$SB/repo").0" "SDK kosong" || ok=1
  expect_no_build "SDK kosong" || ok=1
  return $ok
}

case_a2() {
  local ok=0
  sandbox_new || return 1
  SB_ENV=("ANDROID_HOME=/tidak/ada" "JAVA_HOME=$SB/jdk")
  sb_run "$SCRIPT"
  expect_exit_nonzero "ANDROID_HOME=/tidak/ada" || ok=1
  expect_err_has "ANDROID_HOME" "ANDROID_HOME=/tidak/ada" || ok=1
  expect_err_has "/tidak/ada" "ANDROID_HOME=/tidak/ada" || ok=1
  expect_no_build "ANDROID_HOME=/tidak/ada" || ok=1
  return $ok
}

case_a3() {
  local ok=0 ndk
  sandbox_new || return 1
  ndk="$(src_catalog ndk "$SB/repo")"
  expect_nonempty "$ndk" "ndk di katalog sandbox" || return 1
  rm -rf "$SB/sdk/ndk/$ndk"
  sb_android_env
  sb_run "$SCRIPT"
  expect_exit_nonzero "tanpa NDK" || ok=1
  expect_err_has "ndk;$ndk" "tanpa NDK" || ok=1
  expect_no_build "tanpa NDK" || ok=1
  return $ok
}

case_a4() {
  local ok=0
  sandbox_new || return 1
  SB_ENV=("ANDROID_HOME=$SB/sdk" "JAVA_HOME=/tidak/ada")
  sb_run "$SCRIPT"
  expect_exit_nonzero "JAVA_HOME=/tidak/ada" || ok=1
  expect_err_has "JAVA_HOME" "JAVA_HOME=/tidak/ada" || ok=1
  expect_err_has "JDK $(src_toolchain_version)" "JAVA_HOME=/tidak/ada" || ok=1
  expect_no_build "JAVA_HOME=/tidak/ada" || ok=1
  return $ok
}

case_a5() {
  local ok=0
  sandbox_new || return 1
  SB_ENV=("ANDROID_HOME=$SB/sdk" "JAVA_HOME=$SB/jdk21")
  sb_run "$SCRIPT"
  expect_exit_nonzero "JDK 21" || ok=1
  expect_err_has "JDK $(src_toolchain_version)" "JDK 21" || ok=1
  expect_err_has "21" "JDK 21" || ok=1
  expect_no_build "JDK 21" || ok=1
  return $ok
}

case_a6() {
  local ok=0 want other
  want="cargo install cargo-ndk --version $(src_cargo_ndk_version) --locked"
  sandbox_new || return 1
  sb_android_env
  other="0.0.1"
  [ "$other" = "$SB_STUB_CARGO_NDK_VERSION" ] && other="0.0.2"
  SB_STUB_CARGO_NDK_VERSION="$other"
  sb_run "$SCRIPT"
  expect_exit_nonzero "cargo-ndk $other" || ok=1
  expect_err_has "$want" "cargo-ndk $other" || ok=1
  expect_no_build "cargo-ndk $other" || ok=1

  SB_STUB_CARGO_NDK_VERSION=none
  sb_run "$SCRIPT"
  expect_exit_nonzero "tanpa cargo-ndk" || ok=1
  expect_err_has "$want" "tanpa cargo-ndk" || ok=1
  expect_no_build "tanpa cargo-ndk" || ok=1
  return $ok
}

case_a7() {
  local ok=0 triple=x86_64-linux-android
  sandbox_new || return 1
  sb_android_env
  SB_STUB_RUST_TARGETS="$(src_toolchain_targets | grep -vx "$triple" | tr '\n' ' ')"
  sb_run "$SCRIPT"
  expect_exit_nonzero "tanpa $triple" || ok=1
  expect_err_has "rustup target add $triple" "tanpa $triple" || ok=1
  expect_no_build "tanpa $triple" || ok=1
  return $ok
}

case_a8() {
  local ok=0
  sandbox_new || return 1
  sb_android_env
  sb_edit apps/android-tablet/gradle.properties 's/^tablet\.abis=.*/tablet.abis=arm64-v8a,armeabi-v7a/'
  sb_run "$SCRIPT"
  expect_exit_nonzero "armeabi-v7a" || ok=1
  expect_err_has "armeabi-v7a" "armeabi-v7a" || ok=1
  expect_err_has "matriks" "armeabi-v7a" || ok=1
  expect_no_build "armeabi-v7a" || ok=1
  return $ok
}

case_a9() {
  local ok=0 calls n ndk_line grd_line args flags abi toks
  sandbox_new || return 1
  sb_android_env
  sb_run "$SCRIPT"
  expect_exit_zero "jalur lulus" || return 1
  calls="$(sb_build_calls)"
  n="$(printf '%s\n' "$calls" | sed '/^$/d' | wc -l | tr -d ' ')"
  expect_eq 2 "$n" "jumlah panggilan build" || ok=1
  ndk_line="$(printf '%s\n' "$calls" | sed -n 1p)"
  grd_line="$(printf '%s\n' "$calls" | sed -n 2p)"

  expect_eq cargo "$(log_tool "$ndk_line")" "panggilan build ke-1" || ok=1
  args="$(log_args "$ndk_line")"
  flags="$(expected_t_flags "$SB/repo")"
  expect_nonempty "$flags" "tablet.abis di gradle.properties sandbox" || ok=1
  toks=()
  for abi in $(src_abi_list "$SB/repo"); do
    toks+=("-t $abi ")
  done
  if ! contains_in_order "$args " "ndk " ${toks[@]+"${toks[@]}"} "$CARGO_TAIL"; then
    diag "panggilan build ke-1 harapan 'ndk $flags ... $CARGO_TAIL' berurutan, nyata '$args'"
    ok=1
  fi
  expect_eq "$(src_abi_list "$SB/repo" | wc -l | tr -d ' ')" "$(count_t "$args")" "jumlah -t pada cargo ndk" || ok=1
  expect_eq "$SB/repo" "$(log_cwd "$ndk_line")" "folder kerja cargo ndk" || ok=1

  expect_eq gradlew "$(log_tool "$grd_line")" "panggilan build ke-2" || ok=1
  has_words "$(log_args "$grd_line")" ":app:assembleDebug" \
    || { diag "panggilan gradlew harapan memuat :app:assembleDebug, nyata '$(log_args "$grd_line")'"; ok=1; }
  expect_eq "$SB/repo/apps/android-tablet" "$(log_cwd "$grd_line")" "folder kerja gradlew" || ok=1
  expect_eq "build-android-tablet: selesai" "$(tail -n 1 "$SB/out")" "baris terakhir stdout" || ok=1
  return $ok
}

case_a10() {
  local ok=0 line ndk args
  sandbox_new || return 1
  sb_android_env
  ndk="$(src_catalog ndk "$SB/repo")"

  sb_run "$SCRIPT"
  expect_exit_zero "nilai asli" || ok=1
  line="$(ndk_build_line)"
  if expect_nonempty "$line" "nilai asli: panggilan cargo ndk build"; then
    expect_eq "$(src_catalog minSdk "$SB/repo")" "$(log_env "$line" CARGO_NDK_PLATFORM)" \
      "nilai asli: CARGO_NDK_PLATFORM" || ok=1
    expect_eq "$SB/sdk/ndk/$ndk" "$(log_env "$line" ANDROID_NDK_HOME)" "nilai asli: ANDROID_NDK_HOME" || ok=1
  else
    ok=1
  fi
  line="$(gradlew_line)"
  if expect_nonempty "$line" "nilai asli: panggilan gradlew"; then
    expect_eq "$SB/jdk" "$(log_env "$line" JAVA_HOME)" "nilai asli: JAVA_HOME pada gradlew" || ok=1
    expect_eq "$SB/sdk" "$(log_env "$line" ANDROID_HOME)" "nilai asli: ANDROID_HOME pada gradlew" || ok=1
  else
    ok=1
  fi

  sb_edit apps/android-tablet/gradle/libs.versions.toml 's/^minSdk *= *"[^"]*"/minSdk = "31"/'
  sb_run "$SCRIPT"
  expect_exit_zero "minSdk 31" || ok=1
  line="$(ndk_build_line)"
  expect_eq 31 "$(log_env "$line" CARGO_NDK_PLATFORM)" "minSdk 31: CARGO_NDK_PLATFORM" || ok=1

  sb_edit apps/android-tablet/gradle.properties 's/^tablet\.abis=.*/tablet.abis=arm64-v8a/'
  sb_run "$SCRIPT"
  expect_exit_zero "tablet.abis=arm64-v8a" || ok=1
  line="$(ndk_build_line)"
  args="$(log_args "$line")"
  expect_eq 1 "$(count_t "$args")" "tablet.abis=arm64-v8a: jumlah -t" || ok=1
  has_words "$args" "-t arm64-v8a" || { diag "tablet.abis=arm64-v8a: harapan '-t arm64-v8a', nyata '$args'"; ok=1; }
  return $ok
}

case_a11() {
  local ok=0 sdk compile_sdk ndk line
  sandbox_new || return 1
  sdk="$SB/home/Library/Android/sdk"
  compile_sdk="$(src_catalog compileSdk "$SB/repo")"
  ndk="$(src_catalog ndk "$SB/repo")"
  mkdir -p "$sdk/platforms/android-$compile_sdk.0" "$sdk/ndk/$ndk"
  SB_ENV=("JAVA_HOME=$SB/jdk")
  sb_run "$SCRIPT"
  expect_exit_zero "ANDROID_HOME tidak diset" || return 1
  line="$(ndk_build_line)"
  expect_eq "$sdk" "$(log_env "$line" ANDROID_HOME)" "ANDROID_HOME pada cargo ndk" || ok=1
  line="$(gradlew_line)"
  expect_eq "$sdk" "$(log_env "$line" ANDROID_HOME)" "ANDROID_HOME pada gradlew" || ok=1
  return $ok
}

case_a12() {
  local ok=0
  sandbox_new || return 1
  sb_android_env
  sb_run "$SCRIPT" --salah
  expect_exit_nonzero "--salah" || ok=1
  expect_err_has "--salah" "--salah" || ok=1
  expect_no_build "--salah" || ok=1
  return $ok
}

check A1 AC-8 "SDK tanpa platform dihentikan" case_a1
check A2 AC-8 "ANDROID_HOME yang tidak ada dihentikan" case_a2
check A3 AC-8 "NDK yang hilang dihentikan" case_a3
check A4 AC-8 "JAVA_HOME yang tidak ada dihentikan" case_a4
check A5 AC-8 "JDK versi lain dihentikan" case_a5
check A6 AC-8 "cargo-ndk versi lain atau hilang dihentikan" case_a6
check A7 AC-8 "target Rust Android yang hilang dihentikan" case_a7
check A8 AC-7,AC-8 "ABI di luar matriks ditolak" case_a8
check A9 AC-3,AC-7 "jalur lulus" case_a9
check A10 AC-8 "nilai diteruskan dari sumbernya" case_a10
check A11 AC-8 "ANDROID_HOME bawaan di HOME" case_a11
check A12 AC-8 "argumen salah dihentikan" case_a12
finish
