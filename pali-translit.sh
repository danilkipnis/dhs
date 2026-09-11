#!/usr/bin/env bash
# Convert Velthuis or ITRANS transliterated Pali text to Unicode (IAST-style
# diacritics), UTF-8 encoded.
#
# Usage:
#   ./pali-translit.sh -s velthuis input.txt > output.txt
#   ./pali-translit.sh -s itrans   input.txt > output.txt
#   cat input.txt | ./pali-translit.sh -s velthuis > output.txt
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

scheme=""
infile=""

usage() { echo "Usage: $0 -s {velthuis|itrans} [input-file]" >&2; exit 1; }

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

pyscript="$(mktemp)"
trap 'rm -f "$pyscript"' EXIT

cat > "$pyscript" <<'PYEOF'
import sys, re

scheme = sys.argv[1]

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

table = VELTHUIS if scheme == "velthuis" else ITRANS
table.sort(key=lambda p: -len(p[0]))

pattern = re.compile("|".join(re.escape(pat) for pat, _ in table))
repl = dict(table)

text = sys.stdin.read()
out = pattern.sub(lambda m: repl[m.group(0)], text)
sys.stdout.write(out)
PYEOF

python3 "$pyscript" "$scheme"
