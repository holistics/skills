# DAX → AQL pattern catalogue

For every translation, feed the DAX, the source model schema, and the intent to `generate_aql`; do not hand-write AQL. The snippets below show the target shape for review — the actual function names and operators must be confirmed via `search_docs` or `validate_aql`.

**Before writing or reviewing any AQL, read these references:**

- [AQL function reference](https://docs.holistics.io/reference/aql/functions.md) — canonical list of every AQL function and its signature.
- [AQL operator reference](https://docs.holistics.io/reference/aql/operators.md) — pipe, comparison, logical, and arithmetic operators.
- [AQL error reference](https://docs.holistics.io/docs/reference/aql/error-reference.md) — every validation/runtime error and how to fix it.

## Mental model

DAX measures live inside an **implicit filter context** that the surrounding visual mutates with `CALCULATE`. AQL metrics live inside an **explicit metric context**: the dimensions, filters, relationships, and time window of the surrounding query. The "advanced" parts of AQL are mostly about _overriding_ one piece of that context. Read the docs first: [AQL vs SQL](https://docs.holistics.io/docs/as-code/aql/aql-vs-sql), [Learn AQL in 30 minutes](https://docs.holistics.io/docs/as-code/aql/learn-in-30-minutes), [Order of operations](https://docs.holistics.io/docs/as-code/aql/order-of-operations).

| DAX                                                         | AQL                                                                                                                                                          |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Filter context modifies the current evaluation environment. | Metric context = surrounding dimensions + filters + relationships + time window. Override one piece at a time.                                               |
| `[Measure]` re-evaluates inside `CALCULATE`.                | Pipe `\|` chains operations left-to-right: `x \| f(args)` is `f(x, args)`. Override context with `where`, `with_relationships`, `relative_period`, `of_all`. |
| Filter dropped via `ALL(table)`                             | `metric \| of_all(<dimension>)` drops _just that dimension_ from the metric's context.                                                                       |
| Row context comes from iterators (`SUMX`, `AVERAGEX`).      | Pass the row expression directly: `sum(sales, sales.qty * sales.price)`. Or push the arithmetic into a dimension.                                            |
| `VAR x = … RETURN …`                                        | Define reusable `metric` blocks and compose them; downstream metrics auto-update when the upstream definition changes.                                       |
| Filter on a table vs filter on a measure                    | `filter()` narrows a model before aggregation (SQL `WHERE`). `where()` rides with a metric and lands at step 7 of the pipeline.                              |

## AQL execution order

Every AQL query runs through this 7-step pipeline. Most surprises (and most parity bugs vs DAX) come from steps 3 and 4. See [Order of operations](https://docs.holistics.io/docs/as-code/aql/order-of-operations) for the full worked example.

1. **Create model CTEs.** Each referenced model becomes a CTE.
2. **Apply query params** (for query models only).
3. **Execute AQL dimensions.** Window-function dimensions (`rank`, `ntile`, `previous`, …) evaluate here, _before_ any report filter — so a `rank` dimension on `orders` ranks across all orders, not just the rows the report shows.
4. **Drop filters on excluded dimensions.** If a metric uses `of_all(<dim>)`, any report filter on `<dim>` is dropped _for that metric_. This is what makes "percent of total" work — and what makes "filter Merchant, see categories with no merchant" happen.
5. **Apply filters to non-excluded dimensions.**
6. **Execute aggregations and metric logic.**
7. **Apply filters on measures/metrics.** A filter placed on a metric (not a dimension) lands here, after both branches have computed.

### Practical implications

| Symptom                                                                 | Cause                                                                              | Fix                                                                                                                        |
| ----------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Filtering a dim, but rows still appear with `null` for that dim         | Metric uses `of_all(<that_dim>)`; step 4 drops the filter for it.                  | Filter on a _metric_ (lands at step 7), or wrap with `case(when: <filter>, then: <metric>, else: null)`.                   |
| `rank` dim returns non-consecutive numbers (e.g. 145, 203) under filter | Window in dim runs at step 3, before step-5 filter.                                | Push the filter into the metric and `dimensionalize(...)`, or wrap in `case(when: <filter>, then: rank(...), else: null)`. |
| Metric matches DAX without filters but diverges once a slicer is added  | Either step 4 (filter dropped via `of_all`) or step 5 (relationship path differs). | Compare compiled SQL via Holistics query preview; check `of_all` / `with_relationships` use.                               |

## Aggregations

| DAX                                                 | AQL                                                            |
| --------------------------------------------------- | -------------------------------------------------------------- |
| `Total Sales = SUM(Sales[Amount])`                  | `metric total_sales { definition: @aql sum(sales.amount) ;; }` |
| `Order Count = COUNTROWS(Orders)`                   | `count(orders.id)`                                             |
| `Customer Count = DISTINCTCOUNT(Sales[CustomerID])` | `count_distinct(sales.customer_id)`                            |
| `Avg Deal = AVERAGE(Sales[DealValue])`              | `avg(sales.deal_value)`                                        |

## Safe division

```dax
Profit Margin = DIVIDE([Profit], [Revenue])
```

```aml
metric profit_margin {
  type: 'number'
  definition: @aql safe_divide(sales.profit, sales.revenue) ;;
}
```

## Filtered measure (CALCULATE + simple predicate)

```dax
High Value Sales =
CALCULATE([Total Sales], Sales[OrderValue] > 1000)
```

```aml
metric high_value_sales {
  definition: @aql
    total_sales | where(@aql sales.order_value > 1000)
  ;;
}
```

## Year-over-year (canonical)

```dax
Sales YoY =
VAR CurrentSales = [Total Sales]
VAR PriorSales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))
RETURN DIVIDE(CurrentSales - PriorSales, PriorSales)
```

```aml
metric sales_last_year {
  label: 'Sales Last Year'
  type: 'number'
  definition: @aql
    total_sales | relative_period(orders.created_at, interval(-1 year))
  ;;
}

metric sales_yoy {
  label: 'Sales YoY % Change'
  type: 'number'
  definition: @aql
    safe_divide((total_sales - sales_last_year) * 100, sales_last_year)
  ;;
}
```

Each step is its own metric and can be reused in dashboards and in other metrics. There is no need for `VAR … RETURN`.

## Year-to-date / Month-to-date

```dax
YTD Sales = CALCULATE([Total Sales], DATESYTD('Date'[Date]))
MTD Sales = CALCULATE([Total Sales], DATESMTD('Date'[Date]))
```

```aml
metric ytd_sales { definition: @aql total_sales | period_to_date('year', orders.created_at)  ;; }
metric mtd_sales { definition: @aql total_sales | period_to_date('month', orders.created_at) ;; }
```

(The function name varies by Holistics version; verify with `search_docs`.)

## Inactive relationship (USERELATIONSHIP)

```dax
Sales by Due Date =
CALCULATE(SUM(Sales[SalesAmount]), USERELATIONSHIP(Sales[DueDateKey], 'Date'[DateKey]))
```

```aml
metric sales_by_due_date {
  definition: @aql
    sum(sales.sales_amount)
    | with_relationships(sales.due_date_key > dates.date_key)
  ;;
}
```

The path must already exist in the dataset's `relationships { }` block.

### `with_relationships()` syntax

Full form:

```
with_relationships(metric,
  relationship(model_1.field_1 > model_2.field_2, true | false, 'one_way' | 'two_way'),
  relationship(...)
)
```

Short form (defaults: `true`, `'two_way'`):

```
with_relationships(metric, model_1.field_1 > model_2.field_2)
```

## ALL / reset filter context (percent of total)

```dax
% of Total Sales =
DIVIDE([Total Sales], CALCULATE([Total Sales], ALL(Product)))
```

Use `of_all(<dimension>)` to drop a specific dimension from the metric's context. This is the AQL primitive for "percent of total" and is preferred over any `where(1=1)` trick:

```aml
metric pct_total_sales {
  definition: @aql
    safe_divide(total_sales * 100.0, total_sales | of_all(products))
  ;;
}
```

For `ALLEXCEPT` semantics — _"keep these grains, ignore everything else"_ — use `keep_grains(<dim_or_model>, ...)`. See [keep_grains](https://docs.holistics.io/docs/reference/aql/keep.md). For "turn an aggregation into a dimension value" (cohort, customer lifetime value), use `dimensionalize(<dim>)`. See [Level of Detail](https://docs.holistics.io/docs/as-code/aql/level-of-detail).

```dax
Customer AOV =
CALCULATE(DIVIDE([Total Amount], [Total Orders]), ALLEXCEPT(Users, Users[Id]))
```

```aml
metric customer_aov {
  definition: @aql
    safe_divide(order_items.total_amount, order_items.total_orders) | keep_grains(users)
  ;;
}
```

> Gotcha (step 4 of the pipeline): a metric with `of_all(products)` will _ignore_ any report filter on `products.*`. If the user filters on `products.name` and the metric drops that dimension, the metric is computed across all products and then COALESCE'd back. To filter the displayed rows, either filter on a metric (lands at step 7) or wrap the metric in `case(when: ..., then: ..., else: null)` and filter "is not null". See [Order of operations](https://docs.holistics.io/docs/as-code/aql/order-of-operations).

## Running total

```dax
Running Total =
CALCULATE([Total Sales],
  FILTER(ALL('Date'[Date]), 'Date'[Date] <= MAX('Date'[Date])))
```

```aml
metric running_total_sales {
  definition: @aql
    total_sales | running_total(orders.created_at)
  ;;
}
```

> Note: `running_total` does **not** work with `count_distinct`. Use `approx_count_distinct` instead on warehouses that support it (Snowflake, BigQuery, Databricks, MotherDuck, Presto/Athena). Example: `approx_count_distinct(users.id) | running_total(orders.created_at)`.

## Moving average

```dax
3M Moving Avg = AVERAGEX(DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -3, MONTH), [Total Sales])
```

AQL has no `moving_average` function. Use the window function `window_avg(metric, range, order: <ts>)`. The range `-2..0` means "from 2 rows back to the current row" (3-row trailing window). See [AQL window functions](https://docs.holistics.io/docs/reference/aql/window-function.md).

```aml
metric sales_3m_moving_avg {
  label: '3-month Moving Avg. Sales'
  type: 'number'
  definition: @aql
    window_avg(total_sales, -2..0, order: orders.created_at | month())
  ;;
}
```

The same shape works with `window_sum`, `window_min`, `window_max`, `window_count`. For other rolling patterns, see also the `trailing_period()` function.

## Ranking

```dax
Product Rank = RANKX(ALL(Product[Name]), [Total Sales], , DESC, DENSE)
```

Use AQL `rank` with `order` and optional `partition`:

```aml
metric product_rank {
  type: 'number'
  definition: @aql
    rank(order: total_sales | desc(), partition: product.name)
  ;;
}
```

> Gotcha: window functions in **dimensions** (`rank`, `ntile`, `previous`, …) evaluate at step 3 of the pipeline — _before_ report filters (step 5). A `rank` dimension on `orders` ranks across all orders, not just the rows visible in the report. To limit ranking to a filtered scope, push the filter into the metric and `dimensionalize(...)`, or wrap with `case(when: <filter>, then: rank(...), else: null)`. See [Order of operations](https://docs.holistics.io/docs/as-code/aql/order-of-operations).

## SWITCH / nested IF

```dax
Tier =
SWITCH(TRUE(),
  [Total Sales] >= 100000, "A",
  [Total Sales] >= 10000,  "B",
  "C")
```

Use AQL `case` for multi-branch logic:

```aml
metric tier {
  type: 'text'
  definition: @aql
    case(
      when: total_sales >= 100000, then: 'A',
      when: total_sales >= 10000,  then: 'B',
      else: 'C'
    )
  ;;
}
```

## CALCULATE with multiple filters

```dax
Electronics 2024 = CALCULATE([Total Sales], Product[Category] = "Electronics", 'Date'[Year] = 2024)
```

```aml
metric electronics_2024 {
  definition: @aql
    total_sales
    | where(product.category is 'Electronics')
    | where(orders.created_at matches @2024)
  ;;
}
```

## SUMX / iterator pattern

```dax
Total Line Profit = SUMX(Sales, Sales[Quantity] * Sales[UnitPrice] - Sales[UnitCost])
```

AQL `sum(table, expr)` evaluates the expression per row, then aggregates. No iterator gymnastics:

```aml
metric total_line_profit {
  definition: @aql
    sum(sales, sales.quantity * sales.unit_price - sales.unit_cost)
  ;;
}
```

If the same per-row expression is reused across many metrics, promote it to a dimension and aggregate that dimension instead:

```aml
// in sales.model.aml
dimension line_profit {
  type: 'number'
  definition: @aql sales.quantity * sales.unit_price - sales.unit_cost ;;
}

// metric
metric total_line_profit { definition: @aql sum(sales.line_profit) ;; }
```

## Nested aggregation (aggregate of aggregate)

```dax
Avg Monthly Sales = AVERAGEX(VALUES('Date'[Month]), [Total Sales])
```

Use a pipe chain that reads like a sentence — _"take orders, group by month, calculate sales, then average them"_:

```aml
metric avg_monthly_sales {
  definition: @aql
    orders
    | group(orders.created_at | month())
    | select(sales: total_sales)
    | avg(sales)
  ;;
}
```

Same shape works for "average daily order count", "best month for revenue", etc. Two levels of aggregation in four lines, no subqueries.

## Common anti-patterns to clean up during migration

| Anti-pattern in Power BI                                          | Fix in Holistics                                                            |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `IFERROR(a/b, BLANK())`                                           | `safe_divide(a, b)`                                                         |
| `IF(ISBLANK([m]), 0, [m])`                                        | Leave nulls as nulls; the visualization handles them.                       |
| Nested `CALCULATE(CALCULATE(...))`                                | A single metric with chained `where` calls.                                 |
| `CALCULATE([m], ALL(table))` for percent-of-total                 | `m \| of_all(<dimension>)`.                                                 |
| `CALCULATE([m], ALLEXCEPT(table, keep))`                          | `m \| keep_grains(<keep_dim_or_model>, ...)`.                               |
| `SUMX(table, expr)` translated as a SQL CTE                       | `sum(table, expr)`; promote `expr` to a dimension if reused.                |
| `AVERAGEX(VALUES(...), [m])` translated as a subquery             | `table \| group(<dim>) \| select(<m>) \| avg(<m>)`.                         |
| Repeated `VAR` computation                                        | A separate reusable `metric`; downstream metrics auto-update.               |
| Calculated column performing aggregation                          | Move to a metric, not a dimension.                                          |
| Visual-level filter repeated across six visuals                   | A page-level filter on the dashboard.                                       |
| Multiple "Sales Amount by X Date" variants for role-playing dates | One base metric plus named `with_relationships` aliases.                    |
| Filtering a dimension that the metric `of_all`s                   | Filter on a metric, or wrap the metric in `case(when:, then:, else: null)`. |

## Translation procedure (per measure)

1. Read the DAX, including all referenced sub-measures.
2. Classify the measure and pick the AQL primitive:
   - aggregation → `sum/count/avg/...`
   - filter-context modifier → `where`, `with_relationships`
   - level-of-detail / "ALL" / "ALLEXCEPT" → `of_all` (drop a dim), `keep_grains` (keep only these dims), `dimensionalize` (turn aggregation into dim value)
   - time intelligence → `relative_period`, `period_to_date`, `running_total`, `window_avg`/`window_sum`/`trailing_period` (moving / rolling)
   - iterator (`SUMX`, `AVERAGEX`) → `sum(table, expr)` / nested `group | select | avg`
   - branching → `case(when:, then:, else:)`
   - ranking → `rank(order:, partition:)`
3. Choose the target shape: prefer a `metric @aql` first; fall back to a `measure @sql` only when AQL truly lacks the primitive.
4. Call `generate_aql` with the DAX, the intent, and the model schema as natural-language context.
5. Run `holistics aml validate` and `holistics mcp validate_aql` (CLI).
6. Compare values against Power BI (see [](./validation.md)).
7. If values disagree near `of_all` / `rank` / window functions, re-read the [pipeline order of operations](https://docs.holistics.io/docs/as-code/aql/order-of-operations) — step 4 (filter pruning) and step 3 (window in dimensions) cover most surprises.
