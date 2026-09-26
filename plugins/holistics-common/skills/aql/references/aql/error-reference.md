This is one of three documents aimed at helping answer common questions about AQL:
1. [Troubleshooting](/as-code/reference/troubleshooting)
2. [AQL Error Reference](/reference/aql/error-reference) (this doc)

This page contains explanations for common errors from AQL to help you quickly debug and resolve issues.

## ERR-0: Unexpected internal error {#ERR-0}
**Description:** An unexpected internal error occurred in the AQL parser that wasn't anticipated by the system.

**Solution:** Contact support@holistics.io with details about what you were doing when the error occurred.

## ERR-1: Syntax error {#ERR-1}
**Description:** Your AQL query contains a syntax error that violates the grammar rules of the language.

**Common Causes:**
- Using `=` instead of `==` for equality comparison
- Using `<>` instead of `!=` for inequality comparison
- Missing quotes around string literals
- Unclosed parentheses or brackets

**Example:**
```
Syntax error.
> 1 | users.id = 4000
    |          ^

Expected one of the following:

'!=', '*', '+', '-', '/', '//', ';', '<', '<=', '==', '>', '>='
```

**Solution:** Check the position indicated by the arrow (^) and replace the incorrect syntax with one of the suggested alternatives.

## ERR-100: Invalid expression {#ERR-100}
**Description:** This is a general error for issues that haven't been classified with a specific error code yet.

**Solution:** Review the specific error message provided, which should give context about the problem. If you can't resolve the issue, contact support@holistics.io so we can improve our documentation.

## ERR-101: Relationship not found {#ERR-101}
**Description:** Your query is trying to use fields from unrelated models (models that have no relationships defined between them).

**Example:**
```aml
users | select(unrelated_model.id)
```

**Solution:**
1. Ensure that a relationship between the models exists in your dataset
2. Review the [Relationship documentation](/docs/relationships) to learn how to define relationships

## ERR-102: Model not found {#ERR-102}
**Description:** The model you're referencing in your query doesn't exist in the dataset.

**Common Causes:**
1. The model hasn't been added to the dataset you're using
2. You're using a cross-model field in Model Preview instead of Dataset Preview
3. There's a typo in the model name

**Solution:**
- Check if the model exists in your dataset and add it if needed
- Switch to Dataset Preview when working with cross-model fields
- Verify the spelling of model names in your query

## ERR-103: Field not found in model {#ERR-103}
**Description:** The field you're trying to access doesn't exist in the specified model.

**Common Causes:**
1. Typo in the field name
2. The field exists in a different model
3. The field hasn't been defined yet

**Solution:**
- Check for typos in field names
- Verify that you're referencing the correct model
- Make sure the field is defined in the model

## ERR-104: Fanout detected {#ERR-104}
**Description:** This error occurs when you're trying to access a "many" model from a model on the "one" side of a relationship.

**Example:**
```aml
orders | select(orders_items.quantity)
```

<VideoPlayer src="https://cdn.holistics.io/docs/as-code/concepts/cross-model/one-to-many.mp4" />

This also applies when accessing other models in the definition of a dimension:

```aml
Model orders {
  dimension item_quantity {
    // This will error
    definition: @aql order_items.quantity ;;
  }
}
```

**Solution:**
1. Change the source table that you're starting from (by changing the source or where the dimension is defined)
2. Apply an aggregation on the column:
   - For metrics: `orders | group(orders.id) | select(sum(orders_items.quantity))`
   - For dimensions:
   ```aml
   Model orders {
     dimension item_quantity {
       definition: @aql dimensionalize(sum(order_items.quantity), orders.id) ;;
     }
   }
   ```
3. In some cases, both tables are on the "many" side with a "one" table in the middle. You can use [unique](/reference/aql/unique) to obtain a table with the cartesian product of the relevant fields:
   ```aml
   // users have many wishlist_products, and many (bought) products
   unique(wishlist_products.price, products.price)
   | select(wishlist_products.price - products.price)
   | avg() // average delta of wishlist and actual buy
   ```

