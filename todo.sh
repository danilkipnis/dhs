#!/bin/bash
# Usage: todo.sh [add <text> | done <id> | <id>]
#   (no args)     print todo.md
#   add <text>    append a new item with the next id
#   done <id>     remove the item with that id, renumbering the rest
#   <id>          print that item's description
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TODO_FILE="$SCRIPT_DIR/todo.md"

usage() {
  echo "Usage: $(basename "$0") [add <text> | done <id> | <id>]" >&2
  exit 1
}

# Rewrite each "N. " item prefix sequentially (1, 2, 3, ...), preserving the
# 4-column alignment ("1.  " / "10. ") and leaving continuation lines as-is.
renumber() {
  awk '
    /^[0-9]+\.[ \t]/ {
      n++
      match($0, /^[0-9]+\./)
      rest = substr($0, RLENGTH + 1)
      sub(/^[ \t]+/, "", rest)
      prefix = n "."
      pad = 4 - length(prefix)
      if (pad < 1) pad = 1
      printf "%s%*s%s\n", prefix, pad, "", rest
      next
    }
    { print }
  ' "$1"
}

cmd_add() {
  local text="$1"
  local last next prefix pad tmp
  last=$(grep -oE '^[0-9]+\.' "$TODO_FILE" | tr -d '.' | sort -n | tail -1)
  last=${last:-0}
  next=$((last + 1))
  prefix="${next}."
  pad=$((4 - ${#prefix}))
  (( pad < 1 )) && pad=1
  tmp=$(mktemp)
  # drop trailing blank lines before appending
  awk '{a[NR]=$0} END{ b=0; for(i=NR;i>0;i--){ if(a[i]=="") b++; else break } for(i=1;i<=NR-b;i++) print a[i] }' "$TODO_FILE" > "$tmp"
  printf "%s%*s%s\n" "$prefix" "$pad" "" "$text" >> "$tmp"
  mv "$tmp" "$TODO_FILE"
}

cmd_done() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ ]] || { echo "done requires a numeric id" >&2; exit 1; }
  grep -qE "^${id}\.[ \t]" "$TODO_FILE" || { echo "no item with id ${id}" >&2; exit 1; }
  local tmp
  tmp=$(mktemp)
  awk -v target="$id" '
    /^[0-9]+\.[ \t]/ {
      match($0, /^[0-9]+/)
      cur = substr($0, 1, RLENGTH)
      skip = (cur == target)
      if (skip) next
      print
      next
    }
    { if (!skip) print }
  ' "$TODO_FILE" > "$tmp"
  renumber "$tmp" > "$TODO_FILE"
  rm -f "$tmp"
}

cmd_show() {
  local id="$1"
  [[ "$id" =~ ^[0-9]+$ ]] || { echo "id must be numeric" >&2; exit 1; }
  grep -qE "^${id}\.[ \t]" "$TODO_FILE" || { echo "no item with id ${id}" >&2; exit 1; }
  awk -v target="$id" '
    /^[0-9]+\.[ \t]/ {
      match($0, /^[0-9]+/)
      cur = substr($0, 1, RLENGTH)
      show = (cur == target)
      if (show) print
      next
    }
    { if (show) print }
  ' "$TODO_FILE"
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
