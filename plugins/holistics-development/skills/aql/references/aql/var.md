## Description

Calculate the variance (sample) of the values in a Number column expression, not including NULL values.

## Syntax

```aql
table | var(column)
```

### Input
* `table`: Source Table
* `column`: A **number** column expression on the given table

### Output
`Scalar(number)`

### Examples
```aql
products | var(products.price)
```
