An AQL expression is a structured combination of [data types](/reference/aql/type-index), [operators](/reference/aql/operator), and [functions](/reference/aql/function), allowing you to [query your database](/reference/aql/table-expression) or define [reusable metrics](/reference/aql/metric-expression).

### Types
There are two main types of AQL expressions:
* **[Table expressions](/reference/aql/table-expression)**: Expressions that represent a query that returns a table output, similar to SQL
* **[Metric expressions](/reference/aql/metric-expression)**: Expressions that represent a reusable metric, which is basically some aggregation logic with added context

### Structure
A typical AQL expression often is a combination of AQL functions combined together using the [AQL pipe operator](/reference/aql/operator#pipe), like the followings:

A query that returns the sum of values of all orders from a `order_items` table:
```aml
order_items | select(value: quantity * price) | sum(value)
```

A metric that returns the running total of number of orders in 2023:
```aml
count(orders.id)
| where(orders.created_at is @2023)
| running_total(run: orders.created_at | month())
```

### Dataset
An AQL expression only works within the context of a dataset as it requires knowledge of the models and relationships between them defined in the dataset.
