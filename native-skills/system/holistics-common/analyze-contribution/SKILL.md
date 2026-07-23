---
name: analyze-contribution
label: Analyze Contribution
description: |-
  Identify which segments drove a metric change between two periods by ranking raw delta change per segment — no volume weighting. Requires two periods and change/delta intent. Trigger when the user asks to explain an increase or decrease, OR when the user's phrasing requests a breakdown or attribution with delta intent — e.g. "what drove the GMV increase from Nov to Dec?", "which regions contributed most to the MoM drop?", "break down the revenue change by continent", "which regions drove the revenue drop?", "where did the drop come from?", "was it churn or contraction?", "is it Enterprise or SMB?". Do NOT trigger for single-period breakdowns like "GMV Dec 2024 by continent" or "show revenue by category for 2024" — those are simple grouped queries with no delta. Do NOT trigger for open-ended "why did X change?" questions with no explicit breakdown intent — change_analysis handles those.
---

## Inputs

- **Dataset**: current dataset in context
- **Target metric**: provided by user or inherited from referenced viz
- **Base period**: provided by user
- **Comparison period**: provided by user
- **Candidate dimensions**: named by user, or enumerated from dataset schema

---

## Core Rules

### 0. Always work from the dataset — never ask the user to add context

Inspect the dataset fields and metric definitions directly using available tools. Do not ask the user to pin views, add breakdowns, or provide context that can be read from the dataset. The only allowed clarifying questions: target metric if genuinely ambiguous, or date range if not specified.

### 1. Never assume metric structure

Do not assume numerator, denominator, dimension list, or filter values. Inspect the dataset first. If the metric is a ratio and additive components are unclear, say so and ask.

### 2. Delta-only ranking — no volume weighting

Rank segments by `delta_value` — not by `abs(delta_value)`. For a drop, sort ascending (most negative first); for an increase, sort descending (most positive first). Do not multiply by segment volume, denominator, or any weight. Do not introduce a weighting basis.

### 3. Contribution percentage

- `delta_value = base_value - comparison_value` for each segment
- `overall_delta_value = overall_base_value - overall_comparison_value` (computed without segment grouping)
- `contribution_pct = delta_value / overall_delta_value × 100`

Driver segments (moving in same direction as overall) produce a positive `contribution_pct`. Offset segments (moving against overall) produce a negative `contribution_pct`.

Combined contribution of a group of segments = `sum(their delta_values) / overall_delta_value × 100`. For ratio metrics this is an approximation — segment ratios do not sum linearly — note it briefly when reporting.

`overall_delta_value` must be computed as a separate query without the segment dimension. Do not derive it by summing segment deltas.

### 4. Null safety first

- `where()` in AQL returns null when no rows match — always wrap with `coalesce(..., 0)`
- `safe_divide` returns null when denominator is zero or either operand is null — always wrap with outer `coalesce(..., 0)`
- **Coalesce each additive component individually before any arithmetic.** Never add or subtract potentially-null values directly — `1 + null = null`, which silently nullifies the entire expression. For any metric with multiple components (e.g. numerator = A, denominator = A + B), always write `coalesce(A, 0) + coalesce(B, 0)`, not `A + B`. The outer `coalesce(safe_divide(...), 0)` is not sufficient on its own if any component feeding the denominator is null.
- Never compute `delta_value` from raw nullable values
- New segment detection: if `comparison_value_raw IS NULL` and `base_value_raw IS NOT NULL`, the segment is new in the base period — flag it in prose
- Disappeared segment detection: if `base_value_raw IS NULL` and `comparison_value_raw IS NOT NULL`, the segment disappeared in the base period — flag it in prose
- **Never omit any segment from the output.** Every segment that exists in either the base or comparison period must appear in the output (chart or table), regardless of whether its metric value is null, 0, or has data. A null or zero metric in one period is valid data — do not filter it out.

### 5. Period consistency

All period-specific fields, labels, and filters must refer consistently to the same period throughout.

### 6. Prioritize top 3 dimensions before analysis

1. Enumerate eligible low-to-medium cardinality, business-relevant dimensions from the dataset schema
2. Rank by semantic relevance to the target metric — prefer dimensions where the metric is likely to vary meaningfully, prefer business-actionable dimensions, avoid high-cardinality or technical fields
3. Select top 3 (or all if fewer exist) — do not pad with weak dimensions

