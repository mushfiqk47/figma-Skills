# FIGMA IN PI — fresh-install bootstrap. Paste this whole file to a new Pi and it sets up everything.

> You are Pi, session_mode=implement. Follow context-mode hierarchy strictly:
> ctx_batch_execute > ctx_execute > ctx_execute_file > ctx_search.
> Read/edit files → ctx_execute_file. Multi-command → ctx_batch_execute.
> Web pages → ctx_fetch_and_index then ctx_search. Index docs → ctx_index.
> Be concise. Show file paths clearly.

## STEP 1 — verify + install (ctx_execute, single commands)

```js
// 1a. check claude CLI exists
const {execSync}=require('child_process');
console.log(execSync('claude --version 2>&1',{encoding:'utf8',timeout:15000}));
```

```js
// 1b. install figma plugin (idempotent)
const {execSync}=require('child_process');
console.log(execSync('claude plugin install figma@claude-plugins-official 2>&1',{encoding:'utf8',timeout:60000}));
```

```js
// 1c. verify enabled + OAuth connected (expect figma enabled + https://mcp.figma.com/mcp Connected, NO api key)
const {execSync}=require('child_process');
console.log(execSync('claude plugin list 2>&1',{encoding:'utf8',timeout:20000}));
console.log(execSync('claude mcp list 2>&1',{encoding:'utf8',timeout:20000}));
```

Auth = OAuth only. Never ask for FIGMA_API_KEY. If MCP shows unauthenticated, tell user: in Claude Code run `/mcp` > figma > Authenticate > Allow Access.

## STEP 2 — recreate wrapper (default.write these files)

Base: `C:/Users/MUSHFIQ/figma-native-editor/`

1. `.claude-plugin/plugin.json`
```json
{
  "name": "figma-native-editor",
  "displayName": "Figma Native Editor",
  "description": "Install figma@claude-plugins-official with one step, then create/edit Figma natively via chat - layers, variables, code and assets.",
  "version": "1.0.0",
  "author": { "name": "MUSHFIQ" },
  "license": "Apache-2.0",
  "commands": ["./commands/figma-inspect.md", "./commands/figma-code.md", "./commands/figma-tokens.md", "./commands/figma-assets.md"],
  "skills": ["./skills/figma-native/SKILL.md"],
  "agents": ["./agents/figma-editor.md"]
}
```

2. `.mcp.json` (OAuth remote, no api key)
```json
{
  "mcpServers": { "figma": { "url": "https://mcp.figma.com/mcp", "type": "http" } },
  "notes": "OAuth only - no API key. /mcp -> figma -> Authenticate -> Allow Access."
}
```

3. `commands/figma-inspect.md` — inspect pages/frames via use_figma reads, return node IDs.
4. `commands/figma-code.md` — map auto-layout/fills/text to code, convert 0-1 colors to hex.
5. `commands/figma-tokens.md` — variables with explicit scopes, never ALL_SCOPES.
6. `commands/figma-assets.md` — exportAsync PNG/SVG/PDF, max 10 nodes per call.
7. `skills/figma-native/SKILL.md` — canonical recipes (see STEP 4 rules).
8. `agents/figma-editor.md` — inspect-first, max 10 ops/call, return IDs, screenshot verify.
9. `README.md` + `install.bat`/`install.sh` — `/plugin install figma@claude-plugins-official`.

## STEP 3 — Figma bridge (Pi cannot reach Figma directly: JS login wall, no Figma MCP in Pi gateway. Claude CLI owns the OAuth session. ALL Figma reads/writes go through it via ctx_execute)

Inspect (structure):
```js
const {execSync}=require('child_process');
const prompt='Using your Figma MCP tools, inspect this Figma file and return: file name, pages, top-level frames on current page with names and sizes. URL: <PASTE-URL>';
console.log(execSync('claude -p --allow-dangerously-skip-permissions',{encoding:'utf8',timeout:120000,maxBuffer:1024*1024,input:prompt}).slice(0,4000));
```

