---
name: create-ai-block
label: Create AI Block
description: |-
  Use when the user wants a dashboard AI Block that saves a data-backed narrative — such as a summary, executive readout, key insights, callout, or top-movers note — to an existing dashboard. Typical phrasings: "add a summary for this dashboard", "summarize this page", "turn these charts into an executive readout", "add a block calling out the top movers", or "@Revenue Trend give me the key insights".

Do not use for a one-off explanation in chat, a new chart or query, a dashboard restructure, or reformatting existing narrative text without adding content.
---
# Create an AI Block

Author and save the AI Block prompt; do not generate, preview, or simulate the narrative. The block produces its own narrative when it runs.

## Resolve scope

- Explicit `@mentions` mean exactly those visualizations.
- "This dashboard" means all visualizations across its tabs.
- "This tab" or "this page" means the current tab only.
- If scope is missing, ask the user to choose the relevant tab, the full dashboard, or specific visualizations. Do not guess.
- An AI Block cannot use another AI Block as its source. Ask for non-AI-Block sources if one is included.

## Compose the prompt

Use the user's requested angle, structure, tone, and length. Combine requests in the order stated. When these details are absent, write one concise business-plain instruction without inventing sections, metrics, or analytical focus.

Examples:

> User: "add a summary block for this dashboard's KPIs"
> Prompt: "Summarize this dashboard's KPI trends for the period in view."

> User: "@Revenue Trend and @Signups — give me the key insights in 2–3 sentences"
> Prompt: "From @Revenue Trend and @Signups, give the key insights in 2–3 sentences."

> User: "summarize this dashboard, then list the top 3 movers and one action recommendation"
> Prompt: "Summarize this dashboard, then list the top 3 movers and close with one action recommendation."

## Place or update the block

1. Read the target dashboard file once. When editing an existing AI Block, read and revise its current prompt rather than replacing it blindly.
2. Use the current AML editor schema help or official documentation to confirm the `AiBlock` fields before editing.
3. Add or update the `AiBlock` with the composed prompt and a short, descriptive label.
4. For a new block on a canvas tab, place it below the lowest existing block without moving other blocks. Use half the tab width and a square size, i.e. its width equals its height, unless the user specifies a layout.
5. Validate the changed dashboard file.

Show the saved prompt, the target dashboard and tab, and validation status. If the request requires a new tab, broader rearrangement, or new interactions, use `build_dashboard` instead.