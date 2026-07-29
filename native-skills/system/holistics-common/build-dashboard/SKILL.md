---
name: build-dashboard
description: Build or edit a Holistics canvas dashboard in AML (a `page.aml` file / `Dashboard {}` object) — assemble viz, text, and control blocks, lay them out, wire filter interactions, and set the theme. Use whenever you need to build a dashboard or report page, add or arrange blocks, edit a dashboard's text or section structure, or add dashboard-level filters. Typical phrasings: build a dashboard for X, create a new report page, make a dashboard showing X, add a chart or KPI or table to a dashboard, add a filter or date control, add a title or section header, edit the dashboard's intro text. Do NOT trigger for answering a data question on its own — a one-off query, chart, or analysis with no dashboard to put it on — or for editing models, datasets, or metric definitions, authoring a reusable custom chart type or a theme object, or restyling an existing dashboard's look.
---

# Building a Dashboard (canvas dashboard / `page.aml`)

Build or edit a Holistics `page.aml` dashboard.

## What a good input looks like

A dashboard task is fully specified when you can answer all of:

1. **Audience & decision** — who reads this, and what do they decide with it?
2. **What the reader is doing with it** — monitoring ("is anything off?"), diagnosing ("why did it move?"), comparing ("which of these is doing better?"), planning ("what should we do next?"), or looking something up ("find me the record"). Decide this before anything else: it drives the dashboard's shape more than any other answer.
3. **Questions, ranked** — the real questions this audience asks, in the order they ask them, in their words. Derive them from the audience, the decision, and what the dataset can actually answer. *(A performance-monitoring dashboard commonly lands on status → trend → drivers → lookup. That is one pattern, not the definition — a diagnostic, a comparison, a funnel, or a lookup tool ranks differently, and many have no "how are we doing" question at all.)*
4. **What each question needs** — the measures and dimensions that answer it, and, for a measure that has one, its comparison context (vs previous period, vs target).
5. **Time** — the primary date field, grain, and window that matter.
6. **Interactivity** — what viewers will want to slice by themselves.
7. **Structure & look** — one page or sections/tabs; any branding.

The user's prompt almost never supplies all of this. Your job is to fill the gaps yourself — not to build less because less was specified. Filling a gap means deciding it for *this* reader and *this* dataset, not falling back on a default arrangement.

## What a bare minimum output looks like

The minimum is a **quality bar, not a shape**. A dashboard is a vertical stack of **sections**; which sections, and in what order, comes from the questions you ranked.

* **A section** = a short heading (TextBlock) + the block that answers its question + 0–2 supporting blocks. Each section answers one question you actually ranked — if you can't name a section's question in the reader's words, cut it.
* **Every ranked question is answered by some block, and no block answers none.** Completeness is measured in questions covered, not blocks placed: a generic prompt still gets every question answered, not a sketch — and nothing beyond them.
* **The opening follows what the reader is doing.** Monitoring → a few KPIs across the top. Diagnosing → the thing that moved, large, with its drivers beneath it. Comparing → the comparison itself leading. Planning → the projection or the gap to target. Looking something up → the filters and the table, and little else. **A KPI row is one opening among these, not the default** — a dashboard that isn't for monitoring often has no KPI row at all, and a trailing detail table is worth placing only when someone actually needs the rows.
* **The dataset says what can be answered; the questions say what is.** Read the major subjects/metrics from `fetch_dataset` to find the real fields and the candidate material — then let the ranked questions decide which of it earns a section. One section per dataset subject is a template too.
* **Depth follows the ask.** A broad ask spreads across more sections, each shallow; a focused ask goes deep on one or two and drops the rest. Section count follows the ask's breadth and the dataset's richness.
* **Every block renders real data on real fields**; a KPI's comparison comes from the Period Comparison control, not baked in. The dashboard has wired **controls** — never left on platform defaults — and a **theme** (default `theme: H.themes.classic`). Data with no wired controls is below the minimum.
* **Layout** — sections stack top-to-bottom by importance; within a section, blocks sit in a row of **1–4** (full-width for a hero trend/table, 2–3 side by side for comparisons), aligned to the grid and sized by importance. Per tab, each tab is its own coherent canvas, never a dumping ground; a single-page dashboard is one tab. *(width / `grid_size` / `pos()` mechanics are in the Schema.)*

When the user is specific ("just one chart of X"), their scope wins — build that, note what you'd add, and move on.

**Two dashboards for different jobs should not come out the same shape.** If the one you are about to build would look the same on any dataset with any reader, you defaulted instead of deciding — go back to what the reader is doing and re-derive the opening.

## Workflow

