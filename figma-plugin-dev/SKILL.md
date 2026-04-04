---
name: figma-plugin-dev
description: Build, scaffold, and ship Figma plugins from scratch. Use this skill whenever the user wants to create a Figma plugin, build a Figma extension, develop a FigJam widget, generate code for the Figma Plugin API, set up a plugin project with TypeScript/React/Webpack, debug a Figma plugin, publish to the Figma Community, work with Figma Variables API, implement Codegen extensions for Dev Mode, add payments/monetization to a plugin, or do anything related to Figma plugin or widget development. Even if the user just mentions "Figma" and a feature they want to automate or build inside Figma, this skill likely applies.
---

# Figma Plugin Development

This skill gives you everything needed to scaffold, build, test, and publish production-quality Figma plugins. It covers the full lifecycle — from `manifest.json` to Community submission.

## When to Use This Skill

Use this skill when the user wants to:
- Create a new Figma plugin or FigJam widget
- Set up a plugin project with TypeScript, React, or vanilla JS
- Understand the Figma Plugin API (nodes, traversal, manipulation)
- Build a plugin UI with postMessage communication
- Integrate external APIs or OAuth into a Figma plugin
- Implement design token / Variables API workflows
- Build a Codegen extension for Figma Dev Mode
- Add monetization via the Figma Payments API
- Debug, test, or publish a plugin to Figma Community

---

## Architecture Overview

Figma plugins run in a **dual-environment** architecture:

```
┌──────────────────────────────────┐
│         FIGMA APPLICATION        │
│                                  │
│  ┌────────────┐  ┌────────────┐  │
│  │ Main Thread │  │  UI Thread │  │
│  │  (Sandbox)  │  │  (iframe)  │  │
│  │             │  │            │  │
│  │ code.ts     │  │ ui.html    │  │
│  │ - figma.*   │  │ - DOM      │  │
│  │ - No DOM    │  │ - fetch()  │  │
│  │ - No fetch  │  │ - No figma │  │
│  └──────┬──────┘  └──────┬─────┘  │
│         │  postMessage   │        │
│         └────────────────┘        │
└──────────────────────────────────┘
```

**Key rule:** The main thread has access to `figma.*` APIs but NOT the DOM or network. The UI thread has access to DOM/network but NOT `figma.*`. They communicate via `postMessage`.

---

## Quick Start: Scaffold a Plugin

### Option 1: Figma's Built-in Template (Simplest)
1. Open **Figma Desktop App** (required for local dev)
2. Go to **Plugins → Development → New plugin**
3. Name it, choose "Figma design" or "FigJam", pick a template
4. Save the folder — you get a ready-to-go project

### Option 2: create-figma-plugin (Recommended for Production)
```bash
npx --yes create-figma-plugin
```
This scaffolds a full project with esbuild, TypeScript, and optional Preact UI. Sub-second builds out of the box.

### Option 3: Manual Setup (Full Control)
Create this project structure:

```
my-plugin/
├── src/
│   ├── code.ts          # Main thread entry
│   └── ui.tsx           # UI entry (if using React)
├── manifest.json        # Plugin metadata
├── package.json
├── tsconfig.json
└── webpack.config.js    # or esbuild/vite config
```

Install essential dependencies:
```bash
npm init -y
npm install --save-dev typescript @figma/plugin-typings
npm install --save-dev webpack webpack-cli ts-loader html-webpack-plugin
# If using React:
npm install react react-dom
npm install --save-dev @types/react @types/react-dom
```

---

## manifest.json — The Heart of Your Plugin

Every plugin must define a `manifest.json`. Here is a comprehensive example:

```json
{
  "name": "My Awesome Plugin",
  "id": "1234567890",
  "api": "1.0.0",
  "editorType": ["figma"],
  "main": "dist/code.js",
  "ui": "dist/ui.html",
  "documentAccess": "dynamic-page",
  "networkAccess": {
    "allowedDomains": ["api.example.com"],
    "devAllowedDomains": ["http://localhost:3000"]
  },
  "permissions": [],
  "relaunchButtons": [
    { "command": "edit", "name": "Edit with My Plugin" }
  ]
}
```

### Key Properties
| Property | Required | Description |
|---|---|---|
| `name` | ✅ | Display name in Figma menu |
| `id` | ✅ | Unique ID (assigned by Figma or at publish time) |
| `api` | ✅ | API version (use `"1.0.0"`) |
| `main` | ✅ | Path to compiled JS entry |
| `editorType` | ✅ | `["figma"]`, `["figjam"]`, `["dev"]`, `["slides"]`, or combinations |
| `ui` | Optional | Path to HTML file for UI iframe |
| `documentAccess` | Required for new plugins | Must be `"dynamic-page"` |
| `networkAccess` | Optional | Whitelist external domains |
| `permissions` | Optional | `"currentuser"`, `"activeusers"`, `"fileusers"`, `"payments"`, `"teamlibrary"` |
| `menu` | Optional | Define submenus with multiple commands |
| `parameters` | Optional | Quick Actions parameter inputs |
| `relaunchButtons` | Optional | Persistent node-level action buttons |
| `build` | Optional | Shell command to run before loading |

