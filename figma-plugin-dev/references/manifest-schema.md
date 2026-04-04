# Figma Plugin Manifest — Complete Schema Reference

## Full TypeScript Interface

```typescript
interface PluginManifest {
  // Required
  name: string;
  id: string;
  api: string;               // e.g., "1.0.0"
  main: string;              // Path to compiled JS entry
  editorType: EditorType[];  // ["figma", "figjam", "dev", "slides", "buzz"]

  // UI
  ui?: string | Record<string, string>;

  // Document Access
  documentAccess?: "dynamic-page";

  // Network
  networkAccess?: {
    allowedDomains: string[];
    reasoning?: string;
    devAllowedDomains?: string[];
  };

  // Permissions
  permissions?: PluginPermissionType[];

  // Menu
  menu?: ManifestMenuItem[];

  // Parameters (Quick Actions)
  parameters?: Parameter[];
  parameterOnly?: boolean;

  // Relaunch Buttons
  relaunchButtons?: ManifestRelaunchButton[];

  // Build
  build?: string;

  // Codegen (Dev Mode)
  capabilities?: ("codegen" | "vscode")[];
  codegenLanguages?: string[];
  codegenPreferences?: CodegenPreference[];

  // Experimental
  enableProposedApi?: boolean;
  enablePrivatePluginApi?: boolean;
}
```

## Type Definitions

### EditorType
```typescript
type EditorType = "figma" | "figjam" | "dev" | "slides" | "buzz";
// Note: ["figjam", "dev"] is NOT supported as a combination
```

### PluginPermissionType
```typescript
type PluginPermissionType = 
  | "currentuser"   // figma.currentUser API
  | "activeusers"   // figma.activeUsers API
  | "fileusers"     // StampNode.getAuthorAsync()
  | "payments"      // figma.payments API
  | "teamlibrary";  // figma.teamLibrary API
```

### ManifestMenuItem
```typescript
type ManifestMenuItem =
  | { name: string; command: string; parameters?: Parameter[]; parameterOnly?: boolean }
  | { separator: true }
  | { name: string; menu: ManifestMenuItem[] };  // Submenu
```

### Parameter
```typescript
interface Parameter {
  name: string;           // Display name in UI
  key: string;            // Unique ID for ParameterValues lookup
  description?: string;   // Detailed description
  allowFreeform?: boolean; // Allow any user input
  optional?: boolean;      // Can be skipped
}
```

### ManifestRelaunchButton
```typescript
interface ManifestRelaunchButton {
  command: string;            // Must match setRelaunchData command
  name: string;               // Button display text
  multipleSelection?: boolean; // Show when multiple nodes selected (default: false)
}
```

## Network Access Patterns

### `allowedDomains` Valid Patterns

| Pattern | Meaning |
|---|---|
| `["none"]` | No external network access |
| `["*"]` | All domains (requires `reasoning`) |
| `["*.example.com"]` | All subdomains of example.com |
| `["https://api.example.com"]` | Specific scheme + domain |
| `["api.example.com/rest/"]` | Trailing slash = all paths under this |
| `["api.example.com/rest/get"]` | No trailing slash = exact path only |
| `["http://localhost:3000"]` | Local dev server (requires `reasoning` if in `allowedDomains`) |

### Schemes
Only `http`, `https`, `ws`, and `wss` are permitted. `file` is not allowed.

### devAllowedDomains
Same patterns as `allowedDomains`, but only active during development. Use this for `localhost` to avoid needing `reasoning` in production.

## UI Field Variants

### Single HTML file
```json
{ "ui": "ui.html" }
```
Accessible in code as `__html__`:
```typescript
figma.showUI(__html__, { width: 400, height: 300 });
```

### Multiple HTML files
```json
{
  "ui": {
    "main": "ui/main.html",
    "settings": "ui/settings.html"
  }
}
```
Accessible via `__uiFiles__`:
```typescript
figma.showUI(__uiFiles__["main"]);
// or
figma.showUI(__uiFiles__["settings"]);
```

## Menu Examples

### Simple menu
```json
{
  "menu": [
    { "name": "Run Analysis", "command": "analyze" },
    { "name": "Settings", "command": "settings" }
  ]
}
```

### Menu with separators and submenus
```json
{
  "menu": [
    { "name": "Create Text", "command": "text" },
    { "name": "Create Frame", "command": "frame" },
    { "separator": true },
    {
      "name": "Create Shape",
      "menu": [
        { "name": "Circle", "command": "circle" },
        { "name": "Rectangle", "command": "rectangle" }
      ]
    }
  ]
}
```

### Handling commands in code
```typescript
switch (figma.command) {
  case 'analyze':
    runAnalysis();
    break;
  case 'settings':
    figma.showUI(__uiFiles__["settings"], { width: 300, height: 400 });
    break;
}
```

## Parameters Example (Quick Actions)
```json
{
  "parameters": [
    {
      "name": "Icon name",
      "key": "icon-name",
      "description": "Enter the name of the icon"
    },
    {
      "name": "Size",
      "key": "size",
      "allowFreeform": true
    },
    {
      "name": "Color",
      "key": "color",
      "allowFreeform": true,
      "optional": true
    }
  ],
  "parameterOnly": true
}
```

Listen for parameter input:
```typescript
figma.parameters.on('input', ({ key, query, result }) => {
  if (key === 'icon-name') {
    const icons = ['arrow', 'check', 'close', 'menu'];
    result.setSuggestions(icons.filter(i => i.includes(query)));
  }
});

figma.on('run', ({ parameters }) => {
  if (parameters) {
    const iconName = parameters['icon-name'];
    const size = parameters['size'];
    insertIcon(iconName, size);
  }
});
```

## Codegen Manifest
```json
{
  "name": "My Codegen Plugin",
  "id": "...",
  "api": "1.0.0",
  "main": "code.js",
  "editorType": ["dev"],
  "capabilities": ["codegen", "vscode"],
  "codegenLanguages": [
    { "label": "React", "value": "react" },
    { "label": "Vue", "value": "vue" }
  ]
}
```
