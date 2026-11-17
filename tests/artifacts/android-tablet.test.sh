# Grup artifacts: hasil build Android yang nyata (AC-3, AC-4, AC-7, AC-11).
# Butuh scripts/build-android-tablet.sh lebih dulu. Hanya membaca.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

APK="apps/android-tablet/app/build/outputs/apk/debug/app-debug.apk"
FIX="jalankan scripts/build-android-tablet.sh lebih dulu"
SDK="$(android_home)"

# so_path <ABI>
so_path() {
  printf 'target/%s/release/libtablet_ffi.so' "$(abi_triple "$1")"
}

# first_glob <pola>: path pertama yang ada, menurut urutan glob.
first_glob() {
  local p
  for p in $1; do
    [ -e "$p" ] && { printf '%s' "$p"; return 0; }
  done
  return 1
}

# last_glob <pola>: path terakhir yang ada, menurut urutan glob.
last_glob() {
  local p last=""
  for p in $1; do
    [ -e "$p" ] && last="$p"
  done
  [ -n "$last" ] || return 1
  printf '%s' "$last"
}

case_ha1() {
  local ok=0 abi so
  expect_nonempty "$(src_abis)" "tablet.abis di gradle.properties" || return 1
  for abi in $(src_abi_list); do
    so="$(so_path "$abi")"
    if [ ! -s "$so" ]; then
      diag "$so (ABI $abi) tidak ada atau kosong; $FIX"
      ok=1
    fi
  done
  return $ok
}

case_ha2() {
  local ok=0 ndk objdump abi so loads bad
  ndk="$(src_catalog ndk)"
  if ! objdump="$(first_glob "$SDK/ndk/$ndk/toolchains/llvm/prebuilt/*/bin/llvm-objdump")"; then
    diag "llvm-objdump tidak ada di $SDK/ndk/$ndk/toolchains/llvm/prebuilt/*/bin; pasang NDK $ndk atau set ANDROID_HOME"
    return 1
  fi
  for abi in $(src_abi_list); do
    so="$(so_path "$abi")"
    if [ ! -s "$so" ]; then
      diag "$so (ABI $abi) tidak ada; $FIX"
      ok=1
      continue
    fi
    loads="$("$objdump" -p "$so" | grep LOAD)"
    if [ -z "$loads" ]; then
      diag "$so: llvm-objdump -p tidak mencetak baris LOAD"
      ok=1
      continue
    fi
    bad="$(printf '%s\n' "$loads" | grep -v 'align 2\*\*14$')"
    if [ -n "$bad" ]; then
      diag "$so: baris LOAD harapan berakhir 'align 2**14', nyata: $(printf '%s' "$bad" | tr '\n' ';')"
      ok=1
    fi
  done
  return $ok
}

case_ha3() {
  local ok=0 aapt2 badging
  if [ ! -s "$APK" ]; then
    diag "$APK tidak ada; $FIX"
    return 1
  fi
  if ! aapt2="$(last_glob "$SDK/build-tools/*/aapt2")"; then
    diag "aapt2 tidak ada di $SDK/build-tools/*/; pasang build-tools atau set ANDROID_HOME"
    return 1
  fi
  badging="$("$aapt2" dump badging "$APK" 2>&1)"
  expect_contains "$badging" "minSdkVersion:'$(src_catalog minSdk)'" "aapt2 dump badging" || ok=1
  expect_contains "$badging" "targetSdkVersion:'$(src_catalog targetSdk)'" "aapt2 dump badging" || ok=1
  expect_contains "$badging" "compileSdkVersion='$(src_catalog compileSdk)'" "aapt2 dump badging" || ok=1
  return $ok
}

case_ha4() {
  local ok=0 listing libs p abi allowed
  if [ ! -s "$APK" ]; then
    diag "$APK tidak ada; $FIX"
    return 1
  fi
  if ! listing="$(unzip -l "$APK" 2>&1)"; then
    diag "unzip -l $APK gagal: $(printf '%s' "$listing" | tr '\n' ' ' | cut -c1-300)"
    return 1
  fi
  libs="$(printf '%s\n' "$listing" | awk '$4 ~ /^lib\// { print $4 }')"
  for p in $libs; do
    allowed=1
    for abi in $(src_abi_list); do
      case "$p" in
        "lib/$abi/"*) allowed=0 ;;
      esac
    done
    if [ "$allowed" -ne 0 ]; then
      diag "path $p di APK tidak berada di bawah lib/<ABI>/ untuk ABI di tablet.abis ($(src_abis))"
      ok=1
    fi
  done
  return $ok
}

case_ha5() {
  local status
  status="$(git status --short)"
  if [ -z "$status" ]; then
    return 0
  fi
  diag "git status --short harapan kosong, nyata: $(printf '%s' "$status" | tr '\n' ';')"
  return 1
}

# covers F04 AC-2: kedua pustaka wajib ada, bukan hanya ABI diizinkan.
case_ha6() {
  local ok=0 listing abi
  listing="$(unzip -Z1 "$APK" 2>/dev/null)" || { diag "APK tidak dapat dibaca; $FIX"; return 1; }
  for abi in $(src_abi_list); do
    for library in libtablet_ffi.so libjnidispatch.so; do
      if ! printf '%s\n' "$listing" | grep -qx "lib/$abi/$library"; then
        diag "lib/$abi/$library tidak ada dalam APK"; ok=1
      fi
    done
  done
  return $ok
}

check HA1 AC-3 "pustaka Rust Android ada untuk tiap ABI" case_ha1
check HA2 AC-4 "pustaka Android selaras 16 KB" case_ha2
check HA3 AC-7 "APK memakai SDK dari katalog" case_ha3
check HA4 AC-7 "APK hanya memuat ABI matriks" case_ha4
check HA5 AC-11 "pohon kerja bersih sesudah build" case_ha5
check HA6 F04:AC-2 "APK memuat Rust dan JNA untuk setiap ABI" case_ha6
finish
