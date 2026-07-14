---
name: build-dashboard-theme
label: Build Dashboard Theme
description: |-
  Create, update, or apply a Holistics dashboard theme (library/themes/) from any input: a brand name, website, screenshot, brand guidelines, explicit colors, or a mood description.

  Use when the user wants to theme, brand, restyle, or change a dashboard's look and feel.

  Typical phrasings: build a theme, match our brand, use these colors, make it dark, make it warm/minimal/premium/editorial, glow up this dashboard.

  Do NOT trigger for building a dashboard, authoring block content, or adding controls.
---

Produce a dashboard theme and apply it.

## What a good input looks like
A theme task is fully specified when you can answer:
1. **Mode** — light or dark.
2. **Anchors** — a primary and secondary brand color.
3. **Surfaces** — page background character (pure neutral, warm cream, cool gray), and how blocks separate from it (border, flat, shadow).
4. **Typography** — body font; optionally a display font for titles; overall density (compact / comfortable / spacious).
5. **Personality** — corner rounding, how loud the accent colors are, what mood the whole thing projects.
6. **Target** — which dashboard(s) to apply it to.

## What a bare minimum output looks like
Every run delivers ALL of, regardless of prompt depth:
- a `const <slug>_theme_tokens` object with ALL 19 keys present (the single source of truth — no key is ever omitted; `font_display` = `font_body` when there's no display/body split),
- a complete `ColorPalette` (8 categorical colors — see Palette construction),
- a complete `PageTheme` covering page, canvas, block, table (general incl. `cell_padding` + `borders`, header, sub_header, sub_title, sparkline), and KPI surfaces plus `custom_css` for text blocks, reading every color through `<slug>_theme_tokens(...)` — every section is mandatory on every run,
- the theme actually applied to the target dashboard,
- clean diagnostics on every touched file.
Never deliver a palette without a PageTheme, an unapplied theme, or a dangling `theme:` reference to a file that wasn't written.

## Workflow
1. **Derive the design decisions** (fill the token set), in order:
   - **From the input** — given hex codes / named roles are locked anchors: convert to OKLCH, never adjust them aesthetically. A brand name → reason from its design language; a URL/screenshot → inspect it; mood words → translate ("minimal" = restrained chroma + hairline borders; "warm" = cream surfaces, H near 60-90; "premium/editorial" = display serif + spacious density).
   - **From the project** — check `library/themes/`; an existing theme may be the intended starting point (extend, don't duplicate).
   - **From defaults** — with no signal, build a clean professional light theme (near-white warm-neutral page, one restrained accent pair, comfortable density, hairline borders). Never reply that you need brand input to proceed.
   Ask at most one short round, and only when mode or a locked anchor is both unstated and unguessable AND the user clearly has a specific brand in mind; decide everything else.
2. **Write** `library/themes/<slug>.theme.aml` — the `const <slug>_theme_tokens`, then the `ColorPalette`, then the `PageTheme` (per Schema).
3. **Verify the file** — read it back: non-empty; tokens + palette + theme present; names slug-consistent; PageTheme colors are `<slug>_theme_tokens(...)` accessors (only hover/banding inline) and `custom_css` inlines the token values. Check code diagnostics and fix every error — an unknown-property/name error means invented vocabulary.
4. **Apply** — set `theme: <slug>_theme` on the target dashboard(s); check their diagnostics too.
5. **Deliver** — close with: slug, mode, the anchor colors used and where they came from (given vs assumed), files touched, warnings.

## Schema
A theme file has three parts in order — a `const <slug>_theme_tokens` object (the single source of truth for every design decision), a `ColorPalette`, and a `PageTheme` that reads the tokens through `<slug>_theme_tokens("key")` accessors. This is the complete vocabulary; nothing outside it exists.

    // 1. Design decisions — declare each once here, reference everywhere else
    const <slug>_theme_tokens = {
      primary: "oklch(L C H)",            // brand anchor — locked if the user gave a hex
      secondary: "oklch(L C H)",          // second brand color
      mode: "light|dark",
      background: "oklch(...)",           // page bg — light L 0.95-0.975 (near-white); dark L 0.25-0.30 (soft dark gray, NOT near-black — never below 0.24)
      canvas_bg: "oklch(...)",            // background.L +0.02 light / +0.03 dark
      block_bg: "oklch(...)",             // background.L +0.06 light / +0.07 dark — card surface (a touch brighter than the page)
      text_primary: "oklch(...)",         // L 0.20 light / 0.95 dark, near-neutral C
      text_muted: "oklch(...)",           // L 0.45 light / 0.70 dark
      text_subtle: "oklch(...)",          // L 0.60 light / 0.55 dark
      border: "oklch(...)",               // block_bg.L -0.10 light / +0.06 dark
      focus_ring: "oklch(...)",           // from primary hue, C 0.10-0.18
      semantic_success: "oklch(...)",
      semantic_warning: "oklch(...)",
      semantic_danger: "oklch(...)",
      font_body: "<body family>",         // font_family for body/table/KPI text; may fold in CSS fallbacks
      font_display: "<title family>",     // font_family for block titles; = font_body when there's no display/body split
      corner_style: "sharp|rounded|soft",
      density: "compact|comfortable|spacious",
      elevation: "hairline|flat|shadow"
    }

    // 2. Chart palette — 8 OKLCH literals (see Conventions → Palette)
    ColorPalette <slug>_palette {
      title: "<Human Name>"
      categorical {
        colors: [ <8 OKLCH literals> ]
      }
    }

    // 3. Theme — reads decisions via <slug>_theme_tokens("key"); only derived hover/banding are inline OKLCH
    PageTheme <slug>_theme {
      title: "<Human Name>"
      color { data: <slug>_palette }
      background { bg_color: <slug>_theme_tokens("background") }
      canvas {                                        // frame between page and blocks
        background { bg_color: <slug>_theme_tokens("canvas_bg") }
        border {
          border_width: 0
          border_radius: "..."                        // derived from corner_style: "sharp" -> 4 | "rounded" -> 12 | "soft" -> 20
          border_color: <slug>_theme_tokens("border")
          border_style: "none"                        // "none" | "solid"
        }
        shadow: "none"                                // "none" | "sm"
        opacity: 1
      }
      block {                                         // every dashboard block/card
        background { bg_color: <slug>_theme_tokens("block_bg") }
        border {
          border_width: "..."                         // derived from elevation: "hairline" -> 1 | "flat" -> 0 | "shadow" -> 0
          border_style: "..."                         // derived from elevation: "hairline" -> "solid" | "flat" -> "none" | "shadow" -> "none"
          border_radius: "..."                        // derived from corner_style: "sharp" -> 4 | "rounded" -> 12 | "soft" -> 20
          border_color: <slug>_theme_tokens("border")
        }
        shadow: "..."                                 // derived from elevation: "hairline" -> "none" | "flat" -> "none" | "shadow" -> "sm"
        padding: "..."                                // derived from density: "compact" -> 12 | "comfortable" -> 16 | "spacious" -> 20
        opacity: 1
        label {                                       // block titles
          font_family: <slug>_theme_tokens("font_display")
          font_size: "..."                            // derived from density: "compact" -> 13 | "comfortable" -> 14 | "spacious" -> 15
          font_color: <slug>_theme_tokens("text_primary")
          font_weight: "semibold"
          font_style: "normal"
          letter_spacing: "0"
        }
        text {                                        // block body text
          font_family: <slug>_theme_tokens("font_body")
          font_size: "..."                            // derived from density: "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
          font_color: <slug>_theme_tokens("text_muted")
          font_weight: "normal"
          font_style: "normal"
        }
      }
      viz {
        table {
          general {
            bg_color: <slug>_theme_tokens("block_bg")
            font_color: <slug>_theme_tokens("text_muted")
            font_family: <slug>_theme_tokens("font_body")
            font_size: "..."                          // derived from density: "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
            border_color: <slug>_theme_tokens("border")
            grid_color: <slug>_theme_tokens("border")
            border_width: 1
            hover_color: "oklch(...)"                 // derived inline: background.L +0.03 light / +0.05 dark
            banding_color: "oklch(...)"               // derived inline: background.L +0.015 light / +0.03 dark
            cell_padding: DetailedSpacing { top: "...", right: "...", bottom: "...", left: "..." }   // derived from density (top-bottom / left-right): "compact" -> 6/12 | "comfortable" -> 10/16 | "spacious" -> 14/20
            borders { outer: true, vertical: false, horizontal: true, header: true, row_header: false }
          }
          header {
            bg_color: <slug>_theme_tokens("background")       // header echoes the page bg
            font_color: <slug>_theme_tokens("text_primary")
            font_size: "..."                          // derived from density: "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
            font_weight: "semibold"
          }
          sub_header {
            bg_color: "oklch(...)"                    // same literal as banding_color
            font_color: <slug>_theme_tokens("text_muted")
            font_size: "..."                          // derived from density: "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
            font_weight: "medium"
          }
          sub_title {
            font_color: <slug>_theme_tokens("text_subtle")
            font_size: "..."                          // derived from density: "compact" -> 11 | "comfortable" -> 12 | "spacious" -> 13
            font_weight: "medium"
          }
          sparkline {                                   // in-cell mini charts — brand primary
            line { color: <slug>_theme_tokens("primary") }
            column { color: <slug>_theme_tokens("primary") }
          }
        }
        metric_kpi {
          alignment: "left|center|right"
          label {
            font_family: <slug>_theme_tokens("font_body")
            font_size: "..."                          // derived from density: "compact" -> 18 | "comfortable" -> 20 | "spacious" -> 22
            font_color: <slug>_theme_tokens("text_muted")
          }
          value {
            font_family: <slug>_theme_tokens("font_display")
            font_size: "..."                          // derived from density: "compact" -> 40 | "comfortable" -> 48 | "spacious" -> 56
            font_color: <slug>_theme_tokens("text_primary")
          }
          progress {
            indicator { bg_color: <slug>_theme_tokens("primary") }
            track { bg_color: <slug>_theme_tokens("border") }
          }
          trend {
            positive { text { font_color: <slug>_theme_tokens("semantic_success") font_weight: "medium" } }
            negative { text { font_color: <slug>_theme_tokens("semantic_danger") font_weight: "medium" } }
            neutral { text { font_color: <slug>_theme_tokens("text_muted") font_weight: "normal" } }
          }
        }
      }
      // custom_css — inline each token's literal value (copy from the const; NOT the accessor). The .dac-text-block rules are FIXED (emit verbatim, always). The three commented selectors after them are the ONLY targets experimental mode may decorate; leave them commented (omit) in default mode. No selector outside this block may ever be styled.
      custom_css: @css
        .dac-text-block {
          font-family: <font_body>;
          font-size: 14px;
          color: <text_muted>;
          line-height: 1.6;
        }
        .dac-text-block h1,
        .dac-text-block h2,
        .dac-text-block h3,
        .dac-text-block h4,
        .dac-text-block h5,
        .dac-text-block h6 {
          font-family: <font_display>;
          color: <text_primary>;
          line-height: 1.3;
          margin-top: 0;
          margin-bottom: 0.5em;
          font-weight: 600;
        }
        /* experimental mode ONLY (see Conventions → Custom CSS): decorative, token-derived CSS may go inside these three — properties are open, but leave them commented (omit) in default mode. These are the ONLY selectors decoration may ever target. */
        /* .dac-canvas      { … } */
        /* .dac-block       { … } */
        /* .dac-block-label { … } */
      ;;
    }

## Conventions

### Palette
Fill the 8 categorical `colors: []` — identity by hue. Categorical color encodes *which series*, so every series must be told apart by everyone, colorblind viewers included: distinguish by **hue**, holding lightness and chroma nearly constant so no series dominates and none reads gray. (Do NOT use lightness for "distinctness" or chroma for "hierarchy" — that's the sequential job and it breaks categorical: muted slots read gray, spread-lightness slots leave the band.) Build the 8 slots in order:
1. **Spread 8 hues.** Slot 1 = `primary` (brand identity). Slots 2-8 = seven more hues ~45° apart around the wheel, in a fixed order, seeded so `secondary` lands on a slot. Bias toward the brand's temperature if you like, but keep every neighbour ≥ ~40° apart — never cluster around one or two anchors, and no near-neutral "bridge" slot (it reads gray and wastes a series).
2. **Hold the band.** All 8 at OKLCH C ≥ 0.12 (never < 0.10) and L in a tight sub-band — light ~0.60-0.66, dark ~0.55-0.63. Lock a given anchor's *hue*; pull its L/C into the band.
3. **Nudge only for colorblind separation.** Two hue pairs collapse under CVD even when spread: **blue↔purple** (protanopia) and **adjacent warm↔warm** (deuteranopia). For those, push one slot's *lightness* ±0.05-0.10 (hold its hue) until they separate; and pull yellow/amber down to L ≤ 0.75 to stay under the light cap. This is the only reason to break constant lightness.
4. **Targets to construct against** (the Copilot can't run a validator, so build to these): worst-pair CVD ΔE **≥ 12** under protanopia + deuteranopia (ΔE ≥ 8 is the hard floor — legal only because the dashboard legend supplies secondary encoding), C ≥ 0.10, L in band, ≥ 3:1 vs `block_bg`.

Derive a fresh palette every time — run these same four steps for both light and dark mode (dark just uses the tighter band from step 2, built against the dark surface).

### Modes
- The default is **conservative**: strictly follow the Schema and Conventions, invent no new properties, and emit deterministically (single-source tokens, verbatim `custom_css`, solid surfaces). This runs unless the user asks otherwise.
- **Experimental mode** applies only when the user explicitly asks for a creative / experimental / expressive theme. It relaxes exactly one thing — you may add decorative `custom_css` (gradients, glows, subtle effects, all built from token colors) on the frame surfaces only (which selectors: see Custom CSS). Everything else stays conservative (closed vocabulary, single-source tokens). Decorate the frame, not the data; content stays legible.

### Custom CSS
- **Verbatim block (conservative, always).** Emit the `custom_css` block exactly as shown in the Schema tree — it styles `.dac-text-block` (+ its `h1`–`h6`), the only surface PageTheme's structured properties don't reach. Every selector and property is fixed and closes with `;;` on its own line; only the inlined token *values* vary (never the accessor). Never add, drop, reorder, or restyle a rule.
- **Decoration targets (experimental only).** The Schema's `custom_css` block shows the three decoration selectors as commented placeholders — `.dac-canvas`, `.dac-block`, `.dac-block-label`. In experimental mode, uncomment and fill them with decorative CSS: **properties are open** (gradients, glows, shadows, …) as long as they build from token colors and decorate the frame, not the data. These three are the ONLY selectors decoration may target; the data/content surfaces `.dac-viz-block`, `.dac-text-block`, and `.dac-ic-block` are never styled decoratively. (Styling `.dac-text-block` through the verbatim rules above is the conservative baseline, not decoration.)
- **Font `@import`.** Prepend one `@import url(...)` line above the first rule ONLY when `font_body` or `font_display` names a font Holistics doesn't bundle (bundled, no import: Inter, Arial, Verdana, Tahoma, Trebuchet MS, Times New Roman, Georgia, Garamond, Courier New).

### Others
- **One source of truth.** Declare every color and font once in `const <slug>_theme_tokens`; the PageTheme reads them via `<slug>_theme_tokens("key")`. Only exceptions: the derived `hover_color` / `banding_color` (and `sub_header.bg_color`, which equals banding) have no token; and `custom_css` inlines each token's *value* (CSS can't call the accessor).
- **Colors & fonts.** Colors are `"oklch(L C H)"` (L 0-1, C 0-0.4, H 0-360); convert user hex to OKLCH. `font_family` reads `font_body` (body/table/KPI) or `font_display` (titles) via the accessor; fold any CSS fallbacks into the token value itself.
- **Enums resolve to fixed values.** Each enum token holds only its options (e.g. `"sharp|rounded|soft"`); the per-option mapping lives inline on each derived property in the Schema tree — `corner_style`→`border_radius`, `elevation`→border + block shadow, `density`→`padding` / `cell_padding` / every `font_size`.
- **Vocabulary is closed.** Use only the properties, token keys, and `custom_css` selectors the Schema shows: never style a selector the Schema doesn't list, and never add a property it doesn't show — the three experimental `custom_css` blocks are the sole place properties are open (see Custom CSS). If you think you need another name, confirm with search_docs first — never guess.
- **File.** Write `library/themes/<slug>.theme.aml`; the dashboard references it with `theme: <slug>_theme`.
