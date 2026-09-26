SQL passthrough functions provide a way to leverage native database-specific functions that aren't directly supported in AQL. These functions act as a bridge, allowing you to pass SQL function calls directly to your underlying database while maintaining type safety in your AQL queries.

### sql_text

```aml
sql_text('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
sql_text('UPPER', users.name) // -> Converts name to uppercase
sql_text('CONCAT_WS', '-', users.first_name, users.last_name) // -> Joins first and last name with hyphen
sql_text('SUBSTRING', users.email, 1, 5) // -> Extracts first 5 characters
```

**Description**

Calls a native SQL function that returns a text/string value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Text

---

### sql_number

```aml
sql_number('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
sql_number('POWER', orders.amount, 2) // -> Squares the order amount
sql_number('GREATEST', orders.quantity, 1) // -> Returns the greater of quantity or 1
sql_number('FLOOR', orders.amount) // -> Rounds down to nearest integer
```

**Description**

Calls a native SQL function that returns a numeric value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Number

---

### sql_datetime

```aml
sql_datetime('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
sql_datetime('DATE_ADD', orders.created_at, interval(7 days)) // -> Adds 7 days to created_at
sql_datetime('CONVERT_TZ', orders.created_at, '+00:00', '+07:00') // -> Converts timezone
sql_datetime('DATE_SUB', orders.created_at, interval(1 month)) // -> Subtracts 1 month
```

**Description**

Calls a native SQL function that returns a datetime value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Datetime

---

### sql_date

```aml
sql_date('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
sql_date('CURRENT_DATE') // -> Returns current date
sql_date('DATE', orders.created_at) // -> Extracts date portion from datetime
sql_date('DATE_SUB', orders.created_at, interval(1 month)) // -> Subtracts 1 month
```

**Description**

Calls a native SQL function that returns a date value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Date

---

### sql_truefalse

```aml
sql_truefalse('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
sql_truefalse('REGEXP_LIKE', users.email, '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$') // -> Validates email format
sql_truefalse('STARTS_WITH', users.name, 'John') // -> Checks if name starts with 'John'
```

**Description**

Calls a native SQL function that returns a boolean/truefalse value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Truefalse

---

## Aggregation Versions

Each SQL passthrough function has an aggregation version that can be used with aggregate SQL functions.

### agg_text

```aml
agg_text('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
agg_text('GROUP_CONCAT', orders.status) // -> Concatenates all status values
agg_text('STRING_AGG', users.email, ',') // -> Aggregates emails with comma separator
agg_text('LISTAGG', products.name, '; ') // -> Lists all product names
```

**Description**

Calls a native SQL aggregate function that returns a text/string value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Text

---

### agg_number

```aml
agg_number('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
agg_number('STDDEV_SAMP', orders.amount) // -> Sample standard deviation
agg_number('VAR_POP', sales.revenue) // -> Population variance
agg_number('PERCENTILE_CONT', 0.5, orders.amount) // -> Median using percentile
```

**Description**

Calls a native SQL aggregate function that returns a numeric value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Number

---

### agg_datetime

```aml
agg_datetime('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
agg_datetime('MAX', orders.created_at) // -> Latest order date
agg_datetime('MIN', users.registered_at) // -> Earliest registration date
```

**Description**

Calls a native SQL aggregate function that returns a datetime value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Datetime

---

### agg_date

```aml
agg_date('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
agg_date('MAX', orders.order_date) // -> Latest order date
agg_date('MIN', events.event_date) // -> Earliest event date
```

**Description**

Calls a native SQL aggregate function that returns a date value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Date

---

### agg_truefalse

```aml
agg_truefalse('FUNCTION_NAME', param1, param2, ...)
```

```aml title="Examples"
agg_truefalse('BOOL_AND', orders.is_paid) // -> All orders paid
agg_truefalse('BOOL_OR', users.is_active) // -> Any user active
```

**Description**

Calls a native SQL aggregate function that returns a boolean/truefalse value. The first argument is the SQL function name (as a string), followed by any parameters that function requires.

**Return type**

Truefalse

---

## Important Notes

:::warning Database-Specific Behavior
SQL passthrough functions execute native database functions, which means:
- Function names and syntax vary between databases (PostgreSQL, MySQL, BigQuery, etc.)
- Not all SQL functions are available on all database platforms
- You're responsible for ensuring the SQL function exists in your target database
- The query may fail if the function doesn't exist or has different syntax on your database
:::

:::tip When to Use SQL Passthrough
Use SQL passthrough functions when:
- You need database-specific functionality not available in AQL
- You're working with specialized functions unique to your database platform
- You need to maintain compatibility with existing SQL code

Consider using native AQL functions instead when they're available, as they provide database-agnostic portability.
:::
