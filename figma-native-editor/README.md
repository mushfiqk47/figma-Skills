# Figma Native Editor

Use Figma natively from chat. OAuth only, no API key. Install once, paste a file URL, and edit perfectly.

## Install

```bash
/plugin install figma@claude-plugins-official
```

Verify:

```bash
claude plugin list   # figma@claude-plugins-official, enabled
claude mcp list      # https://mcp.figma.com/mcp, Connected
```

Auth is OAuth via the remote MCP server. If it ever asks, run `/mcp` in Claude Code, select `figma`, then Authenticate and Allow Access. There is no token to copy and nothing secret to set.

To use this local wrapper as well:

```bash
/plugin install ./figma-native-editor
```

## How it works

Pi cannot reach Figma directly (login wall, no Figma MCP in its gateway). All Figma reads and writes go through the Claude CLI, which owns the OAuth session:

```bash
echo '<instruction> + file URL' | claude -p --allow-dangerously-skip-permissions
```

## Use it

1. Copy any `figma.com/design/...` URL.
2. Paste it in chat and say what you want:
   - `inspect this` — pages, frames, sizes
   - `create a primary button, red` — native auto-layout button
   - `create variables and bind everything` — tokens for color, font, padding, radius, spacing
   - `export this frame as code` — dev-ready code
   - `build my full token system` — runs `/figma-vars-create`: 50-950 ramps, Light + Dark, contrast-checked
   - `connect tokens to this frame` — runs `/figma-vars-connect`: every property bound, design unchanged
   - `audit everything` — runs `/figma-audit`: scored report with fix list
3. Every edit returns node IDs so the next step can build on it.

Commands in `commands/`: `figma-inspect`, `figma-code`, `figma-tokens`, `figma-assets`, plus the token pipeline: `figma-vars-create` (full system), `figma-vars-connect` (bind all), `figma-audit` (scored report).
Skill in `skills/figma-native/SKILL.md`. Agent in `agents/figma-editor.md`.

## Edit rules (built in)

- Max 10 operations per write, screenshot after each milestone.
- Text: load current fonts, await, mutate, return IDs.
- Colors 0-1, fills clone-modify-reassign, append before HUG/FILL.
- Variables always get explicit scopes, never ALL_SCOPES.
- Failed scripts change nothing — read the error, fix, retry.

## Worked example (Linkdin-agent file)

- File key `3Let3XxYK6xGBPlEIFRSyc`, Page 4 (`66:2`).
- Frame 1 (`67:3`) 256x233 — red primary button `71:2` + label `71:3`, centered.
- Collection `Linkdin-agent tokens` (`75:2`), variables `75:4`–`75:12`: primary red, on-primary white, surface, radius 8, gap 8, padding 12/20, Inter 14 — all bound, every property shows `var(--...)`.

## Fresh Pi setup

Paste `FIGMA-PI-SETUP.md` (on Desktop) into a new Pi session. It reinstalls the plugin, verifies OAuth, recreates this wrapper, and resumes editing from any Figma URL.

## Structure

```
.claude-plugin/plugin.json
.mcp.json                        # remote OAuth, no api key
commands/figma-inspect.md, figma-code.md, figma-tokens.md, figma-assets.md
skills/figma-native/SKILL.md
agents/figma-editor.md
install.bat, install.sh
```
