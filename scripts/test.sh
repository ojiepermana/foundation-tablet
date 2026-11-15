#!/usr/bin/env bash
# Menjalankan tes tingkat repo di tests/.
#
# Pemakaian:
#   scripts/test.sh                              grup repo dan build-scripts (cepat, tanpa build, tanpa jaringan)
#   scripts/test.sh artifacts                    hasil build kedua platform; jalankan sesudah kedua skrip build
#   scripts/test.sh artifacts/ipados             satu file tes
#   scripts/test.sh repo build-scripts artifacts semuanya
#
# Runner ini tidak menjalankan cargo test; tes Rust tetap "cargo test --workspace --locked".
# Kontraknya ada di docs/specs/0001-arsitektur-dan-build-awal/index.md bagian
# "Perintah tes dan kontrak scripts/test.sh".
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

usage() {
  printf 'Pemakaian: scripts/test.sh [<grup> | <grup>/<nama>]...\n'
  printf 'Tanpa argumen: grup repo lalu build-scripts. Grup artifacts hanya berjalan bila disebut.\n'
  printf 'Grup yang ada:'
  local d
  for d in tests/*/; do
    d="${d%/}"
    d="${d#tests/}"
    [ "$d" = lib ] && continue
    printf ' %s' "$d"
  done
  printf '\n'
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
  esac
done

if [ "$#" -eq 0 ]; then
  set -- repo build-scripts
fi

# Periksa semua argumen lebih dulu.
bad=""
for arg in "$@"; do
  case "$arg" in
    lib | lib/* | "" | */*/* | .* | */.* | */) bad="$bad $arg" ;;
    */*)
      [ -f "tests/$arg.test.sh" ] || bad="$bad $arg"
      ;;
    *)
      [ -d "tests/$arg" ] || bad="$bad $arg"
      ;;
  esac
done
if [ -n "$bad" ]; then
  printf 'test: argumen tidak dikenal:%s\n' "$bad" >&2
  usage >&2
  exit 2
fi

# Susun daftar file menurut urutan argumen; file yang terpilih lagi dilewati.
selected=""
add_file() {
  case "
$selected
" in
    *"
$1
"*) return ;;
  esac
  if [ -z "$selected" ]; then
    selected="$1"
  else
    selected="$selected
$1"
  fi
}
for arg in "$@"; do
  case "$arg" in
    */*) add_file "tests/$arg.test.sh" ;;
    *)
      for f in $(find "tests/$arg" -maxdepth 1 -type f -name '*.test.sh' | LC_ALL=C sort); do
        add_file "$f"
      done
      ;;
  esac
done

if [ -x /bin/bash ]; then
  shell=/bin/bash
else
  shell=bash
fi

files=0
passed=0
failed=0
if [ -n "$selected" ]; then
  while IFS= read -r f; do
    files=$((files + 1))
    printf '# %s\n' "$f"
    if "$shell" "$f" < /dev/null; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  done <<EOF
$selected
EOF
fi

printf 'test: %d file, %d lulus, %d gagal\n' "$files" "$passed" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
