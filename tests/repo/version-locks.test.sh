# Grup repo: kunci versi dan satu sumber nilai (AC-1, AC-2, AC-5 sampai AC-10).
# Nilai harapan dibaca dari sumbernya, bukan disalin ke tes. Pengecualian yang
# dinyatakan spec: janji matriks pada V9.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

CATALOG="apps/android-tablet/gradle/libs.versions.toml"
XCCONFIG="apps/ipados/Config/Base.xcconfig"
SUPPORT_MATRIX="docs/architecture/support-matrix.md"
GETTING_STARTED="docs/getting-started.md"

case_v1() {
  local ok=0 channel targets abi triple
  channel="$(src_toolchain_channel)"
  if ! printf '%s\n' "$channel" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    diag "channel di rust-toolchain.toml harapan berbentuk X.Y.Z, nyata '$channel'"
    ok=1
  fi
  targets="$(src_toolchain_targets)"
  for triple in aarch64-apple-ios aarch64-apple-ios-sim; do
    printf '%s\n' "$targets" | grep -qx "$triple" \
      || { diag "targets di rust-toolchain.toml harapan memuat $triple, nyata: $(printf '%s' "$targets" | tr '\n' ' ')"; ok=1; }
  done
  expect_nonempty "$(src_abis)" "tablet.abis di gradle.properties" || ok=1
  for abi in $(src_abi_list); do
    triple="$(abi_triple "$abi")"
    if [ -z "$triple" ]; then
      diag "ABI $abi di tablet.abis tidak punya triple Rust yang dikenal"
      ok=1
      continue
    fi
    printf '%s\n' "$targets" | grep -qx "$triple" \
      || { diag "targets di rust-toolchain.toml harapan memuat $triple (ABI $abi), nyata: $(printf '%s' "$targets" | tr '\n' ' ')"; ok=1; }
  done
  return $ok
}

case_v2() {
  local ok=0 channel out major_minor
  channel="$(src_toolchain_channel)"
  expect_nonempty "$channel" "channel di rust-toolchain.toml" || return 1
  if ! command -v rustc > /dev/null 2>&1; then
    diag "rustc tidak ditemukan di PATH. Pasang rustup dari https://rustup.rs, lalu jalankan 'rustup toolchain install' dari akar repo"
    return 1
  fi
  if ! out="$(RUSTUP_AUTO_INSTALL=0 rustc --version 2>&1)"; then
    diag "rustc --version gagal (toolchain $channel belum terpasang?). Jalankan 'rustup toolchain install' dari akar repo. Keluaran: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-300)"
    return 1
  fi
  case "$out" in
    "rustc $channel"*) ;;
    *)
      diag "rustc --version dari akar repo harapan diawali 'rustc $channel', nyata '$out'. Jalankan 'rustup toolchain install'"
      ok=1
      ;;
  esac
  major_minor="$(printf '%s' "$channel" | sed -n 's/^\([0-9]*\.[0-9]*\)\..*/\1/p')"
  expect_eq "$major_minor" "$(src_rust_version)" "rust-version di Cargo.toml terhadap X.Y dari channel" || ok=1
  return $ok
}

case_v3() {
  local ok=0 pin count lock_version
  pin="$(src_uniffi_pin)"
  expect_nonempty "$pin" "uniffi di [workspace.dependencies] Cargo.toml" || return 1
  case "$pin" in
    =*) ;;
    *) diag "uniffi di [workspace.dependencies] harapan diawali '=', nyata '$pin'"; ok=1 ;;
  esac
  count="$(grep -c '^name = "uniffi"$' Cargo.lock)"
  expect_eq 1 "$count" "jumlah paket bernama uniffi di Cargo.lock" || ok=1
  lock_version="$(awk '/^name = "uniffi"$/ { f = 1; next } f && /^version = "/ { v = $0; sub(/^version = "/, "", v); sub(/".*/, "", v); print v; exit }' Cargo.lock)"
  expect_eq "${pin#=}" "$lock_version" "versi uniffi di Cargo.lock terhadap pin Cargo.toml" || ok=1
  return $ok
}

case_v4() {
  local ok=0 props url sum
  props="apps/android-tablet/gradle/wrapper/gradle-wrapper.properties"
  url="$(sed -n 's/^distributionUrl=//p' "$props" | head -n 1)"
  if ! printf '%s\n' "$url" | grep -Eq 'gradle-[0-9]+\.[0-9]+\.[0-9]+-bin\.zip$'; then
    diag "distributionUrl harapan berakhir gradle-X.Y.Z-bin.zip, nyata '$url'"
    ok=1
  fi
  sum="$(sed -n 's/^distributionSha256Sum=//p' "$props" | head -n 1)"
  if ! printf '%s\n' "$sum" | grep -Eq '^[0-9a-fA-F]{64}$'; then
    diag "distributionSha256Sum harapan tepat 64 karakter heksadesimal, nyata '$sum'"
    ok=1
  fi
  return $ok
}

