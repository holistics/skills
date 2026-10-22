## Description

A window function that returns the rank of rows within a partition of a table. Tied values are assigned the same rank. The next rank in the sequence is not consecutive. E.g. 1, 1, 3, 4, 4, 6, ...

To get consecutive rank, use `dense_rank`.

## Syntax

```aql
rank(order: metric)
rank(order: metric, ..., partition: partition_expr, ...)
```

### Input
* `metric` (required, repeatable): A metric used for ordering. The order direction can be set using `| asc()` or `| desc()`. The default order is `asc()`
* `partition_expr`: An expression used for partitioning.

### Output
`Scalar(number)`

### Examples
```aql
metric top_ordered = rank(order: orders | count(orders.id) | desc());
metric top_ordered_youngest = rank(order: orders | count(orders.id) | desc(), order: avg(users.age));

metric top_ordered_per_gender = rank(order: orders | count(orders.id) | desc(), partition: users.gender);
```