Do not ask the user to pick dimensions before the list is shown.

### 7. Sequential execution — one dimension at a time

Analyze one dimension per step. Show output for that dimension, then immediately proceed to the next confirmed dimension. Do not batch or union multiple dimensions in one query.

If a dimension fails (query error, no data, schema mismatch, or any other issue), skip it silently and continue to the next dimension. Record the failure reason for the Phase 4 summary table.

---

## change_analysis Context Detection

Before running any phase, check the conversation history for a **Change Analysis — Stage 1 complete** block.

**If found** — this skill was triggered from the `change_analysis` orchestrator:
- Load `metric`, `direction`, `time_reference`, and `anomaly_verdict` from the block.
- In Phase 1:
  - Assign periods as follows (this logic applies only in the change_analysis flow):
    - `base_period` = `time_reference` from the Stage 1 block (the period the user referred to)
    - `comparison_period` = the immediately preceding period at the same granularity
      (e.g., April 2021 → March 2021, Q2 2021 → Q1 2021, 2021 → 2020)
  - **Do not call `ask_user` for period confirmation.** Skip the Phase 1 confirmation prompt entirely.
  - Instead, output this plain-text announcement before proceeding to Phase 2:
    > "You're asking me to break down **[metric]** by dimensions to see where the [drop/increase]
    > happened the most. In this analysis, I'll compare **[comparison_period_name]** with
    > **[base_period_name]** to see which dimensions changed the most between those periods."
  - Then proceed directly to Phase 2.
- In Phase 2: prepend one sentence before the standard overview, referencing the anomaly verdict:
  - If `anomaly_verdict` = Anomalous → *"The anomaly check confirmed this [drop/increase] is
    unusual. Let's find what drove it."*
  - If `anomaly_verdict` = Within normal range → *"Note: the anomaly check found this
    [drop/increase] is within the normal range. Here's the breakdown for reference:"*

**If not found** — manual invocation. Run all phases as normal with no changes.

---

## Execution Phases

Follow these phases in strict order. Each phase defines exactly what to compute and what to show before moving on. Do not skip ahead or batch phases together.

---

### Phase 1 — Resolve periods and confirm with user

**Compute:**

Resolve the user's period descriptions to explicit date literals:
- Single period stated (e.g., "explain the drop in Mar 2021") → base = Mar 2021, comparison = immediately preceding period (Feb 2021)
- Two explicit periods stated (e.g., "increased from Dec to Jan", "from X to Y") → base = the TO/ending period being analyzed (Jan), comparison = the FROM/starting period (Dec)
- Relative descriptions (e.g., "last month vs this month") → base = the later/stated period (this month), comparison = the earlier/preceding period (last month)

Detect granularity and apply the correct `@()` literal format:
- "Feb 2021", "February 2021", "last month" → month → `@(YYYY-MM)` e.g. `@(2021-02)`
- "Q1 2021", "first quarter" → quarter → `@(YYYY-QN)` e.g. `@(2021-Q1)`
- "2021", "last year" → year → `@(YYYY)` e.g. `@(2021)`
- "week of Feb 8", "W06 2021" → week → `@(YYYY-WNN)` e.g. `@(2021-W06)`
- Specific dates ("Feb 15 2021", "yesterday") → day → `@(YYYY-MM-DD)` e.g. `@(2021-02-15)`

Store as `base_period_literal` and `comparison_period_literal` — these must be used verbatim in every subsequent query. Do not generate any query yet.

**Show:**

Determine whether confirmation is required before proceeding:

- **Skip confirmation and proceed to Phase 2 directly** when:
  - The user provided **both periods explicitly and unambiguously** (e.g. "between 10/24 and 11/24", "Q1 vs Q2 2024", "from Jan 2024 to Mar 2024"), **or**
  - The user provided **two relative but fully resolvable periods** (e.g. "this month vs last month", "last quarter vs the one before") — resolve them to absolute date literals using today's date, then proceed without asking

- **Show confirmation** (using `ask_user`) when:
  - Only **one period is stated** and the comparison period is inferred, **or**
  - The period format is **ambiguous** (e.g. "10/24" could mean October 2024 or day 10 of a month)

When confirmation is required, use `ask_user`. The question title **must be this exact sentence** — fill in the bracketed values, do not paraphrase, shorten, or substitute any other wording:

