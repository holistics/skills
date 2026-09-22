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

Add controls to a dashboard and declare their interactions explicitly.

## What a good input looks like

A controls task is fully specified when you can answer:

1. **Intentions** — what viewers should be able to answer for themselves, in their words ("show me just last quarter", "just the EU", "by week instead of month", "how does that compare to last year?"). Each one becomes a control; which construct carries it is Workflow → *step 2*.
2. **Field** — which field each filter reads. Not strictly required — you can derive it from the blocks — but ask or state it whenever the choice isn't obvious, because the wrong field filters the right-looking chart.
3. **Scope** — which blocks each control affects, and which it must not (other tabs, unrelated charts, other filters). Fields say what a control reads; scope says what it changes.
4. **Defaults** — every control opens neutral. Copy the `default` blocks from Schema → *Control blocks* as written; put a real value in only where the user named a starting point.

## What a bare minimum output looks like

* **A time axis earns a date-range filter.** That one is near-automatic: a dashboard that trends over time and can't be re-windowed is missing its most-asked control.
* **A dimension earns a filter when all three hold** — it actually breaks down a block on this dashboard; it's low-cardinality and business-meaningful; and slicing by it answers something the layout doesn't already answer. Fail any one and the filter is a control the reader has to read past. That test, not a target count, sets the number.
* **Two filters that segment the same way count as one.** Region and country, plan and tier — pick the level the reader thinks in.
* **The job caps the set.** An overview supports the widest control row. A lean scorecard or an operational "what's happening now" view wants fewer; a lookup view wants its filters and its table and little else. Add a drill only when the job wants time-grain switching, a PoP only when it wants period comparison — neither by default.
* Every control is fully wired the moment it exists — a declared-but-unwired control is worse than none, because it looks functional.

## Workflow

1. **Read the dashboard's `page.aml` first**, even if the conversation summarises it — real block names, viz types, date field refs `r(<model>.<field>)`, tab membership. Wire against real names only. Note which interactions key the dashboard carries: `explicit_interactions` means work in that array; only `interactions`, or neither, means a legacy dashboard — read Conventions → *Legacy dashboards* before you touch any wiring.
2. **Derive the control set** from those blocks and the intentions. Decide and state it; ask only when a scoping call is both ambiguous and consequential.
3. **Declare each control with its interaction** (per Schema) — a control without its interaction is wired to nothing. List every block it should reach, grouped by the field each block reads. A block added later starts unwired too, so an edit that adds viz blocks also adds them to the controls that should reach them.
4. **Verify — walk the matrix.** Every control × every block it should reach appears in exactly one `to` list, under the field that block actually reads. No `to` list names a block on a tab the control isn't shown on. No filter names another filter unless the user asked for cascading options. Then the hard limit: **no viz block appears in more than one `DateDrillInteraction`, or more than one `PopInteraction`.** Then fix every code diagnostic.
5. **Deliver** — which controls reach which blocks, their defaults, and what you deliberately left unwired.

## Schema

These are the ONLY control constructs in AML — do not invent others. Declare the control blocks like any other block, then wire **every** control in ONE `explicit_interactions: [ … ]` array at the Dashboard level (never inside a tab or a block body). A control is incomplete without its interaction.

### Control blocks

Every `default` below is the **neutral opening** — copy it as written. Replace a value only where the user named a starting point (then: a filter takes a real `operator`/`value`, the drill a grain like `'month'`, the PoP a `duration`/`granularity`).

**Prefer a field filter.** It's backed by a model field, so it takes that field's data type and supports drill-through. Reach for a manual filter (`type:` `'date'` / `'text'` / `'number'` / `'truefalse'`, no field behind it) only when the blocks it must reach span **different datasets**. Either kind reaches only the blocks its interactions list.

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

Each entry is one `from`, one `field`, and the names of the blocks that read that field. `to` holds plain block-name strings.

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

A dashboard with no controls still carries `explicit_interactions: []`. A canvas dashboard without the key falls back to the legacy behavior, where filters and charts on the same dataset link themselves.

## Conventions

### How interactions work — nothing connects unless it's listed

An interaction is a directed edge `from → to` in the `explicit_interactions: []` array. There are no implicit defaults: a filter, drill, or pop changes exactly the blocks its entries name. Every edge is dead until you declare it.

