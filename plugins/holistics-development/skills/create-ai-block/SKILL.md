---
name: create-ai-block
label: Create AI narrative on dashboard
description: |-
  Use when the user wants a dashboard AI Block that provides a data-backed narrative inline in the dashboard — such as a summary, executive readout, key insights, callout, or top-movers note.

  Typical phrasings: "add a summary for this dashboard", "add a block calling out the top movers", or "give viewers the takeaway here so they don't have to read the chart themselves".

  Do not use for a one-off explanation the user wants answered in chat with nothing saved to the dashboard — answer directly instead. Also do not use for a new chart or query, a dashboard restructure, or reformatting existing narrative text without adding content.
---
# Create an AI Block

Author and save the AI Block prompt; do not generate, preview, or simulate the narrative. The block produces its own narrative when it runs.

## Resolve scope

- Explicit `@VizBlock:dashboard_uname.viz_uname` mentions mean exactly those visualizations.
- "This tab" means `@Tab:dashboard_uname.view_uname` — the tab currently in the user's view — which includes all visualizations within it.
- "This dashboard" means `@Dashboard:dashboard_uname`, which includes all visualizations across its tabs.
- Referencing a tab or dashboard, rather than listing individual visualizations, keeps the AI Block current automatically: it updates on its own as visualizations are added or removed.
- If scope is missing, ask the user to choose the relevant tab, the full dashboard, or specific visualizations. Do not guess.
- An AI Block cannot use another AI Block as its source. Ask for non-AI-Block sources if one is included.

## Compose the prompt

Build the prompt from three components, combined into one instruction in the order the user stated them:

- **Source** — the scope resolved above, carried as its `@VizBlock:`/`@Tab:` mention or left implicit for "this dashboard."
- **Content requirement** — the user's requested angle: summary, key insights, comparison, callout, ranked findings, etc.
- **Output style** — tone and length the user stated, if any.

When content requirement or output style is absent, write one concise business-plain instruction without inventing sections, metrics, or analytical focus.

Examples:

> User: "add a summary block for this dashboard's KPIs"
> Prompt: "Summarize this dashboard's KPI trends for the period in view."

> User: "@VizBlock:sales_overview.revenue_trend and @VizBlock:sales_overview.signups — give me the key insights in 2–3 sentences"
> Prompt: "From @VizBlock:sales_overview.revenue_trend and @VizBlock:sales_overview.signups, give the key insights in 2–3 sentences."

> User: "summarize this dashboard, then list the top 3 movers and one action recommendation"
> Prompt: "Summarize this dashboard, then list the top 3 movers and close with one action recommendation."

## Place or update the block

1. Read the target dashboard file once. When editing an existing AI Block, read and revise its current prompt rather than replacing it blindly.
2. Use the current AML editor schema help or official documentation to confirm the `AiBlock` fields before editing.
3. Add or update the `AiBlock` with the composed prompt and a short, descriptive label.
4. For a new block on a canvas tab, place it below the lowest existing block without moving other blocks. Use half the tab width and a square size, i.e. its width equals its height, unless the user specifies a layout.
5. Validate the changed dashboard file.

Show the saved prompt, the target dashboard and tab, and validation status. If the request requires a new tab, broader rearrangement, or new interactions, use `build_dashboard` instead.