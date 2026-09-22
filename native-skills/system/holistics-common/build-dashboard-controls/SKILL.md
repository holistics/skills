---
name: build-dashboard-controls
label: Build Dashboard Controls
description: |-
  Add or edit a Holistics dashboard's interactive controls and the interactions that wire them: field and date-range filters (FilterBlock), date drill (DateDrillBlock), period-over-period comparison (PopBlock).

  Use when the user wants to add, change, or scope a control, or to move a dashboard's legacy `interactions` onto `explicit_interactions`.

  Typical phrasings: add a filter, filter by category, let viewers slice by X, add a date range or date picker, let viewers switch granularity, compare year over year, this filter should only affect X.

  Do NOT trigger for building a new dashboard, authoring chart or text content, or theming and restyling.
user-invocable: false
---

# Dashboard Controls (filters, date drill, period comparison, interactions)

Add interactive controls to a dashboard and explicitly declare their interactions.

## What a good input looks like

A controls task is fully specified when you can identify:

1. **Intentions** — What questions should viewers be able to answer? (e.g., "show me just last quarter," "just the EU," "by week instead of month," "how does that compare to last year?"). Each intention translates into a control. (See Workflow → *step 2* to determine the right construct).
2. **Field** — The underlying data field each filter reads. While often derivable from the blocks, clarify or state your assumption whenever it is ambiguous to ensure charts aren't filtered by the wrong field.
3. **Scope** — Which specific blocks each control should affect, and which it must ignore (e.g., other tabs, unrelated charts, other filters). Fields determine what a control reads; scope determines what it changes.
4. **Defaults** — Every control should start in a neutral state. Copy the `default` blocks exactly as written in Schema → *Control blocks*, inserting specific values only if the user requested a starting point.

## What a bare minimum output looks like

* **Time-based dashboards require a date-range filter.** If a dashboard shows trends over time and lacks a way to re-window that time, it is missing its most essential control.
* **Dimensions earn a filter only if they meet three criteria:** (1) the dimension actually breaks down a block on the dashboard; (2) it has low cardinality and high business value; and (3) filtering by it answers a question the current layout does not. If it fails any of these, skip it to avoid clutter.
* **Combine redundant filters.** If two filters segment data similarly (e.g., Region and Country, or Plan and Tier), consolidate them into the single level that best fits the reader's mental model.
* **Keep controls proportional to the dashboard's purpose.** An overview dashboard supports a wide row of controls. A lean scorecard or an operational view requires fewer. Add a date drill only when time-grain switching is needed, and a PoP only for period comparisons—do not add them by default.
* **Fully wire every control.** An unwired control is deceptive because it appears functional. Every control must be fully connected the moment it is created.

## Workflow

1. **Analyze `page.aml` first**, even if the conversation summarizes it. Identify real block names, viz types, date field references `r(<model>.<field>)`, and tab memberships. Wire connections using real names only. Check the interactions key: if you see `explicit_interactions`, work within that array. If you see only `interactions`, or neither, it is a legacy dashboard—read Conventions → *Legacy dashboards* before modifying any wiring.
2. **Determine the control set** based on the existing blocks and user intentions. State your decisions clearly; only ask the user for input if a scoping decision is both highly ambiguous and consequential.
3. **Declare each control and its interaction** (per the Schema). A control without a declared interaction does nothing. Group all targeted blocks by the field they read. (Note: Newly added viz blocks also start unwired, so include them in the interactions of any controls that should reach them).
4. **Verify the routing matrix.** Ensure every control-to-block relationship appears in exactly one `to` list under the field that block reads. Confirm no `to` list targets a block on a tab where the control isn't visible. Ensure filters do not target other filters unless a cascading hierarchy was requested. **Crucial limit: No viz block may appear in more than one `DateDrillInteraction` or more than one `PopInteraction`.** Finally, fix any code diagnostics.
5. **Deliver.** Summarize which controls reach which blocks, their default states, and explicitly note any elements you deliberately left unwired.

## Schema

