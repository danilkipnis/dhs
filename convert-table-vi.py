#!/usr/bin/env python3
"""Normalize table-vi.json into three orthogonal files.

table-vi.json nests mental states (MS) inside dharmas inside cases, and stores
membership twice: once as `ms_range` (a printed-order transcription of the
source column) and once as the `ms` array (names, spelled out only where the
source prints them). That duplication is why the network diagram's hand-built
edge list drifted out of sync with the data.

The two relations tangled in `ms_range` are separated here:

  membership  (case, dharma) -> MS number    set semantics, from `ms_range`
  derivation  MS number -> parent MS number  a property of the MS itself

`ms_range` interleaves membership runs with cross-reference marks, e.g. dharma
15 of case 1A reads [[93,112],[93,93],[113,121],[97,97],[122,122]] -- the
[93,93] and [97,97] segments are references back to 93 and 97, which are also
genuine members. Because membership is a set, expanding every segment and
unioning collapses those duplicates without needing to tell marks from members.

Derivation comes from the `no` field instead, which is polymorphic: a plain int
for an ordinary MS, or a 2-element array [parent, own] for the six derived
entries (manayatana<-mano, saddhindriya<-saddha, ...). There `own` is the real
MS number and `parent` is the back-reference. `ms_range`'s singleton segments
cannot be used for this -- dharma 59's [207,207] and [208,208] are ordinary
members, indistinguishable in shape from a reference mark.

Outputs:
  ms.json              MS vocabulary, one row per number (the N dimension)
  ms-membership.json   sparse (dharma-instance -> MS numbers) relation
  table-vi-dharmas.json  cases -> dharma instances, no MS nesting
"""

import json
import re
import sys
from collections import defaultdict

SRC = "table-vi.json"


def expand(ranges):
    """Union every [a,b] segment. Duplicate/reference segments collapse."""
    out = set()
    for seg in ranges:
        a, b = seg
        out.update(range(a, b + 1))
    return out


def split_no(no):
    """-> (real_ms_number, parent_or_None). See module docstring."""
    if isinstance(no, list):
        parent, own = no
        return own, parent
    return no, None


# Table VI's name column sometimes carries "[As in dharma X]", linking this
# dharma to an earlier one -- e.g. 76a reads "as in dharma 2i (vedana)". One
# note can name several ("as in dharmas 15, 19, 28 and 33").
#
# Only notes that OPEN with the phrase are this relation. The other 39 notes
# say "MS 28-34 as in dharma 6", which scopes the borrowing to an MS span, not
# to the dharma as a whole -- that is already carried by ms_range/membership.
AS_IN = re.compile(r"^as in dharmas?\b(.*?)(?:;|$)", re.IGNORECASE | re.DOTALL)


def as_in_targets(note):
    """Dharma numbers this dharma is declared identical to."""
    if not note:
        return []
    m = AS_IN.match(note)
    if not m:
        return []
    # Numbers inside the opening clause only; the parenthesised Pali names
    # carry no digits, so every match is a dharma reference.
    return re.findall(r"\d+[a-z]*", m.group(1))


