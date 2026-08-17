---
name: detect-anomaly-aql
description: |-
  Guidelines for writing detect-anomaly queries. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

### Method
The expected band **follows the trend**. For each bucket `t` (`T` truncated to `<grain>`):
- `actual` = `M`; `Δ` = the change from the previous bucket.
- `expected` = previous actual **+ drift**, where drift = the trailing mean of `Δ` over the `W` buckets before `t`. This is the band's centre; it tilts with the trend.
- `spread` = the trailing **stddev of `Δ`** over those `W` buckets.
- `lower/upper_bound` = `expected ∓ k · spread`.
- `z_score` = `(actual − expected) / spread`. Asks whether *this bucket's change* is unusual against the recent distribution of changes, which stays stationary even when the level trends.
- `is_anomaly` = `1` when `abs(z_score) > k`, else `0`. `k` default 3 (looser 2, stricter 4).

A flat window (`spread = 0`) gives `z_score` null through `safe_divide`, and those buckets are never flagged.

The band follows the trend, not the calendar: there is no seasonal term, so a recurring calendar peak flags as an anomaly.

**Warm-up gate (required).** A bucket is only banded and flagged once it has a **full `W`-bucket window** of prior history. Partial-frame window stats return values, not null, so gate explicitly on `n_prior = window_count(...) ≥ W`: buckets with `n_prior < W` get **no band** and are **never flagged**. The leading `W` lead-in buckets are exactly these, carried as context.

**Use these W values exactly.** Shrink `W` only when the total available history is shorter than `W + 1`, and say so explicitly in your response when you do. Never silently use a smaller `W`.

Window `W` by grain, a whole number of cycles:

| Grain | `W` |
|---|---|
| day | 28 (4 weeks) |
| week | 13 (a quarter) |
| month | 12 (a year) |
| quarter | 8 (two years) |

If the series is shorter than `W + 1`, shrink `W` to about half the available history (minimum 4) and say so. With fewer than 8 points total, stop: *"Not enough history (n=X) to detect anomalies."*

### Query

Parameters from the caller: `M`, `T`, `grain`, `W`, `k`, `reporting` (the reporting timeframe in grains), `filters` (the dimensional filters, if any).

The `-1..-1` range (previous bucket) is literal, and every `window_*` call takes `order: T | <grain>() | asc(), partition: []`. Widen the reporting timeframe by `W` buckets in the filter, and add the dimensional filters.

Template:
```aql
metric m_prev   = window_avg(M, -1..-1,  order: T | <grain>() | asc(), partition: []);
metric m_delta  = M - m_prev;
metric m_n      = window_count(M, -W..-1, order: T | <grain>() | asc(), partition: []);
metric m_drift  = window_avg(m_delta, -W..-1,  order: T | <grain>() | asc(), partition: []);
metric m_spread = window_stdev(m_delta, -W..-1, order: T | <grain>() | asc(), partition: []);
metric m_expected = m_prev + m_drift;
metric m_z      = case(when: m_n >= W, then: safe_divide(M - m_expected, m_spread), else: null);
metric m_lower  = case(when: m_n >= W, then: m_expected - k * m_spread, else: null);
metric m_upper  = case(when: m_n >= W, then: m_expected + k * m_spread, else: null);
metric m_anom   = case(when: and(m_n >= W, abs(m_z) > k), then: 1, else: 0);
explore {
  dimensions {
    bucket: T | <grain>()
  }
  measures {
    actual: M,
    expected: m_expected,
    lower_bound: m_lower,
    upper_bound: m_upper,
    z_score: m_z,
    is_anomaly: m_anom
  }
  filters {
    // reporting window WIDENED by W buckets for warm-up; the @( … ) parentheses are REQUIRED.
    T matches @(last <reporting + W> <grain>s)
    // + any dimensional filters carried from the chart, e.g. bq_fct_order_items.merchant_country_code == "US"
  }
  sorts {
    bucket asc nulls last
  }
}
```

**Do not regress these:**
- Count prior buckets with `window_count(M, -W..-1, …)`, **never** `window_sum(1, …)` (SQL-generation error).
- The `n_prior ≥ W` gate is mandatory. Partial windows return values, not null, and would false-flag the first `W` buckets.
- `case(when: …, else: null)` is valid and is how the band is hidden in the lead-in.
- The nested window (`window_stdev(m_delta, …)` where `m_delta` contains a window) compiles directly: one explore, no two-stage query.
- `is_anomaly` must always return `0` or `1`, **never `null`**. The `else: 0` is mandatory: it is plotted as a column, and nulls cause rendering gaps instead of clean zeros.
- `z_score` must be null whenever `n_prior < W`. The caller distinguishes unassessed buckets from normal ones by that null, since `is_anomaly` is `0` for both.
