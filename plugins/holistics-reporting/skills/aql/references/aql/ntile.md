:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
A window function that divides the rows within a partition into a specified number of ranked groups. It assigns a rank (bucket number) to each row, based on the ordering specified.

**Syntax**
```aml
ntile(ranks, order: order_expr)
ntile(ranks, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
ntile(4, order: count(orders.id) | desc())
ntile(4, order: count(orders.id) | desc(), order: average(users.age))

// with partition
ntile(4, order: count(orders.id) | desc(), partition: orders.status)

// Axis-aware examples
ntile(4, order: 'rows')                              // Divide into 4 groups by row order
ntile(3, order: 'columns' | desc())                  // Divide into 3 groups by column order (descending)
ntile(5, order: revenue | desc(), partition: 'rows') // Divide into 5 groups within each row
```


**Input**
- `ranks` (**required**, **number**): The number of ranked groups to divide the rows into.
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by dimensions mapped to rows/x-axis
  - `'columns'` or `'legend'`: Order by dimensions mapped to columns/legend
  - E.g. `ntile(4, order: count(orders.id) | desc())` or `ntile(4, order: 'rows')`
- `partition` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. E.g. `ntile(4, order: count(orders.id), partition: orders.status)` or `ntile(4, order: revenue, partition: 'rows')`

**Output**

The rank group (or bucket number) the current row belongs to, between 1 and `ranks`. If no partition is specified, the whole table is considered as a single partition.

## See also

- [`rank()`](/reference/aql/rank)
- [`dense_rank()`](/reference/aql/dense_rank)
- [`percent_rank()`](/reference/aql/percent_rank)
- [Window Functions](/reference/aql/window-function)
