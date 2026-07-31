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

1. **Slicing needs** — which questions viewers answer *themselves* by filtering (by time window, by segment, by category, ...).
2. **Filter fields** — for each need, the concrete field: the primary date field, plus low-cardinality business dimensions actually used by the dashboard's blocks.
3. **Defaults** — **a filter never carries a `default`**: it opens showing all data, and an arbitrary default (like a date window) silently hides rows. (Only DateDrillBlock's starting granularity and PopBlock's comparison period take a default — those constructs require one.)
4. **Grain switching** — should viewers change the trend's granularity (date drill)? Compare against a prior period (PoP)?
5. **Scope** — exactly which blocks each control affects, and which it must not (other tabs, unrelated charts, other filters).

## What a bare minimum output looks like

* A dashboard with a time axis gets a date-range filter; one with dimensional breakdowns gets 1–3 dimension filters. Fewer only if the user explicitly wants none.
* **The control set follows the dashboard's job.** A date-range filter + 1–3 dimension filters suit an overview. A lean scorecard or an operational "what's happening now" view usually wants fewer controls and **no date drill or period comparison** — add a drill only when the job wants time-grain switching, and a PoP only when it wants period comparison, not by default.
* Every control is fully wired the moment it exists — a declared-but-unwired control is worse than none, because it looks functional.
* **A FilterBlock never gets a `default`** — it always opens showing all data (an arbitrary default silently hides rows). This does not touch DateDrillBlock/PopBlock defaults, which those constructs require.

## Workflow

1. **Read the dashboard's `page.aml` first** (even if a summary exists in the conversation) — extract real block names, viz types, date field references `r(<model>.<field>)`, and tab membership. Wire against real names only.
2. **Derive the control set** from the blocks — the date field the trend uses → date-range filter; breakdown dimensions → dimension filter candidates (low-cardinality, business-meaningful); a time-series chart → date drill; period comparison if asked. The prompt sets priorities and additions but does not cap the set. Ask only when a scoping decision is genuinely ambiguous AND consequential; otherwise decide and state it.
3. **Add each control with its interaction** (per Schema) — a FilterBlock / DateDrillBlock / PopBlock is incomplete without its wired interaction; **never give a FilterBlock a `default`**.
4. **Wire each control to every block it can affect, then turn off the exceptions** (see Conventions → *Declaring scope well*) — a filter can affect **every block on its dataset** (map each with the right field), the drill re-grains **every time-series block**, and **Period Comparison affects every KPI and the trend — not just the trend**. Then disable what you don't want: parent-child filter cross-linking, and cross-tab reach. Build the list by starting from every block the control can affect and removing exceptions — not by listing the ones that seem related, which is how the trend or a KPI gets missed. When editing an existing dashboard, redo this so new blocks aren't left on platform defaults.
5. **Verify — walk the matrix.** Confirm the construction was total: every source (each control, and on tabbed dashboards every viz block) × every block has a *deliberate* fate — mapped (with the right field) or `disabled`. A block a control neither maps nor disables is the failure (it silently falls to platform defaults); the usual miss is a trend or a cross-dimension KPI that a dimension filter or the period control forgot. Then check code diagnostics and fix every error.
6. **Deliver** — summarize which controls affect which blocks, their defaults, and what was deliberately excluded.

## Schema

These are the ONLY control constructs in AML — do not invent others. Declare the control blocks like any other block, then wire **every** control in ONE `interactions: [ … ]` array at the Dashboard level (never inside a tab or a block body). A control is incomplete without its interaction.

### Control blocks

```aml
block <filter>: FilterBlock {
  label: 'Filter Label'
  type: 'field'
  source: FieldFilterSource { dataset: <dataset_name> field: r(<model>.<field>) }
  // NEVER add a `default` — a FilterBlock opens showing all data
}
block <drill>: DateDrillBlock { label: 'Drill by' default: 'month' }   // 'year' | 'quarter' | 'month' | 'week' | 'day'
block <pop>: PopBlock {                                                 // the ONLY period-comparison construct — no PeriodComparisonBlock exists
  label: 'Period Comparison'
  default { type: 'relative' duration: 1 granularity: 'year' }         // granularity: 'year' | 'quarter' | 'month' | 'week' | 'day'
}
```

