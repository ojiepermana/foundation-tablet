# Grup repo: aturan kontribusi (fitur 02, README AC 27).
# Memastikan AGENTS.md dan panduan kontribusi tetap menunjuk dokumen yang ada,
# sehingga aturan singkat di AGENTS.md selalu bisa diikuti sampai rinciannya.
# Membaca file terlacak saja.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd -P)/harness.sh"

GUIDE="docs/contributing.md"

# md_links <file>: mencetak target setiap tautan Markdown [teks](target), satu per baris.
md_links() {
  grep -o '\]([^)]*)' "$1" | sed 's/^](//; s/)$//'
}

# md_slugs <file>: mencetak anchor setiap heading, dengan aturan yang sama seperti GitHub
# untuk teks biasa: huruf kecil, tanda baca dibuang, spasi menjadi tanda hubung.
md_slugs() {
  grep -E '^#{1,6} ' "$1" | sed -E 's/^#+ +//' | tr 'A-Z' 'a-z' \
    | sed -E 's/[^a-z0-9 _-]//g; s/ /-/g'
}

# links_resolve <file>: 0 bila setiap tautan relatif menunjuk file atau folder yang ada,
# dan setiap anchor di file yang sama menunjuk heading yang ada.
links_resolve() {
  local file="$1" dir target path anchor bad=""
  dir="$(dirname "$file")"
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    case "$target" in
      *://* | mailto:*) continue ;;
      \#*)
        anchor="${target#\#}"
        if ! md_slugs "$file" | grep -qx -- "$anchor"; then
          bad="$bad $target"
        fi
        continue
        ;;
    esac
    path="${target%%#*}"
    [ -e "$dir/$path" ] || bad="$bad $target"
  done <<EOF
$(md_links "$file")
EOF
  if [ -n "$bad" ]; then
    diag "$file: tautan tanpa tujuan:$bad"
    return 1
  fi
  return 0
}

case_g1() {
  links_resolve AGENTS.md
}

case_g2() {
  if [ ! -f "$GUIDE" ]; then
    diag "$GUIDE tidak ada"
    return 1
  fi
  links_resolve "$GUIDE"
}

case_g3() {
  if md_links AGENTS.md | grep -qx -- "$GUIDE"; then
    return 0
  fi
  diag "AGENTS.md tidak menautkan $GUIDE"
  return 1
}

# Kata kunci aturan yang wajib tetap ada di AGENTS.md (Done when fitur 02). Bila aturan
# dipindah atau diganti namanya, perbarui daftar ini di commit yang sama.
AGENTS_RULES="
ownership-matrix.md
dependency-rules.md
git status --short
cargo clippy
scripts/test.sh
NOT_RUN
docs/specs/
permissions: contents: read
SHA commit penuh
// SAFETY:
/check review
"

case_g4() {
  local rule missing=""
  while IFS= read -r rule; do
    [ -n "$rule" ] || continue
    grep -qF -- "$rule" AGENTS.md || missing="$missing [$rule]"
  done <<EOF
$AGENTS_RULES
EOF
  if [ -n "$missing" ]; then
    diag "AGENTS.md kehilangan aturan:$missing"
    return 1
  fi
  return 0
}

check G1 README-AC27 "setiap tautan relatif di AGENTS.md menunjuk file yang ada" case_g1
check G2 README-AC27 "setiap tautan relatif dan anchor di panduan kontribusi valid" case_g2
check G3 README-AC27 "AGENTS.md menautkan panduan kontribusi" case_g3
check G4 README-AC27 "AGENTS.md memuat aturan inti kontribusi" case_g4
finish
