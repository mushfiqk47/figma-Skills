# Skill 2: UX Writing — Content Design for Design Systems (Figma MCP-only, JSON, No Vision)

**Trigger:** a component/screen/flow needs microcopy, labels, or content rules.
**Role:** UX writer. Deliverable = approved copy JSON + `use_figma` placement + `description` guidelines. No images, no token work.
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. Verify via `get_design_context` JSON `characters` only.
Shared rules (naming, enums, handoff schema) live in agent.md §0.6.

## 0. Allowed tools + budget
`get_metadata` · `get_design_context` · `search_design_system` · `use_figma`. 2 reads max before drafting: (1) `get_metadata` on target frame → outline, (2) `get_design_context` on that ONE nodeId → text-layer list (`nodeId`, `name`, `characters`, `fontName`, `textAutoResize`, `width/height`).

## 1. Context first (ask if unclear)
Product job · users · flow + step position · platform. Also pull existing copy via step-0 reads so new strings match established terms — never invent competing synonyms.

## 2. Voice proposal (wait for approval)
Follow existing brand voice exactly if present. Otherwise propose ONE line by product type and wait: B2B SaaS professional/confident · consumer friendly/direct · dev-tool precise/peer-to-peer · health/finance reassuring/jargon-free · e-commerce warm/benefit-driven · education encouraging/clear.

## 3. Draft = JSON code (covers every state, nothing else)
```json
{
  "v": 1, "screen": "SignupForm", "nodeId": "12:34", "voice": "friendly/direct",
  "strings": [
    { "nodeId": "12:35", "element": "email-label", "state": "default", "copy": "Email address", "maxChars": 32, "status": "PROPOSED" },
    { "nodeId": "12:36", "element": "email-error", "state": "error", "copy": "Enter a valid email address (e.g., you@company.com)", "maxChars": 80, "status": "PROPOSED" }
  ],
  "glossary": [{ "term": "workspace", "neverUse": ["space", "team area"] }],
  "i18n": { "de_fi": "+30-40%", "cjk": "-10-20%", "rtl": "layout note required" }
}
```
States to cover per component: default / focused / error / success / disabled / empty / loading. `status` follows §0.6 (`PROPOSED → APPROVED → PLACED`, unreviewed stays `DRAFT`). Never deliver `Lorem ipsum` or `Button text`.

## 4. Category rules (no exceptions)
Nav 1–3 words, verb-first actions / noun-phrase destinations · CTA verb + outcome ("Save changes"), never "Click here", destructive names object ("Delete project") · Form labels = noun phrases, placeholder = format example only, errors = what + fix · Feedback: no blame, no raw errors, always next step; loading sets time expectation · Onboarding: benefit first, one action/step, "Step 2 of 4" · Dialogs: never OK/Yes/No — action + object + consequence, safe default prominent when irreversible.

## 5. Standards per string
One idea · headings ≤6 words, body ≤25 words/sentence · glossary-locked · important first · 7th-grade level, icon paired with label (never icon-only meaning) · gender-neutral, no ability/age/skill assumptions · scannable.

## 6. Placement via `use_figma` (one screen per call — per-node fonts, null-checks, name fallback)
One shared `loadFontAsync` fails multi-font screens. Load per node, skip safely, re-resolve stale IDs by layer name:
```js
const strings = /* APPROVED strings with nodeId + fallbackName + font {family, style} */;
const placed = [], failed = [];
const byName = {};
async function indexNames(node) {
  byName[node.name] = node.id;
  if ("children" in node) for (const c of node.children) await indexNames(c);
}
await indexNames(await figma.getNodeByIdAsync("12:34")); // screen root
for (const s of strings) {
  try {
    let n = s.nodeId ? await figma.getNodeByIdAsync(s.nodeId) : null;
    if (!n || n.type !== "TEXT") {
      const alt = s.fallbackName && byName[s.fallbackName] ? await figma.getNodeByIdAsync(byName[s.fallbackName]) : null;
      if (!alt || alt.type !== "TEXT") { failed.push({ nodeId: s.nodeId, reason: "not-found-or-not-text" }); continue; }
      n = alt;
    }
    await figma.loadFontAsync(s.font); // exact per-layer {family, style}; on throw → failed, never guess
    n.characters = s.copy;
    placed.push(n.id);
  } catch (e) { failed.push({ nodeId: s.nodeId, reason: String(e).slice(0, 160) }); }
}
return { screen: "SignupForm", placed: placed.length, placedNodeIds: placed, failed };
```
On any `loadFontAsync` throw: call `figma.listAvailableFontsAsync()`, return its JSON, and ask — never guess `"SemiBold"` vs `"Semi Bold"`. Content guideline into the component description (same call pattern):
```js
const comp = await figma.getNodeByIdAsync("12:34");
comp.description = "Button label: 1–3 words, verb-first, sentence case, max 24 chars.";
return { described: comp.id };
```

## 7. JSON verification (`get_design_context` on the frame)
`characters` === approved copy · length ≤ `maxChars` · no truncation: `FIXED`-sized text whose copy grew (esp. the §3 i18n expansion) gets flagged, never silently shrunk · terms match glossary · every string is `PLACED` or explicitly `DRAFT` with a reason.

## 8. Glossary home
The final JSON (§9) IS the glossary home. Additionally mirror a one-line summary into the target frame's description (`Glossary: workspace (never: space); … — full glossary in Skill-2 report`) so a designer opening the file finds it without the report.

## 9. Non-negotiables
Never invent features to write for · never mark final without user review · placeholder vs approved flagged every time.

## 10. Output (final message = JSON block)
```json
{ "v": 1, "skill": 2, "screen": "SignupForm", "frameId": "12:34", "placed": 0, "failed": [], "drafts": [], "glossary": [{ "term": "workspace", "neverUse": ["space"] }], "openIssues": [] }
```
No variables, no layout, no marketing long-form — microcopy JSON only. Skill 3 consumes this block's `v` + `glossary` + `APPROVED` strings.
