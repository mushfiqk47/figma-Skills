# Skill 5: Design Audit — Full End-to-End File Check + Report (MCP-only, JSON, No Vision)

**Trigger:** user says "audit the design / check everything / give me a report" and names a Figma file, page, or frame (URL with `fileKey` + `nodeId`, or page/frame name).
**Role:** read-only auditor and reporter. Checks the WHOLE file end to end — structure, tokens, variable bindings, missing/uncreated values, modes, color contrast, components, naming, auto-layout, content — and returns one JSON report + fix queue. Makes ZERO canvas edits (hands fixes to Skills 1–4, 3).
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. `use_figma` is FORBIDDEN in this skill (audit never mutates). Evidence = MCP JSON only.

## 0. Allowed tools + budget
`get_metadata` · `get_design_context` (ONE small nodeId at a time, never a whole page) · `get_variable_defs` · `search_design_system` · `get_libraries`. No writes. Order cheap → expensive: page list → page outline → variable defs → libraries → targeted single-node contexts (max 8 nodes per audit; if file is bigger, sample worst-offenders + say what was sampled).

## 1. Locate + scope (read-only, in this order)
1. URL → `fileKey` + `nodeId`. No URL → `get_metadata` (no nodeId) → list pages → ask which page/frame, or audit the page user named.
2. `get_metadata` on scope → frame/component inventory (`nodeId`, `name`, `type`). `get_variable_defs` on scope → collections, modes, variables, alias targets. `get_libraries` + `search_design_system` → what SHOULD have been reused.
3. State scope out loud: `{ fileKey, scopeNodeId, pages: n, nodesChecked: n, sampled: true|false }`. Never report numbers you did not query this session.

## 2. Seven passes — run all seven, JSON only
Emit one block per pass, exact shape:
```json
{ "pass": "token-bindings", "ok": false, "counts": { "checked": 0, "failed": 0 }, "issues": [{ "severity": "❌|⚠️", "nodeId": "1:2", "name": "Hero/Button", "check": "binding-missing", "detail": "raw hex #3B82F6 in fills, expected color/action/primary", "fix": "skill-3" }] }
```
1. **file-structure** (`get_metadata`): page order Cover → Foundations → Components → Utilities; orphan pages; top-level stacking at (0,0); empty frames. Missing-page → `fix: "skill-3"`.
2. **token-inventory** (`get_variable_defs`): collections exist? `Mode 1` still unrenamed? primitives vs semantic vs component-tier present? Unscoped (`ALL_SCOPES`)? Bad slash names (`^Frame \d+` equivalent for tokens: names failing `^[a-z]+(/[a-z0-9-]+)+$`)? Semantic→semantic chains (must be one hop to primitive)? Every semantic valued in EVERY mode? Missing/dangling alias targets? Not-created tokens referenced by name but absent → `created: false, missing: true`.
3. **token-bindings** (`get_design_context` per sampled node): every fill / text-fill / stroke / gap / padding / radius / size bound? Raw hex/px where a token belongs? Primitive bound directly to a layer (must be semantic)? Per-property verdict: `connected | hardcoded | missing-token | primitive-direct`.
4. **modes** (`get_variable_defs` values): Light + Dark (or Brand A/B) resolve per variable? Single-mode variables flagged; plan-limit risk (Free=1, Pro≤4) noted; which frame resolves against which mode.
5. **color-contrast** (computed in JS from variable values + bound pairs, never eyes): luminance math per mode → AA 4.5:1 normal / 3:1 large+UI. Report `{ pair, mode, ratio, required, verdict }`. Failures point at the TOKEN (`fix: "skill-1"`), not the instance.
6. **component-health** (`get_metadata` + `get_design_context` + `search_design_system`): non-semantic names (`Frame 47`, `Group 12`, `Rectangle 8`); list/row/grid missing `layoutMode`; detached duplicates of library components; variant sets with fake/placeholder option names; missing focus/hover/disabled/error variants on interactives; instances vs redrawn copies.
7. **content-health** (`get_design_context` `characters`): Lorem ipsum / "Button text" / empty text layers; unverified `DRAFT` copy; text failing Skill-2 `maxChars`; glossary violations (only if Skill-2 glossary provided, else flag `glossary: absent`); body text < 12px; icon-only meaning (no paired label).

## 3. Scoring + management report (always ends with this)
Health score per pass (0–100 = `pass/(checked)`) + overall = mean of 7. Verdict: `SHIP | FIX-FIRST | REBUILD` (`REBUILD` only if token-inventory + bindings both < 50). Then:
```json
{ "skill": 5, "scope": { "fileKey": "…", "nodeId": "…", "nodesChecked": 0, "sampled": false }, "score": { "file-structure": 0, "token-inventory": 0, "token-bindings": 0, "modes": 0, "color-contrast": 0, "component-health": 0, "content-health": 0, "overall": 0, "verdict": "FIX-FIRST" }, "createdVsMissing": { "collections": [], "created": 0, "missing": [], "unbound": 0, "primitiveDirect": 0 }, "contrast": { "checked": 0, "failed": [] }, "fixQueue": [{ "priority": "P0", "issue": "…", "owner": "skill-1|skill-2|skill-3|skill-4|human", "nodeIds": [] }], "openIssues": [] }
```
`fixQueue` ordered P0 (breaks theming/a11y: missing collections, unbound fills, AA failures) → P1 (drift: primitive-direct, bad names, no focus states) → P2 (polish: page order, DRAFT copy). Each item names its owner skill so the next run is routable. If user asked for a file artifact, also write `audit.report.json` next to the audit — the JSON report IS the deliverable, plus a 5-line human summary on top (score, worst pass, top 3 fixes, what was sampled).

## 4. Non-negotiables
All 7 passes every run (empty pass = `{ checked: 0 }`, never skipped silently) · report BEFORE any fix talk · never mutate the canvas · never estimate counts · never mark `connected` without `boundVariables` JSON proof · never pass contrast without per-mode computed ratios · flag sampling explicitly when the file exceeded the 8-node context budget.
