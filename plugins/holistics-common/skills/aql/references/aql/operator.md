A key component of AQL's query syntax involves the utilization of operators to generate more precise metrics. 

<!-- TODO: Add Arithmetic operators -->

## Pipe

The pipe operator `|` chains expressions left-to-right by passing the left side as the first positional argument to the function on the right.

```aml
expr | fn(args)    // equivalent to:
fn(expr, args)
```

Example:

```aml
orders | filter(orders.country = 'Singapore') | sum(orders.total_value)
```

For the conceptual treatment (when pipes shine, the table-vs-scalar mental model, debugging tips), see [The pipe operator](/as-code/aql/learn/pipe).

## Logical Operator
These operators serve to compare values and yield a [truefalse](/reference/aql/type-truefalse) result.

### Text
| Operator | Example | Description |
| --- | --- | --- |
| `==` <br /> <br /> `is`| `products.name == 'Dandelion'` <br /> <br /> `products.name is 'Dandelion'` | Equal to |
| `!=` <br /> <br /> `is not`| `products.name != 'Rock'` <br /> <br />  `products.name is not 'Rock'`| Not equal to | 
| `like` | `products.name like '%Dan'` | Match the pattern specified |
| `not like` | `products.name not like '%Dan'` | Not match the pattern specified |
| `ilike` | `products.name ilike '%dan'` | Match the pattern specified, case insensitive |
| `not ilike` | `products.name not ilike '%dan'` | Not match the pattern specified, case insensitive |
| `is null` | `products.name is null` | Include if the value is null |
| `is not null` | `products.name is not null` | Include if the value is not null |

### List
| Operator | Example | Description |
| --- | --- | --- |
| `in` | `products.name in ['Dandelion', 'Rock']` | Include if the value is in the list |
| `not in` | `products.name not in ['Dandelion', 'Rock']` | Include if the value is not in the list |


### Truefalse
| Operator | Example | Description |
| --- | --- | --- 
| `is` | `orders.is_paid is true` | Equal to |
| `is not` | `orders.is_paid is not true` | Not equal to|
| `is null` | `orders.is_paid is null` | Include if null |
| `is not null` | `orders.is_paid is not null` | Include if not null |

### Number
| Operator | Example | Description |
| --- | --- | --- |
| `==` <br /> <br /> `is`| `order_items.discount == 0.5`<br /> <br />  `order_items.discount is 0.5`| Equal to|
| `!=`<br /> <br /> `is not`| `order_items.discount != 1`<br /> <br /> `order_items.discount is not 1`| Not equal to| 
| `>` | `order_items.discount > 0.5` | Greater than | 
| `<` | `order_items.discount < 0.5` | Less than | 
| `is null` | `order_items.discount is null`| Include if null |
| `is not null` | `order_items.discount is not null`| Include if not null |


### Datetime
Right hand side of datetime operator takes a [datetime scalar type](/reference/aml/date-format) as input and always starts with `@` token. Datetimes can be expressed in a fully supported format as `@YYYY-MM-DD HH:MM:SS`, in shorter variations like `@YYYY-MM`, or a relative datetime (relative to the current real world time) like `@(last 7 days)`.

:::tip
For more information on datetime, please refer to:
- [Datetime Literals](/reference/aql/datetime-literal)
- [Natural Time Expression](/docs/datetimes/relative-dates)
:::


<table>
  <thead>
    <tr>
      <th>Operator</th>
      <th>Example</th>
      <th>Meaning</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>==</code></td>
      <td>
        - <code>orders.created_at == @2022 </code> <br />
        - <code>orders.created_at == @(last 7 days)</code>
      </td>
      <td>- <code>orders.created_at</code> equal to <code>2022-01-01 00:00:00</code><br />- <code>orders_created_at</code> equal to the first timestamp of the last 7 days</td>
      <td>Include data that equal to an absolute timestamp</td>
    </tr>
    <tr>
      <td><code>is</code><br /><code>matches</code><br /><code>match</code></td>
      <td>
        - <code>orders.created_at is @2022 </code> <br />
        - <code> orders.created_at match @(last 7 days)</code>
      </td>
      <td>- <code>orders.created_at</code> is in the period of the year <code>2022</code><br />- <code>order.created_at</code> is in the period of the last 7 days</td>
      <td>Include data that are in a time period</td>
    </tr>
    <tr>
      <td><code>!=</code></td>
      <td><code>orders.created_at != @2022-01</code></td>
      <td>- <code>orders.created_at</code> is not equal to <code>2022-01-01 00:00:00</code></td>
      <td>Include data that do not equal to an absolute timestamp</td>
    </tr>
    <tr>
      <td><code>is not</code></td>
      <td><code>orders.created_at is not @2022-01</code></td>
      <td>- <code>orders.created_at</code> is not in the period of <code>2022-01</code></td>
      <td>Include data that are not in a time period</td>
    </tr>
    <tr>
      <td><code>&lt;</code></td>
      <td><code>orders.created_at &lt; @2022</code></td>
      <td>- <code>orders.created_at</code> is before the year 2022</td>
      <td>Include data that are before a specific time period</td>
    </tr>
    <tr>
      <td><code>&gt;</code></td>
      <td><code>orders.created_at &gt; @(yesterday)</code></td>
      <td>- <code>orders.created_at</code> is after yesterday</td>
      <td>Include data that are after a specific time period</td>
    </tr>
    <tr>
      <td><code>is null</code></td>
      <td><code>orders.created_at is null</code></td>
      <td>- <code>orders.created_at</code> is null</td>
      <td>Include if the value is null</td>
    </tr>
    <tr>
      <td><code>is not null</code></td>
      <td><code>orders.created_at is not null</code></td>
      <td>- <code>orders.created_at</code> is not null</td>
      <td>Include if the value is not null</td>
    </tr>
  </tbody>
</table>
