Metric expressions are expressions that represent a reusable metric.

### Structure
```aml
source_table_expression (optional)
| aggregation_expression
| metric_function1 (optional)
| metric_function2 (optional)
| ...
```
A metric expression needs to contain at least one [aggregation expression](/reference/aql/metric-expression#aggregation-expression), together with an optional [source table expression](/reference/aql/metric-expression#source-table-expression), and an optional [metric context](/reference/aql/metric-expression#metric-context).

### Aggregation expression
An aggregation expression represents the core logic of the metric expression.

It can be a single aggregation function:
```aml
avg(users.age)
```

or an arithmetic combination of aggregation expressions:
```aml
// difference between average order value and average discount
avg(orders.total_value) - avg(orders.discount)

// average price of products
sum(products.price) / count(products.id)

// country order percentagage
count(orders.id) * 1.0 /
  (count(orders.id) | of_all(countries))
```

### Source table expression
A source [table expression](/reference/aql/table-expression) is only required if the aggregation function **aggregates data from multiple models** and you want to **explicitly set the model to aggregate from**.

For examples:

```aml
// counts number of users from users table
count(users.id)

// same as above and thus the source table expression can be omitted
users | count(users.id)

// count number of times some user placed an order
// The 'orders' part is the table expression
orders | count(users.id)
```

Another use case is [nested aggregation](/as-code/aql/cookbook/level-of-detail#use-case-1-higher-lod--nested-aggregation) where you want to aggregate on an already agregated measure. For example:

Given an existing measure:
```aml
Model users {
    // Average order value of a user
    measure aov {
      definition: @aql
        sum(order_items, order_items.quantity * products.price) * 1.0 
          / count_distinct(orders.id)
      ;;
  }
}
```

You can create a new nested aggregation like this
```aml
// Max of average order value of a user
// The part before 'max()' is the table expression
users | group(users.id) | select(user_aov: users.aov) | max()
```


### Metric context
Every metric expression has a corresponding context, which includes the followings:
* The condition applied to the expression, can be modified with [where](/reference/aql/where) function
* The relationship structure defined in the dataset where the expression is located, can be modified with [with_relationships](/reference/aql/with_relationships) function
* The [level of detail](/as-code/aql/cookbook/level-of-detail) associated with the expression, can be modified with [LOD functions](/reference/aql/metric-function#lod-functions)
* The window function logic applied to the expression, can be modified with [window functions](/reference/aql/metric-function#window-functions)

The context can be manipulated using a combination of [metric functions](/reference/aql/metric-function). See the examples below for more clarity.


### Examples
Count number of users:
```aml
count(users.id)
```

Count number of male users with [where](/reference/aql/where):
```aml
count(users.id) | where(users.gender == 'Male')
```

Cross-model metric:
```aml
sum(products.price * order_items.quantity)
```

Total order values, regardless of dimensions, leveraging [LOD functions](/reference/aql/metric-function#lod-functions):
```aml
sum(products.price * order_items.quantity) | exclude(order_items)
```

Running Total Orders by Month
```aml
count(orders.id) | running_total(run: orders.created_at | month())
```
