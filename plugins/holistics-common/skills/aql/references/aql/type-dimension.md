## Definition

Some functions in AQL require the input to be a reference to a predefined [dimension](/reference/aml/field#dimension) in AML. This means these functions cannot accept arbitrary expressions but only accept AQL in the form of `model.field_name`.

:::info
`date_trunc` and its short-hand functions (`year`, `month`, `day` etc) are the "exceptions" to this. You can think that they accept a reference to a time dimension and return a reference to a derived time-dimension.

For example, it's perfectly valid to group by `users.created_at | year()` or `date_trunc(users.created_at, 'year')`, as these expressions technically return dimension references rather than arbitrary values.
:::

For example, suppose we have the following `users` model:

```aml
Model users {
  dimension id {}
  dimension first_name {}
  dimension last_name {}
  dimension email {}
  dimension delivered_orders {}
  dimension cancelled_orders {}
}
```

When we want to group by the full name, we can't do this:

```aml
users | group(concat(users.first_name, " ", users.last_name)) | select(count(users.id))
//            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//            Error: `group` expects `Dimension` but got `Text`
```

This happens because [group](/reference/aql/group) only accepts references to dimensions, not arbitrary expressions.

To fix this issue, you must define a `users.full_name` field to pass into `group`:

```aml
dimension full_name {
  definition: @aql concat(users.first_name, " ", users.last_name) ;;
}
```

Then you can use it like this:

```aml
users | group(users.full_name) | select(count(users.id))
```
