---
name: figma-code
description: Generate code from Figma component natively.
---

# figma-code

Generate dev-ready code from a selected node.

## Usage
`/figma-code <nodeId> [react|html|tailwind]`

## Workflow
1. Inspect node first:
```js
const n = await figma.getNodeByIdAsync("NODE_ID");
return { id: n.id, type: n.type, name: n.name, w: Math.round(n.width), h: Math.round(n.height), fills: n.fills, strokes: n.strokes };
```
2. Map Figma props to code:
- AutoLayout VERTICAL/HORIZONTAL -> flex-col / flex-row
- `itemSpacing` -> gap
- `paddingTop/Left/Bottom/Right` -> padding
- `cornerRadius` -> border-radius
- SOLID fills 0-1 -> hex (multiply by 255)
- TEXT -> fontFamily, fontSize, lineHeight {unit,value}, letterSpacing {unit,value}
3. Output single component file, no lorem - use real node names and values.

## Rules
- Colors are 0-1 in Figma, convert to hex/rgba in code.
- Don't guess fonts - list via `await figma.listAvailableFontsAsync()` if unsure.
- Return created code path + source node IDs.
