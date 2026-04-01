---
name: setup-holistics-cli
description: Use this skill to set up Holistics CLI and enable useful tools such as `holistics aml validate`
---

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