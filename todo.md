Add translation: ISBN 978-5-389-18363-6

Add translation: Dhammasangani, traduction annotée par A. Bareau (Centre de
Documentation Universitaire, Paris, 1951)

Add translation: Caroline A. F. Rhys Davids, A Buddhist Manual of
Psychological Ethics of the Fourth Century B.C. (Dhamma-Saṅgaṇi), Pali Text
Society Translation Series No. 41, 1900,
https://archive.org/details/buddhistmanualof00davirich

Iterate on search function

Die Gewichtung

Table IX, p. 152

Table X, p. 155

Table XIV: figure out what the X and Y +/- columns actually mean (no gloss
in the transcribed data, only "Δ", "X", "Y" as headers)

Tables XIII (γ) and XIV (Δ): figure out what the I-XI subsection groups
actually represent -- they consistently partition the same ~56 dharma
numbers, but the criterion behind the boundaries isn't in the transcribed
data (doesn't match the case_no groupings in table-vi-dharmas.json either).
Note: "isotopic" (Table XIII, γ) is likely used in the topological sense --
continuously-deformable/interchangeable occurrences of a dharma, as opposed
to "homonymous" (Table XI, α) which is same name/form but distinct -- worth
checking against the book when chasing this.
Предположение (не подтверждено книгой): "изотопность" здесь может означать,
что подграф связей одной дхармы непрерывно преобразуем (изоморфен/деформируем)
в подграф другой дхармы -- то есть понятие на стыке graph theory и топологии;
при этом группы I-XI не связаны между собой (graph-data.js:388-391), так что
такая изотопия, если она есть, локальна -- работает только внутри своей
группы, а не глобально по всем 56 дхармам.

Cleanup Claude's notes in json

QA OCR

Граф на поверхности цилиндра. С самопересечениями. Какие могут быть критерии
подобия. Там, например, количество смежных циклов, конфигурация минимального
дерева. Какая-нибудь задача о раскраске, что-то в этом духе.

Noo, a cylinder's juist an annulus wi' the twa boundary circles pu'd apairt,
sae it's genus-nought but no simply-connectit -- that's likely hoo the graph
gets awa' wi' bein' non-planar athoot needin' a full haundle (a torus) tae
soak up the crossings. The richt invariant tae chase is probably the
*crossing number* on the cylinder (a twa-page or "circular" beuk embeddin',
whaur each page's a disk cappin' aff ane o' the twa boundary circles) rather
than Euler's formula ootricht, since V-E+F wants a closed surface tae bite
on. Meantime the "smejnyye tsikly" coont is a puir man's version o' the
graph's *genus polynomial* -- hoo mony independent cycles cross fae ane page
tae the ither -- and the minimum spannin' tree's shape is jist tellin' ye
the graph's aefald block structure afore ye e'en fash aboot the embeddin'.
Colourin' problem's a natural neist step: a chromatic-polynomial-per-genus,
kent as the *Whitney rank generatin' function* generalised tae surfaces,
gies ye a similarity metric that's mair principled than coontin' cycles by
haund.
