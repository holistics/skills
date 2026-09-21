---
name: format-ai-block-output
label: Format AI Block Output
description: |-
  Use when generating the output or narrative of a dashboard AI Block based on the block's saved prompt — a data-backed summary, report, comparison, status update, risk list, or recommendation — and needs a nice, compact, scannable HTML output. Do NOT trigger while a prompt is still being authored or edited in chat; only once actual content exists to render.
user-invocable: false
---
Return HTML only, no Markdown fences or preamble. Apply these rules based on the content; not every rule fires on every block.

Preserve the meaning, scope, and material uncertainty in the supplied content. Do not make conclusions, statuses, or recommendations appear stronger than the underlying analysis supports.

1. TABULAR / COMPARATIVE DATA → use <table>, not prose bullets. If you find yourself writing multiple bullets that share the same shape (e.g. "<entity> — <attribute> — <value>", or a metric repeated across two time periods, or a list of records each with the same 2-4 fields), that is a table. Use <table>/<tr>/<th>/<td> with a header row instead of restating the field names in every bullet. Do not use a table for a single item.

For a time trend, lead with a short narrative: what changed, when it changed, whether the movement persisted, and its evidenced implication. Add a compact comparison table only when a few periods or segments must be compared.

2. STATUS, SEVERITY, OR DIRECTION → use a colored badge/pill, not bold text. Any value that conveys status, health, priority, sentiment, performance direction, or comparison to a defined target should carry color, not just weight. This includes states such as positive/negative/neutral, high/medium/low, or above/on/below target. Use a small consistent palette: red for negative or critical, green for positive or healthy, amber for watch-list, and gray for neutral. Keep the status text in the pill so color is never the only signal. Apply a status or severity label only when the source data or an explicit benchmark supports it.

3. THE SINGLE MOST ACTIONABLE SENTENCE → an evidence-backed callout, not an inline bold lead-in. Use it only when the data supports a clear decision, priority, or next step. Do not manufacture a bottom line for an exploratory or inconclusive result. Pull the supported takeaway into its own visually distinct block.

4. CAVEATS AND LIMITATIONS → a muted note, separated from primary content. If the data has a limitation (stale timestamps, wrong granularity, partial filter, no anomaly detection applied), don't lead the section with it as bullet #1 — that buries the actual finding under a disclaimer. Give it a visually quieter treatment (smaller text, gray, or a "Note:" prefix) so a reader sees the finding first and the caveat second.

5. KPI-STYLE SINGLE NUMBERS → consider a stat-tile layout. Use tiles only for 2-4 standalone, compatible KPIs when the reader benefits from scanning values before interpretation. Include a label, value, and concise context (such as period or comparison) in each tile. Prefer prose or a table when metrics have different units, there are many values, or interpretation matters more than repeating dashboard KPI tiles.

6. DON'T OVER-BOLD. Bold marks the ONE most important number or claim in a line, not every number and every named entity. If more than ~30% of a paragraph is bold, remove bold from everything except the single most decision-relevant figure.

7. BE CONSISTENT WITHIN THE BLOCK. When enumerating similar items (multiple complaints, multiple records, multiple risks), pick one presentation (e.g. "bold headline + supporting detail" or "table row") and use it for every item in that list — don't mix formats within the same enumeration.

8. VISUAL HIERARCHY → make importance visible. Use headings to separate sections, give the primary finding the strongest emphasis, keep supporting detail visually secondary, and render caveats quietly. Avoid giving every line equal visual weight.

9. THEME ALIGNMENT → follow the active dashboard theme when it is available. Reuse its color intent for emphasis, surfaces, borders, and status treatments; do not introduce a competing palette. When no theme context is available, use a restrained, accessible semantic palette and avoid strong decorative colors.
