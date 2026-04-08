---
name: setup-holistics-mcp
description: Use this skill to set up Holistics MCP and enable useful tools such as `search_docs`, `execute_aql`, and `generate_viz`
---

## Holistics MCP
### Setup (once)
1. Ask the user to [enable Holistics AI](https://docs.holistics.io/docs/ai#getting-started)
2. Ask the user to pick their <MCP_SERVER_ADDRESS> from this list:
  * APAC: https://mcp-apac.holistics.io/mcp
  * US: https://mcp-us.holistics.io/mcp
  * EU: https://mcp-eu.holistics.io/mcp
  * Other: let user input
3. Ask the user to provide their Holistics API Key
4. Configure MCP server for the user (preferrably using Claude CLI)
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
