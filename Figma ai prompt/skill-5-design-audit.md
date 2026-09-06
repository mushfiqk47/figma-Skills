# Skill 5: Design Audit — Full End-to-End File Check + Report (MCP-only, JSON, No Vision)

**Trigger:** user says "audit the design / check everything / give me a report" and names a Figma file, page, or frame (URL with `fileKey` + `nodeId`, or page/frame name).
**Role:** read-only auditor and reporter. Checks the WHOLE file end to end — structure, tokens, variable bindings, missing/uncreated values, modes, color contrast, components, naming, auto-layout, content — and returns one JSON report + fix queue. Makes ZERO canvas edits (hands fixes to Skills 1–4, 3).
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. `use_figma` is FORBIDDEN in this skill (audit never mutates). Evidence = MCP JSON only.
Shared rules (naming, enums, handoff schema) live in agent.md §0.6.

## 0. Allowed tools + budget
`get_metadata` · `get_design_context` (ONE small nodeId at a time, never a whole page) · `get_variable_defs` · `search_design_system` · `get_libraries`. No writes. Order cheap → expensive: page list → page outline → variable defs → libraries → targeted single-node contexts.
**Node budget:** max 8 `get_design_context` calls per audit. Pick order: (1) named screens/frames, (2) frames with the most instances, (3) frames with the most fills/text. If the file exceeds budget, audit those 8 and report `{ sampled: true, sampledNodeIds: [...], skippedEstimate: n }` — never silently claim full coverage.

## 1. Locate + scope + expected set (read-only, in this order)
1. URL → `fileKey` + `nodeId`. No URL → `get_metadata` (no nodeId) → list pages → ask which page/frame, or audit the page user named.
2. `get_metadata` on scope → frame/component inventory (`nodeId`, `name`, `type`). `get_variable_defs` on scope → collections, modes, variables, alias targets. `get_libraries` + `search_design_system` → what SHOULD have been reused.
3. **Expected set (required for the missing-tokens check):** a Skill-4 IR array, a `design.md`/`tokens.json` pasted in context, or an explicit approved token list. Present in context → `missing` = expected names absent from `get_variable_defs`. Absent → the token-inventory pass reports `{ expectedSet: "unknown-expected-set" }` and covers only unbound/hardcoded/dangling findings — never invent a missing list.
4. State scope out loud: `{ fileKey, scopeNodeId, nodesChecked, sampled }`. Never report numbers you did not query this session.

## 2. Seven passes — run all seven, JSON only
Emit one block each, exact shape:
```json
{ "v": 1, "pass": "token-bindings", "ok": false, "counts": { "checked": 0, "failed": 0 }, "issues": [{ "severity": "❌|⚠️", "nodeId": "1:2", "name": "Hero/Button", "check": "binding-missing", "detail": "raw hex #3B82F6 in fills, expected color/action/primary", "fix": "skill-3" }] }
```
1. **file-structure** (`get_metadata`): page order Cover → Foundations → Components → Utilities; orphan pages; top-level stacking at (0,0); empty frames. Missing-page → `fix: "skill-3"`.
2. **token-inventory** (`get_variable_defs` + expected set): collections exist? `Mode 1` still unrenamed? primitives vs semantic vs component-tier present? Unscoped (`ALL_SCOPES`)? Names failing the §0.6 regex? Semantic→semantic chains (must be one hop to primitive)? Every semantic valued in EVERY mode? Dangling alias targets? Expected-but-absent names → `{ created: false, missing: true }` (only with an expected set; else `expectedSet: "unknown-expected-set"`).
3. **token-bindings** (`get_design_context` per sampled node): every fill / text-fill / stroke / gap / padding / radius / size bound? Raw hex/px where a token belongs? Primitive bound directly to a layer (must be semantic)? Per-property verdict: `connected | hardcoded | missing-token | primitive-direct`.
4. **modes** (`get_variable_defs` values): Light + Dark (or Brand A/B) resolve per variable? Single-mode variables flagged; plan-limit risk (Free=1, Pro≤4) noted; which frame resolves against which mode.
5. **color-contrast** (computed in JS from variable values + bound pairs, never eyes): pair discovery = each sampled TEXT node + nearest ancestor fill walking up ≤3 levels (text-fill token value vs ancestor fill token value, per mode). Luminance math → AA 4.5:1 normal / 3:1 large+UI. Report `{ pair, mode, ratio, required, verdict }`. Unresolvable pairs (unbound fill) → `verdict: "uncheckable"` with reason, never a guessed ratio. Failures point at the TOKEN (`fix: "skill-1"`), not the instance.
6. **component-health** (`get_metadata` + `get_design_context` + `search_design_system`): non-semantic names (`Frame 47`, `Group 12`, `Rectangle 8`); list/row/grid missing `layoutMode`; detached duplicates of library components; variant sets with fake/placeholder option names; missing focus/hover/disabled/error variants on interactives; instances vs redrawn copies.
7. **content-health** (`get_design_context` `characters`): Lorem ipsum / "Button text" / empty text layers; unverified `DRAFT` copy; text failing Skill-2 `maxChars`; glossary violations (only if a Skill-2 glossary is in context, else flag `glossary: absent`); body text < 12px; icon-only meaning (no paired label).

## 3. Scoring + management report (always ends with this)
Per-pass score = `checked === 0 ? "n/a" : round(100 * (checked - failed) / checked)`. Overall = mean of scored passes (`"n/a"` if none scored). Verdict: `SHIP | FIX-FIRST | REBUILD` (`REBUILD` only if token-inventory + bindings both < 50). Then:
```json
{ "v": 1, "skill": 5, "scope": { "fileKey": "…", "nodeId": "…", "nodesChecked": 0, "sampled": false, "sampledNodeIds": [] }, "score": { "file-structure": 0, "token-inventory": 0, "token-bindings": 0, "modes": 0, "color-contrast": 0, "component-health": 0, "content-health": 0, "overall": 0, "verdict": "FIX-FIRST" }, "expectedSet": "skill-4-ir | pasted-file | absent", "createdVsMissing": { "collections": [], "created": 0, "missing": [], "unbound": 0, "primitiveDirect": 0 }, "contrast": { "checked": 0, "failed": [], "uncheckable": [] }, "fixQueue": [{ "priority": "P0", "issue": "…", "owner": "skill-1|skill-2|skill-3|skill-4|human", "nodeIds": [] }], "openIssues": [] }
```
`fixQueue` ordered P0 (breaks theming/a11y: missing collections, unbound fills, AA failures) → P1 (drift: primitive-direct, bad names, no focus states) → P2 (polish: page order, DRAFT copy). Each item names its owner skill so the next run is routable. If user asked for a file artifact, the host saves this report as `audit.report.json` — the JSON report IS the deliverable, plus a 5-line human summary on top (score, worst pass, top 3 fixes, what was sampled).

## 4. Non-negotiables
All 7 passes every run (empty pass = `{ checked: 0 }`, score `"n/a"`, never skipped silently) · report BEFORE any fix talk · never mutate the canvas · never estimate counts · never mark `connected` without `boundVariables` JSON proof · never pass contrast without per-mode computed ratios · sampling always disclosed.
