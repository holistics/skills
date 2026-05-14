---
name: ltv-analysis
description: Compute customer lifetime value (LTV), realized or predicted, by cohort or segment, with optional gross-margin and discount-rate adjustments. Use when the user asks "what is a customer worth", wants to size a CAC budget, or compares channels by long-term value.
---

## Decide which LTV
* **Realized (historical)** — actual revenue from a closed cohort. Bounded but truthful.
* **Predicted (forward-looking)** — extrapolate from retention and ARPU curves. Useful for live cohorts and budgeting; sensitive to assumptions.

## Standard formulas
* Simple SaaS: `LTV = ARPU × gross_margin / churn_rate`
* Cohort-based realized: `LTV(t) = sum of revenue from cohort across [0, t] / cohort size`
* Discounted: apply a monthly/annual discount factor to future revenue (typical: 10–15% annual)

## Always do
1. **Slice by cohort** — LTV from 5 years ago does not predict LTV today. Show LTV by acquisition month/quarter.
2. **Show the curve, not just a point** — LTV at month 6, 12, 24, 36 — so the reader can see whether it's still growing.
3. **Use gross margin, not revenue** — LTV that ignores cost of serving the customer is overstated.

## Pitfalls
* **Truncated cohorts** — recent cohorts haven't aged; comparing their LTV to old cohorts at the same calendar date is invalid. Compare at the same cohort age.
* **Immortal-customer assumption** — `ARPU / churn_rate` implicitly assumes constant churn forever. Check whether churn is stable or rising.
* **Pricing changes** — if pricing changed mid-cohort, LTV shifts mechanically; segment by pricing era.
* **Mixing one-time and recurring** — separate transactional revenue from subscription revenue when they behave differently.
