Table functions transform an input table expression into an output table result.

| Function | Syntax | Purpose |
| --- | --- | --- |
| [select](/reference/aql/select)  | `select(table, field1, field2, [,...])` | Selects the fields to be returned in the query result. |
| [group](/reference/aql/group)  | `group(table, field1, field2, [,...])` | Groups the result set by the specified field(s). |
| [filter](/reference/aql/filter)  | `filter(table, condition1, condition2, [,...])` | Filters the result set to include only rows that satisfy the specified conditions |
| [unique](/reference/aql/unique) | `unique(table, field1, field2, [,...])` | Returns the unique values of the specified field(s). |
