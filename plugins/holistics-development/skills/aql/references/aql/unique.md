## Definition
Return a new table with all unique combination of values in the specified dimensions. It is similar to [group](/reference/aql/group) but without the need to specify a source table. The difference is that [group](/reference/aql/group) will only return combination of values that exist with respect to the source table, while [unique](/reference/aql/unique) will choose the source table with the most number of rows.

**Syntax**
```aml
unique(dimension, dimension, ...)
```

```aml title="Examples"
unique(orders.id, products.id) // -> Table(orders.id, products.id)

unique(orders.id, products.id, customers.id) // -> Table(orders.id, products.id, customers.id)
```

**Input**
- `dimension` (**repeatable**): A fully-qualified reference to a dimension. The output table will have one row for each unique combination of values in the specified dimensions.

**Output**

A new table with one row for each unique combination of values in the specified dimensions.

## Sample Usages

import SampleCode from '@site/src/components/SampleCode';

import { example1 } from './unique.js';

<SampleCode title="Unique orders.id and products.id" rawResult={example1} />

Using [unique](/reference/aql/unique) with [select](/reference/aql/select) just like [group](/reference/aql/group):

import { example2 } from './unique.js';

<SampleCode title="Total product by product category" rawResult={example2} />

## See also

- [`group()`](/reference/aql/group)
- [`select()`](/reference/aql/select)
- [Pipe operator](/reference/aql/operator#pipe)
