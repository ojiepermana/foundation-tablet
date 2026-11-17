# Helper tes tingkat repo. Di-source oleh setiap file tests/<grup>/<nama>.test.sh.
#
# Isi: pencatat kasus (baris ok / not ok, 1..n, kode keluar), pembaca nilai dari
# sumber tunggal (tabel "Sumber nilai" spec 0001), pemetaan ABI ke triple Rust,
# serta sandbox dan alat tiruan untuk grup build-scripts.
#
# Aturan: berjalan di bash 3.2 (tanpa array asosiatif, mapfile, ${v,,}, &>>),
# hanya bentuk perintah yang sama di macOS dan Linux (tanpa sed -i, stat,
# find -printf), dan tidak pernah menulis ke dalam repo. Kontraknya ada di
# docs/specs/0001-arsitektur-dan-build-awal/index.md bagian "Rancangan tes fitur 01".

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "$REPO_ROOT" || exit 1

# ---------------------------------------------------------------------------
# Pencatat kasus

_T_N=0
_T_FAILED=0
_T_DIAG=""
_T_TMPDIRS=""

# diag <teks>: menambah satu baris "# " untuk kasus yang sedang berjalan.
diag() {
  _T_DIAG="${_T_DIAG}# $*
"
}

# check <ID> <AC> <nama> <fungsi>: menjalankan fungsi di shell ini dan mencetak
# tepat satu baris ok / not ok. Fungsi mengembalikan 0 bila lulus.
check() {
  local id="$1" ac="$2" name="$3" fn="$4"
  _T_N=$((_T_N + 1))
  _T_DIAG=""
  if "$fn"; then
    printf 'ok %d - %s %s %s\n' "$_T_N" "$id" "$ac" "$name"
  else
    _T_FAILED=$((_T_FAILED + 1))
    printf 'not ok %d - %s %s %s\n' "$_T_N" "$id" "$ac" "$name"
    if [ -n "$_T_DIAG" ]; then
      printf '%s' "$_T_DIAG"
    else
      printf '# kasus gagal tanpa keterangan\n'
    fi
  fi
}

# finish: mencetak 1..n lalu keluar 0 bila semua kasus ok, selain itu 1.
finish() {
  printf '1..%d\n' "$_T_N"
  if [ "$_T_FAILED" -eq 0 ]; then
    exit 0
  fi
  exit 1
}

_t_cleanup() {
  local d
  for d in $_T_TMPDIRS; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}
trap _t_cleanup EXIT

# tmpdir_new: membuat folder sementara di luar repo (path sudah dinormalkan
# dengan pwd -P) dan mencetak path-nya. Dihapus saat file tes selesai.
tmpdir_new() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/tablet-test.XXXXXX")" || return 1
  d="$(cd "$d" && pwd -P)"
  printf '%s' "$d"
}

# ---------------------------------------------------------------------------
# Asersi kecil. Semua mengembalikan 1 dan menulis diag bila gagal.

# expect_eq <harapan> <nyata> <label>
expect_eq() {
  if [ "$1" = "$2" ]; then
    return 0
  fi
  diag "$3: harapan '$1', nyata '$2'"
  return 1
}

# expect_nonempty <nilai> <label>
expect_nonempty() {
  if [ -n "$1" ]; then
    return 0
  fi
  diag "$2: nilai kosong (tidak terbaca dari sumbernya)"
  return 1
}

# expect_contains <teks> <potongan> <label>
expect_contains() {
  case "$1" in
    *"$2"*) return 0 ;;
  esac
  diag "$3: harapan memuat '$2', nyata: $(printf '%s' "$1" | tr '\n' ' ' | cut -c1-400)"
  return 1
}

# expect_not_contains <teks> <potongan> <label>
expect_not_contains() {
  case "$1" in
    *"$2"*)
      diag "$3: harapan tidak memuat '$2', nyata: $(printf '%s' "$1" | tr '\n' ' ' | cut -c1-400)"
      return 1
      ;;
  esac
  return 0
}

