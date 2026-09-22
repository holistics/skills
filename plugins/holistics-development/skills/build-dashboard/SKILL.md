---
name: build-dashboard
label: Build Dashboard
description: |-
  Build or edit a Holistics canvas dashboard (`page.aml` / a `Dashboard {}` object) — its blocks, layout, filter interactions, and theme.

  Use when building a dashboard or report page, adding or arranging blocks, or adding dashboard-level filters.

  Typical phrasings: build a dashboard for X, make a dashboard showing X, add a chart or KPI or table to a dashboard, add a filter or date control, add or edit a title or section header.

  Do NOT trigger for answering a data question on its own — a one-off query, chart, or analysis with no dashboard to put it on — or for editing models, datasets, or metric definitions, authoring a reusable custom chart type or theme object, or restyling a dashboard's look.
---

# Building a Dashboard (canvas dashboard / `page.aml`)

Build or edit a Holistics `page.aml` dashboard.

## What a good input looks like

A dashboard task is fully specified when you can answer all of the following:

1. **Audience & decision** — Who reads this dashboard, and what business decisions do they make with it?
2. **Primary user action** — What is the reader doing with the data?

   * *Monitoring* ("Is anything off?")
   * *Diagnosing* ("Why did it move?")
   * *Comparing* ("Which of these is performing better?")
   * *Planning* ("What should we do next?")
   * *Looking up* ("Find me a specific record.")

   Decide this first: it dictates the dashboard structure more than any other factor.
3. **Ranked questions** — What real-world questions does the audience ask, in what priority, and in their own words? Derive these from the audience, their decision, and the available dataset. *(For instance, a monitoring dashboard typically follows: Status → Trend → Drivers → Lookup. Diagnostic, comparative, or funnel dashboards follow entirely different rank orderings.)*
4. **Question requirements** — Which measures and dimensions answer each question? What comparison context is needed (e.g., vs. previous period, vs. target)?
5. **Time parameters** — What are the primary date fields, time grains, and date windows?
6. **Interactivity** — Which dimensions will users want to slice or filter by?
7. **Structure & presentation** — Should this be single-page or tabbed? Are there branding or visual guidelines?

When the user's prompt leaves gaps, fill them yourself based on the reader and dataset rather than defaulting to a generic design.

## What a bare minimum output looks like

The minimum requirement is a **quality standard, not a fixed layout**. A dashboard is a vertical stack of **sections**, ordered by your ranked questions.

* **Section composition** — A short heading (`TextBlock`) + a primary block that answers the section's question + 0–2 supporting blocks. Every section must answer a specific ranked question. If a block doesn't answer a user question, drop it.
* **Complete question coverage** — Ensure every ranked question is answered by a block. Quality is measured by questions answered, not block count.
* **Opening layout aligns with user action:**
  * *Monitoring* → KPI cards across the top.
  * *Diagnosing* → Prominent metric/driver visual that shifted.
  * *Comparing* → Comparison chart leading the page.
  * *Planning* → Target gap or projection view.
  * *Lookup* → Prominent filter controls and detail tables.

  *A KPI row is not the default opening; non-monitoring dashboards rarely need one, and detail tables should only be included when row-level lookup is explicitly required.*
* **Data-driven scope** — Use `fetch_dataset` to examine available fields and metrics. Let the user's ranked questions determine which metrics merit a section.
* **Proportional depth** — Broad requests require wider, shallower sections; narrow requests require deep, focused sections.
* **Real data & interactive controls** — Wire real fields and metrics. KPI comparisons must reference the dashboard's Period Comparison control rather than static values. Always wire dashboard controls explicitly and apply a theme (default: `theme: H.themes.classic`).
* **Grid layout** — Stack sections vertically by priority. Within each section, place 1–4 blocks per row (full-width for hero trends/tables; 2–3 columns for side-by-side comparisons). Maintain consistent grid alignment and sizing based on visual hierarchy. Each tab must be a self-contained canvas.

If the user gives a tight instruction ("just build one chart for X"), stick strictly to their scope, mention potential additions, and complete the request.

## Workflow

