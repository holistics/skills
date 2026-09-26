## Description

A window function that returns the dense rank of rows within a partition of a table. Tied values are assigned the same rank. The next rank in the sequence is consecutive. E.g. 1, 1, 2, 3, 3, 4, 4, 5, ...

To get non-consecutive rank, use `rank`.

## Syntax

```aql
dense_rank(order: metric)
dense_rank(order: metric, ..., partition: partition_expr, ...)
```

### Input
* `metric` (required, repeatable): A metric used for ordering. The order direction can be set using `| asc()` or `| desc()`. The default order is `asc()`
* `partition_expr`: An expression used for partitioning.

### Output
`Scalar(number)`

### Examples
```aql
metric order_count = orders | count(orders.id);
metric top_ordered = dense_rank(order: order_count | desc());
metric top_ordered_youngest = dense_rank(order: order_count | desc(), order: users | avg(users.age));

metric top_ordered_per_gender = dense_rank(order: order_count | desc(), partition: users.gender);
```
