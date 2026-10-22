<!-- skip to avoid confusion with rank() -->

## Description
Find the top/bottom N values of a dimension based on specified measures.

## Syntax

```aql
top(n, model.dimension, by: measure, ...)
top(n, model.dimension, by: measure, ..., logic: logic)

bottom(n, model.dimension, by: measure, ...)
bottom(n, model.dimension, by: measure, ..., logic: logic)
```

### Input
- `n` (**required**): The number of top/bottom values to return.
- `model.dimension` (**required**): A fully-qualified reference to a model dimension. The output table will have one row for each top/bottom value of the specified dimension.
- `by` (**repeatable**, **required**): A measure that is used for ranking. The top rows are determined by ranking the specified measure in descending order, while the bottom rows are dtermined by ranking the specified measure in ascending order.
- `logic` (**optional**): The logic to use for ranking. Default to **'skip'**. To use 'dense' logic, use `logic: 'dense'`. E.g. `top(10, users.id, by: count(orders.id), logic: 'dense')`

### Output
`Table` containing the top/bottom dimensions. Can be used for filtering in `where()` or `explore.filters`

### Examples

```aql
top(10, users.id, by: orders | count(orders.id)) // -> Table containing 10 users.id that have highest order count
top(10, users.id, by: orders| count(orders.id), by: products | average(products.price)) // -> Table containing 10 users.id that have highest order count and highest average product price
top(10, users.id, by: orders | count(orders.id), logic: 'dense') // -> Table containing 10 users.id that have highest order count, using dense ranking

bottom(10, users.id, by: orders | count(orders.id)) // -> Table containing 10 users.id that have lowest order count
bottom(10, users.id, by: orders | count(orders.id), by: products | average(products.price)) // -> Table containing 10 users.id that have lowest order count and lowest average product price
bottom(10, users.id, by: orders | count(orders.id), logic: 'dense') // -> Table containing 10 users.id that have lowest order count, using dense ranking
```

Example when using in `where()`
```aql
metric top_10_users = top(10, users.id, by: orders | count(orders.id));
// average age of 10 users with most order count
metric average_age_of_top_10_users = users | avg(users.age) | where(users.id in top_10_users);
```

Example when using in `explore.filters`
```aql
metric top_10_users = top(10, users.id, by: orders | count(orders.id));
// list 10 users with most order count
explore {
  dimensions {
    user_id: users.id,
    user_name: users.id,
    created_at: users.created_at,
  }
  filters {
    users.id in top_10_users,
  }
}
```
