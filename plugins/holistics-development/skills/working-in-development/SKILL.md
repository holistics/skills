---
name: working-in-development
description: "Use this whenever working in a (Holistics) AMQL project (i.e. with AML files). It guides you to set up the development environment and tooling properly, and provides the general best practice when working in an AMQL project. Example tooling: `holistics mcp generate_viz`, `holistics mcp search_docs`, `holistics aml validate`."
---

# Working in development
* Holistics Development environment is where the user develops their analytics as-code (AMQL), including modeling, metrics, dashboards, etc. before publishing them to the Reporting environment to provide analytics to end-users.

## Mandatory preparation steps
* **ALWAYS** read [](../../references/holistics.md), and other references if necessary, to understand the Holistics and AMQL context properly. Your knowledge and assumptions about Holistics and AMQL are likely inaccurate or outdated.
* Use [](../develop-amql/) skill when working with AMQL codes.
* Set up Holistics CLI to use powerful Holistics tools and make your development faster, more efficient, and more accurate.

## Holistics CLI
### Setup (once)
Use [](../setup-holistics-cli/) skill

### Usage
* Use `holistics sync-code` to synchronize local codes with Holistics backend, enabling and making sure tools run on latest codes
* Use `holistics aml validate <files...>` to validate AML files after making every new change. For example:
  * `holistics aml validate "new file.model.aml" "new_file2.dataset.aml"`
  * `holistics aml validate **/*.aml`
* Using tools:
  * `holistics mcp`: List available tools
  * `holistics mcp <tool> --help`: Learn more about a tool and its inputs, outputs
  * `holistics mcp <tool> '<json_payload>'`: Call a tool
