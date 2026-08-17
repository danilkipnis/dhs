#!/bin/bash
# Usage: todo.sh [add <text> | done <id> | show <id> | list | grep <pattern>]
#   (no args)      print usage
#   add <text>     append a new item at the end
#   done <id>      remove that item
#   show <id>      print that item's description
#   list           print all items as an "id"/"description" table
#   grep <pattern> like list, but only items whose description matches
#
# Items have no stored id: todo.md is items separated from each other by
# a blank line. <id> is an item's position (1st, 2nd, ...), counted top to
# bottom each time the script runs -- so ids shift down when an earlier
# item is done.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TODO_FILE="$SCRIPT_DIR/todo.md"

usage() {
  echo "Usage: $(basename "$0") [add <text> | done <id> | show <id> | list | grep <pattern>]" >&2
  exit "${1:-1}"
}

# Prints "<first-line> <last-line>" (1-indexed, inclusive) of item <id>'s
# block in todo.md, found by counting blank-line-separated blocks of
# non-blank lines. Prints nothing if there's no such item.
item_line_range() {
  local id="$1"
  awk -v want="$id" '
    /^[ \t]*$/ { in_block = 0; next }
    {
      if (!in_block) { in_block = 1; block++ }
      if (block == want) { if (!start) start = NR; end = NR }
    }
    END { if (start) print start, end }
  ' "$TODO_FILE"
}

# Prints "<id>\t<description>" for every item, one per line, with a
# multi-line item's description joined into a single line.
items_table() {
  awk '
    /^[ \t]*$/ { if (in_block) { print id "\t" desc; in_block = 0 } next }
    {
      if (!in_block) { in_block = 1; id++; desc = $0 }
      else desc = desc " " $0
    }
    END { if (in_block) print id "\t" desc }
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
  # trim leading and trailing blank lines
  awk '
    { a[NR] = $0 }
    END {
      s = 1; while (s <= NR && a[s] ~ /^[ \t]*$/) s++
      n = NR; while (n >= s && a[n] ~ /^[ \t]*$/) n--
      for (i = s; i <= n; i++) print a[i]
    }
  ' "$tmp" > "$TODO_FILE"
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

cmd_list() {
  { printf "id\tdescription\n"; items_table; } | column -t -s "$(printf '\t')"
}

cmd_grep() {
  local pattern="$1"
  { printf "id\tdescription\n"; items_table | awk -F'\t' -v pat="$pattern" '$2 ~ pat'; } \
    | column -t -s "$(printf '\t')"
}

case "${1:-}" in
  "")
    usage 0
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
  show)
    [[ $# -eq 2 ]] || usage
    cmd_show "$2"
    ;;
  list)
    [[ $# -eq 1 ]] || usage
    cmd_list
    ;;
  grep)
    [[ $# -eq 2 ]] || usage
    cmd_grep "$2"
    ;;
  *)
    usage
    ;;
esac
