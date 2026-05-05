# Holistics
[Holistics](https:/holistics.io) is a modern BI platform that aims to enable self-service data access for entire organization by leveraging analytics-as-code and AI.

# Holistics Skills
This repository contains skills (under `plugins/`) to execute Holistics workflows more efficiently and effectively, including developing analytics and comsuming analytics to gain insights.

## How to install
### Claude code
Within claude code, run this command to add Holistics skills marketplace:
```bash
/plugin marketplace add holistics/skills
```

Then, browse and install the relevant plugins via `/plugin` > `Marketplaces` > `holistics-skills` > `Browse plugins` > Install

(Optional) enable auto-update via `/plugin` > `Marketplaces` > `holistics-skills` > `Enable auto-update`

## Choosing plugin
* `holistics-development`: When you are developing your AMQL project with your coding agents such as Claude Code, Codex, etc.
* `holistics-reporting`: When you want to ask data questions on published AMQL objects (datasets, dashboards, etc.) with your general agents such as Claude.ai, ChatGPT, etc.

# Native Skills
**Native skills** (`native-skills/`) are skills that can be imported into Holistics App **for Holistics native AI agent** to use.
Their available toolings are Holistics native web UI and backend features.

In contrary, **plugins** (`plugins/`) contains skills for **non-Holistics AI agents** to work with Holistics.
Their available toolings are typically local IDE, MCP, and CLI.