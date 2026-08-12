---
name: build-dashboard-theme
label: Build Dashboard Theme
description: |-
  Create, update, or apply a Holistics dashboard theme (.holistics/library/themes/) from any input: a brand name, website, screenshot, brand guidelines, explicit colors, or a mood description.

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
Every run delivers ALL of, regardless of prompt depth. These are *structural* invariants — which pieces appear; the *values* inside are yours to derive (see Conventions → Design principles), not fixed by this skill.
- a `const <slug>_theme_tokens` object — the single source of truth; declare every repeated color / font / design decision once. The Schema lists a recommended baseline token set; it is extensible (add a token when the design needs one, e.g. a page gradient or a second accent), not a fixed key count.
- a complete `ColorPalette` (8 categorical colors — see Palette construction).
- a complete `PageTheme` that reads tokens through `<slug>_theme_tokens("key")` accessors and emits EVERY section: `color`, `background`, `canvas`, `block`, `viz.table` (general, header, sub_header, sub_title, sparkline), `viz.metric_kpi` (alignment, label, value, progress, trend — trend including its `background`), and `custom_css`.
- the theme actually applied to the target dashboard.
- clean diagnostics on every touched file.
Never deliver a palette without a PageTheme, an unapplied theme, or a dangling `theme:` reference to a file that wasn't written.