# has_words <teks> <frasa>: frasa muncul sebagai kata utuh (dibatasi spasi).
has_words() {
  case " $1 " in
    *" $2 "*) return 0 ;;
  esac
  return 1
}

# contains_in_order <teks> <potongan>...: semua potongan muncul berurutan.
contains_in_order() {
  local rest="$1" tok
  shift
  for tok in "$@"; do
    case "$rest" in
      *"$tok"*) rest="${rest#*"$tok"}" ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# ---------------------------------------------------------------------------
# Pembaca nilai dari sumber tunggal. Argumen opsional: akar repo lain (sandbox).

# Isi bagian TOML [<bagian>] sampai bagian berikutnya.
_toml_section() {
  awk -v want="[$2]" '
    /^\[/ { insec = ($0 == want); next }
    insec { print }
  ' "$1"
}

src_toolchain_channel() {
  sed -n 's/^channel *= *"\([^"]*\)".*/\1/p' "${1:-$REPO_ROOT}/rust-toolchain.toml" | head -n 1
}

# Satu target per baris, dari daftar targets di rust-toolchain.toml.
src_toolchain_targets() {
  awk '
    /^targets *= *\[/ { f = 1 }
    f {
      line = $0
      sub(/^targets *= */, "", line)
      while (match(line, /"[^"]*"/)) {
        print substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
      }
      if ($0 ~ /\]/) exit
    }
  ' "${1:-$REPO_ROOT}/rust-toolchain.toml"
}

# Nilai uniffi di [workspace.dependencies], termasuk "=" bila ada.
src_uniffi_pin() {
  _toml_section "${1:-$REPO_ROOT}/Cargo.toml" workspace.dependencies \
    | sed -n -e 's/^uniffi *= *"\([^"]*\)".*/\1/p' \
             -e 's/^uniffi *= *{.*version *= *"\([^"]*\)".*/\1/p' \
    | head -n 1
}

# rust-version di [workspace.package].
src_rust_version() {
  _toml_section "${1:-$REPO_ROOT}/Cargo.toml" workspace.package \
    | sed -n 's/^rust-version *= *"\([^"]*\)".*/\1/p' | head -n 1
}

src_xcode_version() {
  tr -d '[:space:]' < "${1:-$REPO_ROOT}/.xcode-version"
}

src_deployment_target() {
  sed -n 's/^IPHONEOS_DEPLOYMENT_TARGET *= *\([0-9.]*\).*/\1/p' \
    "${1:-$REPO_ROOT}/apps/ipados/Config/Base.xcconfig" | head -n 1
}

# src_catalog <kunci> [akar]: nilai kunci di bagian [versions] katalog Gradle.
src_catalog() {
  _toml_section "${2:-$REPO_ROOT}/apps/android-tablet/gradle/libs.versions.toml" versions \
    | sed -n "s/^$1 *= *\"\([^\"]*\)\".*/\1/p" | head -n 1
}

# Isi tablet.abis apa adanya (dipisah koma).
src_abis() {
  sed -n 's/^tablet\.abis=//p' "${1:-$REPO_ROOT}/apps/android-tablet/gradle.properties" | head -n 1
}

# Satu ABI per baris.
src_abi_list() {
  src_abis "$1" | tr ',' '\n' | sed '/^$/d'
}

src_gradle_version() {
  sed -n 's/^distributionUrl=.*gradle-\([0-9][0-9.]*\)-bin\.zip$/\1/p' \
    "${1:-$REPO_ROOT}/apps/android-tablet/gradle/wrapper/gradle-wrapper.properties" | head -n 1
}

src_toolchain_version() {
  sed -n 's/^toolchainVersion=\(.*\)$/\1/p' \
    "${1:-$REPO_ROOT}/apps/android-tablet/gradle/gradle-daemon-jvm.properties" | head -n 1
}

src_cargo_ndk_version() {
  sed -n 's/.*cargo install cargo-ndk --version \([0-9][0-9.]*\) --locked.*/\1/p' \
    "${1:-$REPO_ROOT}/docs/getting-started.md" | head -n 1
}

# abi_triple <ABI>: triple Rust untuk ABI Android, kosong bila tidak dikenal.
abi_triple() {
  case "$1" in
    arm64-v8a) printf 'aarch64-linux-android' ;;
    x86_64) printf 'x86_64-linux-android' ;;
    *) printf '' ;;
  esac
}

