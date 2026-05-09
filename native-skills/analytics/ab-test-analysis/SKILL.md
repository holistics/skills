---
name: ab-test-analysis
description: Evaluate the results of an A/B test — lift on the primary metric, statistical significance, sample-ratio sanity check, and guardrail metrics. Use when the user asks whether an experiment moved a metric.
---

## Pre-checks (before reading results)
1. **Sample ratio mismatch (SRM)** — the variant split should match the planned ratio (e.g. 50/50). If a chi-square test gives p < 0.001, treatment assignment is broken; do not trust the results.
2. **Coverage** — every randomized unit should appear in the analysis. Missing units suggest log loss or a filter bug.
3. **Pre-period parity** — variants should look similar on the metric *before* the test started. If not, the randomization is suspect.

## Primary metric
* Compute **lift** as `(treatment - control) / control` (relative) and `treatment - control` (absolute).
* Report a **confidence interval** (or p-value) — point estimates without uncertainty are misleading.
* Account for **variance reduction** if available (CUPED, regression adjustment) — usually halves the required sample size.

## Guardrails
Even a winning treatment can be a net loss. Always check:
* Latency / error rate
* Bounce / churn / unsubscribe
* Other key business metrics that *shouldn't* regress

## Pitfalls
* **Peeking** — checking results repeatedly inflates false-positive rate. Use sequential tests if you must peek.
* **Novelty / primacy effects** — early lift may fade or reverse; check stability over the test window.
* **Heterogeneity** — an aggregate null can hide a positive effect on one segment and a negative on another. Stratify before concluding "no effect."
* **Multiple comparisons** — testing many metrics requires correction (Bonferroni, FDR), or a pre-registered hierarchy.

## Communicating results
Always state: lift point estimate, confidence interval, sample size, test duration, primary vs secondary metric, and an explicit recommendation (ship / iterate / kill).
