---
name: analyze-changes
description: |-
  Orchestrates a guided investigation when the user sees a metric change (drop or increase) and wants to understand it. Runs an anomaly check first to confirm whether the change is real, then offers dimensional breakdown (key driver) or metric decomposition.

  Auto-trigger on open-ended "why did X change" questions:
    • "Why do we see the drop in revenue in 2026?"
    • "What's causing the decline in signups last quarter?"
    • "Why did our close rate go up in March?"
    • "Explain the decrease in MRR this month"
    • "What happened to conversions last week?"

  Do NOT trigger for:
    • Direct dimension breakdown requests ("break revenue down by region") — analyze_contribution handles those
    • Anomaly scanning with no specific change in mind ("detect anomalies in revenue") — detect_anomaly handles those
    • Forecasts or future projections
user-invocable: false
---

# Change Analysis Orchestrator

This skill runs in two stages. Check for a Stage 1 Summary Block in the conversation
history before doing anything else.

**No-switch guardrail:** Once this skill is loaded, Stage 1 must complete exactly as written before any metric decomposition, dimensional breakdown, existing-viz reuse, or shortcut analysis is performed. If a faster explanation appears to be available, complete Stage 1 first — then present that explanation as a follow-up option after the Stage 1 Summary Block is output.

## Stage 2 Detection

Scan the conversation history for a **Change Analysis — Stage 1 complete** block.

- **If found**: this is a Stage 2 invocation. Load `metric`, `direction`, `time_reference`,
  and `anomaly_verdict` directly from that block. Skip to **Stage 2** below.
- **If not found**: this is a fresh invocation. Run **Stage 1** from the top.

---

## Stage 1

Work through Steps 0–3 in order. Do not skip ahead.

**Stage 1 constraints — enforced until the Stage 1 Summary Block is output:**
- Do NOT call any tool that searches for existing visualizations.
- Do NOT run a dimensional breakdown or load `analyze_contribution` — that belongs to Stage 2 only.
- Do NOT perform metric decomposition — even when the metric formula is obvious or available in the dataset. Decomposition belongs after the anomaly verdict or after the user explicitly chooses that path.
- Do NOT give any direct explanation, analysis, or conclusion about why the metric changed — that belongs to Stage 2.
- Existing or pinned viz data may be used only to identify `metric`, `direction`, and `time_reference`. It must not replace the required anomaly check.
- The only permitted path forward is these Steps 0–3 below:

### Step 0 — Create a Plan
Create a Plan, and add tasks for the 3 steps below.
Skip if planning tools are unavailable.

### Step 1 — Confirm the metric

Brief:
```
Parse the user's message for:
- `metric` — the metric that changed (e.g., "revenue", "close rate", "daily signups")
- `direction` — drop or increase
- `base_period` — the period where the change occurred (e.g., "May 2025")
- `comparison_period` — the reference period (e.g., "April 2025")

If `metric` is not clearly named, ask before proceeding:
> "Which metric are you looking at?"

Fetch `current_value` (value in `base_period`) and `comparison_value` (value in `comparison_period`)
from the dataset. Compute `delta` = current_value − comparison_value.

Post an update to confirm the actual values:
> "Got it — you're seeing a [drop/increase] in **[metric]** from **[comparison_value]**
> ([comparison_period]) to **[current_value]** ([base_period]), [formatted delta]."

Delta formatting:
- Percentage metric (rate, %, ratio): "down/up **[|delta|] percentage points**"
- Currency: "down/up **$[|delta|]** ([relative%]%)"
- Count or other: "down/up **[|delta|]** ([relative%]%)"
```

Execution: Do this yourself, no delegation.

### Step 2 — Run the anomaly check

Dependency: Step 1

Brief:
```
/detect_anomoly
```

Execution:
* Add task to Plan
* Delegate this task to a sub-agent (only do it yourself if delegation is unavailable), alongside with an update message to the user:
> "Before we look at what drove this, let me first check whether this [drop/increase] in
> **[metric]** is actually unusual — or just normal variation. Running the anomaly check
> now..."

### Step 3 — Output the Stage 1 Summary Block

Depdendency: Step 2

Brief:
```
Once the sub-skill's prose verdict is visible, output the following in this exact order:

**1. Plain-language verdict sentence** (bold):

- If anomalous:
  `**The [drop/increase] in [metric] [time_reference] is abnormal.**`

- If within normal range:
  `**The [drop/increase] in [metric] [time_reference] is normal.**`

**2. One sentence of plain-text context:**

- If anomalous:
  `This is outside what we'd expect based on historical patterns — it's a real signal worth investigating.`

- If within normal range:
  `This falls within the expected range based on historical patterns — it may just be regular variation, so there may not be much to act on.`

**3. The Stage 1 Summary Block as plain markdown** — output these fields as plain text (this is the handoff marker for Stage 2 detection):

---
**Change Analysis — Stage 1 complete**
- **Metric**: [metric]
- **Change**: [drop/increase] [time_reference]
- **Anomaly verdict**: [Anomalous / Within normal range]
---

**4. Output the proceed question as plain text** — do NOT call `ask_user` or format options as markdown links. Output this immediately after the Stage 1 Summary Block:

How would you like to proceed?
1. Break down by dimensions — find which segments (e.g., region, plan, product, channel) drove the [drop/increase] the most
2. Decompose the metric *(coming soon)* — split the metric into its components to see which part shifted
```

Execution: Do this yourself, no delegation.

---

## Stage 2

Reminder: Update status of stage 1's tasks.

Act on the user's choice:

### If the user picks option 1 — Break down by dimensions

Dependencies: Step 1 and 2

Brief:
```
/analyze_contribution
```

Execution:
* Create task, alongside this update:
> "Analyzing what drove the [drop/increase] in **[metric]** [time_reference]..."
* Work on this task yourself. Delegate 1 sub-task for each dimension analysis.

### If the user picks option 2 — Decompose the metric

Announce:
> "Metric decomposition isn't supported yet — it's coming soon! Would you like to
> break down by dimensions in the meantime?"

If the user agrees, proceed as option 1 above.
