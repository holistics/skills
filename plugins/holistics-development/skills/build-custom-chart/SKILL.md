---
name: build-custom-chart
label: Build Custom Chart
description: |-
  Create or refine a Holistics custom chart (CustomChartDef in .holistics/library/custom_charts/) for a chart type the built-in viz can't cover.

  Use when the user wants to create a custom chart, convert a Vega/Vega-Lite spec into Holistics AML, or scaffold or refine a chart template — or when a dashboard needs a chart form with no built-in equivalent (heatmap matrix, sankey, waterfall, box plot, ...).

  Typical phrasings: create a custom chart for X, turn this Vega-Lite spec into a Holistics chart, we need a sankey of X.

  Do NOT trigger for a standard built-in chart or a dynamic content block.
---

Create or refine a `CustomChartDef` at `.holistics/library/custom_charts/<chart_name>.chart.aml`.

## What a good input looks like
A custom-chart task is fully specified when you can answer:
1. **Analytical intent** — what comparison or pattern the chart shows (flow, part-to-whole over stages, matrix density, progress-to-target).
2. **Data shape** — the dimensions and measures it binds, their types, and rough cardinality (a 7×12 matrix reads differently from 50×50).
3. **Reuse surface** — which choices future users should be able to make without editing the template (orientation, thresholds, labels).
4. **Look** — how it sits next to built-in charts on a themed dashboard.

## What a bare minimum output looks like
- **Reusable, always**: fields and options bound through the runtime interpolations below — a template with hardcoded dataset field names is broken even if it renders.
- Every option has a `default_value` that renders a correct, complete chart untouched.
- **Native look by default**: readable typography, light neutral gridlines, clean legend, default color scheme; no heavy shadows, saturated backgrounds, thick borders, or patterned fills unless the user asks. The chart should sit beside built-in charts without looking foreign, and survive dashboard theming. (A faithful Exact copy keeps its original styling.)
- A `label` and a one-line `description` saying when to use it.

## Workflow
1. **Derive intent & data shape** — from the request and, in a dashboard context, from the actual dataset fields involved. Note if it's interactive, layered, or multi-view — those are the ones that break; Schema → Interactivity and → Responsiveness cover them. Decide the option set yourself from the reuse surface — don't ask the user to enumerate knobs; ask only for details that materially change the definition (field roles, whether raw Vega is truly needed).
2. **Look for something to start from** (see Conventions → Reuse before building) — check `.holistics/library/custom_charts/` in this project, then `search_docs` for the chart type. State what you found: a complete matching template → copy it; something close → adapt it; nothing → build fresh (`@vgl`).
3. **Name it** — keep the user's chart name; if none, derive a short snake_case uname from the chart's purpose; on collision append a short suffix (`_chart`, `_v2`) rather than inventing a new name.
4. **Write / refine** `.holistics/library/custom_charts/<chart_name>.chart.aml` per Schema — fields and options declared by name, every option with a `default_value`, and data/fields/options bound through the runtime `@{...}` interpolations (never hardcode dataset field names). For refines, see Conventions → Refining an existing chart.
5. **Verify** — check code diagnostics on the chart file and any dashboard using it; fix every error.
6. **Deliver** — reply briefly: what you reused vs built, required fields and their roles, options if any, and what the chart is good for, plus 2-3 concrete next steps. If the chart is multi-view (`facet`/`concat`/`repeat`), lead with the responsiveness caveat from Schema → Responsiveness.

## Schema
Declare fields and options BY NAME. Parametric forms (`field(elem_name_as: ...)`, `multiple`, `unique_elem_name`) are not valid in CustomChartDef and fail to compile.

    CustomChartDef <chart_name> {
      label: 'Human Name'                  // REQUIRED — compile fails without it
      description: 'when to use it'
      fields {
        field <field_name> {
          label: 'Label'
          type: 'dimension|measure'
          // optional: data_type: 'string'|'number'|'boolean'|'date'
          // optional: sort { direction: 'asc'|'desc' }
        }
      }
      options {                            // optional block
        option <option_name> {
          label: 'Option name'
          type: 'input|number-input|toggle|radio|select|color-picker'
          default_value: true              // REQUIRED
          // options: [...]  — required for radio/select: list every choice
        }
      }
      template: <@vgl or @vg heredoc>
    }

**Field rules:** `dimension` for categorical/date/grouping inputs, `measure` for aggregated numeric inputs. Declare a field only if the template binds it. Add `data_type` only when the template branches on the input type; add `sort` only when output order carries meaning (running totals, ranked bars, ordinal axes). Keep the field list as small as flexibility allows. **A `measure` field is auto-aggregated by Holistics** — if the template also aggregates that input (an in-encoding `"aggregate": "sum"`, common in copied Vega-Lite specs), it double-counts; either declare the field `dimension` or strip the in-spec aggregation.

**Option rules:** add an option only if two different users or dashboards would realistically set different values — otherwise hardcode it in the template. `toggle` for booleans, `radio` for 2-4 exclusive choices, `select` for 5+, `number-input` for numeric parameters, `input` for free text, `color-picker` only when theme defaults genuinely can't serve.

### Runtime binding — how the template talks to Holistics
Holistics substitutes each `@{...}` placeholder into the spec before rendering, and the substitution is **context-aware** by grammar position:
- A placeholder **standing alone** becomes a full JSON literal — a string value brings its own quotes (`"field": @{fields.x.name}` → `"field": "Revenue"`), a number/boolean stays bare (`"tooltip": @{options.show.value}` → `"tooltip": true`), and `@{values}` becomes the data-row array.
- A placeholder **inside a quoted string** is spliced in raw, no quotes added, so it composes into that string (`datum['@{fields.x.name}']` → `datum['Revenue']`).

