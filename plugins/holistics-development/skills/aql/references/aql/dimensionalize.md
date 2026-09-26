## Syntax

```aql
dimension bound_model.new_dimension = metric | dimensionalize(model.dimension, ...)
```

### Input
- `metric`: An AQL metric that will be dimensionalized and bound to the `bound_model`
- `model.dimension` (repeatable): The modified metric will **ONLY** be broken down by this model dimension

### Output
Same type as input metric