case_v5() {
  local ok=0 key value line
  for key in agp kotlin composeBom activityCompose compileSdk minSdk targetSdk ndk; do
    value="$(src_catalog "$key")"
    if [ -z "$value" ]; then
      diag "kunci $key tidak ada di [versions] $CATALOG"
      ok=1
    elif ! printf '%s\n' "$value" | grep -Eq '^[0-9.]+$'; then
      diag "nilai $key di [versions] harapan hanya angka dan titik, nyata '$value'"
      ok=1
    fi
  done
  for key in kotlin-gradle-plugin compose-compiler; do
    line="$(grep "^$key *=" "$CATALOG" | head -n 1)"
    if [ -z "$line" ]; then
      diag "baris $key tidak ada di $CATALOG"
      ok=1
    else
      expect_contains "$line" 'version.ref = "kotlin"' "baris $key" || ok=1
    fi
  done
  line="$(grep '^androidx-compose-material3 *=' "$CATALOG" | head -n 1)"
  if [ -z "$line" ]; then
    diag "baris androidx-compose-material3 tidak ada di $CATALOG"
    ok=1
  else
    expect_not_contains "$line" 'version' "baris androidx-compose-material3 (versi dari BOM)" || ok=1
  fi
  return $ok
}

case_v6() {
  local ok=0 file key lines line
  file="apps/android-tablet/app/build.gradle.kts"
  for key in compileSdk minSdk targetSdk ndkVersion; do
    lines="$(grep "$key" "$file")"
    if [ -z "$lines" ]; then
      diag "tidak ada baris yang memuat $key di $file"
      ok=1
      continue
    fi
    while IFS= read -r line; do
      expect_contains "$line" 'libs.versions.' "baris $key di $file" || ok=1
    done <<EOF
$lines
EOF
  done
  for key in applicationId abiFilters; do
    lines="$(grep "$key" "$file")"
    if [ -z "$lines" ]; then
      diag "tidak ada baris yang memuat $key di $file"
      ok=1
      continue
    fi
    while IFS= read -r line; do
      expect_contains "$line" 'gradleProperty("tablet.' "baris $key di $file" || ok=1
    done <<EOF
$lines
EOF
  done
  return $ok
}

case_v7() {
  local result
  result="$(awk '
    pending { n++; t = $0; gsub(/[ \t]/, "", t); if (t != "};") bad = bad " " NR; pending = 0 }
    /buildSettings = \{/ { pending = 1 }
    END { printf "%d%s", n, (bad == "" ? "" : ":" bad) }
  ' apps/ipados/Tablet.xcodeproj/project.pbxproj)"
  case "$result" in
    0)
      diag "project.pbxproj tidak memuat blok buildSettings = {"
      return 1
      ;;
    *:*)
      diag "blok buildSettings di project.pbxproj harapan langsung ditutup '};', baris yang berisi nilai:${result#*:}"
      return 1
      ;;
  esac
  return 0
}

# v8_row <file> <judul> <label>: mengisi V8_ROW dengan satu baris berlabel itu,
# gagal (dengan diag) bila nol atau lebih dari satu baris. Dipanggil langsung,
# bukan di dalam $(...), supaya diag tidak hilang di subshell.
v8_row() {
  local rows n
  rows="$(md_rows_labeled "$1" "$2" "$3")"
  if [ -z "$rows" ]; then
    n=0
  else
    n="$(printf '%s\n' "$rows" | wc -l | tr -d ' ')"
  fi
  if [ "$n" -ne 1 ]; then
    diag "$1 tabel \"${2#\#\# }\": label '$3' harapan tepat 1 baris, nyata $n"
    V8_ROW=""
    return 1
  fi
  V8_ROW="$rows"
}

# v8_has <file> <judul> <label> <token>...: baris berlabel memuat setiap token.
v8_has() {
  local file="$1" heading="$2" label="$3" row tok ok=0
  shift 3
  v8_row "$file" "$heading" "$label" || return 1
  row="$V8_ROW"
  for tok in "$@"; do
    expect_contains "$row" "$tok" "$file baris '$label'" || ok=1
  done
  return $ok
}

