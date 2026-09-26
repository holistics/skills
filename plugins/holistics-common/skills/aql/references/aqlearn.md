# AQL Lessons

## 1. Aggregate Functions
**Aggregate Functions** (like `count`) group values of a column into a single summary value.

Syntax: `table | aggregate_func(column)`, e.g. `orders | count(orders.id)`.

Example explore using multiple aggregate functions:
```aql
explore {
  measures {
    count_of_orders: orders | count(orders.id),
    latest_order_time: orders | max(orders.created_at),
    oldest_order_time: orders | min(orders.created_at),
    avg_order_discount: orders | avg(orders.discount),
    order_cost: order_items | sum(order_items.quantity * products.price - orders.discount),
  }
  dimensions {
    order_status: orders.status,
  }
  sorts {
    order_status ASC,
  }
}
```

All measures here are broken down by `orders.status`.

Semantically, an input **table** of an aggregate function acts as the **Source Table** for that function.  
It allows the function to "reach" or "access" fields in other tables as long as the relationship (either direct or indirect) between the **Source Table** and the **other table** is **many-to-one**.

**IMPORTANT**:
* Always put the **many-side table** as the **Source Table** when using aggregate functions.
* You **CANNOT** use aggregate function when Source Table and the column have **many-to-many** relationship. It would result in a **Fanout error**

