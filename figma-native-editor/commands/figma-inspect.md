---
name: figma-inspect
description: Extract design specs from Figma file natively - pages, nodes, fills, text, layout.
---

# figma-inspect

Extract live specs from a Figma file. Use when user pastes a `figma.com/design/...` URL.

## Workflow

1. Ask for file URL if missing. Confirm it is Design (not board/slides).
2. Inspect first, in small steps:
```js
// Step 1 - pages
return figma.root.children.map(p => ({ id: p.id, name: p.name, children: p.children.length }));
```
3. Then per target page (ONE page per call):
```js
const page = await figma.getNodeByIdAsync("PAGE_ID");
await figma.setCurrentPageAsync(page);
return {
  page: page.name,
  topNodes: page.children.slice(0, 20).map(n => ({ id: n.id, type: n.type, name: n.name, x: Math.round(n.x), y: Math.round(n.y), w: Math.round(n.width), h: Math.round(n.height) }))
};
```
4. Report: page list, frame counts, text styles, colors (0-1 range), spacing.

## Rules
- Never use `figma.notify()` - use `return`.
- Never wrap in async IIFE - top-level `await` + `return` only.
- Return node IDs for next steps.
- `figma.currentPage = x` does NOT work - use `await figma.setCurrentPageAsync(page)`.