> You're asking me to analyze the [drop/increase] in **[metric]** between **[comparison_period_literal]** and **[base_period_literal]**. Please confirm these periods before I proceed.

Options:
> - Yes — that's correct, proceed
> - No — I meant a different comparison
> - Something else: ___

**Wait for user response before proceeding.**

- **Yes** → proceed to Phase 2
- **No** or **Something else** → re-resolve periods, re-show confirmation, wait again

---

### Phase 2 — Compute overall delta, show overview, propose dimensions, confirm

**Compute:**

Run the overall delta query (no segment grouping):
- `overall_base_value = coalesce(metric in base_period_literal, 0)`
- `overall_comparison_value = coalesce(metric in comparison_period_literal, 0)`
- `overall_delta_value = overall_base_value - overall_comparison_value`
- `pct_change = coalesce(safe_divide(abs(overall_delta_value), overall_comparison_value), 0) × 100`

If `overall_delta_value = 0`: stop. Inform the user the metric did not change net between the two periods. Do not proceed further.

Scan the **user's original message** in the conversation history (not AI output) for explicitly named dimensions (e.g. "by category and campaign", "break it down by region", "which segments drove it"). Store this as `user_specified_dimensions` (ordered list, or empty if none found).

If `user_specified_dimensions` is empty: inspect the dataset schema and select top 3 dimensions per Core Rule 6.

**Show:**

**If `user_specified_dimensions` is non-empty — fast path:**

Run only Steps 1 and 2, then proceed directly to Phase 3 using `user_specified_dimensions` as the confirmed dimension list. Do NOT run Steps 3, 4, or 5. Do NOT stop for confirmation.

**If `user_specified_dimensions` is empty — standard path:**

Execute these five steps in the exact order below. Do not reorder, skip, or batch any step.

**Step 1 — Output the overview sentence as plain text:**

> [Metric] [dropped/increased] [pct_change]%, from [comparison_value] to [base_value] between [comparison period] and [base period].

**Step 2 — Call `execute_aql`** with the overall delta query from the Compute step. This renders the overall metric change table immediately after the overview sentence. Title it:

> Overall [Metric] Change: [base_period_name] vs [comparison_period_name]

The table must include these columns: Comparison Value, Base Value, Delta Value, Pct Change.

**Step 3 — Output the transition sentence as plain text:**

> **There are multiple ways to explain what drove this change. In this analysis, I'll break it down by dimensions to identify which segments moved the most.** Here are my top [N] proposed dimensions:

**Step 4 — Output the dimension list as plain text.** This is a text output step, not a tool call. Write the numbered list directly in your response. Each item must include a short reason — **5–8 words max, business-focused, no technical jargon**:

> **1. Dimension Name** — short business reason (e.g. "varies most by sales team", "differs by product line")
>
> **2. Dimension Name** — short business reason
>
> **3. Dimension Name** — short business reason

**Step 5 — Output the Stage 1 Summary Block as plain text, then STOP:**

> ---
> Here's a summary of what we're going to analyze:
>
> - **Metric**: [metric name]
> - **Comparison period**: [comparison_period_literal] ([comparison_period_name])
> - **Base period**: [base_period_literal] ([base_period_name])
> - **Overall change**: [metric] [dropped/increased] [pct_change]%, from [comparison_value] to [base_value] (Δ [±overall_delta_value])
> - **Dimension 1**: [dim1]
> - **Dimension 2**: [dim2]
> - **Dimension 3**: [dim3]
>
> Shall I proceed to break down **[metric]** by each of these dimensions to see where the [drop/increase] happened the most?
> ---

**Do NOT call `ask_user` here.** Stop after outputting this block and wait for the user to reply in the chat.

---

### Stage 2 Detection — check before Phase 3

Before running Phase 3, check the conversation history:

- **If a Stage 1 Summary Block is present** (contains confirmed metric, periods, overall delta, and dimension list):
  - Check the user's most recent reply:
    - **Affirmative** (e.g. "yes", "proceed", "go ahead", "sure", "looks good") → load metric, `base_period_literal`, `comparison_period_literal`, `overall_delta_value`, and confirmed dimension list from the block. Do NOT re-run Phases 1 or 2. Proceed directly to Phase 3 with dimension #1.
    - **Requests changes** (e.g. "remove X", "swap Y for Z", "add Y", "use X instead") → update the dimension list based on the feedback, output a new Stage 1 Summary Block with the updated list, then proceed directly to Phase 3. Do not stop for another confirmation.
    - **Negative** (e.g. "no", "stop", "that's enough", "skip it") → stop. Output a single closing sentence: "Got it — stopping here. Let me know if you'd like to explore any dimension further." Do not proceed to Phase 3.

