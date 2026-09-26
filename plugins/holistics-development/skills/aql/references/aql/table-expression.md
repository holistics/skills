Table expressions are expressions that represent a query that returns a table output, similar to SQL. They are typically [Table Functions](/reference/aql/function#table-functions) combined using the [AQL pipe operator](/reference/aql/operator#pipe).

### Structure
```aml
model_name 
| table_function1 (optional)
| table_function2 (optional)
| ...
```

### Examples

This table expresion is equivalent to `select * from users` in SQL:
```aml
users
```

Selecting a subset of fields:
```aml
users | select(users.id, users.gender)
```

Filtering data with [filter function](/reference/aql/filter):
```aml
users
| filter(gender == 'Female')
| select(id, name)
```
There is no need for explicitly joins like in SQL for **cross-model select**:
```aml
users
| select(users.name, country.name)
```
