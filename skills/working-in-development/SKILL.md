---
name: working-in-development
description: Use Holistics analytics engineering skills and tooling to develop analytics in Holistics more effeciently and effectively. Tooling includes: MCP tools such as `generate_viz`, `search_docs`, and CLI such as `holistics aml validate`. Use this whenever working in a Holistics (AMQL) project.
---

# Working in development
* Holistics Development environment is where the user develops their analytics as-code (AMQL), including modeling, metrics, dashboards, etc. before publishing them to the Reporting environment to provide analytics to end-users.
* Set up Holistics MCP to use powerful Holistics tools and make your development faster, more efficient, and more accurate.

## Holistics CLI
### Setup (once)
Use [](../setup-holistics-cli/) skill

### Usage
* Use `holistics aml validate <files...>` to validate AML files after making any new changes. For example:
  * `holistics aml validate "new file.model.aml" "new_file2.dataset.aml"`
  * `holistics aml validate **/*.aml`

## Holistics MCP
### Setup (once)
Use [](../setup-dev-holistics-mcp/) skill

### Usage
Utilize relevant Holistics MCP tools for your work. They provide high-quality knowledge and outputs.