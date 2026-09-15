---
name: build-dashboard-theme
label: Build Dashboard Theme
description: |-
  Create, update, or apply a Holistics dashboard theme (.holistics/library/themes/) from any input: a brand name, website, screenshot, brand guidelines, explicit colors, or a mood description.

  Use when the user wants to theme, brand, restyle, or change a dashboard's look and feel.

  Typical phrasings: build a theme, match our brand, use these colors, make it dark, make it warm/minimal/premium/editorial, glow up this dashboard.

  Do NOT trigger for building a dashboard, authoring block content, or adding controls.
---

Generate and apply a Holistics dashboard theme.

A theme controls a dashboard's entire visual surface: page and canvas backgrounds, block cards, typography, tables, KPIs, and chart palettes. Themes live as `PageTheme` definitions in `.holistics/library/themes/` and are applied via a dashboard's `theme:` property.

Because users view Holistics in either light or dark app modes, themes are built in one of two configurations:

* **Dynamic (Default):** A paired `PageTheme` for both light and dark modes. The dashboard automatically displays the mode matching the viewer's app preference. **Always build dynamic themes by default.**
* **Static:** A single `PageTheme` forced on all viewers. *Only build static if explicitly requested.* It creates jarring contrast for users in the opposite mode. Convert existing static themes to dynamic rather than maintaining them.

## What a good input looks like

A complete theme specification requires these six decisions:

1. **Mode:** The leading design direction (`light` or `dark`).
2. **Anchors:** Primary and secondary brand colors.
3. **Surfaces:** Page background tone (neutral, warm cream, cool gray) and separation style (bordered, flat, shadowed).
4. **Typography:** Primary body font, optional display font, and overall density (`compact`, `comfortable`, `spacious`).
5. **Personality:** Corner radius (`sharp`, `rounded`, `soft`), accent saturation, and visual mood.
6. **Target:** The specific dashboard(s) receiving the theme.

## What a bare minimum output looks like

Every execution must deliver these structural artifacts. (Internal values are dynamically derived, but this structure is invariant).

**Shared (Once per theme):**

* **Brand Tokens:** A single `const <slug>_brand` object. Shared decisions (brand anchors, fonts, corner style, density, elevation) use unsuffixed keys to keep the design cohesive across modes. Lighting-dependent decisions (surfaces, text tiers, borders, semantic colors) use `_light` and `_dark` pairs.

**Per Mode (For `light` and `dark` in dynamic themes, or the single mode in static):**

* **Chart Palette:** A `ColorPalette` with 8 categorical colors optimized against that mode's background.
* **Page Theme:** A complete `PageTheme` reading shared keys via `<slug>_brand("key")` and mode keys via `<slug>_brand("key_<mode>")`. Must define all sections: `color`, `background`, `canvas`, `block`, `viz.table` (general, header, sub_header, sub_title, sparkline), `viz.metric_kpi` (alignment, label, value, progress, trend with trend background), and `custom_css`.

**Actions:**

* **Apply:** Attach the theme to the target dashboard(s).
* **Validate:** Ensure clean diagnostics on all modified files.

*Never deliver incomplete outputs, unapplied themes, missing mode pairings, or dangling references.*

## Workflow

1. **Derive Design Decisions:** Populate the token set in this order:
   * **From Input:** Convert locked hex codes or explicit roles to visually exact OKLCH. Interpret brand names/URLs into design languages. Map mood terms to rules (e.g., "minimal" = subtle chroma + hairline borders; "warm" = cream backgrounds, hue 60–90; "premium/editorial" = display serif + spacious layout).
   * **From Project Context:** Inspect `.holistics/library/themes/`. Extend existing themes instead of duplicating them. If an existing theme is static, convert it to dynamic by deriving the missing counterpart mode.
   * **From Smart Defaults:** If inputs are empty, lead with `light` mode and generate a clean, professional theme (near-white warm-neutral page, restrained accents, comfortable density, hairline borders). **Never halt execution to ask for missing brand details.**
   * **Derivation Order:** Derive the leading mode first. Then adapt the second mode using identical anchors, typography, and personality, re-lit against the new mode's background. *Only ask a clarifying question if a specific brand is explicitly requested but its anchors are completely unstated and unguessable.*
