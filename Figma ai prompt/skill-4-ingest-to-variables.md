# Skill 4: Ingest → Variables — Any Prompt / design.md / JSON / CSS → Figma Variables (MCP-only, JSON, No Vision)

**Trigger:** user pastes a prompt block or names any source file (`design.md`, `DESIGN.md`, `tokens.json`, DTCG, style-dictionary, CSS `:root` vars, Tailwind config, or any other file path) and says "make the variables / forge the tokens".
**Role:** ingestion forger. Input = messy human source. Output = deep, deduplicated Figma variables via MCP + IR JSON the host may save as `tokens.forged.json`. No images, no app code, no components/copy (those are Skills 2–3).
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. Evidence = MCP JSON only.
Shared rules (naming, enums, batch cap, handoff schema) live in agent.md §0.6.

## 0. Allowed tools + budget
MCP: `get_metadata` · `get_design_context` (single small nodeId only) · `get_variable_defs` · `search_design_system` · `get_libraries` · `use_figma` · `create_new_file`. Max 3 Figma reads before first write.

## 1. Capture the source (never invent it)
MCP has NO file-reading tool. The HOST reads the named file (Read tool) and pastes its content into context, or the user pastes a block directly. This skill only ever parses content actually present in context:
1. Named path + content pasted → parse it. Named path but no content in context → STOP and ask the host/user to paste it. Pasted block only → parse verbatim. Both → file wins, pasted block = overrides (say so).
2. Ambiguous source ("that design file") → STOP and ask for path or paste. Never forge from memory.
3. Record: `{ sourceType, sourcePath | "pasted-block", chars }`. Supported: `design.md` / `DESIGN.md` / `tokens.md`, DTCG / style-dictionary / `tokens.json`, CSS `:root` / SCSS vars, Tailwind config, CSV `name,value`, free-text prompt. Anything else → best-effort free-text parse + flag assumptions.

## 2. Parse → IR JSON (the deep work, do it before touching Figma)
Normalize EVERY raw value into this IR — one entry per token, no duplicates:
```json
{ "name": "color/text/primary", "tier": "semantic", "type": "COLOR", "light": "#111827", "dark": "#F9FAFB", "scopes": ["TEXT_FILL"], "source": "design.md:42", "status": "READY | NEEDS-DECISION" }
```
Rules:
- **Normalize values** with Skill-1 §4 `parseColor` verbatim (hex 3/4/6/8, `rgb()/rgba()`, `hsl()/hsla()` → 0–1 `{r,g,b,a}`; `null` → `NEEDS-DECISION`, never a guess); `px`/`rem` (1rem=16px) → number; `opacity %` → 0–1 FLOAT. Keep the two snippets in sync — Skill 1 §4 is canonical.
- **Name → slash convention** per §0.6: `text-primary` / `textPrimary` / `--text-primary` all become `color/text/primary`; `space-4` → `space/4`. Regex failures → `NEEDS-DECISION`, never silent renames.
- **Tier inference:** raw palette/swatch (`blue-500=#3B82F6`) → `primitive`; role name (`action/primary`, `text/*`, `surface/*`) → `semantic` (alias to a primitive, create the primitive if absent); `button/*`, `card/*`, `input/*` prefix → `component-specific` (alias to semantic). Semantic→semantic chains are FORBIDDEN — flatten to one hop.
- **Mode inference:** pair `light:`/`dark:`, `[data-theme=dark]`, `.dark`, duplicate names into `light` + `dark` on ONE variable. Single value → same value both modes + flag `single-mode`.
- **Dedupe:** identical values under different names → ONE primitive + aliases (report `{ deduped: [{ kept, merged: [...] }] }`). Conflicting values under one name → `NEEDS-DECISION`, stop that entry.
- **Scopes** per Skill-1 §5 / §0.6 discovery fallback. Never `ALL_SCOPES`.
- **Font gate:** `font-family` tokens stay `NEEDS-DECISION` until `figma.listAvailableFontsAsync()` JSON confirms the exact `family + style` — same rule as Skill-1 §2.