## ERR-105: Model in aql field not found {#ERR-105}
**Description:** Same as [ERR-103](/reference/aql/error-reference#ERR-103) - the model referenced in an AQL field cannot be found.

## ERR-106: Relationship path not found {#ERR-106}
**Description:** Same as [ERR-101](/reference/aql/error-reference#ERR-101) - the relationship path between models cannot be found.

## ERR-200: Invalid function argument count {#ERR-200}
**Description:** The function was called with an incorrect number of arguments.

**Example:**
[div](/reference/aql/math-functions#div) called as `div(4)` instead of `div(4, 2)`.

**Solution:**
- Check the function documentation to see how many arguments it requires
- Make sure you're providing all required arguments

## ERR-201: Invalid argument type {#ERR-201}
**Description:** Same as [ERR-240](/reference/aql/error-reference#ERR-240) - the type of argument provided to a function is not compatible with what the function expects.

## ERR-202: Unknown identifier {#ERR-202}
**Description:** The model, field, or metric referenced in the query does not exist in the current scope. This can also be due to the same error as [ERR-102](/reference/aql/error-reference#ERR-102).

**Example:**
```aml
users | select(one: 1) | select(two) // <-- this does not exist
```

**Solution:**
- Check for typos in identifiers
- Ensure the referenced item is defined and accessible in the current scope
- Verify that all required models are included in your dataset

## ERR-203: Unsupported operator for type {#ERR-203}
**Description:** The operator being used is not supported for the data type it's being applied to.

**Example:**
```aml
// error
// This will error
users.last_name + " " + users.first_name
// while this is fine
concat(users.last_name, " ", users.first_name)
```

**Solution:**
Check the table of supported operators for the type you're using, such as [Text Operators](/reference/aql/type-text#text-operator).

## ERR-204: Type mismatch {#ERR-204}
**Description:** AQL expected a specific data type in this position but found a different one instead.

**Example:**
```
// This will error
users.id + ''
//          ^
// Expected `Number`, found `Text`.  (ERR-204)
```

**Solution:**
Use the correct type of value for the operation.

## ERR-205: Invalid named expression {#ERR-205}
**Description:** You tried to name an expression that cannot be used as a field.

**Example:**
```aml
// This will error
users | select(abc: relationship(users.id - users.age, true, 'two_way')) | count()
//             ^
// Named expression expects a field or scalar value, found `unknown`  (ERR-205)
```

**Solution:**
Only use named expressions for fields or scalar values.

## ERR-206: Non-scalar value found {#ERR-206}
**Description:** AQL expected a scalar-like value (number, text, array of text, etc.) but found a different type.

**Solution:**
Similar to [ERR-205](#ERR-205), make sure you're using scalar values where required.

## ERR-209: Dimensionalize not allowed here {#ERR-209}
**Description:** You tried to use `dimensionalize()` inside a metric definition instead of a dimension definition, or nested inside another `dimensionalize()` call.

**Example 1:**
```aml
metric item_quantity {
  // This will error
  definition: @aql dimensionalize(sum(order_items.quantity), orders.id) ;;
}
```

**Example 2:**
```aml
dimension item_quantity {
  definition: @aql dimensionalize(
    // This will error
    dimensionalize(sum(order_items.quantity), orders.id)
    , users.id
  ) ;;
}
```

**Solution:**
1. For the first case, move the definition to a dimension instead of a metric
2. For the second case, break the nested dimensionalize into separate dimensions

## ERR-210: Cannot reference aql field from sql {#ERR-210}
**Description:** You tried to use an AQL field from an SQL field.

**Example:**
```aml
dimension value {
  definition: @aql products.price * order_items.quantity ;;
}
dimension value_discounted {
  definition: @sql {{ value }} * {{ discount }} ;;
}
```

**Solution:**
Change the SQL field to an AQL field.

## ERR-211: Right side of pipe must be a function {#ERR-211}
**Description:** Usually due to pipe precedence issues.

**Example:**
```aml
// This will error
users | count(users.id) / 2
```

AQL interprets this as piping users to a division of 2 numbers:
```aml
// This will error
users | (count(users.id) / 2)
```

**Solution:**
Use parentheses to clarify precedence or use the non-pipe form:
```aml
// Correct with parentheses
(users | count(users.id)) / 2

// Correct without pipe
count(users, users.id) / 2
```

## ERR-213: Member not found in module {#ERR-213}
**Description:** You referenced a non-existent member of an AML module.

**Solution:**
Double-check if the referenced member actually exists in the module. See [AML Module](/reference/aml/module) for more information.

## ERR-215: User attribute not found {#ERR-215}
**Description:** The user attribute referenced in the query does not exist.

**Example:**
```aml
// This will error
H.current_user.not_exists + 300
```

**Solution:**
Remove the reference or create the missing user attribute. See [User attribute](/docs/admin/user-attributes) for more information.

## ERR-216: Multiple values in user attribute {#ERR-216}
**Description:** A user attribute with multiple values is being used in a context that requires a single value.

**Example:**
```aml
// H.current_user.groups is set to ['Admin', 'BU', 'DA']
// This will error
users.group == H.current_user.groups
```

**Solution:**
Use operators that work with multiple values:
```aml
// H.current_user.groups is set to ['Admin', 'BU', 'DA']
users.group in H.current_user.groups
```

## ERR-220: Unsupported behavior {#ERR-220}
**Description:** Behaviors that cannot be expressed in all supported SQL dialects, and thus AQL cannot support them correctly.

**Examples:**
- Selecting an interval: `users | select(_interval: interval(1 month))`
- Adding/subtracting intervals: `(interval(1 month) + interval(2 day))`
  - Note that `users.created_at + interval(1 month) + interval(2 day)` is fine because it's evaluated left to right without adding intervals directly together
- `running_total(median())`
- `running_total(count_distinct())` - Use `running_total(approx_count_distinct())` as an alternative (supported on Snowflake, BigQuery, Databricks, and Presto/Athena)

**Solution:**
When encountering these errors, you may need to fall back to `@sql` to use database-specific functions. For `running_total(count_distinct())`, consider using `running_total(approx_count_distinct())` which provides an approximate count with 2-3% error margin and is much more performant for large datasets.

## ERR-225: Row expression must contain only dimension {#ERR-225}
**Description:** You included a measure in a row expression for comparison.

**Example:**
```aml
// This will error
users | where({users.id, count_orders} in /* some table */)
```

**Solution:**
Remove the measure from the row expression and filter it in a separate step with [filter](/reference/aql/filter).

## ERR-226: Invalid row column subset {#ERR-226}
**Description:** The target table does not contain the field you want to filter.

**Example:**
```aml
users
// This will error
| where({users.id} in users | select(users.first_name, users.last_name))
```

**Solution:**
Add the missing field to the target of `in` or make sure the row and the target table have matching fields:
```aml
users
| where({users.id} in orders | select(orders.user_id)) // this is fine
```

## ERR-227: Cannot match row with table literal {#ERR-227}
**Description:** You tried to match a multi-column row with a simple array.

**Example:**
```aml
users
// This will error
| where({users.id, users.name} in [1, 2, 3])
```

**Solution:**
Remove other columns and keep only one column to match with the array.

## ERR-229: Field already declared {#ERR-229}
**Description:** A field with the same name has already been declared in modeling or ad-hoc.

**Solution:**
Use a different name for the column.

## ERR-232: Invalid window frame {#ERR-232}
**Description:** When passing a range to a window function, the frame must be valid and cannot go backward.

**Example:**
```aml
window_avg(count(users.id), 5..-1, order: users.created_at | month())
//                          ^
//               Invalid window frame.
```

**Solution:**
Use a valid window frame range.

## ERR-233: Cyclic field dependency {#ERR-233}
**Description:** A cyclic dependency was detected in field definitions, which would lead to infinite recursion.

**Example:**
```aml
dimension field_a {
  definition: @aql field_b ;;
}
dimension field_b {
  definition: @aql field_c ;;
}
dimension field_c {
  definition: @aql field_a ;;
}
```
Cyclic dependency: field_a -> field_b -> field_c -> field_a

**Solution:**
Break the cycle in the field definitions.


## ERR-234: Invalid shorthand aggregation {#ERR-234}
Aggregation functions in AQL normally need a table as their first argument and an expression as the second:
```aml
count(users, users.id)
```

To make your code less verbose, AQL offers a shorthand form that automatically infers the table from the expression:
```aml
count(users.id)
// -> AQL infers this to be count(users, users.id)

sum(order_items.quantity * 2)
// -> AQL infers this to be sum(order_items, order_items.quantity * 2)

sum(products.price * products.discount)
// -> AQL infers this to be sum(products, products.price * products.discount)
```

Here's the catch: this shorthand only works when all fields in the expression come from the same model. You'll get this error when trying to mix fields from different models:
```aml
// This will error
sum(products.price * order_items.amount)
```

The fix is straightforward – explicitly provide the table as the first argument:
```aml
// highlight-next-line
sum(order_items, products.price * order_items.amount)
```

## ERR-235: Unsupported date unit {#ERR-235}
**Description:** You tried to use an incorrect unit for a date function.

**Examples:**
```aml title="Extracting minute from a date"
// This will error
date_part('minute', users.created_date)
```

```aml title="Using a wrong unit"
// This will error
date_part('unix_time', users.created_date)
```

**Solution:**
Consult the documentation for [datetime functions](/reference/aql/time-intelligence-functions) to use the correct units.

## ERR-236: Invalid conditional expression {#ERR-236}
**Description:** Conditions must follow specific forms to be valid in AQL. See [Condition Types](/reference/aql/where#condition-types) in the `where()` documentation for detailed explanations of each condition type.

**Valid Simple Conditions:**
- **Constant Condition** - `dimension operator constant_value`:
  ```aml
  orders.status == 'delivered'
  orders.created_at matches @(last 7 days)
  orders.status in ['delivered', 'cancelled']
  ```
- **Single Model Condition** - expressions using fields from a single model:
  ```aml
  date_diff('day', orders.created_at, orders.delivered_at) < 30
  // and/or combinations within single model:
  orders.status == 'delivered' and orders.amount > 100
  ```
- **Cross Model Condition** - expressions using fields from multiple models:
  ```aml
  products.price < 30 and order_items.quantity == 3
  // and/or combinations across models:
  products.category == 'Electronics' or users.country == 'US'
  ```

**Valid Complex Conditions:**
- **Table Condition** - `dimension in table_expression` or just `table_expression`:
  ```aml
  // Explicit form
  orders.status in unique(orders.status)
  | where(orders.status != 'delivered')

  // Implicit form (internally {users.id} in ...)
  top(5, users.id, by: value)
  ```
- **Semi-additive Condition** - `dimension operator metric`:
  ```aml
  users.age > avg(users.age)
  ```

**Common Invalid Cases:**
- Using and/or between complex conditions or between complex and simple conditions:
  ```aml
  // Invalid: OR between table condition and simple condition
  where(users.id in top(5, users.id, by: users.revenue) or users.country == 'US')

  // Invalid: AND between two complex conditions
  where(users.age > avg(users.age) and users.id in top(10, users.id, by: users.revenue))
  ```

**Solutions:**
1. For AND conditions - separate into multiple condition parameters:
   ```aml
   // Instead of: where(users.age > avg(users.age) and users.id in top(10, users.id, by: users.revenue))
   // Use:
   count(users.id)
   | where(users.age > avg(users.age), users.id in top(10, users.id, by: users.revenue))
   ```

2. For OR conditions - rewrite as a single complex condition.

## ERR-237: Unknown function {#ERR-237}
**Description:** The function being called does not exist.

**Solution:**
Check for typos and refer to the [function cheatsheet](/reference/aql/functions) for all available functions.

## ERR-246: No primary key found for model {#ERR-246}
**Description:** This error occurs when using a [Single Model Condition](/reference/aql/where#single-model-condition) on a model that doesn't have a primary key defined.

**Example:**
```aml
// Model definition without primary key
Model orders {
  dimension id {
    type: 'number'
  }
  dimension created_at {
    type: 'datetime'
  }
}

// This will error
count(orders.id) | where(date_diff('day', orders.created_at, orders.delivered_at) < 30)
```

**Solution:**
Add `primary_key: true` to one dimension in your model definition:
```aml
Model orders {
  dimension id {
    type: 'number'
    primary_key: true  // Add this line
  }
  dimension created_at {
    type: 'datetime'
  }
}
```

## ERR-238: Cannot match row with table {#ERR-238}
**Description:** Similar to [ERR-227](#ERR-227), but with real tables instead of table literals.

**Example:**
```aml
users
// This will error
| where({users.name} in users | select(users.id))
```

**Solution:**
Use matching column types or cast the right side.

## ERR-239: Duplicate field name {#ERR-239}
**Description:** There are two fields with the same name in the table.

**Example:**
```aml
users
// This will error
| select(one_field: 1, one_field: 1)
```

**Solution:**
Use different names for fields.

## ERR-240: Function expected other type of arguments {#ERR-240}
**Description:** The function expects arguments of one type but received another type.

**Solution:**
Update the input to match the expected type or use a different function.

## ERR-241: Nested window function not allowed {#ERR-241}
**Description:** Window functions cannot be nested inside other window functions.

**Example:**
```aml
window_sum(rank(order: order_items.quantity), ..)
```

**Solution:**
Unnest the window functions by moving the inner window function to a dimension, then use that instead of nesting.

## ERR-243: Field is neither group nor aggregated {#ERR-243}
To understand this error, you first need to understand how dimensions and metrics work in AQL:
- Dimensions are used for grouping data
- Metrics are aggregation expressions that get sliced by those groupings

But, it's a perfectly valid use case to put reference to dimension **inside a metric definition**.
```aml
explore {
  dimensions {
    products.name,
    products.discount // <---This-----------------------------------------+
  }                   //                                                    ` +
                      //                                                        `
                      //                                                         |
  measures {          //                                                         |
    discounted_value: total_value * products.discount // <- this is referencing this
  }
}
```

The error happens when you remove `products.discount` from the dimensions in the exploration. Since the data isn't grouped by `products.discount` anymore, you can't reference it directly in a metric.

This is not unique to AQL, as you can see the same error in SQL.
<img src="https://cdn.holistics.io/product/aql-sql-group-error-20250306-674.png" width="988" height="311" />

To fix this issue, consider what you're really trying to do:

1. If you're only referencing dimension fields, create a dedicated dimension in an appropriate model instead:
   <img src="https://cdn.holistics.io/product/aql-add-adhoc-dimension-20250306-675.png" width="759" height="255" />

2. If you're mixing metrics and dimensions, wrap any dimension references in an aggregation function that makes sense for your data:
   ```aml
   total_value * max(products.discount)
   ```

This way, your field will work regardless of which dimensions are active in the explore.

Alternatively, if you expect the dimension to always be active anyway, you can add it back and just visually hide it in the UI.

## ERR-244: Invalid table condition {#ERR-244}
This error occurs with table conditions (which take the form `dimension in table`). These conditions only work when AQL can clearly determine which fields the table contains at runtime.

For example, at first glance this looks correct:
```aml
// This will error
users.id in users
```

But here's the issue: models in AQL can contain fields from related models as well, so it's not clear which fields should be used for the comparison. AQL can't determine exactly what you're trying to match against.

To fix this, always use `select` to explicitly specify which fields should be used for comparison:
```aml
// highlight-next-line
users.id in users | select(users.id)
```

## ERR-245: Invalid datetime format {#ERR-245}
**Description:** The datetime literal syntax isn't recognized by the natural language parser.

**Solution:**
Check the documentation for [Natural Time Expression](/docs/datetimes/relative-dates#relative-time-expressions) for supported syntax.

## WARN-300: Should follow group with select or filter {#ERR-300}

**Description**: This warning occurs when an aggregate function directly follows a `group()` function without using `select()` or `filter()` in between.

While you might expect `table | group(dimension) | aggregate_function()` to return grouped results, this pattern isn't valid in AQL.

**Why This Happens**: Aggregate functions (like `count()`, `sum()`, etc.) return single scalar values, not grouped tables.

To maintain the grouping structure while performing aggregations, you must use `select()` or `filter()` to properly apply the aggregation within the grouped context.

**Solutions**:

1. **Consider if grouping is necessary**: Metrics in AQL are automatically sliced by dimensions introduced from explore/visualize without explicit grouping. You typically only need manual grouping for nested aggregations.

  If you really need nested aggregation, you can write:

  ```aml title="This works but may trigger the lint warning"
  users | group(users.id) | avg(count(orders.id))
  ```

  ```aml title="More readable alternative that avoids the warning"
  users | group(users.id) | select(count(orders.id)) | avg()
  ```

2. Use `select()` or `filter()` with your aggregations

  ```aml title="❌ Incorrect usage"
  // This will error
  users | group(users.id) | count(orders.id)
  ```

  ```aml title="✅ Correct with select()"
  users | group(users.id) | select(count(orders.id))
  ```

  ```aml title="✅ Correct with named columns"
  users | group(users.id) | select(order_count: count(orders.id))
  ```

  ```aml title="✅ Correct with filter()"
  users | group(users.id) | filter(count(orders.id) > 5)
  ```

**Key Takeaway**
Always follow `group()` operations with either `select()` or `filter()` when performing aggregations to maintain the proper grouped table structure.
