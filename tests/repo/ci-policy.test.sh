# covers spec 0003 AC-7: gerbang keamanan workflow PR dan laporan CI.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

case_ci1() {
  local ok=0 workflow=.github/workflows/pull-request.yml line uses sha
  [ -s "$workflow" ] || { diag "workflow PR belum tersedia"; return 1; }
  expect_contains "$(cat "$workflow")" '  pull_request:' "pemicu PR" || ok=1
  expect_contains "$(cat "$workflow")" '  contents: read' "izin minimum" || ok=1
  expect_not_contains "$(cat "$workflow")" 'pull_request_target' "tanpa konteks PR istimewa" || ok=1
  expect_not_contains "$(cat "$workflow")" 'secrets.' "tanpa secret PR" || ok=1
  while IFS= read -r line; do
    uses="$(printf '%s' "$line" | sed 's/.*uses: *//;s/ *#.*//')"
    sha="${uses##*@}"
    [ "${#sha}" -eq 40 ] && printf '%s' "$sha" | grep -Eq '^[0-9a-f]+$' || { diag "action tidak terkunci SHA penuh: $uses"; ok=1; }
  done <<LINES
$(sed -n '/uses:/p' "$workflow")
LINES
  expect_eq 2 "$(grep -c 'persist-credentials: false' "$workflow")" "kedua checkout tidak menyimpan kredensial" || ok=1
  for line in scripts/build-ipados.sh scripts/build-android-tablet.sh scripts/test-ipados.sh scripts/test-android-tablet.sh; do
    expect_contains "$(cat "$workflow")" "$line" "workflow memakai jalur lokal $line" || ok=1
  done
  return $ok
}

case_ci2() {
  local scratch ok=0 actual expected
  scratch="$(tmpdir_new)" || return 1
  _T_TMPDIRS="$_T_TMPDIRS $scratch"
  GITHUB_OUTPUT="$scratch/settings" scripts/ci-prepare-android-tablet.sh settings || return 1
  expected="java-version=$(src_toolchain_version)"
  actual="$(cat "$scratch/settings")"
  expect_eq "$expected" "$actual" "JDK CI dari sumber Gradle" || ok=1
  GITHUB_STEP_SUMMARY="$scratch/summary" CI_JOB_STATUS=failure CI_GATES_STATUS=success \
    CI_PREPARE_STATUS=success CI_BUILD_STATUS=failure CI_UI_STATUS=skipped \
    scripts/ci-summary.sh android-tablet || return 1
  actual="$(cat "$scratch/summary")"
  expect_contains "$actual" "$(git rev-parse HEAD)" "SHA checkout nyata" || ok=1
  expect_contains "$actual" '| GATES | PASS | success |' "PASS hanya tahap sukses" || ok=1
  expect_contains "$actual" '| BUILD | FAIL | failure |' "kegagalan dilaporkan" || ok=1
  expect_contains "$actual" '| UI | NOT_RUN | skipped |' "skip tidak menjadi PASS" || ok=1
  return $ok
}

check CI1 F04:AC-7 "workflow PR terkunci dan memakai perintah lokal" case_ci1
check CI2 F04:AC-7 "sumber JDK dan status laporan CI tepat" case_ci2
finish
