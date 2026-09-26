---
### epoch

```aml
epoch(date)
epoch(datetime)
```

**Description**

`epoch` returns a Unix timestamp which is the number of seconds that have elapsed since ‘1970-01-01 00:00:00’ UTC.

You can use this function to return a Unix timestamp based on the current date/datetime or another specified date/datetime.

**Return type**

Number

**Example**

Given an AQL expression as below:
```aml
epoch(orders.created_at)
```

The result would be:

| created_at          | epoch(created_at) |
| ------------------- | ----------------- |
| 2018-06-12 09:26:49 | 1528795609        |
| 2018-06-12          | 1528761600        |

---

### date_trunc

```aml
date_trunc(datetime, datetime_part)
```

Let's say that `orders.created_at` is `2021-05-28 10:30:39`

| Function                                | Result               |
|-----------------------------------------|----------------------|
| `orders.created_at`                     | 2021-05-28 10:30:39 |
| `date_trunc(orders.created_at, 'day')`   | 2021-05-28 00:00:00 |
| `date_trunc(orders.created_at, 'month')` | 2021-05-01 00:00:00 |
| `date_trunc(orders.created_at, 'year')`  | 2021-01-01 00:00:00 |
| `date_trunc(orders.created_at, 'quarter')` | 2021-04-01 00:00:00 |
| `date_trunc(orders.created_at, 'week')`  | 2021-05-24 00:00:00 |
| `date_trunc(orders.created_at, 'hour')`  | 2021-05-28 10:00:00 |
| `date_trunc(orders.created_at, 'minute')` | 2021-05-28 10:30:00 |

```aml title="Examples"
// orders.created_at -> 2021-05-28 10:30:39
date_trunc(orders.created_at, 'day') // -> 2021-05-28 00:00:00
date_trunc(orders.created_at, 'month') // -> 2021-05-01 00:00:00
date_trunc(orders.created_at, 'year') // -> 2021-01-01 00:00:00
date_trunc(orders.created_at, 'quarter') // -> 2021-04-01 00:00:00
date_trunc(orders.created_at, 'week') // -> 2021-05-24 00:00:00
date_trunc(orders.created_at, 'hour') // -> 2021-05-28 10:00:00
date_trunc(orders.created_at, 'minute') // -> 2021-05-28 10:30:00
```

**Description**

Truncates a `date`/`datetime` value to the granularity of `datetime_part`. The `datetime` value is rounded to the beginning of `datetime_part`. The supported parts are:

