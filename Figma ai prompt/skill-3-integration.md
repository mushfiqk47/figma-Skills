# Skill 3: Integration — Bind Tokens + Copy in Figma (MCP-only, JSON, No Vision)

**Trigger:** Skill-1 variables + Skill-2 copy JSON both exist and must be bound/placed/validated in real components.
**Role:** integration gate. Nothing is done until 4 JSON audits pass. Creates NO new tokens and NO new copy — missing input → flag + wait.
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. All proof = `get_variable_defs` + `get_design_context` + `get_metadata` JSON.
Shared rules (naming, enums, batch cap, handoff schema) live in agent.md §0.6.

## 0. Allowed tools + order (cheap → expensive)
`get_metadata` (outline) → `get_variable_defs` (token truth) → `get_design_context` on ONE nodeId (layer truth) → `search_design_system`/`get_libraries` (reuse check) → `use_figma` (mutate, one component per call). Never pull full-page `get_design_context`.

## 1. Preconditions (fail fast, validate the handoff schema)
Require Skill-1/4 final JSON with `"v": 1` + `collections: [{ id, name, modeIds }]` and Skill-2 JSON with `"v": 1` + all strings `APPROVED`. If either is absent or unversioned → return `{ "v": 1, ok: false, blockedOn: "skill-1" | "skill-2" | "skill-4", reason: "…" }` and stop. Re-read target frame (`get_metadata` + `get_variable_defs`) — never trust memory; files change live.

## 2. Token binding — fallback template per field (APIs differ across versions)
Paint binding has two historical signatures and numeric support varies by field. Try in order, record what held — never let one bad field kill the atomic call:
```js
const paintFields = ["fills", "strokes"];                       // setBoundVariableForPaint, capture + reassign
const valueFields = ["itemSpacing", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft", "cornerRadius", "strokeWeight", "fontSize", "opacity"];
const riskyFields = ["width", "height"];                        // frequently unsupported → flag, don't fail
const bound = [], unsupported = [], failed = [];
function bindPaint(node, field, variable) {
  try {
    if (typeof node.setBoundVariableForPaint === "function") {
      const cur = node[field];
      const paints = Array.isArray(cur) ? cur.slice() : [];
      const base = paints[0] || { type: "SOLID", color: { r: 0, g: 0, b: 0 } };
      node[field] = [node.setBoundVariableForPaint(base, field, variable)];
      bound.push(field); return;
    }
    throw new Error("no-setBoundVariableForPaint");
  } catch (e1) {
    try { node.setBoundVariable(field, variable); bound.push(field + ":via-setBoundVariable"); }
    catch (e2) { failed.push({ field, error: String(e2).slice(0, 120) }); }
  }
}
for (const f of valueFields) { try { node.setBoundVariable(f, plan[f]); bound.push(f); } catch (e) { failed.push({ field: f, error: String(e).slice(0, 120) }); } }
for (const f of riskyFields) { try { node.setBoundVariable(f, plan[f]); bound.push(f); } catch (e) { unsupported.push(f); } }
return { component: "Button", bound, unsupported, failed, nodeIds: [node.id] };
```
COLOR values `{r,g,b,a}` 0–1; scopes already explicit from Skill 1. Primitives first (Button, Input, Badge, Icon, Checkbox) → verify each via `get_design_context` JSON (`boundVariables` present, no raw hex/px) → then composed (Card, Modal, Nav, Form, Table) built from primitive INSTANCES, never redrawn. One component per `use_figma` call.

## 3. Detached duplicates → instance swap (don't leave two truths)
When the component audit finds a hand-redrawn duplicate of a library component, swap it for a real instance, preserving position and size:
```js
const comp = await figma.getNodeByIdAsync("9:1");   // master, from search_design_system
const dupe = await figma.getNodeByIdAsync("3:7");   // the redrawn copy
const inst = comp.createInstance();
inst.x = dupe.x; inst.y = dupe.y;
if ("resize" in inst) { try { inst.resize(dupe.width, dupe.height); } catch (e) {} }
dupe.parent.appendChild(inst);
dupe.remove();
return { swapped: inst.id, retired: dupe.id };
```
Only swap when geometry truly matches; otherwise flag for human review instead.

## 4. Copy binding
Per-node placement via the Skill-2 §6 template (per-layer fonts, null-checks, name fallback). Every state (default/hover/focused/error/success/disabled/empty/loading) gets its exact copy. Overflow → `{ flagged: true, reason: "overflow" }`, never truncate/resize silently. Content guideline into the component `description`.

## 5. Four audits — JSON only, report BEFORE fixing
Emit one block each, exact shape:
```json
{ "v": 1, "pass": "token-audit", "ok": false, "counts": { "checked": 0, "failed": 0 }, "issues": [{ "severity": "❌", "nodeId": "1:2", "detail": "raw hex #3B82F6 in fills" }] }
```
1. **token-audit** (`get_variable_defs` + `get_design_context`): raw hex/px, broken alias, missing Light/Dark value, `ALL_SCOPES`, primitive bound directly to layer.
2. **component-audit** (`get_metadata` + `get_design_context`): unbound property, `Frame 47`/`Group 12`/`Rectangle 8` names (`^Frame \d+` etc.), list/row/grid missing `layoutMode`, fake variant names, detached duplicate of an existing library component (`search_design_system` first).
3. **content-audit** (`characters` JSON): lorem/button-text, `length > maxChars`, glossary violation (against Skill-2 `glossary`), `DRAFT` without flag.
4. **a11y-audit** (computed): luminance-ratio AA per mode (4.5:1 / 3:1), color-only meaning (needs icon/label/shape pair), missing focus variant on interactive, body text < 12px.
Fix only after user sees all four blocks; confirm scope for anything beyond the ask.

## 6. Build + re-validate loop
Audit → bind/populate primitives (one call each) → composed → 4-pass validation → fix → re-run same 4 passes and diff in the Skill-5 shape `{ before: {score}, after: {score}, remaining: [...] }` → confirm page order Cover → Foundations → Components → Utilities with semantic names. Small atomic scripts only — a failed `use_figma` applies NOTHING, so retry once after reading the real error (top causes: HUG/FILL set before parenting, `STRETCH` + `AUTO` on same axis, wrong font style string, collection object vs id confusion).

## 7. Non-negotiables
Never batch components in one call · never silent-substitute token/font/copy · never mark done without the 4 JSON blocks in this session (no estimated counts).

## 8. Done = all true, all JSON-proven
Bound everywhere · zero hardcodes · approved copy in every text layer · Light + Dark resolve · AA passes per mode · focus variants exist · semantic names · explicit scopes · glossary-consistent · descriptions carry guidelines · navigable file · final report:
```json
{ "v": 1, "skill": 3, "components": [], "collections": [{ "id": "…", "name": "Semantic / Light+Dark", "modeIds": ["…"] }], "audits": { "token": "pass", "component": "pass", "content": "pass", "a11y": "pass" }, "before": {}, "after": {}, "remaining": [], "openIssues": [] }
```
