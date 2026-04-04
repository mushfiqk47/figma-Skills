# Figma Variables API — Design Tokens Reference

## Overview

The Variables API lets plugins create, read, update, and delete Figma Variables (design tokens). Variables support four data types: `COLOR`, `FLOAT`, `STRING`, and `BOOLEAN`.

## Core Concepts

### Variable Collections
Variables are organized into collections. Each collection has one or more **modes** (e.g., Light/Dark, Desktop/Mobile).

### Variable Types
| Type | Use Cases | Example |
|---|---|---|
| `COLOR` | Colors, fills, strokes | `{ r: 0.1, g: 0.2, b: 0.9, a: 1 }` |
| `FLOAT` | Spacing, sizing, border-radius, opacity | `16`, `1.5` |
| `STRING` | Text content, font families | `"Inter"`, `"Hello World"` |
| `BOOLEAN` | Feature flags, visibility toggles | `true`, `false` |

## API Methods

### Getting Collections & Variables

```typescript
// Get all local variable collections
const collections = await figma.variables.getLocalVariableCollectionsAsync();

// Get all local variables
const variables = await figma.variables.getLocalVariablesAsync();

// Filter by type
const colorVars = await figma.variables.getLocalVariablesAsync('COLOR');
const floatVars = await figma.variables.getLocalVariablesAsync('FLOAT');

// Get a specific variable by ID
const variable = await figma.variables.getVariableByIdAsync(variableId);

// Get a specific collection by ID
const collection = await figma.variables.getVariableCollectionByIdAsync(collectionId);
```

### Creating Collections & Variables

```typescript
// Create a new collection
const collection = figma.variables.createVariableCollection('Design Tokens');

// Create a variable in a collection
const colorVar = figma.variables.createVariable(
  'color/primary/main',     // Name (slashes create folder groups)
  collection,                // Parent collection
  'COLOR'                    // Type
);

// Set value for a mode
const defaultModeId = collection.modes[0].modeId;
colorVar.setValueForMode(defaultModeId, {
  r: 0.2,
  g: 0.4,
  b: 0.95,
  a: 1
});
```

### Adding Modes

```typescript
// Add a new mode to a collection
const darkModeId = collection.addMode('Dark');

// Set value for the dark mode
colorVar.setValueForMode(darkModeId, {
  r: 0.1,
  g: 0.15,
  b: 0.3,
  a: 1
});
```

### Variable Aliases (Token References)

```typescript
// Create an alias — a variable that references another variable
const semanticColor = figma.variables.createVariable(
  'semantic/background-primary',
  collection,
  'COLOR'
);

// Point the semantic token at the primitive token
const alias = figma.variables.createVariableAlias(colorVar);
semanticColor.setValueForMode(defaultModeId, alias);
```

### Applying Variables to Nodes

```typescript
const frame = figma.createFrame();

// Apply a color variable as a fill
const fillsCopy = [...frame.fills];
fillsCopy[0] = figma.variables.setBoundVariableForPaint(
  fillsCopy[0],
  'color',
  colorVar
);
frame.fills = fillsCopy;

// Apply a float variable to properties like corner radius
frame.setBoundVariable('cornerRadius', spacingVar);
```

### Deleting Variables

```typescript
variable.remove();
collection.remove();
```

## Best Practices: Three-Tier Token Architecture

### 1. Primitive (Base) Tokens
Raw values — the foundation:
```
color/blue/500 → #3B82F6
color/gray/100 → #F3F4F6
spacing/4 → 4
spacing/8 → 8
radius/sm → 4
```

### 2. Semantic Tokens
Purpose-driven names that alias primitives:
```
surface/background → alias → color/gray/100
surface/foreground → alias → color/gray/900
text/primary → alias → color/gray/900
interactive/primary → alias → color/blue/500
```

### 3. Component Tokens
Component-specific tokens aliasing semantic tokens:
```
button/bg-primary → alias → interactive/primary
button/text-primary → alias → surface/background
card/bg → alias → surface/background
```

## Complete Example: Import Tokens from JSON

```typescript
interface TokenFile {
  [category: string]: {
    [name: string]: {
      value: string;
      type: 'color' | 'spacing' | 'radius';
    };
  };
}

async function importTokens(json: TokenFile) {
  const collection = figma.variables.createVariableCollection('Imported Tokens');
  const modeId = collection.modes[0].modeId;

  for (const [category, tokens] of Object.entries(json)) {
    for (const [name, token] of Object.entries(tokens)) {
      const varName = `${category}/${name}`;

      if (token.type === 'color') {
        const variable = figma.variables.createVariable(varName, collection, 'COLOR');
        variable.setValueForMode(modeId, hexToRgba(token.value));
      } else {
        const variable = figma.variables.createVariable(varName, collection, 'FLOAT');
        variable.setValueForMode(modeId, parseFloat(token.value));
      }
    }
  }

  figma.notify(`Imported ${Object.keys(json).length} categories of tokens ✅`);
}

function hexToRgba(hex: string): RGBA {
  const r = parseInt(hex.slice(1, 3), 16) / 255;
  const g = parseInt(hex.slice(3, 5), 16) / 255;
  const b = parseInt(hex.slice(5, 7), 16) / 255;
  return { r, g, b, a: 1 };
}
```

## Exporting Variables to JSON

```typescript
async function exportVariables() {
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const output: Record<string, any> = {};

  for (const collection of collections) {
    const collectionData: Record<string, any> = {};

    for (const varId of collection.variableIds) {
      const variable = await figma.variables.getVariableByIdAsync(varId);
      if (!variable) continue;

      const modeValues: Record<string, any> = {};
      for (const mode of collection.modes) {
        modeValues[mode.name] = variable.valuesByMode[mode.modeId];
      }

      collectionData[variable.name] = {
        type: variable.resolvedType,
        values: modeValues,
      };
    }

    output[collection.name] = collectionData;
  }

  // Send to UI for download
  figma.ui.postMessage({ type: 'export-tokens', data: output });
}
```
