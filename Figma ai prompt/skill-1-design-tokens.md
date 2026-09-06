# Skill 1: Design Tokens — Token & Foundation Creation (Figma MCP-only, JSON, No Vision)

**Trigger:** greenfield file, or `get_variable_defs` shows no/partial collections.
**Role:** token architect. Deliverable = real Figma variables + styles via MCP. No images, no app code.
**Overrides agent.md:** `get_screenshot` is FORBIDDEN in this skill. Evidence = MCP JSON only.

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

## 3. Build order (one concern per `use_figma` call)
1. Primitive COLOR collection → 2. Primitive NUMBER collection (space/radius/size) → 3. Semantic collection with Light + Dark modes → 4. Aliases semantic→primitive → 5. Text + effect styles → JSON-validate after EACH step via `get_variable_defs`.

## 4. Copy-paste `use_figma` templates (plain JS, top-level await + return, no IIFE, no closePlugin, no notify)
Hex helper (COLOR vars need 0–1, paints need 0–1 without alpha confusion):
```js
const toRgb01 = (hex) => { const h = hex.replace('#',''); const n = parseInt(h.length===3 ? h.split('').map(c=>c+c).join('') : h, 16); return { r: ((n>>16)&255)/255, g: ((n>>8)&255)/255, b: (n&255)/255 }; };
// variable COLOR value shape: { r, g, b, a: 1 }
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
Create + hide primitives from publishing:
```js
// collection: object from above, NOT just id string
const v = figma.variables.createVariable("blue/500", collection, "COLOR");
v.setValueForMode(modeId, { r: 0.23, g: 0.51, b: 0.96, a: 1 });
v.scopes = ["FRAME_FILL", "SHAPE_FILL"]; // explicit, never ALL_SCOPES
return { variableId: v.id, name: v.name };
```
Semantic alias (one hop only, never semantic→semantic):
```js
semanticVar.setValueForMode(lightModeId, { type: "VARIABLE_ALIAS", id: primitiveVar.id });
semanticVar.setValueForMode(darkModeId, { type: "VARIABLE_ALIAS", id: primitiveDarkSource.id });
```
Every write returns: `{ phase, collectionId, created: n, variableIds: [...], modes: [...] }`.

## 5. Scope map (set explicitly every time)
- Fill colors → `["FRAME_FILL","SHAPE_FILL"]` · text colors → `["TEXT_FILL"]` · strokes → `["STROKE_COLOR"]` · gap → `["GAP"]` · padding → `["COMPOSITION_PADDING"]` or individual padding scopes · radius → `["CORNER_RADIUS"]` · size/width-height → `["WIDTH_HEIGHT"]` · opacity → `["OPACITY"]` · font-size family → `["FONT_SIZE"]` where supported.

## 6. JSON validation after each phase (`get_variable_defs` only)
- `Mode 1` gone; Light + Dark present; every semantic has a value in EVERY mode.
- Alias `type === "VARIABLE_ALIAS"` and target is a primitive.
- Slash naming regex `^[a-z]+(/[a-z0-9-]+)+$` (e.g. `color/text/primary`, `space/4`).
- `get_design_context` spot-check: `boundVariables` set where expected, no raw hex/px leaking.
- Contrast computed in JS (luminance math, not eyes): 4.5:1 normal, 3:1 large/UI. Fix the TOKEN, not the instance.

## 7. Mode-limit + failure recovery
Plan limits: Free = 1 mode, Pro ≤ 4, Org/Ent 40+. If modes needed > allowed → split into multiple collections (e.g. `Semantic / Theme`, `Semantic / Brand`) rather than failing. On any `use_figma` error: STOP, read message, fix cause, retry once — failed scripts apply nothing, so keep blast radius small.

## 8. Non-negotiables
Primitive → Semantic → Component-specific (only on real variant pressure) · neutrals ~80% · AA at definition · explicit scopes · never silent-substitute a missing font/hex (report JSON + ask).

## 9. Output (final message = JSON block)
```json
{ "skill": 1, "collections": ["Primitives / Color", "Primitives / Number", "Semantic / Light+Dark"], "counts": { "primitives": 0, "semantics": 0, "textStyles": 0 }, "modes": ["Light", "Dark"], "aa": { "checked": 0, "failed": [] }, "openIssues": [] }
```
No components, no copy — Skills 2 and 3.