def main():
    with open(SRC, encoding="utf-8") as fh:
        src = json.load(fh)

    vocab = {}          # ms_no -> {no, pali, translation, derived_from?}
    membership = []     # one row per dharma instance
    dharmas = []        # cases -> dharma instances
    as_in_links = []    # (key, [target dharma numbers])
    problems = []

    for case in src["cases"]:
        case_no = case["case_no"]
        out_dharmas = []

        for d in case["dharmas"]:
            dharma_no = d["no"]
            key = f"{case_no}/{dharma_no}"

            members = expand(d.get("ms_range", []))

            # Names, where the source spells them out. Always a subset of
            # `members`; a violation means ms_range under-reports and the
            # membership relation would silently lose an MS.
            named = set()
            for m in d.get("ms", []):
                ms_no, parent = split_no(m["no"])
                named.add(ms_no)

                # The dharma whose column prints this name. Dharma numbers are
                # globally unique across cases, so this alone identifies it.
                # The diagram groups MS under their owning dharma to lay out
                # the MS row, and only this dharma's entry names the MS -- the
                # others reach it through `ms_range`.
                row = {
                    "no": ms_no,
                    "pali": m["pali"],
                    "translation": m["translation"],
                    "owner_dharma": str(dharma_no),
                }
                if parent is not None:
                    row["derived_from"] = parent

                prev = vocab.get(ms_no)
                if prev is None:
                    vocab[ms_no] = row
                elif (prev["pali"], prev["translation"]) != (row["pali"], row["translation"]):
                    problems.append(
                        f"{key}: MS {ms_no} named both "
                        f"{prev['pali']!r} and {row['pali']!r}"
                    )
                elif "derived_from" in row:
                    prev["derived_from"] = row["derived_from"]

            stray = named - members
            if stray:
                problems.append(f"{key}: MS {sorted(stray)} in `ms` but not in `ms_range`")

            targets = as_in_targets(d.get("note"))
            if targets:
                as_in_links.append((key, targets))

            out_dharma = {
                "no": dharma_no,
                "name_pali": d.get("name_pali"),
                "name_translation": d.get("name_translation"),
                # Dharmas this one is declared identical to, from the name
                # column's "[As in dharma X]" note.
                "as_in": targets,
                # Kept for display only -- it preserves the source's printed
                # range notation, which membership flattens away. Membership is
                # what the graph joins on; never read this as the MS set.
                "ms_range": d.get("ms_range", []),
            }
            if d.get("note"):
                out_dharma["note"] = d["note"]
            out_dharmas.append(out_dharma)

            membership.append({
                "case_no": case_no,
                "dharma_no": dharma_no,
                "ms": sorted(members),
            })

        dharmas.append({"case_no": case_no, "dharmas": out_dharmas})

    # An as-in target naming a dharma that does not exist would draw an edge to
    # nowhere, so it is a hard error rather than a dropped link.
    known = {str(d["no"]) for case in dharmas for d in case["dharmas"]}
    for key, targets in as_in_links:
        for t in targets:
            if t not in known:
                problems.append(f"{key}: 'as in dharma {t}' names an unknown dharma")

    # Every derived_from target must itself be a known MS.
    for ms_no, row in vocab.items():
        parent = row.get("derived_from")
        if parent is not None and parent not in vocab:
            problems.append(f"MS {ms_no} derives from unknown MS {parent}")

    # An MS cited by ms_range but never named anywhere has no vocabulary row --
    # the diagram cannot label it, so membership rows would dangle.
    cited = set()
    for row in membership:
        cited.update(row["ms"])
    unnamed = cited - set(vocab)

    if problems:
        print("VALIDATION FAILED:", file=sys.stderr)
        for p in problems:
            print("  " + p, file=sys.stderr)
        return 1

    write("ms.json", {
        "note": (
            "Mental-state vocabulary for table VI, one row per MS number. "
            "Number -> name is a function: no number carries two names. "
            "`derived_from` marks an MS the source presents as a derivative of "
            "an earlier one (e.g. 113 pannindriya <- 93 panna); it is a "
            "property of the MS, not of any case or dharma."
        ),
        "ms": [vocab[n] for n in sorted(vocab)],
    })

    write("ms-membership.json", {
        "note": (
            "Sparse (dharma-instance -> MS) relation, grouped by instance. "
            "Keyed by case_no + dharma_no, since dharma numbers carry per-case "
            "variants (15, 15a, 6b). Derived from table-vi.json's ms_range, "
            "which is authoritative for membership; the nested `ms` arrays are "
            "only a partial name transcription. Flatten to pairs with "
            "rows.flatMap(r => r.ms.map(n => [r.case_no, r.dharma_no, n]))."
        ),
        "membership": membership,
    })

    write("table-vi-dharmas.json", {
        "note": (
            "Cases and their dharma instances, with MS nesting removed. "
            "Join to ms-membership.json on (case_no, dharma_no)."
        ),
        "cases": dharmas,
    })

    pairs = sum(len(r["ms"]) for r in membership)
    cells = len(membership) * len(vocab)
    print(f"ms.json                {len(vocab)} MS")
    print(f"                       {sum(1 for r in vocab.values() if 'derived_from' in r)} derived")
    print(f"table-vi-dharmas.json  {len(dharmas)} cases, {len(membership)} dharma instances")
    print(f"                       {sum(len(t) for _, t in as_in_links)} as-in links "
          f"from {len(as_in_links)} dharmas")
    print(f"ms-membership.json     {pairs} pairs "
          f"({len(membership)}x{len(vocab)} = {cells} cells, {100 * pairs / cells:.1f}% occupancy)")
    if unnamed:
        print(f"\nnote: {len(unnamed)} MS cited by ms_range are never named in the "
              f"source and have no ms.json row: {sorted(unnamed)}")
    return 0


def write(path, obj):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


if __name__ == "__main__":
    sys.exit(main())
