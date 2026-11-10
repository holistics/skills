<!-- Deprecated -->

<head>
   <meta name="robots" content="noindex, nofollow"/>
</head>


:::info
This function will be deprecated soon and replaced by another function
:::

## Definition
Modify a measure into a running measure that accumulates values over one or multiple dimensions as it progresses. Note that the running total will be calculated on all data in the model ignoring any filter on the running dimensions.

To calculate a running total of only the data that is visible in the exploration, please use the [running_total](/reference/aql/running_total) function instead. Here is a comparison between `running_total` and `running_total!`:
<img src="https://cdn.holistics.io/docs/as-code/compare_running_total.png" width="1736"  height= "704" />

**Syntax**
```aml
running_total!(measure)
running_total!(measure, running_dimension, ...)
```

```aml title="Examples"
running_total!(orders.total_orders, orders.created_at)

// with pipe
orders.total_orders | running_total!(orders.created_at | year())

// with multiple running dimensions
running_total!(orders.total_orders, orders.created_at, orders.status)
```

**Input**

- `measure`: The measure that you want to turn into a running measure.
- `running_dimension` (**optional**, **repeatable**): The dimension you want your aggregation to run along. If not specified, the returned measure will run along all dimensions that in your exploration

**Output**

New measure that runs along the specified dimension(s) with all data in the model ignoring any filter on the running dimensions.

## Sample Usages

See the [running_total](/reference/aql/running_total#sample-usages) documentation for sample usages.
