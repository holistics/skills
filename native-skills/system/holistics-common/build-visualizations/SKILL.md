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
2. **Decide the analytics task and the viz type yourself** (Output → *Choosing the viz type*) — leave the type unstated and generate_viz picks one. A chart form no built-in covers goes to the build-custom-chart skill instead.
3. **Get the explore** — `generate_aql`; generate_viz consumes an AQL explore, not a field list.
4. **Write the `query`** — name the viz type, which field plays which role, the number/date formatting, and what to leave out (Conventions → *A VizBlock owns its data and shape*), since it defaults anything unstated. Retrying after an error? Include the error text — it self-corrects from it.
5. **Check what comes back** — give a `MetricKpi` its block-level `settings { hide_label: true }`, wrap the result in the `VizBlock`, and `execute_viz` to validate. Fix every code diagnostic.
6. **Deliver** — each block as name + viz type + the question it answers + any date field it carries, with the field reference.

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
| Data-bound prose, a branded card, or a bespoke table no built-in can shape | `MarkdownViz` (dynamic content block) — describe the card in the `query` (Authoring) | — |
| A chart form no built-in covers (box plot, sankey, waterfall, candlestick, calendar heatmap, dumbbell) | custom chart → the **build-custom-chart** skill (Vega/Vega-Lite) | — |

generate_viz writes the built-in types (Authoring); their per-type field roles and settings come from generate_viz or the docs (search_docs) — never inline the full catalog or invent a type. Watch the confusable boundaries:

* **Static text vs MarkdownViz** — the instant text must show a *live data value*, it's a MarkdownViz (here); fixed words with no data are a TextBlock → build-dashboard.
* **Built-in vs MarkdownViz** — if a standard chart shows it well, use the built-in; **never rebuild a bar/line/table in HTML**. MarkdownViz is for a presentation the built-ins can't express — not for restyling one they can (that's the theme's job).
* **MarkdownViz vs custom chart** — presentational / narrative / branded and expressible in static HTML/CSS (no JS, no real axes) → **MarkdownViz**, inline to this dashboard. A true plotted chart form with axes/scales/marks, or one reused across dashboards → **custom chart** (Vega/Vega-Lite).

### Authoring — never hand-write a viz body

Every viz — built-in or dynamic content block — is written by **generate_viz**, never by hand; hand-written viz grammar is the top source of invalid output. It consumes an **AQL explore**, so the flow is **generate_aql → generate_viz → execute_viz** (execute validates it). Wrap what comes back — `block <x>: VizBlock { label: '…' viz: <generate_viz output> }` — and give a `MetricKpi` block-level `settings { hide_label: true }` (Conventions → *MetricKpi*). You hand-write only the `VizBlock` wrapper and block-level settings; verify any unknown construct with search_docs.

Only the `query` differs by type. A built-in needs the data and the viz type; a `MarkdownViz` card also needs **what it should say** — the sentence or layout, which value goes where, what to emphasize. Describe the finished card, not the fields. A card renders HTML/CSS/Markdown and never JavaScript, so nothing in it can be interactive.

**Custom chart.** Use the **build-custom-chart** skill if available, else `search_docs` for `CustomChartDef` (reusable Vega/Vega-Lite).

## Conventions

* **Prefer `CombinationChart` for any line, area, column, or bar chart.** Combination Chart is Holistics' superset of those four — it renders line, area, column, and bar series (with per-series type), so one viz type covers every trend and every category comparison/ranking. Preferring it keeps charts consistent to theme and lets a chart later gain a second measure, a dual axis, or a mixed column+line without swapping types. Ask generate_viz for a `CombinationChart` and set each series' display (line/area/column/bar) to the analytics task — not a standalone `LineChart`/`AreaChart`/`ColumnChart`/`BarChart`. (Part-to-whole stays `PieChart`; the non-cartesian types — map, funnel, radar, gauge, scatter — are unaffected.)
* **A VizBlock owns its data and shape; the theme and the controls own the rest.** generate_viz builds each chart as a *standalone report*, so what comes back carries decoration and a self-contained time window that a block on a dashboard usually shouldn't keep. One test covers both: *would the theme or a control otherwise provide this?* If yes, drop it. If removing it changes what the chart **says**, keep it — which is why a filter that's part of what the chart fundamentally is (a returns chart is by definition `status = returned`) stays, while one that merely restates what a control filters goes. **A user instruction outranks the test** — asked for this one chart in brand red, or pinned to last 30 days regardless of the date filter, keep it and say so in the handoff.
* **MetricKpi** blocks get `settings { hide_label: true }` at the block level (a sibling of `viz:`) — and no other block setting.
* **Prose** that may contain apostrophes or span lines (viz labels, descriptions, DCB template text) goes in `@md … ;;` heredocs, not single quotes.
* **Layout is build-dashboard's job.** On a fresh build, supply only the blocks; build-dashboard positions them. When adding a block to an existing dashboard standalone, place it and recompute the canvas height (as build-dashboard-controls does for controls).
