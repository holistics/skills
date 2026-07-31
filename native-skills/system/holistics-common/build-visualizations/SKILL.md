---
name: build-visualizations
label: Build Visualizations
description: |-
  Author a Holistics dashboard's data blocks — every VizBlock in page.aml: built-in visualizations (chart, KPI, table, pivot, funnel, map) and dynamic content blocks (MarkdownViz: data-driven HTML/Markdown).

  Use when the user wants to create or edit what a block renders.

  Typical phrasings: build a chart of X, add a KPI, show X as a table, make a dynamic content block, a card or narrative that shows the top product.

  Do NOT trigger for building a whole dashboard, static text blocks, adding filters or controls, or theming and restyling.
user-invocable: false
---

# Building a Dashboard's Data Blocks (charts, KPIs, tables, dynamic content)

Author a dashboard's **data blocks** — the built-in charts and dynamic content blocks that render live data bound to real fields.

## What a good input looks like

For each block: name its **data job**, bind **real dataset fields**, and pick its **viz type** (Output → *Choosing the viz type*). Native judgment picks the chart *shape*; the Holistics-specific part — which viz type, authored against real fields — is this skill's job. (Static text with no live data isn't a data block → build-dashboard.)

## What a bare minimum output looks like

* Every block renders real data on real dataset fields — never a placeholder or invented field.
* A built-in viz keeps its data and functional settings, but strips theme-owned decoration and any filter the dashboard's controls should provide (Conventions → *A data block owns its data and shape*).
* A KPI's comparison context comes from the dashboard's Period Comparison control, not a period baked into the KPI.
* A dynamic content block is valid HTML/CSS/Markdown (**no JavaScript**), every `{{ … }}` bound to a declared query field.
* Prose that may contain apostrophes or span lines (labels, descriptions, DCB text) uses an `@md … ;;` heredoc, not single quotes.

## Workflow

For each block: pick the viz type (Output → *Choosing the viz type*), bind real fields from `fetch_dataset`, and author it (Output → *Authoring* — `generate_viz` for a built-in viz, scaffold-then-craft for a dynamic content block, the build-custom-chart skill for a custom chart), stripping what the theme and controls own. Then check code diagnostics and fix every error; deliver each block as name + viz type + the question it answers + any date field it carries (with the field reference).

## Output

### Choosing the viz type

Static text with no live data isn't a data block — that's a TextBlock, owned by build-dashboard. For a data block, pick the viz type by data job — built-in types are the default (top of the table); the last two rows are the fallbacks when no built-in fits:

| Data job | Viz type |
|---|---|
| Single headline number | `MetricKpi` |
| Progress toward a target | `GaugeChart` |
| Trend over time | `CombinationChart` (line / area series) |
| Category comparison / ranking | `CombinationChart` (column / bar series) |
| Part-to-whole (≤5 categories) | `PieChart` / donut |
| Relationship of two measures | `ScatterChart` / `BubbleChart` |
| Multi-measure profile | `RadarChart` |
| Term frequency | `WordCloud` |
| Staged drop-off | `ConversionFunnel` / `FunnelChart` / `PyramidChart` |
| Cohort behaviour over time | `RetentionHeatmap` |
| Row-level detail / lookup | `DataTable` |
| Cross-tab of values | `PivotTable` |
| Metrics laid out side by side | `MetricSheet` |
| Geography | `PointMap` / `FilledMap` / `Heatmap` |
| Data-bound prose, a branded card, or a bespoke table no built-in can shape | `MarkdownViz` (dynamic content block) — you craft its template (Authoring) |
| A chart form no built-in covers (box plot, sankey, waterfall, candlestick, calendar heatmap, dumbbell) | custom chart → use the **build-custom-chart** skill (Vega/Vega-Lite) |

generate_viz writes the built-in types (Authoring); their per-type field roles and settings come from generate_viz or the docs (search_docs) — never inline the full catalog or invent a type. Watch the confusable boundaries:

* **Static text vs MarkdownViz** — the instant text must show a *live data value*, it's a MarkdownViz (here); fixed words with no data are a TextBlock → build-dashboard.
* **Built-in vs MarkdownViz** — if a standard chart shows it well, use the built-in; **never rebuild a bar/line/table in HTML**. MarkdownViz is for a presentation the built-ins can't express — not for restyling one they can (that's the theme's job).
* **MarkdownViz vs custom chart** — presentational / narrative / branded and expressible in static HTML/CSS (no JS, no real axes) → **MarkdownViz**, inline to this dashboard. A true plotted chart form with axes/scales/marks, or one reused across dashboards → **custom chart** (Vega/Vega-Lite).

### Authoring — never hand-write a viz body

Every built-in viz is written by **generate_viz**, never by hand — hand-written viz grammar is the top source of invalid output. generate_viz consumes an **AQL explore**, so the flow is **generate_aql → generate_viz → execute_viz** (execute validates it). Then wrap the result — `block <x>: VizBlock { label: '…' viz: <generate_viz output> }` — strip what the theme and controls own (Conventions), and give a `MetricKpi` block-level `settings { hide_label: true }` (Conventions → *MetricKpi*). You hand-write only the `VizBlock` wrapper, block-level settings, and a DCB `content:` template — never a viz body; verify any unknown construct with search_docs.

