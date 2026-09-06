# Skill 3: Integration — Bind Tokens + Copy in Figma (MCP-only, JSON, No Vision)

**Trigger:** Skill-1 variables + Skill-2 copy JSON both exist and must be bound/placed/validated in real components.
**Role:** integration gate. Nothing is done until 4 JSON audits pass. Creates NO new tokens and NO new copy — missing input → flag + wait.
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. All proof = `get_variable_defs` + `get_design_context` + `get_metadata` JSON.

## 0. Allowed tools + order (cheap → expensive)
`get_metadata` (outline) → `get_variable_defs` (token truth) → `get_design_context` on ONE nodeId (layer truth) → `search_design_system`/`get_libraries` (reuse check) → `use_figma` (mutate, one component per call). Never pull full-page `get_design_context`.

## 1. Preconditions (fail fast)
Require: Skill-1 final JSON (collectionIds, modeIds) + Skill-2 approved JSON (`status === "APPROVED"`). If either missing → return `{ ok: false, blockedOn: "skill-1" | "skill-2" }` and stop. Re-read both + target frame (`get_metadata` + `get_variable_defs`) — never trust memory; files change live.

## 2. Token binding — field map (use exact API per field)
Paints: `node.setBoundVariableForPaint(field, variable)` — MUST capture return and reassign (`node.fills = [node.setBoundVariableForPaint("fills", v)]`); fields `fills` (incl. `TEXT_FILL` on text nodes) and `strokes`. Numbers/strings: `node.setBoundVariable(field, variable)`; fields `itemSpacing`, `paddingTop/Right/Bottom/Left`, `cornerRadius`, `strokeWeight`, `width`/`height` where supported, `fontSize`. COLOR values `{r,g,b,a}` 0–1; scopes already explicit from Skill 1.
One component per `use_figma` call. Return `{ component, bound, nodeIds, modes }`. Primitives first (Button, Input, Badge, Icon, Checkbox) → verify each via `get_design_context` JSON (`boundVariables` present, no raw hex/px) → then composed (Card, Modal, Nav, Form, Table) built from primitive INSTANCES, never redrawn.

## 3. Copy binding
`await figma.loadFontAsync(exact family+style)` → set `characters` from Skill-2 JSON per state (default/hover/focused/error/success/disabled/empty/loading) → write content guideline into component `description`. Collect per-node `placed/failed` (see Skill 2 template). Overflow → `{ flagged: true, reason: "overflow" }`, never truncate/resize silently.

## 4. Four audits — JSON only, report BEFORE fixing
Emit one block each, exact shape:
```json
{ "pass": "token-audit", "ok": false, "counts": { "checked": 0, "failed": 0 }, "issues": [{ "severity": "❌", "nodeId": "1:2", "detail": "raw hex #3B82F6 in fills" }] }
```
1. **token-audit** (`get_variable_defs` + `get_design_context`): raw hex/px, broken alias, missing Light/Dark value, `ALL_SCOPES`, primitive bound directly to layer.
2. **component-audit** (`get_metadata` + `get_design_context`): unbound property, `Frame 47`/`Group 12`/`Rectangle 8` names (`^Frame \d+` etc.), list/row/grid missing `layoutMode`, fake variant names, detached duplicate of an existing library component (`search_design_system` first).
3. **content-audit** (`characters` JSON): lorem/button-text, `length > maxChars`, glossary violation, `DRAFT` without flag.
4. **a11y-audit** (computed): luminance-ratio AA per mode (4.5:1 / 3:1), color-only meaning (needs icon/label/shape pair), missing focus variant on interactive, body text < 12px.
Fix only after user sees all four blocks; confirm scope for anything beyond the ask.

## 5. Build + re-validate loop
Audit → bind/populate primitives (one call each) → composed → 4-pass validation → fix → re-run same 4 passes and diff `{ before, after, remaining }` → confirm page order Cover → Foundations → Components → Utilities with semantic names. Small atomic scripts only — a failed `use_figma` applies NOTHING, so retry once after reading the real error (top causes: HUG/FILL set before parenting, `STRETCH` + `AUTO` on same axis, wrong font style string, collection object vs id confusion).

## 6. Non-negotiables
Never batch components in one call · never silent-substitute token/font/copy · never mark done without the 4 JSON blocks in this session (no estimated counts).

## 7. Done = all true, all JSON-proven
Bound everywhere · zero hardcodes · approved copy in every text layer · Light + Dark resolve · AA passes per mode · focus variants exist · semantic names · explicit scopes · glossary-consistent · descriptions carry guidelines · navigable file · final report:
```json
{ "skill": 3, "components": [], "audits": { "token": "pass", "component": "pass", "content": "pass", "a11y": "pass" }, "before": {}, "after": {}, "openIssues": [] }
```
