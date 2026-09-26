Datetime literal represents a single timestamp or a range of time. They are typically used with [datetime comparison operators](/reference/aql/operator#datetime).

## Structure
Datetime literal start with `@` token. Datetimes can be expressed in a fully supported format as `@YYYY-MM-DD HH:MM:SS`, in shorter variations like `@YYYY-MM`, or relative datetime (relative to the current real world time) like `@(last 7 days)`.

:::tip
For a full list of datetime expressions, please refer to the [Natural Time Expression](/docs/datetimes/relative-dates) document.
:::

## Examples

```aml title="Fixed date"
@2023
@2023-04
@2023-04-01
```

```aml title="Fixed range"
@2023 - 2023
@2023-04 - 2023-05
@2023-04-01 - 2023-04-30
```


```aml title="Relative datetime"
@(now)
@(today)
@(yesterday)
@(last 7 days)
@(last 3 months)
```

**Note:** For one-word values like `@now`, `@yesterday`, or `@today`, parentheses are optional.