# ANDROID_HOME seperti aturan skrip: variabel bila diset, selain itu ~/Library/Android/sdk.
android_home() {
  if [ -n "${ANDROID_HOME:-}" ]; then
    printf '%s' "$ANDROID_HOME"
  else
    printf '%s' "$HOME/Library/Android/sdk"
  fi
}

# ---------------------------------------------------------------------------
# Tabel Markdown

# md_rows <file> <judul bagian>: baris tabel pertama di bawah judul itu
# (judul ditulis lengkap, misalnya "## Versi alat").
md_rows() {
  awk -v want="$2" '
    $0 == want { insec = 1; next }
    insec && /^#/ { exit }
    insec && /^\|/ { intable = 1; print; next }
    insec && intable { exit }
  ' "$1"
}

# md_cell <baris> <n>: sel ke-n (mulai 1), tanpa spasi di tepi.
md_cell() {
  printf '%s\n' "$1" | awk -F'|' -v n="$2" '{
    c = $(n + 1)
    sub(/^[ \t]+/, "", c)
    sub(/[ \t]+$/, "", c)
    print c
  }'
}

# md_rows_labeled <file> <judul> <label>: baris yang sel pertamanya sama persis dengan label.
md_rows_labeled() {
  local row
  md_rows "$1" "$2" | while IFS= read -r row; do
    if [ "$(md_cell "$row" 1)" = "$3" ]; then
      printf '%s\n' "$row"
    fi
  done
}

# ---------------------------------------------------------------------------
# Sandbox dan alat tiruan untuk grup build-scripts.
#
# sandbox_new membuat folder baru dan mengisi SB. Variabel SB_STUB_* berisi
# perilaku bawaan alat tiruan (jalur lulus) yang dibaca dari file sumber;
# kasus mengubahnya sebelum sb_run. SB_ENV berisi variabel tambahan kasus
# (bentuk NAMA=nilai).

_write_stub() {
  # _write_stub <path> <nama alat> <badan sh>
  cat > "$1" <<EOF
#!/bin/sh
printf '%s\t%s\t%s\tIPHONEOS_DEPLOYMENT_TARGET=%s\tCARGO_NDK_PLATFORM=%s\tANDROID_HOME=%s\tANDROID_NDK_HOME=%s\tJAVA_HOME=%s\n' \\
  "$2" "\$(pwd -P)" "\$*" "\${IPHONEOS_DEPLOYMENT_TARGET-}" "\${CARGO_NDK_PLATFORM-}" \\
  "\${ANDROID_HOME-}" "\${ANDROID_NDK_HOME-}" "\${JAVA_HOME-}" >> "\$STUB_LOG"
$3
exit 0
EOF
  chmod 755 "$1"
}