## Workflow
1. **Derive the design decisions** (fill the token set), in order:
   - **From the input** — given hex codes / named roles are locked anchors: convert to OKLCH, never adjust them aesthetically. A brand name → reason from its design language; a URL/screenshot → inspect it; mood words → translate ("minimal" = restrained chroma + hairline borders; "warm" = cream surfaces, H near 60-90; "premium/editorial" = display serif + spacious density).
   - **From the project** — check `.holistics/library/themes/`; an existing theme may be the intended starting point (extend, don't duplicate).
   - **From defaults** — with no signal, build a clean professional light theme (near-white warm-neutral page, one restrained accent pair, comfortable density, hairline borders). Never reply that you need brand input to proceed.
   Ask at most one short round, and only when mode or a locked anchor is both unstated and unguessable AND the user clearly has a specific brand in mind; decide everything else.
2. **Write** `.holistics/library/themes/<slug>.theme.aml` — the `const <slug>_theme_tokens`, then the `ColorPalette`, then the `PageTheme`. Use the Schema's property surface for the exact property names, and derive every value (surfaces, type sizes, padding, elevation) from Conventions → Design principles — the Schema no longer dictates values.
3. **Verify the file** — read it back: non-empty; tokens + palette + theme present; names slug-consistent; PageTheme colors are `<slug>_theme_tokens(...)` accessors (only hover/banding inline) and `custom_css` inlines the token values. Check code diagnostics and fix every error — an unknown-property/name error means invented vocabulary.
4. **Apply** — set `theme: <slug>_theme` on the target dashboard(s); check their diagnostics too.
5. **Deliver** — close with: slug, mode, the anchor colors used and where they came from (given vs assumed), files touched, warnings.

## Schema
A theme file has three parts in order — a `const <slug>_theme_tokens` object (the single source of truth for every design decision), a `ColorPalette`, and a `PageTheme` that reads the tokens through `<slug>_theme_tokens("key")` accessors. Follow the concrete shape below — it is the complete vocabulary and the exact forms that compile; fill each `"..."` slot with a value derived per Conventions → Design principles. The `const {…}` object and its `<slug>_theme_tokens("key")` accessor are valid AML; there is no `.key` or `["key"]` form.

    // 1. Design tokens — the single source of truth. Declare each decision once; reference it everywhere.
    //    Recommended baseline below; extend when a design needs it (e.g. add page_gradient, accent_2).
    //    Values (the oklch literals) are yours to derive — see Conventions → Design principles.
    const <slug>_theme_tokens = {
      primary: "oklch(...)",  secondary: "oklch(...)",  mode: "light|dark",              // brand anchors (locked if the user gave a hex)
      background: "oklch(...)",  canvas_bg: "oklch(...)",  block_bg: "oklch(...)",        // page -> canvas -> card, stepping up in lightness
      text_primary: "oklch(...)",  text_muted: "oklch(...)",  text_subtle: "oklch(...)",  // descending contrast
      border: "oklch(...)",  focus_ring: "oklch(...)",
      semantic_success: "oklch(...)",  semantic_warning: "oklch(...)",  semantic_danger: "oklch(...)",
      font_body: "<body family>",  font_display: "<title family>",   // font_display = font_body when there's no display/body split; fold CSS fallbacks into the value
      corner_style: "sharp|rounded|soft",  density: "compact|comfortable|spacious",  elevation: "hairline|flat|shadow"
    }

    // 2. Chart palette — 8 OKLCH literals (see Conventions → Palette)
    ColorPalette <slug>_palette {
      title: "<Human Name>"
      categorical {
        colors: [ <8 OKLCH literals> ]
      }
    }

    // 3. Theme — reads tokens via <slug>_theme_tokens("key"); fill each "..." with a value derived per Conventions → Design principles. Only the derived hover/banding tints are inline oklch (no token).
    PageTheme <slug>_theme {
      title: "<Human Name>"
      color { data: <slug>_palette }                // a ColorPalette IDENTIFIER (bare name), never an accessor or string
      background { bg_color: <slug>_theme_tokens("background") }   // experimental: bg_image: "linear-gradient(...)" instead, for a page gradient (see Modes)
      canvas {                                        // frame between page and blocks
        background { bg_color: <slug>_theme_tokens("canvas_bg") }  // may take bg_image instead (experimental gradient)
        border {
          border_width: 0
          border_radius: "..."                        // derived from corner_style: "sharp" -> 4 | "rounded" -> 12 | "soft" -> 20
          border_color: <slug>_theme_tokens("border")
          border_style: "none"                        // "none" | "solid"
        }
        shadow: "none"                                // "none" | "sm" | "md" | "lg"
        opacity: 1
      }
      block {                                         // every dashboard block/card
        background { bg_color: <slug>_theme_tokens("block_bg") }   // may take bg_image instead (experimental gradient)
        border {
          border_width: "..."                         // derived from elevation: "hairline" -> 1 | "flat" -> 0 | "shadow" -> 0
          border_style: "..."                         // derived from elevation: "hairline" -> "solid" | "flat" -> "none" | "shadow" -> "none"
          border_radius: "..."                        // derived from corner_style: "sharp" -> 4 | "rounded" -> 12 | "soft" -> 20
          border_color: <slug>_theme_tokens("border")
        }
        shadow: "..."                                 // derived from elevation: "hairline" -> "none" | "flat" -> "none" | "shadow" -> "sm"  (md/lg for more depth)
        padding: "..."                                // derived from density: "compact" -> 12 | "comfortable" -> 16 | "spacious" -> 20   (a number = all sides; or DetailedSpacing { top:.. right:.. bottom:.. left:.. } per-side — keep the keyword)
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
          alignment: "left"                            // "left" | "center" | "right"
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
            text { font_color: <slug>_theme_tokens("text_muted") }   // progress caption
          }
          trend {                                                    // each badge background = a faint wash of its trend hue — derived inline, no token (light: high L ~0.92, low C; dark: low L ~0.40, low C)
            positive { text { font_color: <slug>_theme_tokens("semantic_success") font_weight: "medium" }  background { bg_color: "oklch(...)" } }
            negative { text { font_color: <slug>_theme_tokens("semantic_danger") font_weight: "medium" }  background { bg_color: "oklch(...)" } }
            neutral  { text { font_color: <slug>_theme_tokens("text_muted") font_weight: "normal" }  background { bg_color: "oklch(...)" } }
          }
        }
      }
      // custom_css — the FIXED verbatim block below, always emitted as-is. It styles .dac-text-block (+ h1-h6), the one surface PageTheme's structured properties don't reach. Inline each token's literal value (copy from the const; NOT the accessor). Never add any other selector or rule — this is the whole custom_css.
      custom_css: @css
        .dac-text-block {
          font-family: <font_body>;
          font-size: 14px;
          color: <text_muted>;
          line-height: 1.6;
        }
        .dac-text-block h1, .dac-text-block h2, .dac-text-block h3, .dac-text-block h4, .dac-text-block h5, .dac-text-block h6 {
          font-family: <font_display>;
          color: <text_primary>;
          line-height: 1.3;
          margin-top: 0;
          margin-bottom: 0.5em;
          font-weight: 600;
        }
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

