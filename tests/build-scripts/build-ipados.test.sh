# Grup build-scripts: kontrak scripts/build-ipados.sh di sandbox dengan alat tiruan
# (AC-3, AC-5, AC-6, AC-8, AC-11). Tidak ada build nyata.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

SIM=aarch64-apple-ios-sim
DEV=aarch64-apple-ios
CARGO_SIM="build -p tablet-ffi --release --locked --target $SIM"
CARGO_DEV="build -p tablet-ffi --release --locked --target $DEV"

# Baris xcodebuild build untuk konfigurasi tertentu (Debug atau Release).
xcb_line() {
  sb_build_calls | awk -F'\t' -v c="-configuration $1" '$1 == "xcodebuild" && index($3, c) { print; exit }'
}

# Baris cargo build untuk triple tertentu.
cargo_line() {
  local line
  while IFS= read -r line; do
    [ "$(log_tool "$line")" = cargo ] || continue
    if has_words "$(log_args "$line")" "--target $1"; then
      printf '%s\n' "$line"
      return
    fi
  done <<EOF
$(sb_build_calls)
EOF
}

case_i1() {
  local ok=0
  sandbox_new || return 1
  SB_ENV=("DEVELOPER_DIR=/tidak/ada")
  sb_run build-ipados.sh
  expect_exit_nonzero "DEVELOPER_DIR=/tidak/ada" || ok=1
  expect_err_has "DEVELOPER_DIR" "DEVELOPER_DIR=/tidak/ada" || ok=1
  expect_err_has "unset DEVELOPER_DIR" "DEVELOPER_DIR=/tidak/ada" || ok=1
  expect_no_build "DEVELOPER_DIR=/tidak/ada" || ok=1
  return $ok
}

case_i2() {
  local ok=0
  sandbox_new || return 1
  SB_STUB_DEVELOPER_DIR="$SB/CommandLineTools"
  sb_run build-ipados.sh
  expect_exit_nonzero "Command Line Tools" || ok=1
  expect_err_has "Command Line Tools" "Command Line Tools" || ok=1
  expect_err_has "xcode-select -s" "Command Line Tools" || ok=1
  expect_no_build "Command Line Tools" || ok=1
  return $ok
}

case_i3() {
  local ok=0
  sandbox_new || return 1
  SB_STUB_XCODE_VERSION=26.4
  sb_run build-ipados.sh
  expect_exit_nonzero "Xcode 26.4" || ok=1
  expect_err_has "Xcode 27" "Xcode 26.4" || ok=1
  expect_err_has "26.4" "Xcode 26.4" || ok=1
  expect_no_build "Xcode 26.4" || ok=1
  return $ok
}

case_i4() {
  local ok=0
  sandbox_new || return 1
  SB_STUB_XCODE_VERSION=27.2
  sb_run build-ipados.sh
  expect_exit_zero "Xcode 27.2" || ok=1
  expect_err_has "peringatan" "Xcode 27.2" || ok=1
  expect_err_has "$(src_xcode_version "$SB/repo")" "Xcode 27.2" || ok=1
  expect_err_has "27.2" "Xcode 27.2" || ok=1
  return $ok
}

case_i5() {
  local ok=0
  sandbox_new || return 1
  SB_STUB_RUST_TARGETS="$(src_toolchain_targets | grep -vx "$SIM" | tr '\n' ' ')"
  sb_run build-ipados.sh
  expect_exit_nonzero "tanpa $SIM" || ok=1
  expect_err_has "rustup target add $SIM" "tanpa $SIM" || ok=1
  expect_no_build "tanpa $SIM" || ok=1
  return $ok
}

case_i6() {
  local ok=0
  sandbox_new || return 1
  rm -f "$SB/bin/cargo"
  sb_run build-ipados.sh
  expect_exit_nonzero "tanpa cargo" || ok=1
  expect_err_has "cargo" "tanpa cargo" || ok=1
  expect_err_has "rustup.rs" "tanpa cargo" || ok=1
  expect_no_build "tanpa cargo" || ok=1
  return $ok
}

