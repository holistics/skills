---
name: build-visualizations
label: Build Visualizations
description: |-
  Author the VizBlocks in a Holistics dashboard's page.aml: built-in visualizations (chart, KPI, table, pivot, funnel, map) and dynamic content blocks (MarkdownViz: data-driven HTML/Markdown).

  Use when the user wants to create or edit what a block renders.

  Typical phrasings: build a chart of X, add a KPI, show X as a table, make a dynamic content block, a card or narrative that shows the top product.

  Do NOT trigger for building a whole dashboard, static text blocks, adding filters or controls, or theming and restyling.
user-invocable: false
---

# Building a Dashboard's VizBlocks (charts, KPIs, tables, dynamic content)

Author a dashboard's **VizBlocks** — the built-in charts and dynamic content blocks that render live data bound to real fields.

## What a good input looks like

A task is fully specified when you can answer, for each block:

1. **Analytics task** — the question this block answers, in the reader's words ("how is revenue trending?", "which categories are biggest?", "what's the total right now?").
2. **Fields** — the measures and dimensions that answer it, read from the dataset with `fetch_dataset` rather than assumed.
3. **Viz type** — the Holistics type that renders that task (Output → *Choosing the viz type*). Which chart *shape* suits a task is ordinary judgment; what needs care is which Holistics type carries that shape.

Static text with no live data isn't a VizBlock — that's a TextBlock.

## What a bare minimum output looks like

* Every block renders real data on real dataset fields — never a placeholder or invented field.
* A KPI's comparison context comes from the dashboard's Period Comparison control, not a period baked into the KPI.
* A dynamic content block shows something a built-in can't, and shows live values — not a static card that happens to be styled.
* Prose that may contain apostrophes or span lines (labels, descriptions, DCB text) uses an `@md … ;;` heredoc, not single quotes.

## Workflow

Per block:

1. **Read the dataset** — `fetch_dataset` for the real measures and dimensions. Bind only fields you have read.
2. **Decide the analytics task and the viz type yourself** (Output → *Choosing the viz type*) — don't leave it to a default. A chart form no built-in covers goes to the build-custom-chart skill instead.
3. **Write the viz body** (Output → *Authoring*) — yourself from the **viz** skill's references if that skill is available; otherwise through generate_aql → generate_viz. Either way, leave out what the theme or a control provides (Conventions → *A VizBlock owns its data and shape*).
4. **Check it** — give a `MetricKpi` its block-level `settings { hide_label: true }`, wrap the viz in the `VizBlock`, and `execute_viz` to validate. Fix every code diagnostic.
5. **Deliver** — each block as name + viz type + the question it answers + any date field it carries, with the field reference.

