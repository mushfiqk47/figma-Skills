---
name: figma-native
description: Edit Figma natively via chat - canonical recipes for layers, text, auto-layout, variables. Use whenever creating/editing Figma via use_figma.
---

# Figma Native via Chat

This skill makes chat-editing match inside-Figma editing perfectly.

## 1. Pre-flight (every call)
- `return` data back. No `figma.closePlugin()`, no async IIFE, no `figma.notify()`, no `console.log()` as output.
- Colors 0-1 only: `{r:1,g:0,b:0}` = red. Paint opacity at paint level, not in color.
- Fills/strokes are read-only arrays: clone, modify, reassign.
- `await` every Promise. Max 10 logical ops per call. Return all created/mutated node IDs.

## 2. Canonical text edit (mandatory)
Every text mutation follows load -> await -> mutate -> return IDs. Load CURRENT fonts, not hardcoded:
```js
const n = await figma.getNodeByIdAsync("TEXT_ID");
const segs = n.getStyledTextSegments(["fontName"]);
for (const s of segs) await figma.loadFontAsync(s.fontName);
n.characters = "New copy";
return { mutatedNodeIds: [n.id] };
```
If style string unverified, call `await figma.listAvailableFontsAsync()` first. Inter is preloaded, others are not.

## 3. Containers
Use `figma.createAutoLayout()` for related children, not `createFrame()` + x/y:
```js
const row = figma.createAutoLayout("HORIZONTAL", { name: "Card row", itemSpacing: 12 });
const card = figma.createAutoLayout("VERTICAL", { name: "Card", itemSpacing: 8, paddingTop: 16, paddingLeft: 16, paddingBottom: 16, paddingRight: 16 });
row.appendChild(card); // append FIRST
card.layoutSizingHorizontal = "FILL"; // then set HUG/FILL
return { createdNodeIds: [row.id, card.id] };
```
- `layoutSizing*` = FIXED|HUG|FILL on child. `primaryAxisSizingMode` = FIXED|AUTO on frame. Don't cross them.
- `FIXED` always works. `HUG` only on auto-layout frame itself OR TEXT child. `FILL` only on child of auto-layout.
- Position new page-level nodes away from (0,0): scan `figma.currentPage.children` for clear space.

## 4. Pages
Context resets each call. First page is current by default.
```js
const p = figma.root.children.find(p => p.name === "Page 1");
await figma.setCurrentPageAsync(p); // sync setter does NOT work, use this, max once per call
```
Multi-page work: one call per page, fanned in parallel. Never loop setCurrentPageAsync.

## 5. Demo-file starter (new file)
Step 1 inspect pages, Step 2 create tokens, Step 3 create components, Step 4 compose layout, Step 5 screenshot verify:
```js
await frame.screenshot(); // inline verify, no separate get_screenshot needed
frame.placeholder = false; // never leave shimmer on finished nodes
```

## 6. Error recovery
use_figma is atomic - failed script changes nothing. On error STOP, read message, fix, retry. Don't recreate everything on visual miss - targeted fix only.