2. **Write Theme File:** Generate `.holistics/library/themes/<slug>.theme.aml` in this exact sequence: `<slug>_brand`, `<slug>_light_palette`, `<slug>_light_theme`, `<slug>_dark_palette`, `<slug>_dark_theme`.
3. **Validate File Integrity:** Verify the file contains all components. Ensure mode-suffixed accessors strictly match their parent theme's mode (e.g., no `_light` keys inside `<slug>_dark_theme`). Verify `custom_css` inlines correctly. Resolve all compilation errors.
4. **Apply Theme:** Attach the theme per Schema Part 4 and verify dashboard diagnostics.
5. **Summarize Delivery:** Conclude with a summary of the theme slug, leading mode, anchor colors (and their source), modified files, and active warnings.

## Schema

A theme file contains one shared Brand Tokens object, then two components per mode (ColorPalette and PageTheme), followed by the dashboard application declaration. Replace `<slug>` and `<mode>` (`light` or `dark`) with actual identifiers, and `"..."` with derived constants.

```aml
// 1. Brand Tokens — the theme's single source of truth, covering both modes.
//    Unsuffixed keys are shared by both modes. `_light` / `_dark` keys are the ONLY
//    things the lighting changes; keep each pair adjacent so the two stay comparable.
const <slug>_brand = {
  primary: "oklch(...)"
  secondary: "oklch(...)"
  font_body: "<body family>"
  font_display: "<title family>"
  corner_style: "sharp|rounded|soft"
  density: "compact|comfortable|spacious"
  elevation: "hairline|flat|shadow"

  background_light: "oklch(...)"
  background_dark: "oklch(...)"
  canvas_bg_light: "oklch(...)"
  canvas_bg_dark: "oklch(...)"
  block_bg_light: "oklch(...)"
  block_bg_dark: "oklch(...)"
  text_primary_light: "oklch(...)"
  text_primary_dark: "oklch(...)"
  text_muted_light: "oklch(...)"
  text_muted_dark: "oklch(...)"
  text_subtle_light: "oklch(...)"
  text_subtle_dark: "oklch(...)"
  border_light: "oklch(...)"
  border_dark: "oklch(...)"
  focus_ring_light: "oklch(...)"
  focus_ring_dark: "oklch(...)"
  semantic_success_light: "oklch(...)"
  semantic_success_dark: "oklch(...)"
  semantic_warning_light: "oklch(...)"
  semantic_warning_dark: "oklch(...)"
  semantic_danger_light: "oklch(...)"
  semantic_danger_dark: "oklch(...)"
}

// 2. Chart Palette — 8 categorical OKLCH colors
ColorPalette <slug>_<mode>_palette {
  title: "<Human Name>"
  categorical {
    colors: [ <8 OKLCH literals> ]
  }
}

// 3. Page Theme — References tokens via accessors
PageTheme <slug>_<mode>_theme {
  title: "<Human Name>"
  color {
    data: <slug>_<mode>_palette
  }
  background {
    bg_color: <slug>_brand("background_<mode>")
  }
  canvas {
    background {
      bg_color: <slug>_brand("canvas_bg_<mode>")
    }
    border {
      border_width: 0
      border_radius: "..." // "sharp" -> 4 | "rounded" -> 12 | "soft" -> 20
      border_color: <slug>_brand("border_<mode>")
      border_style: "none"
    }
    shadow: "none"
    opacity: 1
  }
  block {
    background {
      bg_color: <slug>_brand("block_bg_<mode>")
    }
    border {
      border_width: "..."  // "hairline" -> 1 | "flat" -> 0 | "shadow" -> 0
      border_style: "..."  // "hairline" -> "solid" | "flat" -> "none" | "shadow" -> "none"
      border_radius: "..." // "sharp" -> 4 | "rounded" -> 12 | "soft" -> 20
      border_color: <slug>_brand("border_<mode>")
    }
    shadow: "..."          // "hairline" -> "none" | "flat" -> "none" | "shadow" -> "sm" (or "md"/"lg")
    padding: "..."         // "compact" -> 12 | "comfortable" -> 16 | "spacious" -> 20
    opacity: 1
    label {
      font_family: <slug>_brand("font_display")
      font_size: "..."     // "compact" -> 13 | "comfortable" -> 14 | "spacious" -> 15
      font_color: <slug>_brand("text_primary_<mode>")
      font_weight: "semibold"
      font_style: "normal"
      letter_spacing: "0"
    }
    text {
      font_family: <slug>_brand("font_body")
      font_size: "..."     // "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
      font_color: <slug>_brand("text_muted_<mode>")
      font_weight: "normal"
      font_style: "normal"
    }
  }
  viz {
    table {
      general {
        bg_color: <slug>_brand("block_bg_<mode>")
        font_color: <slug>_brand("text_muted_<mode>")
        font_family: <slug>_brand("font_body")
        font_size: "..."   // "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
        border_color: <slug>_brand("border_<mode>")
        grid_color: <slug>_brand("border_<mode>")
        border_width: 1
        hover_color: "oklch(...)"   // Derived inline: background.L +0.03 (light) / +0.05 (dark)
        banding_color: "oklch(...)" // Derived inline: background.L +0.015 (light) / +0.03 (dark)
        cell_padding: DetailedSpacing {
          top: "..."       // "compact" -> 6  | "comfortable" -> 10 | "spacious" -> 14
          right: "..."     // "compact" -> 12 | "comfortable" -> 16 | "spacious" -> 20
          bottom: "..."    // "compact" -> 6  | "comfortable" -> 10 | "spacious" -> 14
          left: "..."      // "compact" -> 12 | "comfortable" -> 16 | "spacious" -> 20
        }
        borders {
          outer: true
          vertical: false
          horizontal: true
          header: true
          row_header: false
        }
      }
      header {
        bg_color: <slug>_brand("background_<mode>")
        font_color: <slug>_brand("text_primary_<mode>")
        font_size: "..."   // "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
        font_weight: "semibold"
      }
      sub_header {
        bg_color: "oklch(...)" // Same inline literal as banding_color
        font_color: <slug>_brand("text_muted_<mode>")
        font_size: "..."   // "compact" -> 12 | "comfortable" -> 13 | "spacious" -> 14
        font_weight: "medium"
      }
      sub_title {
        font_color: <slug>_brand("text_subtle_<mode>")
        font_size: "..."   // "compact" -> 11 | "comfortable" -> 12 | "spacious" -> 13
        font_weight: "medium"
      }
      sparkline {
        line {
          color: <slug>_brand("primary")
        }
        column {
          color: <slug>_brand("primary")
        }
      }
    }
    metric_kpi {
      alignment: "left"    // "left" | "center" | "right"
      label {
        font_family: <slug>_brand("font_body")
        font_size: "..."   // "compact" -> 18 | "comfortable" -> 20 | "spacious" -> 22
        font_color: <slug>_brand("text_muted_<mode>")
      }
      value {
        font_family: <slug>_brand("font_display")
        font_size: "..."   // "compact" -> 40 | "comfortable" -> 48 | "spacious" -> 56
        font_color: <slug>_brand("text_primary_<mode>")
      }
      progress {
        indicator {
          bg_color: <slug>_brand("primary")
        }
        track {
          bg_color: <slug>_brand("border_<mode>")
        }
        text {
          font_color: <slug>_brand("text_muted_<mode>")
        }
      }
      // Each trend bg_color is a faint wash of its own hue, derived inline:
      // light -> high L ~0.92, low C | dark -> low L ~0.40, low C
      trend {
        positive {
          text {
            font_color: <slug>_brand("semantic_success_<mode>")
            font_weight: "medium"
          }
          background {
            bg_color: "oklch(...)"
          }
        }
        negative {
          text {
            font_color: <slug>_brand("semantic_danger_<mode>")
            font_weight: "medium"
          }
          background {
            bg_color: "oklch(...)"
          }
        }
        neutral {
          text {
            font_color: <slug>_brand("text_muted_<mode>")
            font_weight: "normal"
          }
          background {
            bg_color: "oklch(...)"
          }
        }
      }
    }
  }
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

// 4. Dashboard Application
Dashboard <target_dashboard> {
  theme: DynamicPageTheme {
    light: <slug>_light_theme,
    dark: <slug>_dark_theme,
  }
  ...
}

```

