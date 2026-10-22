---
name: viz
description: Core Holistics Viz AML knowledge — viz types and their properties, field references, calculations, conditions, params, formats, conditional formatting, dynamic content blocks (MarkdownViz), and worked examples. Use whenever you need to write, read, or debug a Viz (chart, table, pivot, KPI, map, MarkdownViz) yourself.
---

# Viz AML core knowledge

A Viz is the AML block that turns a dataset query into a chart, table, or
other visualization — e.g. `PieChart { dataset: ecommerce ... }`. This skill is
the knowledge base you consult while writing one; it doesn't run anything.

## Authoring mode
Plugin setting: `${user_config.authoring_mode}`

Write a Viz yourself with this skill **only** when the authoring mode is `self`. It's set by, in priority order: the user in this conversation, the project's instructions (e.g. `CLAUDE.md`, `AGENTS.md`, Cursor rules — "Holistics authoring mode: self"), then the plugin setting above. Otherwise — including when the plugin setting above is an unfilled `${…}` placeholder — use Holistics AI: `generate_aql` → `generate_viz` (see *Holistics AI* below).

**In self mode, write the Viz from these references and do NOT call `generate_viz`, except as the last-resort fallback below.**

## How to use these references
**Don't write Viz AML from memory — properties differ per viz type and invented ones fail.**

1. **`references/guide.md` — read this first, before writing any Viz.** Field references (`r(...)` vs calculations), converting an AQL explore into a Viz, params, the rules for fitting dimensions into viz slots, and formatting defaults.
2. **`references/type_definitions/viz.aml` — the schema.** Find your viz type's block and use only its properties. `conditional_format.aml`, `action.aml`, and `custom_chart_def.aml` define the types it refers to.
3. **`references/examples.md` — worked examples.** Request → Viz pairs across viz types, BAD examples, and common errors with their fixes.
4. **`references/data_format.md`** — the common date and number format patterns, with links to the full format docs for anything rarer (currency list, full syntax).
5. **`MarkdownViz`** (data-driven HTML/Markdown) — its template syntax is in the public docs: [syntax reference](https://docs.holistics.io/docs/charts/dynamic-content-blocks/syntax-reference) and [getting started](https://docs.holistics.io/docs/charts/dynamic-content-blocks/getting-started).

## Where the fields come from
* Use `fetch_dataset` for the dataset's models, fields, and metrics — the "dataset fields" the references mention. Reference only fields that exist there, or Viz `calculation`s you declare.
* An AQL explore is optional. If you have one, convert it as `guide.md` describes; otherwise place dataset fields directly and declare anything new as a `calculation`.

## Checking a Viz
Run it with tool `execute_viz`:

```json
{ "dataset_uname": "<dataset>", "title": "<short title>", "viz": "<Viz AML>" }
```

It reports invalid properties and unknown fields with exact messages (e.g. `Property 'single_cell_display' does not exist on type 'PieChart'`), and otherwise returns the rendered data. Fix every error and re-run. Inside a `page.aml`, also validate the file with `holistics aml validate`.

## Sub-agent or inline?
You can write the Viz yourself or hand it to a sub-agent — a `viz-writer` sub-agent if available, otherwise a generic one told to use this skill. It writes the Viz, checks it with `execute_viz`, and returns only the final Viz AML. Decide per task:
* **Delegate** when several independent vizzes can be written in parallel (e.g. a dashboard's blocks), or when the session is long and keeping the Viz references out of your context matters.
* **Do it inline** when you've already read the Viz references this session (a sub-agent re-reads them every time it starts), when it's a small edit to an existing Viz, or when the work needs back-and-forth with the user or depends on surrounding decisions.
* **Always inline** when no sub-agent is available (e.g. claude.ai, ChatGPT), or when you *are* the sub-agent.

## Holistics AI
`generate_viz` writes the Viz for you. Use it when the authoring mode isn't `self`, or when your own Viz still fails after ~3 fix rounds. It needs an AQL explore (`aql`); when retrying, pass the last attempt as `current_viz` and its errors in `current_result`. Check what it returns with `execute_viz` as above.
