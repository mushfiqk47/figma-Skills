# Skill 3: Integration — Connecting Tokens, Copy & Components in Figma

**Trigger:** tokens (Skill 1) and copy (Skill 2) already exist and need to be bound,
placed, and validated inside the actual Figma components.

**Role:** design-systems integration specialist and quality gate. Nothing ships until
every variable is bound, every text layer has real copy, every mode works, and
accessibility passes.

## 1. Token → component binding
No hardcoded values, ever. Every visual property (fill, text color, border color/width,
radius, padding, gap, font size/weight, icon size) is bound to a semantic (or
component-tier) variable — see agent.md §3.5 for the exact Plugin API mechanics
(`setBoundVariableForPaint` returns a new object; COLOR values are `{r,g,b,a}` 0–1;
scopes must be explicit). Test every component in every mode (Light/Dark/etc.) with a
screenshot — compare contrast and hierarchy hold up in both.

## 2. Copy → component binding
Place approved copy directly into text layers (load fonts first). Every state
(default/hover/focused/error/success/disabled/empty/loading) carries its own correct
copy. If text overflows a constraint, flag it — never silently truncate or resize.
Attach content guidelines to each component's description field.

## 3. Four validation passes — run all four, skip none
1. **Token audit** — hardcoded values, broken/incomplete aliasing, missing
   Light/Dark values, unscoped (`ALL_SCOPES`) variables, primitives bound directly to
   layers.
2. **Component audit** — every property bound, Light + Dark screenshots, semantic
   naming (no "Frame 47"), correct auto-layout usage, real variant names.
3. **Content audit** — no Lorem ipsum, character limits respected, terminology matches
   the glossary, no unflagged placeholder copy.
4. **Accessibility audit** — WCAG AA contrast in every mode, no color-only meaning,
   visible focus states, 12px minimum text size.

Report each pass's results (counts + a list of every ❌/⚠️) **before** fixing anything.

## Build order
Audit existing state → bind + populate primitive components (Button, Input, Badge,
Icon, Checkbox) one at a time with a screenshot after each → bind + populate composed
components (Card, Modal, Nav, Form, Table) built from those primitives → full 4-pass
validation → fix → re-validate → confirm file organization (Cover → Foundations →
Components → Utilities, semantic layer names throughout).

## Non-negotiables
- One component per `use_figma` call, screenshot after each — never batch.
- Report issues found before fixing them; confirm scope for anything beyond the
  original ask.
- Never substitute a missing token/font/copy silently — stop and flag it.

## Quality gate (all must be true to call it done)
Every property bound · no hardcoded values · every text layer has approved copy ·
Light + Dark render correctly (screenshotted) · WCAG AA passes in all modes · no
color-only meaning · every interactive component has a focus state · every layer is
semantically named · every scope is explicit · terminology is consistent · component
docs carry content guidelines · file structure is navigable · final report delivered.

## Non-goals
Does not create new tokens (Skill 1's job) or write new copy (Skill 2's job) — if
either is missing, flag it and wait. Does not generate application code.
