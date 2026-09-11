---
name: detect-anomaly-aql
description: |-
  Guidelines for writing detect-anomaly queries. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

### Method

Anomalies are detected by evaluating the *change* between consecutive periods rather than absolute levels. By calculating the expected change (`Δ`) from the previous bucket, the system adjusts for steady trends without triggering false anomalies on the climb.

For each time bucket `t` (truncated to the specified `<grain>`), calculations are based on **every preceding bucket**:

* **`avg_change`**: Mean of `Δ`. The expected change.
* **`spread`**: Standard deviation of `Δ`. The normal variation of the change.
* **`expected`**: Previous `actual` + `avg_change`. The projected value for the current bucket.
* **`lower/upper_bound`**: `expected` ∓ `k · spread`.
* **`z_score`**: (`actual` − `expected`) / `spread`. The deviation from expectations, measured in standard deviations (`spread`).
* **`anomaly_flag`**: `1` if `abs(z_score) > k`, else `0` (default `k`=3; use 2 for looser, 4 for stricter). Used solely for charting.
* **`verdict`**: `'unusual'`, `'normal'`, or `'not assessed'`. The primary text output read by the caller.

**Key Mechanical Behaviors:**

* **No Fixed Baseline:** The evaluation frame is always `..-1` (the first bucket through the one immediately preceding the current). Every bucket is judged against its entire available history.
* **Natural Lead-In:** Because `spread` uses a *sample* standard deviation, it requires at least two prior changes to compute. Before this, `spread`—and consequently `expected`—evaluates to null. These opening buckets serve purely as context and are self-excluding.
* **Null-Driven Logic:** Arithmetic involving nulls cascades automatically. A null `expected` or `spread` naturally results in a null `z_score`, `lower_bound`, and `upper_bound`. This prevents errors on short series without requiring explicit gates.
* **The `verdict` Routing:** The caller relies on `verdict` to translate nulls into readable states using sequential fallbacks:
  1. `abs(z_score) > k` → `'unusual'`
  2. `abs(z_score) >= 0` → `'normal'` (Matches any real number, but *fails* on nulls)
  3. `else` → `'not assessed'` (Captures nulls from the lead-in period or perfectly flat data where `spread` is `0`).
* **The Cost of Infinite Memory:** An expanding frame means an extreme early spike permanently inflates the `spread` for all subsequent buckets. This can widen the band enough to mask milder anomalies later in the series. The caller will note this when relevant.

### Query

A complete query example calculating monthly `total_revenue` for 2016 and 2017 with `k` = 3:

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

**Implementation Rules:**

* **Variable Substitution:** Replace `total_revenue` with your metric `M`, `orders.created_at` with time `T`, `month()` with your desired grain, and `3` with your chosen `k` value. Leave both window frames (`..-1` and `-1..-1`) exactly as written.
* **No Lower Time Bound:** The filter must reach as far back as the data goes to establish the baseline. Use an upper bound only (e.g., `orders.created_at < @2018-01-01`). Let the caller handle reporting on the specific requested date range.
* **Never Crop the Fetch:** Because the baseline expands, shortening the data fetch fundamentally changes the `expected`, `spread`, and `z_score` calculations. Never crop the query to match a chart's display range.
* **Dimensional Filters:** Add these directly to the `filters` block, one per line (e.g., `orders.region == "West"`).

**Strict Anti-Regression Guidelines (Do Not Alter):**

* **Keep the `..-1` frame.** Do not introduce a fixed baseline length (e.g., `-12..-1`) or add an `n_prior` gate.
* **Use `window_stdev` (sample).** Do not use `window_stdevp` (population). The population function returns `0` instead of null for the lead-in period, which triggers false extreme anomalies.
* **Do not add explicit null guards.** Let nulls naturally cascade through the metrics.
* **Keep both `verdict` and `anomaly_flag`.** `verdict` carries states for the caller, while `anomaly_flag` plots the chart series. Never drop one for the other.
* **Nested windows compile natively.** `window_stdev(m_delta, …)` requires no two-stage queries.
* **`anomaly_flag` requires `else: 0`.** It must never return null. Charting nulls causes rendering gaps instead of clean zeros.
* **`verdict` logic is strict.** Branch two must remain `abs(m_z) >= 0` to route nulls safely. `verdict` must always return a string, never null.
* **Use literal dates.** Write dates directly (e.g., `@2016-01-01`, `@(last 12 months)`). Do not wrap them in functions; `@date(...)` is a syntax error.
