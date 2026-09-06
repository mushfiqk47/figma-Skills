# Skill 1: Design Tokens — Token & Foundation Creation (Figma MCP-only, JSON, No Vision)

**Trigger:** greenfield file, or `get_variable_defs` shows no/partial collections.
**Role:** token architect. Deliverable = real Figma variables + styles via MCP. No images, no app code.
**Overrides agent.md:** `get_screenshot` is FORBIDDEN in this skill. Evidence = MCP JSON only.
Shared rules (batch cap, naming, scopes, handoff schema) live in agent.md §0.6 — this skill does not restate them.

## 0. Allowed tools + call budget
Allowed: `get_metadata` · `get_design_context` · `get_variable_defs` · `search_design_system` · `get_libraries` · `use_figma` · `create_new_file`. Max 3 reads before first write. `get_design_context` only on a single small nodeId — never a whole page.

## 1. Locate + diagnose (read-only, in this order)
1. URL → `fileKey` + `nodeId`. No URL → `get_metadata` with no nodeId → pick page → `get_metadata` on that page.
2. `get_variable_defs` on page → record: collection names, mode names/ids, variable names, alias targets.
3. `search_design_system` for color/type/spacing + `get_libraries` → reuse before building.
4. Classify out loud: Greenfield / Extend (match existing naming exactly) / Repair (list drift first). Ask if ambiguous.

## 2. Propose, wait for approval
- Colors: 1 primary + 1 neutral + 1–3 status families. Default source Tailwind v4 (verify hexes via web search — palettes drift). Accept Radix / Open Color / Material 3 / Apple HIG if specified.
- Type: exact family if given, else 2–3 options by product type. Never commit until `listAvailableFontsAsync` JSON confirms the exact `family + style` string.
- Present as a compact table + wait. No writes before approval.

## 3. Build order (one concern per `use_figma` call, ≤25 variables per call per §0.6)
1. Primitive COLOR collection → 2. Primitive NUMBER collection (space/radius/size) → 3. Semantic collection with Light + Dark modes → 4. Aliases semantic→primitive → 5. Text + effect styles → JSON-validate after EACH step via `get_variable_defs`.

