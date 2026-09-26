## Description

Calculate the variance (population) of the values in a number model dimension, not including NULL values.

## Syntax

```aql
table | varp(column)
```

### Input
* `table`: Source Table
* `column`: A **number** column expression on the given table

### Output
`Scalar(number)`

### Examples
```aql
products | varp(products.price)
```
