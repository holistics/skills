## Description
Provide the grouping context for calculating metrics in subsequent `select()` or `filter()`.

## Syntax

```aql
table | group(column, ...)
```

### Input
- `table`: A Source Table
- `column` (repeatable): Column that is reachable from the Source Table (i.e. the column has a one-to-one or one-to-many relationship with the Source Table)

### Output
A Table with applied grouping