case_i7() {
  local ok=0 calls n line i bad_cwd
  sandbox_new || return 1
  sb_run build-ipados.sh
  expect_exit_zero "tanpa argumen" || return 1
  calls="$(sb_build_calls)"
  n="$(printf '%s\n' "$calls" | sed '/^$/d' | wc -l | tr -d ' ')"
  expect_eq 4 "$n" "jumlah panggilan build" || ok=1
  i=0
  while IFS= read -r line; do
    i=$((i + 1))
    case "$i" in
      1)
        expect_eq "cargo $CARGO_SIM" "$(log_tool "$line") $(log_args "$line")" "panggilan build ke-1" || ok=1
        ;;
      2)
        expect_eq "cargo $CARGO_DEV" "$(log_tool "$line") $(log_args "$line")" "panggilan build ke-2" || ok=1
        ;;
      3)
        expect_eq xcodebuild "$(log_tool "$line")" "panggilan build ke-3" || ok=1
        for tok in "-project apps/ipados/Tablet.xcodeproj" "-scheme Tablet" "-configuration Debug" \
          "generic/platform=iOS Simulator" "-derivedDataPath apps/ipados/build/DerivedData"; do
          expect_contains "$(log_args "$line")" "$tok" "panggilan build ke-3 (simulator)" || ok=1
        done
        has_words "$(log_args "$line")" build || { diag "panggilan build ke-3 tidak memuat aksi build"; ok=1; }
        ;;
      4)
        expect_eq xcodebuild "$(log_tool "$line")" "panggilan build ke-4" || ok=1
        for tok in "-project apps/ipados/Tablet.xcodeproj" "-scheme Tablet" "-configuration Release" \
          "generic/platform=iOS" "-derivedDataPath apps/ipados/build/DerivedData" "CODE_SIGNING_ALLOWED=NO"; do
          expect_contains "$(log_args "$line")" "$tok" "panggilan build ke-4 (perangkat)" || ok=1
        done
        expect_not_contains "$(log_args "$line")" "generic/platform=iOS Simulator" "panggilan build ke-4 (perangkat)" || ok=1
        has_words "$(log_args "$line")" build || { diag "panggilan build ke-4 tidak memuat aksi build"; ok=1; }
        ;;
    esac
  done <<EOF
$calls
EOF
  bad_cwd="$(awk -F'\t' -v r="$SB/repo" '$2 != r { print $1 " " $2 }' "$SB/calls.log" | tr '\n' ';')"
  if [ -n "$bad_cwd" ]; then
    diag "folder kerja harapan $SB/repo, nyata: $bad_cwd"
    ok=1
  fi
  expect_eq "build-ipados: selesai" "$(tail -n 1 "$SB/out")" "baris terakhir stdout" || ok=1
  return $ok
}

case_i8() {
  local ok=0 expected line triple
  sandbox_new || return 1
  expected="$(src_deployment_target "$SB/repo")"
  expect_nonempty "$expected" "IPHONEOS_DEPLOYMENT_TARGET di Base.xcconfig sandbox" || return 1
  sb_run build-ipados.sh
  expect_exit_zero "nilai asli" || ok=1
  for triple in "$SIM" "$DEV"; do
    line="$(cargo_line "$triple")"
    expect_nonempty "$line" "panggilan cargo build untuk $triple" || { ok=1; continue; }
    expect_eq "$expected" "$(log_env "$line" IPHONEOS_DEPLOYMENT_TARGET)" \
      "IPHONEOS_DEPLOYMENT_TARGET pada cargo build $triple" || ok=1
  done
  sb_edit apps/ipados/Config/Base.xcconfig 's/^IPHONEOS_DEPLOYMENT_TARGET *=.*/IPHONEOS_DEPLOYMENT_TARGET = 27.0/'
  sb_run build-ipados.sh
  expect_exit_zero "sesudah diubah ke 27.0" || ok=1
  for triple in "$SIM" "$DEV"; do
    line="$(cargo_line "$triple")"
    expect_nonempty "$line" "panggilan cargo build untuk $triple sesudah diubah" || { ok=1; continue; }
    expect_eq "27.0" "$(log_env "$line" IPHONEOS_DEPLOYMENT_TARGET)" \
      "IPHONEOS_DEPLOYMENT_TARGET pada cargo build $triple sesudah diubah" || ok=1
  done
  return $ok
}

case_i9() {
  local ok=0 cargo_args
  sandbox_new || return 1

  sb_run build-ipados.sh --simulator
  expect_exit_zero "--simulator" || ok=1
  cargo_args="$(sb_build_calls | awk -F'\t' '$1 == "cargo" { print $3 }')"
  expect_eq "$CARGO_SIM" "$cargo_args" "--simulator: panggilan cargo build" || ok=1
  expect_nonempty "$(xcb_line Debug)" "--simulator: xcodebuild Debug" || ok=1
  expect_eq "" "$(xcb_line Release)" "--simulator: xcodebuild Release" || ok=1

  sb_run build-ipados.sh --device
  expect_exit_zero "--device" || ok=1
  cargo_args="$(sb_build_calls | awk -F'\t' '$1 == "cargo" { print $3 }')"
  expect_eq "$CARGO_DEV" "$cargo_args" "--device: panggilan cargo build" || ok=1
  expect_eq "" "$(xcb_line Debug)" "--device: xcodebuild Debug" || ok=1
  if expect_nonempty "$(xcb_line Release)" "--device: xcodebuild Release"; then
    expect_contains "$(log_args "$(xcb_line Release)")" "CODE_SIGNING_ALLOWED=NO" "--device: xcodebuild Release" || ok=1
  else
    ok=1
  fi
  return $ok
}

