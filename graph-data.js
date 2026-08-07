// The table-vi half of the graph: MS vocabulary, dharma instances, and every
// edge incident on an MS node, all derived from the normalized table-vi files
// so table-vi.json stays the single source of truth.
//
// Membership comes from ms-membership.json, which is expanded from `ms_range`.
// The old hand-maintained edge list only wired each MS to the dharma that
// *names* it plus a partial set of cross-references, so borrowed MS spans were
// unevenly connected -- e.g. dharma 63 of case 144A reached nothing at all.
// Deriving edges from membership covers every span uniformly.
// Derive the whole graph from the per-table source files. Every array the
// renderer reads is built here, so the source tables in the repo are the only
// data -- nothing is duplicated into this file. Verified to reproduce the
// previous hand-maintained blob exactly, all 29 arrays, order-insensitive.
function buildGraphData(F){
  const {t3,t4,t5,t5c,t5cf,t5m,t5o,t5s,t5t,t5tr,t7,t8} = F;
  const data = {};
  const warn = [];

  // "12-15" -> 12,13,14,15; anything else is a single token.
  const expand = s => {
    const m = /^(\d+)-(\d+)$/.exec(String(s));
    if(!m) return [String(s)];
    const out=[]; for(let i=+m[1]; i<=+m[2]; i++) out.push(String(i));
    return out;
  };

  // ---------- case-id universe ----------
  // No single table lists every case: table-v has the fully-described ones,
  // Table-viii adds those with only a paragraph cite, and table-iii/iv add
  // letter-suffixed ones (222a/222b appear nowhere else).
  const t5byCase = new Map(t5.rows.map(r => [String(r.case_id), r]));
  const t8byCase = new Map(), t8range = new Map();
  for(const r of t8){
    for(const cid of expand(r.case_id)){
      t8byCase.set(cid, r);
      // Remember the printed range so a case can cite "158-161" as its source.
      if(!/^\d+$/.test(String(r.case_id))) t8range.set(cid, r.case_id);
    }
  }
  const universe = new Set([...t5byCase.keys(), ...t8byCase.keys()]);
  for(const row of t3.rows) for(const c of row.cases) expand(c).forEach(x=>universe.add(x));
  for(const row of t4.rows) for(const c of row.cases) expand(c).forEach(x=>universe.add(x));
  for(const row of [...t5s, ...t5t]) for(const c of (row.cases||[])) universe.add(String(c));

  const caseKey = cid => {
    const m = /^(\d+)([a-z]?)$/.exec(cid);
    return m ? [+m[1], m[2]] : [Number.MAX_SAFE_INTEGER, cid];
  };
  const orderedCases = [...universe].sort((a,b)=>{
    const ka=caseKey(a), kb=caseKey(b);
    return ka[0]!==kb[0] ? ka[0]-kb[0] : (ka[1]<kb[1] ? -1 : ka[1]>kb[1] ? 1 : 0);
  });

  // table-vii labels a case "1A"/"119A"; the numeric/letter stem is the case.
  const REF = /^(\d+[a-z]?)([A-Z])$/;
  const variants = new Map();
  for(const e of t7.entries){
    const m = REF.exec(e.case_ref);
    if(!m){ warn.push(`table-vii case_ref not parseable: ${e.case_ref}`); continue; }
    if(!variants.has(m[1])) variants.set(m[1], []);
    variants.get(m[1]).push(e.case_ref);
  }
  const caseOf = ref => { const m = REF.exec(ref); return m ? m[1] : null; };

  data.cases = orderedCases.map(cid => {
    const r = t5byCase.get(cid);
    const c = {
      id: 'case-'+cid, case_id: cid, label: cid,
      stub: !r,                                   // no table-v row: cite only
      nomenclature_id: r ? r.nomenclature_id : null,
      sphere_id:       r ? r.sphere_id       : null,
      content_ids:     r ? r.content_ids     : null,
      trancic_id:      r ? r.trancic_id      : null,
      object_ids:      r ? r.object_ids      : null,
      mental_ids:      r ? r.mental_ids      : null,
      case_no_variants: variants.get(cid) || [],
    };
    if(t8byCase.has(cid)){
      c.paragraph = t8byCase.get(cid).paragraph;
      c.pages     = t8byCase.get(cid).pages;
      if(t8range.has(cid)) c.paragraph_case_range = t8range.get(cid);
    }
    return c;
  });

  // ---------- table-iii / table-iv ----------
  data.nomenclature = t3.rows.map(r => ({
    id:'nom-'+r.term_id, term_id:String(r.term_id), term_pali:r.term, translation:r.translation,
  }));

  // Only char_dharma is an actual table-iv field. The thought/action qualities
  // the diagram used to show were parsed out of the English translation, which
  // is guesswork rather than data, so they are not derived at all.
  data.spheres = t4.rows.map(r => ({
    id:'sph-'+r.sphere_id, sphere_id:String(r.sphere_id), sphere_pali:r.sphere,
    translation:r.translation, avacara:r.avacara,
    avacara_inferred: r.avacara_inferred ?? false,
    char_dharma:r.char_dharma,
  }));
  data.avacaras = Object.entries(t4.lookups.avacara).map(([k,v]) => ({id:'av-'+k, key:k, gloss:v}));
  data.quality_dharma = Object.entries(t4.lookups.char_dharma)
    .map(([k,v]) => ({id:'qd-'+k, letter:k, gloss:v}));

  // ---------- table-v dimension tables ----------
  data.content = t5c.rows.map(r => ({
    id:'ct-'+r.id, content_id:r.id, pali:r.pali, translation:r.translation,
    label: r.label ?? null, parent_id: r.parent_id ?? null,
  }));
  // Verbatim rows, note/book_no included: the sidebar prints the full gloss.
  data.content_defs = Object.fromEntries(t5c.rows.map(r => [r.id, r]));
  data.content_footnotes = t5cf.links.map(l => ({case_id:l.case_id, content_id:l.content_id}));
  data.trancic = t5tr.rows.map(r => ({id:'tv-'+r.id, trancic_id:String(r.id), pali:r.pali, translation:r.translation}));
  data.mental  = t5m.rows.map(r => ({id:'mv-'+r.id, mental_id:String(r.id), pali:r.pali, translation:r.translation}));
  data.sense_objects   = t5o.sense_objects.map(r => ({id:'so-'+r.id, object_id:String(r.id), translation:r.translation}));
  data.dhyanic_objects = t5o.dhyanic_objects.map(r => ({id:'do-'+r.id, object_id:String(r.id), pali:r.pali, translation:r.translation}));

  // ---------- table-vii supersets ----------
  data.supersets = t7.entries.map(e => ({
    id:'sup-'+e.id, label:e.id, case_ref:e.case_ref, case_num:caseOf(e.case_ref),
    count:e.count, transcribed_in_table_vi:e.transcribed_in_table_vi, note: e.note ?? null,
  }));

  // ---------- edges ----------
  const caseEdges = (rows, from) =>
    rows.flatMap(r => r.cases.flatMap(x => expand(x).map(c => ({from: from(r), to:'case-'+c}))));

  data.nomenclature_case_edges = caseEdges(t3.rows, r=>'nom-'+r.term_id);
  data.sphere_case_edges       = caseEdges(t4.rows, r=>'sph-'+r.sphere_id);
  data.avacara_sphere_edges       = t4.rows.map(r=>({from:'av-'+r.avacara,      to:'sph-'+r.sphere_id}));
  data.quality_dharma_sphere_edges= t4.rows.map(r=>({from:'qd-'+r.char_dharma,  to:'sph-'+r.sphere_id}));

  data.content_case_edges = t5.rows.flatMap(r =>
    (r.content_ids||[]).map(cid => ({from:'ct-'+cid, to:'case-'+r.case_id})));
  data.trancic_case_edges = t5.rows.flatMap(r => {
    const t = r.trancic_id;
    if(t == null) return [];
    return (Array.isArray(t)?t:[t]).map(x => ({from:'tv-'+x, to:'case-'+r.case_id}));
  });
  data.mental_case_edges = t5.rows.flatMap(r =>
    (r.mental_ids||[]).map(m => ({from:'mv-'+m, to:'case-'+r.case_id})));

  // object_ids mixes both object kinds in one column; brackets mark dhyanic.
  data.sense_object_case_edges = [];
  data.dhyanic_object_case_edges = [];
  for(const r of t5.rows){
    const o = r.object_ids;
    if(o == null) continue;
    for(const it of (Array.isArray(o)?o:[o])){
      const m = /^\[(.+)\]$/.exec(String(it));
      const target = m ? data.dhyanic_object_case_edges : data.sense_object_case_edges;
      const pre = m ? 'do-' : 'so-';
      for(const x of expand(m ? m[1] : it)) target.push({from:pre+x, to:'case-'+r.case_id});
    }
  }

  data.superset_case_edges = t7.entries.map(e => ({from:'sup-'+e.id, to:'case-'+caseOf(e.case_ref)}));

  // Dharma numbers carry per-case letter variants (6, 6a, 6b). A printed range
  // keeps its suffix across the run: "12a-15a" is 12a,13a,14a,15a -- expanding
  // it as bare integers would point at another case's dharmas.
  const dharmaTokens = raw => {
    const out = [];
    for(let part of String(raw).split(',')){
      part = part.trim();
      if(!part) continue;
      const rng = /^(\d+)([a-z]*)-(\d+)([a-z]*)$/.exec(part);
      if(rng){
        if(rng[2] !== rng[4]){ warn.push(`mixed-suffix dharma range "${part}"`); continue; }
        for(let i=+rng[1]; i<=+rng[3]; i++) out.push(i + rng[2]);
        continue;
      }
      if(/^\d+[a-z]*$/.test(part)){ out.push(part); continue; }
      // Prose such as "as in D9" / "plus Δ63": carried by based_on and
      // additional_dharmas instead, so it is not a token.
      if(!/^(as in|plus)/i.test(part)) warn.push(`unparsed dharma notation "${part}"`);
    }
    return out;
  };
  const byId = new Map(t7.entries.map(e => [e.id, e]));
  const resolve = (e, seen = new Set()) => {
    if(seen.has(e.id)){ warn.push(`based_on cycle at ${e.id}`); return []; }
    seen.add(e.id);
    let out = dharmaTokens(e.dharmas_raw);
    if(e.based_on){
      const base = byId.get(e.based_on);
      if(!base) warn.push(`${e.id}: based_on "${e.based_on}" not found`);
      else out = out.concat(resolve(base, seen));
    }
    for(const extra of (e.additional_dharmas || [])) out.push(String(extra));
    return [...new Set(out)];
  };
  data.superset_dharma_edges = [];
  for(const e of t7.entries){
    const ds = resolve(e);
    // The entry declares its own size; a mismatch means the notation was
    // misread, which would silently add or drop dharmas.
    if(ds.length !== e.count) warn.push(`${e.id}: expanded ${ds.length} dharmas but count says ${e.count}`);
    for(const d of ds) data.superset_dharma_edges.push({from:'sup-'+e.id, to:'dh-'+d});
  }

  return {data, warn};
}