Deep-dive (children/fills/text):
```js
const {execSync}=require('child_process');
const prompt='Using your Figma MCP tools on file <KEY> page <PAGE-ID>: for frames <IDS> return full child tree (type,name,x,y,w,h,characters for TEXT,fills) + screenshot description. Under 1500 chars.';
console.log(execSync('claude -p --allow-dangerously-skip-permissions',{encoding:'utf8',timeout:120000,maxBuffer:1024*1024,input:prompt}).slice(0,4000));
```

Create (example red primary button):
```js
const {execSync}=require('child_process');
const prompt='Using Figma MCP write tools on file <KEY> page <PAGE>: inside frame <FRAME> (<W>x<H> white), create ONE primary button: auto-layout HORIZONTAL named Primary Button, red #D92626, radius 8, padding 12v/20h, gap 8, TEXT Get Started Inter Medium 14 white (load font first). Center in frame. Screenshot verify. Return node IDs + x,y,w,h.';
console.log(execSync('claude -p --allow-dangerously-skip-permissions',{encoding:'utf8',timeout:180000,maxBuffer:1024*1024,input:prompt}).slice(0,3500));
```

Tokens + bind (everything):
```js
const {execSync}=require('child_process');
const prompt='Using Figma MCP write tools on file <KEY> page <PAGE>: create collection <NAME> (mode Default), explicit scopes never ALL_SCOPES: color/primary COLOR <HEX> [FRAME_FILL,SHAPE_FILL] bind button fills; color/on-primary white [TEXT_FILL] bind text; color/surface white [FRAME_FILL] bind frame; radius/md 8 [CORNER_RADIUS]; spacing/gap-sm 8 [GAP]; padding/v-md 12 + padding/h-lg 20 [GAP - Figma has no padding scope]; font/family + font/size [FONT_FAMILY]/[FONT_SIZE] (listAvailableFontsAsync first). Return collection + variable IDs, confirm var(--...) bindings.';
console.log(execSync('claude -p --allow-dangerously-skip-permissions',{encoding:'utf8',timeout:180000,maxBuffer:1024*1024,input:prompt}).slice(0,4000));
```

## STEP 4 — native-edit rules (every write)

- Max 10 logical ops per call. Placeholders while building (`placeholder=true`), remove when done. Screenshot after each milestone.
- Text: getStyledTextSegments(["fontName"]) → loadFontAsync → await → mutate → return IDs. Verify names via listAvailableFontsAsync (Inter is preloaded, others are not).
- Colors 0-1 only. Fills/strokes clone-modify-reassign. Opacity at paint level.
- Containers: createAutoLayout() for related children. appendChild FIRST, then HUG/FILL. FIXED always works. Never cross layoutSizing (child: FIXED|HUG|FILL) with axis sizing (frame: FIXED|AUTO).
- Pages: context resets each call. setCurrentPageAsync max once per call. Multi-page = one call per page, fanned in parallel. Sync setter does NOT work.
- Never figma.notify / closePlugin / async-IIFE. Always return { createdNodeIds, mutatedNodeIds } + variable/collection IDs.
- use_figma is atomic: on error STOP, read message, fix, retry. Visual miss = targeted fix, never recreate everything.

## STEP 5 — verify + hand over

Run `claude plugin list` + `claude mcp list`, confirm wrapper files exist, then reply: plugin version + enabled, MCP Connected via OAuth, wrapper path, file key/pages/frames of user URL, what was created + IDs, tokens + bindings. Ask what to build next.

## Known session values (my file, reuse as example)

- URL: https://www.figma.com/design/3Let3XxYK6xGBPlEIFRSyc/Linkdin-agent?node-id=66-2
- Key 3Let3XxYK6xGBPlEIFRSyc, Page 4 (66:2), Frame 1 (67:3) 256x233, Frame 2 (67:4) 13x127.
- Button 71:2 + text 71:3 centered. Collection 75:2, vars 75:4–75:12 all bound.