### Design principles
The Schema's tree carries sensible defaults (the `// derived from ...` comments) — treat them as a coherent starting point, not a mandate. Pick the actual numbers with judgment and keep them consistent across the whole theme.
- **Surfaces step up in lightness** page → canvas → block, so cards read as raised above the page. Light mode: near-white page (L ~0.95-0.975), each surface a touch brighter. Dark mode: soft dark-gray page (L ~0.25-0.30, never near-black), each surface a touch brighter. Text tiers descend in contrast: `text_primary` (strongest) → `text_muted` → `text_subtle`; `border` sits just off the block surface; the two derived table tints (`hover_color`, `banding_color`) are a hair above the surface.
- **One type scale.** Set a body size and a consistent step, and sit every text slot on it — block title ≥ body, table text ≈ body, sub-title < body, KPI value much larger, KPI label small. Bigger where emphasis belongs, smaller for secondary text; don't pick sizes ad hoc.
- **Density is one coherent choice.** `compact` / `comfortable` / `spacious` moves block `padding`, table `cell_padding`, and every `font_size` *together* — tighter density means smaller padding and slightly smaller type; spacious the reverse. Never pair tight padding with loose type.
- **Elevation & corners** from the enum tokens: `elevation` → `hairline` = 1px border + no shadow · `flat` = no border + no shadow · `shadow` = no border + a soft shadow (`sm`, or `md`/`lg` for more depth). `corner_style` → `sharp` ≈ small radius · `rounded` ≈ medium · `soft` ≈ large, applied consistently to canvas and block.

### Modes
- **Conservative (default).** Solid surfaces; restrained palette; `custom_css` is the verbatim `.dac-text-block` block only. Runs unless the user asks otherwise.
- **Experimental (opt-in).** Only when the user explicitly asks for a creative / experimental / expressive theme — and only through **native properties**, never raw CSS decoration. Reach for `bg_image` gradients/imagery on `background` / `canvas.background` / `block.background` (`"linear-gradient(...)"` built from token colors, which the renderer themes and resizes for you), bolder palette chroma, and `md` / `lg` shadows for depth. `custom_css` still stays the verbatim block. Push the look on the frame surfaces (page, canvas, cards); keep the data legible.

### Custom CSS
`custom_css` is the single verbatim block, the same in every theme — nothing else ever goes in it.
- **Verbatim block (always).** Emit exactly the `.dac-text-block` (+ `h1`–`h6`) block the Schema shows — that text surface is the one PageTheme's structured properties don't reach. Only the inlined token *values* vary (copy them from the const, never the accessor); the block closes with `;;` on its own line. Never add, drop, reorder, or restyle a rule, and never introduce another selector — `custom_css` is injected unsanitized and `!important`, so a stray rule would silently override the structured theme.
- **Font `@import`.** Prepend one `@import url(...)` line above the first rule ONLY when `font_body` or `font_display` names a font Holistics doesn't bundle (bundled, no import: Inter, Arial, Verdana, Tahoma, Trebuchet MS, Times New Roman, Georgia, Garamond, Courier New).

### Others
- **One source of truth.** Declare every color and font once in `const <slug>_theme_tokens`; the PageTheme reads them via `<slug>_theme_tokens("key")`. Only exceptions: the derived `hover_color` / `banding_color` (and `sub_header.bg_color`, which equals banding) have no token; and `custom_css` inlines each token's *value* (CSS can't call the accessor).
- **Colors & fonts.** Colors are `"oklch(L C H)"` (L 0-1, C 0-0.4, H 0-360); convert user hex to OKLCH. `font_family` reads `font_body` (body/table/KPI) or `font_display` (titles) via the accessor; fold any CSS fallbacks into the token value itself.
- **Filters/controls have no theme section** — they auto-derive from `block.background` / `block.text` / `block.border`, so keep those block colors legible against each other. And `viz` themes only `table` + `metric_kpi`; there is no `bar`/`line`/`pie` viz theming to add.
- **Vocabulary is closed.** Use only the properties, token keys, and the one `custom_css` block the Schema shows — never style a selector it doesn't list, never add a property it doesn't show. Unsure of a name? `search_docs` it — never guess.
- **File.** Write `.holistics/library/themes/<slug>.theme.aml`; the dashboard references it with `theme: <slug>_theme`.
