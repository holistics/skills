## Description
Apply condition(s) to filter a metric.

## Syntax

```aql
metric | where(condition)
```

### Input
- `metric`: An AQL metric.
- `condition` (**repeatable**): A condition that will be applied to the metric. A valid condition must be in following forms:
  - `model.dimension operator value`. E.g. `orders.status == 'delivered'`, `orders.created_at matches @(last 7 days)`
  - `model.dimension in table`. E.g. `orders.status in (unique(orders.status) | where(orders.status != 'delivered'))`
  - `model.dimension operator measure`. E.g. `users.age > avg(users.age)`

### Output
New metric with applied conditions (same type as the input metric)

### Examples

```aql
orders | count(orders.id) | where(orders.status == 'delivered')

// multiple conditions
orders | count(orders.id) | where(orders.status == 'delivered' and orders.created_at matches @(last 7 days))
```

## Condition Types

The `where()` function supports various types of conditions that can be categorized into simple and complex conditions.

### Simple Conditions

#### Constant Condition
A constant condition compares a dimension with a constant value using an operator.

**Format**: `dimension operator constant_value`

**How it works**: The condition targets the specific model that the dimension belongs to and filters it before the data enters the metric calculation. This pre-filtering ensures that only rows meeting the criteria are included in the aggregation.

**Examples**:
```aml
// Equality check
count(orders.id) | where(orders.status == 'delivered')

// Comparison operators
sum(orders.amount) | where(orders.amount > 100)

// Date matching
count(orders.id) | where(orders.created_at matches @(last 7 days))

// List inclusion
count(orders.id) | where(orders.status in ['delivered', 'cancelled'])
```

#### Single Model Condition
A single model condition uses fields from a single model to perform calculations or comparisons. This type of condition only works when the model defines a primary key.

**Format**: Expression using fields from a single model

**How it works**: Similar to constant conditions, this filters the model before metric calculation. The model must have a primary key because internally, the condition is converted to a table condition on the primary key. For example:
```aml
count(orders.id) | where(date_diff('day', orders.created_at, orders.delivered_at) < 30)
// is internally converted to:
count(orders.id) | where({orders.id} in 
  orders 
  | filter(date_diff('day', orders.created_at, orders.delivered_at) < 30) 
  | select(orders.id)
)
```

**Examples**:
```aml
// Date difference calculation
count(orders.id) | where(date_diff('day', orders.created_at, orders.delivered_at) < 30)

// Field comparison within same model
count(orders.id) | where(orders.discount_amount < orders.total_amount * 0.5)

// Complex calculations on single model
sum(orders.revenue) | where((orders.revenue / orders.quantity) > 50)
```

#### Cross Model Condition
A cross model condition involves fields from multiple models. This type of condition is converted to a table condition internally.

**Format**: Expression using fields from multiple models

**How it works**: When you use fields from multiple models in a condition, the system internally converts it to a table condition that matches on **all dimensions involved**. This creates a unique combination of all referenced dimensions and filters based on that combination.

**Important note**: Cross model conditions match on all dimensions involved, creating dimension combinations. This behavior might be exactly what you want in some cases, but in others you might need a different approach:

**When dimension combination matching is desired**:
If you want to analyze specific combinations (e.g., specific product-discount pairs), the default behavior works well.

**When you might want an alternative approach**:
If you want to match on specific dimensions rather than all dimensions involved, you might prefer using a table condition for more control.

**Examples**:
```aml
// Average quantity of items in cancelled orders with quantity > 3
avg(order_items.quantity) | where(order_items.quantity > 3 and orders.status == 'cancelled')
This is internally converted to:
{order_items.quantity, orders.status} in unique(order_items.quantity, orders.status)
  | filter(order_items.quantity > 3 and orders.status == 'cancelled')
// Result: Averages ONLY items with quantity > 3

// Alternative: Average ALL items in cancelled orders that contain at least one item with qty > 3
avg(order_items.quantity) | where(order_items.order_id in 
  order_items
  | filter(order_items.quantity > 3 and orders.status == 'cancelled')
  | select(order_items.order_id)
)
// Result: Averages ALL items in qualifying orders

// Example difference:
// Order #1 (cancelled): items with quantities [2, 5, 7]
// - Cross-model approach: avg([5, 7]) = 6
// - Alternative approach: avg([2, 5, 7]) = 4.67
```

