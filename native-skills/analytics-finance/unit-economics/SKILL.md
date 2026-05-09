---
name: unit-economics
description: Compute the SaaS unit-economics quartet — CAC, LTV, LTV:CAC ratio, and CAC payback period — and assess whether the business acquires customers profitably. Use when evaluating growth health or comparing acquisition channels.
---

## The four metrics
1. **CAC** (Customer Acquisition Cost) — total acquisition spend / new customers in the period.
   * **Fully-loaded CAC** includes sales + marketing salaries, tools, ad spend.
   * **Marketing CAC** includes paid media only — useful for channel-level analysis but understates true cost.
2. **LTV** — see [ltv-analysis](../ltv-analysis/SKILL.md) for derivation.
3. **LTV:CAC ratio** — typical SaaS target is **≥3**. Below 1 means losing money on each customer; above 5 may indicate underinvestment in growth.
4. **CAC payback period** — months until cumulative gross profit from a customer equals CAC. Typical SaaS targets: **<12 months** for SMB, **<24** for mid-market.

## Slicing
The aggregate ratio is often misleading. Always also compute by:
* **Acquisition channel** — paid vs organic vs referral economics differ wildly
* **Segment / plan tier** — enterprise customers have higher CAC but much higher LTV
* **Cohort** — economics drift over time; show the trend

## Pitfalls
* **Immature cohorts** — recent cohorts haven't realized their LTV yet; payback period is the more honest near-term metric.
* **Lagged attribution** — if customers acquired in month N start paying in month N+3, time-aligning revenue and spend is critical.
* **Counting only cash CAC** — ignoring fully-loaded cost makes channels look cheaper than they are.
* **Using revenue, not gross profit** — LTV:CAC must use gross-profit-based LTV to be meaningful.