- **If no Stage 1 Summary Block is present**: this is a fresh invocation — run from Phase 1.

---

### Phase 3 — Analyze one dimension (repeat for each confirmed dimension)

Execute this phase once per dimension, in confirmed order. Complete the full phase — compute, show, wait — before moving to the next dimension.

**Show (once, before starting any dimension analysis):**

Display the confirmed dimension list as a section header so the user can see exactly what will be analyzed:

> # Analyzing these dimensions
> 1. [dim1]
> 2. [dim2]
> 3. [dim3]

Always show this, even when the user accepted the proposed list without changes.

**Compute:**

1. Resolve the sort direction from `overall_delta_value` — use this value when filling in the AML template below:
   - `overall_delta_value < 0` (drop) → `sort_direction = 'asc'` (most negative first)
   - `overall_delta_value > 0` (increase) → `sort_direction = 'desc'` (most positive first)

2. Write the per-dimension `CombinationChart` AML block using the template below. Fill in every placeholder before calling `execute_viz`:

   - `[dataset_uname]` — dataset identifier from Phase 2
   - `[date_field]` — the date field used for period filtering (e.g., `orders.created_at`)
   - `[base_period_literal]` and `[comparison_period_literal]` — confirmed literals from Phase 1
   - `[base_period_name]` and `[comparison_period_name]` — human-readable period names
   - `[metric_name]` — display name for the Y-axis label
   - `[metric_formula]` — for additive metrics: the raw field reference (e.g., `revenue_won`). For ratio metrics: rebuild inline with coalesced components — `safe_divide(coalesce(num, 0), coalesce(den_A, 0) + coalesce(den_B, 0) + ...)` — applied before the `where()` filter
   - `[dimension_label]` — display name of the dimension
   - `[dimension_field_ref]` — field ref from dataset schema in `table.field` format (e.g., `owners_csv.owner`), used inside `r(...)` in the AML
   - `[sort_direction]` — `'asc'` for drops, `'desc'` for increases. Always fill in the actual value — never leave as a placeholder

   **Note:** In the template below, each `formula:` line ends with `[END]` as a placeholder. Replace every `[END]` with two semicolons (`; ;` without the space) when writing the actual AML block. (Literal double-semicolons cannot appear in this skill file as they are the AML content terminator.)

       CombinationChart {
         dataset: [dataset_uname]
         calculation base_value_raw {
           label: 'Base Value Raw'
           formula: @aql [metric_formula] | where([date_field] is [base_period_literal])[END]
           calc_type: 'measure'
           data_type: 'number'
         }
         calculation comparison_value_raw {
           label: 'Comparison Value Raw'
           formula: @aql [metric_formula] | where([date_field] is [comparison_period_literal])[END]
           calc_type: 'measure'
           data_type: 'number'
         }
         calculation base_value {
           label: '[base_period_name]'
           formula: @aql coalesce(base_value_raw, 0)[END]
           calc_type: 'measure'
           data_type: 'number'
         }
         calculation comparison_value {
           label: '[comparison_period_name]'
           formula: @aql coalesce(comparison_value_raw, 0)[END]
           calc_type: 'measure'
           data_type: 'number'
         }
         calculation delta_value {
           label: 'Δ Change'
           formula: @aql base_value - comparison_value[END]
           calc_type: 'measure'
           data_type: 'number'
         }
         x_axis: VizFieldFull {
           label: '[dimension_label]'
           ref: r([dimension_field_ref])
           format {
             type: 'text'
           }
         }
         y_axis {
           label: '[metric_name]'
           series {
             mark_type: 'column'
             field: VizFieldFull {
               label: '[base_period_name]'
               ref: 'base_value'
               format {
                 type: 'number'
               }
             }
             settings {
               color: '#255DD4'
             }
           }
           series {
             mark_type: 'column'
             field: VizFieldFull {
               label: '[comparison_period_name]'
               ref: 'comparison_value'
               format {
                 type: 'number'
               }
             }
             settings {
               color: '#92AEEA'
             }
           }
         }
         y_axis {
           label: 'Δ Change'
           settings {
             alignment: 'right'
           }
           series {
             mark_type: 'line'
             field: VizFieldFull {
               label: 'Δ Change'
               ref: 'delta_value'
               format {
                 type: 'number'
               }
             }
             settings {
               color: '#1F3864'
               line_interpolation: 'smooth'
             }
           }
         }
         settings {
           sort {
             field_index: 2
             direction: '[sort_direction]'
             type: 'series'
           }
           legend_label: 'top'
           x_axis_label: '[dimension_label]'
         }
       }