function buildTableVi(data, vocab, membership, dharmaFile){

  // --- MS vocabulary: one node per MS number (number -> name is a function) ---
  data.ms = vocab.ms.map(m => ({
    id: 'ms-' + m.no,
    no: m.no,
    pali: m.pali,
    translation: m.translation,
    owner_dharma: m.owner_dharma,
    derived_from: m.derived_from ?? null,
  }));

  // --- Dharma instances. quality and owner_case are the case_no's letter
  // suffix and numeric stem; dharma numbers are globally unique across cases,
  // so the dharma number alone is a stable node id. ---
  const msNamedBy = new Set(vocab.ms.map(m => m.owner_dharma));
  data.dharmas = [];
  data.dharma_case_edges = [];
  const dharmaCase = new Map();          // dharma_no -> case_no
  for(const c of dharmaFile.cases){
    const caseNo = c.case_no;
    const caseNum = caseNo.slice(0, -1), quality = caseNo.slice(-1);
    for(const d of c.dharmas){
      const id = String(d.no);
      dharmaCase.set(id, caseNo);
      data.dharmas.push({
        id: 'dh-' + id,
        dharma_id: id,
        name_pali: d.name_pali,
        name_translation: d.name_translation,
        owner_case: caseNum,
        quality: quality,
        source_case_no: caseNo,
        ms_range: d.ms_range || [],
        note: d.note ?? null,
        // No MS names printed here: the source deferred to another dharma.
        xref: !msNamedBy.has(id),
        as_in: d.as_in || [],
      });
      data.dharma_case_edges.push({from: 'dh-' + id, to: 'case-' + caseNum});
    }
  }

  // --- Dharma -> dharma "as in". Table-vi's name column declares some dharmas
  // identical to an earlier one (76a reads "as in dharma 2i"); one note can name
  // several. Both endpoints sit on the dharma row, so curve() bows these into an
  // arc, the same treatment as MS derivation on the MS row. ---
  data.dharma_as_in_edges = [];
  for(const c of dharmaFile.cases){
    for(const d of c.dharmas){
      for(const t of (d.as_in || [])){
        data.dharma_as_in_edges.push({from: 'dh-' + d.no, to: 'dh-' + t});
      }
    }
  }

  // --- Table-vii's contribution, as case->dharma edges rather than a row of
  // superset nodes. A superset Dn is just "the dharmas of case X", so it says
  // the same kind of thing the table-vi edges do and belongs on the same two
  // rows. Pairs table-vi already states are skipped -- drawing a dashed line
  // over an identical solid one would only thicken it. What is left is exactly
  // what table-vii adds: cases table-vi never transcribed, and dharmas beyond
  // the ones it did. ---
  const viPairs = new Set(data.dharma_case_edges.map(e => e.to + '|' + e.from));
  const supersetCase = new Map(
    data.superset_case_edges.map(e => [e.from, e.to])
  );
  const seenVii = new Set();
  data.dharma_case_vii_edges = [];
  for(const e of data.superset_dharma_edges){
    const caseId = supersetCase.get(e.from);
    if(!caseId) continue;                       // superset with no case edge
    const key = caseId + '|' + e.to;
    if(viPairs.has(key) || seenVii.has(key)) continue;
    seenVii.add(key);
    data.dharma_case_vii_edges.push({from: e.to, to: caseId, superset: e.from.replace('sup-','')});
  }


  // --- MS edges, straight off the membership relation. An edge is a cross-ref
  // when this dharma is not the one that names the MS. ---
  // MS-to-dharma is the only relation an MS participates in. Dharma sets and
  // supersets are sets of dharmas, so they are reached transitively and get no
  // MS edges of their own.
  const ownerOf = new Map(vocab.ms.map(m => [m.no, m.owner_dharma]));
  data.ms_edges = [];
  const dharmaMs = new Map();            // dharma_no -> [ms numbers]
  for(const row of membership.membership){
    const dId = String(row.dharma_no);
    dharmaMs.set(dId, row.ms);
    for(const n of row.ms){
      data.ms_edges.push({
        from: 'ms-' + n,
        to: 'dh-' + dId,
        // A cross-ref is a dharma that borrows the MS via `ms_range` rather
        // than being the dharma whose column prints its name.
        xref: ownerOf.get(n) !== dId,
      });
    }
  }

  // --- MS -> MS derivation. The source prints a handful of entries as
  // derivatives of an earlier MS (122 sammadit.t.hi <- 97 dhammavicaya,
  // 113 pannindriya <- 93 panna, ...). Both endpoints sit on the MS row, so
  // curve() bows these into an arc rather than a flat line. ---
  data.ms_derivation_edges = data.ms
    .filter(m => m.derived_from != null)
    .map(m => ({from: 'ms-' + m.derived_from, to: 'ms-' + m.no}));

  const orphans = data.ms.filter(m => !dharmaMs.has(m.owner_dharma)).length;
  if(orphans) console.warn(`${orphans} MS name a dharma with no membership row`);
  return data;
}

