## Description

Calculate the smallest value in a column expression, not including NULL values.

## Syntax

```aql
table | min(column)
```

### Input
* `table`: Source Table
* `column`: A column expression on the given table

### Output
`Scalar`

### Examples
```aql
products | min(products.price)
```