So: put the placeholder where the value belongs and let position handle quoting.
- **Data:** always `"data": {"values": @{values}}`.
- **The token surface is closed** — only `@{values}`, `@{fields.<name>.(name|type|format)}`, and `@{options.<name>.value}` resolve; nothing else. There is no `@{fields.<name>.label}` (that `label` is a Studio setting, not a runtime token) — use `@{fields.<name>.name}` for a display title. Use `@{fields.<name>.type}` only when an encoding's type varies with the input, and `@{fields.<name>.format}` with `"formatType": "holisticsFormat"` to honor the field's number/date format.
- **Expression contexts must quote the placeholder.** A `filter` predicate, a Vega `expr` / `signal` update, or a `datum[...]` access is parsed as an expression, so the value must arrive as a string: `{"filter": "@{options.show.value}"}`, `datum['@{fields.x.name}']` (field names can contain spaces). A bare `@{...}` there yields a raw boolean/number/name that is not a valid expression and crashes the compiler (`{"filter": @{options.show.value}}` → `{"filter": false}` → crash).
- **Heredoc envelope:** `template: @vgl { … };;` (or `@vg`) — the brace right after the engine tag IS the spec object's own opening brace (don't add a second), and the spec closes with `}` then two semicolons. A doubled `{{ }}` or a missing/single trailing semicolon won't parse.
- **`@vg` only:** explicit transform syntax (every transform carries a `"type"`); define a dataset before any `lookup` that reads it.

### Responsiveness — let the chart fill its widget
Holistics auto-fits every custom chart to its widget and redraws on resize; you wire up no resize handling. Just don't pin sizes:
- **Vega-Lite:** omit top-level `width`/`height` — Holistics sets them to `"container"`. If you copied a sized gallery spec, delete the sizes or set them to `"container"`; a fixed `"width": 400` locks the chart at 400px.
- **Vega (`@vg`):** bind each scale's `range` to the `"width"`/`"height"` shorthand (`"range": "width"`), never fixed pixels, and drop top-level `width`/`height`. For margins or grid layouts, derive your own signals from the `width`/`height` signals Holistics maintains (`"update": "width - 50"`).
- **Multi-view Vega-Lite (`facet`/`row`/`column`/`concat`/`repeat`) does NOT stretch** — it lays panels out at natural size and gets scaled as a whole, so it shrinks to unreadable on a small widget. For a responsive small-multiples grid, build it in `@vg` and size cells from the `width`/`height` signals.
- Escape hatch: `"holisticsConfig": { "disableAutoSize": true }` renders at spec size and lets the widget scroll.

### Interactivity — cross-filter, context menu, highlight
Interactions are Vega-Lite `params` (selections) wired to Holistics through a top-level `holisticsConfig` (beside `data`/`mark`/`layer`):
- `crossFilterSignals`: selection names that cross-filter the dashboard on **click** — use a **point** selection (`"select": "point"`) or an **interval** selection (`{"type":"interval","encodings":["x"]}`).
- `contextMenuSignals`: selection names that open the context menu (drill-through, date-drill) on **right-click** — use a **hover** selection (`{"type":"point","on":"mouseover","clear":"mouseout"}`).
- Cross-filter and the context menu fire on different triggers, so wire them to **different** params — a click selection for one, a hover selection for the other.
- **On a layered spec, declare the `params` inside ONE layer unit, not at the spec's top level.** A top-level selection on a `layer` gets replicated into every layer and fails to render with `Duplicate signal name: "<sel>_tuple"`. Put the `params` block in the first layer; the selection still hoists to a top-level signal, so other layers can filter on it (`{"filter": {"param": "sel"}}`) and `holisticsConfig` still sees it. `holisticsConfig` itself stays at the top level.
- Highlight/fade effect: gate an encoding on the selection with `"empty": false` so it applies only when something is actually selected — `{"condition": {"param": "sel", "empty": false, "value": 1}, "value": 0.3}`. Omit `empty: false` and the "selected" branch is true for everything by default (nothing fades).
- To filter one layer of a combo chart by a selection, use a **param predicate** — `{"filter": {"param": "sel"}}`, the object form — never a bare boolean (see the expression-position rule above).

## Conventions

### Reuse before building — check first
You can't browse the web — your sources are `.holistics/library/custom_charts/` in this project and `search_docs` (which reaches Holistics' official chart library and AML reference). Check both and **state what you found before drafting**. Unsure of a token or syntax? `search_docs` it — don't guess.

Classify by how complete your source is: **Exact** (you have the full template for a matching type), **Similar** (right field shape, different layout/options, or you only got a snippet), or **None**. A request with constraints beyond the chart type ("but...", "with...", "except...") is at most Similar.

**Exact → copy faithfully.** Reproduce `fields`, `options`, and `template` character-for-character. The only permitted edits:
- file path (to the requested location),
- chart uname (per the naming rule above),
- a top-level `label` — CustomChartDef REQUIRES one, and library templates are sometimes published without it; adding a short label is the one allowed addition, without it the chart fails to compile.
No restructuring, renaming, restyling, or "improving" — unless the user explicitly asks to adapt.

**Similar → adapt minimally.** Start from the closest template and change only what the stated requirements need.

**None → build from scratch.** Use `@vgl` (Vega-Lite) by default; `@vg` only for what Vega-Lite cannot express (signals, interdependent datasets, missing transforms). If the user supplied a Vega/Vega-Lite spec, convert it rather than rewriting it.

### Refining an existing chart
- Read the current file first. Preserve its file path and uname unless asked to rename.
- Non-structural changes (rename labels, adjust options, tweak formatting) → edit in place, leave everything else untouched.
- Structural changes (switch template engine, add a data level, rework the data pipeline) → flag it and confirm refine-vs-rebuild with the user before proceeding.
