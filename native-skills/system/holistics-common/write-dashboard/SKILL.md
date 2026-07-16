---
name: write-dashboard
description: Write or edit a Holistics canvas dashboard in AML (a `.page.aml` file / `Dashboard {}` object) — assemble viz/text/filter blocks, lay them out, wire filter interactions, and set the theme. Use this whenever you need to build a dashboard, add/arrange blocks, or add dashboard-level filters.
---

# Writing a Dashboard (canvas dashboard / `page.aml`)

A dashboard is a `Dashboard <uname> { ... }` object. You declare **blocks** (viz, text, filters), place
them in a **view** (layout), and optionally wire **interactions** (a filter block driving vizzes).

```
Dashboard <uname> {
  title: 'Human title'
  block <block_uname>: <BlockType> { ... }   // one per block; block_uname must be unique
  ...more blocks...
  interactions: [ ... ]                       // optional: filter/pop/date-drill → target blocks
  view: <Layout> { ... }                      // where each block appears
  settings { ... }                            // optional: timezone, cache, autorun
  theme: H.themes.<name>                       // optional
}
```

Rules of thumb:
* Every block that should appear must be **referenced by its uname in the `view`** — a block not placed in the view is not shown.
* Prefer the **smallest set of blocks** that answers the question; give each a clear `label`.
* Do NOT invent dataset/model/field names — use ones you have confirmed (via tools or provided context).

## Blocks

`block <uname>: <Type> { ... }`. Types:

* **VizBlock** — `viz: <a Viz object>` (a chart/table/KPI). This is the main content block.
  ```
  block v_sales: VizBlock {
    label: 'Monthly sales'
    viz: LineChart { dataset: car_retails ... }   // see "Reusing a generated viz" below
  }
  ```
* **TextBlock** — markdown content: `content: @md # My heading ;;` (note the `@md ... ;;` heredoc).
* **FilterBlock** — a dashboard-level control:
  ```
  block f_country: FilterBlock {
    label: 'Country'
    type: 'field'                                  // 'field' | 'text' | 'number' | 'date' | 'truefalse'
    source: FieldFilterSource { dataset: car_retails field: r(car_retails_offices.country) }
    default { operator: 'is' value: [] }
  }
  ```
* **PopBlock** (period-over-period) and **DateDrillBlock** (date granularity) — similar shape; add only when asked.

### Reusing a generated viz (preferred)
If you already produced a visualization for this data, reference the stored artifact instead of
re-writing its AML — set the block's `viz:` value to the artifact ref you got back:
```
block v_sales: VizBlock { label: 'Monthly sales' viz: @Context:Viz:<id> }
```
The referenced viz (and its dataset) is inlined for you. Only hand-write the `viz: <Type> { ... }` when
you don't have a generated one to reuse.

## Field references inside a viz (common source of errors)
When you DO hand-write viz fields, `ref:` uses different forms depending on what you reference:
* **Model field / dimension** → `r(model_name.field_name)` — e.g. `r(car_retails_offices.country)`
* **Dataset metric** → `r(dataset_name.metric_name)` — e.g. `r(car_retails.total_sales)`
* **Dataset dimension** (two-arg) → `r(dataset_name, model_name.dimension_name)`
* **Adhoc `calculation` defined in the viz** → its **bare string name**, NOT `r()` — e.g. `ref: 'avg_payment'`

## Layout (`view`)
* **CanvasLayout** — free positioning on a grid. Each block gets `position: pos(x, y, w, h)` (grid units).
  Set `grid_size` (5/10/15/20/25), `width`, `height`; `auto_expand_vertically: true` is handy.
* **LinearLayout** — stacked top-to-bottom: just `block <uname>` entries, no positions.
* **TabLayout** — `tab <uname>: CanvasLayout | LinearLayout { ... }` per tab.

Use CanvasLayout for most dashboards. Place filters/titles at the top, KPIs in a row, charts below.

## Interactions (optional)
Wire a filter/pop/date-drill block to the vizzes it should control:
```
interactions: [
  FilterInteraction { from: 'f_country' to: [ CustomMapping { block: ['v_sales', 'v_2c7f'] } ] }
]
```

## Settings (optional)
`settings { timezone: 'Asia/Ho_Chi_Minh' autorun: true cache_duration: 3600 }`

---

## Full example (trimmed)
A canvas dashboard: a title, two KPIs, a chart, a table, an office-country filter wired to the charts,
laid out on a canvas.

```aml
Dashboard sales_overview {
  title: 'Sales Overview'

  block title: TextBlock {
    content: @md # Sales Overview ;;
  }

  block v_total_sales: VizBlock {
    label: 'Total Sales'
    settings { hide_label: true }
    viz: MetricKpi {
      dataset: car_retails
      calculation total_sales_amount {
        formula: @aql car_retails_payments | sum(car_retails_payments.amount) ;;
        calc_type: 'measure'
        data_type: 'number'
      }
      value: VizFieldFull {
        ref: 'total_sales_amount'                 // bare name: it's an adhoc calculation
        format { type: 'number' pattern: '#,###0.00' }
      }
      settings { display_mode: 'single' alignment: 'center' }
    }
  }

  block v_unique_customers: VizBlock {
    label: 'Unique Customers'
    settings { hide_label: true }
    viz: MetricKpi {
      dataset: car_retails
      value: VizFieldFull {
        ref: r(car_retails.unique_customers)      // dataset metric
        format { type: 'number' pattern: '#,###' }
      }
      settings { display_mode: 'single' alignment: 'center' }
    }
  }

  block v_monthly_sales: VizBlock {
    label: 'Monthly Sales Trend'
    viz: LineChart {
      dataset: car_retails
      x_axis: VizFieldFull {
        ref: r(car_retails_payments.payment_date) // model field
        transformation: 'datetrunc month'
        format { type: 'date' pattern: 'LLL yyyy' }
      }
      y_axis {
        series {
          field: VizFieldFull {
            ref: r(car_retails.total_sales)
            format { type: 'number' pattern: '#,###0.00' }
          }
        }
      }
      settings { row_limit: 100 show_data_points: true }
    }
  }

  block v_by_country: VizBlock {
    label: 'Sales by Country'
    viz: DataTable {
      dataset: car_retails
      fields: [
        VizFieldFull { ref: r(car_retails_offices.country) format { type: 'text' } },
        VizFieldFull { ref: r(car_retails.total_sales) format { type: 'number' pattern: '#,###0.00' } }
      ]
      settings { row_limit: 5000 }
    }
  }

  block f_country: FilterBlock {
    label: 'Office Country'
    type: 'field'
    source: FieldFilterSource { dataset: car_retails field: r(car_retails_offices.country) }
    default { operator: 'is' value: [] }
  }

  interactions: [
    FilterInteraction {
      from: 'f_country'
      to: [ CustomMapping { block: ['v_monthly_sales', 'v_by_country'] } ]
    }
  ]

  view: CanvasLayout {
    width: 1300
    height: 720
    grid_size: 20
    auto_expand_vertically: true
    block f_country { position: pos(20, 20, 400, 60) }
    block title { position: pos(20, 100, 1260, 60) }
    block v_total_sales { position: pos(20, 180, 400, 120) }
    block v_unique_customers { position: pos(440, 180, 400, 120) }
    block v_monthly_sales { position: pos(20, 320, 820, 300) }
    block v_by_country { position: pos(860, 180, 420, 440) }
    mobile { mode: 'auto' }
  }

  theme: H.themes.vanilla
}
```