sandbox_new() {
  local compile_sdk ndk
  SB="$(tmpdir_new)" || return 1
  _T_TMPDIRS="$_T_TMPDIRS $SB"
  compile_sdk="$(src_catalog compileSdk)"
  ndk="$(src_catalog ndk)"

  mkdir -p "$SB/repo/scripts" "$SB/repo/apps/ipados/Config" "$SB/repo/apps/android-tablet/gradle" \
    "$SB/bin" "$SB/sdk/platforms/android-$compile_sdk.0" "$SB/sdk/ndk/$ndk" \
    "$SB/jdk/bin" "$SB/jdk21/bin" "$SB/xcode/Contents/Developer" "$SB/CommandLineTools" "$SB/home"
  cp -p "$REPO_ROOT/scripts/build-ipados.sh" "$REPO_ROOT/scripts/build-android-tablet.sh" "$SB/repo/scripts/"
  cp "$REPO_ROOT/.xcode-version" "$SB/repo/.xcode-version"
  cp "$REPO_ROOT/apps/ipados/Config/Base.xcconfig" "$SB/repo/apps/ipados/Config/Base.xcconfig"
  cp "$REPO_ROOT/apps/android-tablet/gradle/libs.versions.toml" "$SB/repo/apps/android-tablet/gradle/libs.versions.toml"
  cp "$REPO_ROOT/apps/android-tablet/gradle.properties" "$SB/repo/apps/android-tablet/gradle.properties"
  : > "$SB/calls.log"

  _write_stub "$SB/repo/scripts/generate-bindings.sh" generate-bindings '
if [ "${STUB_GENERATE_FAIL:-0}" = 1 ]; then
  echo "generate-bindings: generasi gagal (fixture)" >&2
  exit 1
fi
case "$1" in
  swift)
    mkdir -p bindings/swift/Sources/TabletBindings target/bindings/swift/headers/TabletFFI
    echo "// fixture" > bindings/swift/Sources/TabletBindings/TabletBindings.swift
    echo "// fixture" > target/bindings/swift/headers/TabletFFI/TabletFFI.h
    echo "module TabletFFI {}" > target/bindings/swift/headers/TabletFFI/module.modulemap
    ;;
  kotlin)
    mkdir -p bindings/kotlin/foundation/tablet/bindings
    echo "// fixture" > bindings/kotlin/foundation/tablet/bindings/tablet_ffi.kt
    ;;
esac'
  _write_stub "$SB/repo/apps/android-tablet/gradlew" gradlew ''
  _write_stub "$SB/bin/cargo" cargo '
if [ "$1" = ndk ] && [ "$2" = --version ]; then
  if [ "$STUB_CARGO_NDK_VERSION" = none ]; then
    echo "error: no such command: \`ndk\`" >&2
    exit 1
  fi
  echo "cargo-ndk $STUB_CARGO_NDK_VERSION"
fi
if [ "$1" = build ]; then
  previous=""
  for argument in "$@"; do
    if [ "$previous" = --target ]; then
      mkdir -p "target/$argument/release"
      echo "fixture $argument" > "target/$argument/release/libtablet_ffi.a"
    fi
    previous="$argument"
  done
fi
if [ "$1" = ndk ] && [ "$2" != --version ]; then
  for triple in aarch64-linux-android x86_64-linux-android; do
    mkdir -p "target/$triple/release"
    echo "fixture $triple" > "target/$triple/release/libtablet_ffi.so"
  done
fi'
  _write_stub "$SB/bin/rustup" rustup '
if [ "$1" = target ] && [ "$2" = list ] && [ "$3" = --installed ]; then
  for t in $STUB_RUST_TARGETS; do echo "$t"; done
fi'
  _write_stub "$SB/bin/xcode-select" xcode-select '
if [ "$1" = -p ]; then echo "$STUB_DEVELOPER_DIR"; fi'
  _write_stub "$SB/bin/xcodebuild" xcodebuild '
if [ "$1" = -version ]; then
  echo "Xcode $STUB_XCODE_VERSION"
  echo "Build version 00A000"
fi
if [ "$1" = -create-xcframework ]; then
  previous=""
  for argument in "$@"; do
    if [ "$previous" = -output ]; then mkdir -p "$argument"; fi
    previous="$argument"
  done
fi'
  _write_stub "$SB/jdk/bin/java" java '
if [ "$1" = -version ]; then echo "openjdk version \"$STUB_JAVA_VERSION\" 2026-01-20" >&2; fi'
  _write_stub "$SB/jdk21/bin/java" java '
if [ "$1" = -version ]; then echo "openjdk version \"21.0.5\" 2024-10-15" >&2; fi'

  SB_STUB_CARGO_NDK_VERSION="$(src_cargo_ndk_version)"
  SB_STUB_RUST_TARGETS="$(src_toolchain_targets | tr '\n' ' ')"
  SB_STUB_DEVELOPER_DIR="$SB/xcode/Contents/Developer"
  SB_STUB_XCODE_VERSION="$(src_xcode_version)"
  SB_STUB_JAVA_VERSION="$(src_toolchain_version).0.2"
  SB_ENV=()
}

