---
name: working-in-reporting
description: Use Holistics analytics skills and tooling to work with Holistics analytics more effeciently and effectively. Tooling includes: MCP tools such as `generate_viz`, `search_docs`. Use this whenever the user is trying to perform analytics using their Holistics platform.
---

# Working in reporting
* Holistics Reporting environment is where the user utilize the already-published analytics to query datasets, view dashboards, or do self-serve analytics in general, to gain insights for their business.
* Set up Holistics MCP to use powerful Holistics tools and to perform analytics faster, more efficient, and more accurate.

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
        "X-Holistics-Env:live"
      ]
    }
  }
}
```

NOTE: at any point, if the user rejects a step (e.g. providing API key), you can give them instructions instead of doing the configuration for them.