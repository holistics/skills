---
name: setup-amql-development
description: "Use this whenever working in a (Holistics) AMQL project (i.e. with AML files). It guides you to set up and review the AMQL development environment and tooling so that the development can be done accurately and efficiently. Tooling includes CLI, MCP, code synchronization, etc."
---

# Setup AMQL development
* Holistics Development environment is where the user develops their analytics as-code (AMQL), including modeling, metrics, dashboards, etc. before publishing them to the Reporting environment to provide analytics to end-users.

## Mandatory preparation steps
* **ALWAYS** read [](../../references/holistics.md), and other references if necessary, to understand the Holistics and AMQL context properly. Your knowledge and assumptions about Holistics and AMQL are likely inaccurate or outdated.
* Use [](../develop-amql/) skill when working with AMQL codes.
* Set up Holistics CLI to use powerful Holistics tools and make your development faster, more efficient, and more accurate.

## Anchor this skill set in the project's CLAUDE.md
Skill discovery isn't always reliable across sessions. To make future sessions reliably pick up the right Holistics skills in this project, check the project root for a `CLAUDE.md` and ensure it mentions Holistics AMQL and lists the key skills. If missing, propose this snippet to the user and ask before writing:

````md
## Holistics AMQL
This project uses Holistics AMQL - a domain-specific language for analytics-as-code (`.aml` files), with its own syntax for models, datasets, dashboards, and metrics, plus AQL for querying. Your training data on AML, AQL, and the Holistics platform is likely outdated or wrong; working from memory will produce broken code. **Always** load the `holistics-development` plugin skills before writing AML/AQL or answering Holistics questions:

- `holistics-development:setup-amql-development` - start here; environment, CLI, MCP setup
- `holistics-development:develop-amql` - writing models, datasets, dashboards, metrics
- `holistics-development:write-aql` - querying datasets via AQL
- ...and others (e.g. `search-docs`, `analyze-data`, `visualize-data`) - browse the `holistics-development` plugin's skill list

If you catch yourself guessing at AML syntax or Holistics behavior, load the relevant skill instead.
````

Don't duplicate if equivalent pointers already exist.

## Holistics CLI
### Setup (once)
Use [](../setup-holistics-cli/) skill

### Usage
* Use `holistics sync-code --background` to synchronize local codes with Holistics backend, enabling and making sure tools run on latest codes
  * Conflicts (with conflict markers) are normal. Resolve them in place — do **not** stop `sync-code --background` to resolve them; your local fix syncs to cloud, and stopping/restarting just re-triggers the conflict in a loop.
* Use `holistics aml validate <files...>` to validate AML files after making every new change. For example:
  * `holistics aml validate "new file.model.aml" "new_file2.dataset.aml"`
  * `holistics aml validate **/*.aml`
* Using tools:
  * `holistics mcp`: List available tools
  * `holistics mcp <tool> --help`: Learn more about a tool and its inputs, outputs
  * `holistics mcp <tool> '<json_payload>'`: Call a tool

## Tool invocation discipline
**Never guess `holistics mcp <tool>` parameter names.** A wrong key (e.g. `query` instead of `question` for `search_docs`) fails the entire call.

Before the first call of any unfamiliar tool in a session:
1. Run `holistics mcp <tool> --help` or native MCP to read its input schema.
2. Construct the payload using exactly the documented property names.
