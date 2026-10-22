:::tip Knowledge Checkpoint
This documentation assumes that you are familiar with the following functions:
- [where](/reference/aql/where)
- [filter](/reference/aql/filter)
:::

In AQL, we have the `where()` and the `filter()` functions that perform roughly the same function (apply a filtering condition onto an object), so you may wonder which one to use in a particular situation. In this document, we will explain when and where you should use which function.

### Quick comparison

A quick rule-of-thumb to follow when deciding between `where()` and `filter()`:

| Function | <div width="200">Target</div> | Valid filtering condition | When to use |
| :------- | :--------------------- | :------------------------ | :---------- |
| where() | Measure | <ul class=""><li><code>dimension operator value</code>. E.g. <code>orders.status == 'delivered'</code>, <code>orders.created_at matches @(last 7 days)</code></li><li><code>dimension in [value1, value2, ...]</code>. E.g. <code>orders.status in ['delivered', 'cancelled']</code></li><li><code>dimension in table</code>. E.g. <code>orders.status in unique(orders.status)</code></li><li><code>dimension operator measure</code>. E.g. <code>users.age &gt; avg(users.age)</code></li></ul> | Apply filters to a Measure |
| filter() | Table | Any expression that returns [truefalse](/reference/aql/type-truefalse) and is valid in the context of the table row | Filter a Table


### Examples

Suppose that you have an Ecommerce dataset with the following models:

```aml
Model orders {
	dimension id {}
	dimension status {}
	dimension country {}
	dimension user_id {}
	dimension value {}
}
```

In the examples below, we will demonstrate the difference on how `where()` and `filter()` are used.

#### Only `where()` can be used

Suppose you have defined the `total_orders` measure inside `orders` model:

```aml
Model orders {
	...

	measure total_orders {
		definition: @aql count(orders.id)
	}
}
```

Now you want to calculate **“the total orders which are delivered.”** You can use `where()` to apply filter to the measure:

```aml
orders.total_orders | where(orders.status == 'delivered') // valid expression

// This will error
orders.total_orders | filter(orders.status == 'delivered') // invalid expression
```

By definition, `filter()` cannot be used here.

#### Only `filter()` can be used

`filter()` can be used when you want to filter by arbitrary expression that haven't been defined as a dimension yet. For example, you want to know which country has at least 100,000 users who have placed at least 1 order:

```aml
orders
| group(orders.country)
| select(orders.country, users_count: count_distinct(orders.user_id))
// highlight-next-line
| filter(users_count >= 100000) // where here will be invalid
```

In this case, `where()` cannot be used in place of `filter()`, because by definition, `where()` have to filter on an existing dimension of `orders`, while the field `users_count` is an aggregation that has not been defined and calculated before.
