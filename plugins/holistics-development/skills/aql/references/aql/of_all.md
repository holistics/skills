## Syntax

```aql
metric | exclude_grains(model.dimension, ...)
metric | exclude_grains(model.dimension, ..., keep_filters: true)
```

### Input
- `metric`: An AQL metric
- `model.dimension` (repeatable): The model dimension that is excluded from breaking down the metric
- `keep_filters` (optional): A boolean value that specifies whether to keep the filters applied on the excluded dimensions. Default is false.

### Output
Same type as input metric
