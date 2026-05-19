# TMDL → AML translation

Per-concept structural mapping. Verify exact AML syntax with `search_docs` or the Holistics docs before committing changes. The snippets below show the target shape; they are not authoritative grammar.

## Table → Model

### TMDL (input)
```tmdl
table Sales
	column SalesOrderLineKey
		dataType: int64
		sourceColumn: SalesOrderLineKey
		isHidden

	column 'Sales Amount'
		dataType: decimal
		formatString: \$#,##0.00
		sourceColumn: SalesAmount

	column OrderDateKey
		dataType: int64
		sourceColumn: OrderDateKey
		isHidden

	partition Sales = m
		mode: import
		source = ```let Source = Excel.Workbook(...) in Sales```
```

### AML (output) — `models/tables/sales.model.aml`
```aml
Model sales {
  type: 'table'
  label: 'Sales'
  data_source_name: 'warehouse'
  table_name: 'sales'

  dimension sales_order_line_key {
    label: 'Sales Order Line Key'
    type: 'number'
    hidden: true
    definition: @sql {{ #SOURCE.sales_order_line_key }} ;;
  }

  dimension sales_amount {
    label: 'Sales Amount'
    type: 'number'
    format: '$#,##0.00'
    definition: @sql {{ #SOURCE.sales_amount }} ;;
  }

  dimension order_date_key {
    label: 'Order Date Key'
    type: 'number'
    hidden: true
    definition: @sql {{ #SOURCE.order_date_key }} ;;
  }
}
```

### M-backed table → query model

For tables loaded via Power Query (M), move the ETL upstream. If a transient query is unavoidable, use a query model:

```aml
Model active_users {
  type: 'query'
  data_source_name: 'warehouse'

  dimension id    { type: 'number' definition: @sql {{ #SOURCE.id }} ;; }
  dimension email { type: 'text'   definition: @sql {{ #SOURCE.email }} ;; }

  query: @sql
    select id, email, signup_at
    from raw.users
    where deleted_at is null
  ;;
}
```

## Calculated column → dimension

### DAX
```dax
'Sales'[Margin] = Sales[SalesAmount] - Sales[TotalProductCost]
```

### AML
```aml
dimension margin {
  label: 'Margin'
  type: 'number'
  definition: @sql {{ sales_amount }} - {{ total_product_cost }} ;;
}
```

Prefer an AQL definition when expressing relational logic. Fall back to SQL for arithmetic and string operations as shown above.

## Relationships → dataset

### TMDL (`relationships.tmdl`)
```tmdl
relationship sales_to_customer
	fromColumn: Sales.CustomerKey
	toColumn: Customer.CustomerKey

relationship sales_orderdate_to_date
	fromColumn: Sales.OrderDateKey
	toColumn: 'Date'.DateKey

relationship sales_duedate_to_date
	isActive: false
	fromColumn: Sales.DueDateKey
	toColumn: 'Date'.DateKey

relationship sales_shipdate_to_date
	isActive: false
	fromColumn: Sales.ShipDateKey
	toColumn: 'Date'.DateKey
```

### AML (`datasets/aw_sales.dataset.aml`)
```aml
Dataset aw_sales {
  label: 'AdventureWorks Sales'

  models: [sales, customer, dates, product, reseller, sales_order, sales_territory]

  relationships: [
    relationship(sales.customer_key > customer.customer_key, true),

    // active date relationship
    relationship(sales.order_date_key > dates.date_key, true),

    // role-playing date relationships (named aliases)
    relationship(sales.due_date_key  > dates.date_key, false) { alias: 'due_date'  },
    relationship(sales.ship_date_key > dates.date_key, false) { alias: 'ship_date' }
  ]
}
```

An `isActive: false` Power BI relationship maps to `false` in the relationship tuple together with an `alias`. The alias is the name used inside `with_relationships(...)` in any metric that needs that join path.

Confirm the exact relationship syntax with `search_docs`; the alias mechanism may use a slightly different keyword depending on your Holistics version.

## Role-playing dimension pattern

Power BI uses `USERELATIONSHIP` inside `CALCULATE` to activate an inactive join. Holistics replaces this with a named alias:

```dax
Sales Amount by Due Date =
CALCULATE(
    SUM(Sales[SalesAmount]),
    USERELATIONSHIP(Sales[DueDateKey], 'Date'[DateKey])
)
```

becomes:

```aml
metric sales_amount_by_due_date {
  label: 'Sales Amount by Due Date'
  type: 'number'
  definition: @aql
    sum(sales.sales_amount)
    | with_relationships(sales.due_date_key > dates.date_key)
  ;;
}
```

## Hidden / display folder / format mapping

| TMDL property | AML equivalent |
|---------------|----------------|
| `isHidden` | `hidden: true` |
| `formatString: "$#,##0.00"` | `format: '$#,##0.00'` |
| `displayFolder: "KPIs"` | Model or dataset grouping, or a `folder:` metadata field |
| `description: "..."` | `description: '...'` |
| `dataType: int64 / decimal / double` | `type: 'number'` |
| `dataType: string` | `type: 'text'` |
| `dataType: dateTime` | `type: 'datetime'` |
| `dataType: boolean` | `type: 'truefalse'` |
| `sortByColumn: <col>` | A sort-by directive on the dimension |

## Date table

Power BI commonly uses a marked Date table. Holistics does not require one — `relative_period`, `year()`, `quarter()`, and `month()` all work on any timestamp column. If Power BI has a custom calendar (fiscal year, holidays), still migrate that calendar table as a normal model.

## Auto date/time

Power BI's "Auto date/time" feature generates `LocalDateTable_*` hidden tables. Do not migrate them. Disable Auto date/time in Power BI before exporting `.pbip` so they vanish from TMDL.
