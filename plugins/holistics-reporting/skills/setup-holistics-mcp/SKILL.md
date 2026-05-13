---
name: setup-holistics-mcp
description: Use this skill to set up Holistics MCP and enable useful tools such as `search_docs`, `execute_aql`, and `generate_viz`
---

## Holistics MCP
### Setup (once)
1. Ask the user to [enable Holistics AI](https://docs.holistics.io/docs/ai#getting-started)
2. Ask the user to pick their <MCP_SERVER_ADDRESS> from based on their login URL:
  * secure.holistics.io (APAC region) -> https://mcp-apac.holistics.io/reporting/mcp
  * us.holistics.io (US region) -> https://mcp-us.holistics.io/reporting/mcp
  * eu.holistics.io (EU region) -> https://mcp-eu.holistics.io/reporting/mcp
  * Other: let user input the MCP URL
3. Configure MCP server for the user (preferrably using Claude CLI)
```json
{
  "mcpServers": {
    "holistics-reporting": {
      "type": "http",
      "url": "<MCP_SERVER_ADDRESS>"
    }
  }
}
```

NOTE: at any point, if the user rejects a step, you can give them instructions instead of doing the configuration for them.

### References
* https://docs.holistics.io/docs/ai/mcp-server#how-to-connect