For the full manifest schema, read `references/manifest-schema.md`.

---

## Communication Between Main & UI

This is the most important pattern in Figma plugin development.

### From Plugin → UI
```typescript
// In code.ts (main thread)
figma.ui.postMessage({ type: 'selection-data', nodes: data });
```

### From UI → Plugin  
```typescript
// In ui.ts (UI thread)
parent.postMessage({ pluginMessage: { type: 'create-rect', width: 100 } }, '*');
```

### Listening for Messages
```typescript
// In code.ts — listen for UI messages
figma.ui.onmessage = (msg) => {
  if (msg.type === 'create-rect') {
    const rect = figma.createRectangle();
    rect.resize(msg.width, msg.width);
  }
};

// In ui.ts — listen for plugin messages
onmessage = (event) => {
  const msg = event.data.pluginMessage;
  if (msg.type === 'selection-data') {
    renderNodes(msg.nodes);
  }
};
```

### Type-Safe Messaging Pattern
Define shared message types:
```typescript
// types.ts (shared)
type PluginMessage =
  | { type: 'create-node'; nodeType: string; name: string }
  | { type: 'update-selection'; ids: string[] }
  | { type: 'export-result'; data: Uint8Array };

type UIMessage =
  | { type: 'selection-changed'; count: number }
  | { type: 'node-created'; id: string };
```

---

## Essential API Patterns

### Showing the UI
```typescript
figma.showUI(__html__, {
  width: 400,
  height: 500,
  themeColors: true  // Inherit Figma's light/dark theme
});
```

### Working with Selection
```typescript
const selection = figma.currentPage.selection;
for (const node of selection) {
  if (node.type === 'TEXT') {
    await figma.loadFontAsync(node.fontName as FontName);
    node.characters = 'Updated text';
  }
}
```

### Creating Nodes
```typescript
const frame = figma.createFrame();
frame.name = 'My Frame';
frame.resize(400, 300);
frame.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.9 } }];
figma.currentPage.appendChild(frame);
```

### Traversal & Search
```typescript
// Find all text nodes on current page
const textNodes = figma.currentPage.findAll(n => n.type === 'TEXT') as TextNode[];

// Find by name
const logo = figma.currentPage.findOne(n => n.name === 'Logo');

// Use criteria for better performance
const texts = figma.currentPage.findAllWithCriteria({ types: ['TEXT'] });
```

### Client Storage (Persistence)
```typescript
// Save user preferences
await figma.clientStorage.setAsync('my-plugin-settings', {
  theme: 'dark',
  lastUsed: Date.now()
});

// Retrieve them
const settings = await figma.clientStorage.getAsync('my-plugin-settings');
```

### Notifications
```typescript
figma.notify('Successfully exported 5 layers! ✅');
figma.notify('Something went wrong', { error: true, timeout: 5000 });
```

### Closing the Plugin
```typescript
figma.closePlugin('Done! Your layers have been updated.');
// Or just:
figma.closePlugin();
```

---

## Node Types & Hierarchy

The Figma document is a tree:
```
DocumentNode (figma.root)
  └── PageNode (figma.currentPage)
       ├── FrameNode
       │    ├── TextNode
       │    ├── RectangleNode
       │    └── GroupNode
       │         └── EllipseNode
       ├── ComponentNode
       │    └── InstanceNode
       ├── VectorNode
       └── SectionNode
```

### Common Node Types
- **Containers:** `FrameNode`, `GroupNode`, `SectionNode`, `ComponentNode`, `ComponentSetNode`, `InstanceNode`
- **Shapes:** `RectangleNode`, `EllipseNode`, `PolygonNode`, `StarNode`, `VectorNode`, `LineNode`
- **Content:** `TextNode`, `BooleanOperationNode`, `SliceNode`

### Shared Properties (via Mixins)
- `id`, `name`, `type`, `visible`, `locked`
- `absoluteBoundingBox`, `absoluteRenderBounds`
- `fills`, `strokes`, `effects`, `opacity`
- `children` (for container nodes via `ChildrenMixin`)
- Methods: `clone()`, `remove()`, `exportAsync()`, `findAll()`, `findOne()`

---

## Build & Development Workflow

### TypeScript Configuration
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2017",
    "module": "commonjs",
    "jsx": "react-jsx",
    "strict": true,
    "outDir": "./dist",
    "typeRoots": ["./node_modules/@figma/plugin-typings", "./node_modules/@types"]
  },
  "include": ["src/**/*.ts", "src/**/*.tsx"]
}
```

### Webpack Configuration (for React UI)
```javascript
// webpack.config.js
const HtmlWebpackPlugin = require('html-webpack-plugin');
const path = require('path');

