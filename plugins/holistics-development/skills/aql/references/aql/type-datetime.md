## Definition
A datetime value, represented as a string in the format "YYYY-MM-DD HH:MM:SS". The "datetime" type includes both date and time information, and is typically used to represent timestamps in the local time zone of the system or application where it is being used. It also has built-in time zone handling, which allows it to handle time zone conversions and daylight saving time adjustments automatically.

```aml 
dimension order_shipped_at {
  label: "Order Shipped At"
  type: "datetime"
}
```

## Datetime Operator
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
      <td><code>&gt;</code></td>
      <td><code>orders.created_at &gt; @(yesterday)</code></td>
      <td>- <code>orders.created_at</code> is after yesterday</td>
      <td>Include data that are after a specific time period</td>
    </tr>
    <tr>
      <td><code>&lt;</code></td>
      <td><code>orders.created_at &lt; @2022</code></td>
      <td>- <code>orders.created_at</code> is before the year 2022</td>
      <td>Include data that are before a specific time period</td>
    </tr>
  </tbody>
</table>
