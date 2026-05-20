# DAX → AQL pattern catalogue

For every translation, feed the DAX, the source model schema, and the intent to `generate_aql`; do not hand-write AQL. The snippets below show the target shape for review — the actual function names and operators must be confirmed via `search_docs` or `validate_aql`.

## Mental model

| DAX | AQL |
|-----|-----|
| Filter context modifies the current evaluation environment. | Each metric declares its **dimension scope** explicitly via pipes (`\|`). |
| `[Measure]` re-evaluates inside `CALCULATE`. | `metric_name \| with_filter(...)` / `with_relationships(...)`. |
| Row context comes from iterators (`SUMX`, `AVERAGEX`). | Composed metrics plus dimension scope; fall back to SQL for true row iteration. |
| `VAR x = … RETURN …` | Define reusable `metric` blocks and compose them. |

## Aggregations

| DAX | AQL |
|-----|-----|
| `Total Sales = SUM(Sales[Amount])` | `metric total_sales { definition: @aql sum(sales.amount) ;; }` |
| `Order Count = COUNTROWS(Orders)` | `count(orders)` |
| `Customer Count = DISTINCTCOUNT(Sales[CustomerID])` | `count_distinct(sales.customer_id)` |
| `Avg Deal = AVERAGE(Sales[DealValue])` | `avg(sales.deal_value)` |

## Safe division

```dax
Profit Margin = DIVIDE([Profit], [Revenue])
```

```aml
metric profit_margin {
  type: 'number'
  definition: @aql safe_divide(profit, revenue) ;;
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
    total_sales | with_filter(@aql sales.order_value > 1000)
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
metric ytd_sales { definition: @aql total_sales | to_date_period(orders.created_at, 'year')  ;; }
metric mtd_sales { definition: @aql total_sales | to_date_period(orders.created_at, 'month') ;; }
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

The alias must already exist in the dataset's `relationships { … }` block.

## ALL / reset filter context

```dax
% of Total Sales =
DIVIDE([Total Sales], CALCULATE([Total Sales], ALL(Product)))
```

```aml
metric pct_total_sales {
  definition: @aql
    safe_divide(total_sales, total_sales | with_filter(@aql 1=1))
  ;;
}
```

For more nuanced `ALL` / `ALLEXCEPT` behaviour, use explicit dimension scope on the metric (for example, by resetting the grouping). Confirm the exact syntax with `search_docs`.

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

## Moving average

```dax
3M Moving Avg = AVERAGEX(DATESINPERIOD('Date'[Date], MAX('Date'[Date]), -3, MONTH), [Total Sales])
```

```aml
metric sales_3m_moving_avg {
  definition: @aql
    total_sales | moving_average(orders.created_at, interval(3 month))
  ;;
}
```

## Ranking

```dax
Product Rank = RANKX(ALL(Product[Name]), [Total Sales], , DESC, DENSE)
```

AQL has limited window-style ranking, so `RANKX`-style needs usually drop to SQL:

```aml
measure product_rank {
  type: 'number'
  definition: @sql
    rank() over (order by {{ total_sales }} desc)
  ;;
}
```

## SWITCH / nested IF

```dax
Tier =
SWITCH(TRUE(),
  [Total Sales] >= 100000, "A",
  [Total Sales] >= 10000,  "B",
  "C")
```

Prefer SQL `CASE` for multi-branch logic:

```aml
measure tier {
  type: 'text'
  definition: @sql
    case
      when {{ total_sales }} >= 100000 then 'A'
      when {{ total_sales }} >=  10000 then 'B'
      else 'C'
    end
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
    | with_filter(@aql product.category = 'Electronics')
    | with_filter(@aql year(orders.created_at) = 2024)
  ;;
}
```

## SUMX / iterator pattern

```dax
Total Line Profit = SUMX(Sales, Sales[Quantity] * Sales[UnitPrice] - Sales[UnitCost])
```

Compute the per-row expression as a dimension, then `sum()` it:

```aml
// in sales.model.aml
dimension line_profit {
  type: 'number'
  definition: @sql ({{ quantity }} * {{ unit_price }}) - {{ unit_cost }} ;;
}
```
```aml
// metric
metric total_line_profit { definition: @aql sum(sales.line_profit) ;; }
```

Avoid translating `SUMX` as runtime iteration; push the arithmetic into the model instead.

## Common anti-patterns to clean up during migration

| Anti-pattern in Power BI | Fix in Holistics |
|--------------------------|------------------|
| `IFERROR(a/b, BLANK())` | `safe_divide(a, b)` |
| `IF(ISBLANK([m]), 0, [m])` | Leave nulls as nulls; the visualization handles them. |
| Nested `CALCULATE(CALCULATE(...))` | A single metric with chained `with_filter` calls. |
| Repeated `VAR` computation | A separate reusable `metric`. |
| Calculated column performing aggregation | Move to a metric, not a dimension. |
| Visual-level filter repeated across six visuals | A page-level filter on the dashboard. |
| Multiple "Sales Amount by X Date" variants for role-playing dates | One base metric plus named `with_relationships` aliases. |

## Translation procedure (per measure)

1. Read the DAX, including all referenced sub-measures.
2. Classify the measure: aggregation, filter-context modifier, time intelligence, iterator, or row context.
3. Choose the target shape: prefer a `metric @aql` first; fall back to a `measure @sql` if AQL lacks the function (ranking, windows).
4. Call `generate_aql` with the DAX, the intent, and the model schema as natural-language context.
5. Run `validate_aql` (MCP) or `holistics aml validate` (CLI).
6. Compare values against Power BI (see [](./validation.md)).
