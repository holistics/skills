---
name: detect-anomaly-aql
description: |-
  Guidelines for writing detect-anomaly queries. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

### Method
Detect anomalies by working out what change to expect in each period from the periods before it, then flagging the periods whose actual lands far from that expectation.

Everything is computed on **changes**, not levels: `Δ` = the change from the previous bucket. That is what lets the band follow a trend, since a steadily climbing series has large values but ordinary changes, and so never trips on the climb itself.

For each bucket `t` (`T` truncated to `<grain>`), over the `W` buckets before it:

- `avg_change` = mean of `Δ`. The change to expect.
- `spread` = stddev of `Δ`. How much that change normally varies.
- `expected` = previous `actual` + `avg_change`. Where this bucket should land.
- `lower/upper_bound` = `expected` ∓ `k · spread`.
- `z_score` = (`actual` − `expected`) / `spread`. How far off it landed, counted in `spread`s.
- `is_anomaly` = `1` when `abs(z_score) > k`, else `0`. `k` default 3 (looser 2, stricter 4).

**`W` is 12, at every grain.** Twelve is where the spread estimate stops improving much, and a longer baseline costs assessed buckets without buying precision. Do not vary it by grain, by series length, or by anything else.

**A full window is required.** Check `n_prior = window_count(...) >= W`, so a bucket is banded and flagged only once it has `W` buckets behind it, and gets `z_score` null otherwise. Without that check the opening `W` buckets false-flag, because a window function over a partial frame returns a value rather than null. Those opening buckets are the **lead-in**: carried for context, never judged.

The gate is also what makes a short series safe, with no branching and no arithmetic: too little history returns nulls rather than an error. So read the result instead of predicting it. If no bucket in the reporting window comes back with a non-null `z_score`, there was not enough history to assess anything, and the answer says that rather than that nothing was unusual.

### Query

A complete query: monthly `total_revenue`, reporting on 2016 and 2017, `W` 12, `k` 3.

```aql
metric m_prev       = window_avg(total_revenue, -1..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_delta      = total_revenue - m_prev;
metric m_n          = window_count(total_revenue, -12..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_avg_change = window_avg(m_delta, -12..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_spread     = window_stdev(m_delta, -12..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_expected   = m_prev + m_avg_change;
metric m_z          = case(when: m_n >= 12, then: safe_divide(total_revenue - m_expected, m_spread), else: null);
metric m_lower      = case(when: m_n >= 12, then: m_expected - 3 * m_spread, else: null);
metric m_upper      = case(when: m_n >= 12, then: m_expected + 3 * m_spread, else: null);
metric m_anom       = case(when: and(m_n >= 12, abs(m_z) > 3), then: 1, else: 0);
explore {
  dimensions {
    bucket: orders.created_at | month()
  }
  measures {
    actual: total_revenue,
    expected: m_expected,
    lower_bound: m_lower,
    upper_bound: m_upper,
    z_score: m_z,
    is_anomaly: m_anom
  }
  filters {
    orders.created_at matches @2015-01-01 - 2017-12-31
  }
  sorts {
    bucket asc nulls last
  }
}
```

Substitute `total_revenue` with `M`, `orders.created_at` with `T`, `month()` with the grain, and `3` with `k`. Leave `12` and `-1..-1` exactly as written: `W` is always 12, and `-1..-1` is the previous bucket.

**The filter opens `W` buckets before the reporting window.** Above, the report covers 2016 and 2017 and `W` is 12, so the filter opens at 2015-01-01 and those twelve months arrive as the lead-in. A relative window widens the same way: a 24-month report becomes `matches @(last 36 months)`.

**Dimensional filters go in the same block**, one per line:

```aql
  filters {
    orders.created_at matches @2015-01-01 - 2017-12-31
    orders.region == "West"
  }
```

**Do not regress these:**
- Count prior buckets with `window_count(M, -W..-1, …)`, **never** `window_sum(1, …)` (SQL-generation error).
- The `n_prior ≥ W` gate is mandatory. Partial windows return values, not null, and would false-flag the first `W` buckets.
- `case(when: …, else: null)` is valid and is how the band is hidden in the lead-in.
- The nested window (`window_stdev(m_delta, …)` where `m_delta` contains a window) compiles directly: one explore, no two-stage query.
- `is_anomaly` must always return `0` or `1`, **never `null`**. The `else: 0` is mandatory: it is plotted as a column, and nulls cause rendering gaps instead of clean zeros.
- `z_score` must be null whenever `n_prior < W`. The caller distinguishes unassessed buckets from normal ones by that null, since `is_anomaly` is `0` for both.
- Dates are **literals, not calls**: `@2016-01-01`, `@2016-01-01 - 2017-12-31`, `@(last 12 months)`. There is no `@date(...)` function, and writing one is a syntax error at the `(`.