### Complex Conditions

#### Table Condition
A table condition checks if a dimension exists in a derived table.

**Format**: 
- Explicit: `dimension in table_expression`
- Implicit: `table_expression` (internally converted to `{dimension} in table_expression`)

**How it works**: Table conditions provide fine-grained control by allowing you to filter based on whether a dimension value exists in a derived table. The table expression can include complex transformations, filters, and aggregations, giving you precise control over which values to include.

When using the implicit form (just a table expression), the system matches on the dimensions that are clear from the context.

**Examples**:
```aml
// Explicit table condition
count(orders.id) | where(orders.status in unique(orders.status) | where(orders.created_at > @2023-01-01))

// Using complex table expressions
sum(orders.amount) | where(
  orders.user_id in users
  | filter(users.country == 'US')
  | select(users.id)
)

// Implicit table condition (just table expression)
count(users.id) | where(top(5, users.id, by: users.revenue))
// This is internally converted to:
// count(users.id) | where({users.id} in top(5, users.id, by: users.revenue))
```

#### Semi-additive Condition
A semi-additive condition compares a dimension with the result of a metric calculation. This is commonly used for [semi-additive calculations](/as-code/aql/cookbook/aql-semi-additive-calculation) like bank balances or inventory levels.

**Format**: `dimension operator metric`

**How it works**: The metric on the right side of the operator is calculated first, then each row is filtered based on whether the dimension value meets the comparison criteria. This enables powerful filtering patterns like "values greater than average" or "dates equal to the maximum date".

**Examples**:
```aml
// Compare with average
sum(users.revenue) | where(users.age > avg(users.age))

// Semi-additive: Last balance date
sum(balances.amount) | where(balances.date == max(balances.date))

// Compare with calculated metric
count(orders.id) | where(orders.amount > sum(orders.amount) / count(orders.id))
```

## When not to use `where()`?

Sometimes you want to filter an arbitrary expression that haven't been explicitly defined as a dimension yet. For example, you want to know which country has at least 100,000 users who have placed at least 1 order:

```aml
orders
| group(orders.country)
| select(orders.country, users_count: count_distinct(orders.user_id))
// This will error
| where(users_count >= 100000) // `where` here will be invalid
```

In this case, `where()` cannot be used, because by definition, `where()` have to filter on an existing dimension of `orders`, while the field `users_count` is an aggregation that has not been defined and calculated before. You can use `filter()` function instead.

```aml
orders
| group(orders.country)
| select(orders.country, users_count: count_distinct(orders.user_id))
// highlight-next-line
| filter(users_count >= 100000) // `filter` works here because it acts on table 
```
## FAQ 

### What is the difference between `where()` vs `filter()`

To understand when should you use `where()` or `filter()` to apply filtering condition to a transformation, please visit this document: [where vs filter](/reference/aql/where-vs-filter)

### I can't apply `where()` to a dimensionalized metric?

`where()` cannot be applied to a dimension. If you want to dimensionalize a metric (i.e turning a metric into a dimension), and you want to apply `where()` to the resulting dimension, **don't do this**:

```aml
// DON't do this
dimension dimensionalized_metric {
    // ... 
    definition: @aql min(orders.created_at | month()) | dimensionalize(users.id);;
}

dimension another_dimension {
  // ...
    definition: @aql dimensionalized_metric | where(orders.country == 'Vietnam');;
}

```

If you do this, you won't get the desired result.

Instead, **do this**:

```
dimension dimensionalized_metric {
    // ... 
    definition: @aql min(orders.created_at | month()) | where(orders.country == 'Vietnam') | dimensionalize(users.id);;
}
```