## Conventions

### Palette Construction

Construct the 8 categorical colors using OKLCH (`oklch(L C H)`). Categorical colors identify distinct data series, so distinction relies strictly on **hue**. Maintain uniform lightness and chroma so no single series visually dominates.

1. **Hue Distribution:** Set Slot 1 to `primary`. Space Slots 2–8 roughly 45° apart around the wheel. Ensure `secondary` lands on a defined slot. Maintain ≥ 40° separation between adjacent slots with no near-neutral tones.
2. **Lightness & Chroma Bounds:** Maintain Chroma C ≥ 0.12 (hard floor C ≥ 0.10). Keep Lightness L within a tight sub-band: **Light:** ~0.60-0.66; **Dark:** ~0.55-0.63.
3. **CVD Adjustments:** Shift lightness by ±0.05-0.10 *only* to separate collapsing pairs (blue/purple or adjacent warm colors) under protanopia and deuteranopia. Cap yellow/amber hues at L ≤ 0.75.
4. **Contrast Verification:** Ensure worst-pair CVD ΔE ≥ 12 (absolute floor ΔE ≥ 8) and maintain a ≥ 3:1 contrast ratio against `block_bg`.

*Note: Re-derive lightness and chroma bounds independently per mode. Never reuse light-mode palette values in dark mode.*

