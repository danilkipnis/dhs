#!/bin/bash
# Usage: todo.sh [add <text> | done <id> | <id>]
#   (no args)     print todo.md
#   add <text>    append a new item at the end
#   done <id>     remove that item
#   <id>          print that item's description
#
# Items have no stored id: todo.md is just "# TODO", a blank line, then
# items separated from each other by a blank line. <id> is an item's
# position (1st, 2nd, ...), counted top to bottom each time the script
# runs -- so ids shift down when an earlier item is done.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TODO_FILE="$SCRIPT_DIR/todo.md"

usage() {
  echo "Usage: $(basename "$0") [add <text> | done <id> | <id>]" >&2
  exit 1
}

# Prints "<first-line> <last-line>" (1-indexed, inclusive) of item <id>'s
# block in todo.md, found by counting blank-line-separated blocks of
# non-blank lines and skipping the first one (the "# TODO" heading).
# Prints nothing if there's no such item.
item_line_range() {
  local id="$1"
  awk -v want=$((id + 1)) '
    /^[ \t]*$/ { in_block = 0; next }
    {
      if (!in_block) { in_block = 1; block++ }
      if (block == want) { if (!start) start = NR; end = NR }
    }
    END { if (start) print start, end }
  ' "$TODO_FILE"
}

cmd_add() {
  local text="$1"
  local tmp
  tmp=$(mktemp)
  # drop trailing blank lines, then append a blank-line-separated item
  awk '{a[NR]=$0} END{ b=0; for(i=NR;i>0;i--){ if(a[i]=="") b++; else break } for(i=1;i<=NR-b;i++) print a[i] }' "$TODO_FILE" > "$tmp"
  printf "\n%s\n" "$text" >> "$tmp"
  mv "$tmp" "$TODO_FILE"
}

cmd_done() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ && "$id" -ge 1 ]] || { echo "done requires a numeric id" >&2; exit 1; }
  local range start end
  range=$(item_line_range "$id")
  [[ -n "$range" ]] || { echo "no item with id ${id}" >&2; exit 1; }
  read -r start end <<< "$range"
  local tmp
  tmp=$(mktemp)
  awk -v s="$start" -v e="$end" 'NR >= s && NR <= e { next } { print }' "$TODO_FILE" \
    | awk '/^[ \t]*$/ { blank++; if (blank > 1) next; print; next } { blank = 0; print }' \
    > "$tmp"
  # trim trailing blank lines
  awk '{a[NR]=$0} END{ n=NR; while(n>0 && a[n] ~ /^[ \t]*$/) n--; for(i=1;i<=n;i++) print a[i] }' "$tmp" > "$TODO_FILE"
  rm -f "$tmp"
}

cmd_show() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ && "$id" -ge 1 ]] || { echo "id must be numeric" >&2; exit 1; }
  local range start end
  range=$(item_line_range "$id")
  [[ -n "$range" ]] || { echo "no item with id ${id}" >&2; exit 1; }
  read -r start end <<< "$range"
  sed -n "${start},${end}p" "$TODO_FILE"
}

case "${1:-}" in
  "")
    cat "$TODO_FILE"
    ;;
  add)
    [[ $# -ge 2 ]] || usage
    shift
    cmd_add "$*"
    ;;
  done)
    [[ $# -eq 2 ]] || usage
    cmd_done "$2"
    ;;
  *[0-9]*)
    [[ $# -eq 1 && "$1" =~ ^[0-9]+$ ]] || usage
    cmd_show "$1"
    ;;
  *)
    usage
    ;;
esac
