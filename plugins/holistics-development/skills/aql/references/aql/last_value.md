:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
Returns the value of an expression from the last row of the window frame.

**Syntax**
```aml
last_value(expr, order: order_expr, ...)
last_value(expr, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
last_value(count(orders.id), order: users.created_at | asc())
last_value(count(orders.id), order: users.created_at | asc(), order: users.id)

// with partition
last_value(count(orders.id), order: users.created_at | asc(), partition: orders.status)

// Axis-aware examples
last_value(revenue, order: 'rows')                          // Last value in row order
last_value(revenue, order: 'columns', partition: 'rows')    // Last column value within each row
last_value(sales, order: 'x_axis' | desc())                 // Last value in reverse row order
```

**Input**
- `expr` (**required**): The expression to retrieve the last value from.
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by dimensions mapped to rows/x-axis
  - `'columns'` or `'legend'`: Order by dimensions mapped to columns/legend
  - E.g. `last_value(count(orders.id), order: users.created_at | desc())` or `last_value(revenue, order: 'rows')`
- `partition` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. E.g. `last_value(count(orders.id), order: users.created_at, partition: orders.status)` or `last_value(revenue, order: 'columns', partition: 'rows')`

**Output**

The value of the expression from the last row of the window frame. If no partition is specified, the whole table is considered as a single partition.

## See also

- [`first_value()`](/reference/aql/first_value)
- [`nth_value()`](/reference/aql/nth_value)
- [`next()`](/reference/aql/next)
- [Window Functions](/reference/aql/window-function)
