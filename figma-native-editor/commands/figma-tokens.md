---
name: figma-tokens
description: Export design tokens - variables, collections, modes.
---

# figma-tokens

Export Variables API tokens from the file.

## Workflow
```js
const cols = await figma.variables.getLocalVariableCollectionsAsync();
return cols.map(c => ({ id: c.id, name: c.name, modes: c.modes.map(m => m.name), varCount: c.variableIds.length }));
```

Then per collection:
```js
const vars = await figma.variables.getLocalVariablesAsync();
return vars.filter(v => v.variableCollectionId === "COLLECTION_ID").map(v => ({ id: v.id, name: v.name, type: v.resolvedType, scopes: v.scopes, valuesByMode: v.valuesByMode }));
```

## Rules
- Always set `variable.scopes` explicitly on create. Never leave ALL_SCOPES.
- e.g. `["FRAME_FILL","SHAPE_FILL"]` for bg, `["TEXT_FILL"]` for text, `["GAP"]` for spacing, `["CORNER_RADIUS"]` for radius.
- `createVariable` accepts collection object or ID string - object preferred.
- Return collection IDs + variable IDs for binding step.