**Dynamic content block (`MarkdownViz`) — a data-bound HTML/Markdown template.** It pairs a **dataset query** (bound to fields) with a **`content:` template** that references those fields with `{{ … }}` placeholders (`{% … %}` for loops); Holistics injects live values on render. Division of labour: **generate_viz scaffolds the query** — the `dataset` + `rows`/`values` field bindings, the error-prone part — from an AQL explore; **you write only the `content:` template**, the HTML/CSS presentation. Shape:

```aml
block <card>: VizBlock {
  label: 'Card Title'
  viz: MarkdownViz {
    dataset: <dataset_name>
    rows: [ VizFieldFull { ref: r(<model>.<dimension>) label: 'Product' } ]                       // dimensions (generate_viz fills these)
    values: [ VizFieldFull { ref: r(<model>.<measure>) label: 'Revenue' aggregation: 'sum' } ]    // measures
    content: @md
      <div class="card"><h3>{{ rows[0].`Product` }}</h3><p>{{ rows[0].values.`Revenue` }}</p></div>
    ;;
  }
}
```

The template syntax hinges on one Holistics-specific fact: the query result is `rows`, and within a row a **dimension is a top-level field while a measure sits under `values`** — ``{{ rows[0].`Product` }}`` vs ``{{ rows[0].values.`Revenue` }}`` (as in the example). Don't memorize the rest — loops, negative indexing, pivot nesting, `.raw` vs `.formatted`, and the bare-value cross-filter drill all live in the docs (**charts → dynamic-content-blocks → syntax reference**), and generate_viz's scaffold is a working starting point. **HTML / CSS / Markdown only — no JavaScript.**

**Custom chart.** Use the **build-custom-chart** skill if available, else `search_docs` for `CustomChartDef` (reusable Vega/Vega-Lite).

## Conventions

* **Prefer `CombinationChart` for any line, area, column, or bar chart.** Combination Chart is Holistics' superset of those four — it renders line, area, column, and bar series (with per-series type), so one viz type covers every trend and every category comparison/ranking. Preferring it keeps charts consistent to theme and lets a chart later gain a second measure, a dual axis, or a mixed column+line without swapping types. Ask generate_viz for a `CombinationChart` and set each series' display (line/area/column/bar) to the data job — not a standalone `LineChart`/`AreaChart`/`ColumnChart`/`BarChart`. (Part-to-whole stays `PieChart`; the non-cartesian types — map, funnel, radar, gauge, scatter — are unaffected.)
* **A data block owns its data and shape — never its look or its filtering (strip both from generate_viz's output).** generate_viz builds each chart as a *standalone report*, so its output bundles three things: the **data + shape** (yours — keep), the **look** (the theme's — strip), and the chart's **own filters** (the controls' — strip). The durable test for any `settings`/`filter` it emitted: *would the theme or a control otherwise provide this?* If yes, strip it; if removing it changes what the chart **says**, keep it. Applying the test:
  * **Look → strip** (theme-owned): series/mark colors, fonts, data labels, axis titles, point markers, legend/gridline styling.
  * **Own filters → strip** (controls-owned): the viz-level date window (`matches 'today' / 'this month'`) and the baked-in period comparison (Period-over-Period — `pop_settings`, or a MetricKpi `display_mode: 'compare by number' / 'compare by percent'`). On a dashboard the date filter sets the window, the Period Comparison control the comparison, the drill the grain, dimension filters the segmenting — the chart itself does none of it. Left in, they hide rows and go empty when the data doesn't reach 'today'; a KPI's "vs previous period" then rightly comes from the control, not the KPI.
  * **Keep** (data + shape): `group_values_into`, `sorts`, number/date `format`s (incl. `pattern: 'inherited'`), `row_limit`/`pagination_size`, aggregations; **color that IS the data** (a `RetentionHeatmap`/`Heatmap` scale, `ScaleFormat`/`conditional_formats` on a table); and a `filter`/`conditions` that's part of what the chart fundamentally is (a returns chart by definition `status = returned`, a "new customers" KPI by definition `status = new`) — but NOT one that merely restates what a control filters.

  Worked example — a `CombinationChart` back from generate_viz: **strip** `series { color: … }` (look), `filter { … 'matches' 'this month' }` (a control provides the date), and `pop_settings { … }` (the Period Comparison control provides the compare); **keep** `sorts`, `format`, `group_values_into`, `row_limit` (data + shape).
* **MetricKpi** blocks get `settings { hide_label: true }` at the block level (a sibling of `viz:`) — and no other block setting.
* **Prefer the dataset's predefined metrics** over re-deriving equivalents.
* **Prose** that may contain apostrophes or span lines (viz labels, descriptions, DCB template text) goes in `@md … ;;` heredocs, not single quotes.
* **Layout is build-dashboard's job.** On a fresh build, supply only the blocks; build-dashboard positions them. When adding a block to an existing dashboard standalone, place it and recompute the canvas height (as build-dashboard-controls does for controls).
