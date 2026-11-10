:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
Returns the value of an expression from the first row of the window frame.

**Syntax**
```aml
first_value(expr, order: order_expr, ...)
first_value(expr, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
first_value(count(orders.id), order: users.created_at | asc())
first_value(count(orders.id), order: users.created_at | asc(), order: users.id)

// with partition
first_value(count(orders.id), order: users.created_at | asc(), partition: orders.status)

// Axis-aware examples
first_value(revenue, order: 'rows')                          // First value in row order
first_value(revenue, order: 'columns', partition: 'rows')    // First column value within each row
first_value(sales, order: 'x_axis' | desc())                 // First value in reverse row order
```

**Input**
- `expr` (**required**): The expression to retrieve the first value from.
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by dimensions mapped to rows/x-axis
  - `'columns'` or `'legend'`: Order by dimensions mapped to columns/legend
  - E.g. `first_value(count(orders.id), order: users.created_at | desc())` or `first_value(revenue, order: 'rows')`
- `partition` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. E.g. `first_value(count(orders.id), order: users.created_at, partition: orders.status)` or `first_value(revenue, order: 'columns', partition: 'rows')`

**Output**

The value of the expression from the first row of the window frame. If no partition is specified, the whole table is considered as a single partition.

## See also

- [`last_value()`](/reference/aql/last_value)
- [`nth_value()`](/reference/aql/nth_value)
- [`previous()`](/reference/aql/previous)
- [Window Functions](/reference/aql/window-function)