# sb_android_env: ANDROID_HOME dan JAVA_HOME bawaan untuk kasus Android.
sb_android_env() {
  SB_ENV=("ANDROID_HOME=$SB/sdk" "JAVA_HOME=$SB/jdk")
}

# sb_edit <path relatif di repo sandbox> <ekspresi sed>: ubah berkas lewat berkas sementara.
sb_edit() {
  sed "$2" "$SB/repo/$1" > "$SB/edit.tmp" && mv "$SB/edit.tmp" "$SB/repo/$1"
}

# sb_run <skrip> [argumen...]: menjalankan skrip sandbox dengan lingkungan kosong
# dari folder kerja selain akar sandbox. Hasil: SB_RC, berkas $SB/out dan $SB/err.
sb_run() {
  local script="$1"
  shift
  : > "$SB/calls.log"
  (
    cd "$SB/home" || exit 99
    env -i PATH="$SB/bin:/usr/bin:/bin" HOME="$SB/home" STUB_LOG="$SB/calls.log" \
      STUB_CARGO_NDK_VERSION="$SB_STUB_CARGO_NDK_VERSION" \
      STUB_RUST_TARGETS="$SB_STUB_RUST_TARGETS" \
      STUB_DEVELOPER_DIR="$SB_STUB_DEVELOPER_DIR" \
      STUB_XCODE_VERSION="$SB_STUB_XCODE_VERSION" \
      STUB_JAVA_VERSION="$SB_STUB_JAVA_VERSION" \
      ${SB_ENV[@]+"${SB_ENV[@]}"} \
      "$SB/repo/scripts/$script" "$@" > "$SB/out" 2> "$SB/err"
  )
  SB_RC=$?
}

sb_out() { cat "$SB/out"; }
sb_err() { cat "$SB/err"; }

# sb_build_calls: baris calls.log yang berarti build (cargo build, cargo ndk ... build,
# xcodebuild selain -version, gradlew), berurutan.
sb_build_calls() {
  awk -F'\t' '
    ($1 == "cargo" && ($3 ~ /^build( |$)/ || ($3 ~ /^ndk( |$)/ && $3 ~ / build( |$)/))) \
      || ($1 == "xcodebuild" && $3 != "-version" && $3 !~ /^-create-xcframework/) \
      || $1 == "gradlew" { print }
  ' "$SB/calls.log"
}

# log_tool, log_cwd, log_args <baris>; log_env <baris> <NAMA>
log_tool() { printf '%s\n' "$1" | cut -f1; }
log_cwd() { printf '%s\n' "$1" | cut -f2; }
log_args() { printf '%s\n' "$1" | cut -f3; }
log_env() {
  printf '%s\n' "$1" | awk -F'\t' -v k="$2=" '{
    for (i = 4; i <= NF; i++) if (index($i, k) == 1) { print substr($i, length(k) + 1); exit }
  }'
}

# expect_exit_nonzero <label>
expect_exit_nonzero() {
  if [ "$SB_RC" -ne 0 ]; then
    return 0
  fi
  diag "$1: harapan kode keluar bukan 0, nyata 0"
  return 1
}

# expect_exit_zero <label>
expect_exit_zero() {
  if [ "$SB_RC" -eq 0 ]; then
    return 0
  fi
  diag "$1: harapan kode keluar 0, nyata $SB_RC; stderr: $(tr '\n' ' ' < "$SB/err" | cut -c1-400)"
  return 1
}

# expect_no_build <label>
expect_no_build() {
  local calls
  calls="$(sb_build_calls)"
  if [ -z "$calls" ]; then
    return 0
  fi
  diag "$1: harapan tanpa build, nyata: $(printf '%s' "$calls" | cut -f1,3 | tr '\t\n' ' ;')"
  return 1
}

# expect_err_has <potongan> <label>
expect_err_has() {
  expect_contains "$(sb_err)" "$1" "$2: stderr"
}
