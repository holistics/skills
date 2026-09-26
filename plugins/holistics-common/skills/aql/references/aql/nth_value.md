:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
Returns the value of an expression from the Nth row of the window frame, where N is a positive integer.

**Syntax**
```aml
nth_value(expr, index, order: order_expr, ...)
nth_value(expr, index, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
nth_value(count(orders.id), 2, order: users.created_at | asc())
nth_value(count(orders.id), 3, order: users.created_at | asc(), order: users.id)

// with partition
nth_value(count(orders.id), 2, order: users.created_at | asc(), partition: orders.status)

// Axis-aware examples
nth_value(revenue, 3, order: 'rows')                          // 3rd value in row order
nth_value(revenue, 2, order: 'columns', partition: 'rows')    // 2nd column value within each row
nth_value(sales, 5, order: 'x_axis' | desc())                 // 5th value in reverse row order
```

**Input**
- `expr` (**required**): The expression to retrieve the Nth value from.
- `index` (**required**, **number**): The index of the row from which to retrieve the value (1-based).
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by dimensions mapped to rows/x-axis
  - `'columns'` or `'legend'`: Order by dimensions mapped to columns/legend
  - E.g. `nth_value(count(orders.id), 2, order: users.created_at | desc())` or `nth_value(revenue, 3, order: 'rows')`
- `partition` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. E.g. `nth_value(count(orders.id), 2, order: users.created_at, partition: orders.status)` or `nth_value(revenue, 2, order: 'columns', partition: 'rows')`

**Output**

The value of the expression from the Nth row of the window frame. If no partition is specified, the whole table is considered as a single partition.

**Notes**

This function is not supported in SQL Server.

## See also

- [`first_value()`](/reference/aql/first_value)
- [`last_value()`](/reference/aql/last_value)
- [Window Functions](/reference/aql/window-function)