case_v8() {
  local ok=0 channel pin ndkv xcode dt agp gradle kotlin bom act csdk tsdk msdk ndk tcv row cell
  channel="$(src_toolchain_channel)"
  pin="$(src_uniffi_pin)"
  ndkv="$(src_cargo_ndk_version)"
  xcode="$(src_xcode_version)"
  dt="$(src_deployment_target)"
  agp="$(src_catalog agp)"
  gradle="$(src_gradle_version)"
  kotlin="$(src_catalog kotlin)"
  bom="$(src_catalog composeBom)"
  act="$(src_catalog activityCompose)"
  csdk="$(src_catalog compileSdk)"
  tsdk="$(src_catalog targetSdk)"
  msdk="$(src_catalog minSdk)"
  ndk="$(src_catalog ndk)"
  tcv="$(src_toolchain_version)"
  for v in channel pin ndkv xcode dt agp gradle kotlin bom act csdk tsdk msdk ndk tcv; do
    eval "expect_nonempty \"\$$v\" \"nilai sumber $v\"" || ok=1
  done
  [ "$ok" -eq 0 ] || return 1

  local SM="$SUPPORT_MATRIX" H="## Versi alat"
  v8_has "$SM" "$H" "Rust" "$channel" || ok=1
  v8_has "$SM" "$H" "UniFFI" "${pin#=}" || ok=1
  v8_has "$SM" "$H" "cargo-ndk" "--version $ndkv" || ok=1
  v8_has "$SM" "$H" "Xcode dan Swift" "Xcode $xcode" || ok=1
  v8_has "$SM" "$H" "iPadOS minimum" "IPHONEOS_DEPLOYMENT_TARGET = $dt" || ok=1
  v8_has "$SM" "$H" "Android Gradle Plugin" "$agp" || ok=1
  v8_has "$SM" "$H" "Gradle" "$gradle" || ok=1
  v8_has "$SM" "$H" "Kotlin" "$kotlin" || ok=1
  v8_has "$SM" "$H" "Compose" "BOM $bom" "\`activity-compose\` $act" || ok=1
  v8_has "$SM" "$H" "Android SDK" "\`compileSdk\` $csdk" "\`targetSdk\` $tsdk" "\`minSdk\` $msdk" || ok=1
  v8_has "$SM" "$H" "NDK" "$ndk" || ok=1
  v8_has "$SM" "$H" "JDK" "toolchainVersion=$tcv" || ok=1

  local GS="$GETTING_STARTED" P="## Prasyarat"
  if v8_row "$GS" "$P" "Xcode"; then
    row="$V8_ROW"
    cell="$(md_cell "$row" 2)"
    case "$cell" in
      "$xcode"*) ;;
      *) diag "$GS baris 'Xcode': sel kedua harapan diawali '$xcode', nyata '$cell'"; ok=1 ;;
    esac
  else
    ok=1
  fi
  v8_has "$GS" "$P" "\`rustup\`" "toolchain $channel" || ok=1
  v8_has "$GS" "$P" "Android SDK" "platforms;android-$csdk.0" "ndk;$ndk" || ok=1
  if v8_row "$GS" "$P" "JDK"; then
    row="$V8_ROW"
    expect_eq "$tcv" "$(md_cell "$row" 2)" "$GS baris 'JDK' sel kedua" || ok=1
  else
    ok=1
  fi
  if v8_row "$GS" "$P" "\`cargo-ndk\`"; then
    row="$V8_ROW"
    expect_eq "$ndkv" "$(md_cell "$row" 2)" "$GS baris '\`cargo-ndk\`' sel kedua" || ok=1
  else
    ok=1
  fi
  return $ok
}

case_v9() {
  local ok=0 abi
  grep -Fxq 'TARGETED_DEVICE_FAMILY = 2' "$XCCONFIG" \
    || { diag "$XCCONFIG harapan memuat baris 'TARGETED_DEVICE_FAMILY = 2'"; ok=1; }
  grep -Fxq 'ARCHS[sdk=iphonesimulator*] = arm64' "$XCCONFIG" \
    || { diag "$XCCONFIG harapan memuat baris 'ARCHS[sdk=iphonesimulator*] = arm64'"; ok=1; }
  expect_nonempty "$(src_abis)" "tablet.abis di gradle.properties" || ok=1
  for abi in $(src_abi_list); do
    case "$abi" in
      arm64-v8a | x86_64) ;;
      *) diag "ABI $abi di tablet.abis tidak ada di matriks dukungan (arm64-v8a, x86_64)"; ok=1 ;;
    esac
  done
  return $ok
}

check V1 AC-8 "channel dan targets rust-toolchain.toml" case_v1
check V2 AC-1,AC-8 "rustc di akar repo sama dengan channel" case_v2
check V3 AC-2,AC-8 "uniffi dikunci persis dan sama dengan Cargo.lock" case_v3
check V4 AC-8 "wrapper Gradle dikunci dengan checksum" case_v4
check V5 AC-8 "katalog versi Gradle lengkap dan berbentuk angka" case_v5
check V6 AC-8 "build.gradle.kts membaca nilai dari katalog dan gradle.properties" case_v6
check V7 AC-8 "buildSettings project.pbxproj kosong" case_v7
check V8 AC-9,AC-10 "dokumen mengikuti sumber nilai" case_v8
check V9 AC-5,AC-6,AC-7 "janji matriks ada di konfigurasi" case_v9
finish
