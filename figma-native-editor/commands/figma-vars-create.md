---
name: figma-vars-create
description: Create full Figma variable system from DESIGN.md, any source, or pasted Figma link - Tailwind v4 50-950 ramps, Light/Dark modes, WCAG AA contrast, color + type + spacing + radius + padding.
---

# figma-vars-create

Build the complete token foundation. Run BEFORE connecting anything.

## Usage
`/figma-vars-create <DESIGN.md path | pasted palette/text | figma.com URL> [brand Hex]`

## Step 1 - harvest the source (one of three)

**A. DESIGN.md / text:** read the file, pull every hex, font family, size, spacing value.
**B. Any source mentioned:** user names it ("use Stripe blue", "match my site") - resolve to hex first, confirm with user before creating.
**C. Figma link:** extract live paints via MCP, then:
```js
const page = await figma.getNodeByIdAsync("PAGE_ID");
await figma.setCurrentPageAsync(page);
const paints = page.findAllWithCriteria({ types: ['FRAME','RECTANGLE','TEXT','ELLIPSE','COMPONENT','INSTANCE'] })
  .flatMap(n => [...(n.fills||[]), ...(n.strokes||[])].filter(p => p.type==='SOLID').map(p => p.color));
const hexes = [...new Set(paints.map(c => '#' + [c.r,c.g,c.b].map(v => Math.round(v*255).toString(16).padStart(2,'0')).join('')))];
return { hexes };
```

## Step 2 - derive the system (500 is the base, always)

Color architecture = **primitives (modeless) + semantics (Light/Dark modes)**:
- `primitives/brand-50 ... brand-950` - 11 steps, Tailwind v4 shape: 50 lightest, 500 = brand base exactly, 950 darkest. Same for `primitives/neutral-*` and each semantic hue (success/warning/danger/info).
- `semantic/` collection with TWO modes: `Light` + `Dark`. Every value aliases a primitive (never raw hex), e.g. `bg/surface: Light→neutral-50, Dark→neutral-950`. Text-on-fill pairs MUST pass WCAG AA: **4.5:1 normal text, 3:1 large (18pt+ / 14pt+ bold)**. If a pair fails, step the ramp until it passes and note it.
- Type: `font/family`, `font/size-*` (12/14/16/20/24/32...), `font/weight-*`, `font/line-*`.
- Space: 4pt base `space/1=4 ... space/16=64`, `padding/v-*`, `padding/h-*`, `radius/sm-md-lg-full`.

## Step 3 - create (small batches, explicit scopes, never ALL_SCOPES)

```js
const col = figma.variables.createVariableCollection("Design tokens");
col.renameMode(col.modes[0].modeId, "Light");
const darkId = col.addMode("Dark");
const v = figma.variables.createVariable("brand/500", col, "COLOR");
v.setValueForMode(col.modes[0].modeId, { r: 0.851, g: 0.149, b: 0.149 });
v.scopes = ["FRAME_FILL", "SHAPE_FILL", "TEXT_FILL"];
return { collectionId: col.id, variableId: v.id };
```
- COLOR hues: fill scopes. TEXT_FILL only for text inks. FLOAT radius: [CORNER_RADIUS]. FLOAT gap/padding: [GAP] (Figma has no padding scope). STRING family: [FONT_FAMILY]. FLOAT size: [FONT_SIZE].
- Dark mode values: set EVERY semantic in both modes. Primitives stay modeless.
- Max ~10 variables per call. Return every ID.

## Step 4 - report (mandatory)

Table: variable | Light | Dark | contrast vs pair | AA pass/fail. Plus collection ID + total counts. Any AA fail must be fixed before `/figma-vars-connect`.