## 4. Copy-paste `use_figma` templates (plain JS, top-level await + return, no IIFE, no closePlugin, no notify)
Canonical color parser — hex (3/4/6/8), `rgb()/rgba()`, `hsl()/hsla()` → `{r,g,b,a}` 0–1, or `null` when unparseable (Skill 4 uses this same snippet verbatim):
```js
const parseColor = (raw) => {
  const s = String(raw).trim().toLowerCase();
  const clamp01 = (n) => Math.min(1, Math.max(0, n));
  let m = s.match(/^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/);
  if (m) {
    let h = m[1];
    if (h.length <= 4) h = h.split('').map(c => c + c).join('');
    const n = parseInt(h, 16);
    const hasA = h.length === 8;
    const a = hasA ? (n & 255) / 255 : 1;
    const v = hasA ? n >>> 8 : n;
    return { r: ((v >> 16) & 255) / 255, g: ((v >> 8) & 255) / 255, b: (v & 255) / 255, a };
  }
  m = s.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$/);
  if (m) return { r: clamp01(+m[1] / 255), g: clamp01(+m[2] / 255), b: clamp01(+m[3] / 255), a: m[4] === undefined ? 1 : clamp01(+m[4]) };
  m = s.match(/^hsla?\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*(?:,\s*([\d.]+)\s*)?\)$/);
  if (m) {
    const h = ((+m[1]) % 360 + 360) % 360 / 360, sat = clamp01(+m[2] / 100), li = clamp01(+m[3] / 100);
    const q = li < 0.5 ? li * (1 + sat) : li + sat - li * sat, p = 2 * li - q;
    const f = (t) => { if (t < 0) t += 1; if (t > 1) t -= 1; if (t < 1/6) return p + (q - p) * 6 * t; if (t < 1/2) return q; if (t < 2/3) return p + (q - p) * (2/3 - t) * 6; return p; };
    return { r: f(h + 1/3), g: f(h), b: f(h - 1/3), a: m[4] === undefined ? 1 : clamp01(+m[4]) };
  }
  return null; // NEVER guess — caller marks the token NEEDS-DECISION
};
```
Idempotent collection find-or-create + rename Mode 1:
```js
const name = "Primitives / Color";
let col = figma.variables.getLocalVariableCollections().find(c => c.name === name);
if (!col) col = figma.variables.createVariableCollection(name);
const modeId = col.modes[0].modeId;
if (col.modes[0].name === "Mode 1") col.renameMode(modeId, "Source");
return { collectionId: col.id, modeId, modes: col.modes.map(m => m.name) };
```
Create variables (collection OBJECT, not id string; explicit scopes; `null` color → skip + report):
```js
const rgba = parseColor("#3B82F6");
if (!rgba) return { skipped: [{ name: "blue/500", reason: "unparseable color" }] };
let v = figma.variables.getLocalVariables().find(x => x.name === "blue/500" && x.variableCollectionId === collection.id);
if (!v) {
  v = figma.variables.createVariable("blue/500", collection, "COLOR");
  v.setValueForMode(modeId, rgba);
  v.scopes = ["FRAME_FILL", "SHAPE_FILL"]; // explicit, never ALL_SCOPES (§0.6 discovery fallback if this throws)
}
const n = figma.variables.createVariable("space/4", numCollection, "FLOAT");
n.setValueForMode(numModeId, 16);
n.scopes = ["GAP"];
return { variableIds: [v.id, n.id] };
```
Semantic alias (one hop only, never semantic→semantic):
```js
semanticVar.setValueForMode(lightModeId, { type: "VARIABLE_ALIAS", id: primitiveVar.id });
semanticVar.setValueForMode(darkModeId, { type: "VARIABLE_ALIAS", id: primitiveDarkSource.id });
```
Text + effect styles (composite properties variables can't cover):
```js
await figma.loadFontAsync({ family: "Inter", style: "Regular" });
const ts = figma.createTextStyle();
ts.name = "body/body"; ts.fontName = { family: "Inter", style: "Regular" }; ts.fontSize = 16; ts.lineHeight = { value: 24, unit: "PIXELS" };
const es = figma.createEffectStyle();
es.name = "elevation/md";
es.effects = [{ type: "DROP_SHADOW", visible: true, color: { r: 0, g: 0, b: 0, a: 0.12 }, offset: { x: 0, y: 4 }, radius: 12, spread: 0, blendMode: "NORMAL" }];
return { textStyleId: ts.id, effectStyleId: es.id };
```
Hiding primitives from publishing has NO Plugin API — do it in the Figma UI after forging (library `…` menu → hide collection) and record `{ publishingHidden: true|false, how: "ui" }` in the report. Never claim a script did it.
Every write returns: `{ phase, collectionId, created: n, skipped: [], variableIds: [...], modes: [...] }`.

## 5. Scope map (set explicitly every time; §0.6 discovery fallback if a string throws)
- Fill colors → `["FRAME_FILL","SHAPE_FILL"]` · text colors → `["TEXT_FILL"]` · strokes → `["STROKE_COLOR"]` · gap → `["GAP"]` · padding → individual padding scopes accepted by the running API · radius → `["CORNER_RADIUS"]` · size/width-height → `["WIDTH_HEIGHT"]` · opacity → `["OPACITY"]` · font-size → `["FONT_SIZE"]` where supported.

## 6. JSON validation after each phase (`get_variable_defs` only)
- `Mode 1` gone; Light + Dark present; every semantic has a value in EVERY mode.
- Alias `type === "VARIABLE_ALIAS"` and target is a primitive.
- Variable-name regex per §0.6 (collection names exempt).
- `get_design_context` spot-check: `boundVariables` set where expected, no raw hex/px leaking.
- Contrast computed in JS (luminance math, not eyes): 4.5:1 normal, 3:1 large/UI. Fix the TOKEN, not the instance.

## 7. Mode-limit + failure recovery
Plan limits: Free = 1 mode, Pro ≤ 4, Org/Ent 40+. If modes needed > allowed → split into multiple collections (e.g. `Semantic / Theme`, `Semantic / Brand`) rather than failing. On any `use_figma` error: STOP, read message, fix cause, retry once — failed scripts apply nothing, so keep blast radius small.

## 8. Non-negotiables
Primitive → Semantic → Component-specific (only on real variant pressure) · neutrals ~80% · AA at definition · explicit scopes · never silent-substitute a missing font/color/value (report JSON + ask).

## 9. Output (final message = JSON block)
```json
{ "v": 1, "skill": 1, "collections": [{ "id": "…", "name": "Primitives / Color", "modeIds": ["…"] }], "counts": { "primitives": 0, "semantics": 0, "textStyles": 0, "effectStyles": 0 }, "modes": ["Light", "Dark"], "aa": { "checked": 0, "failed": [] }, "publishingHidden": false, "openIssues": [] }
```
No components, no copy — Skills 2 and 3.