### interactions — one array at the Dashboard level, wiring every control block above

```aml
interactions: [
  // This array carries two kinds of disable:
  //   • ALWAYS (single-page included): parent-child filter→filter — each filter disables every OTHER filter block, so choosing a value in one doesn't narrow another's options.
  //   • TABBED only: nothing crosses a tab boundary — each filter / drill / pop / viz also disables every block on the other tab(s). Omit these lines on a single-page dashboard.
  FilterInteraction {
    from: '<filter>'
    to: [
      CustomMapping { block: '<viz_block>' field: r(<model>.<field>) },                     // affect this viz block (same tab) through this field
      CustomMapping { block: ['<other_filter>', '<other_filter2>'] disabled: true },        // parent-child: every OTHER filter block — ALWAYS, single-page too
      CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true }    // TABBED: every viz block on the other tab(s)
    ]
  },
  DateDrillInteraction {
    from: '<drill>'
    to: [
      CustomMapping { block: '<viz_block>' field: r(<model>.<date_field>) },
      CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true }    // TABBED: every viz block on the other tab(s)
    ]
  },
  PopInteraction {
    from: '<pop>'
    to: [
      CustomMapping { block: '<viz_block>' field: r(<model>.<date_field>) },
      CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true }    // TABBED: every viz block on the other tab(s)
    ]
  },
  // TABBED viz cross-filtering off too: for EVERY viz block, a FilterInteraction disabling EVERY viz block on the other tab(s). Symmetric — repeat per viz block.
  FilterInteraction {
    from: '<tab_a_viz>'
    to: [ CustomMapping { block: ['<other_tab_viz_1>', '<other_tab_viz_2>'] disabled: true } ]
  }
]
```

## Conventions

### How interactions work — every edge is explicit

An interaction is a directed edge `from → to` in the `interactions: []` array. What you don't declare falls back to Holistics' **implicit defaults** — it compiles cleanly but behaves wrong, silently. So declare every edge that matters, and disable the ones you don't want.

* **DateDrillInteraction / PopInteraction** have one shape: control **→ the viz blocks** it affects. The drill re-grains **every time-series block**; Period Comparison compares **every KPI and the trend — not just the trend** (a KPI's "vs previous period" comes from here, not from a period baked into the KPI). Control → viz only.
* **FilterInteraction** is the general cross-filter edge, and its `from` may be a filter **or** a viz — three kinds:
  * **filter → viz** — the filter slices the viz (map the semantically right field per block).
  * **filter → filter** — parent-child cross-linking: picking a value in one filter narrows another's options. Usually unwanted → `disabled: true`.
  * **viz → viz** — clicking a viz cross-filters the others. Within a tab it's often fine; disable where unwanted.
* **With tabs, nothing crosses a tab boundary.** Every interaction that would reach a block on another tab — filter → viz, **drill → viz, pop → viz**, filter → filter, and viz → viz — gets a `disabled: true` mapping for those blocks, symmetrically (if A disables B, B disables A). Each control and each viz affects only its own tab; cross-tab interaction is never intended.

### Declaring scope well

* **Wire a control to every block it can affect, then disable the exceptions.** A filter can affect every block on its dataset — map each one (with the right field). Period Comparison affects every KPI and the trend. The drill affects every time-series block. Start from that full set and turn OFF the ones you don't want (parent-child filter links, cross-tab reach). Don't build the list by guessing which blocks "go with" the control — that's how the trend or a KPI gets silently missed and left on platform defaults.
* When one filter feeds blocks built on different models, map the semantically right field per block — e.g. a global date filter maps `r(users.sign_up_date)` on customer blocks and `r(orders.created_date)` on order blocks. Never force one field onto every block.
* When the user scopes a control ("only the Orders tab"), map exactly those blocks and add `disabled: true` mappings for everything else — including blocks on other tabs, which are otherwise still subject to platform defaults.
* When adding a control to a dashboard that already has interactions, update the existing declarations so the picture stays complete — new blocks are otherwise silently back on defaults.
* Layout ownership: when invoked **standalone** (adding controls to an existing dashboard), place controls at the top of the canvas above the charts they affect, shift existing blocks down, and recompute the canvas height. When **build-dashboard is driving a fresh build**, it owns all positions — supply only the control blocks and their interaction wiring, not the layout.
