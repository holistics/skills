## Syntax

```aql
metric | keep_grains(model.dimension, ...)
```

### Input
- `metric`: An AQL metric
- `model.dimension` (repeatable): The modified metric will **ONLY** be broken down by this model dimension. NOTE: make sure to include this dimension in the `explore`
- `keep_filters` **(optional)**: A boolean value that specifies whether to keep the filters applied on the excluded dimensions. Default is false.

### Output
Same type as input metric
