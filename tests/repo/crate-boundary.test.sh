# Grup repo: batas crate yang tahan lama (AC-1, AC-2).
# Membaca Cargo.toml dan Cargo.lock tanpa memanggil Cargo.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

# lock_query <mode> <paket>: menelusuri blok [[package]] di Cargo.lock.
#   direct  : nama dependensi langsung paket itu (gabungan semua versinya)
#   closure : tutup transitif dependensi paket itu, tanpa paket itu sendiri
# Keluar 2 bila paket tidak ditemukan.
lock_query() {
  awk -v mode="$1" -v root="$2" '
    function grab(s,   w) {
      while (match(s, /"[^"]*"/)) {
        w = substr(s, RSTART + 1, RLENGTH - 2)
        sub(/ .*/, "", w)
        deps[cur] = deps[cur] " " w
        s = substr(s, RSTART + RLENGTH)
      }
    }
    /^\[\[package\]\]/ { cur = ""; indeps = 0; next }
    /^\[/ { cur = ""; indeps = 0; next }
    /^name = "/ { cur = $0; sub(/^name = "/, "", cur); sub(/".*/, "", cur); seen[cur] = 1; next }
    cur != "" && /^dependencies = \[/ {
      line = $0; sub(/^dependencies = \[/, "", line); grab(line)
      indeps = ($0 !~ /\]/); next
    }
    indeps { grab($0); if ($0 ~ /\]/) indeps = 0; next }
    END {
      if (!(root in seen)) exit 2
      if (mode == "direct") {
        n = split(deps[root], a, " ")
        for (i = 1; i <= n; i++) print a[i]
        exit 0
      }
      queue[1] = root; head = 1; tail = 1; visited[root] = 1
      while (head <= tail) {
        p = queue[head]; head++
        n = split(deps[p], a, " ")
        for (i = 1; i <= n; i++) {
          if (!(a[i] in visited)) { visited[a[i]] = 1; tail++; queue[tail] = a[i]; print a[i] }
        }
      }
    }
  ' Cargo.lock
}

case_b1() {
  if git ls-files --error-unmatch Cargo.lock > /dev/null 2>&1; then
    return 0
  fi
  diag "Cargo.lock tidak terlacak Git (git ls-files --error-unmatch Cargo.lock keluar bukan 0)"
  return 1
}

case_b2() {
  local ok=0 members
  members="$(awk '/^members *= *\[/ { f = 1 } f { print } f && /\]/ { exit }' Cargo.toml)"
  expect_contains "$members" '"crates/core"' "members di Cargo.toml" || ok=1
  expect_contains "$members" '"crates/tablet-ffi"' "members di Cargo.toml" || ok=1
  expect_eq "tablet-core" "$(sed -n 's/^name *= *"\([^"]*\)".*/\1/p' crates/core/Cargo.toml | head -n 1)" \
    "nama paket crates/core" || ok=1
  expect_eq "tablet-ffi" "$(sed -n 's/^name *= *"\([^"]*\)".*/\1/p' crates/tablet-ffi/Cargo.toml | head -n 1)" \
    "nama paket crates/tablet-ffi" || ok=1
  return $ok
}

case_b3() {
  local closure rc bad
  closure="$(lock_query closure tablet-core)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    diag "blok [[package]] tablet-core tidak ditemukan di Cargo.lock"
    return 1
  fi
  bad="$(printf '%s\n' "$closure" | grep '^uniffi' | tr '\n' ' ')"
  if [ -n "$bad" ]; then
    diag "tutup transitif tablet-core harapan tanpa paket uniffi*, nyata memuat: $bad"
    return 1
  fi
  return 0
}

case_b4() {
  local direct rc ok=0
  direct="$(lock_query direct tablet-ffi)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    diag "blok [[package]] tablet-ffi tidak ditemukan di Cargo.lock"
    return 1
  fi
  printf '%s\n' "$direct" | grep -qx 'tablet-core' \
    || { diag "dependensi tablet-ffi di Cargo.lock harapan memuat tablet-core, nyata: $(printf '%s' "$direct" | tr '\n' ' ')"; ok=1; }
  printf '%s\n' "$direct" | grep -qx 'uniffi' \
    || { diag "dependensi tablet-ffi di Cargo.lock harapan memuat uniffi, nyata: $(printf '%s' "$direct" | tr '\n' ' ')"; ok=1; }
  return $ok
}

case_b5() {
  local line ok=0
  line="$(grep '^crate-type' crates/tablet-ffi/Cargo.toml | head -n 1)"
  expect_nonempty "$line" "baris crate-type di crates/tablet-ffi/Cargo.toml" || return 1
  expect_contains "$line" '"staticlib"' "crate-type" || ok=1
  expect_contains "$line" '"cdylib"' "crate-type" || ok=1
  return $ok
}

case_b6() {
  local f found=""
  for f in crates/*/Cargo.toml; do
    [ -f "$f" ] || continue
    if grep -q 'uniffi' "$f"; then
      found="$found $f"
    fi
  done
  expect_eq " crates/tablet-ffi/Cargo.toml" "$found" "manifest crates/*/Cargo.toml yang memuat uniffi"
}

check B1 AC-1 "Cargo.lock ter-commit" case_b1
check B2 AC-2 "workspace memuat tablet-core dan tablet-ffi" case_b2
check B3 AC-2 "tablet-core tidak menarik uniffi" case_b3
check B4 AC-2 "tablet-ffi bergantung pada tablet-core dan uniffi" case_b4
check B5 AC-2 "tablet-ffi menghasilkan staticlib dan cdylib" case_b5
check B6 AC-2 "hanya tablet-ffi yang memuat uniffi" case_b6
finish
