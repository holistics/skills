### Definition
Get a subset of rows from `table` that match one or more `condition`.

**Syntax**
```aml
filter(table, condition, condition, ...)
```

```aml title="Examples"
filter(orders, orders.status == 'refunded') //-> Table(orders.id, orders.status, ...)
filter(orders, orders.is_cancelled) // -> Table(orders.id, orders.status, ...)

// with pipe
orders | filter(orders.status == 'refunded') //-> Table(orders.id, orders.status, ...)
orders
| select(orders.id, orders.status)
| filter(orders.status == 'refunded') //-> Table(orders.id, orders.status)

// multiple conditions
orders
| filter(orders.status == 'refunded', orders.is_cancelled)
| select(orders.id) //-> Table(orders.id)
```

**Input**
- `table`: A model reference or the returned table from a previous expression.
- `condition` (**repeatable**): A formula returning a [truefalse](/reference/aql/type-truefalse) value. Each `condition` is evaluated over each row of `table`:
  - If the `condition` evaluates to true, the row is included in the output table.
  - If the `condition` evaluates to false, the row is excluded from the output table.

  :::info
  If multiple `condition` are provided, they are evaluated as a logical AND. For example, `filter(orders, orders.status == refunded', orders.is_cancelled)` is equivalent to `filter(orders, and(orders.status == refunded', orders.is_cancelled))`.
  :::

**Output**

A new table that contains all rows in `table` that match the `condition`.

### Sample Usages

import SampleCode from '@site/src/components/SampleCode';

import { example1 } from './filter.js';

<SampleCode
  title="List all orders from Viet Nam created in August 2022"
  rawResult={example1}
/>

import { example2 } from './filter.js';

Any expression that can be used in [select](/reference/aql/select) column, can be used in [filter](/reference/aql/filter) condition.
<SampleCode
  title="List Order Status with more than 1000 orders"
  rawResult={example2}
/>

## See also

- [`where()`](/reference/aql/where): applies on metrics, not tables
- [`select()`](/reference/aql/select)
- [`group()`](/reference/aql/group)
- [where vs filter](/reference/aql/where-vs-filter)
- [Pipe operator](/reference/aql/operator#pipe)