## 2. Dimensions & Measures
* "Dimensions" are the fields that **break down** or
[_dice_](https://www.hypertextbookshop.com/dataminingbook/public_version/contents/chapters/chapter003/section004/blue/page004.html)
your "Measures".
* "Measures" (or "Metrics") are **calculations that are aggregated over the Dimensions**.

By choosing the Dimensions, you can view your Measures with the desired level of detail.

Example:
```aql
explore {
  measures {
    count_of_orders: orders | count(orders.id),
  }
  dimensions {
    order_delivery_attempts: orders.delivery_attempts,
    order_status: orders.status,
  }
  sorts {
    order_status ASC,
  }
}
```

We have found the count of orders broken down by `orders.delivery_attempts` and `orders.status`.

Measures/metrics can be broken down by zero or more dimensions!

## 3. Date Trunc
`date_trunc()` truncates a date/datetime field to a time granularity. Two syntactic forms:
```aql
date_trunc(orders.created_at, 'month')   // function form
orders.created_at | month()              // short-hand
```
Available granularities: `'day'`, `'month'`, `'year'`, `'quarter'`, `'hour'`, `'minute'`, etc.

Example explore:
```aql
explore {
  measures {
    avg_order_discount: orders | avg(orders.discount),
  }
  dimensions {
    time: orders.created_at | year(),
  }
  sorts {
    time ASC,
  }
}
```
This calculates the average order discount per year.

**Caveat**: **CANNOT** use `date_trunc()`, `year()`, etc. inside `explore.filters`.

## 4. Explore Filters

Explore-level filtering uses two blocks (same syntax, both AND-combined, both applied to all explore measures):
* `explore.filters {}` — conditions on **dimensions** (like SQL `WHERE`). E.g. `orders.status == 'delivered'`.
* `explore.having {}` — conditions on **metrics / measures / aggregations** (like SQL `HAVING`). E.g. `order_count > 10`.

Put each condition in the block matching its left operand — dimension conditions in `filters`, metric conditions in `having`.

Filter expressions use AQL Operators:
```aql
orders.created_at > @2024
users.email like '%.com'
```

Example explore:
```aql
explore {
  measures {
    count_of_users: users | count(users.id),
  }
  filters {
    users.sign_up_at < @(2 years ago),
    users.last_name in ['Kasey', 'Stacey'],
  }
  dimensions {
    time: users.sign_up_at | year(),
  }
  sorts {
    time ASC,
  }
}
```
Result: user count by sign-up year, filtered to Kasey/Stacey who signed up over 2 years ago.

IMPORTANT: Explore filters are combined by **AND** logic.

For date/time filtering, you can use time expressions via this syntax `matches @(time_expression)`:
* `matches @(single_period)`
* `matches @(start_period - end_period)` or `matches @(start_period to end_period)` (end-inclusive)
* `matches @(start_period until end_period)` (end-exclusive)

<example>
<aql>orders.created_at matches @(last year)</aql>
<description>Orders that are created last year</description>
</example>
<example>
<aql>orders.created_at matches @(2 years ago - last year)</aql>
<description>Orders that are created last year and the year before.</description>
</example>
<example>
<aql>orders.created_at matches @(2 years ago until last year)</aql>
<description>Orders that are created in 2020, if current year is 2022</description>
</example>
<example>
<aql>orders.created_at matches @(2019)</aql>
<description>Orders that are created in 2019</description>
</example>
<example>
<aql>orders.created_at matches @(2018-02-03)</aql>
<description>Orders that are created on February 3rd, 2018</description>
</example>
<example>
<aql>orders.created_at is not @(2018)</aql>
<description>Orders that are **not** created in 2018</description>
</example>
<example>
<aql>orders.created_at is not @(2018 - 2019)</aql>
<description>Orders that are **not** created in 2018 and 2019</description>
</example>

Examples for filtering on metrics (metric conditions go in `explore.having`):
```aql
metric delivered_orders = orders | count(orders.id) | where(orders.status == 'delivered');
metric cancelled_orders = orders | count(orders.id) | where(orders.status == 'cancelled');
metric orders_diff = cancelled_orders - delivered_orders;
explore {
  measures {
    delivered_orders: delivered_orders,
    cancelled_orders: cancelled_orders,
  }
  dimensions {
    product_name: products.name,
  }
  having {
    orders_diff > 10,
  }
  sorts {
    product_name ASC,
  }
}
```

## 5. Relationships
AQL can perform analytics on multiple models together within the same AQL query.
To enable such capability, the relationships among the models must already be pre-defined.

Let's see some simple examples where we perform AQL queries across multiple models.
Given these relationships:
```yaml
- from_model: orders
  from_fields: [orders.user_id]
  to_model: users
  to_field: id
  type: many_to_one
- from_model: users
  from_fields: [city_id]
  to_model: cities
  to_field: id
  type: many_to_one
- from_model: countries
  from_fields: [code]
  to_model: cities
  to_field: country_code
  type: one_to_many
- from_model: order_items
  from_fields: [order_items.order_id]
  to_model: orders
  to_field: id
  type: many_to_one
- from_model: order_items
  from_fields: [order_items.product_id]
  to_model: products
  to_field: id
  type: many_to_one
```

Example 1:
```aql
explore {
  dimensions {
    country: countries.name,
    city: cities.name,
  }
  sorts {
    country ASC,
    city ASC,
  }
}
```
This lists out all cities and their corresponding countries.

Example 2:
```aql
explore {
  measures {
    count_users: users | count(users.id),
  }
  dimensions {
    country: countries.name,
    city: cities.name,
  }
  sorts {
    country ASC,
    city ASC,
  }
}
```
This calculates the count of users broken down by `countries.name` and `cities.name`.

Example 3:
```aql
explore {
  measures {
    count_orders: orders | count(orders.id),
    count_distinct_products: products | count_distinct(products.id),
  }
  dimensions {
    sign_up_year: users.sign_up_at | year(),
  }
  filters {
    cities.name == 'London',
  }
  sorts {
    sign_up_year ASC,
  }
}
```
Yields the **count of orders** and **distinct products** by **year of sign-up**, for users in **London**.

AQL handles the joins automatically — once relationships are defined, just specify dimensions and measures.

## 6. Text literals
Example text literals:
```aql
explore {
  filters {
    users.last_name in ['Kasey', "Stacey", "Wendy's", 'Lily\'s'],
  }
}
```

## 7. pipe
Pipe `|` is a shorthand syntax. `argument1 | function(argument2)` is equivalent to `function(argument1, argument2)`.

**NOTE**: Pipe `|` has **lower** syntax precedence than arithmetic operators -> **make sure to parenthesize properly**.

## 8. Level of Detail
**Level of detail** (aka **granularity**) of a measure is dictated by the dimensions that break it down.

Analytics often need to combine multiple levels of detail. AQL provides level-of-detail (LOD) functions for this:
* `exclude_grains` (alias: `of_all`)
* `keep_grains`
* `dimensionalize`

## 9. exclude_grains
Basic syntax:
```aql
metric | exclude_grains(dimension1, dimension2, ...)
```
`metric` is calculated _of all_ values of the listed dimensions, i.e. **not** broken down by them.

With this AQL explore
```aql
metric user_count = users | count(users.id);

explore {
  dimensions {
    country: countries.name,
    city: cities.name,
  }
  measures {
    user_count: user_count,
    user_count_of_all_city_names: user_count | exclude_grains(cities.name, keep_filters: true),
  }
  filters {
    countries.name in ['United Kingdom', 'Germany'],
  }
  sorts {
    country ASC,
    city ASC,
  }
}
```
* `user_count` is broken down by **both** `countries.name` and `cities.name`
* `user_count_of_all_city_names` uses `exclude_grains()` and is broken down by **only** `countries.name`, **not** `cities.name`
* The `keep_filters` option makes `exclude_grains` keep the filters on the excluded dimensions

=> `exclude_grains` calculates a metric at a level of detail **lower** than the explore by excluding the listed dimensions.

**NOTE**: The excluded dimensions (i.e. dimensions in the arguments of `exclude_grains`) **MUST** be present in the explore.

A very common use case for this is calculating the "Percent of Total":
```aql
metric user_count = users | count(users.id);

explore {
  dimensions {
    country: countries.name,
    city: cities.name,
  }
  measures {
    user_count: user_count,
    user_count_of_all_city_names: user_count | exclude_grains(cities.name),
    user_count_over_all_cities_percentage: user_count * 100.0 / (user_count | exclude_grains(cities.name)),
  }
  filters {
    countries.name in ['United Kingdom', 'Germany'],
  }
  sorts {
    country ASC,
    city ASC,
  }
}
```
Example result:
| countries.name  | cities.name  | user_count | user_count_of_all_city_names | user_count_over_all_cities_percentage |
| :-------------- | :----------- | :--------- | :--------------------------- | :------------------------------------ |
| Germany         | Berlin       | 88         | 181                          | 48.62                                 |
| Germany         | Frankfurt    | 93         | 181                          | 51.38                                 |
| United Kingdom  | Cambridge    | 80         | 177                          | 45.20                                 |
| United Kingdom  | London       | 97         | 177                          | 54.80                                 |

**NOTE**: Make sure to exclude all the necessary dimensions in the explore.
For example, when there are multiple dimensions of `cities` in the explore, to calculate the user count over all cities, we need to use `exclude_grains` on **all dimensions** of `cities` **in the explore**:
```aql
metric user_count = users | count(users.id);

explore {
  dimensions {
    country: countries.name,
    city_id: cities.id,
    city: cities.name,
  }
  measures {
    user_count: user_count,
    user_count_of_all_cities: user_count | exclude_grains(cities.id, cities.name),
    user_count_over_all_cities_percentage: user_count * 100.0 / (user_count | exclude_grains(cities.id, cities.name)), // exclude both cities.id and cities.name
    user_count_over_all_countries_percentage: user_count * 100.0 / (user_count | exclude_grains(countries.name, cities.id, cities.name)), // exclude countries.name, cities.id, cities.name
  }
  filters {
    countries.name in ['United Kingdom', 'Germany'],
  }
  sorts {
    country ASC,
    city_id ASC,
  }
}
```

## 10. keep_grains
As opposed to `exclude_grains` which excludes specific dimensions, `keep_grains` only **keeps** the specified dimensions
and **excludes all remaining dimensions**.

Basic syntax:
```aql
metric | keep_grains(dimension1, dimension2, ...)
```

**NOTE**: The kept dimensions (i.e. dimensions in the arguments of `keep_grains`) **MUST** be present in the explore.

Thus, `keep_grains` is another way to calculate metrics with a _level of detail_ **lower** than the explore's level of detail.

In this example:
```aql
metric user_count = users | count(users.id);

explore {
  dimensions {
    country: countries.name,
    city_id: cities.id,
    city: cities.name,
  }
  measures {
    user_count: user_count,
    user_count_by_country: user_count | keep_grains(countries.name),
    user_count_of_all_cities: user_count | exclude_grains(cities.id, cities.name),
  }
  filters {
    countries.name in ['United Kingdom', 'Germany'],
  }
  sorts {
    country ASC,
    city ASC,
  }
}
```
the results of `user_count_by_country` and `user_count_of_all_cities` are the same,
because they both effectively break down `user_count` by `countries.name` **only**.

When we add `users.gender` to the explore dimensions:
```aql
metric user_count = user | count(users.id);

explore {
  dimensions {
    country: countries.name,
    city_id: cities.id,
    city: cities.name,
    gender: users.gender, // new dimension
  }
  measures {
    user_count: user_count,
    user_count_by_country: user_count | keep_grains(countries.name),
    user_count_of_all_cities: user_count | exclude_grains(cities.id, cities.name),
  }
  filters {
    countries.name in ['United Kingdom', 'Germany'],
  }
  sorts {
    country ASC,
    city ASC,
    gender ASC,
  }
}
```
Now we see that:
* `keep_grains` **keeps** `user_count_by_country` broken down by **only** `countries.name`, regardless of new dimensions in the explore.
* while `exclude_grains` **excludes** `cities.id` and `cities.name` when calculating `user_count_of_all_cities`, so `user_count_of_all_cities` is broken down by both `countries.name` and `users.gender`.

## 11. dimensionalize
`dimensionalize` breaks the metric down by the specified dimensions. It allows us
to calculate metrics at a **fixed** _level of detail_ that can be **different** from the explore's level of detail.

For example, let's say we are grouping the countries based on their user count:
* If a country's user count is **greater than 180**, then the country is grouped as **"Good"**
* **Otherwise**, the country is grouped as **"Not good"**

Then, we want to count the number of countries in each group for each continent.

Sample output:
| countries.continent_name  | countries.group | country_count |
| :------------------------ | :-------------- | :------------ |
| Asia                      | Good            | 2             |
| Asia                      | Not good        | 3             |

We can use this AQL:
```aql
dimension countries.user_count = users | count(users.id) | dimensionalize(countries.name);
dimension countries.group = case(when: countries.user_count > 180, then: "Good", else: "Not good");

explore {
  dimensions {
    continent: countries.continent_name,
    group: countries.group,
  }
  measures {
    country_count: countries | count(countries.name),
  }
  filters {
  }
  sorts {
    continent ASC,
    group ASC,
  }
}
```

=> `dimensionalize()` also turns metrics into **dimensions** for further calculations/aggregations.

**NOTE**: `dimensionalize` can ONLY be used when declaring a `dimension`. It CANNOT be used directly inside an AQL `explore` or `metric`.

## 12. Nested Aggregation
Nested aggregation can be performed by `unique()` **followed by** `select()`.

Steps to calculate a nested aggregation:
1. **Build the Metric**:
    1. Start with `unique(inner_dimensions)` (i.e. the fields being grouped for inner aggregation).
    2. Pipe to `select(inner_aggregation)`
    3. Pipe to `outer_aggregation()`.
2. **Use the Metric** in the explore:
    1. Add the Metric to the explore **measures**
    2. Break down the **outer aggregation** by specifying the explore **dimensions**

Notes:
* `inner_aggregation` is broken down by `inner_dimensions`
* while `outer_aggregation` will be broken down by `explore.dimensions` when the Metric is used in an explore

Some nested aggregation examples:
* Total count of users per city: `unique(cities.name) | select(v: users | count(users.id)) | sum(v)`
* Average count of users per city: `unique(cities.name) | select(v: users | count(users.id)) | avg(v)`
* Average metric_x per city: `unique(cities.name) | select(v: metric_x) | avg(v)`
* Highest average user age per city: `unique(cities.name) | select(v: users | avg(users.age)) | max(v)`
* Let x be the highest average user age per city, calculate median of x per continent: `unique(countries.continent) | select(v: unique(cities.name) | select(v: users | avg(users.age)) | max(v)) | median(v)`

## 13. Filter on Aggregation

Filter on aggregation can be performed by `unique()` **followed by** `filter()`.

To filter the **explore result** by a metric/aggregation, use the `explore.having {}` block instead (see §4) — e.g. `having { order_count > 10 }`.


## 14. Window functions
### Window functions are **metrics**
=> Either
* Put them in `explore.measures`
* Or declare as a model dimension first before putting them in `explore.dimensions`
  * Use this when it does not make sense to put `order` or `partition` columns in the explore dimensions.

Example:
```aql
metric next_order_price = next(order.price, order: order.id | asc(), partition: order.id);
explore {
  dimensions {
    id: order.id,
    price: order.price, // NOTE: order.price is a dimension
  }
  measures {
    next_order_price: next_order_price,
  }
  sorts {
    id ASC,
  }
}
```

or
```aql
// We don't want to include items.ordinal_number in explore dimensions
dimension items.next_item_price_in_order = next(items.price, order: items.ordinal_number | asc(), partition: orders.id);
explore {
  dimensions {
    order_id: order.id,
    item_id: items.id
    price: items.price,
    next_item_price: items.next_item_price_in_order,
  }
  sorts {
    order_id ASC,
    item_id ASC,
  }
}
```

## 15. Ranking
When doing ranking (e.g. using `top`, `bottom`)
* Include the ranking in the explore dimensions/measures if possible, so that the user can view the ranks conveniently.
* If you use ranking in filters, MAKE SURE the ranking uses the same granularity as the explore.

### Ranking in filters
For example, given this question: Show the order count over month in 2005 of top 5 all-time most-ordered products.

#### Good examples
These are the proper answers:
```aql
metric order_count = orders | count(orders.id);
metric top_5_products = top(5, products.id, by: order_count, logic: 'dense');

explore {
  dimensions {
    product_id: products.id,
    product_name: products.name,
    month: demo_orders.created_at | month(),
  }
  measures {
    order_count: order_count,
  }
  filters {
    products.id in top_5_products,
    demo_orders.created_at is @(2005),
  }
  sorts {
    product_id ASC,
    month ASC,
  }
}
```

```aql
metric order_count = orders | count(orders.id);
metric top_5_products = top(5, products.name, by: order_count, logic: 'dense');

explore {
  dimensions {
    product_name: products.name,
    month: demo_orders.created_at | month(),
  }
  measures {
    order_count: order_count,
  }
  filters {
    products.name in top_5_products,
    demo_orders.created_at is @(2005),
  }
  sorts {
    product_name ASC,
    month ASC,
  }
}
```

#### Bad examples
This is a WRONG answer:
```aql
metric order_count = orders | count(orders.id);
metric top_5_products = top(5, products.id, by: order_count, logic: 'dense');

explore {
  dimensions {
    product_name: products.name,
    month: demo_orders.created_at | month(),
  }
  measures {
    order_count: order_count,
  }
  filters {
    products.id in top_5_products,
    demo_orders.created_at is @(2005),
  }
  sorts {
    product_name ASC,
    month ASC,
  }
}
```

Why it is wrong:
For example, top 5 includes these products:
* id: 1, name: Laptop, order_count: 10
* id: 2, name: Phone, order_count: 8
* id: 3, name: Phone, order_count: 4
* id: 4, name: Tablet, order_count: 4
* id: 5, name: Tablet, order_count: 4

Individually by ID, "Laptop" has higher ranking. But when aggregated by name, "Phone" has a higher order_count. Also, only 3 rows of product names appear instead of 5 (since several ids collapse to the same name).

=> This is because the explore wants to aggregate by `products.name`, but the ranking ranked by `products.id` => Different granularities

=> Rule: ranking and explore MUST share the same granularity. Two ways:
  * Include `products.id` in `explore.dimensions` (first good example)
  * Change `top_5_products` to rank by `products.name` (second good example)

### Types of window functions
Navigation window functions allow you to access values from other rows within the same partition:
* previous()
* next()
* first_value()
* last_value()
* nth_value()

Ranking window functions assign a rank to each row based on the value of a specified column:
* rank()
* dense_rank()
* percent_rank()
* ntile()

Aggregate window functions calculate aggregate values across a subset of rows within a partition:
* window_sum()
* window_avg()
* window_min()
* window_max()
* window_count()
* window_stdev()
* window_stdevp()
* window_var()
* window_varp()

### Constraints
* In Navigation and Ranking window functions, the `order` and `partition` columns MUST be present in the table at the function's level-of-detail.
  * If does not make sense to include those columns, you can dimensionalize the Ranking window function.

### Default behaviors
* Partitioning:
  * Omit `partition`, omit `order`: entire table is a single partition.
  * `partition: []`: entire table is a single partition (regardless of `order`).
  * Omit `partition`, specify `order`: all explore dimensions except the `order` column become the partition columns.
* Frame:
  * Omit `order`: default `..` (all rows in partition).
  * Specify `order`: default `..0` (first row to current).

Examples:
```aql
metric user_count = users | count(users.id);
explore {
  dimensions {
    country: countries.name,
    city: cities.name,
  }
  measures {
    user_count: user_count,
    rank_within_each_row: ntile(3, order: user_count | desc()), // partitions by all other explore dims (countries.name, cities.name) — typically not useful
    rank_among_whole_table: ntile(3, order: user_count | desc(), partition: []), // this ranks the user count across the whole table
  }
}
```
```aql
metric price_group_among_all_products = ntile(3, order: product | max(product.price), partition: []);
dimension product.price_group = price_group_among_all_products; // must be declared as a model dimension first before being used in explore.dimensions
explore {
  dimensions {
    category: category.name,
    id: product.id,
    name: product.name,
    price: product.price,
    price_group_among_all_products_as_dim: product.price_group,
  }
  measures {
    price_group_among_all_products: price_group_among_all_products,
    price_group_within_category: ntile(3, order: product | max(product.price), partition: category.name),
  }
}
```

=> Best practice:
* Always specify `order`
* Partitioning:
  * Entire table as a single partition -> use `partition: []`
  * Each row is a partition -> omit `partition`
  * Explicit partition: `partition: column1, partition: column2, ...`

### Common mistakes
- mistake: use `window_count(count)` to calculate "moving count"
  correct: use `window_sum(count)` to calculate "moving count"

### Learn more
Learn more in Window Functions Overview doc.

## 16. Cross-model calculations
### In dimensions
Declare the dimension on the "many" side of the relationship.

Examples:
```
dimension users.identity = concat(user_groups.name, ' ', users.name); // a user group has many users

dimension discounted_price = products.price - products.discount;
```

### In metrics
Use the "many" side of the relationship as the source model.

Examples:
```
metric user_identities = users | select(identity: concat(user_groups.name, ' ', users.name)) | string_agg(identity);

metric total_discounted_price = products | select(v: products.price - products.discount) | sum();
```

## 17. SQL passthrough functions
When a function isn't natively provided in AQL, you can use SQL passthrough functions:
* sql_text()
* sql_number()
* sql_date()
* sql_datetime()
* sql_truefalse()

SQL passthrough aggregation functions:
* agg_text()
* agg_number()
* agg_date()
* agg_datetime()
* agg_truefalse()

Example for BigQuery:
```aql
dimension users.enable_spell_check = sql_truefalse('JSON_QUERY', users.settings, '$.enable_spell_check');
metric approx_uniq_products = agg_number('APPROX_COUNT_DISTINCT', products.name);

explore {
  dimensions {
    user_id: users.id,
    user_enable_spell_check: users.enable_spell_check,
  }
  measures {
    approx_uniq_products: approx_uniq_products,
  }
}
```
Alternative using BigQuery JSON_VALUE (which returns a scalar STRING):
```aql
dimension users.enable_spell_check = cast(sql_text('JSON_VALUE', users.settings, '$.enable_spell_check'), 'truefalse');
```

Example for Postgresql:
```aql
dimension users.enable_spell_check = sql_truefalse('jsonb_path_query', sql_text('to_jsonb', users.settings), '$.enable_spell_check');
metric all_paid = agg_truefalse('BOOL_AND', orders.is_paid);

explore {
  dimensions {
    user_id: users.id,
    user_enable_spell_check: users.enable_spell_check,
  }
  measures {
    all_paid: all_paid,
  }
}
```

# Glossary
Aggregator functions:
* count()
* count_if()
* count_distinct()
* average(). alias: avg()
* min()
* max()
* sum()
* median()
* stdev()
* stdevp()
* var()
* varp()
* corr()
* string_agg()
* percentile_cont()
* percentile_disc()
* min_by()
* max_by()

Time-based functions:
* running_total()
* period_to_date()
* exact_period()
* relative_period()
* trailing_period()
* epoch()
* date_format()
* from_unixtime()
* last_day()
* date_trunc()
* date_part(). Example: date_part('dayofweek', model.date_dimension)
* date_diff(unit, start_date, end_date)

Table functions:
* where()
* group()
* unique()
* top()
* bottom()

Logical functions:
* and
* or
* not()
* case when

Math functions:
* abs()
* sqrt()
* ceil()
* floor()
* round()
* trunc()
* exp()
* ln()
* log10()
* log2()
* pow()
* mod()
* div()
* sign()
* radians()
* degrees()
* pi()
* acos()
* asin()
* atan()
* atan2()
* sin()
* tan()
* cot()

Level-of-detail functions:
* keep_grains()
* exclude_grains(). alias: of_all()
* dimensionalize()

Null/zero functions:
* coalesce()
* nullif()
* safe_divide()

Text functions:
* concat()
* find(): Find index of substring
* left(): Extract substring from the left
* right(): Extract substring from the right
* mid(): Extract substring from the middle
* len()
* lpad()
* rpad()
* lower()
* upper()
* trim()
* ltrim()
* rtrim()
* regexp_extract()
* regexp_like()
* regexp_replace()
* replace()
* split_part()

Miscellaneous functions:
* cast()

AI functions (Snowflake/Databricks only):
* ai_complete(model, prompt): Query an AI model and return the generated response. (Replaces deprecated `ai_query()`.)
* ai_similarity(text1, text2)
* ai_classify(text, ...categories)
* ai_summarize(text)

Operators for **text** fields: is, is not, like, not like, ilike, not ilike, is null, is not null, in, not in
Operators for **number** fields: is, is not, >, <, is null, is not null, in, not in
Operators for **truefalse** fields: is, is not is null, is not null, in, not in
Operators for **datetime** fields: is (matches), is not, is null, is not null

# Rules
### Dimension delaration MUST ALWAYS be associated with a model
* INVALID: `dimension user_count`. Reason: missing model
* VALID: `dimension countries.user_count`

### Must NOT use date_trunc in any date comparison. Use `is` and time expression instead
Do **NOT** use date_trunc() in date comparisons like this:
```aql
dimension users.sign_up_in_2015 = date_trunc(users.sign_up_at, 'year') == @2015;
explore {
  filters {
    users.sign_up_in_2015 is true,
  }
}
```

Use **ONLY** date syntax `@(time expression)` for date comparisons:
```aql
explore {
  filters {
    users.sign_up_at is @(2015),
  }
}
```

### Calculations in dimensions MUST be declared as a new dimension on the root/source model
Do **NOT** make inline dimension calculations in explore or metrics, e.g.
```aql
explore {
  dimensions {
    area: square.side * square.side, // bad
    rounded_area: round(square.side * square.side), // bad
    area_cm: concat(cast(square.side * square.side, 'text'), ' cm'), // bad
    group: concat(canvas.name, ' ', square.color), // bad
  }
  filters {
    square.side * square.side > 10, // bad
  }
}
```

**Refactor** into new `dimension` (with proper root/source model) INSTEAD:
```aql
dimension square.area = square.side * square.side;
dimension square.rounded_area: round(square.side * square.side);
dimension square.area_cm = concat(cast(square.area, 'text'), ' cm');
dimension square.group = concat(canvas.name, ' ', square.color); // a canvas has many squares
explore {
  dimensions {
    area: square.area,
    rounded_area: square.rounded_area,
    area_cm: square.area_cm,
    group: square.group,
  }
  filters {
    square.area > 10,
  }
}
```

NOTE: The source model should be on the "many" side of the relationship.

### MUST use aliases in explore sorts
We can **ONLY** use dimension and measure **aliases** inside `explore.sorts`.

### Must NOT use aliases in explore filters
We **CANNOT** use dimension and measure **aliases** inside `explore.filters`.

### previous() must have order
`order:` argument is **mandatory** in `previous()`.

### running_total() must NOT use date_trunc
Do **NOT** put date_trunc (`date_trunc()`, `year()`, `month()`, etc.) in `running_total()`
* Do **NOT**: `running_total(metric, model.time | month())`
* **DO**: `running_total(metric, model.time)`

### relative_period() rules
When using `relative_period()` (on the relative-period metric):
* **ALWAYS** **filter** the time frame of base-period metric using `explore.filters`
* **ALWAYS** apply **date trunc** to the corresponding time dimension in `explore.dimensions` (if exists)

### automatic joins
AQL automatically performs joins between models.
**NEVER** try to implement relationships or joins in AQL.

### AQL is not SQL
Look for valid AQL syntax, functions and use them.
Do **NOT** use SQL syntax.

E.g. `current_date` does not exist in AQL. Use `@(today)` instead.

### date_trunc vs date_part
* `date_trunc` truncates the date/datetime to the specified unit (returned data type: date/datetime)
* `date_part` extracts the numeric representation of the specified part of the date/datetime.
  * available parts: `'year'`, `'month'`, `'week'`, `'dayofweek'`, `'day'`, `'hour'`, `'minute'`, `'second'`

Example: Given `orders.created_at` is `2026-03-04` (type: date)
* `date_trunc(orders.created_at, 'year')` or `orders.created_at | year()` -> `2026-01-01` (type: date)
* `date_part('year', orders.created_at)` -> `2026` (type: number)

Tip: read docs for the full list of supported datetime units/parts.

### Prefer nested aggregation to dimensionalize()
Favor **nested aggregation** over `dimensionalize()`.

### Prefer nicely refactored metrics
Try to break down into smaller metrics.

### unique() and group()
`unique()` is similar to `group()` except that `group()` requires a source table as first argument
* `group(source_table, dim1, dim2, ...)`
* `unique(dim1, dim2, ...)` -> **only** use `unique()` at the **beginning** of an expression.

=> Both group dimensions for subsequent aggregations. **Prefer `unique()`** — more intuitive, less error-prone.

Notes:
* Do **not** use `unique()` or `group()` **unless** you need to
  * calculate nested aggregations
  * or filter on aggregations
* **CANNOT** chain multiple `unique()` or `group()` on the same level of metric. Use proper nested aggregation instead.

### Count on primary keys
Prefer counting on primary keys (e.g. `id`) whenever possible.

### where() vs filter()
* Use `where()` when filtering **a single Model Dimension** (e.g. `where(model_a.dim_x > 0)`, `where(model_a.dim_y in single_column_table)`, `where(model_a.dim_y in top_records)`).
  * `where()` CANNOT filter on dimension calculations, e.g. `where(model_a.dim_x * model_b.dim_y > 0)`
  * `where()` CANNOT filter on measures, e.g. `where(metric_z > 0)`
  * `where()` CANNOT filter on columns calculated in `select()`, e.g. `model_a | select(x: model_a.dim_x) | where(x > 0)`
* Use `filter()`
  * when filtering on metrics/measures (e.g. `filter((model_a | sum(model_a.dim_x)) > 0)`, `filter(metric_z > 0)`)
  * when filtering on columns calculated in `select()` (e.g. `model_a | select(x: model_a.dim_x) | filter(x > 0)`)
* `filter()` CANNOT do `filter(model_a.dim_x in table)` but `where()` can

When filtering on dimension calculations, always try to refactor the calculations into a new dimension first!
Example: total area of the squares whose area > 100
```aql
dimension square.area = square.side * square.side;
metric total_area =
  square
  | where(square.area > 100)
  | sum(square.area);
```


`explore.filters` filters on **dimensions** (acts like `where()`); `explore.having` filters on **metrics/measures/aggregations** (acts like `filter()`). Both apply to **all** explore measures — prefer them over local `where()`/`filter()` for explore-wide filtering.


### Avoid <= and >=
**Avoid** using `<=` and `>=` whenever possible!
For example
* Use `> 3` instead of `>= 4`
* Use `< @(2025)` instead of `<= @(2024-12-31)`

### Avoid `and` condition in where() and filter()
**Avoid** using `and` in conditions whenever possible. Instead:
* Use chaining
* Refactor the condition into a new dimension/metric

=>
* Don't:
  * `where(model.dim > 1 and model.dim < 3)`
  * `filter(metric > 1 and metric < 3)`
  * `filter(model.field > 1 and metric < 3)`
* Do:
  * `where(model.dim > 1) | where(model.dim < 3)`
  * `filter(metric > 1) | filter(metric < 3)`
  * `where(model.dim > 1) | filter(metric < 3)`
  * `where(model.dimension_matched is true)`
  * `filter(metric_matched is true)`

### Using measures and metrics
In the dataset fields, there can be some measures.
Remember, those measures are **already aggregated**.

To use those measures:
* DO
  * Use directly. E.g. `model.measure`, `standalone_measure`, `model.measure | where(model.field > 0)`
  * Make sure to include the `model.` reference if the measure is associated with a model
  * If you need to re-aggregate a measure, make sure to use `unique()` and `select()` (i.e. nested aggregation) properly. E.g. `unique(model.field) | select(v: model.measure) | sum(v)`, `unique(model.field) | select(v: model.measure) | avg(v)`,  `unique(model.field) | select(v: standalone_measure) | avg(v)`
* DON'T
  * Re-aggregate without proper nested aggregation. E.g.: `model | sum(model.measure)`, `avg(model.measure)`, `sum(standalone_measure)`, `standalone_measure | avg(standalone_measure)`.

### Explore dimensions versus measures
**Only** **measures** or **metrics** can be put in `explore.measures`.  
A **dimension** must be **aggregated** into a metric to be put in `explore.measures`.

### exclude_grains() and keep_grains() with multiple dimensions
When the explore has multiple dimensions of a model, `exclude_grains` / `keep_grains` MUST list **all of that model's dimensions present in the explore**. Excluding the ID alone is NOT enough!

For example,
```aql
explore {
  dimensions {
    user_id: users.id,
    user_name: users.name,
  }
  measures {
    order_count: order_count,
    order_count_of_all_user_ids: order_count | exclude_grains(users.id),
    order_count_of_all_users: order_count | exclude_grains(users.id, users.name),
    order_count_over_all_users_percentage: order_count * 100.0 / (order_count | exclude_grains(users.id, users.name)),
  }
}
```
Result:
```csv
user_id,user_name,order_count,order_count_of_all_user_ids,order_count_of_all_users,order_count_over_all_users_percentage
1,Alice,1,3,15,6.67
2,Alice,2,3,15,13.33
3,Bob,4,4,15,26.67
4,Chloe,8,8,15,53.33
```
See how both user 1 and user 2 have the same order_count_of_all_user_ids = 3 because they have the same name "Alice".
=> If we want to calculate the proper total order count of all users, use `order_count | exclude_grains(users.id, users.name)` to exclude **all dimensions** of `users` in the explore.

### Including one-side values with absent many-side values
AQL typically performs a LEFT JOIN from many to one. This is for metric-centric logics and to avoid fan-outs.

Thus, this AQL
```aql
metric order_count = orders | count(orders.id);
explore {
  dimensions {
    user_id: users.id,
  }
  measures {
    order_count: order_count,
  }
}
```
does NOT include users who haven't made any orders.

To include users who haven't made any orders (one-side values with absent many-side values), we need to add a metric on users (on the one-side model):
```aql
metric order_count = orders | count(orders.id);
metric user_count = users | count(users.id);
explore {
  dimensions {
    user_id: users.id,
  }
  measures {
    order_count: order_count,
  }
  having {
    user_count > 0, // added (hidden) metric on one-side model
  }
}
```

### Using select()
* `select()` returns a Table that may contain multiple columns and multiple values. To return a single scalar value, you need to re-aggregate the Table.
* Chaining `select()` is **NOT** like chaining SQL CTEs. It only adds more columns on the same level.

### Commenting
AQL **only** supports inline commenting using `//`.  
It does NOT support block commenting and does NOT support `--`.
