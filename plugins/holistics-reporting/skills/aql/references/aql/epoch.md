## Description

`epoch` returns a Unix timestamp which is the number of seconds that have elapsed since `1970-01-01 00:00:00 UTC`.

## Syntax

```aql
epoch(expr)
```

### Input
* `expr`: A date or datetime expression

### Output
`Scalar(number)`

### Examples
```aql
epoch(orders.created_at)
```
