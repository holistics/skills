import SampleCode from '@site/src/components/SampleCode';

### Definition
Run one expression or multiple expression over each row of a table and use the output to return a new table with the same number of row. In AQL, the [select](#) function serves as an intermediate step for subsequent transformations.

**Syntax**
```aml
select(table, expr1, expr2, ...)
select(table, col_name: expr1, ...)
```

```aml title="Examples"
select(orders, orders.id, orders.status) // -> Table(orders.id, orders.status)

// with pipe
orders | select(orders.id, orders.status) | select(orders.id) // -> Table(orders.id)

// named column
orders | select(orders.status, formatted_status: concat('Status: ', orders.status))
```

**Input**

- `table`: A model reference or the returned table from a previous expression.
- `expr` (**repeatable**): An expression to evaluate for each row of `table`.
:::caution
You need to name the column in the output table (e.g. `formatted_status: concat('Status: ', orders.status)`). Only expression that has clear fully-qualified column name (e.g. `orders.id`) can be used directly and reference as-is in the output table.
:::

**Output**

A table with the same number of rows as the input table, but with only the specified columns. E.g. `select(orders, orders.id, formatted_status: concat('Status: ', orders.status)` will return a table with 2 columns: `orders.id` and `formatted_status`.

| orders.status | formatted_status |
|---------------|------------------|
| pending       | Status: pending  |
| cancelled     | Status: cancelled|
| pending       | Status: pending  |

### Sample Usages

import { example1 } from './select.js';

<SampleCode
  title="List all order items and their value"
  rawResult={example1}
/>

import { example2 } from './select.js';

<SampleCode
  title="Use select to create an intermediate table for a metric"
  rawResult={example2}
/>

## See also

- [`filter()`](/reference/aql/filter)
- [`group()`](/reference/aql/group)
- [`unique()`](/reference/aql/unique)
- [Pipe operator](/reference/aql/operator#pipe)