* **filter → viz** — field filter and manual filter alike. List every block the filter should slice, under the field that block reads.
* **date drill → viz** — re-grains only the blocks listed. List every time-series block. **A viz block takes at most one date drill.**
* **pop → viz** — applies the comparison only to the blocks listed. List **every KPI and the trend**, not just the trend — a KPI's "vs previous period" comes from here, never baked into the KPI. **A viz block takes at most one PoP.**
* **filter → filter** — a `FilterInteraction` from one filter to another makes them parent-child: a value picked in the parent narrows the child's options. Declare it only when the user asks for cascading filters (country → city).
* **viz → viz** — a `FilterInteraction` from one viz block to others makes a click on its data point cross-filter them. `field` is optional on this edge. Declare it only when the user asks for cross-filtering, and only between blocks on the same tab.

`FilterInteraction`'s `from` may be a filter or a viz; `DateDrillInteraction` and `PopInteraction` are control → viz only. `aggregation` is an optional override on an entry whose targets are viz blocks.

**With tabs, nothing crosses a tab boundary.** A control placed on one tab lists only that tab's blocks. No disabling is needed — a block that isn't listed isn't reached.

**Don't write `disabled: true`.** An entry with `from`, `to`, and `disabled: true` switches an edge off, which leaving the edge out already does. Files saved from the GUI may contain it; it is safe to keep or to drop.

### Legacy dashboards — `interactions` and `CustomMapping`

Older dashboards wire controls under `interactions: [ … ]`, where `to` holds `CustomMapping { block: … field: … }` objects. That key runs on the opposite rule: filters and charts on the same dataset link themselves, and the array records only the exceptions — a different field, or `disabled: true`.

Which key is in force:

| `explicit_interactions` | `interactions` | In force |
|---|---|---|
| present | present | `explicit_interactions` — the legacy array is ignored |
| present | absent | `explicit_interactions` |
| absent | present | `interactions`, plus auto-linking |
| absent | absent | auto-linking, no exceptions |

Adding `explicit_interactions` to a legacy dashboard switches off the whole `interactions` array and all auto-linking in one step. Anything you don't carry across stops working, silently. So never add one explicit entry beside a legacy array. Convert the whole dashboard, then make the change the user asked for.

**When to convert.** Convert when the task changes a control or an interaction, or adds blocks that controls should reach. A task that leaves wiring alone (restyling, rewording, moving blocks) leaves the legacy array alone too.

**How to convert.** Work out every edge that is live today, then declare each one:

1. **Mapped edges.** Each `CustomMapping` with a `field` becomes an entry: same `from`, same `field`, the mapping's `block` names in `to`. Carry `aggregation` across. Merge mappings that share a `from` and a `field` into one entry.
2. **Auto-linked filter → viz edges.** Each field filter reached every viz block on its own dataset, unless a mapping disabled that block or gave it another field. Add an entry from the filter to those blocks, with the filter's own `source` field. Auto-linking ignored tabs, so those blocks can sit on other tabs. Keep a cross-tab edge only if the filter is shown on that tab too; otherwise drop it and say so.
3. **Drill and pop edges** were never auto-linked. Only their mappings carry over, by rule 1.
4. **Disabled edges** carry nothing over. Leaving them out is the conversion.
5. **Parent-child and cross-filtering.** Legacy linked filter → filter and viz → viz on the same dataset unless disabled. Carry across only the ones the dashboard depends on: a filter pair that reads as a hierarchy (country → city), or cross-filtering the user mentions. Drop the rest, and list what you dropped at delivery so the user can ask for it back.
6. **Delete the `interactions` array** once `explicit_interactions` holds everything. It is ignored from that point, and a wiring list that does nothing misleads the next reader.

Then run Workflow → *step 4* on the result. At delivery, say that the dashboard moved to the new syntax and which edges changed.

### Others

* **One control, blocks on different models → one entry per field.** A global date filter gets one entry with `field: r(users.sign_up_date)` listing the customer blocks, and another with `field: r(orders.created_date)` listing the order blocks.
* **When the user narrows a control's reach** — "this filter should only affect the Orders tab", "don't let this one touch the KPIs", "apply the date range to the trend only" — take the excluded blocks out of the control's `to` lists. What stays listed is its whole reach.
* **Adding a control is three tasks, not one** — declare the block, wire its interactions, place it in the layout. Miss the second and it renders as a working control that changes nothing; miss the third and it doesn't render at all. The third one changes hands: **standalone** (adding to an existing dashboard) you own it. Place a control so its position advertises its reach — one that affects the whole page belongs in a row at the top, one scoped to a section sits with that section, one that belongs to a tab goes on that tab. Then make room for it rather than overlapping anything, and keep the canvas height right. When **build-dashboard drives a fresh build**, it owns every position — supply the block and its wiring only.
