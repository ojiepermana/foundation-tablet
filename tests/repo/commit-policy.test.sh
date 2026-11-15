# Grup repo: aturan commit (AC-9 bagian mode, AC-11).
# Membaca indeks Git dan file terlacak saja.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

# Daftar izin file biner terlacak (sumber tunggal). Fitur yang kelak meng-commit
# biner yang sah menambah path-nya di sini, di commit yang sama.
BINARY_ALLOWLIST="apps/android-tablet/gradle/wrapper/gradle-wrapper.jar"

# Path yang harus diabaikan oleh .gitignore akar repo (spec 0001, "Aturan commit").
IGNORED_PATHS="
target/x
apps/ipados/build/x
a/xcuserdata/x
apps/ipados/Tablet.xcodeproj/project.xcworkspace/x
apps/ipados/Config/Local.xcconfig
.build/x
.swiftpm/x
apps/android-tablet/app/build/x
apps/android-tablet/build/x
apps/android-tablet/.gradle/x
apps/android-tablet/.kotlin/x
apps/android-tablet/local.properties
apps/android-tablet/app/.cxx/x
apps/android-tablet/captures/x
apps/android-tablet/app/src/main/jniLibs/x
bindings/swift/TabletFFI.xcframework/x
bindings/swift/Sources/x
bindings/kotlin/x
.DS_Store
.idea/x
a.iml
"

case_c1() {
  local hits
  hits="$(git ls-files | grep -E '\.(a|so|apk)$|xcframework|/build/|^target/')"
  if [ -z "$hits" ]; then
    return 0
  fi
  diag "hasil build terlacak Git, harapan kosong, nyata: $(printf '%s' "$hits" | tr '\n' ' ')"
  return 1
}

case_c2() {
  local actual expected
  actual="$(git ls-files --eol | awk '$1 == "i/-text"' | cut -f2 | LC_ALL=C sort)"
  expected="$(printf '%s\n' $BINARY_ALLOWLIST | LC_ALL=C sort)"
  expect_eq "$(printf '%s' "$expected" | tr '\n' ' ')" "$(printf '%s' "$actual" | tr '\n' ' ')" \
    "file biner terlacak terhadap daftar izin"
}

case_c3() {
  local ok=0 p out
  for p in $IGNORED_PATHS; do
    out="$(git check-ignore -v "$p" 2>/dev/null)"
    case "$out" in
      .gitignore:*) ;;
      "") diag "$p tidak diabaikan .gitignore akar repo"; ok=1 ;;
      *) diag "$p diabaikan oleh aturan di luar .gitignore akar repo: $out"; ok=1 ;;
    esac
  done
  return $ok
}

case_c4() {
  local lines bad
  lines="$(git ls-files -s scripts apps/android-tablet/gradlew)"
  expect_nonempty "$lines" "git ls-files -s scripts apps/android-tablet/gradlew" || return 1
  if ! printf '%s\n' "$lines" | grep -q 'apps/android-tablet/gradlew$'; then
    diag "apps/android-tablet/gradlew tidak terlacak Git"
    return 1
  fi
  bad="$(printf '%s\n' "$lines" | awk '$1 != "100755" { print $1 " " $4 }' | tr '\n' ';')"
  if [ -n "$bad" ]; then
    diag "mode harapan 100755, nyata: $bad"
    return 1
  fi
  return 0
}

case_c5() {
  local ok=0 f empty="" markers=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -s "$f" ] || empty="$empty $f"
    case "${f##*/}" in
      .gitkeep | .keep) markers="$markers $f" ;;
    esac
  done <<EOF
$(git ls-files)
EOF
  if [ -n "$empty" ]; then
    diag "file terlacak berukuran 0 byte:$empty"
    ok=1
  fi
  if [ -n "$markers" ]; then
    diag "file penanda tempat terlacak:$markers"
    ok=1
  fi
  return $ok
}

check C1 AC-11 "tidak ada hasil build terlacak" case_c1
check C2 AC-11 "biner terlacak hanya dari daftar izin" case_c2
check C3 AC-11 ".gitignore akar mengabaikan semua hasil build dan file lokal" case_c3
check C4 AC-9 "skrip dan gradlew bermode 100755" case_c4
check C5 AC-11 "tanpa file kosong atau file penanda tempat" case_c5
finish