With several blocks to build and a `viz-writer` sub-agent available, you may hand blocks to sub-agents in parallel (see the viz skill's *Sub-agent or inline?*) — give each its viz type, fields, and what to leave out, then wrap and check what comes back.

## Output

### Choosing the viz type

Pick the viz type by analytics task — built-in types are the default (top of the table); the last two rows are the fallbacks when no built-in fits:

| Analytics task | Preferred viz type | Other viz types |
|---|---|---|
| Single headline number | `MetricKpi` | — |
| Progress toward a target | `GaugeChart` | — |
| Trend over time | `CombinationChart` (line / area series) | `LineChart`, `AreaChart` |
| Category comparison / ranking | `CombinationChart` (column / bar series) | `ColumnChart`, `BarChart` |
| Part-to-whole (≤5 categories) | `PieChart` | donut variant |
| Relationship of two measures | `ScatterChart` | `BubbleChart` (a third measure as point size) |
| Multi-measure profile | `RadarChart` | — |
| Term frequency | `WordCloud` | — |
| Staged drop-off | `ConversionFunnel` | `FunnelChart`, `PyramidChart` |
| Cohort behaviour over time | `RetentionHeatmap` | — |
| Row-level detail / lookup | `DataTable` | — |
| Cross-tab of values | `PivotTable` | — |
| Metrics laid out side by side | `MetricSheet` | — |
| Geography | `PointMap` | `FilledMap` (by region), `Heatmap` (density) |
| Data-bound prose, a branded card, or a bespoke table no built-in can shape | `MarkdownViz` (dynamic content block) — see Authoring | — |
| A chart form no built-in covers (box plot, sankey, waterfall, candlestick, calendar heatmap, dumbbell) | custom chart → the **build-custom-chart** skill (Vega/Vega-Lite) | — |

Each built-in type's field roles and settings come from the viz skill's type definitions, generate_viz, or the docs (search_docs) — never inline the full catalog or invent a type. Watch the confusable boundaries:

* **Static text vs MarkdownViz** — the instant text must show a *live data value*, it's a MarkdownViz (here); fixed words with no data are a TextBlock → build-dashboard.
* **Built-in vs MarkdownViz** — if a standard chart shows it well, use the built-in; **never rebuild a bar/line/table in HTML**. MarkdownViz is for a presentation the built-ins can't express — not for restyling one they can (that's the theme's job).
* **MarkdownViz vs custom chart** — presentational / narrative / branded and expressible in static HTML/CSS (no JS, no real axes) → **MarkdownViz**, inline to this dashboard. A true plotted chart form with axes/scales/marks, or one reused across dashboards → **custom chart** (Vega/Vega-Lite).

### Authoring

Viz grammar written from memory is the top source of invalid output, so every viz body — built-in or dynamic content block — comes from one of two paths:

* **With the viz skill (if available)** — write it yourself from that skill's references: read `guide.md`, use only the properties your viz type has in `type_definitions/viz.aml`, pattern-match `examples.md`, and for a `MarkdownViz` follow the [dynamic content block syntax](https://docs.holistics.io/docs/charts/dynamic-content-blocks/syntax-reference). Start from the dataset fields; an AQL explore is optional. Switch to generate_viz when the user or the project's instructions ask for Holistics AI, or when the viz still fails after ~3 fix rounds.
* **Otherwise, generate_viz** — never hand-write the body. It consumes an **AQL explore**, so the flow is **generate_aql → generate_viz**. In its `query`, name the viz type, which field plays which role, and the number/date formatting, since it defaults anything unstated. Retrying after an error? Include the error text — it self-corrects from it.

Either way, `execute_viz` validates it. Wrap the viz — `block <x>: VizBlock { label: '…' viz: <viz> }` — and give a `MetricKpi` block-level `settings { hide_label: true }` (Conventions → *MetricKpi*); verify any unknown construct with search_docs.

A `MarkdownViz` card also needs **what it should say** — the sentence or layout, which value goes where, what to emphasize. Decide the finished card, not just the fields (and describe it that way in generate_viz's `query`). A card renders HTML/CSS/Markdown and never JavaScript, so nothing in it can be interactive.

**Custom chart.** Use the **build-custom-chart** skill if available, else `search_docs` for `CustomChartDef` (reusable Vega/Vega-Lite).

## Conventions

* **Prefer `CombinationChart` for any line, area, column, or bar chart.** Combination Chart is Holistics' superset of those four — it renders line, area, column, and bar series (with per-series type), so one viz type covers every trend and every category comparison/ranking. Preferring it keeps charts consistent to theme and lets a chart later gain a second measure, a dual axis, or a mixed column+line without swapping types. Ask generate_viz for a `CombinationChart` and set each series' display (line/area/column/bar) to the analytics task — not a standalone `LineChart`/`AreaChart`/`ColumnChart`/`BarChart`. (Part-to-whole stays `PieChart`; the non-cartesian types — map, funnel, radar, gauge, scatter — are unaffected.)
* **A VizBlock owns its data and shape; the theme and the controls own the rest.** Both generate_viz and the viz skill's guide build each chart as a *standalone report*, so it carries decoration and a self-contained time window that a block on a dashboard usually shouldn't keep. One test covers both: *would the theme or a control otherwise provide this?* If yes, drop it. If removing it changes what the chart **says**, keep it — which is why a filter that's part of what the chart fundamentally is (a returns chart is by definition `status = returned`) stays, while one that merely restates what a control filters goes. **A user instruction outranks the test** — asked for this one chart in brand red, or pinned to last 30 days regardless of the date filter, keep it and say so in the handoff.
* **MetricKpi** blocks get `settings { hide_label: true }` at the block level (a sibling of `viz:`) — and no other block setting.
* **Prose** that may contain apostrophes or span lines (viz labels, descriptions, DCB template text) goes in `@md … ;;` heredocs, not single quotes.
* **Layout is build-dashboard's job.** On a fresh build, supply only the blocks; build-dashboard positions them. When adding a block to an existing dashboard standalone, place it and recompute the canvas height (as build-dashboard-controls does for controls).