These are the ONLY control constructs available in AML—do not invent others. Declare control blocks like any other block, then wire **every** control inside ONE `explicit_interactions: [ … ]` array at the Dashboard level (never inside a tab or block body). A control is incomplete without its interaction.

### Control blocks

The `default` blocks below represent the **neutral opening state**—copy them as written. Replace values only when a specific starting point is requested (e.g., a filter takes a real `operator`/`value`, a drill takes a grain like `'month'`, and a PoP takes a `duration`/`granularity`).

**Prefer field filters.** Because they are backed by a model field, they inherit the correct data type and support drill-through. Reach for a manual filter (where `type:` is `'date'`, `'text'`, `'number'`, or `'truefalse'`, with no underlying field) only when the target blocks span **different datasets**. Both types of filters only affect the blocks listed in their interactions.

```aml
block <filter>: FilterBlock {                         // field filter — the default choice
  label: 'Filter Label'
  type: 'field'                                       // takes its data type from the field
  source: FieldFilterSource { dataset: <dataset_name> field: r(<model>.<field>) }
  default { operator: 'matches' value: '$H_NIL$' }
}
block <date_filter>: FilterBlock {                    // manual filter — only across datasets
  label: 'Date Range'
  type: 'date'                                        // or 'text' | 'number' | 'truefalse'
  default { operator: 'matches' value: '$H_NIL$' }
}
block <drill>: DateDrillBlock { label: 'Date Drill' default: 'default' }
block <pop>: PopBlock {                               // the ONLY period-comparison construct — no PeriodComparisonBlock exists
  label: 'Compare To'
  default { type: 'relative' duration: [] }
}
```

### explicit_interactions — one array at the Dashboard level, wiring every control block above

Each entry consists of one `from` control, one `field`, and a `to` array of plain strings naming the blocks that read that field.

```aml
explicit_interactions: [
  FilterInteraction {
    from: '<filter>'                                        // every viz block the filter should slice
    to: ['<viz_block_1>', '<viz_block_2>']
    field: r(<model>.<field>)
  },
  FilterInteraction {
    from: '<date_filter>'                                   // blocks on another model read another field:
    to: ['<order_viz_1>', '<order_viz_2>']                  // same `from`, one entry per field
    field: r(<orders_model>.<date_field>)
  },
  FilterInteraction {
    from: '<date_filter>'
    to: ['<customer_viz>']
    field: r(<users_model>.<date_field>)
  },
  DateDrillInteraction {
    from: '<drill>'                                         // every time-series block; a block takes at most ONE drill
    to: ['<trend_viz>']
    field: r(<model>.<date_field>)
  },
  PopInteraction {
    from: '<pop>'                                           // every KPI *and* the trend; a block takes at most ONE pop
    to: ['<kpi_1>', '<kpi_2>', '<trend_viz>']
    field: r(<model>.<date_field>)
  }
]
```

A dashboard with no controls still carries an empty `explicit_interactions: []` array. If a canvas dashboard lacks this key entirely, it falls back to legacy behavior, automatically linking filters and charts that share a dataset.

## Conventions

### How interactions work — nothing connects unless it's listed

An interaction is a directed edge (`from → to`) inside the `explicit_interactions: []` array. There are no implicit connections: a control affects *only* the blocks explicitly listed. Every connection is dead until declared.