1. **Derive the spec and rank the sections.** Collect specs from the prompt and run `fetch_dataset` (identifying metrics, primary date fields, and low-cardinality dimensions for slicing). Identify the reader's primary action and rank their core questions. Map these questions directly to dashboard sections. Clarify only critical ambiguities with the user; make reasonable assumptions for everything else and document them.
2. **Propose and confirm.** Present a concise summary plan along with a 12-column grid wireframe detailing dataset references, ranked section questions, and filter controls:

   ````
   ## What's in the dashboard
   **For** — <audience> **doing** <monitoring | diagnosing | comparing | planning | looking something up>
   **Dataset** — @Dataset:<dataset_name>
   **Sections** — ordered by question hierarchy:
   - **<section>** — <question answered, in reader's words>
   **Controls** — date range and slicing dimensions:
   - <Filter label> — <target field/description>

   ```mermaid
   ---
   config:
     fontFamily: "Inter, ui-sans-serif, system-ui, sans-serif"
     htmlLabels: false
   ---
   block-beta
   columns 1
   block:frame
     columns 12
     b_title["Sales Overview"]:12
     f_date["Date Range"]:3 f_country["Office Country"]:3 c_pop["Compare To"]:3 space:3
     k_sales["Total Sales · KPI"]:3 k_orders["Orders · KPI"]:3 k_cust["Customers · KPI"]:3 space:3
     h_trend["How sales are moving"]:12
     v_trend["Monthly Sales Trend · Line"]:12
     h_where["Where it comes from"]:12
     v_country["Sales by Country · Bar"]:6 v_detail["Order Detail · Table"]:6
   end
   classDef board fill:none,stroke:#e3e7ed
   classDef sect fill:#ffffff,fill-opacity:0.6,stroke:none
   classDef ctrl fill:#f5f8fa,stroke:#cbd0d7
   classDef viz fill:#d1e5fa,stroke:#1b7ce4
   class frame board
   class b_title,h_trend,h_where sect
   class f_date,f_country,c_pop ctrl
   class k_sales,k_orders,k_cust,v_trend,v_country,v_detail viz
   ```
   ````

   * **Wireframe rules:** Enclose the layout in a `block:frame` container with `columns 12`. Set column spans to match canvas positions (`3` = ¼, `4` = ⅓, `6` = ½, `12` = full). Every row must sum to 12; use bare `space:<n>` blocks for padding. Apply styles using the exact `classDef` definitions (`sect` for text, `ctrl` for filters, `viz` for visualizations). Label blocks as `<name> · <VizType>`. For multi-tab layouts, provide a separate diagram per tab under `**Tab: <label>**`.

   Include actionable option links at the end of your proposal:

   ```
   Build this dashboard? 
   [Yes — build it as planned](#opt) 
   [<alternative instruction or adjustment>](#opt)
   ```

   Wait for user confirmation before building. Do not run queries or edit files until approved.
3. **Build the dashboard.** Follow the AML Schema. Create static text blocks (`TextBlock`) for titles and guidance. Generate visualization AML for data blocks rather than hand-writing them. Construct the layout using a `TabLayout` structure with `pos()` coordinates matched precisely to your approved wireframe.
4. **Wire controls and interactions.** Include the `explicit_interactions: []` block on every dashboard. Map each control (`FilterBlock`, `PopBlock`, `DateDrillBlock`) to its target visualization blocks and fields. Ensure interactive controls reach all relevant data blocks on their respective tabs.
5. **Verify output quality.** Confirm that every block answers a ranked question, opening blocks reflect the user's workflow, layout spans match the wireframe, control interactions are fully mapped, and no diagnostics errors exist.
6. **Deliver.** Provide a handoff summary containing the dataset used, block-to-question mappings, date field references, tab structures, and key design assumptions.

## Schema

A dashboard is defined as a `Dashboard <uname> { … }` object containing block declarations, filter interactions, and layout positioning. Use only dataset, model, and field names verified via `fetch_dataset`.

### Block types

* **VizBlock** — Contains a visualization (`viz: <VizObject>`). Use `settings { hide_label: true }` on KPI blocks where the visual already displays the metric title.
* **TextBlock** — Static text, markdown, or custom HTML (`content: @md … ;;`).
* **FilterBlock** — Interactive filter control. Set `type:` (`'field' | 'text' | 'number' | 'date' | 'truefalse'`) and configure `source: FieldFilterSource { dataset field }`. Do not set a `default` property, as defaults hide unselected data on initial load.
* **PopBlock & DateDrillBlock** — Controls for Period-over-Period comparisons and date granularity switching.

### Field references inside a viz (the #1 source of errors)

Use the correct `ref:` syntax based on the field type:

* **Model field / dimension:** `r(<model>.<field>)`
* **Dataset metric:** `r(<dataset>.<metric>)`
* **Dataset dimension (two-argument):** `r(<dataset>, <model>.<dimension>)`
* **Ad-hoc calculation (defined in viz):** Use the string alias directly (`ref: 'total_sales'`), not `r()`.

### The dashboard — worked example

