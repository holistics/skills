---
name: build-custom-chart
label: Build Custom Chart
description: |-
  Create or refine a Holistics custom chart (CustomChartDef in library/custom_charts/) for a chart type the built-in viz can't cover.

  Use when the user wants to create a custom chart, convert a Vega/Vega-Lite spec into Holistics AML, or scaffold or refine a chart template — or when a dashboard needs a chart form with no built-in equivalent (heatmap matrix, sankey, waterfall, box plot, ...).

  Typical phrasings: create a custom chart for X, turn this Vega-Lite spec into a Holistics chart, we need a sankey of X.

  Do NOT trigger for a standard built-in chart or a dynamic content block.
---

Create or refine a `CustomChartDef` at `library/custom_charts/<chart_name>.chart.aml`.

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
1. **Derive intent & data shape** — from the request and, in a dashboard context, from the actual dataset fields involved. Decide the option set yourself from the reuse surface — don't ask the user to enumerate knobs; ask only for details that materially change the definition (field roles, whether raw Vega is truly needed).
2. **Classify the reuse match** (see Conventions → Reuse before building) — always check `library/custom_charts/` then the official library BEFORE writing anything, and state what you found: Exact → copy faithfully; Similar → adapt minimally; None → build from scratch (`@vgl` by default).
3. **Name it** — keep the user's chart name; if none, derive a short snake_case uname from the chart's purpose; on collision append a short suffix (`_chart`, `_v2`) rather than inventing a new name.
4. **Write / refine** `library/custom_charts/<chart_name>.chart.aml` per Schema — fields and options declared by name, every option with a `default_value`, and data/fields/options bound through the runtime `@{...}` interpolations (never hardcode dataset field names). For refines, see Conventions → Refining an existing chart.
5. **Verify** — check code diagnostics on the chart file and any dashboard using it; fix every error.
6. **Deliver** — reply briefly: what you reused vs built, required fields and their roles, options if any, and what the chart is good for, plus 2-3 concrete next steps — lead with a responsiveness suggestion whenever the template uses `facet`, `concat`, or `repeat` (these layouts break most easily on small canvases).

## Schema
Declare fields and options BY NAME. Parametric forms (`field(elem_name_as: ...)`, `multiple`, `unique_elem_name`) are not valid in CustomChartDef and fail to compile.

    CustomChartDef <chart_name> {
      label: 'Human Name'                  // REQUIRED — compile fails without it
      description: 'when to use it'
      fields {
        field <field_name> {
          label: 'Label'
          type: 'dimension'                // 'dimension' | 'measure'
          // optional: data_type: 'string'|'number'|'boolean'|'date'
          // optional: sort { direction: 'asc'|'desc' }
        }
      }
      options {                            // optional block
        option <option_name> {
          label: 'Label'
          type: 'toggle'                   // 'input'|'number-input'|'toggle'|'radio'|'select'|'color-picker'
          default_value: true              // REQUIRED
          // options: [...]  — required for radio/select: list every choice
        }
      }
      template: <@vgl or @vg heredoc>
    }

**Field rules:** `dimension` for categorical/date/grouping inputs, `measure` for aggregated numeric inputs. Declare a field only if the template binds it. Add `data_type` only when the template branches on the input type; add `sort` only when output order carries meaning (running totals, ranked bars, ordinal axes). Keep the field list as small as flexibility allows.

**Option rules:** add an option only if two different users or dashboards would realistically set different values — otherwise hardcode it in the template. `toggle` for booleans, `radio` for 2-4 exclusive choices, `select` for 5+, `number-input` for numeric parameters, `input` for free text, `color-picker` only when theme defaults genuinely can't serve.

### Runtime binding — how the template talks to Holistics
- Open `template: @vgl {` (or `@vg {`) and end the heredoc with the closing brace immediately followed by two semicolon characters — a bare brace or single semicolon fails with "Unterminated string".
- Bind data with `"values": @{values}`.
- Reference bound fields as `@{fields.<name>.name}` and option values as `@{options.<name>.value}` — never hardcode dataset field names. Use `@{fields.<name>.type}` only when an encoding's type depends on the bound field, and `@{fields.<name>.format}` (with `"formatType": "holisticsFormat"`) to honor the field's configured number/date format.
- Write every `@{...}` interpolation unquoted; it inserts a correctly quoted value itself.
- In Vega expression strings, access fields with quoted brackets — `datum[''@{fields.<name>.name}'']` — field names can contain spaces; use single quotes inside inline object literals.
- `@vg` templates use explicit transform syntax (every transform has a `"type"` key); define a dataset before any `lookup` that depends on it.

## Conventions

### Reuse before building — classify the match first
Check in order, and **state what you found before drafting anything**:
1. `library/custom_charts/` in this project.
2. The official library: https://docs.holistics.io/docs/charts/custom-charts/library/ (if unreachable, fall back to 1-2 keyword searches).

Classify: **Exact** (a template matches the requested type), **Similar** (same field shape, different layout/options), or **None**. A request with constraints beyond the chart type ("but...", "with...", "except...") is at most Similar.

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
