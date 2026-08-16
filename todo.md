# TODO

1.  Add translation: ISBN 978-5-389-18363-6
2.  Add translation: Dhammasangani, traduction annotée par A. Bareau (Centre de
    Documentation Universitaire, Paris, 1951)
3.  Add translation: Caroline A. F. Rhys Davids, A Buddhist Manual of
    Psychological Ethics of the Fourth Century B.C. (Dhamma-Saṅgaṇi), Pali Text
    Society Translation Series No. 41, 1900,
    https://archive.org/details/buddhistmanualof00davirich
4.  Transcribe the cases (not in table-v only but in the book, not
    in the book)
5.  Iterate on search function
6.  Add a note that the graph is potentially a simplification because nowhere
    in the text does it say that dharmasets from vi are strict subsets of the
    dharmasets in table vii. If it is required two additional entities would
    have to be introduced in order to cover for that. Or one. (exactly one
    layer "subsets" inbetween cases and dharmas)
7.  Die Gewichtung
9.  Table IX, p. 152
10. Table X, p. 155
11. Cleanup js code
12. Cleanup Claude's notes in json
13. QA OCR
14. Add vertical (up/down keys) navigation to the popups. Up-one level on the er
plane (e.g. from Cases to the connected item in the Sphere of Thought if any. Or
down: from cases to the dharmas level). Pick first item if there are several
matching entries. There are multiple er levels (entities) above e.g. the Cases
level: t,s,mv,o,etc. Encode following rule: If there are entries from multiple
entities("levels on er plane") connected to the given one on the(level) up or
down, pick the first one (meaning the one located on the left in the view, the
first one if sorting the currently displayed neighboring entries by their
corresponding x axis in the view). E.g. for Cases we have three positions as
for now: "above cases" (t,s,mv,o, etc.), "the cases (same level as the current
entry)", and "below cases". We are only interested in the above and below
levels, since entries on the same level are already handled by the left/right
buttons/keys. Just handle the keyboard up/down, do not add buttons into the popup.