- `'day'`: The day in the Gregorian calendar year that contains the `datetime` value.
- `'week'`: The first day of the week in the week that contains the `datetime` value. Weeks begin on the day that was set in` your [Week Start Day Setting](/docs/datetimes/week-start-day)
- `'month'`: The first day of the month in the month that contains the `datetime` value.
- `'quarter'`: The first day of the quarter in the quarter that contains the `datetime` value.
- `'year'`: The first day of the year in the year that contains the `datetime` value.
- `'hour'`: The hour in the day that contains the `datetime` value.
- `'minute'`: The minute in the hour that contains the `datetime` value.

:::tip
All date part has a corresponding short-hand truncate function. Examples below will use the short-hand version.
- `day(orders.created_at)` or `orders.created_at | day()`
- `month(orders.created_at)` or `orders.created_at | month()`
- `year(orders.created_at)` or `orders.created_at | year()`
- `quarter(orders.created_at)` or `orders.created_at | quarter()`
- `week(orders.created_at)` or `orders.created_at | week()`
- `hour(orders.created_at)` or `orders.created_at | hour()`
- `minute(orders.created_at)` or `orders.created_at | minute()`
:::

**Return type**

`date` or `datetime` depending on the input type.

### date_part

**Syntax**
```aml
date_part(datetime_part, datetime)
```

**Description**
The `date_part` function extracts a specific numeric part from a date or datetime value. It returns the numeric representation of the specified part of the date.


**Examples**
Let's say `orders.created_at` is `2021-05-28 10:30:39`

| Function                                | Result |
|-----------------------------------------|--------|
| `date_part('year', orders.created_at)` | 2021 |
| `date_part('quarter', orders.created_at)` | 2 |
| `date_part('month', orders.created_at)` | 5 |
| `date_part('week', orders.created_at)` | 22 |
| `date_part('dayofweek', orders.created_at)` | 5 |
| `date_part('dow', orders.created_at)` | 5 |
| `date_part('day', orders.created_at)` | 28 |
| `date_part('hour', orders.created_at)` | 10 |
| `date_part('minute', orders.created_at)` | 30 |
| `date_part('second', orders.created_at)` | 39 |

```aml title="Code Examples"
// orders.created_at -> 2021-05-28 10:30:39
date_part('year', orders.created_at) // -> 2021
date_part('quarter', orders.created_at) // -> 2
date_part('month', orders.created_at) // -> 5
date_part('week', orders.created_at) // -> 21
date_part('dayofweek', orders.created_at) // -> 4
date_part('dow', orders.created_at) // -> 4
date_part('day', orders.created_at) // -> 28
date_part('hour', orders.created_at) // -> 10
date_part('minute', orders.created_at) // -> 30
date_part('second', orders.created_at) // -> 39
```

**Supported Date Parts**
- `'year'`: Returns the numeric year (e.g., 2021)
- `'quarter'`: Returns the quarter number (1-4)
- `'month'`: Returns the month number (1-12)
- `'week'`: Returns the week number of the year (1-53)
- `'dayofweek'` or `'dow'`: Returns the day of the week number (0-6)
- `'day'`: Returns the day of the month (1-31)
- `'hour'`: Returns the hour of the day (0-23)
- `'minute'`: Returns the minute of the hour (0-59)
- `'second'`: Returns the second of the minute (0-59)

:::tip
**Shorthand Functions**
Shorthand functions with `_num` suffix are available for quick access:
- `year_num(orders.created_at)` or `orders.created_at | year_num()`
- `quarter_num(orders.created_at)` or `orders.created_at | quarter_num()`
- `month_num(orders.created_at)` or `orders.created_at | month_num()`
- `week_num(orders.created_at)` or `orders.created_at | week_num()`
- `dayofweek_num(orders.created_at)` or `orders.created_at | dayofweek_num()`
- `dow_num(orders.created_at)` or `orders.created_at | dow_num()`
- `day_num(orders.created_at)` or `orders.created_at | day_num()`
- `hour_num(orders.created_at)` or `orders.created_at | hour_num()`
- `minute_num(orders.created_at)` or `orders.created_at | minute_num()`
- `second_num(orders.created_at)` or `orders.created_at | second_num()`
:::

**Additional Notes**
- The function returns an integer representing the specified part of the date
- Day of week use 0-based indices
- Week numbering follows the ISO 8601 standard
- Day of week numbering depends on your organization settings

**Return type**
Number

### date_diff
```aml
date_diff(datetime_part, start, end)
```

```aml title="Examples"
date_diff('day', orders.created_at, @now)
date_diff('month', orders.created_at, @now)
```

**Description**

Calculates the difference between two dates in the specified `datetime_part`. The supported parts are:
- `'day'`: The number of days between the two dates.
- `'week'`: The number of weeks between the two dates.
- `'month'`: The number of months between the two dates.
- `'quarter'`: The number of quarters between the two dates.
- `'year'`: The number of years between the two dates.

**Return type**

Number

---

### date_format

```aml
date_format(datetime, format)
```

**Description**

Formats a date according to the specified format string.

**Return type**

Text

**Examples**

```aml title="Format a date"
date_format(orders.created_at, '%Y-%m-%d')
```

```aml title="Format a date with time"
date_format(orders.created_at, '%Y-%m-%d %H:%M:%S')
```

```aml title="Format a date with month name"
date_format(orders.created_at, '%B %d, %Y')
```

```aml title="Format a date with day of the week"
date_format(orders.created_at, '%A, %B %d, %Y')
```

**Format Patterns**

| Pattern | Description                                   | Example                |
| :------ | :-------------------------------------------- | :--------------------- |
| `%Y`    | Four-digit year                               | `2018`                 |
| `%y`    | Two-digit year                                | `18`                   |
| `%q`    | Quarter of the year (1–4)                     | `3`                    |
| `%m`    | Two-digit month                               | `07`                   |
| `%B`    | Full month name                               | `July`                 |
| `%b`    | Abbreviated month name                        | `Jul`                  |
| `%A`    | Full day of week                              | `Sunday`               |
| `%a`    | Abbreviated day of week                       | `Sun`                  |
| `%d`    | Two-digit day of month (01-31)                | `08`                   |
| `%H`    | Two-digit hour based on 24-hour clock (00–23) | `00`                   |
| `%I`    | Two-digit hour based on 12-hour clock (01–12) | `12`                   |
| `%M`    | Two-digit minutes (00–59)                     | `34`                   |
| `%S`    | Two-digit seconds (00–59)                     | `59`                   |
| `%p`    | AM or PM                                      | `AM`                   |
| `%L`    | Three-digit milliseconds (000–999)            | `000`                  |
| `%f`    | Six-digit microseconds (000000–999999)        | `000000`               |
| `%%`    | The percent sign                              | `%`                    |

:::note
Not all format patterns are supported by all databases.
:::

---

### from_unixtime

```aml
from_unixtime(number)
```

**Description**

Converts a Unix timestamp (seconds since epoch) to a datetime value.

**Return type**

Datetime

**Example**

```aml
from_unixtime(1528795609)
```

---

### last_day

```aml
last_day(datetime, date_part)
```

**Description**

Returns the last day of the period for a given date.

**Return type**

Date

**Examples**

```aml title="Get the last day of the month"
last_day(orders.created_at, 'month')
```

```aml title="Get the last day of the quarter"
last_day(orders.created_at, 'quarter')
```

**Supported Date Parts**

- `'month'`: The last day of the month
- `'year'`: The last day of the year
- `'quarter'`: The last day of the quarter
- `'week'`: The last day of the week
