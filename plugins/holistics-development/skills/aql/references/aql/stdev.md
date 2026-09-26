## Description

Calculate the standard deviation (sample) of the values in a Number column expression, not including NULL values.

## Syntax

```aql
table | stdev(column)
```

### Input
* `table`: Source Table
* `column`: A **number** column expression on the given table

### Output
`Scalar(number)`

### Examples
```aql
products | stdev(products.price)
```
