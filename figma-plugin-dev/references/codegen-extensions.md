# Figma Codegen Extensions — Dev Mode Reference

## Overview

Codegen plugins run in **Figma Dev Mode** and generate custom code snippets that appear in the Inspect panel alongside native CSS, Swift, and Compose output.

## Manifest Configuration

```json
{
  "name": "My Codegen Plugin",
  "id": "1234567890",
  "api": "1.0.0",
  "main": "code.js",
  "editorType": ["dev"],
  "capabilities": ["codegen", "vscode"],
  "codegenLanguages": [
    { "label": "React (TSX)", "value": "react-tsx" },
    { "label": "Vue SFC", "value": "vue-sfc" }
  ],
  "codegenPreferences": [
    {
      "itemType": "select",
      "propertyName": "styling",
      "label": "Styling Method",
      "options": [
        { "label": "CSS Modules", "value": "css-modules" },
        { "label": "Styled Components", "value": "styled-components" },
        { "label": "Tailwind CSS", "value": "tailwind" }
      ],
      "default": "css-modules"
    },
    {
      "itemType": "select",
      "propertyName": "typescript",
      "label": "TypeScript",
      "options": [
        { "label": "Yes", "value": "true" },
        { "label": "No", "value": "false" }
      ],
      "default": "true"
    }
  ],
  "documentAccess": "dynamic-page",
  "networkAccess": {
    "allowedDomains": ["none"]
  }
}
```

### Key Fields
- **`editorType: ["dev"]`** — Required for codegen; runs only in Dev Mode
- **`capabilities: ["codegen"]`** — Enables the codegen event system
- **`capabilities: ["vscode"]`** — Optional; enables Figma for VS Code support
- **`codegenLanguages`** — Each entry appears as an option in the Inspect panel dropdown
- **`codegenPreferences`** — Adds configuration UI (dropdowns, checkboxes) to the Inspector

## Core Implementation

### Basic Example

```typescript
figma.codegen.on("generate", async (event) => {
  const { node, language } = event;

  if (language === "react-tsx") {
    return generateReact(node);
  } else if (language === "vue-sfc") {
    return generateVue(node);
  }

  return [];
});

function generateReact(node: SceneNode): CodegenResult[] {
  const componentName = toPascalCase(node.name);
  
  const code = `import React from 'react';
import styles from './${componentName}.module.css';

interface ${componentName}Props {
  className?: string;
}

export const ${componentName}: React.FC<${componentName}Props> = ({ className }) => {
  return (
    <div className={\`\${styles.root} \${className || ''}\`}>
      {/* ${node.name} */}
    </div>
  );
};`;

  return [
    {
      language: "TYPESCRIPT",
      code,
      title: `${componentName}.tsx`,
    },
  ];
}
```

### CodegenResult Interface

```typescript
interface CodegenResult {
  language: string;      // Syntax highlighting language
  code: string;          // Generated code string
  title: string;         // Tab title in the Inspect panel
}
```

Common language values for syntax highlighting: `"TYPESCRIPT"`, `"JAVASCRIPT"`, `"HTML"`, `"CSS"`, `"JSON"`, `"PLAINTEXT"`.

## Reading Preferences

```typescript
figma.codegen.on("generate", async (event) => {
  const prefs = figma.codegen.preferences;
  
  const stylingMethod = prefs.styling;   // "css-modules" | "styled-components" | "tailwind"
  const useTypeScript = prefs.typescript === "true";

  // Generate code based on user preferences
  return generateCode(event.node, { stylingMethod, useTypeScript });
});
```

## Extracting Node Properties for Code

### Layout Properties
```typescript
function extractLayout(node: SceneNode) {
  if (!('layoutMode' in node)) return null;
  
  return {
    direction: node.layoutMode,           // "HORIZONTAL" | "VERTICAL" | "NONE"
    gap: node.itemSpacing,
    padding: {
      top: node.paddingTop,
      right: node.paddingRight,
      bottom: node.paddingBottom,
      left: node.paddingLeft,
    },
    align: node.primaryAxisAlignItems,
    justify: node.counterAxisAlignItems,
  };
}
```

### Style Properties
```typescript
function extractStyles(node: SceneNode) {
  const styles: Record<string, any> = {};
  
  if ('fills' in node && Array.isArray(node.fills)) {
    const solidFill = node.fills.find((f: Paint) => f.type === 'SOLID' && f.visible !== false);
    if (solidFill && solidFill.type === 'SOLID') {
      styles.backgroundColor = rgbToHex(solidFill.color);
    }
  }
  
  if ('cornerRadius' in node && typeof node.cornerRadius === 'number') {
    styles.borderRadius = `${node.cornerRadius}px`;
  }
  
  if ('opacity' in node && node.opacity !== 1) {
    styles.opacity = node.opacity;
  }
  
  return styles;
}
```

## Performance Considerations

- **3-second timeout:** The `generate` callback must complete within 3 seconds or it will be terminated with an error
- Keep code generation logic simple and synchronous where possible
- Pre-compute mappings instead of doing heavy tree traversal during generation
- Cache reusable data between invocations when appropriate

## Helper Utilities

```typescript
function toPascalCase(str: string): string {
  return str
    .replace(/[^a-zA-Z0-9]/g, ' ')
    .split(' ')
    .filter(Boolean)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join('');
}

function rgbToHex(color: RGB): string {
  const r = Math.round(color.r * 255).toString(16).padStart(2, '0');
  const g = Math.round(color.g * 255).toString(16).padStart(2, '0');
  const b = Math.round(color.b * 255).toString(16).padStart(2, '0');
  return `#${r}${g}${b}`;
}

function rgbToCSS(color: RGB, opacity?: number): string {
  const r = Math.round(color.r * 255);
  const g = Math.round(color.g * 255);
  const b = Math.round(color.b * 255);
  if (opacity !== undefined && opacity < 1) {
    return `rgba(${r}, ${g}, ${b}, ${opacity.toFixed(2)})`;
  }
  return `rgb(${r}, ${g}, ${b})`;
}
```
