Aggregate Functions are functions that group values of multiple rows into a single summary value. They are equivalent to aggregate functions that SQL supports (SUM, COUNT, AVG, MAX, MIN,...). For more information about how to use them, please refer to their [concept](/as-code/aql/learn/grouping) page.

---
### count

```aml
count(field)
count(table, field)
```

```aml title="Examples"
count(orders.id)
count(orders, orders.id)

// with pipe
orders | count(orders.id)
```

**Description**

Counts the total number of items in a group, not including NULL values.

**Return type**

Whole number

---
### count_if

```aml
count_if(truefalse_field)
count_if(table, condition)
```

```aml title="Examples"
count_if(orders.country == 'Vietnam')

// with pipe
orders | count_if(orders.country == 'Vietnam')
```

**Description**

Counts total rows from one table that satisfy the given condition.

**Return type**

Whole number

---

### count_distinct

```aml
count_distinct(field)
count_distinct(table, field)
```

```aml title="Examples"
count_distinct(orders.id)
count_distinct(orders, orders.id)

// with pipe
orders | count_distinct(orders.id)
```

**Description**

Counts the total number of distinct items in a group, not including NULL values.

**Return type**

Whole number

---

### approx_count_distinct (alias: approx_countd)

```aml
approx_count_distinct(field)
approx_count_distinct(table, field)
```

```aml title="Examples"
approx_count_distinct(orders.user_id)
approx_count_distinct(orders, orders.user_id)

// with pipe
orders | approx_count_distinct(orders.user_id)

// using alias
approx_countd(orders.user_id)
```

**Description**

Counts the approximate number of distinct items in a group, not including NULL values. This function uses HyperLogLog algorithm to provide an approximate count that is much faster and uses less memory than exact count_distinct for large datasets.

**Return type**

Whole number

**Supported databases**

- Snowflake
- BigQuery
- Databricks
- MotherDuck
- Presto/Athena

**Notes**

- The approximation error is typically within 2-3% of the actual value
- For running totals with `approx_count_distinct`, MotherDuck is not supported due to missing DataSketch extension
- This function is particularly useful for large datasets where exact counts are expensive

---

### average (alias: avg)

```aml
average(field)
average(table, field)
```

```aml
average(orders.value)
average(orders, orders.value)

// with pipe
orders | average(orders.value)
```

**Description**

Averages the values of items in a group, not including NULL values.

**Return type**

Number

---

### min

```aml
min(field)
min(table, field)
```

```aml title="Examples"
min(orders.quantity)
min(orders, orders.quantity)

// with pipe
orders | min(orders.quantity)
```

**Description**

Return the item in the group with the smallest value, not including NULL values.

**Return type**

Vary

---

### max

```aml
max(field)
max(table, field)
```

```aml
max(order_item.quantity)
max(orders, order_item.quantity)

// with pipe
orders | max(order_item.quantity)
```

**Description**

Returns the item in the group with the largest value, not including NULL values.

**Return type**

Varies

---

### sum

```aml
sum(field)
sum(table, field)
```

```aml
sum(order_item.quantity)
sum(order_items, order_item.quantity)

// with pipe
order_items | sum(order_item.quantity)
```

**Description**

Sums the value in the group, not including NULL values.

**Return type**

Number

---

### median

```aml
median(field)
median(table, field)
```

```aml title="Examples"
median(orders.quantity)
median(orders, orders.quantity)

// with pipe
orders | median(orders.quantity)
```

**Description**

Computes the median of the values in the group, not including NULL values.

**Return type**

Number

---

### stdev

```aml
stdev(field)
stdev(table, field)
```

```aml title="Examples"
stdev(orders.id)
stdev(orders, orders.id)

// with pipe
orders | stdev(orders.id)
```

**Description**

Computes the standard deviation (sample) of the values in the group, not including NULL values.

**Return type**

Number

---

### stdevp

```aml
stdevp(field)
stdevp(table, field)
```

```aml title="Examples"
stdevp(orders.id)
stdevp(orders, orders.id)

// with pipe
orders | stdevp(orders.id)
```

**Description**

Computes the standard deviation (population) of the values in the group, not including NULL values.

**Return type**

Number

---

### var

```aml
var(field)
var(table, field)
```

```aml title="Examples"
var(orders.id)
var(orders, orders.id)

// with pipe
orders | var(orders.id)
```

**Description**

Returns the variance (sample) of the values in the group, not including NULL values.

**Return type**

Number

---

### varp

```aml
varp(field)
varp(table, field)
```

