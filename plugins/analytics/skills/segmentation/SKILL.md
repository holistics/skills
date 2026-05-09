---
name: segmentation
description: Split users, customers, orders, or other entities into meaningful subgroups (RFM, behavioral, value-based, lifecycle) and analyze each subgroup separately. Use when an aggregate metric likely hides important variation across cohorts.
---

## When to segment
Aggregate metrics often hide divergent behavior across subgroups. Segment before drawing conclusions when:
* The user asks "who are our best/worst X" or "how does X vary across groups"
* A trend looks flat but you suspect offsetting movements (e.g. SMB churn masked by enterprise growth)
* You're sizing or prioritizing — different segments deserve different strategies

## Common segmentation types
* **RFM** (Recency, Frequency, Monetary) — retention and marketing on transactional businesses
* **Behavioral** — by feature usage, lifecycle stage, engagement level
* **Value-based** — ARR tier, deal size, plan
* **Demographic / firmographic** — for B2C / B2B targeting
* **Acquisition** — by channel, campaign, signup cohort

## How to evaluate a segmentation
1. **Size** — each segment should be material (rule of thumb: ≥5% of base, or large enough for statistical confidence)
2. **Distinctness** — segments should differ on the metric you care about, not just on the segmenting variable
3. **Stability** — membership shouldn't churn so fast the segment becomes meaningless

## Pitfalls
* **Tiny segments** — outliers dominate; either merge or exclude
* **Overlapping segments** — if you'll do per-segment math, prefer mutually exclusive splits
* **Backward causation** — segmenting by an outcome (e.g. "high-value customers") and then explaining the outcome with that segmentation is circular