1. **Derive the spec, then the sections** (fill "What a good input looks like", in this order): from the prompt → from the dataset (call `fetch_dataset` — predefined metrics first, then date fields, then low-cardinality descriptive dimensions as breakdown/filter candidates). Name **what the reader is doing** and **rank their questions** before you think about blocks — those two answers decide the dashboard's opening and its order, and skipping them is what makes every dashboard come out the same. Then turn the ranked questions into **sections**, using the dataset's subjects/metrics as the material that answers them (see *What a bare minimum output looks like*), and set each section's depth by the ask's breadth. Ask at most one short round, and only for what is genuinely undecidable; decide everything else and state every assumption.
2. **Propose and confirm (text).** Present a short text plan and get the user's OK before building — group blocks by role, name the dataset with its `@Dataset:` reference, list each control in plain terms (what viewers can slice by), and describe the layout at a high level (the sections top-to-bottom, and any tabs). Proceed on approval or no objection; if the response is ambiguous, ask once.

   ```
   ## What's in the dashboard
   **For** — <who reads it> **doing** <monitoring | diagnosing | comparing | planning | looking something up>
   **Dataset** — @Dataset:<dataset_name>
   **Sections** — in the order the reader asks them; each answers one question
   - **<section>** — <the question this section answers, in the reader's words>
     - <block name> — <VizType> — <its role in the section>
   **Controls** — a date range plus 1–2 things viewers can slice by
   - <Filter label> — <what it filters, in plain words>
   **Layout** — the sections top-to-bottom by importance (and any tabs)
   ```

