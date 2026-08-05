---
name: build-dashboard-controls
label: Build Dashboard Controls
description: |-
  Add or edit a Holistics dashboard's interactive controls and the interactions that wire them: field and date-range filters (FilterBlock), date drill (DateDrillBlock), period-over-period comparison (PopBlock).

  Use when the user wants to add, change, or scope a control.

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

1. **Read the dashboard's `page.aml` first**, even if the conversation summarises it — real block names, viz types, date field refs `r(<model>.<field>)`, tab membership. Wire against real names only.
2. **Derive the control set** from those blocks and the intentions. Decide and state it; ask only when a scoping call is both ambiguous and consequential.
3. **Declare each control with its interaction** (per Schema) — a control without its wired interaction is incomplete. Map the edges that are dead until mapped, disable the ones that are live (Conventions → *How interactions work*). Editing an existing dashboard means redoing this, or new blocks sit on platform defaults.
4. **Verify — walk the matrix.** Every source (each control; on tabbed dashboards every viz block too) × every block has a deliberate fate: mapped with the right field, or `disabled`. Neither one means it falls silently to platform defaults — usually a trend or a cross-dimension KPI. Then check the one hard limit: **no viz block appears in more than one drill mapping, or more than one pop mapping.** Then fix every code diagnostic.
5. **Deliver** — which controls reach which blocks, their defaults, and what you deliberately excluded.

## Schema

These are the ONLY control constructs in AML — do not invent others. Declare the control blocks like any other block, then wire **every** control in ONE `interactions: [ … ]` array at the Dashboard level (never inside a tab or a block body). A control is incomplete without its interaction.

### Control blocks

Every `default` below is the **neutral opening** — copy it as written. Replace a value only where the user named a starting point (then: a filter takes a real `operator`/`value`, the drill a grain like `'month'`, the PoP a `duration`/`granularity`).

**Prefer a field filter.** It's backed by a model field, so it takes that field's data type, auto-maps to same-tab blocks on its dataset, and supports drill-through. Reach for a manual filter (`type:` `'date'` / `'text'` / `'number'` / `'truefalse'`, no field behind it) only when the blocks it must reach span **different datasets** — and then map every block by hand, because a manual filter with no mapping filters nothing.

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

### interactions — one array at the Dashboard level, wiring every control block above

```aml
interactions: [
  // ── MAP: these do nothing until declared. One CustomMapping per block, each naming that block's own field.
  FilterInteraction {
    from: '<date_filter>'                                                                   // manual filter — unmapped, it filters nothing
    to: [ CustomMapping { block: '<viz_block>' field: r(<model>.<date_field>) } ]           // repeat per block it should slice
  },
  DateDrillInteraction {
    from: '<drill>'                                                                         // every time-series block; a block takes at most ONE drill
    to: [ CustomMapping { block: '<viz_block>' field: r(<model>.<date_field>) } ]
  },
  PopInteraction {
    from: '<pop>'                                                                           // every KPI *and* the trend; a block takes at most ONE pop
    to: [ CustomMapping { block: '<viz_block>' field: r(<model>.<date_field>) } ]
  },

  // ── DISABLE: these are live until switched off.
  FilterInteraction {
    from: '<filter>'                                                                        // field filter — already auto-maps to same-tab blocks on its dataset
    to: [
      CustomMapping { block: '<viz_block>' field: r(<model>.<other_field>) },               // only to override the auto-mapped field, or to reach past that set
      CustomMapping { block: ['<other_filter>', '<other_filter2>'] disabled: true },        // parent-child: every OTHER filter block — ALWAYS, single-page too
      CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true }    // TABBED: every viz block on the other tab(s)
    ]
  },
  // TABBED: viz→viz cross-filtering across tabs. For EVERY viz block, disable EVERY viz block on the other tab(s). Symmetric — repeat per viz block.
  FilterInteraction {
    from: '<tab_a_viz>'
    to: [ CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true } ]
  }
]
```

## Conventions

### How interactions work — every edge is explicit

An interaction is a directed edge `from → to` in the `interactions: []` array. What you don't declare falls back to Holistics' **implicit defaults**. Six edges exist, and they split into two opposite failure modes: some are **live until you disable them**, the rest do **nothing until you map them**.

Live by default — declare a mapping to *change* or `disabled: true` to *stop*:

* **field filter → viz** — auto-maps to same-tab blocks on its dataset. Map a block only to name a different field or to reach past that set; disable what shouldn't be sliced.
* **filter → filter** — parent-child: a value picked in one filter narrows another's options. Usually unwanted → `disabled: true`.
* **viz → viz** — clicking a data point cross-filters the others. Fine within a tab; disable where unwanted.

Dead until mapped — one `CustomMapping` per block, naming that block's own field:

* **manual filter → viz** — carries no field of its own, so an unmapped manual filter filters nothing.
* **date drill → viz** — re-grains only the blocks it's mapped to. Map every time-series block. **A viz block takes at most one date drill.**
* **pop → viz** — applies the comparison only to the blocks it's mapped to. Map **every KPI and the trend**, not just the trend — a KPI's "vs previous period" comes from here, never baked into the KPI. **A viz block takes at most one PoP.**

`FilterInteraction`'s `from` may be a filter or a viz; `DateDrillInteraction` and `PopInteraction` are control → viz only.

**With tabs, nothing crosses a tab boundary** — and which edges need work follows the same split. The three live-by-default edges (**field filter → viz**, **filter → filter**, **viz → viz**) each need a `disabled: true` mapping for every block on the other tab(s), symmetrically: if A disables B, B disables A. The dead-until-mapped edges need nothing — a manual filter, drill, or pop reaches only what it's mapped to, so leaving other-tab blocks unmapped already excludes them.

### Others

* **One control, blocks on different models → name the right field per block.** A global date filter maps `r(users.sign_up_date)` on customer blocks and `r(orders.created_date)` on order blocks.
* **When the user narrows a control's reach** — "this filter should only affect the Orders tab", "don't let this one touch the KPIs", "apply the date range to the trend only" — what that takes depends on the control. A manual filter, a drill, or a pop reaches only what you map it to, so map the blocks they named and you're done. A **field filter** already reaches every same-tab block on its dataset, so narrowing it means adding `disabled: true` for the blocks being excluded; mapping the ones they want achieves nothing on its own.
* **Adding a control is three tasks, not one** — declare the block, wire its interactions, place it in the layout. Miss the second and it renders as a working control that changes nothing; miss the third and it doesn't render at all. The third one changes hands: **standalone** (adding to an existing dashboard) you own it. Place a control so its position advertises its reach — one that affects the whole page belongs in a row at the top, one scoped to a section sits with that section, one that belongs to a tab goes on that tab. Then make room for it rather than overlapping anything, and keep the canvas height right. When **build-dashboard drives a fresh build**, it owns every position — supply the block and its wiring only.
