#!/usr/bin/env bash
# Convert Velthuis or ITRANS transliterated Pali text to Unicode (IAST-style
# diacritics), UTF-8 encoded.
#
# Usage:
#   ./pali-translit.sh -s velthuis input.txt > output.txt
#   ./pali-translit.sh -s itrans   input.txt > output.txt
#   cat input.txt | ./pali-translit.sh -s velthuis > output.txt
#   ./pali-translit.sh help                 # print the correspondence tables
#
# Only the diacritics Pali actually needs are covered: a ii/ī, aa/ā, uu/ū,
# .m/M -> anusvara m-with-dot-below (ṃ), the velar/palatal/retroflex nasals
# n-with-dot-above/tilde/dot-below (ṅ ñ ṇ), and retroflex t/d/l (ṭ ḍ ḷ).
# Everything else in the file (spaces, punctuation, plain letters) passes
# through untouched.
#
# Velthuis and ITRANS both have variant conventions in the wild (e.g. some
# writers use "n^" instead of \"n for ṅ, or ".n" for anusvara instead of
# ṇ). Check a few known words in the output before trusting it on a large
# file, and adjust the tables below if your source uses a different variant.

set -euo pipefail

usage() {
  echo "Usage: $0 -s {velthuis|itrans} [input-file]" >&2
  echo "       $0 help    (print the correspondence tables)" >&2
  exit 1
}

pyscript="$(mktemp)"
trap 'rm -f "$pyscript"' EXIT

cat > "$pyscript" <<'PYEOF'
import sys, re

# Longest patterns must come first so the regex alternation prefers them
# over their shorter prefixes (e.g. ".dh" before ".d" before "d").
VELTHUIS = [
    ("aa", "ā"), ("ii", "ī"), ("uu", "ū"),
    (".m", "ṃ"),
    ('"n', "ṅ"),
    ("~n", "ñ"),
    (".th", "ṭh"), (".dh", "ḍh"),
    (".t", "ṭ"), (".d", "ḍ"), (".n", "ṇ"), (".l", "ḷ"),
]

ITRANS = [
    ("aa", "ā"), ("ii", "ī"), ("uu", "ū"),
    ("A", "ā"), ("I", "ī"), ("U", "ū"),
    ("~N", "ṅ"), ("~n", "ñ"),
    ("Th", "ṭh"), ("Dh", "ḍh"),
    ("T", "ṭ"), ("D", "ḍ"), ("N", "ṇ"),
    ("L", "ḷ"),
    (".m", "ṃ"), ("M", "ṃ"),
]

SCHEMES = {"velthuis": VELTHUIS, "itrans": ITRANS}

def print_table():
    for name, table in SCHEMES.items():
        print(f"{name}:")
        for pat, uni in sorted(table, key=lambda p: p[0].lower()):
            print(f"  {pat:<5} -> {uni}")
        print()

def convert(scheme):
    table = sorted(SCHEMES[scheme], key=lambda p: -len(p[0]))
    pattern = re.compile("|".join(re.escape(pat) for pat, _ in table))
    repl = dict(table)
    text = sys.stdin.read()
    sys.stdout.write(pattern.sub(lambda m: repl[m.group(0)], text))

mode = sys.argv[1]
if mode == "table":
    print_table()
else:
    convert(mode)
PYEOF

if [[ "${1:-}" == "help" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 -s {velthuis|itrans} [input-file]"
  echo "       $0 help    (print the correspondence tables)"
  echo
  echo "Correspondence tables:"
  python3 "$pyscript" table
  exit 0
fi

scheme=""
infile=""

while getopts ":s:h" opt; do
  case "$opt" in
    s) scheme="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
infile="${1:-}"

case "$scheme" in
  velthuis|itrans) ;;
  *) usage ;;
esac

if [[ -n "$infile" ]]; then
  exec 0<"$infile"
fi

python3 "$pyscript" "$scheme"