case_i10() {
  local ok=0
  sandbox_new || return 1
  sb_run build-ipados.sh --salah
  expect_exit_nonzero "--salah" || ok=1
  expect_err_has "--salah" "--salah" || ok=1
  expect_no_build "--salah" || ok=1

  sb_run build-ipados.sh --help
  expect_exit_zero "--help" || ok=1
  expect_contains "$(sb_out)" "--simulator" "--help: stdout" || ok=1
  expect_contains "$(sb_out)" "--device" "--help: stdout" || ok=1
  if [ -s "$SB/calls.log" ]; then
    diag "--help: calls.log harapan kosong, nyata: $(cut -f1,3 "$SB/calls.log" | tr '\t\n' ' ;')"
    ok=1
  fi
  return $ok
}

case_i11() {
  local before after
  sandbox_new || return 1
  before="$(cd "$SB/repo" && find . | LC_ALL=C sort)"
  sb_run build-ipados.sh
  expect_exit_zero "jalur lulus" || return 1
  # F04 menambah keluaran binding/XCFramework yang sah, tidak menyunting sumber.
  rm -rf "$SB/repo/target" "$SB/repo/bindings"
  after="$(cd "$SB/repo" && find . | LC_ALL=C sort)"
  if [ "$before" = "$after" ]; then
    return 0
  fi
  printf '%s\n' "$before" > "$SB/before.txt"
  printf '%s\n' "$after" > "$SB/after.txt"
  diag "file baru di repo sandbox: $(grep -Fxv -f "$SB/before.txt" "$SB/after.txt" | tr '\n' ' ')"
  diag "file yang hilang dari repo sandbox: $(grep -Fxv -f "$SB/after.txt" "$SB/before.txt" | tr '\n' ' ')"
  return 1
}

# F04, covers spec 0003 AC-1 dan AC-8.
case_i12() {
  local ok=0 calls generator framework line
  sandbox_new || return 1
  sb_run build-ipados.sh
  expect_exit_zero "kemasan default" || return 1
  calls="$(cat "$SB/calls.log")"
  generator="$(printf '%s\n' "$calls" | awk -F'\t' '$1 == "generate-bindings" { print $3 }')"
  expect_eq "swift target/$SIM/release/libtablet_ffi.a target/$DEV/release/libtablet_ffi.a" "$generator" "generator memakai tepat kedua pustaka yang dibangun" || ok=1
  framework="$(printf '%s\n' "$calls" | awk -F'\t' '$1 == "xcodebuild" && $3 ~ /^-create-xcframework/ { print $3 }')"
  for line in "-library target/$SIM/release/libtablet_ffi.a" "-library target/$DEV/release/libtablet_ffi.a" "-headers target/bindings/swift/headers"; do
    expect_contains "$framework" "$line" "XCFramework" || ok=1
  done
  contains_in_order "$calls" "generate-bindings" "-create-xcframework" "-configuration Debug" "-configuration Release" || { diag "generasi dan kemasan harus mendahului kedua build aplikasi"; ok=1; }
  sb_run build-ipados.sh --simulator
  expect_exit_zero "kemasan simulator saja" || ok=1
  generator="$(awk -F'\t' '$1 == "generate-bindings" { print $3 }' "$SB/calls.log")"
  expect_eq "swift target/$SIM/release/libtablet_ffi.a" "$generator" "generator simulator saja" || ok=1
  expect_not_contains "$(awk -F'\t' '$3 ~ /^-create-xcframework/ { print $3 }' "$SB/calls.log")" "target/$DEV/" "XCFramework simulator tidak memakai slice lama perangkat" || ok=1
  return $ok
}

case_i13() {
  local ok=0
  sandbox_new || return 1
  SB_ENV=("STUB_GENERATE_FAIL=1")
  sb_run build-ipados.sh
  expect_exit_nonzero "generator gagal" || ok=1
  expect_err_has "generate-bindings: generasi gagal" "galat diteruskan" || ok=1
  expect_eq "" "$(awk -F'\t' '$1 == "xcodebuild" && $3 != "-version" { print }' "$SB/calls.log")" "tidak ada pengemasan atau build Xcode setelah generator gagal" || ok=1
  return $ok
}

check I1 AC-8 "DEVELOPER_DIR yang tidak ada dihentikan" case_i1
check I2 AC-8 "Command Line Tools ditolak" case_i2
check I3 AC-8 "Xcode selain 27 ditolak" case_i3
check I4 AC-8 "Xcode 27 lain hanya diberi peringatan" case_i4
check I5 AC-8 "target Rust simulator yang hilang dihentikan" case_i5
check I6 AC-8 "cargo yang hilang dihentikan" case_i6
check I7 AC-3,AC-5,AC-6 "jalur lulus tanpa argumen" case_i7
check I8 AC-8 "IPHONEOS_DEPLOYMENT_TARGET dibaca dari Base.xcconfig" case_i8
check I9 AC-5,AC-6 "--simulator dan --device masing masing" case_i9
check I10 AC-8 "argumen salah dan --help" case_i10
check I11 AC-11 "skrip hanya membuat keluaran generasi yang sah" case_i11
check I12 F04:AC-1 "binding dan XCFramework berasal dari slice run ini" case_i12
check I13 F04:AC-8 "generator gagal menghentikan Xcode" case_i13
finish