3. Call `execute_viz` with the completed AML block, `dataset_uname`, and a title (e.g., `"[Metric] by [Dimension] — [base_period_name] vs [comparison_period_name]"`). The result data returned by `execute_viz` contains all calculation values including `base_value_raw`, `comparison_value_raw`, and `delta_value` — use this for segment classification in step 4 and `contribution_pct` in step 5.

4. From the chart result data, classify each segment's `impact_direction` (post-query):
   - `overall_delta_value < 0` and `delta_value < 0` → driver_of_change
   - `overall_delta_value < 0` and `delta_value > 0` → offset_to_change
   - `overall_delta_value > 0` and `delta_value > 0` → driver_of_change
   - `overall_delta_value > 0` and `delta_value < 0` → offset_to_change
   - `delta_value = 0` → neutral

5. Compute `contribution_pct = delta_value / overall_delta_value × 100` for each segment using the scalar `overall_delta_value` from Phase 2.

6. Compute and store `dimension_driver_pct = sum(delta_value for all driver_of_change segments) / overall_delta_value × 100` — used to rank dimensions in Phase 4.

**Show:**

1. Header: `# [Metric] breakdown by [Dimension Name] — [N] segments`
2. The combo chart generated above — **this is the only viz output at this step, no DataTable.**
3. One sentence summarizing the overall picture for this dimension (e.g. which direction most segments moved, whether the change was concentrated or spread).

4. Segment insight — output as concise prose, no tables.

   Write one sentence describing the overall pattern for this dimension (e.g. "Most segments moved in the same direction as the overall drop.").

   Then list the **top 3 driver segments** (those moving in the same direction as the overall change) as bullets:

   > The top drivers were:
   > - **[Segment A]**: [contribution_display] of the net [drop/increase] ([±delta])
   > - **[Segment B]**: [contribution_display] of the net [drop/increase] ([±delta])
   > - **[Segment C]**: [contribution_display] of the net [drop/increase] ([±delta])

   **Contribution display rule:** if `|contribution_pct| > 100%`, show `[N]× the net change` where N = round(|contribution_pct| / 100, 1). Otherwise show `[contribution_pct]%`.

   If there are more than 3 driver segments, list the rest in a single follow-on sentence:
   > [Segment D], [Segment E], and [Segment F] also contributed (range: [min_delta] to [max_delta]).

   If offset segments exist (moving against the overall change), add one sentence:
   > [Segment G] and [Segment H] moved in the opposite direction, partially offsetting the [drop/increase].

   Omit the offset sentence if no offset segments exist.

5. Conditional flags — each as its own bullet, only when applicable:
   - `↑ [Segment] bucked the trend ([comparison_value] → [base_value], [±delta]).`
   - `Change is spread broadly — no single segment dominates.`
   - `⚠ [Segment] is new in [base period] — not a rate change.`
   - `⚠ [Segment] absent in [base period] — reflects exit from data.`
   - `⚠ [Segment] moved [N]× the net change. The overall change is small, but that's because large drops in some segments were offset by large gains in others — not because things were stable.`
6. After displaying output, immediately proceed to the next confirmed dimension without prompting. After all dimensions are complete, proceed to Phase 4.

If the dimension fails at any point (query error, empty result, schema issue, etc.), skip it silently and continue to the next. Record the dimension name and failure reason for the Phase 4 summary table.

---

### Phase 3 Completion → Proceed to Phase 4

Immediately after outputting the last confirmed dimension's analysis (the final chart + prose block):
- Do NOT stop, pause, or wait for user input.
- Do NOT end the response.
- Continue within the same response and proceed directly to Phase 4.

Phase 4 is mandatory and requires no user confirmation. Skipping it is not allowed.

