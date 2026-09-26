<!-- Deprecated -->

<head>
   <meta name="robots" content="noindex, nofollow"/>
</head>


## Definition
Apply metric function(s) to modify the original measure 

**Syntax**
```aml
eval(measure, metric_function)
```

**Input**
- *measure*: A define AQL measure
- *metric_function* (repeated): A [metric functions](/reference/aql/metric-function) to modify the measure. E.g. `with_relationships`, `dimensionalize`, etc.

**Output**

A newly modifed measure  

## Examples

Let’s say you want to calculate the percentage of sales contributed by each country in your E-commerce business.

<img src="https://cdn.holistics.io/docs/percent-of-total-tbl.png" alt="Percent of total" width="500"></img>

You will need to:

- Sum the order values grouped by country
- Divide the sum of each country by the total order value across all countries

Below is the formula for the `percent_of_total` measure that follow the logic above:

```aml
measure percent_of_total {
	definition: @aql
		sum(orders.order_value) / eval(sum(orders.order_value), exclude(orders.country))
}
```

Technically, the `eval()` function will create a new aggregation context for the `sum(orders.order_value)` expression. This new context excludes `orders.country` dimension, which allows the sum to be calculated over all countries.

For more information about context modifiers, you can refer to the following docs:

- [exclude, exclude_grains, of_all](/reference/aql/of_all)
