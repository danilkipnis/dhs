
[index](https://danilkipnis.github.io/dhs/index.html)

[ER](https://danilkipnis.github.io/dhs/er.html)

### Navigation keys

With a tooltip pinned, arrow keys (or WASD) move between nodes: left/right
step along the current row, up/down cross to a connected row above/below, and
Tab walks every node on the row left-to-right, crossing between entity types
and wrapping at the end (Shift+Tab walks it right-to-left). `M` opens/closes
the sidebar; Escape closes it if
open. `+`/`-` zoom in/out; `O` (or a keyboard's dedicated mute key) toggles
sound. All of this is disabled while typing in the search box.

### Table VI is normalized by a script

`table-vi.json` nests mental states inside dharmas inside cases, and records
membership twice — as `ms_range` (a transcription of the printed column) and as
the `ms` array (names, spelled out only where the source prints them).
`convert-table-vi.py` separates the relations tangled there into three files:

| file | |
|---|---|
| `ms.json` | mental-state vocabulary, one row per number (355) |
| `ms-membership.json` | sparse (dharma → mental state) relation (1642 pairs) |
| `table-vi-dharmas.json` | cases → dharma instances, mental states unnested |

`ms_range` is authoritative for membership; the `ms` arrays are a partial name
transcription and are a subset of it in every case. The converter fails rather
than emit bad data if that stops holding, if a number acquires two names, or if
an "as in" reference names a dharma that does not exist.

`make` regenerates these when `table-vi.json` changes; `make check` fails if the
committed copies differ from a fresh run.

## Why table VII's sets are "supersets"

Table VII gives, per case, the full set of dharma numbers belonging to it. That
set contains table VI's on both axes: table VII names 26 cases where table VI
transcribes 15, and for every case in both, table VI's dharma set is a subset of
table VII's — a strict subset in 14 of the 15, equal only at case 1A. So table VII
is the roster and table VI the detail, and the 667 green case–dharma edges are
exactly what table VII knows and table VI has not yet recorded.

## Provenance

Everything transcribed here — the
selection and arrangement of the tables, the English translations of the Pāli
terms, the paragraph and page references — is Piatigorsky's work, from the 1984
book ([archive.org](https://archive.org/details/buddhistphilosop0000piat)); the
primary source is
[there too](https://archive.org/details/in.ernet.dli.2015.314228).
