# Skill 1: Design Tokens — Token & Foundation Creation

**Trigger:** building a token system from scratch, or a file has no/partial variable
collections yet (colors, type scale, spacing, radius, elevation).

**Role:** design-systems token architect. Deliverable is real, bound Figma variables —
not a spec doc, not code.

## Sequence
1. **Understand** — product type, brand personality, existing brand colors/fonts if any.
2. **Propose, then wait for approval** — before creating anything:
   - 1 primary color family + 1 neutral family + 1–3 status families (success/warning/
     error/info). Source from tailwindcolor.com / Tailwind v4 (verify current values via
     web search — palettes drift). Or use a named system (Radix, Open Color, Material 3,
     Apple HIG) if the user specifies one; verify it's current.
   - Typography: use exact fonts if given (verify loadable via
     `figma.listAvailableFontsAsync()`); otherwise propose 2–3 options by project type and
     wait for a pick.
3. **Build, in this order** (see agent.md §4 for full mechanics):
   - Primitives (color, then spacing/radius/size numbers) — hidden from publishing.
   - Semantic aliases, Light + Dark modes set up from the start.
   - Text styles + effect styles (shadows/elevation).
   - Screenshot + validate after each phase.

## Non-negotiables
- Three tiers only: Primitive → Semantic → Component-specific (only if variant
  complexity truly demands it). Semantic aliases primitives, never other semantics.
- 80/20 rule: neutrals cover ~80% of the UI; saturated accent reserved for the ~20%
  that needs attention.
- WCAG AA contrast checked at the moment a pairing is defined, not as a later pass.
- Every variable gets an explicit `scopes` value — never leave `ALL_SCOPES`.
- Slash naming (`color/text/primary`, `space/4`, `radius/lg`).
- Never silently substitute a font, color, or value that fails/is unavailable — report
  and ask.

## Reference scales (defaults if nothing else is specified)
- **Type:** 1.25× ratio scale, `display → heading-xl/lg/md/sm → body-lg/body/body-sm →
  caption/overline`. Weight: regular/medium/semibold/bold only. Line-height: tight 1.2 /
  normal 1.5 / relaxed 1.75. Note: percentage line-height and text-case aren't
  variable-bindable in Figma — use text styles for those.
- **Spacing:** 4px base (`space/0` through `space/24`+).
- **Radius:** none/sm/md/lg/xl/2xl/full.
- **Border:** thin/default/thick.
- **Opacity:** disabled/hover/pressed/overlay.

## Output
A validated variable/token layer only. No components, no copy — those are Skills 2 and 3.
