# Figma Widgets vs Plugins — Decision Guide

## Core Differences

| Feature | Plugins | Widgets |
|---|---|---|
| **Persistence** | Transient — exists while running | Persistent — lives on canvas |
| **Visibility** | Single user (off-canvas modal) | Multiplayer (visible to all) |
| **UI Model** | Off-canvas iframe/modal | On-canvas React-like components |
| **Primary Use** | Automation, import/export, batch ops | Collaboration, interactive tools |
| **Installation** | Each user installs separately | Added to file, available to all editors |
| **State** | Temporary (or clientStorage) | Synced across all users |

## When to Build a Plugin

- Automating repetitive design tasks (rename layers, batch export)
- Importing/exporting data (design tokens, content, translations)
- Performing analysis (accessibility audits, lint checks)
- Connecting to external services (APIs, databases)
- Tasks that don't need to be visible to other users
- Complex UIs that need a full panel/modal experience

## When to Build a Widget

- Interactive elements all collaborators should see (voting, polls)
- Shared state visible on the canvas (progress trackers, timers)
- Collaborative tools (whiteboards, annotation systems)
- On-canvas utilities (color pickers, calculators)
- FigJam-specific interactive content

## Widget Development Basics

### Manifest
```json
{
  "name": "My Widget",
  "id": "...",
  "api": "1.0.0",
  "widgetApi": "1.0.0",
  "main": "code.js",
  "editorType": ["figma", "figjam"]
}
```

### Widget Code (React-like JSX)
```typescript
const { widget } = figma;
const { AutoLayout, Text, Input, useSyncedState, useEffect } = widget;

function MyWidget() {
  const [count, setCount] = useSyncedState('count', 0);

  return (
    <AutoLayout
      direction="vertical"
      spacing={8}
      padding={16}
      fill="#FFFFFF"
      cornerRadius={8}
    >
      <Text fontSize={24} fontWeight="bold">
        Count: {count}
      </Text>
      <AutoLayout
        onClick={() => setCount(count + 1)}
        padding={{ horizontal: 16, vertical: 8 }}
        fill="#0066FF"
        cornerRadius={4}
      >
        <Text fontSize={14} fill="#FFFFFF">
          Increment
        </Text>
      </AutoLayout>
    </AutoLayout>
  );
}

widget.register(MyWidget);
```

### Key Widget APIs
- **`useSyncedState(key, default)`** — State synced across all users
- **`useSyncedMap(key)`** — Synced key-value map
- **`useEffect(callback)`** — Side effects on state change  
- **`useStickable()`** — FigJam: receive stamps/sticky notes
- **`useStickableHost()`** — FigJam: host stickable objects
- **`usePropertyMenu(items, onChange)`** — Property menu in toolbar

### Widget Components
- `AutoLayout` — Flexbox-like container
- `Text` — Text rendering
- `Input` — User text input
- `Frame` — Basic frame
- `Image` — Image rendering
- `SVG` — SVG rendering
- `Fragment` — Grouping without DOM element

## Combining Widgets + Plugin API

Widgets can use the Plugin API for deeper Figma integration:
```typescript
function MyWidget() {
  return (
    <AutoLayout
      onClick={async () => {
        // Access Plugin API from widget
        const selection = figma.currentPage.selection;
        const count = selection.length;
        figma.notify(`${count} nodes selected`);
      }}
    >
      <Text>Check Selection</Text>
    </AutoLayout>
  );
}
```

Widgets can also launch iframes for complex UIs:
```typescript
function MyWidget() {
  return (
    <AutoLayout
      onClick={() => {
        return new Promise((resolve) => {
          figma.showUI(__html__, { width: 400, height: 300 });
        });
      }}
    >
      <Text>Open Settings</Text>
    </AutoLayout>
  );
}
```
