---
name: figma-audit
description: Full end-to-end audit of tokens, bindings, contrast, and layout - scored report with fix list.
---

# figma-audit

Audit everything, change nothing. Read-only. Output is a scored report.

## Usage
`/figma-audit <figma.com URL | frame/node IDs>`

## Check 1 - token architecture (25 pts)

```js
const cols = await figma.variables.getLocalVariableCollectionsAsync();
const vars = await figma.variables.getLocalVariablesAsync();
return cols.map(c => ({ name: c.name, modes: c.modes.map(m => m.name), varCount: c.variableIds.length }));
```
Score: primitives 50-950 complete per hue (500 = brand base)? Semantics alias primitives, never raw hex? Light + Dark mode parity (every semantic set in BOTH modes)? Scopes explicit (no ALL_SCOPES)? No duplicates, no unused variables? Deduct per violation.

## Check 2 - contrast a11y (25 pts)

Every text-on-fill pair, both modes: normal text needs **4.5:1**, large text (18pt+ / 14pt+ bold) needs **3:1**. Compute relative luminance per WCAG and tabulate pair | ratio | AA pass/fail. One fail = flag with the ramp step that fixes it.

## Check 3 - binding coverage (25 pts)

Per frame subtree via `get_design_context`: % of bindable properties showing `var(--...)`. List every raw value still on canvas with node ID + property. 100% tokenizable = full marks.

## Check 4 - layout + type health (25 pts)

Auto-layout where children relate (no absolute x/y stacks)? HUG only on auto-layout frame or TEXT child, FILL only on auto-layout child (else FIXED)? Page-level nodes clear of (0,0) overlap? Fonts loaded/valid (no missing-family nodes)? Text not clipped (screenshot spot-check)?

## Report format (mandatory)

```
FIGMA AUDIT - <file> - <date>
1. Tokens ....../25
2. Contrast .../25
3. Bindings .../25
4. Layout ...../25
TOTAL ...../100 - [HEALTHY | NEEDS WORK | CRITICAL]
Top fixes (ordered): 1... 2... 3...
Appendix: full fail table (node ID, property, expected, actual)
```

HEALTHY 90+, NEEDS WORK 70-89, CRITICAL below 70. End with the single next command to run (`/figma-vars-create` gap, `/figma-vars-connect` remainder, or specific node fixes).