```aml
Dashboard sales_overview {
  title: 'Sales Overview'
  theme: H.themes.classic
  settings { timezone: 'Asia/Ho_Chi_Minh' autorun: true cache_duration: 3600 }

  // ---- BLOCKS DECLARATION
  block b_title: TextBlock { content: @md # Sales Overview ;; }

  block f_date: FilterBlock {
    label: 'Date Range'
    type: 'date'
    source: FieldFilterSource { dataset: car_retails field: r(car_retails_payments.payment_date) }
  }
  block f_country: FilterBlock {
    label: 'Office Country'
    type: 'field'
    source: FieldFilterSource { dataset: car_retails field: r(car_retails_offices.country) }
  }
  block c_pop: PopBlock { label: 'Compare To' }

  block v_total_sales: VizBlock {
    label: 'Total Sales'
    settings { hide_label: true }
    viz: MetricKpi { … }
  }
  block v_orders: VizBlock { label: 'Orders' settings { hide_label: true } viz: MetricKpi { … } }
  block v_customers: VizBlock { label: 'Customers' settings { hide_label: true } viz: MetricKpi { … } }

  block h_trend: TextBlock { content: @md ## How sales are moving ;; }
  block v_monthly_sales: VizBlock {
    label: 'Monthly Sales Trend'
    viz: LineChart {
      dataset: car_retails
      calculation avg_order { formula: @aql car_retails_orders | average(...) ;; calc_type: 'measure' data_type: 'number' }
      x_axis: VizFieldFull {
        ref: r(car_retails_payments.payment_date)
        transformation: 'datetrunc month'
        format { type: 'date' pattern: 'LLL yyyy' }
      }
      y_axis {
        series { field: VizFieldFull { ref: r(car_retails.total_sales) } }
        series { field: VizFieldFull { ref: 'avg_order' } }
      }
      settings { row_limit: 100 show_data_points: true }
    }
  }

  block h_where: TextBlock { content: @md ## Where it comes from ;; }
  block v_by_country: VizBlock { label: 'Sales by Country' viz: BarChart { … } }
  block v_detail: VizBlock { label: 'Order Detail' viz: DataTable { … } }

  // ---- INTERACTIONS
  explicit_interactions: [
    FilterInteraction {
      from: 'f_date'
      to: ['v_total_sales', 'v_orders', 'v_customers', 'v_monthly_sales', 'v_by_country', 'v_detail']
      field: r(car_retails_payments.payment_date)
    },
    FilterInteraction {
      from: 'f_country'
      to: ['v_total_sales', 'v_orders', 'v_customers', 'v_monthly_sales', 'v_by_country', 'v_detail']
      field: r(car_retails_offices.country)
    },
    PopInteraction {
      from: 'c_pop'
      to: ['v_total_sales', 'v_orders', 'v_customers', 'v_monthly_sales']
      field: r(car_retails_payments.payment_date)
    }
  ]

  // ---- VIEW LAYOUT
  view: TabLayout {
    tab main: CanvasLayout {
      label: 'Overview'
      width: 1220
      height: 1440
      grid_size: 20
      auto_expand_vertically: true

      block b_title       { position: pos(20, 20, 1180, 100) layer: 1 }
      block f_date        { position: pos(20, 140, 280, 100) layer: 1 }
      block f_country     { position: pos(320, 140, 280, 100) layer: 1 }
      block c_pop         { position: pos(620, 140, 280, 100) layer: 1 }
      block v_total_sales { position: pos(20, 260, 280, 120) layer: 1 }
      block v_orders      { position: pos(320, 260, 280, 120) layer: 1 }
      block v_customers   { position: pos(620, 260, 280, 120) layer: 1 }
      block h_trend       { position: pos(20, 400, 1180, 100) layer: 1 }
      block v_monthly_sales { position: pos(20, 520, 1180, 400) layer: 1 }
      block h_where       { position: pos(20, 940, 1180, 100) layer: 1 }
      block v_by_country  { position: pos(20, 1060, 580, 360) layer: 1 }
      block v_detail      { position: pos(620, 1060, 580, 360) layer: 1 }
      mobile { mode: 'auto' }
    }
  }
}
```

### Text blocks — the dashboard's words

Use `TextBlock` components for titles, subtitles, section headings, explanatory notes, metric definitions, and user documentation.

```aml
block <x>: TextBlock { content: @md ## Section heading ;; }
```

When a block displays dynamic, real-time data values, use a data visualization block (`MetricKpi` or standard chart) instead of a `TextBlock`.

## Conventions

* **Stick to supported AML syntax.** Use standard layout properties (`Dashboard`, `block`, `explicit_interactions`, `settings`, `theme`, `view` / `TabLayout` / `CanvasLayout`, `position: pos()`, `layer`, `mobile`). Spacing and gaps are managed using `pos()` coordinates.
* **Avoid mixing interaction formats.** Do not combine `explicit_interactions: []` with legacy `interactions: []` or `CustomMapping`. If updating a legacy dashboard, convert all controls and interactions to the `explicit_interactions` structure.
* **Prefer generated visualizations.** Rely on tool-generated visualization AML rather than manually coding viz blocks to minimize syntax errors.
* **Use global controls over per-chart filters.** Let dashboard-level filters control time ranges, grains, and segments across charts. Use chart-specific filters only for core chart definitions (e.g., Top 10 lists).
* **Format text strings cleanly.** Use `@md … ;;` heredocs for multiline content or strings containing special characters and apostrophes. Write clear descriptions and titles aimed at end users.
* **Maintain consistent file structure.** Save dashboard files in the specified project directory (defaulting to `dashboards/`).