3. **Build the dashboard** per Schema. Author the **static text** blocks yourself (titles, section intros, how-to-read notes). For each **data** block, generate the viz and put the returned AML in the block; hand-write a `viz: <Type> { … }` body only as a last resort, because hand-written viz AML is the single biggest source of invalid output (if you must, the `ref:` forms in the Schema are where it breaks). Then lay everything out — the view is always a TabLayout: one tab for a single-page dashboard, or blocks partitioned across tabs, each tab's canvas built the same way with a control row reserved at the top.
4. **Wire the controls and the `interactions: []` array.** Every dashboard needs it — not only to connect the controls but because viz blocks cross-filter each other by default. Build the control set the job needs (a date range + 1–2 dimension filters at minimum; add a date drill or Period Comparison when the questions call for one), then wire each control to every block it can affect, disable filter→filter cross-linking, and disable everything that would cross a tab boundary.
5. **Verify against the minimum output.** Every block answers a ranked question (cut any that can't); the opening block matches what the reader is doing, and you can say why this dashboard's shape would be wrong for a different reader — if you can't, you defaulted; each KPI's comparison comes from the dashboard's Period Comparison control, not a period baked into the KPI; block bodies are sound, styling-free, and **carry no filters of their own** — no per-block date window or comparison, since the date filter and Period Comparison provide them; every block declared is placed in the view; the `interactions: []` array is present and complete — every control wired to every block it can affect (each filter to every block on its dataset or disabled; Period Comparison to the KPIs, not just the trend), cross-tab cross-filtering disabled; then check code diagnostics and fix every error.
6. **Deliver** with a handoff note — dataset used; each block name + viz type + the question it answers; which blocks carry date fields (with the field reference); tab membership if tabbed; and the assumptions you made.

## Schema

A dashboard is a `Dashboard <uname> { … }` object: you **declare blocks**, wire **interactions**, and place every block in the **view**. A block that isn't placed in the view is not shown. Never invent a dataset, model, or field name — use only ones you confirmed via `fetch_dataset` or the provided context.

### Block types

* **VizBlock** — `viz: <a Viz object>`; the main content block (chart, table, KPI, dynamic content). Block-level `settings { hide_label: true }` hides the block's own label — use it on KPIs, whose viz already prints the label.
* **TextBlock** — `content: @md … ;;`; static markdown/HTML/CSS. See *Text blocks* below.
* **FilterBlock** — a dashboard-level control. `type:` is one of `'field' | 'text' | 'number' | 'date' | 'truefalse'`; a field filter takes `source: FieldFilterSource { dataset field }`. **Never give a FilterBlock a `default`** — a default silently hides rows on load.
* **PopBlock** (period-over-period / Period Comparison) and **DateDrillBlock** (date granularity) — same block shape; add when the dashboard's questions need a comparison or a switchable grain.

### Field references inside a viz (the #1 source of errors)

`ref:` takes a different form depending on what you are pointing at:

* **model field / dimension** → `r(<model>.<field>)`
* **dataset metric** → `r(<dataset>.<metric>)`
* **dataset dimension** (two-arg) → `r(<dataset>, <model>.<dimension>)`
* **an adhoc `calculation` defined inside the viz** → its **bare string name**, not `r()` — e.g. `ref: 'total_sales'`

### The dashboard — worked example (this is the complete layout vocabulary)

Copy the vocabulary here, not the arrangement — this one is a monitoring dashboard.

```aml
Dashboard sales_overview {
  title: 'Sales Overview'
  theme: H.themes.classic                    // default; build-dashboard-theme for real branding
  settings { timezone: 'Asia/Ho_Chi_Minh' autorun: true cache_duration: 3600 }   // all optional

  // ---- BLOCKS: declared once here, by name. Positions live in the view, never here.
  block b_title: TextBlock { content: @md # Sales Overview ;; }

  block f_date: FilterBlock {                // the date range — sets the time window for the whole page
    label: 'Date Range'
    type: 'date'
    source: FieldFilterSource { dataset: car_retails field: r(car_retails_payments.payment_date) }
  }
  block f_country: FilterBlock {             // 1–2 dimension filters — what viewers slice by
    label: 'Office Country'
    type: 'field'
    source: FieldFilterSource { dataset: car_retails field: r(car_retails_offices.country) }
  }                                          // no `default {}` — a default hides rows on load
  block c_pop: PopBlock { label: 'Compare To' }   // Period Comparison — the KPIs' comparison comes from HERE

  block v_total_sales: VizBlock {
    label: 'Total Sales'
    settings { hide_label: true }
    viz: MetricKpi { … }                     // the generated viz AML
  }
  block v_orders: VizBlock { label: 'Orders' settings { hide_label: true } viz: MetricKpi { … } }
  block v_customers: VizBlock { label: 'Customers' settings { hide_label: true } viz: MetricKpi { … } }

  block h_trend: TextBlock { content: @md ## How sales are moving ;; }
  block v_monthly_sales: VizBlock {          // hand-written body — LAST RESORT; note each ref: form
    label: 'Monthly Sales Trend'
    viz: LineChart {
      dataset: car_retails
      calculation avg_order { formula: @aql car_retails_orders | average(...) ;; calc_type: 'measure' data_type: 'number' }
      x_axis: VizFieldFull {
        ref: r(car_retails_payments.payment_date)      // model field
        transformation: 'datetrunc month'
        format { type: 'date' pattern: 'LLL yyyy' }
      }
      y_axis {
        series { field: VizFieldFull { ref: r(car_retails.total_sales) } }   // dataset metric
        series { field: VizFieldFull { ref: 'avg_order' } }                  // adhoc calculation: bare name
      }
      settings { row_limit: 100 show_data_points: true }
    }
  }                                          // NO viz-level `filter` — f_date and c_pop provide the window and the comparison

  block h_where: TextBlock { content: @md ## Where it comes from ;; }
  block v_by_country: VizBlock { label: 'Sales by Country' viz: BarChart { … } }
  block v_detail:     VizBlock { label: 'Order Detail' viz: DataTable { … } }

  // ---- INTERACTIONS: always present. Two kinds of disable live here:
  //   • ALWAYS (single-page too): filter → filter — each filter disables every OTHER filter block,
  //     so choosing a value in one doesn't narrow another's options.
  //   • TABBED only: nothing crosses a tab boundary — each filter / drill / pop / viz also disables
  //     every block on the other tab(s). Omit these lines on a single-page dashboard.
  interactions: [
    FilterInteraction {
      from: 'f_country'
      to: [
        CustomMapping { block: 'v_monthly_sales' field: r(car_retails_offices.country) },   // map EVERY block it can affect
        CustomMapping { block: ['v_by_country', 'v_detail'] field: r(car_retails_offices.country) },
        CustomMapping { block: ['f_date'] disabled: true },                                 // parent-child — ALWAYS
        CustomMapping { block: ['<other_tab_viz>'] disabled: true }                         // TABBED only
      ]
    },
    DateDrillInteraction {
      from: '<drill>'
      to: [ CustomMapping { block: 'v_monthly_sales' field: r(car_retails_payments.payment_date) } ]
    },
    PopInteraction {
      from: 'c_pop'
      to: [
        // model.field ref — NOT ref('<dataset>', …). PoP maps to the KPIs too, not only the trend.
        CustomMapping { block: ['v_total_sales', 'v_orders', 'v_customers'] field: r(car_retails_payments.payment_date) },
        CustomMapping { block: 'v_monthly_sales' field: r(car_retails_payments.payment_date) }
      ]
    },
    // TABBED viz cross-filtering off too: for EVERY viz block, a FilterInteraction disabling EVERY
    // viz block on the other tab(s). Symmetric — repeat per viz block.
    FilterInteraction {
      from: '<tab_a_viz>'
      to: [ CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true } ]
    }
  ]

  // ---- VIEW: ALWAYS a TabLayout of CANVASES; each tab IS a canvas. SINGLE-PAGE = one tab.
  // A canvas carries each block's position + layer, never its body, and its coordinates restart at (20, 20).
  view: TabLayout {
    tab main: CanvasLayout {
      label: 'Overview'                      // tab title
      width: 1220                            // 12-col grid, 80px cols · spans: ¼ 280 · ⅓ 380 · ½ 580 · full 1180
      height: 1000                           // tallest block's bottom + 20
      grid_size: 20                          // legal: 5 | 10 | 15 | 20 | 25 — use 20; spacing is pos()-driven:
                                             // first block at 20, steps of 20, last ends at width - 20
      auto_expand_vertically: true
      // HEIGHT — give text blocks, MetricKpi, and control blocks (filter/drill/pop) a pos() height of
      // AT LEAST 100 (more when the content needs it): each renders taller than a naive estimate, so a
      // shorter height clips the content or forces an inner scrollbar. Charts scale to their box — size
      // those by importance.
      block b_title    { position: pos(20, 20, 1180, 100) layer: 1 }    // full-width title
      block f_date     { position: pos(20, 140, 280, 100) layer: 1 }    // control row across the top
      block f_country  { position: pos(320, 140, 280, 100) layer: 1 }
      block c_pop      { position: pos(620, 140, 280, 100) layer: 1 }
      block v_total_sales { position: pos(20, 260, 280, 120) layer: 1 } // KPI row: x 20 / 320 / 620 / 920
      block v_orders      { position: pos(320, 260, 280, 120) layer: 1 }
      block v_customers   { position: pos(620, 260, 280, 120) layer: 1 }
      block h_trend    { position: pos(20, 400, 1180, 100) layer: 1 }   // section heading
      block v_monthly_sales { position: pos(20, 520, 1180, 400) layer: 1 }  // hero; ends at 1200 = width - 20
      block h_where    { position: pos(20, 940, 1180, 100) layer: 1 }
      block v_by_country { position: pos(20, 1060, 580, 360) layer: 1 } // ½ + ½ side by side
      block v_detail     { position: pos(620, 1060, 580, 360) layer: 1 }
      mobile { mode: 'auto' }
    }

    // MULTI-TAB — add more `tab <x>: CanvasLayout { … }`, each built exactly like the tab above
    // (coordinates restart at 20,20 per tab). Partition the blocks; each tab is coherent on its own.
    tab detail: CanvasLayout {
      label: 'Detail'
      width: 1220
      height: 460
      grid_size: 20
      block <other_viz> { position: pos(20, 20, 1180, 400) layer: 1 }
    }
  }
}
```

### Text blocks — the dashboard's words

`TextBlock` carries the title + subtitle, section headings/intros, dividers, and **how-to-read notes** (what a metric means, how to filter, caveats). Good analytics is explained, not just plotted — reach for a text block whenever the dashboard needs guidance, not only charts.

```aml
block <x>: TextBlock { content: @md ## Section heading ;; }   // static markdown / HTML / CSS
```

The instant a block must show a *live data value* it is not a TextBlock — that's a data block (a MetricKpi or a dynamic content block).

## Conventions

* **The Schema above is the complete layout vocabulary** (`Dashboard`, `block`, `interactions`, `settings`, `theme`, `view` / `TabLayout` / `CanvasLayout`, `position: pos()`, `layer`, `mobile`). Use only the properties and constructs shown — never guess or invent one (e.g. there is no layout `margin`/`padding`/`gap`; spacing is pos()-driven). A bare top-level `view: CanvasLayout` and a `LinearLayout` are also valid AML, but this skill always wraps the canvas in a TabLayout for uniformity. If you believe you need something not shown here, confirm it with `search_docs` first.
* **Prefer a generated viz over a hand-written one** — hand-written viz AML is the biggest source of invalid output.
* **A chart doesn't filter itself; the dashboard's controls do.** The date filter sets the time window, Period Comparison the comparison period, the drill the grain, dimension filters the segmenting. Strip any viz-level `filter` and any baked-in period.
* Prose strings that may contain apostrophes or span lines (the dashboard `description`, TextBlock content, title subtitle) go in `@md … ;;` heredocs, not single quotes.
* Write the dashboard `description` and title subtitle for end users in plain language — not for analysts, not technical.
* **File placement:** decide the target folder once — the user's stated location, or `dashboards/` by default — and keep it for the whole conversation. Never switch folders because an example file you read lives elsewhere.
