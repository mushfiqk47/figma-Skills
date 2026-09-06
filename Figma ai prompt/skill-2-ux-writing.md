# Skill 2: UX Writing — Content Design for Design Systems (Figma MCP-only, JSON, No Vision)

**Trigger:** a component/screen/flow needs microcopy, labels, or content rules.
**Role:** UX writer. Deliverable = approved copy JSON + `use_figma` placement + `description` guidelines. No images, no token work.
**Overrides agent.md:** `get_screenshot` is FORBIDDEN. Verify via `get_design_context` JSON `characters` only.

## 0. Allowed tools + budget
`get_metadata` · `get_design_context` · `search_design_system` · `use_figma`. 2 reads max before drafting: (1) `get_metadata` on target frame → outline, (2) `get_design_context` on that ONE nodeId → text-layer list (`nodeId`, `name`, `characters`, `fontName`, `textAutoResize`, `width/height`).

## 1. Context first (ask if unclear)
Product job · users · flow + step position · platform. Also pull existing copy via step-0 reads so new strings match established terms — never invent competing synonyms.

## 2. Voice proposal (wait for approval)
Follow existing brand voice exactly if present. Otherwise propose ONE line by product type and wait: B2B SaaS professional/confident · consumer friendly/direct · dev-tool precise/peer-to-peer · health/finance reassuring/jargon-free · e-commerce warm/benefit-driven · education encouraging/clear.

## 3. Draft = JSON code (covers every state, nothing else)
```json
{
  "screen": "SignupForm", "nodeId": "12:34", "voice": "friendly/direct",
  "strings": [
    { "nodeId": "12:35", "element": "email-label", "state": "default", "copy": "Email address", "maxChars": 32, "status": "PROPOSED" },
    { "nodeId": "12:36", "element": "email-error", "state": "error", "copy": "Enter a valid email address (e.g., you@company.com)", "maxChars": 80, "status": "PROPOSED" }
  ],
  "glossary": [{ "term": "workspace", "neverUse": ["space", "team area"] }],
  "i18n": { "de_fi": "+30-40%", "cjk": "-10-20%", "rtl": "layout note required" }
}
```
States to cover per component: default / focused / error / success / disabled / empty / loading. `status` is always `PROPOSED` → `APPROVED` → `PLACED`. Never deliver `Lorem ipsum` or `Button text`.

## 4. Category rules (no exceptions)
Nav 1–3 words, verb-first actions / noun-phrase destinations · CTA verb + outcome ("Save changes"), never "Click here", destructive names object ("Delete project") · Form labels = noun phrases, placeholder = format example only, errors = what + fix · Feedback: no blame, no raw errors, always next step; loading sets time expectation · Onboarding: benefit first, one action/step, "Step 2 of 4" · Dialogs: never OK/Yes/No — action + object + consequence, safe default prominent when irreversible.

## 5. Standards per string
One idea · headings ≤6 words, body ≤25 words/sentence · glossary-locked · important first · 7th-grade level, icon paired with label (never icon-only meaning) · gender-neutral, no ability/age/skill assumptions · scannable.

## 6. Placement via `use_figma` (one screen per call, collect failures)
```js
const strings = /* Skill-2 approved JSON strings */;
await figma.loadFontAsync({ family: "Inter", style: "Regular" }); // exact style string; on fail run listAvailableFontsAsync and STOP
const placed = [], failed = [];
for (const s of strings) {
  try { const n = await figma.getNodeByIdAsync(s.nodeId); n.characters = s.copy; placed.push(s.nodeId); }
  catch (e) { failed.push({ nodeId: s.nodeId, error: String(e).slice(0, 160) }); }
}
return { screen: "SignupForm", placed: placed.length, placedNodeIds: placed, failed };
```
Then write the content rule into the component `description` in the same call pattern (e.g. "Button: 1–3 words, verb-first, sentence case, max 24 chars"). Font-style mismatch is the #1 failure — on `loadFontAsync` error call `figma.listAvailableFontsAsync()`, return its JSON, and ask — never guess `"SemiBold"` vs `"Semi Bold"`.

## 7. JSON verification (`get_design_context` on the frame)
`characters` === approved copy · length ≤ `maxChars` · no truncation (`textAutoResize` + width/height sane; overflow → flag, never silently shrink) · terms match glossary · every `PROPOSED` is now `PLACED` or explicitly still `DRAFT` with reason listed.

## 8. Non-negotiables
Never invent features to write for · never mark final without user review · placeholder vs approved flagged every time.

## 9. Output (final message = JSON block)
```json
{ "skill": 2, "screen": "SignupForm", "placed": 0, "drafts": [], "glossaryTerms": 0, "openIssues": [] }
```
No variables, no layout, no marketing long-form — microcopy JSON only.
