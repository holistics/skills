---
name: working-in-development
description: Use Holistics analytics engineering skills and tooling to develop analytics in Holistics more effeciently and effectively. Tooling includes: MCP tools such as `generate_viz`, `search_docs`, and CLI such as `holistics aml validate`. Use this whenever working in a Holistics (AMQL) project.
---

# Working in development
* Holistics Development environment is where the user develops their analytics as-code (AMQL), including modeling, metrics, dashboards, etc. before publishing them to the Reporting environment to provide analytics to end-users.
* Set up Holistics MCP to use powerful Holistics tools and make your development faster, more efficient, and more accurate.

## Holistics CLI
### Setup (once)
#### macOS and Linux
```bash
curl -fsSL https://raw.githubusercontent.com/holistics/holistics-cli/refs/heads/master/install.sh | bash
```
The CLI is not compatible with MacOS 12.x (Monterey), which reached end of life on September 16, 2024. There are 2 solutions:
* Upgrade to MacOS 13 (Ventura) or later
* If you have Node.js installed, you can run the CLI from source code, please refer to: https://github.com/holistics/holistics-cli#how-to-run-the-code-via-node

#### Windows
At the moment, we do not have an installation script for Windows. Please manually download the [latest release](https://github.com/holistics/holistics-cli/releases/latest), then add it to your Path in the Environment Variables.

### Usage
* Use `holistics aml validate <files...>` to validate AML files after making any new changes. For example:
  * `holistics aml validate "new file.model.aml" "new_file2.dataset.aml"`
  * `holistics aml validate **/*.aml`

## Holistics MCP
### Setup (once)
1. Ask the user to [enable Holistics AI](https://docs.holistics.io/docs/ai#getting-started)
2. Ask the user to pick their <MCP_SERVER_ADDRESS> from this list:
  * APAC: https://mcp-apac.holistics.io/mcp
  * US: https://mcp-us.holistics.io/mcp
  * EU: https://mcp-eu.holistics.io/mcp
  * Other: let user input
3. Ask the user to provide their Holistics API Key
4. Configure MCP server for the user
```json
{
  "mcpServers": {
    "holistics-development": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "<MCP_SERVER_ADDRESS>",
        "--header",
        "X-Holistics-Key:<YOUR_HOLISTICS_API_KEY>"
        "X-Holistics-Env:development"
      ]
    }
  }
}
```

NOTE: at any point, if the user rejects a step (e.g. providing API key), you can give them instructions instead of doing the configuration for them.