module.exports = (env, argv) => ({
  mode: argv.mode || 'development',
  entry: {
    code: './src/code.ts',
    ui: './src/ui.tsx',
  },
  module: {
    rules: [
      { test: /\.tsx?$/, use: 'ts-loader', exclude: /node_modules/ },
      { test: /\.css$/, use: ['style-loader', 'css-loader'] },
    ],
  },
  resolve: { extensions: ['.tsx', '.ts', '.js'] },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'dist'),
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './src/ui.html',
      filename: 'ui.html',
      chunks: ['ui'],
      inject: 'body',
      inlineSource: '.(js|css)$',  // Inline everything
    }),
  ],
});
```

### Development Commands
```json
// package.json scripts
{
  "scripts": {
    "build": "webpack --mode=production",
    "watch": "webpack --mode=development --watch",
    "dev": "webpack --mode=development --watch"
  }
}
```

### Loading in Figma
1. Run `npm run watch` in your terminal
2. In Figma Desktop: **Plugins → Development → Import plugin from manifest...**
3. Select your `manifest.json`
4. Run via **Plugins → Development → Your Plugin Name**

---

## Debugging

### Figma Developer Console
- Open: **Plugins → Development → Open Console...** (⌥⌘I / Ctrl+Alt+I)
- All `console.log()` output appears here
- You can interact with `figma.currentPage`, inspect nodes, etc.

### Developer VM
- Enable: **Plugins → Development → Use Developer VM**
- Add `debugger;` in your code to set breakpoints
- Full browser DevTools experience (call stack, scope, step-through)

### Tips
- Comment out `figma.closePlugin()` while debugging to keep objects explorable
- Check for errors (shown in red) in the console
- Use `console.log(JSON.stringify(node, null, 2))` for deep inspection

---

## UI Libraries & Theming

### Option 1: `@create-figma-plugin/ui` (Recommended)
- Built-in **Light, Dark, and FigJam** themes
- Automatically matches user's Figma theme
- Comprehensive component library

### Option 2: `react-figma-plugin-ds`
- React port of Figma's native UI components
- Requires manual dark mode handling

### Option 3: Custom UI with Theme Colors
Use `themeColors: true` in `figma.showUI()` to get CSS variables:
```css
body {
  background: var(--figma-color-bg);
  color: var(--figma-color-text);
  font-family: var(--figma-font-family);
}
```

---

## Performance Best Practices

1. **Batch operations:** Process nodes in chunks of 50-100, yielding with `await delay(10)` between batches
2. **Scope searches:** Use `node.findAll()` from specific containers, not `figma.root`
3. **Use `findAllWithCriteria`:** Filter by type during search for efficiency
4. **Skip hidden nodes:** Check `node.visible` before processing
5. **Use async methods:** Prefer `*Async()` variants (e.g., `loadFontAsync`, `loadAsync`)
6. **Show progress:** Use `figma.ui.postMessage` to send progress updates to the UI
7. **Dynamic page loading:** Set `"documentAccess": "dynamic-page"` in manifest and use `page.loadAsync()` when accessing non-current pages

```typescript
// Anti-freeze helper
async function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function processNodes(nodes: SceneNode[]) {
  for (let i = 0; i < nodes.length; i++) {
    processNode(nodes[i]);
    if (i % 50 === 0) {
      await delay(10); // Yield to prevent UI freeze
      figma.ui.postMessage({ type: 'progress', value: i / nodes.length });
    }
  }
}
```

---

## Advanced Topics

For detailed coverage of these topics, read the respective reference files:

| Topic | Reference File |
|---|---|
| Variables & Design Tokens API | `references/variables-api.md` |
| Codegen Extensions (Dev Mode) | `references/codegen-extensions.md` |
| Payments & Monetization | `references/payments-api.md` |
| OAuth & External APIs | `references/oauth-integration.md` |
| Widgets vs Plugins | `references/widgets-vs-plugins.md` |
| Publishing Checklist | `references/publishing-checklist.md` |
| Full Manifest Schema | `references/manifest-schema.md` |

---

## Publishing to Figma Community

### Pre-submission Checklist
1. ✅ Test across scenarios (empty selection, multiple nodes, large files)
2. ✅ Proper error handling with `figma.notify()` for user feedback
3. ✅ `manifest.json` fully configured (ID, permissions, networkAccess)
4. ✅ Plugin icon (clear at 16px, 24px, 32px, 128px)
5. ✅ Description, screenshots, and support contact info
6. ✅ Privacy policy (if processing user data)

### Publishing Steps
1. **Plugins → Development → Manage plugins in development**
2. Click `...` on your plugin → **Publish**
3. Fill metadata (icon, description, screenshots)
4. Submit for review (typically 5-10 business days)

---

## Common Plugin Patterns

When the user describes a feature, map it to one of these patterns:

| User Says | Pattern | Key APIs |
|---|---|---|
| "Rename layers" | Batch manipulation | `findAll`, `node.name` |
| "Export to code" | Codegen extension | `figma.codegen.on('generate')` |
| "Sync design tokens" | Variables API | `figma.variables.*` |
| "Check accessibility" | Audit/inspect | `node.fills`, contrast calculations |
| "Add content/images" | Content generation | `figma.createImage()`, `node.fills` |
| "Organize components" | Library management | `findAll`, component properties |
| "Connect to API" | OAuth + external service | UI `fetch()`, `postMessage`, `clientStorage` |
| "Paid premium features" | Monetization | `figma.payments.*` |