* **filter → viz**: Applies to both field and manual filters. List every block the filter should slice under the field that block reads.
* **date drill → viz**: Adjusts the time grain for the listed blocks. List every applicable time-series block. **A viz block can take at most one date drill.**
* **pop → viz**: Applies period comparison to the listed blocks. You must list **every KPI and the trend** (a KPI's "vs previous period" comes from this interaction, not the KPI itself). **A viz block can take at most one PoP.**
* **filter → filter**: Creates a parent-child relationship (e.g., picking a country narrows the city options). Declare this only if the user specifically requests cascading filters.
* **viz → viz**: Clicking a data point cross-filters other blocks. (The `field` is optional here). Declare this only if cross-filtering is requested, and restrict it to blocks on the same tab.

For `FilterInteraction`, `from` can be a filter or a viz block. `DateDrillInteraction` and `PopInteraction` strictly route from a control to a viz block. The `aggregation` key is an optional override when targeting viz blocks.

**Tab Boundaries:** Connections do not cross tabs. A control placed on one tab should only target blocks on that same tab. You do not need to explicitly disable cross-tab interactions; simply omitting those blocks from the `to` list is sufficient.

**Avoid `disabled: true`:** An entry that includes `from`, `to`, and `disabled: true` simply turns the connection off. Leaving the entry out altogether achieves the exact same thing. If you see this in GUI-generated code, you may keep or remove it.

### Legacy dashboards — `interactions` and `CustomMapping`

Older dashboards define connections under `interactions: [ … ]`, where the `to` field contains `CustomMapping { block: … field: … }` objects. This legacy system auto-links filters and charts on the same dataset; the array only records exceptions (like using a different field or `disabled: true`).

Determine the active behavior using this matrix:

| `explicit_interactions` | `interactions` | In force |
| --- | --- | --- |
| present | present | `explicit_interactions` — the legacy array is ignored |
| present | absent | `explicit_interactions` |
| absent | present | `interactions`, plus auto-linking |
| absent | absent | auto-linking, no exceptions |

**Warning:** Adding `explicit_interactions` instantly disables the entire legacy `interactions` array and all auto-linking. Any connections you do not explicitly rebuild will silently break. Never mix a new explicit entry into a legacy array. Instead, convert the entire dashboard to the explicit model first, then apply the requested changes.

**When to convert:** Convert the dashboard when you need to change a control, modify an interaction, or add a block that a control should affect. If your task does not alter wiring (e.g., restyling, rewording, or simply moving blocks), leave the legacy array alone.

**How to convert:** Trace every currently active connection and explicitly declare it:

1. **Mapped edges:** Convert each `CustomMapping` (that has a `field`) into a new entry: retain the same `from` and `field`, and place the mapping's `block` names in the `to` array. Carry over any `aggregation` settings. Merge mappings that share a `from` and a `field` into a single entry.
2. **Auto-linked filter → viz edges:** By default, legacy field filters reached all viz blocks on their dataset (unless overridden). Add an explicit entry routing the filter to those blocks using the filter's own `source` field. (Note: Auto-linking ignored tabs. Retain a cross-tab edge only if the filter is actually visible on the target tab; otherwise, drop it and notify the user).
3. **Drill and pop edges:** These were never auto-linked. Carry over their mappings using Rule 1.
4. **Disabled edges:** Ignore these entirely. Omitting them is how you disable them in the new syntax.
5. **Parent-child and cross-filtering:** Legacy systems auto-linked filter → filter and viz → viz on the same dataset. Keep only the essential ones (e.g., obvious hierarchies like country → city, or user-requested cross-filters). Drop the rest, and list what was removed during delivery so the user can request them back if needed.
6. **Delete the `interactions` array:** Once `explicit_interactions` contains all necessary connections, delete the old array to prevent confusion for future editors.

Run Workflow → *step 4* on your resulting configuration. Upon delivery, confirm that the dashboard was migrated to the new syntax and outline any edges that were changed or dropped.

### Others

* **Cross-model filtering:** When one control affects blocks on different models, create one entry per field. For instance, a global date filter requires one entry with `field: r(users.sign_up_date)` for customer blocks, and a second entry with `field: r(orders.created_date)` for order blocks.
* **Narrowing scope:** If the user says "this filter should only affect the Orders tab," "don't let this touch the KPIs," or "apply the date range only to the trend," simply remove the excluded blocks from the control's `to` array. The remaining list defines its exact reach.
* **Adding a control is a three-part task:** (1) declare the block, (2) wire its interactions, and (3) place it in the layout. Missing step 2 creates a broken control; missing step 3 means it won't render at all. Placement matters: a page-wide control belongs at the top, a section-scoped control belongs near its section, and a tab-scoped control belongs inside its tab. Ensure it doesn't overlap existing content and maintains proper canvas height. **Note:** If `build-dashboard` is driving a fresh build, it handles layout positioning—you only need to supply the block and its wiring.