// Every table the diagram draws, keyed as buildGraphData() expects.
const SOURCES = {
  t3:'table-iii.json', t4:'table-iv.json', t5:'table-v.json',
  t5c:'table-v-content.json', t5cf:'table-v-content-footnotes.json',
  t5m:'table-v-mental.json', t5o:'table-v-objects.json',
  t5s:'table-v-sphere.json', t5t:'table-v-thought.json',
  t5tr:'table-v-trancic.json', t7:'table-vii.json', t8:'Table-viii.json',
  t11:'table-xi.json',
  vocab:'ms.json', membership:'ms-membership.json', dharmaFile:'table-vi-dharmas.json',
};

// --- Table-xi's homonym groups, as dharma_id -> [other dharma_ids sharing a
// name]. Each entry's parent+children form one mutually-homonymous group; a
// "see" entry (dharma 36) carries no children of its own and instead points
// at the entry that already lists it, so its group is borrowed from there. ---
function dharmaSortKey(idStr){
  const m = String(idStr).match(/^(\d+)([a-zA-Z]*)$/);
  if(!m) return [1e9, String(idStr)];
  return [parseInt(m[1],10), m[2]];
}
function dharmaCmpKey(a,b){
  const ka = dharmaSortKey(a), kb = dharmaSortKey(b);
  if(ka[0]!==kb[0]) return ka[0]-kb[0];
  return ka[1]<kb[1] ? -1 : ka[1]>kb[1] ? 1 : 0;
}
function buildHomonymGroups(table){
  const links = new Map();     // id -> Set of homonymous ids
  const seeTargets = new Map(); // id -> id it defers to
  function link(a,b){
    if(a===b) return;
    if(!links.has(a)) links.set(a, new Set());
    if(!links.has(b)) links.set(b, new Set());
    links.get(a).add(b);
    links.get(b).add(a);
  }
  for(const e of table.entries){
    if(e.see){ seeTargets.set(e.parent, e.see); continue; }
    const group = [e.parent, ...e.children];
    for(let i=0;i<group.length;i++){
      for(let j=i+1;j<group.length;j++) link(group[i], group[j]);
    }
  }
  for(const [id, target] of seeTargets){
    for(const t of (links.get(target) || [])) link(id, t);
    link(id, target);
  }
  const out = {};
  for(const [id, set] of links){
    out[id] = Array.from(set).sort(dharmaCmpKey);
  }
  return out;
}

// Fetches every source table and returns the fully built graph data
// ({data, warn}), so any page that needs the tables -- the main diagram, the
// standalone ER diagram -- shares this one pipeline instead of re-deriving it.
async function loadGraphData(){
  const entries = await Promise.all(Object.entries(SOURCES).map(async ([k,f]) => {
    const res = await fetch(f);
    if(!res.ok) throw new Error(`${f}: HTTP ${res.status}`);
    return [k, await res.json()];
  }));
  const F = Object.fromEntries(entries);
  const built = buildGraphData(F);
  buildTableVi(built.data, F.vocab, F.membership, F.dharmaFile);
  built.data.homonyms_by_dharma = buildHomonymGroups(F.t11);
  return {data: built.data, warn: built.warn, F};
}
