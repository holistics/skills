---
name: detect-anomaly-aql
description: |-
  Guidelines for writing detect-anomaly queries. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

### Method
Detect anomalies by working out what change to expect in each period from the periods before it, then flagging the periods whose actual lands far from that expectation.

Everything is computed on **changes**, not levels: `Δ` = the change from the previous bucket. That is what lets the band follow a trend, since a steadily climbing series has large values but ordinary changes, and so never trips on the climb itself.

For each bucket `t` (`T` truncated to `<grain>`), over **every bucket before it**:

- `avg_change` = mean of `Δ`. The change to expect.
- `spread` = stddev of `Δ`. How much that change normally varies.
- `expected` = previous `actual` + `avg_change`. Where this bucket should land.
- `lower/upper_bound` = `expected` ∓ `k · spread`.
- `z_score` = (`actual` − `expected`) / `spread`. How far off it landed, counted in `spread`s.
- `anomaly_flag` = `1` when `abs(z_score) > k`, else `0`. `k` default 3 (looser 2, stricter 4). For the chart only.
- `verdict` = `'unusual'`, `'normal'`, or `'not assessed'`. The one field the caller reads.

**There is no baseline length to set.** The frame is `..-1` — the first bucket of the series through the bucket before this one. Every bucket is judged against everything that came before it, so nothing has to be chosen per grain, per series, or per run.

**The opening buckets exclude themselves.** `spread` is a *sample* standard deviation, undefined for fewer than two values, so it comes back null until a bucket has at least two prior changes behind it — the fourth bucket of a series. `expected` is null before that too, since the first bucket has no previous value to project from. Nothing gates this: the nulls arise on their own. Those opening buckets are the **lead-in**: carried for context, never judged.

**Nulls do all the branching.** `z_score` is arithmetic on `expected` and `spread`, so a null in either carries through, and `lower_bound` / `upper_bound` go null with it. A short series is therefore safe with no gate and no arithmetic: too little history returns nulls rather than an error. Read the result instead of predicting it; the caller reports what came back assessed.

**`verdict` turns those nulls into a word, so the caller never reads a null.** Its three branches are tried in order, and the second one is what makes this work without a null test:

- `abs(z_score) > k` → `'unusual'`
- `abs(z_score) >= 0` → `'normal'` — true for every real number, and *not* true when `z_score` is null
- otherwise → `'not assessed'`

A null `z_score` fails both comparisons and falls to the `else`, so every row comes back carrying a literal word. Two things land in `'not assessed'`: a bucket with fewer than two prior changes behind it, and a perfectly flat stretch, where `spread` is `0` and `safe_divide` returns null. Both are correct — there is nothing to judge against in either case.

**The baseline never forgets, and that is the cost.** With an expanding frame an unusual bucket raises `spread` for every bucket after it, permanently — there is no window for its influence to fall out of. One violent early spike can widen the band enough to hide milder anomalies for the rest of the series. The caller says so when the flagged set makes it relevant.

### Query

A complete query: monthly `total_revenue`, reporting on 2016 and 2017, `k` 3.

```aql
metric m_prev       = window_avg(total_revenue, -1..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_delta      = total_revenue - m_prev;
metric m_avg_change = window_avg(m_delta, ..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_spread     = window_stdev(m_delta, ..-1, order: orders.created_at | month() | asc(), partition: []);
metric m_expected   = m_prev + m_avg_change;
metric m_z          = safe_divide(total_revenue - m_expected, m_spread);
metric m_lower      = m_expected - 3 * m_spread;
metric m_upper      = m_expected + 3 * m_spread;
metric m_anom       = case(when: abs(m_z) > 3, then: 1, else: 0);
metric m_verdict    = case(
  when: abs(m_z) > 3,  then: 'unusual',
  when: abs(m_z) >= 0, then: 'normal',
  else: 'not assessed'
);
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
    anomaly_flag: m_anom,
    verdict: m_verdict
  }
  filters {
    orders.created_at < @2018-01-01
  }
  sorts {
    bucket asc nulls last
  }
}
```

Substitute `total_revenue` with `M`, `orders.created_at` with `T`, `month()` with the grain, and `3` with `k`. Leave both frames exactly as written: `..-1` is every bucket before this one, and `-1..-1` is the previous bucket.

**The time filter has no lower bound.** Above, the report covers 2016 and 2017, but the filter carries no start date at all: the baseline is every prior bucket, so the fetch has to reach as far back as the data goes. Write it as an upper bound only — `orders.created_at < @2018-01-01` — and let the caller report on the range it was asked about.

**Cropping the fetch changes the numbers, it does not just shorten them.** With an expanding baseline, every `expected`, `spread` and `z_score` depends on how far back the query reaches, so the same bucket scores differently under a narrower filter. Never crop to the range a chart happens to display, and never re-crop between the Step 2 query and the Step 3 chart — which is why the chart is drawn from this explore verbatim.

**Dimensional filters go in the same block**, one per line:

```aql
  filters {
    orders.created_at < @2018-01-01
    orders.region == "West"
  }
```

**Do not regress these:**
- The baseline frame is `..-1`, **not** a fixed count like `-12..-1`. This method has no baseline length; do not reintroduce one, and do not add an `n_prior` gate to compensate.
- `window_stdev` is the **sample** standard deviation, and that is what makes the lead-in self-exclude: it is null below two values. `window_stdevp` (population) returns `0` there instead, and a zero spread scores every opening bucket as an extreme anomaly.
- Nulls carry the lead-in through `m_expected` and `m_spread` into `m_z`, `m_lower`, `m_upper` and `m_anom`. Nothing downstream needs a guard of its own — do not add one.
- **`verdict` and `anomaly_flag` are not redundant.** `verdict` is the caller's only input and carries three states; `anomaly_flag` exists solely so the chart has a numeric column series. Never drop one for the other, and never have the caller read `anomaly_flag`.
- The nested window (`window_stdev(m_delta, …)` where `m_delta` contains a window) compiles directly: one explore, no two-stage query.
- `anomaly_flag` must always return `0` or `1`, **never `null`**. The `else: 0` is mandatory: it is plotted as a column, and nulls cause rendering gaps instead of clean zeros. This is also why it cannot carry the third state and `verdict` exists.
- `verdict`'s second branch must stay `abs(m_z) >= 0`, not a null test. It is what routes a null `z_score` to `'not assessed'` without any null-handling function.
- `verdict` must never return null. Every row carries one of the three words.
- **The fetch must reach the start of the series.** It is the only thing standing in for a baseline length now, and a bounded lower bound silently rescales every score in the result.
- Dates are **literals, not calls**: `@2016-01-01`, `@2016-01-01 - 2017-12-31`, `@(last 12 months)`. There is no `@date(...)` function, and writing one is a syntax error at the `(`.
