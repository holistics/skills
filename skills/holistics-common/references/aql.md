# AQL
## AQL Explore anatomy
```aql
// Adhoc fields:
metric adhoc_metric_name = ...; // adhoc metric (aka. measure)
dimension model_name.adhoc_dimension_name = ...; // adhoc dimension

// Explore
explore {
  dimensions {
    label1: model_name.dimension_name,
    label2: model_name.dimension_name | month(),
  }
  measures {
    label3: metric_name,
    label4: sum(model_name.dimension_name), // inline metric expression
  }
  filters {
    filter_expression_1,
    filter_expression_2,
  }
}
```