```aml title="Examples"
varp(orders.id)
varp(orders, orders.id)

// with pipe
orders | varp(orders.id)
```

**Description**

Returns the variance (population) of the values in the group, not including NULL values.

**Return type**

Number

---

### corr

```aml
corr(table, field1, field2)
```

**Description**

Returns the Pearson correlation coefficient of two number fields in the table.

**Return type**

Number

**Examples**

```aml title="Calculate the correlation between age and order value"
corr(users, users.age, orders.value)
```

---

### string_agg

```aml
string_agg(expression, sep: _sep, distinct: _distinct, order: _order)
string_agg(table, expression, sep: _sep, distinct: _distinct, order: _order)
```

**Description**

Returns a text that is the concatenation of all values of the expression.

**Return type**

Text

**Examples**

```aml title="Basic usage: Concatenate all product names"
string_agg(products.name)
```

```aml title="Concatenate product names with a separator"
string_agg(products.name, sep: ', ')
```

```aml title="Concatenate distinct product names with a separator"
string_agg(products.name, sep: ', ', distinct: true)
```

```aml title="Concatenate product names, ordered by name"
string_agg(products.name, order: 'asc')
```

```aml title="Concatenate product names, ordered by name (descending)"
string_agg(products.name, order: 'desc')
```

**Parameters**

- `expression`: A field or an AQL expression to be evaluated in each row of the table to be aggregated
- `table` (optional): The table to aggregate. Only optional when the table can be inferred from the expression
- `sep` (optional): Separator between values, default is `','`
- `distinct` (optional): If true, only distinct values are concatenated, default is `false`
- `order` (optional): Specifies the ordering of values ('asc' or 'desc'), default is not specified

**Notes**

For SQL Server, the distinct parameter is not supported.

---

### percentile_cont

```aml
percentile_cont(expression, percentile)
percentile_cont(table, expression, percentile)
```

**Description**

Returns the value at the given percentile of the sorted expression values, interpolating between adjacent values if needed.

**Return type**

Number

**Examples**

```aml title="Calculate 70th percentile of user ages"
percentile_cont(ecommerce_users.age, 0.7)
```

```aml title="Full form usage: Calculate 70th percentile of user ages"
ecommerce_users | percentile_cont(ecommerce_users.age, 0.7)
```

```aml title="Nested aggregation: Calculate 70th percentile of total value by users"
unique(ecommerce_users.id) | percentile_cont(total_value, 0.7)
```

**Parameters**

- `expression`: A field or an AQL expression to be evaluated
- `table` (optional): The table to aggregate. Only optional when the table can be inferred from the expression
- `percentile`: The percentile to compute. Must be a value between 0 and 1

**Notes**

This is not supported in the following databases:

- MySQL
- Presto/Athena
- Bigquery (it only support `percentile_disc` and window function version of `percentile_cont`)

---

### percentile_disc

```aml
percentile_disc(expression, percentile)
percentile_disc(table, expression, percentile)
```

**Description**

Returns the value at the given percentile of the sorted expression values. If the percentile falls between two values, a discrete value will be returned (the logic to select the value is database dependent).

**Return type**

Number

**Examples**

```aml title="Calculate 70th percentile of user ages"
percentile_disc(ecommerce_users.age, 0.7)
```

```aml title="Full form usage: Calculate 70th percentile of user ages"
ecommerce_users | percentile_disc(ecommerce_users.age, 0.7)
```

```aml title="Nested aggregation: Calculate 70th percentile of total orders by users"
unique(ecommerce_users.id) | percentile_disc(count(ecommerce_orders.id), 0.7)
```

**Parameters**

- `expression`: A field or an AQL expression to be evaluated
- `table` (optional): The table to aggregate. Only optional when the table can be inferred from the expression
- `percentile`: The percentile to compute. Must be a value between 0 and 1

---

### min_by

```aml
min_by(table, value, by)
```

**Description**

Returns the value of `value` from the row where `by` is minimum.

**Return type**

Varies

**Examples**

```aml title="Get the name of the customer with the lowest order value"
min_by(orders, orders.customer_name, orders.value)
```

**Notes**

This function is not supported in the following databases:

- MySQL
- PostgreSQL
- Redshift
- SQL Server

---

### max_by

```aml
max_by(table, value, by)
```

**Description**

Returns the value of `value` from the row where `by` is maximum.

**Return type**

Varies

**Examples**

```aml title="Get the name of the customer with the highest order value"
max_by(orders, orders.customer_name, orders.value)
```

**Notes**

This function is not supported in the following databases:

- MySQL
- PostgreSQL
- Redshift
- SQL Server