If Phase 4 was not produced in the same response as the final Phase 3 output (e.g., due to response length), run Phase 4 immediately at the start of the next response before addressing anything else.

---


### Phase 4 — Final overview

Produced after all confirmed dimensions are complete, or after the user stops early.

**Do NOT display any charts or visualizations in this phase.** The per-dimension charts were already shown in Phase 3 — do not repeat them here.

**Show:**

Opening heading and summary line:
> # Summary
>
> [Metric] [dropped/increased] by [pct_change]% (from [comparison_value] to [base_value], [±abs(delta)]) between [comparison period] and [base period].

Ranked table of all confirmed dimensions, sorted by `dimension_driver_pct` descending. Successfully analyzed dimensions appear first; failed dimensions appear at the bottom:

| Dimension | Top Segment | Contribution to change |
|-----------|-------------|------------------------|
| … | | |

For the **Contribution to change** column, apply the same threshold rule as the per-segment display:
- If `|dimension_driver_pct| ≤ 100%`: show `[dimension_driver_pct]%`
- If `|dimension_driver_pct| > 100%`: show `[N]× the net change` where [N] = round(|dimension_driver_pct| / 100, 1)

**Conditionally include (one line each):**

- Dimension with no dominant segment → add note in Top Segment cell: `spread across segments`
- Failed dimension → set Top Segment to `Failed to analyze: [reason]`, Contribution to change to `—`

**Always include at the end:**

> **You might want to:**
> - [suggestion 1]
> - [suggestion 2]
> - [suggestion 3]

---

## Implementation Notes for Holistics / AQL

- `base_period_literal` and `comparison_period_literal` are resolved and confirmed in Phase 1 — every query must use these exact values for period filtering, with no exceptions
- Never use `relative_period()` for period filtering — it does not reliably resolve ratio metrics across all dimensions and can produce NULL measures. Always filter with explicit `where(date_field is @(literal))` using the confirmed literals
- `@()` literals must match the period granularity: `@(YYYY-MM-DD)` for days, `@(YYYY-WNN)` for weeks, `@(YYYY-MM)` for months, `@(YYYY-QN)` for quarters, `@(YYYY)` for years. Never use a day literal `@(YYYY-MM-DD)` for a month or quarter period — it filters only a 2-day window, not the full period.
- Before generating any query, define `base_period_name`, `comparison_period_name`, `base_period_literal`, `comparison_period_literal` — reuse these exact aliases throughout
- Reuse existing dataset metric definitions whenever possible; inspect before deciding how to compute segment values. Exception: for ratio metrics, do not reference the pre-built ratio field directly in the query — pre-built ratios often lack per-component null handling and will silently return null when any component is null. Instead, inspect the metric definition to identify its numerator and denominator components, then rebuild the formula inline using `coalesce(safe_divide(coalesce(num_component, 0), coalesce(den_A, 0) + coalesce(den_B, 0) + ...), 0)`
- Always wrap `where()` aggregations with `coalesce(..., 0)` — `where()` returns null, not 0, when nothing matches
- Always wrap ratio metrics with outer `coalesce`: `coalesce(safe_divide(num, den), 0)` — `safe_divide` returns null for any null operand or zero denominator; the outer coalesce is sufficient to guarantee a non-null result
- `contribution_pct` is computed post-query from chart result data: divide each segment's `delta_value` by the scalar `overall_delta_value` — do not attempt to express this as a single AQL formula within the segment-grouped query
- Never apply any filter that excludes null or zero metric values. All segments must be visible regardless of their metric value in either period
- Run one AQL query per dimension — never union or batch dimensions
- Do not introduce volume weighting of any kind
- For ratio metrics, note in output that combined contribution % across multiple segments is an approximation
- Never call `execute_aql` during Phase 3 — it renders a visible result table to the user. Use `execute_viz` with a hand-written AML block instead.
- For Phase 3 combo charts, do not call `generate_viz` — write the `CombinationChart` AML block directly using the template in step 2, then call `execute_viz`. Sort is controlled by the `settings { sort { field_index: 2, direction: '...', type: 'series' } }` block — `field_index: 2` always refers to `delta_value` (series index 0 = base_value column, 1 = comparison_value column, 2 = delta_value line). Fill in `direction` with the pre-resolved value (`'asc'` or `'desc'`) — never leave it as a placeholder.

;;
