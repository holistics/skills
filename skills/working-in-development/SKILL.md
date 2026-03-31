---
name: working-in-development
description: Use Holistics analytics engineering skills and tooling to develop analytics in Holistics more effeciently and effectively. Tooling includes: MCP tools such as `generate_viz`, `search_docs`. Use this whenever working in a Holistics (AMQL) project.
---

## Working in development
* Holistics Development environment is where the user develops their analytics as-code (AMQL), including modeling, metrics, dashboards, etc. before publishing them to the Reporting environment to provide analytics to end-users.
* Set up Holistics MCP to use powerful Holistics tools and make your development faster, more efficient, and more accurate.

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