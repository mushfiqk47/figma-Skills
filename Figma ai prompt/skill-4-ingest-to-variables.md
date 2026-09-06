# Skill 4: Ingest → Variables — Any Prompt / design.md / JSON / CSS → Figma Variables (MCP-only, JSON, No Vision)

**Trigger:** user pastes a prompt block or names any source file (`design.md`, `DESIGN.md`, `tokens.json`, DTCG, style-dictionary, CSS `:root` vars, Tailwind config, or any other file path) and says "make the variables / forge the tokens".
**Role:** ingestion forger. Input = messy human source. Output = deep, deduplicated Figma variables via MCP + optional `tokens.forged.json` artifact. No images, no app code, no components/copy (those are Skills 2–3).
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. Evidence = MCP JSON only.

## 0. Allowed tools + budget
MCP: `get_metadata` · `get_design_context` (single small nodeId only) · `get_variable_defs` · `search_design_system` · `get_libraries` · `use_figma` · `create_new_file`. Files: read the mentioned source via file read (full content, never guess). Max 3 Figma reads before first write.

## 1. Capture the source (never invent it)
1. If user named a path → read THAT file in full. If pasted block → use THAT block verbatim. If both → file wins, pasted block = overrides (say so).
2. If source is missing/ambiguous (“that design file”) → STOP and ask for path or paste. Never forge from memory.
3. Record: `{ sourceType, sourcePath | "pasted-block", chars, parsedAt }`. Supported: `design.md` / `DESIGN.md` / `tokens.md`, DTCG / style-dictionary / `tokens.json`, CSS `:root` / SCSS vars, Tailwind config, CSV `name,value`, free-text prompt. Anything else → parse best-effort as free text + flag assumptions.

## 2. Parse → IR JSON (the deep work, do it before touching Figma)
Normalize EVERY raw value into this IR — one entry per token, no duplicates:
```json
{ "name": "color/text/primary", "tier": "semantic", "type": "COLOR", "light": "#111827", "dark": "#F9FAFB", "scopes": ["TEXT_FILL"], "source": "design.md:42", "status": "READY | NEEDS-DECISION" }
```
Rules:
- **Normalize values:** hex / `rgb()` / `hsl()` → `#RRGGBB` + 0–1 `{r,g,b,a}` (3-digit hex expanded); `px`/`rem` (1rem=16px) → number; `opacity %` → 0–1 FLOAT; font families kept verbatim until `listAvailableFontsAsync` confirms.
- **Name → slash convention:** `text-primary` / `textPrimary` / `--text-primary` all become `color/text/primary`; `space-4` → `space/4`; reject `^[a-z]+(/[a-z0-9-]+)+$` failures into `NEEDS-DECISION`, never auto-rename silently.
- **Tier inference:** raw palette/swatch (`blue-500=#3B82F6`) → `primitive`; role name (`action/primary`, `text/*`, `surface/*`) → `semantic` (alias to a primitive, create the primitive if absent); `button/*`, `card/*`, `input/*` prefix → `component-specific` (alias to semantic). Semantic→semantic chains are FORBIDDEN — flatten to one hop.
- **Mode inference:** pair `light:`/`dark:`, `[data-theme=dark]`, `.dark`, `Mode 1`-style duplicates into `light` + `dark` on ONE variable. Single value → same value both modes + flag `single-mode`.
- **Dedupe:** identical values under different names → ONE primitive + aliases (report `{ deduped: [{ kept, merged: [...] }] }`). Conflicting values under one name → `NEEDS-DECISION`, stop that entry.
- **Scopes:** fill → `FRAME_FILL,SHAPE_FILL`; text color → `TEXT_FILL`; stroke → `STROKE_COLOR`; gap → `GAP`; padding → padding scopes; radius → `CORNER_RADIUS`; width/height → `WIDTH_HEIGHT`; opacity → `OPACITY`; font-size → `FONT_SIZE`. Never `ALL_SCOPES`.

## 3. Diagnose Figma (read-only, cheap → expensive)
1. URL → `fileKey` + `nodeId`, else `get_metadata` (no nodeId) → page → `get_metadata` on page.
2. `get_variable_defs` → existing collections/modes/names. `search_design_system` + `get_libraries` → reuse check.
3. Classify: Greenfield / Extend (match existing names exactly) / Repair (list drift first).

## 4. Propose forge plan, WAIT for approval (no writes before this)
Compact table: source entries → collections to create/reuse → new primitives / semantics / component-tier counts → modes → dedupe merges → `NEEDS-DECISION` list. User approves or corrects. Large sources (>75 entries): split into batches of ≤25 and approve batch 1 first.

## 5. Forge — atomic `use_figma` batches (one collection per call, ≤25 vars per call)
Plain JS, top-level `await` + `return`. No IIFE, no `closePlugin`, no `notify`. Find-or-create (idempotent — re-runs never duplicate):
```js
const findOrCreateCol = (name) => { let c = figma.variables.getLocalVariableCollections().find(x => x.name === name); if (!c) c = figma.variables.createVariableCollection(name); if (c.modes[0]?.name === "Mode 1") c.renameMode(c.modes[0].modeId, "Light"); return c; };
const toRgb01 = (hex) => { const h = hex.replace("#",""); const f = h.length===3 ? h.split("").map(c=>c+c).join("") : h; const n = parseInt(f,16); return { r: ((n>>16)&255)/255, g: ((n>>8)&255)/255, b: (n&255)/255, a: 1 }; };
const col = findOrCreateCol("Primitives / Color");
let v = figma.variables.getLocalVariables().find(x => x.name === "blue/500" && x.variableCollectionId === col.id);
if (!v) { v = figma.variables.createVariable("blue/500", col, "COLOR"); v.setValueForMode(col.modes[0].modeId, toRgb01("#3B82F6")); v.scopes = ["FRAME_FILL","SHAPE_FILL"]; }
return { collectionId: col.id, variableId: v.id, name: v.name };
```
Alias (semantic→primitive, ensure Dark mode exists first, split collections if plan mode-limit hit: Free=1, Pro≤4):
```js
semVar.setValueForMode(lightId, { type: "VARIABLE_ALIAS", id: primVar.id });
```
Types: `COLOR` / `FLOAT` / `STRING` / `BOOLEAN` — pick by normalized value, never default blindly. Every call returns `{ batch, created, aliased, variableIds, collectionId }`.

## 6. Validate (JSON only) + optional writeback
After EACH batch: `get_variable_defs` → collections exist, `Mode 1` gone, every semantic valued in EVERY mode, aliases one-hop to primitives, scopes explicit, naming regex passes, contrast computed in JS (4.5:1 / 3:1 — fix the TOKEN). Spot-check `get_design_context` only if layers were touched. On `use_figma` error: STOP, read message, fix, retry once (failed scripts apply nothing).
Then emit final JSON:
```json
{ "skill": 4, "source": { "type": "design.md", "path": "…", "entries": 0 }, "forged": { "primitives": 0, "semantics": 0, "componentTier": 0 }, "deduped": [], "modes": ["Light","Dark"], "aa": { "checked": 0, "failed": [] }, "needsDecision": [], "openIssues": [] }
```
If user asked for a file artifact, also write `tokens.forged.json` (the IR array) next to the source — Figma remains the source of truth, the file is just a receipt.

## 7. Non-negotiables
Never forge without reading the actual source · never silent-substitute a missing font/hex/mode (mark `NEEDS-DECISION`, ask) · never exceed 25 vars/call · never create components or copy (hand off to Skills 3 / 2) · never report counts you did not query this session.
