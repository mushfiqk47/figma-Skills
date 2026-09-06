---
name: figma-assets
description: Download assets from Figma - export PNG, SVG, PDF slices.
---

# figma-assets

Export nodes as assets.

## Workflow
```js
const n = await figma.getNodeByIdAsync("NODE_ID");
const bytes = await n.exportAsync({ format: "PNG", constraint: { type: "SCALE", value: 2 } });
return { id: n.id, name: n.name, byteLength: bytes.length };
```

## Formats
- `PNG` with SCALE 1/2/3 for raster
- `SVG` for vectors/icons (no constraint needed)
- `PDF` for print slices
- `JPG` with constraint for photos

## Rules
- Export one logical batch per call (max ~10 nodes).
- Name files from node names: `icon-home.svg`, `hero-cover@2x.png`.
- Return node IDs + export settings used.
