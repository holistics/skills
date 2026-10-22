---
name: viz
description: Core Holistics Viz AML knowledge — viz types and their properties, field references, calculations, conditions, params, formats, conditional formatting, dynamic content blocks (MarkdownViz), and worked examples. Use whenever you need to write, read, or debug a Viz (chart, table, pivot, KPI, map, MarkdownViz) yourself.
---

# Viz AML core knowledge

A Viz is the AML block that turns a dataset query into a chart, table, or
other visualization — e.g. `PieChart { dataset: ecommerce ... }`. This skill is
the knowledge base you consult while writing one; it doesn't run anything.

## How to use these references
**Don't write Viz AML from memory — properties differ per viz type and invented ones fail.**

1. **`references/guide.md` — read this first, before writing any Viz.** Field references (`r(...)` vs calculations), converting an AQL explore into a Viz, params, the rules for fitting dimensions into viz slots, and formatting defaults.
2. **`references/type_definitions/viz.aml` — the schema.** Find your viz type's block and use only its properties. `conditional_format.aml`, `action.aml`, and `custom_chart_def.aml` define the types it refers to.
3. **`references/examples.md` — worked examples.** Request → Viz pairs across viz types, BAD examples, and common errors with their fixes.
4. **`references/data_format.md`** — the common date and number format patterns. For anything rarer (currency list, full syntax), use `search_docs`.
5. **`references/dynamic_content_blocks.md`** — only for `MarkdownViz` (data-driven HTML/Markdown).

## Where the fields come from
* Use `fetch_dataset` for the dataset's models, fields, and metrics — the "dataset fields" the references mention. Reference only fields that exist there, or Viz `calculation`s you declare.
* An AQL explore is optional. If you have one, convert it as `guide.md` describes; otherwise place dataset fields directly and declare anything new as a `calculation`.

## Checking a Viz
Run it with tool `execute_viz`:

```json
{ "dataset_uname": "<dataset>", "title": "<short title>", "viz": "<Viz AML>" }
```

It reports invalid properties and unknown fields with exact messages (e.g. `Property 'single_cell_display' does not exist on type 'PieChart'`), and otherwise returns the rendered data. Fix every error and re-run. Inside a `page.aml`, also validate the file with `holistics aml validate`.

## Delegating to Holistics AI
Use `generate_viz` instead of writing the Viz yourself when the user asks for Holistics AI, the project's instructions (e.g. `CLAUDE.md`, `AGENTS.md`) say to use it, or the Viz still fails after ~3 fix rounds. It needs an AQL explore (`aql`); pass your last attempt as `current_viz` and its errors in `current_result`.
