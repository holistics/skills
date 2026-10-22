---
name: working-in-reporting
description: "Use Holistics analytics skills and tooling to work with Holistics analytics more efficiently and effectively. Tooling includes MCP tools such as `generate_viz` and `search_docs`. Use this whenever the user is trying to perform analytics using their Holistics platform."
---

# Working in reporting
* Holistics Reporting environment is where the user utilize the already-published analytics to query datasets, view dashboards, or do self-serve analytics in general, to gain insights for their business.

## Mandatory preparation steps
* **ALWAYS** read [](../../references/holistics.md), and other references if necessary, to understand the Holistics context properly. Your knowledge and assumptions about Holistics are likely inaccurate or outdated.
* Set up Holistics MCP to use powerful Holistics tools and to perform analytics faster, more efficient, and more accurate.

## Holistics MCP
### Setup (once)
Use [](../setup-holistics-mcp/) skill

### Usage
Utilize relevant Holistics MCP tools for your work. They provide high-quality knowledge and outputs.

## AQL & Viz authoring mode
- **`holistics-ai`** (default) — Holistics AI writes AQL and Viz (`generate_aql`, `generate_viz`).
- **`self`** — the agent writes AQL and Viz itself from the bundled `aql` / `viz` skill references, and validates them with `validate_aql` / `execute_viz`.

The user can switch with `/plugin configure holistics-reporting@holistics-skills` (Claude Code), or by telling you or adding `Holistics authoring mode: self` to their project or custom instructions. See the `write-aql` skill for how the mode is resolved.
