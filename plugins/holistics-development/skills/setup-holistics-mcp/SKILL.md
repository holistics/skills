---
name: setup-holistics-mcp
description: Use this skill to set up or review Holistics MCP connection and enable useful tools such as `search_docs`, `execute_aql`, and `generate_viz`
---

## IMPORTANT: Use CLI MCP instead
Use `holistics mcp` command instead. It provides access to all MCP tools without any additional setup or maintenance.

Only set up or maintain agent's direct MCP connection when explicitly asked by the user.

## Direct Holistics MCP connection
### Setup (once)
1. Ask the user to [enable Holistics AI](https://docs.holistics.io/docs/ai#getting-started)
2. Ask the user to pick their <MCP_SERVER_ADDRESS> from based on their login URL:
  * secure.holistics.io (APAC region) -> https://mcp-apac.holistics.io/development/mcp
  * us.holistics.io (US region) -> https://mcp-us.holistics.io/development/mcp
  * eu.holistics.io (EU region) -> https://mcp-eu.holistics.io/development/mcp
  * Other: let user input the MCP URL
3. Configure MCP server for the user (preferrably using Claude CLI)
```json
{
  "mcpServers": {
    "holistics-development": {
      "type": "http",
      "url": "<MCP_SERVER_ADDRESS>"
    }
  }
}
```

NOTE: at any point, if the user rejects a step, you can give them instructions instead of doing the configuration for them.

### References
* https://docs.holistics.io/docs/ai/mcp-server#how-to-connect