### Design Principles

* **Surface Elevation:** Backgrounds step up in lightness from page → canvas → block. Light mode uses a near-white page (L ~0.95-0.975) with progressively lighter cards. Dark mode uses a soft dark-gray page (L ~0.25-0.30) with elevated cards. (Because brand anchors are shared, any dark-mode chroma pull-backs are applied directly in that mode's chart palette).
* **Typographic Hierarchy:** Use a single cohesive type scale. Block titles ≥ body text, table text ≈ body text, sub-titles < body text, KPI labels small, and KPI values prominent.
* **System Density:** The density property (`compact`, `comfortable`, `spacious`) scales padding, cell spacing, and font sizes simultaneously.
* **Corner & Elevation Consistency:** Corner styling (`sharp`, `rounded`, `soft`) and elevation (`hairline`, `flat`, `shadow`) apply uniformly to both canvas and block cards.
* **Cross-Mode Parity:** Brand anchors, fonts, corner styles, densities, and elevations use unsuffixed keys and are inherently shared. Font sizes, padding, and palette hue sequences must be manually matched across modes. Only surface lightness ladders, text tiers, borders, focus rings, semantic colors, and hover/banding tints are re-derived per mode.

### Treatment Options & Custom CSS

* **Conservative (Default):** Solid backgrounds, restrained palettes, and the verbatim `custom_css` block.
* **Experimental (Opt-In):** Used only when explicitly requested. Applies native `bg_image` gradients (e.g., `"linear-gradient(...)"`) to `background`, `canvas.background`, or `block.background`, bolder chroma, and `md`/`lg` shadows. Custom CSS remains verbatim.
* **Custom CSS:** Emit the `.dac-text-block` (+ `h1`–`h6`) CSS block exactly as shown in the Schema. Replace string placeholders with literal values and terminate with `;;` on its own line. Do not add, remove, or modify selectors. Include an `@import url(...)` above the CSS *only* if `font_body` or `font_display` references non-bundled fonts. (Bundled fonts: Inter, Arial, Verdana, Tahoma, Trebuchet MS, Times New Roman, Georgia, Garamond, Courier New).

### General Constraints

* **Token Integrity:** Declare every design decision in `<slug>_brand` and reference it via an accessor. Use a `_light` / `_dark` suffix only when the modes genuinely require different values; otherwise, keep the key unsuffixed and shared.
* **Color Formatting:** Always use `"oklch(L C H)"`. Convert user-provided hex codes to OKLCH.
* **Closed Vocabulary:** Strictly use the properties, tokens, and structures defined in this specification.
