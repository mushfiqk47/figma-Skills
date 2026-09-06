---
name: figma-vars-connect
description: Bind variables to Figma frames end-to-end natively - zero design change, zero missed tokens or layouts. Run AFTER figma-vars-create.
---

# figma-vars-connect

Connect tokens to canvas. The design must look pixel-identical after. Geometry, colors, type - nothing moves, nothing recolors. Only raw values become `var(--...)` bindings.

## Usage
`/figma-vars-connect <frame/node IDs> [collection name]`

## Step 1 - freeze the before-state (mandatory, one page per call)

```js
const page = await figma.getNodeByIdAsync("PAGE_ID");
await figma.setCurrentPageAsync(page);
const root = await figma.getNodeByIdAsync("FRAME_ID");
const snap = [];
root.findAll(n => snap.push({ id: n.id, type: n.type, x: Math.round(n.x), y: Math.round(n.y), w: Math.round(n.width), h: Math.round(n.height) }));
await root.screenshot();
return { count: snap.length, nodes: snap };
```
Keep this snapshot. It is the contract: after-state must match it exactly.

## Step 2 - inventory every bindable property (read-only)

Walk the whole subtree and list, per node: fills, strokes, text fills, fontFamily, fontSize, fontWeight, lineHeight, cornerRadius (per-corner), itemSpacing, paddingTop/Bottom/Left/Right, gap, width/height where token-driven, effects. Map each raw value to the matching variable from `/figma-vars-create` (nearest ramp step for stray hexes - flag them, never invent new raws silently).

## Step 3 - bind in small batches (max 10 nodes per call)

```js
const btn = await figma.getNodeByIdAsync("BTN_ID");
const primary = await figma.variables.getVariableByIdAsync("VAR_ID");
const fills = JSON.parse(JSON.stringify(btn.fills));
fills[0] = btn.setBoundVariableForPaint(fills[0], "color", primary);
btn.fills = fills;
btn.setBoundVariable("cornerRadius", await figma.variables.getVariableByIdAsync("RADIUS_ID"));
return { mutatedNodeIds: [btn.id] };
```
- Text: load current fonts via `getStyledTextSegments(["fontName"])` + `await loadFontAsync` BEFORE any mutation.
- Fills/strokes: clone array, `setBoundVariableForPaint`, reassign (they are read-only).
- `setBoundVariableForPaint` returns a NEW paint - capture and reassign.
- One property family per pass (fills, then radius, then spacing, then type) so failures stay isolated.

## Step 4 - prove zero-change + full coverage (mandatory)

1. Re-snapshot geometry - every x/y/w/h must equal Step 1 exactly.
2. `get_design_context` on each bound node - every bindable property must show `var(--...)`.
3. Screenshot after, compare with before.
4. Report: `bound X/Y properties (Z%)`, list of every unbound property with reason (only non-tokenizable values allowed: images, gradients, absolute-positioned one-offs), plus all mutated node IDs. Anything missed = run again until 100% of tokenizable surface is bound.