## 3. Diagnose Figma (read-only, cheap → expensive)
1. URL → `fileKey` + `nodeId`, else `get_metadata` (no nodeId) → page → `get_metadata` on page.
2. `get_variable_defs` → existing collections/modes/names. `search_design_system` + `get_libraries` → reuse check.
3. Classify: Greenfield / Extend (match existing names exactly) / Repair (list drift first).

## 4. Propose forge plan, WAIT for approval (no writes before this)
Compact table: source entries → collections to create/reuse → new primitives / semantics / component-tier counts → modes → dedupe merges → `NEEDS-DECISION` list. User approves or corrects. Large sources (>75 entries): split into batches of ≤25 (§0.6 cap) and approve batch 1 first.

## 5. Forge — atomic `use_figma` batches (one collection per call, ≤25 vars per call)
Plain JS, top-level `await` + `return`. No IIFE, no `closePlugin`, no `notify`. Idempotent — re-runs never duplicate. Build ONE lookup map per batch (never scan all variables per token):
```js
const findOrCreateCol = (name) => { let c = figma.variables.getLocalVariableCollections().find(x => x.name === name); if (!c) c = figma.variables.createVariableCollection(name); if (c.modes[0]?.name === "Mode 1") c.renameMode(c.modes[0].modeId, "Light"); return c; };
const col = findOrCreateCol("Primitives / Color");
const existing = new Map(figma.variables.getLocalVariables().filter(x => x.variableCollectionId === col.id).map(x => [x.name, x]));
const parseColor = /* Skill-1 §4 verbatim */;
const created = [], skipped = [];
for (const t of batch /* ≤25 IR entries */) {
  if (existing.has(t.name)) continue;
  const rgba = parseColor(t.light);
  if (!rgba) { skipped.push({ name: t.name, reason: "unparseable color" }); continue; }
  const v = figma.variables.createVariable(t.name, col, "COLOR");
  v.setValueForMode(col.modes[0].modeId, rgba);
  v.scopes = t.scopes;
  existing.set(t.name, v); created.push(v.id);
}
return { collectionId: col.id, created: created.length, createdIds: created, skipped };
```
Alias (semantic→primitive, ensure Dark mode exists first, split collections if plan mode-limit hit: Free=1, Pro≤4):
```js
semVar.setValueForMode(lightId, { type: "VARIABLE_ALIAS", id: primVar.id });
```
Types: `COLOR` / `FLOAT` / `STRING` / `BOOLEAN` — pick by normalized value, never default blindly.

## 6. Validate (JSON only)
After EACH batch: `get_variable_defs` → collections exist, `Mode 1` gone, every semantic valued in EVERY mode, aliases one-hop to primitives, scopes explicit, §0.6 naming passes, contrast computed in JS (4.5:1 / 3:1 — fix the TOKEN). Spot-check `get_design_context` only if layers were touched. On `use_figma` error: STOP, read message, fix, retry once (failed scripts apply nothing).
Final JSON:
```json
{ "v": 1, "skill": 4, "source": { "type": "design.md", "path": "…", "entries": 0 }, "collections": [{ "id": "…", "name": "Primitives / Color", "modeIds": ["…"] }], "forged": { "primitives": 0, "semantics": 0, "componentTier": 0 }, "deduped": [], "modes": ["Light", "Dark"], "aa": { "checked": 0, "failed": [] }, "needsDecision": [], "openIssues": [] }
```
The host may save the full IR array as `tokens.forged.json` next to the source on request — Figma remains the source of truth, the file is just a receipt. This skill never writes files itself.

## 7. Non-negotiables
Never forge without the actual source in context · never silent-substitute a missing font/color/mode (mark `NEEDS-DECISION`, ask) · never exceed 25 vars/call · never create components or copy (hand off to Skills 3 / 2) · never report counts you did not query this session.
