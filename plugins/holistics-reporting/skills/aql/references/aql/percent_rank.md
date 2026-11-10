:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
Returns the relative percentile of a row within a partition of a table. The value is between 0 and 1, inclusive.

**Syntax**
```aml
percent_rank(order: order_expr, ...)
percent_rank(order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
percent_rank(order: count(orders.id) | desc())
percent_rank(order: count(orders.id) | desc(), order: average(users.age))

// with partition
percent_rank(order: count(orders.id) | desc(), partition: orders.status)

// Axis-aware examples
percent_rank(order: 'rows')                              // Percentile rank by row order
percent_rank(order: 'columns' | desc())                  // Percentile rank by column order (descending)
percent_rank(order: revenue | desc(), partition: 'rows') // Percentile rank within each row
```

**Input**
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by dimensions mapped to rows/x-axis
  - `'columns'` or `'legend'`: Order by dimensions mapped to columns/legend
  - E.g. `percent_rank(order: count(orders.id) | desc())` or `percent_rank(order: 'rows')`
- `partition` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. E.g. `percent_rank(order: count(orders.id), partition: orders.status)` or `percent_rank(order: revenue, partition: 'rows')`

**Output**

The percentile rank of the current row within its partition, as a value between 0 and 1. If no partition is specified, the whole table is considered as a single partition.

## See also

- [`rank()`](/reference/aql/rank)
- [`dense_rank()`](/reference/aql/dense_rank)
- [`ntile()`](/reference/aql/ntile)
- [Window Functions](/reference/aql/window-function)
