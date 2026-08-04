# Rise of thought in the *Dhammasangani* — a network diagram

An interactive diagram of the cases of rise of thought described by tables III–VIII
of Essay 5, "Rise of Thought as Phenomenon and System," of Alexander
Piatigorsky's *The Buddhist Philosophy of Thought: Essays in Interpretation*
(1984).

**→ [danilkipnis.github.io/dhs](https://danilkipnis.github.io/dhs/)**

The tables cross-reference each other heavily: a case cites a sphere of thought,
which decomposes into an avacāra and a character of dharmas; it cites nomenclature
terms, content variants, trancic and mental variables, sense and dhyanic objects;
and it resolves into dharmas, which resolve into mental states. Read on the page
this is hard to hold in view at once. Drawn as one graph it is legible, and the
gaps in the transcription become visible too.

Click any node to see what it connects to. Click **ER** in the description bar for
the entity–relationship diagram of the underlying data structure.

## The six levels

Most general at the top, each level spanning many of the one below:

| | |
|---|---|
| character of dharmas · avacāra | table IV's two axes — 3 and 4 entries |
| sphere of thought · nomenclature of thought | tables IV and III — 13 and 9 |
| content variants · trancic variables · sense objects · dhyanic objects · mental variables | table V's dimension tables — 48, 16, 6, 22, 15 |
| cases | table V (109 fully described) plus those known only from a citation — 273 in all |
| dharmas | table VI — 155 instances across the 15 cases transcribed so far |
| mental states | table VI — 355 |

Two relations run *along* a row rather than between rows, drawn as arcs: a mental
state printed as a derivative of an earlier one (6 of these — MS 122 "correct
view" from MS 97, MS 113 from MS 93), and a dharma whose name column declares it
"as in" an earlier dharma (153 links from 74 dharmas — Δ76a is "as in Δ2i").

## Data

Each `table-*.json` is a transcription of the corresponding table. They are the
only data; `index.html` fetches them and derives every node and edge at load time.

| file | table |
|---|---|
| `table-iii.json` | III, nomenclature of thought |
| `table-iv.json` | IV, sphere of thought |
| `table-v.json` + `table-v-{content,trancic,mental,objects,sphere,thought}.json` | V, cases and their dimension tables |
| `table-vi.json` | VI, dharmas and their mental states |
| `table-vii.json` | VII, sets of dharmas |
| `Table-viii.json` | VIII, paragraph and page citations |

Transcription is incomplete and the files say where. Table VI covers 15 of the
cases table VII names; `transcribed_in_table_vi` marks which. A case with no
table V row is drawn as a stub, known only from its citation in table VIII.

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

## Running it locally

```
make serve      # http://localhost:8000/index.html
```

Serving over HTTP is required — `fetch()` is blocked on `file://` URLs, so opening
`index.html` directly shows a load error rather than a diagram. `make help` lists
the other targets.

## Why table VII's sets are "supersets"

Table VII gives, per case, the full set of dharma numbers belonging to it. That
set contains table VI's on both axes: table VII names 26 cases where table VI
transcribes 15, and for every case in both, table VI's dharma set is a subset of
table VII's — a strict subset in 14 of the 15, equal only at case 1A. So table VII
is the roster and table VI the detail, and the 667 green case–dharma edges are
exactly what table VII knows and table VI has not yet recorded.

## Provenance

The *Dhammasangani* itself is ancient. Everything transcribed here — the
selection and arrangement of the tables, the English translations of the Pāli
terms, the paragraph and page references — is Piatigorsky's work, from the 1984
book ([archive.org](https://archive.org/details/buddhistphilosop0000piat)); the
primary source is
[there too](https://archive.org/details/in.ernet.dli.2015.314228).
No claim is made over any of it.

If you hold rights in the book and would like something here changed or removed,
please open an issue.
