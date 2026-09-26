## Description
A window function that returns the value of the next row at an offset relative to the current row.

## Syntax

```aql
metric | next(order: order_dimension, ...)
metric | next(offset, order: order_dimension, ...)
metric | next(offset, order: order_dimension, ..., reset: partition_dimension, ...)
metric | next(offset, order: order_dimension, ..., partition: partition_dimension, ...)
```

### Input
- `metric`(**required**): An AQL metric
- `offset` (**optional**): The offset of the next row relative to the current row. If not specified, the default value is 1.
- `order` (**required**, **repeatable**): A model dimension that is used for ordering. The order is default to ascending. The order can be set explicitly with `| asc()` or `| desc()`.
- `partition` or `reset` (**repeatable**, **optional**): A model dimension that is used for partitioning the table. If partitions are not specified, the table will be partitioned by all other grouping columns.

### Output
`Scalar`

### Examples
```aql
users | count(users.id) | next(order: users | count(users.id) | desc())
users | count(users.id) | next(2, order: users.created_at | month())
users | count(users.id) | next(4, order: users.created_at | month(), reset: users.gender)
```
